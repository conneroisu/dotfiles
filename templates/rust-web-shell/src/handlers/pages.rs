use crate::handlers::auth::{FlashMessage, get_user_from_session};
use crate::models::UserResponse;
use askama::Template;
use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse, Response},
};
use sqlx::SqlitePool;
use tower_sessions::Session;

#[derive(Template)]
#[template(path = "index.html")]
struct IndexTemplate {
    css: String,
    js: String,
    user: Option<UserResponse>,
    flash_messages: Vec<FlashMessage>,
}

// Helper function to get assets
fn get_assets() -> (String, String) {
    let css = include_str!(concat!(env!("OUT_DIR"), "/output.css"));
    let js = include_str!(concat!(env!("OUT_DIR"), "/index.js"));
    (css.to_string(), js.to_string())
}

pub async fn show_index(
    session: Session,
    State(pool): State<SqlitePool>,
) -> Result<Html<String>, Response> {
    let (css, js) = get_assets();
    let user = get_user_from_session(&session, &pool).await;

    let template = IndexTemplate {
        css,
        js,
        user,
        flash_messages: Vec::new(),
    };

    match template.render() {
        Ok(html) => Ok(Html(html)),
        Err(e) => {
            tracing::error!("Template render error: {}", e);
            Err((StatusCode::INTERNAL_SERVER_ERROR, "Template error").into_response())
        }
    }
}
