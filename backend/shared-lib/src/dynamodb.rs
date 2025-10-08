use aws_sdk_dynamodb::Client;
use std::env;

pub async fn get_client() -> Client {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    Client::new(&config)
}

pub fn table_name() -> String {
    env::var("TABLE_NAME").unwrap_or_else(|_| "tk-nq-main".to_string())
}
