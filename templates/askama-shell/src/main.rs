use rust_web_shell::{create_app, setup_database};
use std::env;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| {
                "rust_web_shell=debug,tower_http=debug,axum::rejection=trace".into()
            }),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load environment variables
    dotenvy::dotenv().ok();

    // Get configuration from environment
    let database_url = env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite:app.db".to_string());

    let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());

    let port = env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse::<u16>()
        .expect("PORT must be a valid number");

    // Set up database
    tracing::info!("Connecting to database: {}", database_url);
    let pool = setup_database(&database_url).await?;
    tracing::info!("Database connected and migrations applied");

    // Create the application
    let app = create_app(pool).await;

    // Create the listener
    let listener = tokio::net::TcpListener::bind(format!("{}:{}", host, port)).await?;

    tracing::info!(
        "🦀 Rust Web Shell server starting on http://{}:{}",
        host,
        port
    );
    tracing::info!("📱 Dashboard: http://{}:{}/dashboard", host, port);
    tracing::info!("🔐 Login: http://{}:{}/login", host, port);
    tracing::info!("📝 Signup: http://{}:{}/signup", host, port);

    // Start the server
    axum::serve(listener, app).await?;

    Ok(())
}
