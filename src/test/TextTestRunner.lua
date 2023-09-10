local TestRunner = require 'test/TestRunner'
local TextTestResult = require 'test/TextTestResult'

---Test runner which outputs to a stream.
---@class omi.test.TextTestRunner : omi.test.TestRunner
local TextTestRunner = TestRunner:derive()

---Creates and returns a result object for the test runner.
---@param options omi.test.RunOptions
---@return omi.test.TestResult
function TextTestRunner:makeResult(options)
    return TextTestResult:new(options)
end

---Creates a new test runner.
---@return omi.test.TextTestRunner
function TextTestRunner:new()
    ---@type omi.test.TextTestRunner
    return TestRunner.new(self)
end

return TextTestRunner
