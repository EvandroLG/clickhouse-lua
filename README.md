# clickhouse-lua  &middot; [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Lua Version](https://img.shields.io/badge/Lua-5.1%2B-blue.svg)](https://www.lua.org/)

A simple, lightweight HTTP-based ClickHouse client for Lua.

## Features

- **Simple API**: Easy-to-use interface for ClickHouse operations
- **HTTP-based**: Uses ClickHouse's HTTP interface for maximum compatibility
- **Multiple Formats**: Support for JSONEachRow, JSON, TabSeparated, and more
- **Auto-detection**: Automatically detects HTTP method based on SQL command
- **Lightweight**: Minimal dependencies, pure Lua implementation

## Installation

```bash
luarocks install clickhouse
```

## Quick Start

```lua
local clickhouse = require("clickhouse_client")
local client = clickhouse.ClickHouseClient.new({
    host = "localhost",
    port = 8123,
    username = "default",
    password = "",
    database = "default"
})

-- Test connection
local success, err = client:ping()
if success then
    print("Connected to ClickHouse!")
else
    print("Connection failed:", err)
end

-- Execute a simple query
local result, err = client:query("SELECT version()")
if result then
    print("ClickHouse version:", result[1].version)
else
    print("Query failed:", err)
end
```

## API Reference

### Constructor

#### `ClickHouseClient.new(config)`

Creates a new ClickHouse client instance.

**Parameters:**
- `config` (table): Configuration options
  - `host` (string): ClickHouse server host (default: "localhost")
  - `port` (number): ClickHouse server port (default: 8123)
  - `username` (string): Username for authentication (default: "default")
  - `password` (string): Password for authentication (default: "")
  - `database` (string): Default database to use (default: "default")
  - `timeout` (number): Request timeout in seconds (default: 30)
  - `format` (string): Default format for data exchange (default: "JSONEachRow")

**Returns:** `ClickHouseClient` instance

### Methods

#### `client:ping()`

Tests the connection to ClickHouse server.

**Returns:**
- `success` (boolean): True if connection is successful
- `error` (string|nil): Error message if connection failed

#### `client:query(sql, params)`

Executes a SQL query against ClickHouse.

**Parameters:**
- `sql` (string): SQL query to execute
- `params` (table|nil): Optional parameters
  - `format` (string): Response format (overrides default)
  - `method` (string): HTTP method ("GET" or "POST", auto-detected if not specified)
  - Additional key-value pairs are passed as URL parameters

**Returns:**
- `result` (table|string|nil): Query results (parsed or raw depending on format)
- `error` (string|nil): Error message if query failed

#### `client:insert(table_name, data, params)`

Inserts data into a ClickHouse table.

**Parameters:**
- `table_name` (string): Name of the target table
- `data` (table): Array of objects to insert
- `params` (table|nil): Optional parameters
  - `format` (string): Data format ("JSONEachRow" or "JSON", default: "JSONEachRow")

**Returns:**
- `success` (boolean|nil): True if insertion succeeded
- `error` (string|nil): Error message if insertion failed

## License

[MIT](https://github.com/EvandroLG/ts-audio/tree/master/LICENSE)
