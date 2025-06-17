# Makefile for convert_img

# Variables
PYTHON := python
TEST_FILES := test_convert_img.py test_integration.py
MAIN_FILE := convert_img.py

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  test        - Run all tests"
	@echo "  test-unit   - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  lint        - Run linting (ruff preferred)"
	@echo "  format      - Format code with black (if available)"
	@echo "  clean       - Clean up temporary files"
	@echo "  install-dev - Install development dependencies"

# Test targets
.PHONY: test
test: test-unit test-integration

.PHONY: test-unit
test-unit:
	@echo "Running unit tests..."
	$(PYTHON) -m unittest test_convert_img.py -v

.PHONY: test-integration
test-integration:
	@echo "Running integration tests..."
	$(PYTHON) -m unittest test_integration.py -v

# Linting target
.PHONY: lint
lint:
	@echo "Running linting..."
	@if command -v ruff >/dev/null 2>&1; then \
		echo "Using ruff..."; \
		ruff check $(MAIN_FILE) $(TEST_FILES); \
	elif command -v flake8 >/dev/null 2>&1; then \
		echo "Using flake8..."; \
		flake8 $(MAIN_FILE) $(TEST_FILES) --max-line-length=88 --ignore=E203,W503; \
	elif command -v pycodestyle >/dev/null 2>&1; then \
		echo "Using pycodestyle..."; \
		pycodestyle $(MAIN_FILE) $(TEST_FILES) --max-line-length=88 --ignore=E203,W503; \
	else \
		echo "No linter found. Install ruff, flake8, or pycodestyle."; \
		echo "Checking basic syntax instead..."; \
		$(PYTHON) -m py_compile $(MAIN_FILE); \
		for test in $(TEST_FILES); do $(PYTHON) -m py_compile $$test; done; \
	fi

# Formatting target
.PHONY: format
format:
	@echo "Formatting code..."
	@if command -v ruff >/dev/null 2>&1; then \
		echo "Using ruff format..."; \
		ruff format $(MAIN_FILE) $(TEST_FILES); \
	elif command -v black >/dev/null 2>&1; then \
		echo "Using black..."; \
		black $(MAIN_FILE) $(TEST_FILES) --line-length=88; \
	elif command -v autopep8 >/dev/null 2>&1; then \
		echo "Using autopep8..."; \
		autopep8 --in-place --max-line-length=88 $(MAIN_FILE) $(TEST_FILES); \
	else \
		echo "No formatter found. Install ruff, black, or autopep8."; \
	fi

# Clean target
.PHONY: clean
clean:
	@echo "Cleaning up..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.coverage" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type f -name ".coverage" -delete
	find . -type d -name "htmlcov" -exec rm -rf {} +
	@echo "Cleanup complete."

# Development dependencies installation
.PHONY: install-dev
install-dev:
	@echo "Installing development dependencies..."
	@if command -v pip >/dev/null 2>&1; then \
		pip install ruff pytest coverage; \
		echo "Installed: ruff, pytest, coverage"; \
	else \
		echo "pip not found. Cannot install development dependencies."; \
	fi

# Coverage target (optional)
.PHONY: coverage
coverage:
	@echo "Running tests with coverage..."
	@if command -v coverage >/dev/null 2>&1; then \
		coverage run -m unittest $(TEST_FILES); \
		coverage report -m --include="convert_img.py"; \
		coverage html --include="convert_img.py"; \
		echo "Coverage report generated in htmlcov/"; \
	else \
		echo "coverage not installed. Run 'make install-dev' first."; \
	fi

# Quick syntax check
.PHONY: check-syntax
check-syntax:
	@echo "Checking syntax..."
	$(PYTHON) -m py_compile $(MAIN_FILE)
	@for test in $(TEST_FILES); do \
		echo "Checking $$test..."; \
		$(PYTHON) -m py_compile $$test; \
	done
	@echo "Syntax check passed."

# Run a specific test file
.PHONY: test-file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=test_convert_img.py"; \
	else \
		echo "Running $(FILE)..."; \
		$(PYTHON) -m unittest $(FILE) -v; \
	fi

# Comprehensive check (lint + test)
.PHONY: check
check: lint test
	@echo "All checks passed!"