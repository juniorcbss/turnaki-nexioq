#[tokio::test]
async fn health_returns_expected_headers_and_body() {
    let base = std::env::var("API_BASE_URL").unwrap_or_else(|_| "https://mqp7tk0dkh.execute-api.us-east-1.amazonaws.com".to_string());
    let url = format!("{}/health", base);
    let res = reqwest::get(url).await.unwrap();
    assert!(res.status().is_success());
    let headers = res.headers();
    assert_eq!(headers.get("x-content-type-options").unwrap(), "nosniff");
    let json: serde_json::Value = res.json().await.unwrap();
    assert!(json.get("service").is_some());
    assert!(json.get("status").is_some());
}


