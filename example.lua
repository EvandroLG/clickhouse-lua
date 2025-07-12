#!/usr/bin/env lua
-- example.lua - Examples for ClickHouse Lua Client

local clickHouse = require("clickhouse")
local ClickHouseClient = clickHouse.ClickHouseClient

local client = ClickHouseClient:new({
  host = "localhost",
  port = 8123,
  username = "default",
  password = "",
  database = "default",
})

local function print_section(title)
  print()
  print(title)
  print(string.rep("-", string.len(title)))
end

print_section("Example 1: Testing connection with ping")

local success, err = client:ping()
if success then
  print("✓ Connected to ClickHouse!")
else
  print("✗ Connection failed:", err)
end

print_section("Example 2: Simple SELECT query")

local result, err = client:query("SELECT 1 as test_value, 'Hello ClickHouse!' as message")
if result and result[1] then
  print("Query Result:")
  for _, row in ipairs(result) do
    print(string.format("test_value: %d, message: %s", row.test_value, row.message))
  end
else
  print("✗ Query failed:", err)
end

print_section("Example 3: Query with TabSeparated format")

local tab_result, err = client:query("SELECT version(), uptime()", { format = "TabSeparated" })
if tab_result then
  print("Raw result:", tab_result)
else
  print("Query failed:", err)
end

print_section("Example 4: List databases using query")

local databases, err = client:query("SHOW DATABASES")
if databases then
  print("Available databases:")
  for i, db in ipairs(databases) do
    print("  " .. i .. ".", db.name)
  end
else
  print("Query failed:", err)
end

print_section("Example 5: Create table and insert data")

-- Create a simple test table
local create_sql = [[
    CREATE TABLE IF NOT EXISTS test_table (
        id UInt32,
        name String,
        created DateTime DEFAULT now()
    ) ENGINE = Memory
]]

local success, err = client:query(create_sql)
if success then
  print("✓ Table created successfully")

  -- Insert data using INSERT query
  local insert_sql = [[
        INSERT INTO test_table (id, name) VALUES
        (1, 'Alice'),
        (2, 'Bob'),
        (3, 'Charlie')
    ]]

  local insert_result, insert_err = client:query(insert_sql)
  if insert_result ~= nil then
    print("✓ Data inserted successfully")

    -- Query the data back
    local select_result, select_err = client:query("SELECT * FROM test_table ORDER BY id")
    if select_result then
      print("✓ Data retrieved:")
      for _, row in ipairs(select_result) do
        print(string.format("  ID: %s, Name: %s, Created: %s",
          row.id, row.name, row.created))
      end
    else
      print("Select failed:", select_err)
    end

    -- Clean up
    client:query("DROP TABLE test_table")
    print("✓ Test table cleaned up")
  else
    print("Insert failed:", insert_err)
  end
else
  print("Table creation failed:", err)
end

print_section("Example 6: Using the insert method")

-- Create a simple table for insert method demo
local success, err = client:query("CREATE TABLE IF NOT EXISTS demo_users (id Int32, name String) ENGINE = Memory")
if success then
  print("✓ Demo table created")

  -- Insert data using the insert method
  local users_data = {
    { id = 1, name = "Alice" },
    { id = 2, name = "Bob" }
  }

  local insert_success, insert_err = client:insert("demo_users", users_data)
  if insert_success then
    print("✓ Data inserted using insert method")

    -- Query the data back
    local result, query_err = client:query("SELECT * FROM demo_users ORDER BY id")
    if result then
      print("✓ Inserted users:")
      for _, user in ipairs(result) do
        print(string.format("  ID: %d, Name: %s", user.id, user.name))
      end
    end

    -- Clean up
    client:query("DROP TABLE demo_users")
    print("✓ Demo table cleaned up")
  else
    print("✗ Insert failed:", insert_err)
  end
else
  print("✗ Table creation failed:", err)
end

print_section("Example 7: Aggregation and analytics")

local analytics_query = [[
    SELECT
        'Q1' as quarter, 1000 as revenue, 50 as customers
    UNION ALL SELECT 'Q2', 1200, 65
    UNION ALL SELECT 'Q3', 1100, 60
    UNION ALL SELECT 'Q4', 1300, 70
]]

local analytics_result = client:query(analytics_query)
if analytics_result then
  print("Quarterly data:")
  local total_revenue = 0
  local total_customers = 0

  for _, row in ipairs(analytics_result) do
    print(string.format("  %s: Revenue=%s, Customers=%s",
      row.quarter, row.revenue, row.customers))
    total_revenue = total_revenue + row.revenue
    total_customers = total_customers + row.customers
  end

  print(string.format("  Total: Revenue=%d, Customers=%d", total_revenue, total_customers))
end
