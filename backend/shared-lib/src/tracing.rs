use tracing_subscriber::{fmt, EnvFilter};

pub fn init_tracing() {
    fmt()
        .json()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .with_target(true)
        .with_current_span(false)
        .with_file(false)
        .with_line_number(false)
        .init();
}
