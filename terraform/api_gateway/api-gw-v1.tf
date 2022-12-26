resource "aws_api_gateway_rest_api" "foo" {
  name                         = "foo" # Must be configured
  description                  = "This is a demo api-gw template" # Must be configured
  disable_execute_api_endpoint = false
  api_key_source               = "HEADER"
  binary_media_types           = ["UTF-8-encoded", "application/octet", "image/jpeg"]
  endpoint_configuration {
    # Must be configured
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_resource" "foo" {
  # All options # Must be configured
  rest_api_id = aws_api_gateway_rest_api.foo.id
  parent_id   = aws_api_gateway_rest_api.foo.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "foo" {
  rest_api_id = aws_api_gateway_rest_api.foo.id
  resource_id = aws_api_gateway_resource.foo.id
  http_method = "GET"

  # Preferred value COGNITO_USER_POOLS, AWS_IAM, CUSTOME
  # SaC Testing - Severity: Critical - Set authorizatoin and authorizer_id to empty string and null
  authorization        = ""                                # Must be configured # oak9: authorization should be set to any of aws_iam, custom, cognito_user_pools # oak9: authorization should be set to any of aws_iam, custom, cognito_user_pools
  authorizer_id        = ""                                # Must be configured
  authorization_scopes = [""]                              # Must be configured
  api_key_required     = false                             # Must be configured
  request_models       = { "application/json" = "Empty" }
  request_validator_id = aws_api_gateway_request_validator.foo.id
  request_parameters = {
    "method.request.path.proxy" = true,
    "method.request.path.param" = true
  }
}

resource "aws_api_gateway_integration" "foo" {
  rest_api_id             = aws_api_gateway_rest_api.foo.id
  resource_id             = aws_api_gateway_resource.foo.id
  http_method             = aws_api_gateway_method.foo.http_method
  integration_http_method = "POST"
  connection_type         = "INTERNET"
  type                    = "MOCK" # Must be configured
  cache_key_parameters    = ["method.request.path.param"]
  cache_namespace         = "foobar"
  timeout_milliseconds    = 29000               # Must be configured
  passthrough_behavior    = "WHEN_NO_TEMPLATES" # Must be configured
  content_handling        = "CONVERT_TO_TEXT"

  request_parameters = {
    # Must be configured
    "integration.request.header.X-Authorization" = "'static'"
  }

  request_templates = {
    # Must be configured
    "application/xml" = <<EOF
{
   "statusCode" : 200
}
EOF
  }

  depends_on = [aws_api_gateway_method.foo]
}

resource "aws_api_gateway_method_response" "foo" {
  # All options # Must be configured
  rest_api_id = aws_api_gateway_rest_api.foo.id
  resource_id = aws_api_gateway_resource.foo.id
  http_method = aws_api_gateway_method.foo.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  depends_on = [
    aws_api_gateway_method.foo,
  ]
}

resource "aws_api_gateway_integration_response" "foo" {
  rest_api_id       = aws_api_gateway_rest_api.foo.id
  resource_id       = aws_api_gateway_resource.foo.id
  http_method       = aws_api_gateway_method.foo.http_method
  status_code       = aws_api_gateway_method_response.foo.status_code # Must be configured
  selection_pattern = "^Token*"                                       # Must be configured
  response_parameters = {
    # Must be configured
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,DELETE,GET,HEAD,PATCH,POST,PUT'"
  }
  # Transforms the backend JSON response to XML
  response_templates = {
    # Must be configured
    "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }

  depends_on = [
    aws_api_gateway_integration.foo,
    aws_api_gateway_method_response.foo,
  ]
}

resource "aws_api_gateway_gateway_response" "foo" {
  # All options # Must be configured
  rest_api_id   = aws_api_gateway_rest_api.foo.id
  status_code   = "401"
  response_type = "UNAUTHORIZED"

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Authorization" = "'Basic'"
  }
}
