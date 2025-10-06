use lambda_runtime::{run, service_fn, LambdaEvent, Error};
use serde::{Deserialize, Serialize};
use aws_sdk_ses::Client;
use shared_lib::init_tracing;

#[derive(Debug, Deserialize)]
struct SqsEvent {
    #[serde(rename = "Records")]
    records: Vec<SqsRecord>,
}

#[derive(Debug, Deserialize)]
struct SqsRecord {
    body: String,
}

#[derive(Debug, Deserialize)]
struct NotificationPayload {
    #[serde(rename = "type")]
    notification_type: String, // "confirmation", "reminder", "cancellation"
    to: Option<String>,
    patient_email: Option<String>,
    patient_name: String,
    booking_id: String,
    appointment_date: Option<String>,
    appointment_time: Option<String>,
    professional_name: Option<String>,
    treatment_name: Option<String>,
    clinic_address: Option<String>,
    hours_before: Option<u32>,
}

#[derive(Debug, Serialize)]
struct Response {
    sent: usize,
    failed: usize,
}

fn get_subject(notification_type: &str) -> String {
    match notification_type {
        "confirmation" => "✅ Cita Confirmada - Turnaki NexioQ".into(),
        "reminder" => "⏰ Recordatorio de Cita - Turnaki NexioQ".into(),
        "cancellation" => "❌ Cita Cancelada - Turnaki NexioQ".into(),
        _ => "Notificación - Turnaki NexioQ".into(),
    }
}

fn render_template(notification: &NotificationPayload) -> String {
    let app_url = std::env::var("APP_URL").unwrap_or_else(|_| "https://turnaki.nexioq.com".into());
    let clinic_email = std::env::var("CLINIC_EMAIL").unwrap_or_else(|_| "contacto@clinica.com".into());
    
    // Template básico en HTML (en producción, cargar desde archivos)
    let template = match notification.notification_type.as_str() {
        "confirmation" => format!(
            r#"<!DOCTYPE html>
<html><body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
<h2 style="color: #0ea5e9;">¡Cita Confirmada!</h2>
<p>Hola <strong>{}</strong>,</p>
<p>Tu cita ha sido confirmada exitosamente:</p>
<ul>
<li>📅 Fecha: {}</li>
<li>🕐 Hora: {}</li>
<li>👨‍⚕️ Profesional: {}</li>
<li>🏥 Tratamiento: {}</li>
<li>📍 Ubicación: {}</li>
</ul>
<p><strong>Código:</strong> {}</p>
<p><a href="{}/my-appointments" style="background: #0ea5e9; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Ver mi Cita</a></p>
<p style="color: #64748b; font-size: 14px;">© 2025 Turnaki NexioQ</p>
</body></html>"#,
            notification.patient_name,
            notification.appointment_date.as_deref().unwrap_or("Por confirmar"),
            notification.appointment_time.as_deref().unwrap_or("Por confirmar"),
            notification.professional_name.as_deref().unwrap_or("Por asignar"),
            notification.treatment_name.as_deref().unwrap_or("Consulta general"),
            notification.clinic_address.as_deref().unwrap_or("Clínica principal"),
            notification.booking_id,
            app_url
        ),
        "reminder" => format!(
            r#"<!DOCTYPE html>
<html><body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
<div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0;">
<h2 style="color: #d97706;">⏰ Tu cita es en {} horas</h2>
</div>
<p>Hola <strong>{}</strong>,</p>
<p>Te recordamos que tienes una cita programada:</p>
<ul>
<li>📅 Fecha: {}</li>
<li>🕐 Hora: {}</li>
<li>👨‍⚕️ Profesional: {}</li>
<li>🏥 Tratamiento: {}</li>
</ul>
<p><strong>💡 Recomendaciones:</strong> Llega 10 minutos antes</p>
<p><a href="{}/my-appointments" style="background: #0ea5e9; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Ver mi Cita</a></p>
<p style="color: #64748b; font-size: 14px;">© 2025 Turnaki NexioQ</p>
</body></html>"#,
            notification.hours_before.unwrap_or(24),
            notification.patient_name,
            notification.appointment_date.as_deref().unwrap_or(""),
            notification.appointment_time.as_deref().unwrap_or(""),
            notification.professional_name.as_deref().unwrap_or(""),
            notification.treatment_name.as_deref().unwrap_or(""),
            app_url
        ),
        "cancellation" => format!(
            r#"<!DOCTYPE html>
<html><body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
<h2 style="color: #ef4444;">Cita Cancelada</h2>
<p>Hola <strong>{}</strong>,</p>
<p>Tu cita ha sido cancelada:</p>
<ul>
<li>📅 Fecha: {}</li>
<li>🕐 Hora: {}</li>
<li>📍 Código: {}</li>
</ul>
<p><a href="{}/booking" style="background: #0ea5e9; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Agendar Nueva Cita</a></p>
<p style="color: #64748b; font-size: 14px;">© 2025 Turnaki NexioQ</p>
</body></html>"#,
            notification.patient_name,
            notification.appointment_date.as_deref().unwrap_or(""),
            notification.appointment_time.as_deref().unwrap_or(""),
            notification.booking_id,
            app_url
        ),
        _ => format!("<p>Notificación para {}</p>", notification.patient_name),
    };
    
    template
}

async fn handler(event: LambdaEvent<SqsEvent>) -> Result<Response, Error> {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let ses_client = Client::new(&config);
    
    let from_email = std::env::var("SES_FROM_EMAIL").unwrap_or_else(|_| "noreply@nexioq.com".into());
    
    let mut sent = 0;
    let mut failed = 0;
    
    for record in event.payload.records {
        match serde_json::from_str::<NotificationPayload>(&record.body) {
            Ok(notification) => {
                let to = notification.patient_email.as_ref()
                    .or(notification.to.as_ref())
                    .ok_or("No recipient email")?;
                
                let subject = get_subject(&notification.notification_type);
                let html_body = render_template(&notification);
                
                let result = ses_client
                    .send_email()
                    .source(&from_email)
                    .destination(
                        aws_sdk_ses::types::Destination::builder()
                            .to_addresses(to)
                            .build()
                    )
                    .message(
                        aws_sdk_ses::types::Message::builder()
                            .subject(
                                aws_sdk_ses::types::Content::builder()
                                    .data(subject)
                                    .build()
                                    .unwrap()
                            )
                            .body(
                                aws_sdk_ses::types::Body::builder()
                                    .html(
                                        aws_sdk_ses::types::Content::builder()
                                            .data(html_body)
                                            .build()
                                            .unwrap()
                                    )
                                    .build()
                            )
                            .build()
                    )
                    .send()
                    .await;
                
                match result {
                    Ok(_) => {
                        tracing::info!(to = %to, notification_type = %notification.notification_type, "Email sent");
                        sent += 1;
                    }
                    Err(e) => {
                        tracing::error!(error = %e, "Failed to send email");
                        failed += 1;
                    }
                }
            }
            Err(e) => {
                tracing::error!(error = %e, "Failed to parse notification");
                failed += 1;
            }
        }
    }
    
    Ok(Response { sent, failed })
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    init_tracing();
    run(service_fn(handler)).await
}
