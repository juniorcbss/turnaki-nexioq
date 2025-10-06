# Módulo Cognito - Autenticación y Autorización

## Descripción

Este módulo crea un User Pool de AWS Cognito completo con dominio Hosted UI, client application y atributos personalizados para multi-tenancy.

## Características

- ✅ User Pool con autenticación por email
- ✅ Políticas de contraseña robustas
- ✅ Auto-verificación de email
- ✅ Dominio Hosted UI para OAuth
- ✅ Client configurado para OAuth 2.0
- ✅ Atributos custom: `tenant_id` y `role`
- ✅ Recuperación de cuenta por email
- ✅ Tokens JWT con validez configurable

## Uso

```hcl
module "cognito" {
  source = "../../modules/cognito"

  project_name = "turnaki-nexioq"
  environment  = "dev"
  
  callback_urls = [
    "http://localhost:5173/auth",
    "https://dev.turnaki.nexioq.com/auth"
  ]
  
  logout_urls = [
    "http://localhost:5173",
    "https://dev.turnaki.nexioq.com"
  ]

  tags = {
    ManagedBy = "Terraform"
    Module    = "Cognito"
  }
}
```

## Variables

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_name` | string | Nombre del proyecto | - | ✅ |
| `environment` | string | Ambiente (dev, qas, prd) | - | ✅ |
| `callback_urls` | list(string) | URLs de callback OAuth | - | ✅ |
| `logout_urls` | list(string) | URLs de logout OAuth | - | ✅ |
| `tags` | map(string) | Tags adicionales | `{}` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `user_pool_id` | ID del User Pool |
| `user_pool_arn` | ARN del User Pool |
| `user_pool_endpoint` | Endpoint del User Pool |
| `client_id` | ID del App Client |
| `domain` | Dominio de Cognito |
| `issuer` | URL del issuer para JWT |

## Configuración de Contraseñas

```
- Mínimo 8 caracteres
- Al menos 1 mayúscula
- Al menos 1 minúscula
- Al menos 1 número
- Al menos 1 símbolo
- Contraseñas temporales válidas por 7 días
```

## Atributos Custom

### tenant_id
- **Tipo**: String
- **Mutable**: Sí
- **Uso**: Asociar usuario con tenant en arquitectura multi-tenant

### role
- **Tipo**: String
- **Mutable**: Sí
- **Uso**: Rol del usuario (admin, professional, patient)
- **Valores**: `admin`, `professional`, `patient`

## Flujo OAuth 2.0

### 1. Authorization Code Flow

```
1. Usuario → Cognito Hosted UI
2. Login exitoso → Callback URL + código
3. Frontend intercambia código por tokens
4. Frontend usa tokens en API calls
```

### 2. Tokens Generados

| Token | Validez | Uso |
|-------|---------|-----|
| Access Token | 1 hora | Autorización en API Gateway |
| ID Token | 1 hora | Información del usuario |
| Refresh Token | 30 días | Renovar access/id tokens |

## Ejemplo Completo

```hcl
module "auth" {
  source = "../../modules/cognito"

  project_name = "turnaki-nexioq"
  environment  = "prd"
  
  callback_urls = [
    "https://turnaki.nexioq.com/auth",
    "https://app.turnaki.nexioq.com/auth"
  ]
  
  logout_urls = [
    "https://turnaki.nexioq.com",
    "https://app.turnaki.nexioq.com"
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Usar en API Gateway
module "api" {
  source = "../../modules/api-gateway"
  
  # ... otras variables
  cognito_client_id = module.auth.client_id
  cognito_issuer    = module.auth.issuer
}

# Output para frontend
output "cognito_config" {
  value = {
    user_pool_id = module.auth.user_pool_id
    client_id    = module.auth.client_id
    domain       = "${module.auth.domain}.auth.us-east-1.amazoncognito.com"
  }
}
```

## URLs Importantes

### Hosted UI
```
https://{domain}.auth.{region}.amazoncognito.com/login?client_id={client_id}&response_type=code&redirect_uri={callback_url}
```

### Logout
```
https://{domain}.auth.{region}.amazoncognito.com/logout?client_id={client_id}&logout_uri={logout_url}
```

## Integración con Frontend

```typescript
// Configuración
const cognitoConfig = {
  userPoolId: 'us-east-1_XXXXXXXXX',
  clientId: 'abcdefghijklmnopqrstuvwxyz',
  domain: 'turnaki-nexioq-dev-auth.auth.us-east-1.amazoncognito.com'
};

// Login
window.location.href = `https://${cognitoConfig.domain}/login?client_id=${cognitoConfig.clientId}&response_type=code&redirect_uri=${callbackUrl}`;

// Intercambiar código por tokens
const response = await fetch(`https://${cognitoConfig.domain}/oauth2/token`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: cognitoConfig.clientId,
    code: authorizationCode,
    redirect_uri: callbackUrl
  })
});

const tokens = await response.json();
// tokens.access_token, tokens.id_token, tokens.refresh_token
```

## Convenciones de Nombres

```
User Pool: {project_name}-{environment}-users
Domain: {project_name}-{environment}-auth
Client: {project_name}-{environment}-client
```

**Ejemplos**:
- `turnaki-nexioq-dev-users`
- `turnaki-nexioq-dev-auth`
- `turnaki-nexioq-dev-client`

## Costos Estimados

### MAU (Monthly Active Users)
- **0-50,000 usuarios**: Gratis
- **50,000-100,000**: $0.0055/usuario

### Advanced Security (opcional)
- **Detección de riesgos**: $0.05/usuario

**Ejemplo**: 1,000 usuarios activos/mes = GRATIS

## Notas de Seguridad

- ✅ Contraseñas nunca almacenadas en texto plano
- ✅ MFA disponible (no habilitado por defecto)
- ✅ Tokens JWT firmados
- ✅ HTTPS obligatorio
- ⚠️ Habilitar MFA en producción
- ⚠️ Configurar WAF para Hosted UI en PRD

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0

## Mantenimiento

Actualizado: Octubre 2025  
Versión: 1.0.0