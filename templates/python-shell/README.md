# Python Development Shell Template

A comprehensive Python development environment with modern tooling for building high-quality Python applications.

## Features

### Python Versions
- **Python 3.12** - Latest stable Python with all modern features
- **Python 3.11** - Alternative version support
- **Virtual Environment** - Built-in venv support

### Advanced Type Checking
- **basedpyright** - Advanced type checker (Pylance backend) with superior inference
- **mypy** - Static type checker with strict mode support
- **Type Stubs** - Comprehensive type hint support

### Lightning-Fast Linting & Formatting
- **ruff** - Extremely fast Python linter and formatter (Rust-based)
- **black** - Uncompromising code formatter
- **isort** - Import statement organizer
- **flake8** - Traditional Python linter (alternative)

### Package Management Options
- **Poetry** - Modern dependency management with lock files
- **pip** - Traditional Python package installer
- **pipenv** - pip + virtualenv wrapper
- **uv** - Ultra-fast Python package installer

### Comprehensive Testing
- **pytest** - Modern testing framework with rich plugin ecosystem
- **pytest-cov** - Code coverage analysis
- **pytest-mock** - Mocking utilities
- **pytest-asyncio** - Async testing support
- **hypothesis** - Property-based testing framework
- **tox** - Testing across multiple Python versions

### Development Tools
- **IPython** - Enhanced interactive Python shell
- **Jupyter Lab** - Modern notebook interface
- **pre-commit** - Git hook management
- **bandit** - Security vulnerability scanner
- **safety** - Dependency security checker

### Profiling & Performance
- **py-spy** - Sampling profiler (no code changes needed)
- **memory-profiler** - Memory usage analysis
- **line-profiler** - Line-by-line performance profiling
- **cProfile** - Built-in Python profiler

## Quick Start

```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#python-shell

# Enter development shell
nix develop

# Initialize project with Poetry (recommended)
init-poetry

# Or initialize with pip
init-pip

# Install dependencies
deps-install

# Run tests
test

# Start development
dev
```

## Available Commands

### Project Initialization
- `init-poetry` - Initialize modern Poetry project with complete setup
- `init-pip` - Initialize pip-based project with requirements files
- `px` - Edit pyproject.toml
- `rx` - Edit requirements.txt

### Development
- `dev` - Run main Python application
- `repl` - Start IPython enhanced REPL
- `notebook` - Launch Jupyter Lab for interactive development

### Testing
- `test` - Run tests with coverage analysis
- `test-watch` - Run tests in watch mode (auto-rerun on changes)

### Code Quality
- `lint` - Run all linting tools (ruff, mypy, basedpyright)
- `lint-ruff` - Fast linting with ruff
- `lint-mypy` - Type checking with mypy
- `lint-basedpyright` - Advanced type checking with basedpyright
- `format` - Format code (black + isort)
- `format-black` - Format with black
- `format-isort` - Sort imports with isort

### Dependencies
- `deps-install` - Install project dependencies
- `deps-update` - Update dependencies (Poetry projects)

### Profiling
- `profile-time` - Profile execution time with cProfile
- `profile-memory` - Profile memory usage

### Utilities
- `clean` - Clean Python cache files and artifacts
- `dx` - Edit flake.nix

## Project Structure

### Poetry Project (Recommended)
```
my-python-project/
├── pyproject.toml           # Poetry configuration and dependencies
├── src/
│   ├── __init__.py          # Package initialization
│   └── main.py              # Main application module
├── tests/
│   ├── __init__.py          # Test package
│   └── test_main.py         # Test modules with pytest examples
├── .pre-commit-config.yaml  # Pre-commit hook configuration
├── .gitignore               # Comprehensive Python gitignore
└── flake.nix                # Nix development environment
```

### Pip Project
```
my-python-project/
├── requirements.txt         # Production dependencies
├── requirements-dev.txt     # Development dependencies
├── setup.py                 # Package configuration
├── src/                     # Source code
├── tests/                   # Test directory
└── flake.nix                # Development environment
```

## Type Checking

### basedpyright (Recommended)
Advanced type checker with superior inference:

```python
from typing import List, Optional, Dict, Any

def process_data(items: List[Dict[str, Any]]) -> Optional[str]:
    """Process data with advanced type inference."""
    if not items:
        return None
    
    # basedpyright provides excellent inference here
    result = [item.get("name", "unknown") for item in items]
    return ", ".join(result)
```

### mypy Configuration
```toml
# pyproject.toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

## Linting Configuration

### ruff (Ultra-Fast Linting)
```toml
# pyproject.toml
[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # Pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "UP",  # pyupgrade
]
```

### black Configuration
```toml
# pyproject.toml
[tool.black]
line-length = 88
target-version = ['py312']
include = '\.pyi?$'
```

## Testing Strategy

### pytest with Coverage
```python
import pytest
from hypothesis import given, strategies as st
from unittest.mock import Mock, patch

def test_basic_functionality():
    """Basic test example."""
    assert 2 + 2 == 4

@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
])
def test_parametrized(input, expected):
    """Parametrized test example."""
    assert input.upper() == expected

@given(st.text())
def test_property_based(text):
    """Property-based test with hypothesis."""
    assert len(text.upper()) == len(text)

@pytest.mark.asyncio
async def test_async_function():
    """Async test example."""
    result = await some_async_function()
    assert result is not None
```

### Coverage Configuration
```toml
# pyproject.toml
[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
]
```

## Package Management

### Poetry (Recommended)
Modern dependency management with lock files:

```bash
# Add dependencies
poetry add requests fastapi

# Add development dependencies
poetry add --group dev pytest black ruff

# Install dependencies
poetry install

# Update dependencies
poetry update

# Show dependency tree
poetry show --tree
```

### pip with Virtual Environments
Traditional approach:

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements-dev.txt
pip install -e .

# Freeze dependencies
pip freeze > requirements.txt
```

## Advanced Features

### Pre-commit Hooks
Automatic code quality checks:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.0.292
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]

  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile", "black"]
```

### Security Scanning
```bash
# Security vulnerability scanning
bandit -r src/
safety check

# Dependency security check
safety check --json
```

### Performance Profiling
```python
# Time profiling with py-spy (no code changes needed)
py-spy record -o profile.svg -- python src/main.py

# Memory profiling
@profile
def memory_intensive_function():
    """Function to profile memory usage."""
    data = [i for i in range(1000000)]
    return sum(data)

# Line profiling
@profile
def line_by_line_function():
    """Function to profile line by line."""
    for i in range(100):
        result = i ** 2
    return result
```

## Modern Python Features

### Type Hints and Annotations
```python
from typing import Generic, TypeVar, Protocol
from dataclasses import dataclass
from enum import Enum

T = TypeVar('T')

class Comparable(Protocol):
    def __lt__(self, other: 'Comparable') -> bool: ...

@dataclass
class Person:
    name: str
    age: int
    
    def __post_init__(self) -> None:
        if self.age < 0:
            raise ValueError("Age cannot be negative")

class Status(Enum):
    PENDING = "pending"
    COMPLETE = "complete"
    FAILED = "failed"
```

### Async/Await Support
```python
import asyncio
import aiohttp
from typing import List

async def fetch_data(url: str) -> dict:
    """Fetch data asynchronously."""
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

async def process_urls(urls: List[str]) -> List[dict]:
    """Process multiple URLs concurrently."""
    tasks = [fetch_data(url) for url in urls]
    return await asyncio.gather(*tasks)
```

## IDE Integration

### Language Server Support
- **Pylsp** - Python LSP server
- **Pyright** - Microsoft's Python language server
- **Jedi Language Server** - Alternative language server

### Editor Configuration
Most editors automatically detect the Python environment and tools:

- **VS Code**: Automatically uses basedpyright/Pylance
- **PyCharm**: Built-in support for all tools
- **Vim/Neovim**: Works with language servers
- **Emacs**: LSP mode integration

## Performance Optimization

### Profiling Workflow
```bash
# 1. Quick profiling with py-spy
py-spy record -o profile.svg -- python src/main.py

# 2. Detailed line profiling
kernprof -l -v src/main.py

# 3. Memory profiling
python -m memory_profiler src/main.py

# 4. Built-in profiling
python -m cProfile -s cumulative src/main.py
```

### Optimization Tips
- Use `ruff` for fast linting in CI/CD
- Enable `basedpyright` strict mode for better type safety
- Use `hypothesis` for property-based testing
- Profile before optimizing
- Use `py-spy` for production profiling

## Platform Support

- ✅ **Linux** (x86_64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)
- ✅ **Windows** (via WSL)

## Best Practices

### Code Organization
```python
# Modern Python imports
from __future__ import annotations  # Enable PEP 563

import sys
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass

# Local imports
from .utils import helper_function
from .models import DataModel
```

### Error Handling
```python
from typing import Result, Ok, Err  # Use a Result type library

def safe_divide(a: float, b: float) -> Result[float, str]:
    """Safe division with proper error handling."""
    if b == 0:
        return Err("Division by zero")
    return Ok(a / b)
```

### Testing Best Practices
- Write tests first (TDD)
- Use descriptive test names
- Test edge cases with `hypothesis`
- Mock external dependencies
- Aim for >90% code coverage

## Troubleshooting

### Common Issues
**Import errors**: Check PYTHONPATH and virtual environment
**Type errors**: Ensure all dependencies have type stubs
**Slow linting**: Use `ruff` instead of `flake8` for speed
**Test failures**: Check pytest configuration and fixtures

### Performance Tips
- Use `uv` for faster package installation
- Enable `ruff` cache for faster linting
- Use `pytest-xdist` for parallel testing
- Profile with `py-spy` for minimal overhead

This template provides everything needed for professional Python development with cutting-edge tooling and best practices!