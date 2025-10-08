use lambda_http::Request;
use serde::Deserialize;
use crate::error::ApiError;
use base64::Engine as _;

#[derive(Debug, Deserialize)]
pub struct JwtClaims {
    pub sub: Option<String>,
    pub email: Option<String>,
    #[serde(rename = "cognito:groups")]
    pub groups: Option<Vec<String>>, // Owner, Admin, Odontólogo, Recepción, Paciente
    pub tenant_id: Option<String>,
    #[serde(rename = "custom:tenant_id")]
    pub custom_tenant_id: Option<String>,
}

fn extract_bearer_token(req: &Request) -> Result<String, ApiError> {
    let auth = req
        .headers()
        .get("authorization")
        .or_else(|| req.headers().get("Authorization"))
        .ok_or_else(|| ApiError::Validation("Falta header Authorization".into()))?;

    let auth_str = auth.to_str().map_err(|_| ApiError::Validation("Header Authorization inválido".into()))?;
    let prefix = "Bearer ";
    if let Some(token) = auth_str.strip_prefix(prefix) {
        Ok(token.to_string())
    } else {
        Err(ApiError::Validation("Formato de Authorization inválido (usar 'Bearer <token>')".into()))
    }
}

pub fn parse_jwt_claims(req: &Request) -> Result<JwtClaims, ApiError> {
    let token = extract_bearer_token(req)?;
    // Formato JWT: header.payload.signature (base64url)
    let mut parts = token.split('.');
    let _header = parts.next().ok_or_else(|| ApiError::Validation("JWT malformado".into()))?;
    let payload_b64 = parts.next().ok_or_else(|| ApiError::Validation("JWT malformado".into()))?;

    let payload_bytes = base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(payload_b64)
        .map_err(|_| ApiError::Validation("Payload JWT inválido".into()))?;

    let claims: JwtClaims = serde_json::from_slice(&payload_bytes)
        .map_err(|_| ApiError::Validation("Claims JWT inválidos".into()))?;

    Ok(claims)
}

pub fn require_tenant(req: &Request) -> Result<String, ApiError> {
    let claims = parse_jwt_claims(req)?;
    if let Some(t) = claims.tenant_id.or(claims.custom_tenant_id) {
        return Ok(t);
    }
    Err(ApiError::Forbidden("Tenant no presente en token".into()))
}


