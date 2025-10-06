use lambda_http::{run, service_fn, Body, Request, Response, Error, RequestExt, RequestPayloadExt};
use serde::{Deserialize, Serialize};
use validator::Validate;
use shared_lib::{init_tracing, success_response, created_response, ApiError, get_client, table_name};
use aws_sdk_dynamodb::types::AttributeValue;
use uuid::Uuid;

#[derive(Debug, Deserialize, Validate)]
struct CreateTreatmentRequest {
    #[validate(length(min = 1, max = 50))]
    tenant_id: String,
    
    #[validate(length(min = 3, max = 100))]
    name: String,
    
    #[validate(range(min = 5, max = 480))]
    duration_minutes: i32,
    
    #[serde(default)]
    buffer_minutes: Option<i32>,
    
    #[serde(default)]
    price: Option<f64>,
}

#[derive(Debug, Serialize)]
struct Treatment {
    id: String,
    tenant_id: String,
    name: String,
    duration_minutes: i32,
    buffer_minutes: i32,
    price: f64,
    created_at: String,
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
    let result: Result<Response<Body>, ApiError> = (|| async {
        let method = req.method().as_str();
        
        match method {
            "POST" => create_treatment(req).await,
            "GET" => list_treatments(req).await,
            _ => Err(ApiError::NotFound("Método no soportado".into()))
        }
    })().await;
    
    match result {
        Ok(resp) => Ok(resp),
        Err(api_err) => Ok(api_err.into_response())
    }
}

async fn create_treatment(req: Request) -> Result<Response<Body>, ApiError> {
    let payload = req.payload::<CreateTreatmentRequest>()?
        .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
    
    payload.validate()
        .map_err(|e| ApiError::Validation(format!("{:?}", e)))?;
    
    let treatment_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().to_rfc3339();
    
    let client = get_client().await;
    
    client.put_item()
        .table_name(table_name())
        .item("PK", AttributeValue::S(format!("TENANT#{}", payload.tenant_id)))
        .item("SK", AttributeValue::S(format!("TREATMENT#{}", treatment_id)))
        .item("GSI1PK", AttributeValue::S(format!("TENANT#{}", payload.tenant_id)))
        .item("GSI1SK", AttributeValue::S(format!("TREATMENT#{}", treatment_id)))
        .item("id", AttributeValue::S(treatment_id.clone()))
        .item("tenantId", AttributeValue::S(payload.tenant_id.clone()))
        .item("name", AttributeValue::S(payload.name.clone()))
        .item("durationMinutes", AttributeValue::N(payload.duration_minutes.to_string()))
        .item("bufferMinutes", AttributeValue::N(payload.buffer_minutes.unwrap_or(0).to_string()))
        .item("price", AttributeValue::N(payload.price.unwrap_or(0.0).to_string()))
        .item("createdAt", AttributeValue::S(now.clone()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))?;
    
    let treatment = Treatment {
        id: treatment_id,
        tenant_id: payload.tenant_id,
        name: payload.name,
        duration_minutes: payload.duration_minutes,
        buffer_minutes: payload.buffer_minutes.unwrap_or(0),
        price: payload.price.unwrap_or(0.0),
        created_at: now,
    };
    
    created_response(treatment)
}

async fn list_treatments(req: Request) -> Result<Response<Body>, ApiError> {
    let tenant_id = req.query_string_parameters_ref()
        .and_then(|params| params.first("tenant_id"))
        .ok_or_else(|| ApiError::Validation("tenant_id requerido".into()))?;
    
    let client = get_client().await;
    
    let result = client.query()
        .table_name(table_name())
        .key_condition_expression("PK = :pk AND begins_with(SK, :sk)")
        .expression_attribute_values(":pk", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .expression_attribute_values(":sk", AttributeValue::S("TREATMENT#".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))?;
    
    let treatments: Vec<Treatment> = result.items.unwrap_or_default()
        .iter()
        .map(|item| Treatment {
            id: item.get("id").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            tenant_id: item.get("tenantId").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            name: item.get("name").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
            duration_minutes: item.get("durationMinutes").and_then(|v| v.as_n().ok()).and_then(|n| n.parse().ok()).unwrap_or(30),
            buffer_minutes: item.get("bufferMinutes").and_then(|v| v.as_n().ok()).and_then(|n| n.parse().ok()).unwrap_or(0),
            price: item.get("price").and_then(|v| v.as_n().ok()).and_then(|n| n.parse().ok()).unwrap_or(0.0),
            created_at: item.get("createdAt").and_then(|v| v.as_s().ok()).map(|s| s.to_string()).unwrap_or_default(),
        })
        .collect();
    
    success_response(serde_json::json!({"treatments": treatments, "count": treatments.len()}))
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(handler)).await
}
