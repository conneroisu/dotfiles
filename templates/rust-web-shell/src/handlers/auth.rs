use crate::models::{CreateUserRequest, LoginRequest, User, UserResponse};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::{rand_core::OsRng, SaltString};
use askama::Template;
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::{Html, IntoResponse, Redirect, Response},
    Json,
};
use tower_sessions::Session;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::SqlitePool;
use std::collections::HashMap;
use validator::Validate;

#[derive(Template)]
#[template(path = "login.html")]
struct LoginTemplate {
    css: String,
    js: String,
    user: Option<UserResponse>,
    flash_messages: Vec<FlashMessage>,
}

#[derive(Template)]
#[template(path = "signup.html")]
struct SignupTemplate {
    css: String,
    js: String,
    user: Option<UserResponse>,
    flash_messages: Vec<FlashMessage>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FlashMessage {
    pub level: String,
    pub content: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginQuery {
    message: Option<String>,
}

// Helper function to get assets
fn get_assets() -> (String, String) {
    let css = include_str!(concat!(env!("OUT_DIR"), "/output.css"));
    let js = include_str!(concat!(env!("OUT_DIR"), "/index.js"));
    (css.to_string(), js.to_string())
}

// Helper function to get user from session
pub async fn get_user_from_session(session: &Session, pool: &SqlitePool) -> Option<UserResponse> {
    if let Ok(Some(user_id)) = session.get::<String>("user_id").await {
        if let Ok(Some(user)) = User::find_by_id(pool, &user_id).await {
            return Some(user.into());
        }
    }
    None
}

// Helper function to hash password
fn hash_password(password: &str) -> Result<String, argon2::password_hash::Error> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = argon2.hash_password(password.as_bytes(), &salt)?;
    Ok(password_hash.to_string())
}

// Helper function to verify password
fn verify_password(password: &str, hash: &str) -> Result<bool, argon2::password_hash::Error> {
    let parsed_hash = PasswordHash::new(hash)?;
    let argon2 = Argon2::default();
    Ok(argon2.verify_password(password.as_bytes(), &parsed_hash).is_ok())
}

pub async fn show_login(
    session: Session,
    State(pool): State<SqlitePool>,
    Query(query): Query<LoginQuery>,
) -> Result<Html<String>, Response> {
    let (css, js) = get_assets();
    let user = get_user_from_session(&session, &pool).await;
    
    // If user is already logged in, redirect to dashboard
    if user.is_some() {
        return Err(Redirect::to("/dashboard").into_response());
    }
    
    let mut flash_messages = Vec::new();
    if let Some(message) = query.message {
        flash_messages.push(FlashMessage {
            level: "info".to_string(),
            content: message,
        });
    }
    
    let template = LoginTemplate {
        css,
        js,
        user,
        flash_messages,
    };
    
    match template.render() {
        Ok(html) => Ok(Html(html)),
        Err(e) => {
            tracing::error!("Template render error: {}", e);
            Err((StatusCode::INTERNAL_SERVER_ERROR, "Template error").into_response())
        }
    }
}

pub async fn handle_login(
    session: Session,
    State(pool): State<SqlitePool>,
    Json(login_request): Json<LoginRequest>,
) -> Result<Json<serde_json::Value>, Response> {
    // Validate the request
    if let Err(validation_errors) = login_request.validate() {
        let mut errors = HashMap::new();
        for (field, field_errors) in validation_errors.field_errors() {
            let error_message = field_errors[0].message.as_ref()
                .map(|m| m.as_ref())
                .unwrap_or("Invalid input");
            errors.insert(field, error_message);
        }
        return Ok(Json(json!({
            "success": false,
            "errors": errors
        })));
    }

    // Find user by email
    let user = match User::find_by_email(&pool, &login_request.email).await {
        Ok(Some(user)) => user,
        Ok(None) => {
            return Ok(Json(json!({
                "success": false,
                "message": "Invalid email or password"
            })));
        }
        Err(e) => {
            tracing::error!("Database error during login: {}", e);
            return Err((StatusCode::INTERNAL_SERVER_ERROR, "Database error").into_response());
        }
    };

    // Check if user is active
    if !user.is_active {
        return Ok(Json(json!({
            "success": false,
            "message": "Account is deactivated"
        })));
    }

    // Verify password
    match verify_password(&login_request.password, &user.password_hash) {
        Ok(true) => {
            // Password is correct, create session
            if let Err(e) = session.insert("user_id", &user.id).await {
                tracing::error!("Session error: {}", e);
                return Err((StatusCode::INTERNAL_SERVER_ERROR, "Session error").into_response());
            }

            // Update last login
            if let Err(e) = User::update_last_login(&pool, &user.id).await {
                tracing::warn!("Failed to update last login for user {}: {}", user.id, e);
            }

            Ok(Json(json!({
                "success": true,
                "message": "Login successful",
                "user": UserResponse::from(user)
            })))
        }
        Ok(false) => {
            Ok(Json(json!({
                "success": false,
                "message": "Invalid email or password"
            })))
        }
        Err(e) => {
            tracing::error!("Password verification error: {}", e);
            Err((StatusCode::INTERNAL_SERVER_ERROR, "Password verification error").into_response())
        }
    }
}

pub async fn show_signup(
    session: Session,
    State(pool): State<SqlitePool>,
) -> Result<Html<String>, Response> {
    let (css, js) = get_assets();
    let user = get_user_from_session(&session, &pool).await;
    
    // If user is already logged in, redirect to dashboard
    if user.is_some() {
        return Err(Redirect::to("/dashboard").into_response());
    }
    
    let template = SignupTemplate {
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

pub async fn handle_signup(
    State(pool): State<SqlitePool>,
    Json(signup_request): Json<CreateUserRequest>,
) -> Result<Json<serde_json::Value>, Response> {
    // Validate the request
    if let Err(validation_errors) = signup_request.validate() {
        let mut errors = HashMap::new();
        for (field, field_errors) in validation_errors.field_errors() {
            let error_message = field_errors[0].message.as_ref()
                .map(|m| m.as_ref())
                .unwrap_or("Invalid input");
            errors.insert(field, error_message);
        }
        return Ok(Json(json!({
            "success": false,
            "errors": errors
        })));
    }

    // Check if user already exists
    match User::find_by_email(&pool, &signup_request.email).await {
        Ok(Some(_)) => {
            return Ok(Json(json!({
                "success": false,
                "errors": {
                    "email": "Email already exists"
                }
            })));
        }
        Ok(None) => {} // Good, user doesn't exist
        Err(e) => {
            tracing::error!("Database error checking existing user: {}", e);
            return Err((StatusCode::INTERNAL_SERVER_ERROR, "Database error").into_response());
        }
    }

    // Check if username already exists
    match User::find_by_username(&pool, &signup_request.username).await {
        Ok(Some(_)) => {
            return Ok(Json(json!({
                "success": false,
                "errors": {
                    "username": "Username already exists"
                }
            })));
        }
        Ok(None) => {} // Good, username doesn't exist
        Err(e) => {
            tracing::error!("Database error checking existing username: {}", e);
            return Err((StatusCode::INTERNAL_SERVER_ERROR, "Database error").into_response());
        }
    }

    // Hash the password
    let password_hash = match hash_password(&signup_request.password) {
        Ok(hash) => hash,
        Err(e) => {
            tracing::error!("Password hashing error: {}", e);
            return Err((StatusCode::INTERNAL_SERVER_ERROR, "Password hashing error").into_response());
        }
    };

    // Create the user
    match User::create(&pool, signup_request.email, signup_request.username, password_hash).await {
        Ok(user) => {
            Ok(Json(json!({
                "success": true,
                "message": "Account created successfully",
                "user": UserResponse::from(user)
            })))
        }
        Err(e) => {
            tracing::error!("Database error creating user: {}", e);
            Err((StatusCode::INTERNAL_SERVER_ERROR, "Database error").into_response())
        }
    }
}

pub async fn handle_logout(session: Session) -> Redirect {
    let _ = session.delete().await;
    Redirect::to("/")
}