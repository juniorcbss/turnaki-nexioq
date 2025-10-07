# API Gateway Routes - Conectar Lambdas con Endpoints HTTP
# Este archivo conecta las lambdas desplegadas con rutas HTTP

# =====================================
# INTEGRACIONES LAMBDA → API GATEWAY  
# =====================================

# Health (ruta pública)
resource "aws_apigatewayv2_integration" "health" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_health.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "health" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_health.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Bookings (rutas protegidas)
resource "aws_apigatewayv2_integration" "bookings" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_bookings.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "bookings" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_bookings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Availability (ruta mixta - POST protegida)
resource "aws_apigatewayv2_integration" "availability" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_availability.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "availability" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_availability.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Tenants (rutas protegidas)
resource "aws_apigatewayv2_integration" "tenants" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_tenants.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "tenants" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_tenants.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Treatments (rutas protegidas)
resource "aws_apigatewayv2_integration" "treatments" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_treatments.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "treatments" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_treatments.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# Professionals (rutas protegidas)
resource "aws_apigatewayv2_integration" "professionals" {
  api_id           = module.api_gateway.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_professionals.function_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "professionals" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_professionals.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

# =====================================
# RUTAS HTTP → LAMBDAS
# =====================================

# Health endpoint (público)
resource "aws_apigatewayv2_route" "health" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health.id}"
  
  # Sin autenticación (endpoint público)
}

# Bookings endpoints (protegidos)
resource "aws_apigatewayv2_route" "get_bookings" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /bookings"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "post_bookings" {
  api_id    = module.api_gateway.api_id
  route_key = "POST /bookings"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "put_bookings" {
  api_id    = module.api_gateway.api_id
  route_key = "PUT /bookings/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "delete_bookings" {
  api_id    = module.api_gateway.api_id
  route_key = "DELETE /bookings/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.bookings.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

# Availability endpoint (protegido)
resource "aws_apigatewayv2_route" "post_availability" {
  api_id    = module.api_gateway.api_id
  route_key = "POST /booking/availability"
  target    = "integrations/${aws_apigatewayv2_integration.availability.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

# Tenants endpoints (protegidos)
resource "aws_apigatewayv2_route" "get_tenants" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /tenants"
  target    = "integrations/${aws_apigatewayv2_integration.tenants.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "post_tenants" {
  api_id    = module.api_gateway.api_id
  route_key = "POST /tenants"
  target    = "integrations/${aws_apigatewayv2_integration.tenants.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "get_tenant_by_id" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /tenants/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.tenants.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

# Treatments endpoints (protegidos)
resource "aws_apigatewayv2_route" "get_treatments" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /treatments"
  target    = "integrations/${aws_apigatewayv2_integration.treatments.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "post_treatments" {
  api_id    = module.api_gateway.api_id
  route_key = "POST /treatments"
  target    = "integrations/${aws_apigatewayv2_integration.treatments.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

# Professionals endpoints (protegidos)
resource "aws_apigatewayv2_route" "get_professionals" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /professionals"
  target    = "integrations/${aws_apigatewayv2_integration.professionals.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}

resource "aws_apigatewayv2_route" "post_professionals" {
  api_id    = module.api_gateway.api_id
  route_key = "POST /professionals"
  target    = "integrations/${aws_apigatewayv2_integration.professionals.id}"
  
  authorization_type = "JWT"
  authorizer_id      = module.api_gateway.authorizer_id
}
