resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name}"
  deletio_window_in_days = 7
  enable_key_rotation     = true
}
