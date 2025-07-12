TEST_FILE = tests.lua

deps:
	@echo "Installing Lua dependencies..."
	@echo "Checking Lua version..."
	@lua -v
	@echo ""
	@echo "Installing core dependencies..."
	@luarocks install luasocket || echo "luasocket already installed"
	@luarocks install lua-cjson || echo "lua-cjson already installed"
	@echo ""
	@echo "Installing development dependencies (optional)..."
	@luarocks install lunatest || echo "Warning: luacheck not available for this Lua version"
	@luarocks install luasec || echo "Warning: luasec not available (HTTPS support)"
	@echo ""
	@echo "Core dependencies check complete!"
	@echo "Note: Some dev tools may not be available for your Lua version"

test:
	@echo "Running tests..."
	@lua $(TEST_FILE)

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f *.rock
	@rm -f *.tar.gz
	@rm -f luacov.*.out
	@echo "Clean complete!"
