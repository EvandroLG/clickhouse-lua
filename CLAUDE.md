# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Lua HTTP client library for ClickHouse database. The project provides a simple, dependency-minimal interface for connecting to ClickHouse servers and executing SQL queries.

### Core Architecture

- **Main Module**: `clickhouse_client.lua` - Contains the `ClickHouseClient` class with all functionality
- **Test Suite**: `tests.lua` - Comprehensive test suite with custom assertion framework
- **Example Usage**: `example.lua` - Demonstrates client usage patterns

### Key Components

The `ClickHouseClient` class provides:
- Connection management with authentication via HTTP headers
- Query execution with automatic HTTP method detection (GET for SELECT, POST for DDL/DML)
- Support for multiple response formats (JSONEachRow, JSON, TabSeparated)
- Data insertion with format-specific serialization
- Ping functionality for connection testing

## Development Commands

### Dependencies
```bash
make deps
```
Installs required Lua dependencies via LuaRocks:
- `luasocket` - HTTP client functionality
- `lua-cjson` - JSON parsing/encoding
- Optional dev tools: `luacheck`, `lua-format`, `luasec`

### Testing
```bash
make test
# or directly:
lua tests.lua
```
Runs the complete test suite with custom assertion framework. Tests cover:
- Constructor behavior with various configurations
- Query method with different SQL types and parameters
- Insert method with multiple data formats
- Error handling and edge cases

### Code Quality
```bash
make lint    # Run luacheck static analysis
make format  # Format code with lua-format
make clean   # Clean build artifacts
```

## Code Patterns

### Client Initialization
```lua
local client = ClickHouseClient.new({
  host = "localhost",
  port = 8123,
  username = "default", 
  password = "",
  database = "default"
})
```

### Query Execution
- The client automatically detects HTTP method based on SQL command type
- FORMAT clauses are automatically added for SELECT queries unless already present
- INSERT VALUES queries are handled specially to avoid incorrect FORMAT addition

### Error Handling
All methods return `result, error` pattern where:
- Success: `result` contains data, `error` is nil
- Failure: `result` is nil, `error` contains error message

### Testing Patterns
The test suite uses a custom framework with:
- `test(description, function)` - Define test cases
- `assert_*` functions - Various assertion types
- `create_test_client()` - Helper for test database connections

## Dependencies

Required:
- `luasocket` - HTTP client
- `lua-cjson` - JSON handling

Optional:
- `luacheck` - Static analysis
- `lua-format` - Code formatting
- `luasec` - HTTPS support (not currently used)