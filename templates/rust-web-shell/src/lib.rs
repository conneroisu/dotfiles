pub mod handlers;
pub mod models;

use axum::{
    Router,
    http::StatusCode,
    routing::{get, post},
};
use sqlx::SqlitePool;
use tower_http::{cors::CorsLayer, trace::TraceLayer};
use tower_sessions::cookie::time::Duration;
use tower_sessions::{Expiry, MemoryStore, SessionManagerLayer};

pub async fn create_app(pool: SqlitePool) -> Router {
    // Create session store
    let session_store = MemoryStore::default();
    let session_layer = SessionManagerLayer::new(session_store)
        .with_secure(false)
        .with_expiry(Expiry::OnInactivity(Duration::weeks(1))); // 7 days

    Router::new()
        // Pages
        .route("/", get(handlers::show_index))
        .route("/login", get(handlers::show_login))
        .route("/signup", get(handlers::show_signup))
        .route("/dashboard", get(handlers::show_dashboard))
        // Auth endpoints
        .route("/login", post(handlers::handle_login))
        .route("/signup", post(handlers::handle_signup))
        .route("/logout", post(handlers::handle_logout))
        // Fallback for 404
        .fallback(fallback_handler)
        // Middleware
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive())
        .layer(session_layer)
        .with_state(pool)
}

async fn fallback_handler() -> (StatusCode, &'static str) {
    (StatusCode::NOT_FOUND, "Not Found")
}

pub async fn setup_database(database_url: &str) -> Result<SqlitePool, sqlx::Error> {
    let pool = SqlitePool::connect(database_url).await?;

    // Run migrations
    sqlx::migrate!("./migrations").run(&pool).await?;

    Ok(pool)
}
