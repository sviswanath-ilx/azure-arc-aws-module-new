resource "aws_iam_role" "arc_for_server_ssm_role" {
  name               = var.ArcForServerEC2SSMRoleName
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  description = "Azure Arc for servers to access SSM services role"

  tags  = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  role       = aws_iam_role.arc_for_server_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "arc_for_server_ssm_instance_profile" {
  name = var.ArcForServerSSMInstanceProfileName
  role = aws_iam_role.arc_for_server_ssm_role.name
  path = "/"
}

resource "aws_iam_openid_connect_provider" "microsoft_oidc" {
  client_id_list = ["api://34a6b290-8d65-48d3-966d-52758964f5e9"]
  thumbprint_list = ["626d44e704d1ceabe3bf0d53397464ac8080142c"]
  url = "https://sts.windows.net/975f013f-7f24-47e8-a7d3-abc4752bf346/"

  tags  = var.tags
}

resource "aws_iam_role" "arc_for_server_role" {
  name = "ArcForServer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.microsoft_oidc.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "sts:RoleSessionName" = "ConnectorPrimaryIdentifier_${var.ConnectorPrimaryIdentifier}",
            "sts.windows.net/975f013f-7f24-47e8-a7d3-abc4752bf346/:aud" = "api://34a6b290-8d65-48d3-966d-52758964f5e9",
            "sts.windows.net/975f013f-7f24-47e8-a7d3-abc4752bf346/:sub" = "c79e5535-7ea7-4197-8e0f-743faa585cd4"
          }
        }
      }
    ]
  })

  description = "Azure Arc for servers role"

  tags = var.tags
}

resource "aws_iam_role_policy" "arc_for_server_policy" {
  name = "ArcForServer"
  role = aws_iam_role.arc_for_server_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "RunInstallationCommands",
        Effect = "Allow",
        Action = "ssm:SendCommand",
        Resource = [
          "arn:aws:ssm:*::document/AWS-RunPowerShellScript",
          "arn:aws:ssm:*::document/AWS-RunShellScript",
          "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      {
        Sid = "CheckInstallationCommandStatus",
        Effect = "Allow",
        Action = [
          "ssm:CancelCommand",
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation"
        ],
        Resource = "*"
      },
      {
        Sid = "GetEC2Information",
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages"
        ],
        Resource = "*"
      },
      {
        Sid = "ListStackInstancesInformation",
        Effect = "Allow",
        Action = "cloudformation:ListStackInstances",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "EC2SSMIAMRoleAutoAssignmentFunctionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags  = var.tags
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "LambdaExecutionPolicy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DisassociateIamInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:PassRole",
          "iam:AddRoleToInstanceProfile",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:GetServiceSetting"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "lambda:DeleteFunction",
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:EC2SSMIAMRoleAutoAssignmentFunction"
      }
    ]
  })
}

resource "aws_lambda_function" "ec2_ssm_auto_assign" {
  function_name = "EC2SSMIAMRoleAutoAssignmentFunction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 900
  # filename      = "lambda.zip"
  # source_code_hash = filebase64sha256("lambda.zip")
  filename          = "${path.module}/lambda.zip"
  source_code_hash  = filebase64sha256("${path.module}/lambda.zip")

  tags  = var.tags
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "EC2SSMIAMRoleAutoAssignmentFunctionScheduler"
  description         = "Triggers Lambda based on schedule interval."
  schedule_expression = "rate(${var.EC2SSMIAMRoleAutoAssignmentScheduleInterval})"
  state               = var.EC2SSMIAMRoleAutoAssignment == "true" && var.EC2SSMIAMRoleAutoAssignmentSchedule == "Enable" ? "ENABLED" : "DISABLED"
}


resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "EC2SSMIAMRoleAutoAssignmentFunctionScheduler"
  arn       = aws_lambda_function.ec2_ssm_auto_assign.arn

  input = jsonencode({
    ArcForServerSSMInstanceProfileName = var.ArcForServerSSMInstanceProfileName,
    ArcForServerEC2SSMRoleName         = var.ArcForServerEC2SSMRoleName,
    EC2SSMIAMRolePolicyUpdateAllowed   = var.EC2SSMIAMRolePolicyUpdateAllowed
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_ssm_auto_assign.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}