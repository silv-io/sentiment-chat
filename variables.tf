variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "sentiment-chat"
}

variable "bedrock_model_id" {
  description = "The ID of the Bedrock model to use for sentiment analysis."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "negative_sentiment_threshold" {
  description = "The sentiment score threshold below which an alert is triggered."
  type        = number
  default     = -0.5
}
