local failed = 0
local passed = 0

---@param name string
---@param fn fun()
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  PASS " .. name)
  else
    failed = failed + 1
    print("  FAIL " .. name .. ": " .. tostring(err))
  end
end

local function assert_eq(got, expected, msg)
  if got ~= expected then
    error((msg or "") .. " expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(got))
  end
end

local function assert_nil(got, msg)
  if got ~= nil then
    error((msg or "") .. " expected nil, got " .. vim.inspect(got))
  end
end

local function assert_table_eq(got, expected, msg)
  local g = vim.inspect(got)
  local e = vim.inspect(expected)
  if g ~= e then
    error((msg or "") .. " expected " .. e .. ", got " .. g)
  end
end

return {
  test = test,
  assert_eq = assert_eq,
  assert_nil = assert_nil,
  assert_table_eq = assert_table_eq,
  summary = function()
    print(string.format("\n%d passed, %d failed", passed, failed))
    return failed
  end,
}
