use lambda_http::{run, service_fn, Body, Request, Response, Error, RequestPayloadExt};
use serde::{Deserialize, Serialize};
use validator::Validate;
use shared_lib::{init_tracing, success_response, ApiError, get_client, table_name, require_tenant};
use aws_sdk_dynamodb::types::AttributeValue;
use chrono::{DateTime, Utc, Duration as ChronoDuration};

#[derive(Debug, Deserialize, Validate)]
struct AvailabilityRequest {
    #[validate(length(min = 1, max = 50))]
    site_id: String,
    
    #[validate(length(min = 1, max = 50))]
    professional_id: Option<String>,
    
    #[serde(default)]
    date: Option<String>,
}

#[derive(Debug, Serialize)]
struct Slot {
    start: String,
    end: String,
    professional_id: String,
    available: bool,
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
    let result: Result<Response<Body>, ApiError> = (|| async {
        // Multitenancy: extraer tenant desde el token
        let tenant_id = require_tenant(&req)?;

        let payload = req.payload::<AvailabilityRequest>()?
            .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
        
        payload.validate()
            .map_err(|e| ApiError::Validation(format!("{:?}", e)))?;
        
        tracing::info!(
            site_id = %payload.site_id,
            professional_id = ?payload.professional_id,
            "Processing availability request"
        );
        
        // Consultar slots ocupados en DynamoDB
        let date_str = payload.date.clone().unwrap_or_else(|| {
            let tomorrow = Utc::now() + ChronoDuration::days(1);
            tomorrow.format("%Y-%m-%d").to_string()
        });
        let date = date_str.as_str();
        
        let occupied_slots = query_occupied_slots(&tenant_id, &payload.site_id, date).await?;
        
        // Generar slots disponibles (horario 9am-5pm, cada 15 min)
        let mut available_slots = vec![];
        let start_hour = 9;
        let end_hour = 17;
        
        for hour in start_hour..end_hour {
            for minute in [0, 15, 30, 45] {
                let start_time = format!("{}T{:02}:{:02}:00Z", date, hour, minute);
                let end_time_dt = DateTime::parse_from_rfc3339(&start_time)
                    .map_err(|_| ApiError::Internal(anyhow::anyhow!("Date parse error")))?
                    + ChronoDuration::minutes(45);
                
                let prefix = if let Some(pid) = &payload.professional_id {
                    format!("{:02}:{:02}#{}", hour, minute, pid)
                } else {
                    format!("{:02}:{:02}", hour, minute)
                };

                let is_occupied = occupied_slots.iter().any(|slot| slot.starts_with(&prefix));
                
                if !is_occupied {
                    available_slots.push(Slot {
                        start: start_time,
                        end: end_time_dt.to_rfc3339(),
                        professional_id: payload.professional_id.clone().unwrap_or_else(|| "default".into()),
                        available: true,
                    });
                }
            }
        }
        
        let response = serde_json::json!({
            "slots": available_slots,
            "total": available_slots.len(),
            "date": date
        });
        
        success_response(response)
    })().await;
    
    match result {
        Ok(resp) => Ok(resp),
        Err(api_err) => Ok(api_err.into_response())
    }
}

async fn query_occupied_slots(tenant_id: &str, site_id: &str, date: &str) -> Result<Vec<String>, ApiError> {
    let client = get_client().await;
    
    // Query slots reservados para esta fecha alineado con clave de bookings
    let pk = format!("TENANT#{}#SITE#{}#DATE#{}", tenant_id, site_id, date);
    
    let result = client.query()
        .table_name(table_name())
        .key_condition_expression("PK = :pk AND begins_with(SK, :sk)")
        .expression_attribute_values(":pk", AttributeValue::S(pk))
        .expression_attribute_values(":sk", AttributeValue::S("SLOT#".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB query error: {}", e)))?;
    
    let slots = result.items.unwrap_or_default()
        .iter()
        .filter_map(|item| {
            let sk = item.get("SK").and_then(|v| v.as_s().ok())?;
            // SLOT#HH:MM#PROFESSIONAL_ID
            sk.strip_prefix("SLOT#").map(|s| s.to_string())
        })
        .collect();
    
    Ok(slots)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(handler)).await
}
