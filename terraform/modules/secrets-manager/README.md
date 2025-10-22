# Módulo Secrets Manager

Este módulo gestiona secretos sensibles en AWS Secrets Manager.

## Propósito

Almacenar configuraciones sensibles como:
- Connection strings de bases de datos
- API keys de terceros
- JWT secrets
- Tokens de integración

## Uso

```hcl
module "secrets" {
  source = "../../modules/secrets-manager"

  project_name = var.project_name
  environment  = var.environment

  secrets = {
    database = {
      description = "Database connection string"
      value = {
        host     = "localhost"
        port     = 5432
        database = "turnaki"
        username = "admin"
        password = "secret123"
      }
    }
    stripe_api_key = {
      description = "Stripe API key"
      value = {
        api_key = "sk_test_..."
      }
    }
  }

  tags = var.tags
}
```

## Variables

| Variable | Descripción | Tipo | Default |
|----------|-------------|------|---------|
| `project_name` | Nombre del proyecto | `string` | - |
| `environment` | Ambiente (dev, qas, prd) | `string` | - |
| `secrets` | Mapa de secretos | `map(object)` | `{}` |
| `recovery_window_in_days` | Ventana de recuperación | `number` | `30` |
| `tags` | Tags adicionales | `map(string)` | `{}` |

## Outputs

| Output | Descripción |
|--------|-------------|
| `secret_arns` | ARNs de los secretos creados |
| `secret_names` | Nombres de los secretos creados |
| `secrets_access_policy_arn` | ARN de la política de acceso |

## Integración con Lambdas

Para que las Lambdas puedan leer los secretos:

```hcl
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda.name
  policy_arn = module.secrets.secrets_access_policy_arn
}
```

## Notas

- Los valores de los secretos pueden actualizarse manualmente en AWS Console
- El módulo NO sobrescribe cambios manuales debido a `lifecycle.ignore_changes`
- La ventana de recuperación por defecto es 30 días
- Los secretos se cifran automáticamente en reposo

