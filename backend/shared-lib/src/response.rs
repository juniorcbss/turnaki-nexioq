use lambda_http::{http::StatusCode, Body, Response};
use serde::Serialize;
use serde_json;
use uuid::Uuid;

use crate::error::ApiError;

pub fn success_response<T: Serialize>(data: T) -> Result<Response<Body>, ApiError> {
    let body = serde_json::to_string(&data)?;
    let cid = Uuid::new_v4().to_string();

    Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .header("x-content-type-options", "nosniff")
        .header("cache-control", "no-store")
        .header("x-correlation-id", cid)
        .body(body.into())
        .map_err(|e| ApiError::Internal(e.into()))
}

pub fn created_response<T: Serialize>(data: T) -> Result<Response<Body>, ApiError> {
    let body = serde_json::to_string(&data)?;
    let cid = Uuid::new_v4().to_string();

    Response::builder()
        .status(StatusCode::CREATED)
        .header("content-type", "application/json")
        .header("x-content-type-options", "nosniff")
        .header("x-correlation-id", cid)
        .body(body.into())
        .map_err(|e| ApiError::Internal(e.into()))
}
