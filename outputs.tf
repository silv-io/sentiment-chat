output "websocket_uri" {
  description = "The URI of the WebSocket API."
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "s3_bucket_website_endpoint" {
  description = "The website endpoint for the S3 bucket."
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alerts."
  value       = aws_sns_topic.alerts.arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS key."
  value       = aws_kms_key.main.arn
}

output "verified_permissions_policy_store_id" {
  description = "The ID of the Verified Permissions policy store."
  value       = aws_verifiedpermissions_policy_store.main.id
}
