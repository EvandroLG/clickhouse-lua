-- ClickHouse Lua Client
-- A simple HTTP-based client for ClickHouse database

local http = require("socket.http")
local ltn12 = require("ltn12")
local url = require("socket.url")
local json = require("cjson")

local ClickHouseClient = {}
ClickHouseClient.__index = ClickHouseClient

--- Creates a new ClickHouseClient instance.
---
--- @param config table Configuration table with the following fields:
--- @field host string The ClickHouse server host (default: "localhost")
--- @field port number The ClickHouse server port (default: 8123)
--- @field username string|user string The username for authentication (default: "default")
--- @field password string The password for authentication (default: "")
--- @field database string The database to use (default: "default")
--- @field timeout number Request timeout in seconds (default: 30)
--- @field format string The format for data exchange (default: "JSONEachRow")
---
--- @return ClickHouseClient A new client instance
function ClickHouseClient.new(config)
  local self = setmetatable({}, ClickHouseClient)

  self.host = config.host or "localhost"
  self.port = config.port or 8123
  self.username = config.username or "default"
  self.password = config.password or ""
  self.database = config.database or "default"
  self.timeout = config.timeout or 30
  self.format = config.format or "JSONEachRow"

  self.base_url = string.format("http://%s:%d/", self.host, self.port)

  return self
end

--- Builds HTTP headers for ClickHouse API requests.
--- This internal method constructs the necessary headers including
--- authentication credentials for interacting with the ClickHouse database.
---
--- @return table Headers table containing Content-Type and ClickHouse-specific authentication headers
function ClickHouseClient:_build_headers()
  local headers = {
    ["Content-Type"] = "text/plain",
    ["X-ClickHouse-User"] = self.username,
    ["X-ClickHouse-Database"] = self.database
  }

  if self.password and self.password ~= "" then
    headers["X-ClickHouse-Key"] = self.password
  end

  return headers
end

---Execute a SQL query against ClickHouse server
---
---@param sql string The SQL query to execute
---@param params table|nil Optional parameters:
---  - format: string - Response format (default: self.format)
---  - method: string - HTTP method (default: auto-detected based on SQL)
---  - Any other key-value pairs will be passed as URL parameters
---
---@return table|string|nil The query results parsed according to format, or raw response text
---@return string|nil Error message if the query failed
function ClickHouseClient:query(sql, params)
  params = params or {}

  -- Get the format (either from params or default)
  local format = params.format or self.format

  -- Determine if we should add FORMAT clause
  local final_sql = sql
  local sql_upper = string.upper(string.gsub(sql, "^%s+", "")) -- trim leading whitespace and uppercase

  -- Only add FORMAT clause for queries that can benefit from it and don't already have one
  local should_add_format = format and
      not sql_upper:match("FORMAT%s+%w+") and
      not sql_upper:match("VALUES%s*%(") and               -- Don't add to INSERT ... VALUES
      not sql_upper:match("^INSERT%s+INTO%s+%w+%s+VALUES") -- Alternative INSERT VALUES pattern

  if should_add_format then
    final_sql = sql .. " FORMAT " .. format
  end

  -- Auto-detect HTTP method based on SQL command
  local method = params.method
  if not method then
    if sql_upper:match("^CREATE") or
        sql_upper:match("^INSERT") or
        sql_upper:match("^UPDATE") or
        sql_upper:match("^DELETE") or
        sql_upper:match("^DROP") or
        sql_upper:match("^ALTER") or
        sql_upper:match("^TRUNCATE") then
      method = "POST"
    else
      method = "GET"
    end
  end

  -- Prepare query parameters (excluding format and method since they're handled separately)
  local query_params = {
    query = final_sql
  }

  -- Add any additional parameters (except format and method)
  for k, v in pairs(params) do
    if k ~= "format" and k ~= "method" then
      query_params[k] = v
    end
  end

  -- Build query string
  local query_string = ""
  for k, v in pairs(query_params) do
    if query_string ~= "" then
      query_string = query_string .. "&"
    end
    query_string = query_string .. url.escape(k) .. "=" .. url.escape(tostring(v))
  end

  local request_url = self.base_url .. "?" .. query_string

  -- Prepare response table
  local response_body = {}

  -- Make HTTP request with appropriate method
  local result, status_code
  if method == "POST" then
    result, status_code = http.request {
      url = request_url,
      method = "POST",
      headers = self:_build_headers(),
      source = ltn12.source.string(""), -- Empty body for POST
      sink = ltn12.sink.table(response_body)
    }
  else
    result, status_code = http.request {
      url = request_url,
      method = "GET",
      headers = self:_build_headers(),
      sink = ltn12.sink.table(response_body)
    }
  end

  -- Check for HTTP errors
  if not result then
    return nil, "HTTP request failed: " .. tostring(status_code)
  end

  if status_code ~= 200 then
    return nil, "ClickHouse error (HTTP " .. status_code .. "): " .. table.concat(response_body)
  end

  local response_text = table.concat(response_body)

  -- Parse response based on format only if we actually used that format
  if should_add_format and format == "JSONEachRow" then
    return self:_parse_json_each_row(response_text)
  elseif should_add_format and format == "JSON" then
    return self:_parse_json(response_text)
  else
    -- For INSERT/CREATE/etc or when format wasn't added, return raw response or empty table
    if response_text == "" then
      return {} -- Empty success response
    else
      return response_text
    end
  end
end

--- Parse JSONEachRow format response
---
--- @param response_text string Raw response text from ClickHouse
---
--- @return table|nil Parsed JSON objects as array, or nil on error
--- @return string|nil Error message if parsing failed
function ClickHouseClient:_parse_json_each_row(response_text)
  if response_text == "" then
    return {}
  end

  local lines = {}
  for line in response_text:gmatch("[^\r\n]+") do
    if line ~= "" then
      local success, parsed = pcall(json.decode, line)
      if success then
        table.insert(lines, parsed)
      else
        return nil, "Failed to parse JSON: " .. line
      end
    end
  end

  return lines
end

--- Parse JSON format response
---
--- @param response_text string Raw response text from ClickHouse
---
--- @return table|nil Parsed JSON object, or nil on error
--- @return string|nil Error message if parsing failed
function ClickHouseClient:_parse_json(response_text)
  if response_text == "" then
    return {}
  end

  local success, parsed = pcall(json.decode, response_text)
  if success then
    return parsed.data or parsed
  else
    return nil, "Failed to parse JSON response"
  end
end

--- Execute an INSERT query with data
---
--- @param table_name string The name of the table to insert into
--- @param data table Array of objects to insert
--- @param params table|nil Optional parameters including format
---
--- @return boolean|nil True on success, nil on error
--- @return string|nil Error message if the insertion failed
function ClickHouseClient:insert(table_name, data, params)
  params = params or {}
  local format = params.format or "JSONEachRow"

  -- Prepare data based on format
  local request_body
  if format == "JSONEachRow" then
    local lines = {}

    for _, row in ipairs(data) do
      table.insert(lines, json.encode(row))
    end

    request_body = table.concat(lines, "\n")
  elseif format == "JSON" then
    request_body = json.encode({ data = data })
  else
    request_body = tostring(data)
  end

  -- Build INSERT query
  local sql = string.format("INSERT INTO %s FORMAT %s", table_name, format)
  local query_string = "query=" .. url.escape(sql)
  local request_url = self.base_url .. "?" .. query_string
  local response_body = {}

  -- Make HTTP POST request
  local result, status_code = http.request {
    url = request_url,
    method = "POST",
    headers = self:_build_headers(),
    source = ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body)
  }

  -- Check for HTTP errors
  if not result then
    return nil, "HTTP request failed: " .. tostring(status_code)
  end

  if status_code ~= 200 then
    return nil, "ClickHouse error (HTTP " .. status_code .. "): " .. table.concat(response_body)
  end

  return true
end

--- Pings the ClickHouse server to check if the connection is active.
--- This method sends a simple "SELECT 1" query to verify connectivity.
---
--- @return boolean success True if the connection is active
--- @return string|nil error Error message if the connection failed, nil otherwise
function ClickHouseClient:ping()
  local result, err = self:query("SELECT 1", { format = "TabSeparated" })

  if result then
    return true
  end

  return false, err
end

return {
  ClickHouseClient = ClickHouseClient
}
