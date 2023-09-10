local class = require 'class'
local format = string.format
local utils = require 'utils/type'
local signal = require 'test/signal'
local TestResult = require 'test/TestResult'

---Tries to retrieve a traceback.
---@param target function?
---@param targetName string?
---@return string?
local function tryGetTraceback(target, targetName)
    if not debug then
        return
    end

    local level = 4
    local result = { '\nstack traceback:' }
    while debug and debug.getinfo and target do
        local info = debug.getinfo(level, 'Slfn')
        if not info then break end

        if info.short_src ~= '[C]' then
            local name
            if info.namewhat ~= nil then
                local fName = info.func == target and targetName or info.name
                if not fName then
                    fName = format('<%s:%s>', info.short_src, info.currentline)
                end
                name = format("function '%s'", fName)
            else
                name = 'main chunk'
            end

            result[#result+1] = format('\n\t%s:%s: in %s', info.short_src, info.currentline, name)
        end

        level = level + 1
    end

    if #result > 1 then
        return table.concat(result)
    end

    if debug and debug.traceback then
        return debug.traceback('', 4)
    end
end

---Base test runner.
---@class omi.test.TestRunner : omi.Class
local TestRunner = class()

---@alias omi.test.RunResult 'success' | 'fail' | 'skip' | 'error'

---Runs a function on a test case object and reports test status on `result`.
---@param result omi.test.TestResult The result object.
---@param case omi.test.TestCase The case to run the test on.
---@param name string The name of the test.
---@param func function The function to run.
---@param tbName string? The name of the test as it should appear in a traceback. Defaults to `name`.
---@return omi.test.RunResult
---@return string? skipReason
---@protected
function TestRunner:_runFunction(result, case, name, func, tbName)
    if not func then
        -- should not happen
        result:addError('failed to resolve function', tryGetTraceback())
        return 'error'
    end

    ---@type omi.test.FunctionRecord
    local rec = {
        case = case,
        name = name,
        func = func,
    }

    ---@type omi.test.RunResult
    local runResult = 'success'

    ---@type string?
    local skipReason

    xpcall(function() func(case) end, function(err)
        if utils.isinstance(err, signal.Skip) then
            ---@cast err omi.test.SkipTestSignal
            runResult = 'skip'
            skipReason = err:reason()
            return
        end

        local tb = tryGetTraceback(func, tbName or name)
        if utils.isinstance(err, signal.Fail) then
            ---@cast err omi.test.FailTestSignal
            runResult = 'fail'
            result:addFail(rec, err, tb)
        else
            runResult = 'error'
            result:addError(err, tb, rec)
        end
    end)

    return runResult, skipReason
end

---Collects all tests in a case.
---@param case omi.test.TestCase
---@return omi.test.CaseRecord
function TestRunner:collectTestsFromCase(case)
    ---@type omi.test.FunctionRecord[]
    local tests = {}
    local seen = {}
    local stack = { case }

    while stack[1] do
        local tab = stack[#stack]
        stack[#stack] = nil
        seen[tab] = true

        for k, v in pairs(tab) do
            if k:sub(1, 4) == 'test' and type(v) == 'function' then
                tests[#tests + 1] = {
                    case = case,
                    name = k,
                    func = v,
                }
            end
        end

        local mt = getmetatable(tab)
        if type(mt) == 'table' and mt.__index and not seen[mt.__index] then
            stack[#stack + 1] = mt.__index
        end
    end

    return tests
end

---Collects all tests in a suite.
---@param suite omi.test.TestSuite
---@return omi.test.CaseRecord[]
function TestRunner:collectTests(suite)
    ---@type omi.test.CaseRecord[]
    local records = {}

    for _, cls in suite:cases() do
        ---@type omi.test.TestCase
        local case = cls:new()
        local tests = self:collectTestsFromCase(case)

        if #tests > 0 then
            records[#records+1] = {
                case = case,
                tests = tests,
            }
        end
    end

    return records
end

---Creates and returns a result object for the test runner.
---@param options omi.test.RunOptions
---@return omi.test.TestResult
function TestRunner:makeResult(options)
    return TestResult:new(options)
end

---Runs a test case.
---@param testCase omi.test.CaseRecord
---@param result omi.test.TestResult
function TestRunner:runTestCase(testCase, result)
    local skipTests
    local case = testCase.case
    local runResult, skipAllReason = self:_runFunction(result, case, 'beforeAll', case.beforeAll)
    if runResult ~= 'success' then
        skipTests = true
    end

    for _, rec in ipairs(testCase.tests) do
        result:startTest(rec)

        if skipTests then
            result:addSkip(rec, skipAllReason)
        else
            local skipReason, testResult
            runResult, skipReason = self:_runFunction(result, case, rec.name, case.beforeEach, 'beforeEach')

            if runResult ~= 'success' then
                -- beforeEach errored/failed/skipped → skip the test and don't run afterEach
                testResult = runResult
            else
                testResult, skipReason = self:_runFunction(result, case, rec.name, rec.func)
                runResult = self:_runFunction(result, case, rec.name, case.afterEach, 'afterEach')

                -- error/fail in after → failed test
                if runResult == 'error' or runResult == 'fail' then
                    testResult = runResult
                end
            end

            if testResult == 'skip' then
                result:addSkip(rec, skipReason)
            elseif testResult == 'success' then
                result:addSuccess(rec)
            end
        end

        result:stopTest(rec)
    end

    self:_runFunction(result, case, 'afterAll', case.afterAll)
end

---Runs a test suite or test case.
---@param suite omi.test.TestSuite
---@param options omi.test.RunOptions
function TestRunner:runTests(suite, options)
    ---@type omi.test.TestResult
    local result = self:makeResult(options)

    local endTime
    local startTime = os and os.clock and os.clock()
    result:startTestRun()

    local success, records = xpcall(
        function() return self:collectTests(suite) end,
        function(err) result:addError(err, tryGetTraceback(self.collectTests, 'collectTests')) end
    )

    if success and #records > 0 then
        for _, rec in ipairs(records) do
            self:runTestCase(rec, result)
        end
    end

    endTime = os and os.clock and os.clock()
    result:stopTestRun((startTime and endTime) and (endTime - startTime) or nil)

    return result
end

---Creates a new test runner.
---@return omi.test.TestRunner
function TestRunner:new()
    return setmetatable({}, self)
end

return TestRunner
