use lambda_http::{run, service_fn, Body, Request, Response, Error, RequestExt, RequestPayloadExt};
use serde::{Deserialize, Serialize};
use validator::Validate;
use shared_lib::{init_tracing, success_response, created_response, ApiError, get_client, table_name};
use aws_sdk_dynamodb::types::AttributeValue;
use uuid::Uuid;

#[derive(Debug, Deserialize, Validate)]
struct CreateProfessionalRequest {
    #[validate(length(min = 1, max = 50))]
    tenant_id: String,
    
    #[validate(length(min = 3, max = 100))]
    name: String,
    
    #[validate(email)]
    email: String,
    
    #[serde(default)]
    specialties: Vec<String>,
    
    #[serde(default)]
    schedule: Option<String>, // JSON con horarios
}

#[derive(Debug, Serialize)]
struct Professional {
    id: String,
    tenant_id: String,
    name: String,
    email: String,
    specialties: Vec<String>,
    schedule: String,
    status: String,
    created_at: String,
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
    let result: Result<Response<Body>, ApiError> = (|| async {
        let method = req.method().as_str();
        
        match method {
            "POST" => create_professional(req).await,
            "GET" => list_professionals(req).await,
            _ => Err(ApiError::NotFound("Método no soportado".into()))
        }
    })().await;
    
    match result {
        Ok(resp) => Ok(resp),
        Err(api_err) => Ok(api_err.into_response())
    }
}

async fn create_professional(req: Request) -> Result<Response<Body>, ApiError> {
    let payload = req.payload::<CreateProfessionalRequest>()?
        .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
    
    payload.validate()
        .map_err(|e| ApiError::Validation(format!("{:?}", e)))?;
    
    let prof_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().to_rfc3339();
    
    let client = get_client().await;
    
    client.put_item()
        .table_name(table_name())
        .item("PK", AttributeValue::S(format!("TENANT#{}", payload.tenant_id)))
        .item("SK", AttributeValue::S(format!("PROFESSIONAL#{}", prof_id)))
        .item("GSI1PK", AttributeValue::S(format!("TENANT#{}", payload.tenant_id)))
        .item("GSI1SK", AttributeValue::S(format!("PROFESSIONAL#{}", prof_id)))
        .item("GSI3PK", AttributeValue::S(format!("PROFESSIONAL#{}", prof_id)))
        .item("GSI3SK", AttributeValue::S("METADATA".to_string()))
        .item("id", AttributeValue::S(prof_id.clone()))
        .item("tenantId", AttributeValue::S(payload.tenant_id.clone()))
        .item("name", AttributeValue::S(payload.name.clone()))
        .item("email", AttributeValue::S(payload.email.clone()))
        .item("specialties", AttributeValue::L(
            payload.specialties.iter().map(|s| AttributeValue::S(s.clone())).collect()
        ))
        .item("schedule", AttributeValue::S(payload.schedule.unwrap_or_else(|| "{}".into())))
        .item("status", AttributeValue::S("active".to_string()))
        .item("createdAt", AttributeValue::S(now.clone()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))?;
    
    let professional = Professional {
        id: prof_id,
        tenant_id: payload.tenant_id,
        name: payload.name,
        email: payload.email,
        specialties: payload.specialties,
        schedule: "{}".into(),
        status: "active".into(),
        created_at: now,
    };
    
    created_response(professional)
}

async fn list_professionals(req: Request) -> Result<Response<Body>, ApiError> {
    let tenant_id = req.query_string_parameters_ref()
        .and_then(|params| params.first("tenant_id"))
        .ok_or_else(|| ApiError::Validation("tenant_id requerido".into()))?;
    
    let client = get_client().await;
    
    let result = client.query()
        .table_name(table_name())
        .key_condition_expression("PK = :pk AND begins_with(SK, :sk)")
        .expression_attribute_values(":pk", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .expression_attribute_values(":sk", AttributeValue::S("PROFESSIONAL#".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB query error: {}", e)))?;
    
    let professionals: Vec<Professional> = result.items.unwrap_or_default()
        .iter()
        .map(|item| Professional {
            id: item.get("id").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            tenant_id: item.get("tenantId").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            name: item.get("name").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            email: item.get("email").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            specialties: item.get("specialties").and_then(|v| v.as_l().ok())
                .map(|list| list.iter().filter_map(|v| v.as_s().ok().map(|s| s.to_string())).collect())
                .unwrap_or_default(),
            schedule: item.get("schedule").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_else(|| "{}".into()),
            status: item.get("status").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            created_at: item.get("createdAt").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
        })
        .collect();
    
    success_response(serde_json::json!({"professionals": professionals, "count": professionals.len()}))
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(handler)).await
}


