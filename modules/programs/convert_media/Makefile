# Makefile for convert_media development and testing

.PHONY: help test test-unit test-integration lint format clean install dev-install

# Default target
help:
	@echo "Available targets:"
	@echo "  test           - Run all tests"
	@echo "  test-unit      - Run unit tests only"
	@echo "  test-integration - Run integration tests only (requires FFmpeg)"
	@echo "  lint           - Run linting checks"
	@echo "  format         - Format code"
	@echo "  clean          - Clean up temporary files"
	@echo "  install        - Install package"
	@echo "  dev-install    - Install package in development mode"

# Test targets
test: test-unit test-integration

test-unit:
	@echo "Running unit tests..."
	python -m pytest test_convert_media.py -v

test-integration:
	@echo "Running integration tests (requires FFmpeg)..."
	python -m pytest test_integration.py -v

# Alternative test runners
test-pytest:
	@echo "Running all tests with pytest..."
	python -m pytest -v

test-unittest:
	@echo "Running unit tests with unittest..."
	python -m unittest test_convert_media.py -v
	@echo "Running integration tests with unittest..."
	python -m unittest test_integration.py -v

# Coverage
test-coverage:
	@echo "Running tests with coverage..."
	python -m pytest --cov=convert_media --cov-report=html --cov-report=term

# Linting and formatting
lint:
	@echo "Running linting checks..."
	python -m py_compile convert_media.py
	@echo "Checking for syntax errors in tests..."
	python -m py_compile test_convert_media.py
	python -m py_compile test_integration.py

format:
	@echo "Formatting code with black (if available)..."
	@command -v black >/dev/null 2>&1 && black convert_media.py test_*.py || echo "black not available, skipping formatting"

# Installation
install:
	pip install .

dev-install:
	pip install -e .[test]

# Cleanup
clean:
	@echo "Cleaning up temporary files..."
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf *.pyc
	rm -rf .coverage
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Development helpers
check-ffmpeg:
	@echo "Checking FFmpeg availability..."
	@command -v ffmpeg >/dev/null 2>&1 && echo "FFmpeg is available" || echo "FFmpeg is not available - integration tests will be skipped"

demo:
	@echo "Running convert_media demo (requires FFmpeg)..."
	@echo "This will create a test video and convert it to GIF..."
	@command -v ffmpeg >/dev/null 2>&1 || (echo "FFmpeg not available, cannot run demo" && exit 1)
	@echo "Creating test video..."
	ffmpeg -y -f lavfi -i testsrc=duration=2:size=320x240:rate=10 -c:v libx264 -pix_fmt yuv420p test_demo.mp4 2>/dev/null
	@echo "Converting to GIF..."
	python convert_media.py test_demo.mp4 test_demo.gif --gif-fps 5 --duration 1
	@echo "Converting to GIF with palette..."
	python convert_media.py test_demo.mp4 test_demo_palette.gif --gif-fps 5 --gif-palette --duration 1
	@echo "Extracting audio..."
	python convert_media.py test_demo.mp4 test_demo.mp3 --audio-only
	@echo "Demo files created: test_demo.gif, test_demo_palette.gif, test_demo.mp3"
	@echo "Cleaning up..."
	rm -f test_demo.mp4

# Run specific test file
test-file:
	@echo "Usage: make test-file FILE=test_convert_media.py"
	@test -n "$(FILE)" || (echo "Please specify FILE=filename" && exit 1)
	python -m pytest $(FILE) -v

# Quick validation
validate:
	@echo "Running quick validation..."
	python -c "import convert_media; print('Module imports successfully')"
	python -c "import convert_media; args = convert_media.parse_args(['input.mp4', 'output.gif']); print('Argument parsing works')"
	@echo "Basic validation passed"