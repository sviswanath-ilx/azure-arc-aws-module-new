# variable "profile_name" {
#   type        = string
#   description = "Provide profile name for AWS CLI"
#   default     = "sandbox"  # Replace with your actual AWS CLI profile name
# }

# variable "aws_region" {
#   description = "Provide region name for AWS"
#   type        = string
#   default = "us-east-2"
# }

variable "ArcForServerEC2SSMRoleName" {
  default = "AzureArcForServerSSM"
  description = "The name of the IAM role assigned to the EC2 instance for SSM tasks."
}

variable "ArcForServerSSMInstanceProfileName" {
  default = "AzureArcForServerSSMInstanceProfile"
  description = "The name of the IAM instance profile attached to the EC2 IAM role used for SSM tasks."
}

variable "ConnectorPrimaryIdentifier" {
  default = "3b4f21d7-4dca-4d6c-aa8b-a2d884b347f4"
  description = "AWS Connector Primary Identifier for a given multiCloudConnectors resource."
}

variable "EC2SSMIAMRoleAutoAssignment" {
  default = "true"
}

variable "EC2SSMIAMRoleAutoAssignmentSchedule" {
  default = "Enable"
}

variable "EC2SSMIAMRoleAutoAssignmentScheduleInterval" {
  default = "1 day"
}

variable "EC2SSMIAMRolePolicyUpdateAllowed" {
  default = "true"
}

variable "oidc_client_id" {
  description = "OIDC client ID"
}

variable "oidc_thumbprint" {
  description = "OIDC thumbprint"
}

variable "oidc_url" {
  description = "OIDC provider URL"
}

variable "azure_connector_id" {
  description = "Azure Arc connector ID"
}

variable "tags" {
  type        = map(any)
  description = "Tags for the azure arc aws instance"
}
  
