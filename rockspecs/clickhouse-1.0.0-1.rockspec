package = "clickhouse"
version = "1.0.0-1"
source = {
  url = "git+https://github.com/EvandroLG/clickhouse-lua.git",
  tag = "v1.0.0"
}
description = {
  summary = "A Lua HTTP client library for ClickHouse database.",
  detailed = [[
      A simple, dependency-minimal HTTP client for ClickHouse database.
      Provides connection management, query execution, data insertion,
      and support for multiple response formats (JSONEachRow, JSON, TabSeparated).
   ]],
  homepage = "https://github.com/username/clickhouse-lua",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "luasocket",
  "lua-cjson"
}
build = {
  type = "builtin",
  modules = {
    ["clickhouse_client"] = "clickhouse_client.lua"
  },
}

