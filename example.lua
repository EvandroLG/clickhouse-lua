#!/usr/bin/env lua
-- example.lua - Examples for ClickHouse Lua Client

local clickHouse = require("clickhouse_client")
local ClickHouseClient = clickHouse.ClickHouseClient

local client = ClickHouseClient:new({
  host = "localhost",
  port = 8123,
  username = "default",
  password = "",
  database = "default",
})

local success, err = client:ping()
if success then
  print("✓ Connected to ClickHouse!")
else
  print("✗ Connection failed:", err)
end
