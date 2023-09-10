---Contains utilities for testing Lua.
---@class omi.test
local test = {}


---@class omi.test.FunctionRecord
---@field case omi.test.TestCase
---@field name string
---@field func function

---@class omi.test.CaseRecord
---@field case omi.test.TestCase
---@field tests omi.test.FunctionRecord[]

---@class omi.test.SuccessRecord
---@field func omi.test.FunctionRecord

---@class omi.test.ErrorRecord
---@field func omi.test.FunctionRecord?
---@field error unknown
---@field formattedError string

---@class omi.test.SkipRecord
---@field func omi.test.FunctionRecord
---@field reason string?

---@class omi.test.FailRecord
---@field func omi.test.FunctionRecord
---@field failure omi.test.FailTestSignal
---@field formattedError string

---@class omi.test.RunOptions
---@field args table? Command-line arguments to use options from. Takes precedence over other options.
---@field verbosity integer? Verbosity level.
---@field stream file*? File pointer for output. Takes precedence over `output`.
---@field output string? Output filename.
---@field exit boolean? Whether to exit after running, if `os.exit` is available. Defaults to true.
---@field runner omi.test.TestRunner? The test runner to use. A `TextTestRunner` is used by default.


local utils = require 'utils/type'
local TestCase = require 'test/TestCase'
local TestSuite = require 'test/TestSuite'
local TextTestRunner = require 'test/TextTestRunner'

test.signal = require 'test/signal'
test.TestResult = require 'test/TestResult'
test.TestCase = TestCase
test.TestSuite = TestSuite
test.TestRunner = require 'test/TestRunner'
test.TextTestResult = require 'test/TextTestResult'
test.TextTestRunner = TextTestRunner


---Copies command-line arguments into `options`.
---@param options omi.test.RunOptions
local function parseArgs(options)
    local copy = {}
    for k, v in pairs(options) do copy[k] = v end

    ---@type omi.test.RunOptions
    options = copy
    local args = options.args
    if not args then
        return options
    end

    local i = 1
    while i <= #args do
        local arg = args[i]

        if arg == '-v' or arg == '--verbose' then
            local value = tonumber(args[i + 1]) or 2
            options.verbosity = value
            i = i + 1
        elseif arg == '-o' or arg == '--output' then
            local path = args[i + 1]
            if path then
                options.output = path
            end
        end

        i = i + 1
    end

    return options
end

---Creates a new test suite.
---@param cases omi.test.TestCase[]
---@return omi.test.TestSuite
function test.suite(cases)
    return TestSuite:new(cases)
end

---Creates a new test case class.
---@param name string
---@return omi.test.TestCase
function test.case(name)
    return TestCase:derive(name)
end

---Runs tests on a test suite or a single test case.
---@param cls omi.test.TestCase | omi.test.TestSuite
---@param options omi.test.RunOptions?
function test.run(cls, options)
    ---@type omi.test.RunOptions
    options = parseArgs(options or {})

    ---@type omi.test.TestRunner
    local runner = options.runner or TextTestRunner:new()

    if utils.isinstance(cls, TestCase) then
        ---@cast cls omi.test.TestCase
        cls = test.suite({ cls })
    elseif not utils.isinstance(cls, TestSuite) then
        -- assume argument that isn't case or suite is a list of cases
        ---@cast cls omi.test.TestCase[]
        cls = test.suite(cls)
    end

    ---@cast cls omi.test.TestSuite
    local result = runner:runTests(cls, options)
    if os.exit and utils.default(options.exit, true) then
        local code = result:wasUnsuccessful() and 1 or 0
        os.exit(code)
    end

    return result
end

---Returns true if this function was called from the main chunk.
---If unable to determine whether the function was called from the
---main chunk, this will return false.
---@return boolean
function test.isMain()
    if debug and debug.getlocal and not pcall(debug.getlocal, 5, 1) then
        return true
    end

    return false
end


return test
