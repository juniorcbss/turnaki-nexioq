use lambda_runtime::{run, service_fn, LambdaEvent, Error};
use serde::{Deserialize, Serialize};
use aws_sdk_ses::Client;
use shared_lib::init_tracing;
use std::fs;
use std::path::Path;
use serde_json::Value;

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
    clinic_email: Option<String>,
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
    let templates_dir = std::env::var("TEMPLATES_DIR")
        .unwrap_or_else(|_| "/var/task/templates".into());

    let template_name = match notification.notification_type.as_str() {
        "confirmation" => "booking-confirmation.html",
        "reminder" => "booking-reminder.html",
        "cancellation" => "booking-cancelled.html",
        _ => "booking-confirmation.html",
    };

    let path = Path::new(&templates_dir).join(template_name);
    let Ok(html) = fs::read_to_string(&path) else {
        return format!("<p>Notificación para {}</p>", notification.patient_name);
    };

    let manage_booking_url = format!("{}/my-appointments", app_url);
    let booking_url = format!("{}/booking", app_url);

    let mut output = html
        .replace("{{patient_name}}", notification.patient_name.as_str())
        .replace("{{appointment_date}}", notification.appointment_date.as_deref().unwrap_or(""))
        .replace("{{appointment_time}}", notification.appointment_time.as_deref().unwrap_or(""))
        .replace("{{professional_name}}", notification.professional_name.as_deref().unwrap_or(""))
        .replace("{{treatment_name}}", notification.treatment_name.as_deref().unwrap_or(""))
        .replace("{{clinic_address}}", notification.clinic_address.as_deref().unwrap_or(""))
        .replace("{{booking_id}}", notification.booking_id.as_str())
        .replace("{{manage_booking_url}}", manage_booking_url.as_str())
        .replace("{{booking_url}}", booking_url.as_str())
        .replace("{{app_url}}", app_url.as_str());

    if let Some(hours) = notification.hours_before {
        output = output.replace("{{hours_before}}", &hours.to_string());
    }
    let clinic_email = notification.clinic_email.as_deref().unwrap_or("soporte@nexioq.com");
    output = output.replace("{{clinic_email}}", clinic_email);

    output
}

async fn handler(event: LambdaEvent<Value>) -> Result<Response, Error> {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let ses_client = Client::new(&config);
    
    let from_email = std::env::var("SES_FROM_EMAIL").unwrap_or_else(|_| "noreply@nexioq.com".into());
    
    let mut sent = 0;
    let mut failed = 0;
    
    // Si el evento tiene Records => SQS. Si no, intentamos parsear payload directo
    if event.payload.get("Records").is_some() {
        let sqs: SqsEvent = serde_json::from_value(event.payload)
            .map_err(|e| lambda_runtime::Error::from(e.to_string()))?;
        for record in sqs.records {
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
                        Ok(_) => { tracing::info!(to = %to, notification_type = %notification.notification_type, "Email sent"); sent += 1; }
                        Err(e) => { tracing::error!(error = %e, "Failed to send email"); failed += 1; }
                    }
                }
                Err(e) => {
                    tracing::error!(error = %e, "Failed to parse notification");
                    failed += 1;
                }
            }
        }
    } else {
        match serde_json::from_value::<NotificationPayload>(event.payload) {
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
                    Ok(_) => { tracing::info!(to = %to, notification_type = %notification.notification_type, "Email sent"); sent += 1; }
                    Err(e) => { tracing::error!(error = %e, "Failed to send email"); failed += 1; }
                }
            }
            Err(e) => {
                tracing::error!(error = %e, "Failed to parse direct notification payload");
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
