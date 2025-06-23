# Create New Repository Example

## Instructions for Claude Code Agent

Analyze existing examples in the `./examples` directory and create a new, unique example that demonstrates different functionality or use cases not covered by existing examples.

### Workflow Steps

1. **Analyze Existing Examples**
   - Scan the `./examples` directory for all existing examples
   - Read and understand what each example demonstrates
   - Identify patterns, technologies, and use cases already covered
   - Note the complexity levels (basic, intermediate, advanced)
   - Document the structure and naming conventions used

2. **Identify Repository Capabilities**
   - Analyze the main codebase to understand all available features
   - Review API documentation, configuration options, and modules
   - Check for unused or underdemonstrated functionality
   - Look for integration opportunities with external services/tools
   - Identify different user personas or use cases

3. **Gap Analysis & Example Planning**
   - Compare repository capabilities with existing examples
   - Identify missing demonstrations:
     - **Complexity gaps** (need more basic or advanced examples?)
     - **Feature gaps** (unused features that should be demonstrated?)
     - **Integration gaps** (external service integrations?)
     - **Use case gaps** (different user scenarios?)
     - **Technology gaps** (different language bindings, frameworks?)
   - Choose the most valuable gap to fill

4. **Create Example Structure**

   Use this directory structure for new examples:
   ```
   ./examples/
   └── [example-name]/
       ├── README.md              # Example documentation
       ├── [main-files]           # Core example code
       ├── config/                # Configuration files (if needed)
       │   ├── .env.example
       │   └── settings.json
       ├── data/                  # Sample data (if needed)
       │   ├── sample.json
       │   └── test-data.csv
       ├── docs/                  # Additional documentation (if complex)
       │   ├── setup.md
       │   └── explanation.md
       └── tests/                 # Example tests (if applicable)
           ├── test-example.js
           └── integration-test.py
   ```

### Example Analysis Commands

Use these commands to understand existing examples:

```bash
# List all existing examples
find ./examples -mindepth 1 -maxdepth 1 -type d | sort

# Analyze example structures
find ./examples -name "README.md" -exec echo "=== {} ===" \; -exec head -10 {} \;

# Find common patterns
find ./examples -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" | head -20

# Check for different complexity levels
grep -r "beginner\|basic\|simple\|advanced\|complex" ./examples/*/README.md

# Look for integrations
grep -r "API\|database\|service\|integration" ./examples/*/README.md

# Check example categories
ls -la ./examples/ | grep "^d" | awk '{print $9}' | grep -v "^\.$\|^\.\.$"
```

### Repository Capability Analysis

Analyze the main repository for features to demonstrate:

```bash
# Find main entry points
find . -name "main.*" -o -name "index.*" -o -name "app.*" -not -path "./examples/*"

# Look for API endpoints
grep -r "route\|endpoint\|@.*Mapping" --include="*.js" --include="*.ts" --include="*.py" --include="*.java" . | grep -v examples

# Find configuration options
find . -name "config.*" -o -name "settings.*" -o -name "*.config.*" -not -path "./examples/*"

# Check for CLI commands
grep -r "command\|cli\|argv\|argparse" --include="*.js" --include="*.ts" --include="*.py" . | grep -v examples

# Look for database schemas
find . -name "*.sql" -o -name "*migration*" -o -name "*schema*" -not -path "./examples/*"

# Find available modules/packages
find . -name "*.js" -o -name "*.py" -o -name "*.go" | grep -E "(lib|src|pkg)/" | grep -v examples
```

### Example Categories to Consider

**By Complexity Level:**
- **Hello World** - Minimal setup, basic functionality
- **Tutorial** - Step-by-step learning example
- **Real-world** - Production-like scenario
- **Advanced** - Complex features, edge cases

**By Use Case:**
- **API Integration** - Connecting to external services
- **Data Processing** - ETL, transformation, analysis
- **Authentication** - Login flows, security examples
- **Performance** - Optimization, benchmarking
- **Testing** - Unit tests, integration tests
- **Deployment** - Docker, cloud deployment
- **Monitoring** - Logging, metrics, observability

**By Technology:**
- **Framework Integration** - React, Vue, Django, etc.
- **Database Examples** - PostgreSQL, MongoDB, Redis
- **Cloud Services** - AWS, GCP, Azure
- **Message Queues** - RabbitMQ, Kafka, Redis
- **Real-time** - WebSockets, SSE, GraphQL subscriptions

**By User Type:**
- **Developer** - Technical implementation
- **End User** - User-facing applications
- **Admin** - Management and configuration
- **Integration** - Third-party system integration

### Example README.md Template

Create comprehensive documentation for each example:

```markdown
# [Example Name]

> Brief description of what this example demonstrates

## What This Example Shows

- Primary feature or concept demonstrated
- Secondary features included
- Real-world scenario this addresses
- Target audience (beginner/intermediate/advanced)

## Prerequisites

- System requirements
- Dependencies that need to be installed
- Account setup (if external services required)
- Knowledge prerequisites

## Quick Start

```bash
# Clone and setup commands
cd examples/[example-name]
npm install  # or pip install, cargo build, etc.

# Configuration setup
cp config/.env.example .env
# Edit .env with your settings

# Run the example
npm start
```

## How It Works

### Architecture Overview
[Explain the example's structure and data flow]

### Key Components
1. **Component 1** - What it does and why
2. **Component 2** - What it does and why
3. **Component 3** - What it does and why

### Code Walkthrough

#### Setup and Configuration
[Explain initialization code]

#### Core Logic
[Explain main functionality]

#### Error Handling
[Explain error handling approach]

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `option1` | string | `"default"` | What this controls |
| `option2` | number | `100` | What this controls |

## Expected Output

[Show what users should expect to see]

```
Example output here
```

## Variations and Extensions

### Easy Modifications
- How to customize X
- How to add feature Y
- How to integrate with Z

### Advanced Extensions
- Performance optimizations
- Additional features to add
- Integration opportunities

## Troubleshooting

### Common Issues

**Issue**: Error message
**Solution**: How to fix it

**Issue**: Another common problem
**Solution**: How to resolve it

### Debugging

- How to enable debug logging
- Key files to check
- Useful debugging commands

## Related Examples

- [Example A](../example-a/) - Related concept
- [Example B](../example-b/) - Next complexity level

## Further Reading

- [Documentation Section](../../doc/section/)
- [External Resource](https://example.com)
- [Related Tutorial](https://tutorial.com)

---
*This example demonstrates [key concepts] and is suitable for [target audience]*
```

### Example Creation Guidelines

1. **Uniqueness Requirements**
   - Must demonstrate different functionality than existing examples
   - Should address a genuine use case or learning need
   - Avoid duplicating existing patterns unless adding significant value

2. **Quality Standards**
   - **Functional**: Example must work out of the box
   - **Clear**: Well-commented code with explanations
   - **Complete**: Include all necessary files and documentation
   - **Tested**: Verify the example works as documented

3. **Code Quality**
   - Follow project's coding standards
   - Include error handling
   - Use meaningful variable and function names
   - Add comments explaining non-obvious code

4. **Documentation Quality**
   - Clear setup instructions
   - Explain what the example demonstrates
   - Include expected output
   - Provide troubleshooting information

### Example Ideas Generation

**For Web Applications:**
- Progressive Web App example
- Server-sent events implementation
- File upload with progress tracking
- Real-time collaboration features
- Authentication with social providers

**For APIs:**
- Rate limiting implementation
- Webhook handling
- API versioning strategies
- Bulk operations
- Caching strategies

**For Data Processing:**
- Streaming data processing
- Batch processing with queues
- Data validation and cleaning
- Export to different formats
- Real-time analytics

**For Integrations:**
- Third-party API integration
- Database migration example
- Monitoring and alerting setup
- CI/CD pipeline configuration
- Container orchestration

### Testing the New Example

Before finalizing:

1. **Fresh Environment Test**
   - Test setup on a clean system
   - Verify all dependencies are documented
   - Ensure setup instructions are complete

2. **Documentation Validation**
   - Follow your own instructions step-by-step
   - Verify all links and references work
   - Test all code examples

3. **Edge Case Testing**
   - Test with different configurations
   - Try error scenarios
   - Verify error messages are helpful

### Integration with Repository

1. **Update Main Examples Index**
   - Add the new example to any examples listing
   - Update main README if it references examples
   - Add to documentation index

2. **Cross-Reference**
   - Link from related documentation
   - Reference in API docs if relevant
   - Add to getting started guides if appropriate

3. **Announce the Addition**
   - Include in commit message
   - Update changelog if maintained
   - Consider blog post or announcement for significant examples

### Example Naming Conventions

Use clear, descriptive names:
- `basic-api-client` - Simple, descriptive
- `realtime-chat-websockets` - Technology and use case
- `advanced-authentication-jwt` - Complexity and feature
- `integration-stripe-payments` - Type and service
- `tutorial-data-processing` - Format and topic

### Success Criteria

A successful new example should:
- [ ] Demonstrate functionality not covered by existing examples
- [ ] Work out of the box following the documentation
- [ ] Include comprehensive documentation
- [ ] Follow project coding standards
- [ ] Address a real use case or learning need
- [ ] Be appropriately scoped (not too simple or complex)
- [ ] Include proper error handling
- [ ] Have clear setup and running instructions

### Notes

- Prioritize examples that address common user questions
- Consider creating examples for frequently requested features
- Balance simplicity with real-world applicability
- Include performance considerations for resource-intensive examples
- Consider maintenance burden when creating complex examples
- Document any external service dependencies clearly
