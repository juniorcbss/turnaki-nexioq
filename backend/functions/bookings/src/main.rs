use lambda_http::{run, service_fn, Body, Request, Response, Error, RequestPayloadExt};
use serde::{Deserialize, Serialize};
use validator::Validate;
use shared_lib::{init_tracing, success_response, created_response, ApiError, get_client, table_name, require_tenant};
use aws_sdk_dynamodb::types::AttributeValue;
use uuid::Uuid;

#[derive(Debug, Deserialize, Validate)]
struct CreateBookingRequest {
    #[validate(length(min = 1, max = 50))]
    tenant_id: String,
    
    #[validate(length(min = 1, max = 50))]
    site_id: String,
    
    #[validate(length(min = 1, max = 50))]
    professional_id: String,
    
    #[validate(length(min = 1, max = 50))]
    treatment_id: String,
    
    start_time: String, // ISO8601
    
    patient_name: String,
    patient_email: String,
}

#[derive(Debug, Serialize)]
struct Booking {
    id: String,
    tenant_id: String,
    site_id: String,
    professional_id: String,
    treatment_id: String,
    start_time: String,
    end_time: String,
    patient_name: String,
    patient_email: String,
    status: String,
    created_at: String,
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
    let result: Result<Response<Body>, ApiError> = (|| async {
        let method = req.method().as_str();
        let path = req.uri().path();
        
        match (method, path) {
            ("POST", "/bookings") => create_booking(req).await,
            ("GET", "/bookings") => list_bookings(req).await,
            ("DELETE", path) if path.starts_with("/bookings/") => cancel_booking(req).await,
            ("PUT", path) if path.starts_with("/bookings/") => update_booking(req).await,
            _ => Err(ApiError::NotFound("Método no soportado".into()))
        }
    })().await;
    
    match result {
        Ok(resp) => Ok(resp),
        Err(api_err) => Ok(api_err.into_response())
    }
}

async fn create_booking(req: Request) -> Result<Response<Body>, ApiError> {
    let payload = req.payload::<CreateBookingRequest>()?
        .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
    
    payload.validate()
        .map_err(|e| ApiError::Validation(format!("{:?}", e)))?;
    
    // Enforce multitenancy: tenant del token debe coincidir con el payload
    let tenant_from_token = require_tenant(&req)?;
    if tenant_from_token != payload.tenant_id {
        return Err(ApiError::Forbidden("tenant_id del payload no coincide con el token".into()));
    }

    let booking_id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().to_rfc3339();
    
    // Parse start_time
    let start = chrono::DateTime::parse_from_rfc3339(&payload.start_time)
        .map_err(|_| ApiError::Validation("start_time inválido (usar ISO8601)".into()))?;
    // Obtener duración y buffer desde el tratamiento
    let treatment_minutes = fetch_treatment_duration_minutes(&tenant_from_token, &payload.treatment_id).await?;
    let buffer_minutes = fetch_treatment_buffer_minutes(&tenant_from_token, &payload.treatment_id).await?;
    let end = start + chrono::Duration::minutes((treatment_minutes + buffer_minutes) as i64);
    
    let client = get_client().await;
    
    // Reserva atómica con ConditionExpression
    // PK=TENANT#tid#SITE#sid#DATE#2025-09-30, SK=SLOT#10:00#prof-123
    let slot_pk = format!("TENANT#{}#SITE#{}#DATE#{}", 
        tenant_from_token, payload.site_id, start.format("%Y-%m-%d"));
    let slot_sk = format!("SLOT#{}#{}", start.format("%H:%M"), payload.professional_id);
    
    let transact_result = client.transact_write_items()
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .put(
                    aws_sdk_dynamodb::types::Put::builder()
                        .table_name(table_name())
                        .item("PK", AttributeValue::S(slot_pk.clone()))
                        .item("SK", AttributeValue::S(slot_sk.clone()))
                        .item("bookingId", AttributeValue::S(booking_id.clone()))
                        .item("status", AttributeValue::S("reserved".to_string()))
                        .item("createdAt", AttributeValue::S(now.clone()))
                        .condition_expression("attribute_not_exists(PK)")
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .put(
                    aws_sdk_dynamodb::types::Put::builder()
                        .table_name(table_name())
                        .item("PK", AttributeValue::S(format!("BOOKING#{}", booking_id)))
                        .item("SK", AttributeValue::S("METADATA".to_string()))
                        .item("GSI1PK", AttributeValue::S(format!("TENANT#{}", tenant_from_token)))
                        .item("GSI1SK", AttributeValue::S(format!("BOOKING#{}", booking_id)))
                        .item("GSI3PK", AttributeValue::S(format!("PROFESSIONAL#{}", payload.professional_id)))
                        .item("GSI3SK", AttributeValue::S(start.to_rfc3339()))
                        .item("id", AttributeValue::S(booking_id.clone()))
                        .item("tenantId", AttributeValue::S(tenant_from_token.clone()))
                        .item("siteId", AttributeValue::S(payload.site_id.clone()))
                        .item("professionalId", AttributeValue::S(payload.professional_id.clone()))
                        .item("treatmentId", AttributeValue::S(payload.treatment_id.clone()))
                        .item("startTime", AttributeValue::S(start.to_rfc3339()))
                        .item("endTime", AttributeValue::S(end.to_rfc3339()))
                        .item("patientName", AttributeValue::S(payload.patient_name.clone()))
                        .item("patientEmail", AttributeValue::S(payload.patient_email.clone()))
                        .item("status", AttributeValue::S("confirmed".to_string()))
                        .item("createdAt", AttributeValue::S(now.clone()))
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .send()
        .await;
    
    match transact_result {
        Ok(_) => {
            tracing::info!(booking_id = %booking_id, "Booking created atomically");
            
            let booking = Booking {
                id: booking_id,
                tenant_id: tenant_from_token,
                site_id: payload.site_id,
                professional_id: payload.professional_id,
                treatment_id: payload.treatment_id,
                start_time: start.to_rfc3339(),
                end_time: end.to_rfc3339(),
                patient_name: payload.patient_name,
                patient_email: payload.patient_email,
                status: "confirmed".into(),
                created_at: now,
            };
            
            created_response(booking)
        }
        Err(e) => {
            if e.to_string().contains("ConditionalCheckFailed") {
                Err(ApiError::Conflict("Slot no disponible (reservado por otro usuario)".into()))
            } else {
                Err(ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))
            }
        }
    }
}

async fn list_bookings(req: Request) -> Result<Response<Body>, ApiError> {
    // Enforce multitenancy desde el token, ignorando tenant_id por query si difiere
    let tenant_id = require_tenant(&req)?;
    
    let client = get_client().await;
    
    let result = client.query()
        .table_name(table_name())
        .index_name("GSI1")
        .key_condition_expression("GSI1PK = :pk")
        .expression_attribute_values(":pk", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB query error: {}", e)))?;
    
    let bookings: Vec<Booking> = result.items.unwrap_or_default()
        .iter()
        .filter_map(|item| {
            Some(Booking {
                id: item.get("id")?.as_s().ok()?.to_string(),
                tenant_id: item.get("tenantId")?.as_s().ok()?.to_string(),
                site_id: item.get("siteId")?.as_s().ok()?.to_string(),
                professional_id: item.get("professionalId")?.as_s().ok()?.to_string(),
                treatment_id: item.get("treatmentId")?.as_s().ok()?.to_string(),
                start_time: item.get("startTime")?.as_s().ok()?.to_string(),
                end_time: item.get("endTime")?.as_s().ok()?.to_string(),
                patient_name: item.get("patientName")?.as_s().ok()?.to_string(),
                patient_email: item.get("patientEmail")?.as_s().ok()?.to_string(),
                status: item.get("status")?.as_s().ok()?.to_string(),
                created_at: item.get("createdAt")?.as_s().ok()?.to_string(),
            })
        })
        .collect();
    
    success_response(serde_json::json!({"bookings": bookings, "count": bookings.len()}))
}

async fn cancel_booking(req: Request) -> Result<Response<Body>, ApiError> {
    let path = req.uri().path();
    let booking_id = path.strip_prefix("/bookings/")
        .ok_or_else(|| ApiError::Validation("ID de booking inválido".into()))?;
    
    let client = get_client().await;
    
    // Primero obtener el booking para conocer el slot
    let get_result = client.get_item()
        .table_name(table_name())
        .key("PK", AttributeValue::S(format!("BOOKING#{}", booking_id)))
        .key("SK", AttributeValue::S("METADATA".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB get error: {}", e)))?;
    
    let item = get_result.item()
        .ok_or_else(|| ApiError::NotFound("Booking no encontrado".into()))?;
    
    let tenant_id = item.get("tenantId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("tenantId no encontrado")))?
        .to_string();

    // Verificar que el tenant del token coincide
    let tenant_from_token = require_tenant(&req)?;
    if tenant_from_token != tenant_id {
        return Err(ApiError::Forbidden("No puedes cancelar reservas de otro tenant".into()));
    }
    
    let site_id = item.get("siteId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("siteId no encontrado")))?;
    
    let professional_id = item.get("professionalId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("professionalId no encontrado")))?;
    
    let start_time = item.get("startTime")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("startTime no encontrado")))?;
    
    let start = chrono::DateTime::parse_from_rfc3339(start_time)
        .map_err(|_| ApiError::Internal(anyhow::anyhow!("startTime inválido")))?;
    
    let slot_pk = format!("TENANT#{}#SITE#{}#DATE#{}", tenant_id, site_id, start.format("%Y-%m-%d"));
    let slot_sk = format!("SLOT#{}#{}", start.format("%H:%M"), professional_id);
    
    // Transacción atómica para cancelar booking y liberar slot
    let now = chrono::Utc::now().to_rfc3339();
    
    let transact_result = client.transact_write_items()
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .update(
                    aws_sdk_dynamodb::types::Update::builder()
                        .table_name(table_name())
                        .key("PK", AttributeValue::S(format!("BOOKING#{}", booking_id)))
                        .key("SK", AttributeValue::S("METADATA".to_string()))
                        .update_expression("SET #status = :cancelled, cancelledAt = :now")
                        .expression_attribute_names("#status", "status")
                        .expression_attribute_values(":cancelled", AttributeValue::S("cancelled".to_string()))
                        .expression_attribute_values(":now", AttributeValue::S(now.clone()))
                        .condition_expression("#status <> :cancelled")
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .delete(
                    aws_sdk_dynamodb::types::Delete::builder()
                        .table_name(table_name())
                        .key("PK", AttributeValue::S(slot_pk))
                        .key("SK", AttributeValue::S(slot_sk))
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .send()
        .await;
    
    match transact_result {
        Ok(_) => {
            tracing::info!(booking_id = %booking_id, "Booking cancelled atomically");
            success_response(serde_json::json!({
                "message": "Booking cancelado exitosamente",
                "booking_id": booking_id,
                "cancelled_at": now
            }))
        }
        Err(e) => {
            if e.to_string().contains("ConditionalCheckFailed") {
                Err(ApiError::Conflict("Booking ya está cancelado".into()))
            } else {
                Err(ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))
            }
        }
    }
}

#[derive(Debug, Deserialize, Validate)]
struct UpdateBookingRequest {
    start_time: String,
}

async fn update_booking(req: Request) -> Result<Response<Body>, ApiError> {
    let path = req.uri().path();
    let booking_id = path.strip_prefix("/bookings/")
        .ok_or_else(|| ApiError::Validation("ID de booking inválido".into()))?;
    
    let payload = req.payload::<UpdateBookingRequest>()?
        .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
    
    payload.validate()
        .map_err(|e| ApiError::Validation(format!("{:?}", e)))?;
    
    let client = get_client().await;
    
    // Primero obtener el booking actual
    let get_result = client.get_item()
        .table_name(table_name())
        .key("PK", AttributeValue::S(format!("BOOKING#{}", booking_id)))
        .key("SK", AttributeValue::S("METADATA".to_string()))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB get error: {}", e)))?;
    
    let item = get_result.item()
        .ok_or_else(|| ApiError::NotFound("Booking no encontrado".into()))?;
    
    let tenant_id = item.get("tenantId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("tenantId no encontrado")))?.to_string();

    // Enforce multitenancy del token
    let tenant_from_token = require_tenant(&req)?;
    if tenant_from_token != tenant_id {
        return Err(ApiError::Forbidden("No puedes reprogramar reservas de otro tenant".into()));
    }
    
    let site_id = item.get("siteId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("siteId no encontrado")))?.to_string();
    
    let professional_id = item.get("professionalId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("professionalId no encontrado")))?.to_string();
    
    let old_start_time = item.get("startTime")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("startTime no encontrado")))?.to_string();
    
    let old_start = chrono::DateTime::parse_from_rfc3339(&old_start_time)
        .map_err(|_| ApiError::Internal(anyhow::anyhow!("startTime inválido")))?;
    
    let new_start = chrono::DateTime::parse_from_rfc3339(&payload.start_time)
        .map_err(|_| ApiError::Validation("start_time inválido (usar ISO8601)".into()))?;
    
    // Calcular nueva duración según el tratamiento
    let treatment_id = item.get("treatmentId")
        .and_then(|v| v.as_s().ok())
        .ok_or_else(|| ApiError::Internal(anyhow::anyhow!("treatmentId no encontrado")))?
        .to_string();
    let treatment_minutes = fetch_treatment_duration_minutes(&tenant_id, &treatment_id).await?;
    let buffer_minutes = fetch_treatment_buffer_minutes(&tenant_id, &treatment_id).await?;
    let new_end = new_start + chrono::Duration::minutes((treatment_minutes + buffer_minutes) as i64);
    
    let old_slot_pk = format!("TENANT#{}#SITE#{}#DATE#{}", tenant_id, site_id, old_start.format("%Y-%m-%d"));
    let old_slot_sk = format!("SLOT#{}#{}", old_start.format("%H:%M"), professional_id);
    
    let new_slot_pk = format!("TENANT#{}#SITE#{}#DATE#{}", tenant_id, site_id, new_start.format("%Y-%m-%d"));
    let new_slot_sk = format!("SLOT#{}#{}", new_start.format("%H:%M"), professional_id);
    
    let now = chrono::Utc::now().to_rfc3339();
    
    // Transacción: liberar slot antiguo, reservar nuevo slot, actualizar booking
    let transact_result = client.transact_write_items()
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .delete(
                    aws_sdk_dynamodb::types::Delete::builder()
                        .table_name(table_name())
                        .key("PK", AttributeValue::S(old_slot_pk))
                        .key("SK", AttributeValue::S(old_slot_sk))
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .put(
                    aws_sdk_dynamodb::types::Put::builder()
                        .table_name(table_name())
                        .item("PK", AttributeValue::S(new_slot_pk))
                        .item("SK", AttributeValue::S(new_slot_sk))
                        .item("bookingId", AttributeValue::S(booking_id.to_string()))
                        .item("status", AttributeValue::S("reserved".to_string()))
                        .item("createdAt", AttributeValue::S(now.clone()))
                        .condition_expression("attribute_not_exists(PK)")
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .transact_items(
            aws_sdk_dynamodb::types::TransactWriteItem::builder()
                .update(
                    aws_sdk_dynamodb::types::Update::builder()
                        .table_name(table_name())
                        .key("PK", AttributeValue::S(format!("BOOKING#{}", booking_id)))
                        .key("SK", AttributeValue::S("METADATA".to_string()))
                        .update_expression("SET startTime = :start, endTime = :end, GSI3SK = :gsi3sk, updatedAt = :now")
                        .expression_attribute_values(":start", AttributeValue::S(new_start.to_rfc3339()))
                        .expression_attribute_values(":end", AttributeValue::S(new_end.to_rfc3339()))
                        .expression_attribute_values(":gsi3sk", AttributeValue::S(new_start.to_rfc3339()))
                        .expression_attribute_values(":now", AttributeValue::S(now.clone()))
                        .build()
                        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
                )
                .build()
        )
        .send()
        .await;
    
    match transact_result {
        Ok(_) => {
            tracing::info!(booking_id = %booking_id, "Booking rescheduled atomically");
            success_response(serde_json::json!({
                "message": "Booking reprogramado exitosamente",
                "booking_id": booking_id,
                "new_start_time": new_start.to_rfc3339(),
                "updated_at": now
            }))
        }
        Err(e) => {
            if e.to_string().contains("ConditionalCheckFailed") {
                Err(ApiError::Conflict("Nuevo slot no disponible".into()))
            } else {
                Err(ApiError::Internal(anyhow::anyhow!("DynamoDB error: {}", e)))
            }
        }
    }
}

async fn fetch_treatment_duration_minutes(tenant_id: &str, treatment_id: &str) -> Result<i64, ApiError> {
    let client = get_client().await;
    let result = client.get_item()
        .table_name(table_name())
        .key("PK", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .key("SK", AttributeValue::S(format!("TREATMENT#{}", treatment_id)))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB get error: {}", e)))?;

    let item = result.item().ok_or_else(|| ApiError::NotFound("Tratamiento no encontrado".into()))?;
    let duration = item.get("durationMinutes")
        .and_then(|v| v.as_n().ok())
        .and_then(|n| n.parse::<i64>().ok())
        .unwrap_or(45);
    Ok(duration)
}

async fn fetch_treatment_buffer_minutes(tenant_id: &str, treatment_id: &str) -> Result<i64, ApiError> {
    let client = get_client().await;
    let result = client.get_item()
        .table_name(table_name())
        .key("PK", AttributeValue::S(format!("TENANT#{}", tenant_id)))
        .key("SK", AttributeValue::S(format!("TREATMENT#{}", treatment_id)))
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("DynamoDB get error: {}", e)))?;

    let item = result.item().ok_or_else(|| ApiError::NotFound("Tratamiento no encontrado".into()))?;
    let buffer = item.get("bufferMinutes")
        .and_then(|v| v.as_n().ok())
        .and_then(|n| n.parse::<i64>().ok())
        .unwrap_or(0);
    Ok(buffer)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(handler)).await
}
