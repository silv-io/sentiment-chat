data "archive_file" "connect_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/connect"
  output_path = "${path.module}/lambda/connect.zip"
}

data "archive_file" "disconnect_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/disconnect"
  output_path = "${path.module}/lambda/disconnect.zip"
}

data "archive_file" "sendmessage_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/sendmessage"
  output_path = "${path.module}/lambda/sendmessage.zip"
}

resource "aws_lambda_function" "connect" {
  function_name = "${var.project_name}-connect"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.handler"
  runtime       = "python3.9"
  filename      = data.archive_file.connect_lambda_zip.output_path
  source_code_hash = data.archive_file.connect_lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      MEMORYDB_HOST   = aws_memorydb_cluster.main.cluster_endpoint[0].address
      POLICY_STORE_ID = aws_verifiedpermissions_policy_store.main.id
    }
  }
}

resource "aws_lambda_function" "disconnect" {
  function_name = "${var.project_name}-disconnect"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.handler"
  runtime       = "python3.9"
  filename      = data.archive_file.disconnect_lambda_zip.output_path
  source_code_hash = data.archive_file.disconnect_lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      MEMORYDB_HOST = aws_memorydb_cluster.main.cluster_endpoint[0].address
    }
  }
}

resource "aws_lambda_function" "sendmessage" {
  function_name = "${var.project_name}-sendmessage"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.handler"
  runtime       = "python3.9"
  filename      = data.archive_file.sendmessage_lambda_zip.output_path
  source_code_hash = data.archive_file.sendmessage_lambda_zip.output_base64sha256
  timeout       = 30

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      MEMORYDB_HOST                = aws_memorydb_cluster.main.cluster_endpoint[0].address
      BEDROCK_MODEL_ID             = var.bedrock_model_id
      SNS_TOPIC_ARN                = aws_sns_topic.alerts.arn
      POLICY_STORE_ID              = aws_verifiedpermissions_policy_store.main.id
      NEGATIVE_SENTIMENT_THRESHOLD = var.negative_sentiment_threshold
      API_GATEWAY_ID               = aws_apigatewayv2_api.websocket_api.id
      API_GATEWAY_STAGE            = "prod"
      AWS_REGION                   = var.aws_region
    }
  }
}

resource "aws_lambda_permission" "apigw_connect" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "apigw_disconnect" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disconnect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$disconnect"
}

resource "aws_lambda_permission" "apigw_sendmessage" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sendmessage.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/sendmessage"
}
