use thiserror::Error;

#[derive(Error, Debug)]
pub enum ParError {
    #[error("Configuration error: {0}")]
    Config(String),

    #[error("Prompt error: {0}")]
    Prompt(String),

    #[error("Worktree error: {0}")]
    Worktree(String),

    #[error("Execution error: {0}")]
    Execution(String),

    #[error("Terminal error: {0}")]
    Terminal(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Git error: {0}")]
    Git(String),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_yaml::Error),

    #[error("Template error: {0}")]
    Template(#[from] tera::Error),

    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

pub type Result<T> = std::result::Result<T, ParError>;