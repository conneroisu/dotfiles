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
use rand::{distributions::Alphanumeric, Rng};

#[derive(Template)]
#[template(path = "dashboard.html")]
struct DashboardTemplate {
    css: String,
    js: String,
    user: Option<UserResponse>,
    dashboard_user: DashboardUser,
    flash_messages: Vec<FlashMessage>,
    csrf_token: String,
}

#[derive(Debug)]
struct DashboardUser {
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

// Generate a cryptographically secure CSRF token
fn generate_csrf_token() -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(32)
        .map(char::from)
        .collect()
}

// Get or create CSRF token from session
async fn get_or_create_csrf_token(session: &Session) -> Result<String, Response> {
    // Try to get existing token from session
    if let Ok(Some(token)) = session.get::<String>("csrf_token").await {
        return Ok(token);
    }
    
    // Generate new token and store in session
    let token = generate_csrf_token();
    if let Err(_) = session.insert("csrf_token", &token).await {
        tracing::error!("Failed to store CSRF token in session");
        return Err((StatusCode::INTERNAL_SERVER_ERROR, "Session error").into_response());
    }
    
    Ok(token)
}

// Validate CSRF token from request against session
pub async fn validate_csrf_token(session: &Session, provided_token: &str) -> Result<bool, Response> {
    match session.get::<String>("csrf_token").await {
        Ok(Some(session_token)) => Ok(session_token == provided_token),
        Ok(None) => Ok(false), // No token in session
        Err(_) => {
            tracing::error!("Failed to retrieve CSRF token from session");
            Err((StatusCode::INTERNAL_SERVER_ERROR, "Session error").into_response())
        }
    }
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
    
    // Get or create CSRF token
    let csrf_token = get_or_create_csrf_token(&session).await?;
    
    // Convert to dashboard user with formatted dates
    let dashboard_user = DashboardUser {
        email: user_response.email.clone(),
        username: user_response.username.clone(),
        email_verified: user_response.email_verified,
        created_at_formatted: user_response.created_at.format("%b %d, %Y").to_string(),
        updated_at_formatted: user_response.updated_at.format("%b %d, %Y").to_string(),
        created_at_full: user_response.created_at.format("%b %d, %Y at %I:%M %p").to_string(),
        updated_at_full: user_response.updated_at.format("%b %d, %Y at %I:%M %p").to_string(),
    };
    
    let template = DashboardTemplate {
        css,
        js,
        user: Some(user_response),
        dashboard_user,
        flash_messages: Vec::new(),
        csrf_token,
    };
    
    match template.render() {
        Ok(html) => Ok(Html(html)),
        Err(e) => {
            tracing::error!("Template render error: {}", e);
            Err((StatusCode::INTERNAL_SERVER_ERROR, "Template error").into_response())
        }
    }
}