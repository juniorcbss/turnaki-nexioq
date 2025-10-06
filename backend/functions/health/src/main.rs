use lambda_http::{run, service_fn, Body, Error, Request, Response};
use serde_json::json;
use shared_lib::{init_tracing, success_response};

async fn handler(_req: Request) -> Result<Response<Body>, Error> {
    let body = json!({
        "status": "ok",
        "service": "health",
        "timestamp": chrono::Utc::now().to_rfc3339()
    });

    Ok(success_response(body)?)
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

    #[tokio::test]
    async fn test_health_returns_ok() {
        let request = Request::default();
        let response = handler(request).await.unwrap();

        assert_eq!(response.status(), StatusCode::OK);
        assert_eq!(response.headers().get("content-type").unwrap(), "application/json");

        let body: serde_json::Value = serde_json::from_slice(response.body()).unwrap();
        assert_eq!(body["status"], "ok");
        assert_eq!(body["service"], "health");
        assert!(body.get("timestamp").is_some());
    }
}
