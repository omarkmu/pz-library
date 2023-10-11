local class = require 'class'
local utils = require 'utils/type'
local signal = require 'test/signal'
local stringify = (require 'utils/string').stringify
local format = string.format

---Base class for test cases.
---@class omi.test.TestCase : omi.Class
---@field protected _name string?
local TestCase = class()

---Formats a value for use in an assertion message.
---@param value unknown
---@return string
---@protected
function TestCase:_formatValue(value)
    if type(value) == 'string' then
        return format('%q', value)
    end

    return stringify(value)
end

---Runs once before all test cases.
function TestCase:beforeAll()
end

---Runs once after all test cases.
function TestCase:afterAll()
end

---Runs before each test case.
function TestCase:beforeEach()
end

---Runs after each test case.
function TestCase:afterEach()
end

---Returns the name of this test case.
---@return string?
function TestCase:getName()
    return self._name
end

---Asserts `a` matches pattern `patt` and fails if it does not.
---@param a string | number The value to check.
---@param patt string A string pattern to match against.
---@param msg string? Custom assertion message.
function TestCase:assertMatch(a, patt, msg)
    local s, matched = pcall(string.match, a, patt)
    if not s then
        self:fail(format('match failed with %s', matched), msg)
    end

    if not matched then
        self:fail(format('%s does not match pattern %q', self:_formatValue(a), patt), msg)
    end
end

---Asserts `a` does not match pattern `patt` and fails if it does.
---@param a string | number The value to check.
---@param patt string A string pattern to match against.
---@param msg string? Custom assertion message.
function TestCase:assertNotMatch(a, patt, msg)
    local s, matched = pcall(string.match, a, patt)
    if not s then
        self:fail(format('match failed with %s', matched), msg)
    end

    if matched then
        self:fail(format('%s matches pattern %q', self:_formatValue(a), patt), msg)
    end
end

---Asserts `a` and `b` are equal and fails if they are not.
---@param a unknown The first value to compare.
---@param b unknown The second value to compare.
---@param msg string? Custom assertion message.
function TestCase:assertEqual(a, b, msg)
    if utils.deepEquals(a, b) then
        return
    end

    self:fail(format('%s != %s', self:_formatValue(a), self:_formatValue(b)), msg)
end

---Asserts `a` and `b` are not equal and fails if they are.
---@param a unknown The first value to compare.
---@param b unknown The second value to compare.
---@param msg string? Custom assertion message.
function TestCase:assertNotEqual(a, b, msg)
    if not utils.deepEquals(a, b) then
        return
    end

    self:fail(format('%s == %s', self:_formatValue(a), self:_formatValue(b)), msg)
end

---Asserts that `a` is truthy and fails if it is not.
---@param a unknown The value to check.
---@param msg string? Custom assertion message.
function TestCase:assertTrue(a, msg)
    if a then
        return
    end

    self:fail(format('%s is not true', self:_formatValue(a)), msg)
end

---Asserts that `a` is falsy and fails if it is not.
---@param a unknown The value to check.
---@param msg string? Custom assertion message.
function TestCase:assertFalse(a, msg)
    if not a then
        return
    end

    self:fail(format('%s is not false', self:_formatValue(a)), msg)
end

---Asserts that `a` is nil and fails if it is not.
---@param a unknown The value to check.
---@param msg string? Custom assertion message.
function TestCase:assertNil(a, msg)
    if a == nil then
        return
    end

    self:fail(format('%s is not nil', self:_formatValue(a)), msg)
end

---Asserts that `a` is not nil and fails if it is.
---@param a unknown The value to check.
---@param msg string? Custom assertion message.
function TestCase:assertNotNil(a, msg)
    if a ~= nil then
        return
    end

    self:fail(format('value is nil', self:_formatValue(a)), msg)
end

---Asserts that `func` raises an error and fails if it does not.
---@param func function The function to call.
---@param msg string? Custom assertion message.
---@param ... unknown Function arguments to pass.
function TestCase:assertError(func, msg, ...)
    local s = pcall(func, ...)
    if not s then
        return
    end

    self:fail('function did not raise an error', msg)
end

---Asserts that `func` raises an error that matches `patt`, and fails if it does not.
---@param func function The function to call.
---@param patt string A string pattern to match against.
---@param msg string? Custom assertion message.
---@param ... unknown Function arguments to pass.
function TestCase:assertErrorMatch(func, patt, msg, ...)
    local s, e = pcall(func, ...)
    if s then
        self:fail('function did not raise an error', msg)
    end

    self:assertMatch(tostring(e), patt, msg)
end

---Signals a test failure.
---@param msg string? A failure message.
---@param customMsg string? A custom failure message. Behavior depends on the value of `longMessage`.
function TestCase:fail(msg, customMsg)
    if customMsg ~= nil then
        customMsg = tostring(customMsg)
    end

    if msg and customMsg then
        msg = self:longMessage() and format('%s: %s', msg, customMsg) or customMsg
    elseif customMsg then
        msg = customMsg
    elseif not msg then
        msg = 'fail'
    end

    error(signal.Fail:new(msg), 0)
end

---Signals that a test case should be skipped.
---@param reason string? The reason for skipping the test.
function TestCase:skip(reason)
    error(signal.Skip:new(reason), 0)
end

---Signals that a test case should be skipped if `condition` is truthy.
---@param condition unknown
---@param reason string? The reason for skipping the test.
function TestCase:skipIf(condition, reason)
    if condition then
        error(signal.Skip:new(reason), 0)
    end
end

---Signals that a test case should be skipped if `condition` is falsy.
---@param condition unknown
---@param reason string? The reason for skipping the test.
function TestCase:skipUnless(condition, reason)
    self:skipIf(not condition, reason)
end

---Gets or sets the behavior for messages passed to assertion functions.
---If true, custom messages are added to the default failure message.
---Otherwise, custom messages replace the failure message.
---This is reset before each test call.
---@param opt boolean?
---@return boolean
function TestCase:longMessage(opt)
    local value
    if opt ~= nil then
        value = not not opt
        rawset(self, '_longMessage', value)
    else
        value = not not rawget(self, '_longMessage')
    end

    return value
end

---Creates a test case class.
---@param name string
---@return omi.test.TestCase
function TestCase:derive(name)
    local cls = class.derive(self, {})
    ---@cast cls omi.test.TestCase

    cls._name = name

    return cls
end

---Creates a new test case object.
---@return omi.test.TestCase
function TestCase:new()
    return setmetatable({}, self)
end


return TestCase
