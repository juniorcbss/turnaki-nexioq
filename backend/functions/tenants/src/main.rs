use lambda_http::{run, service_fn, Body, Request, Response, Error, RequestPayloadExt};
use serde::{Deserialize, Serialize};
use validator::Validate;
use shared_lib::{init_tracing, success_response, created_response, ApiError, get_client, table_name};
use aws_sdk_dynamodb::types::AttributeValue;
use uuid::Uuid;

#[derive(Debug, Deserialize, Validate)]
struct CreateTenantRequest {
    #[validate(length(min = 3, max = 100))]
    name: String,
    
    #[validate(email)]
    contact_email: String,
    
    #[serde(default)]
    timezone: Option<String>,
}

#[derive(Debug, Serialize)]
struct Tenant {
    id: String,
    name: String,
    contact_email: String,
    timezone: String,
    created_at: String,
    status: String,
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
    let result: Result<Response<Body>, ApiError> = (|| async {
        let method = req.method().as_str();
        let path = req.uri().path();
        
        match (method, path) {
            ("POST", "/tenants") => create_tenant(req).await,
            ("GET", path) if path.starts_with("/tenants/") => {
                let id = path.strip_prefix("/tenants/").unwrap();
                get_tenant(id).await
            }
            _ => Err(ApiError::NotFound("Ruta no encontrada".into()))
        }
    })().await;
    
    match result {
        Ok(resp) => Ok(resp),
        Err(api_err) => Ok(api_err.into_response())
    }
}

async fn create_tenant(req: Request) -> Result<Response<Body>, ApiError> {
    let payload = req.payload::<CreateTenantRequest>()?
        .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
    
    payload.validate()
        .map_err(|e| ApiError::Validation(format!("{:?}", e)))?;
    
    let tenant_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().to_rfc3339();
    
    let client = get_client().await;
    
    client.put_item()
        .table_name(table_name())
        .item("PK", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .item("SK", AttributeValue::S("METADATA".to_string()))
        .item("GSI1PK", AttributeValue::S("TENANT".to_string()))
        .item("GSI1SK", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .item("id", AttributeValue::S(tenant_id.clone()))
        .item("name", AttributeValue::S(payload.name.clone()))
        .item("contactEmail", AttributeValue::S(payload.contact_email.clone()))
        .item("timezone", AttributeValue::S(payload.timezone.clone().unwrap_or_else(|| "America/Bogota".into())))
        .item("createdAt", AttributeValue::S(now.clone()))
        .item("status", AttributeValue::S("active".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))?;
    
    tracing::info!(tenant_id = %tenant_id, "Tenant created");
    
    let tenant = Tenant {
        id: tenant_id,
        name: payload.name,
        contact_email: payload.contact_email,
        timezone: payload.timezone.unwrap_or_else(|| "America/Bogota".into()),
        created_at: now,
        status: "active".into(),
    };
    
    created_response(tenant)
}

async fn get_tenant(id: &str) -> Result<Response<Body>, ApiError> {
    let client = get_client().await;
    
    let result = client.get_item()
        .table_name(table_name())
        .key("PK", AttributeValue::S(format!("TENANT#{}", id)))
        .key("SK", AttributeValue::S("METADATA".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))?;
    
    if let Some(item) = result.item {
        let tenant = Tenant {
            id: item.get("id").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            name: item.get("name").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            contact_email: item.get("contactEmail").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            timezone: item.get("timezone").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_else(|| "UTC".into()),
            created_at: item.get("createdAt").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            status: item.get("status").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
        };
        success_response(tenant)
    } else {
        Err(ApiError::NotFound(format!("Tenant {} no encontrado", id)))
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(handler)).await
}

#[cfg(test)]
mod tests {
    use super::*;
    use lambda_http::http::StatusCode;
    use serde_json::json;

    #[tokio::test]
    async fn test_create_tenant_validates_email() {
        let body = json!({
            "name": "Clínica Test",
            "contact_email": "invalid-email",
            "timezone": "America/Bogota"
        }).to_string();

        let mut request = Request::new(Body::from(body));
        *request.method_mut() = lambda_http::http::Method::POST;
        *request.uri_mut() = "/tenants".parse().unwrap();
        request.headers_mut().insert("content-type", "application/json".parse().unwrap());

        let response = handler(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::BAD_REQUEST);

        let body: serde_json::Value = serde_json::from_slice(response.body()).unwrap();
        assert!(body.get("error").is_some());
    }

    #[tokio::test]
    async fn test_get_tenant_not_found_returns_404() {
        if std::env::var("CI").is_ok() {
            // En CI no hay DynamoDB disponible; evitamos depender de AWS en este test.
            return;
        }
        let mut request = Request::new(Body::Empty);
        *request.method_mut() = lambda_http::http::Method::GET;
        *request.uri_mut() = "/tenants/non-existent-id".parse().unwrap();

        let response = handler(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::NOT_FOUND);
    }
}
