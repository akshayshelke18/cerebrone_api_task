provider "aws" {
  region = "us-east-1"
}
# Creating Rest API
resource "aws_api_gateway_rest_api" "api_gw" {
  name = "cerebrone_api_gw"
}

# Creating Resource
resource "aws_api_gateway_resource" "cerebrone_resource" {
  path_part   = "cerebrone_resource"
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
}

# GET Method
resource "aws_api_gateway_method" "cerebrone_apt_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.cerebrone_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# PUT Method
resource "aws_api_gateway_method" "cerebrone_apt_put_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.cerebrone_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# POST Method
resource "aws_api_gateway_method" "cerebrone_apt_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.cerebrone_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Intergration with Lamda
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  resource_id             = aws_api_gateway_resource.cerebrone_resource.id
  http_method             = aws_api_gateway_method.cerebrone_apt_put_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

# Lamda permissions
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api_gw.id}/*/${aws_api_gateway_method.cerebrone_apt_put_method.http_method}${aws_api_gateway_resource.cerebrone_resource.path}"
}

# Creating IAM Policy for Lamda
resource "aws_iam_role_policy" "lambda_policy"{
    name = "lambda_policy"
    role = aws_iam_role.lambda_role.id
    policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1617215985083",
      "Action": "logs:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
})
}

# Creating IAM Role
resource "aws_iam_role" "lambda_role" {
    name = "lambda_role"
    assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

locals {
  lambda_zip_location = "outputs/hello.zip"
}

data "archive_file" "hello" {
  type        = "zip"
  source_file = "hello.py"
  output_path = "local.lambda_zip_location"
}

# Creating Lamda Function
resource "aws_lambda_function" "test_lambda" {
  filename      = "local.lambda_zip_location"
  function_name = "hello"
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello.new"  
  source_code_hash = base64sha256(local.lambda_zip_location)
  runtime = "python3.7"
}