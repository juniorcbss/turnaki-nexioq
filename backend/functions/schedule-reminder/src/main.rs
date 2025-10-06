use lambda_http::{run, service_fn, Body, Request, Response, Error, RequestPayloadExt};
use serde::{Deserialize, Serialize};
use shared_lib::{init_tracing, success_response, ApiError};
use aws_sdk_scheduler::types::{FlexibleTimeWindow, FlexibleTimeWindowMode, Target};
use aws_sdk_scheduler::Client as SchedulerClient;

#[derive(Debug, Deserialize)]
struct ScheduleReminderRequest {
  booking_id: String,
  appointment_time: String, // ISO8601
  patient_email: String,
  patient_name: String,
}

#[derive(Debug, Serialize)]
struct ScheduleReminderResponse {
  message: String,
  schedule_name: String,
  reminder_times: Vec<String>,
}

async fn handler(req: Request) -> Result<Response<Body>, Error> {
  let result: Result<Response<Body>, ApiError> = (|| async {
    schedule_reminder(req).await
  })().await;
  
  match result {
    Ok(resp) => Ok(resp),
    Err(api_err) => Ok(api_err.into_response())
  }
}

async fn schedule_reminder(req: Request) -> Result<Response<Body>, ApiError> {
  let payload = req.payload::<ScheduleReminderRequest>()?
    .ok_or_else(|| ApiError::Validation("Body vacío".into()))?;
  
  let appointment_time = chrono::DateTime::parse_from_rfc3339(&payload.appointment_time)
    .map_err(|_| ApiError::Validation("appointment_time inválido (usar ISO8601)".into()))?;
  
  // Calcular tiempos de recordatorio: T-24h y T-2h
  let reminder_24h = appointment_time - chrono::Duration::hours(24);
  let reminder_2h = appointment_time - chrono::Duration::hours(2);
  
  let config = aws_config::load_from_env().await;
  let scheduler_client = SchedulerClient::new(&config);
  
  let role_arn = std::env::var("SCHEDULER_ROLE_ARN")
    .map_err(|_| ApiError::Internal(anyhow::anyhow!("SCHEDULER_ROLE_ARN no configurado")))?;
  
  let lambda_arn = std::env::var("NOTIFICATION_LAMBDA_ARN")
    .map_err(|_| ApiError::Internal(anyhow::anyhow!("NOTIFICATION_LAMBDA_ARN no configurado")))?;
  
  // Crear schedule para recordatorio 24h
  let schedule_name_24h = format!("booking-{}-24h", payload.booking_id);
  
  let payload_24h = serde_json::json!({
    "type": "reminder",
    "booking_id": payload.booking_id,
    "patient_email": payload.patient_email,
    "patient_name": payload.patient_name,
    "hours_before": 24
  });
  
  scheduler_client
    .create_schedule()
    .name(&schedule_name_24h)
    .schedule_expression(format!("at({})", reminder_24h.format("%Y-%m-%dT%H:%M:%S")))
    .flexible_time_window(
      FlexibleTimeWindow::builder()
        .mode(FlexibleTimeWindowMode::Off)
        .build()
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
    )
    .target(
      Target::builder()
        .arn(&lambda_arn)
        .role_arn(&role_arn)
        .input(payload_24h.to_string())
        .build()
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
    )
    .send()
    .await
    .map_err(|e| ApiError::Internal(anyhow::anyhow!("Scheduler error: {}", e)))?;
  
  tracing::info!(schedule_name = %schedule_name_24h, "24h reminder scheduled");
  
  // Crear schedule para recordatorio 2h
  let schedule_name_2h = format!("booking-{}-2h", payload.booking_id);
  
  let payload_2h = serde_json::json!({
    "type": "reminder",
    "booking_id": payload.booking_id,
    "patient_email": payload.patient_email,
    "patient_name": payload.patient_name,
    "hours_before": 2
  });
  
  scheduler_client
    .create_schedule()
    .name(&schedule_name_2h)
    .schedule_expression(format!("at({})", reminder_2h.format("%Y-%m-%dT%H:%M:%S")))
    .flexible_time_window(
      FlexibleTimeWindow::builder()
        .mode(FlexibleTimeWindowMode::Off)
        .build()
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
    )
    .target(
      Target::builder()
        .arn(&lambda_arn)
        .role_arn(&role_arn)
        .input(payload_2h.to_string())
        .build()
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Build error: {}", e)))?
    )
    .send()
    .await
    .map_err(|e| ApiError::Internal(anyhow::anyhow!("Scheduler error: {}", e)))?;
  
  tracing::info!(schedule_name = %schedule_name_2h, "2h reminder scheduled");
  
  let response = ScheduleReminderResponse {
    message: "Recordatorios programados exitosamente".into(),
    schedule_name: schedule_name_24h,
    reminder_times: vec![
      reminder_24h.to_rfc3339(),
      reminder_2h.to_rfc3339(),
    ],
  };
  
  success_response(response)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
  init_tracing();
  run(service_fn(handler)).await
}
