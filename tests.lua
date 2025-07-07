local clickhouse = require("clickhouse_client")
local ClickHouseClient = clickhouse.ClickHouseClient

local test_count = 0
local passed_count = 0

local function test(description, test_func)
  test_count = test_count + 1
  print("Test " .. test_count .. ": " .. description)

  local success, err = pcall(test_func)
  if success then
    passed_count = passed_count + 1
    print("   PASSED")
  else
    print("  � FAILED: " .. tostring(err))
  end
  print()
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "Assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function assert_not_nil(value, message)
  if value == nil then
    error(message or "Expected non-nil value")
  end
end

local function assert_nil(value, message)
  if value ~= nil then
    error((message or "Expected nil value") .. ", got " .. tostring(value))
  end
end

local function assert_type(value, expected_type, message)
  local actual_type = type(value)
  if actual_type ~= expected_type then
    error((message or "Type assertion failed") .. ": expected " .. expected_type .. ", got " .. actual_type)
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "Expected true value")
  end
end

local function assert_false(value, message)
  if value then
    error(message or "Expected false value")
  end
end

-- Helper function to create test client with test database
local function create_test_client(config)
  config = config or {}
  config.database = config.database or "test_db"
  return ClickHouseClient.new(config)
end

-- Constructor Tests
test("Constructor with default config", function()
  local client = ClickHouseClient.new({})

  assert_not_nil(client, "Client should not be nil")
  assert_equal(client.host, "localhost")
  assert_equal(client.port, 8123)
  assert_equal(client.username, "default")
  assert_equal(client.password, "")
  assert_equal(client.database, "default")
  assert_equal(client.timeout, 30)
  assert_equal(client.format, "JSONEachRow")
  assert_equal(client.base_url, "http://localhost:8123/")
end)

test("Constructor with custom config", function()
  local config = {
    host = "clickhouse.example.com",
    port = 9000,
    username = "testuser",
    password = "testpass",
    database = "testdb",
    timeout = 60,
    format = "JSON"
  }

  local client = ClickHouseClient.new(config)

  assert_equal(client.host, "clickhouse.example.com")
  assert_equal(client.port, 9000)
  assert_equal(client.username, "testuser")
  assert_equal(client.password, "testpass")
  assert_equal(client.database, "testdb")
  assert_equal(client.timeout, 60)
  assert_equal(client.format, "JSON")
  assert_equal(client.base_url, "http://clickhouse.example.com:9000/")
end)

test("Constructor with partial config", function()
  local config = {
    host = "myhost",
    password = "mypass"
  }

  local client = ClickHouseClient.new(config)

  assert_equal(client.host, "myhost")
  assert_equal(client.port, 8123)
  assert_equal(client.username, "default")
  assert_equal(client.password, "mypass")
  assert_equal(client.database, "default")
end)

test("Query method with SELECT statement", function()
  local client = create_test_client()
  local result, err = client:query("SELECT 1")

  assert_nil(err, "Should not have error: " .. tostring(err))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query method with INSERT statement", function()
  local client = create_test_client()

  client:query("CREATE TABLE IF NOT EXISTS test_table (id Int32) ENGINE = Memory")

  local result, err = client:query("INSERT INTO test_table VALUES (1)")

  assert_nil(err, "Should not have error: " .. tostring(err))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query method with CREATE statement", function()
  local client = create_test_client()
  local result, err = client:query("CREATE TABLE IF NOT EXISTS test_create (id Int32) ENGINE = Memory")

  assert_nil(err, "Should not have error: " .. tostring(err))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query method with custom format parameter", function()
  local client = create_test_client()

  local result, err = client:query("SELECT 1", { format = "TabSeparated" })

  assert_nil(err, "Should not have error: " .. tostring(err))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query method with custom HTTP method", function()
  local client = create_test_client()

  local result, err = client:query("SELECT 1", { method = "POST" })

  assert_nil(err, "Should not have error: " .. tostring(err))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query method with additional parameters", function()
  local client = create_test_client()

  local result, err = client:query("SELECT 1", {
    max_result_rows = 1000
  })

  assert_nil(err, "Should not have error: " .. tostring(err))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query auto-detects POST method for DDL/DML", function()
  local client = create_test_client()

  client:query("CREATE TABLE IF NOT EXISTS test_ddl (id Int32) ENGINE = Memory")

  local test_queries = {
    "CREATE TABLE IF NOT EXISTS test_ddl2 (id Int32) ENGINE = Memory",
    "INSERT INTO test_ddl VALUES (1)",
    "DROP TABLE IF EXISTS test_ddl2",
    "TRUNCATE TABLE test_ddl"
  }

  for _, sql in ipairs(test_queries) do
    local result, err = client:query(sql)
    assert_nil(err, "Should not have error for: " .. sql .. (err and (" - " .. err) or ""))
    assert_not_nil(result, "Result should not be nil for: " .. sql)
  end
end)

test("Query auto-detects GET method for SELECT", function()
  local client = create_test_client()

  client:query("CREATE TABLE IF NOT EXISTS test_select (id Int32) ENGINE = Memory")
  client:query("INSERT INTO test_select VALUES (1)")

  local result, err = client:query("SELECT * FROM test_select")

  assert_nil(err, "Should not have error" .. (err and (" - " .. err) or ""))
  assert_not_nil(result, "Result should not be nil")
end)

test("Query adds FORMAT clause when appropriate", function()
  local client = create_test_client({ format = "JSON" })
  local result, err = client:query("SELECT 1")

  assert_nil(err, "Should not have error")
  assert_not_nil(result, "Result should not be nil")
end)

test("Query doesn't add FORMAT clause to INSERT VALUES", function()
  local client = create_test_client({ format = "JSON" })

  client:query("CREATE TABLE IF NOT EXISTS test_insert (id Int32) ENGINE = Memory")
  local result, err = client:query("INSERT INTO test_insert VALUES (1)")

  assert_nil(err, "Should not have error")
  assert_not_nil(result, "Result should not be nil")
end)

test("Query doesn't add FORMAT clause when already present", function()
  local client = create_test_client({ format = "JSON" })
  local result, err = client:query("SELECT 1 FORMAT TabSeparated")

  assert_nil(err, "Should not have error")
  assert_not_nil(result, "Result should not be nil")
end)

test("Query handles ClickHouse errors", function()
  local client = create_test_client()
  local result, err = client:query("INVALID_SQL_COMMAND")

  assert_nil(result, "Result should be nil on SQL error")
  assert_not_nil(err, "Error should be present")
  assert_type(err, "string", "Error should be a string")
end)

test("Insert with JSONEachRow format", function()
  local client = create_test_client()
  local create_result, create_err = client:query(
    "CREATE TABLE IF NOT EXISTS test_insert_json (id Int32, name String) ENGINE = Memory")

  local data = {
    { id = 1, name = "Alice" },
    { id = 2, name = "Bob" }
  }

  local result, err = client:insert("test_insert_json", data)

  assert_true(result, "Insert should succeed")
  assert_nil(err, "Should not have error")

  client:query("DROP TABLE IF EXISTS test_insert_json")
end)

test("Insert with JSON format", function()
  local client = create_test_client()

  local _, create_err = client:query(
    "CREATE TABLE IF NOT EXISTS test_insert_json_format (id Int32, name String) ENGINE = Memory")
  assert_nil(create_err, "Should create table without error: " .. tostring(create_err))

  local data = {
    { id = 1, name = "Alice" },
    { id = 2, name = "Bob" }
  }

  local result, err = client:insert("test_insert_json_format", data, { format = "JSON" })
  assert_true(result, "Insert should succeed: " .. tostring(err))
  assert_nil(err, "Should not have error: " .. tostring(err))

  local verify_result, verify_err = client:query("SELECT COUNT(*) as count FROM test_insert_json_format")
  assert_nil(verify_err, "Should verify without error: " .. tostring(verify_err))
  assert_not_nil(verify_result, "Verify result should not be nil")

  client:query("DROP TABLE IF EXISTS test_insert_json_format")
end)

test("Insert with non-existent table", function()
  local client = create_test_client()

  local data = { { id = 1, name = "Alice" } }
  local result, err = client:insert("non_existent_table_12345", data)

  assert_nil(result, "Insert should fail for non-existent table")
  assert_not_nil(err, "Should have error for non-existent table")
  assert_type(err, "string", "Error should be a string")
end)

print("=" .. string.rep("=", 60))
print("Test Summary:")
print("Total tests: " .. test_count)
print("Passed: " .. passed_count)
print("Failed: " .. (test_count - passed_count))
print("Success rate: " .. string.format("%.1f", (passed_count / test_count) * 100) .. "%")
print("=" .. string.rep("=", 60))

if passed_count == test_count then
  print("<� All tests passed!")
  os.exit(0)
else
  print("L Some tests failed!")
  os.exit(1)
end

