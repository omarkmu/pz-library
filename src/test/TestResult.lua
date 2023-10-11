local class = require 'class'
local format = string.format

---Contains results of a test run.
---@class omi.test.TestResult : omi.Class
---@field errors omi.test.ErrorRecord[]
---@field skipped omi.test.SkipRecord[]
---@field failures omi.test.FailRecord[]
---@field successes omi.test.SuccessRecord[]
---@field testsRun integer
---@field protected _verbosity integer
---@field protected _inTest boolean
local TestResult = class()


---Formats an error object.
---@param error unknown
---@param traceback string?
---@return string
function TestResult:formatError(error, traceback)
    if traceback then
        return format('%s\n%s', tostring(error), traceback)
    end

    return tostring(error)
end

---Formats a test failure.
---@param error omi.test.FailTestSignal
---@param traceback string?
---@return string
function TestResult:formatFailure(error, traceback)
    return self:formatError(error, traceback)
end

---Adds a success to the test results.
---@param func omi.test.FunctionRecord
---@return omi.test.SuccessRecord
function TestResult:addSuccess(func)
    local success = {
        func = func,
    }

    self.successes[#self.successes + 1] = success
    return success
end

---Adds an error to the test results.
---@param error unknown
---@param traceback string?
---@param func omi.test.FunctionRecord?
---@return omi.test.ErrorRecord
function TestResult:addError(error, traceback, func)
    ---@type omi.test.ErrorRecord
    local err = {
        func = func,
        error = error,
        formattedError = self:formatError(error, traceback),
    }

    self.errors[#self.errors + 1] = err
    return err
end

---Adds a skipped test to the test results.
---@param func omi.test.FunctionRecord
---@param reason string?
---@return omi.test.SkipRecord
function TestResult:addSkip(func, reason)
    ---@type omi.test.SkipRecord
    local skip = {
        func = func,
        reason = reason,
    }

    self.skipped[#self.skipped + 1] = skip
    return skip
end

---Adds a failed test to the test results.
---@param func omi.test.FunctionRecord
---@param failure omi.test.FailTestSignal
---@param traceback string?
---@return omi.test.FailRecord
function TestResult:addFail(func, failure, traceback)
    ---@type omi.test.FailRecord
    local fail = {
        func = func,
        failure = failure,
        formattedError = self:formatFailure(failure, traceback),
    }

    self.failures[#self.failures + 1] = fail
    return fail
end

---Called when a test is about to be run.
---@param func omi.test.FunctionRecord
---@diagnostic disable-next-line: unused-local
function TestResult:startTest(func)
    self._inTest = true
    self.testsRun = self.testsRun + 1
end

---Called when a test has run.
---@param func omi.test.FunctionRecord
---@diagnostic disable-next-line: unused-local
function TestResult:stopTest(func)
    self._inTest = false
end

---Called once before any tests are run.
function TestResult:startTestRun() end

---Called once after all tests have run.
---@param duration number? The time the tests took in seconds.
---@diagnostic disable-next-line: unused-local
function TestResult:stopTestRun(duration) end

---Returns `true` if the test had any failures or errors.
---@return boolean
function TestResult:wasUnsuccessful()
    return #self.errors > 0 or #self.failures > 0
end

---Creates a new test result object.
---@param options omi.test.RunOptions
---@return omi.test.TestResult
function TestResult:new(options)
    ---@type omi.test.TestResult
    local this = setmetatable({}, self)

    this.successes = {}
    this.errors = {}
    this.failures = {}
    this.skipped = {}
    this.testsRun = 0
    this._inTest = false
    this._verbosity = options.verbosity or 1

    return this
end

return TestResult
