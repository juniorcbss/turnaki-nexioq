use lambda_http::ext::PayloadError;
use lambda_http::{http::StatusCode, Body, Response};
use serde_json::json;
use uuid::Uuid;

#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Validación fallida: {0}")]
    Validation(String),

    #[error("Recurso no encontrado: {0}")]
    NotFound(String),

    #[error("Conflicto: {0}")]
    Conflict(String),

    #[error("Prohibido: {0}")]
    Forbidden(String),

    #[error("Error interno: {0}")]
    Internal(#[from] anyhow::Error),
}

impl ApiError {
    pub fn into_response(self) -> Response<Body> {
        let cid = Uuid::new_v4().to_string();
        let (status, message) = match self {
            ApiError::Validation(msg) => (StatusCode::BAD_REQUEST, msg),
            ApiError::NotFound(msg) => (StatusCode::NOT_FOUND, msg),
            ApiError::Conflict(msg) => (StatusCode::CONFLICT, msg),
            ApiError::Forbidden(msg) => (StatusCode::FORBIDDEN, msg),
            ApiError::Internal(err) => {
                tracing::error!(error = %err, "Internal error");
                (StatusCode::INTERNAL_SERVER_ERROR, "Error interno del servidor".to_string())
            }
        };

        Response::builder()
            .status(status)
            .header("content-type", "application/json")
            .header("x-content-type-options", "nosniff")
            .header("cache-control", "no-store")
            .header("x-correlation-id", cid)
            .body(json!({"error": message, "status": status.as_u16()}).to_string().into())
            .unwrap()
    }
}

impl From<serde_json::Error> for ApiError {
    fn from(err: serde_json::Error) -> Self {
        ApiError::Internal(err.into())
    }
}

impl From<PayloadError> for ApiError {
    fn from(err: PayloadError) -> Self {
        ApiError::Validation(format!("Error parseando payload: {}", err))
    }
}
