use crate::handlers::auth::{get_user_from_session, FlashMessage};
use crate::models::UserResponse;
use askama::Template;
use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse, Redirect, Response},
};
use tower_sessions::Session;
use sqlx::SqlitePool;

#[derive(Template)]
#[template(path = "dashboard.html")]
struct DashboardTemplate {
    css: String,
    js: String,
    user: Option<UserResponse>,
    dashboard_user: DashboardUser,
    flash_messages: Vec<FlashMessage>,
}

#[derive(Debug)]
struct DashboardUser {
    pub id: String,
    pub email: String,
    pub username: String,
    pub email_verified: bool,
    pub created_at_formatted: String,
    pub updated_at_formatted: String,
    pub created_at_full: String,
    pub updated_at_full: String,
}

// Helper function to get assets
fn get_assets() -> (String, String) {
    let css = include_str!(concat!(env!("OUT_DIR"), "/output.css"));
    let js = include_str!(concat!(env!("OUT_DIR"), "/index.js"));
    (css.to_string(), js.to_string())
}

pub async fn show_dashboard(
    session: Session,
    State(pool): State<SqlitePool>,
) -> Result<Html<String>, Response> {
    let (css, js) = get_assets();
    
    // Get user from session
    let user_response = match get_user_from_session(&session, &pool).await {
        Some(user) => user,
        None => {
            // User not logged in, redirect to login
            return Err(Redirect::to("/login").into_response());
        }
    };
    
    // Convert to dashboard user with formatted dates
    let dashboard_user = DashboardUser {
        id: user_response.id.clone(),
        email: user_response.email.clone(),
        username: user_response.username.clone(),
        email_verified: user_response.email_verified,
        created_at_formatted: user_response.created_at.format("%b %d, %Y").to_string(),
        updated_at_formatted: user_response.created_at.format("%b %d, %Y").to_string(),
        created_at_full: user_response.created_at.format("%b %d, %Y at %I:%M %p").to_string(),
        updated_at_full: user_response.created_at.format("%b %d, %Y at %I:%M %p").to_string(),
    };
    
    let template = DashboardTemplate {
        css,
        js,
        user: Some(user_response),
        dashboard_user,
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