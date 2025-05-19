  # This is the ID of the Azure Multi-Cloud Connector resource in Azure. 
  # Replace with your actual Azure Multi-Cloud Connector ID.
  # Example: "/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.HybridConnectivity/PublicCloudConnectors/{connector-name}"
  # Note: The above example is a placeholder. You should replace it with the actual ID of your Azure Multi-Cloud Connector resource.
  # Example: "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myResourceGroup/providers/Microsoft.HybridConnectivity/PublicCloudConnectors/myConnector"

locals {
  azure_connector_id = "/subscriptions/f7f17b68-862f-46b7-b8a9-aea4b7bc27d6/resourcegroups/viswa-rg/providers/microsoft.hybridconnectivity/publiccloudconnectors/azure-to-aws"
}

