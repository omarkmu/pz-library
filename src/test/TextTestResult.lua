local format = string.format
local concat = table.concat
local TestResult = require 'test/TestResult'


---Test result which outputs to a stream.
---@class omi.test.TextTestResult : omi.test.TestResult
---@field protected _thinSep string
---@field protected _fullSep string
---@field protected _stream file*?
---@field protected _closeStream boolean?
---@field protected _buffer string[]
local TextTestResult = TestResult:derive()
TextTestResult._fullSep = string.rep('=', 70)
TextTestResult._thinSep = string.rep('-', 70)


---Formats a function name with the available information.
---@param func omi.test.FunctionRecord
---@return string
---@protected
function TextTestResult:_formatFunctionName(func)
    local name = func.name
    local caseName = func.case and func.case:getName()
    if caseName then
        name = format('%s (%s)', name, caseName)
    end

    return name
end

---Prints the status of a test run.
---@param status string
---@param shortStatus string
---@param func omi.test.FunctionRecord?
---@protected
---@diagnostic disable-next-line: unused-local
function TextTestResult:_writeStatus(status, shortStatus, func)
    if not self._inTest then
        -- avoid printing fail/error status for beforeAll/afterAll
        return
    end

    if self._verbosity >= 2 then
        self:_print(status)
    elseif self._verbosity >= 1 then
        self:_write(shortStatus)
    end
end

---Prints to the output.
---@param ... unknown
---@protected
function TextTestResult:_print(...)
    if self._stream then
        self._stream:write(...)
        self._stream:write('\n')
    else
        self._buffer[#self._buffer + 1] = concat({ ... })

        print(concat(self._buffer))

        self._buffer = {}
    end
end

---Prints a formatted string to the output.
---@param f string
---@param ... unknown
---@protected
function TextTestResult:_printf(f, ...)
    self:_print(format(f, ...))
end

---Writes provided arguments to the output with no newline.
---@param ... unknown
---@protected
function TextTestResult:_write(...)
    if self._stream then
        self._stream:write(...)
        self._stream:flush()
    else
        -- printing via stdout → need buffer to avoid newline
        self._buffer[#self._buffer + 1] = concat({ ... })
    end
end

---Prints a list of errors or failures.
---@param errType string
---@param list (omi.test.FailRecord | omi.test.ErrorRecord)[]
---@protected
function TextTestResult:_printErrorList(errType, list)
    if #list == 0 then
        return
    end

    self:_print(self._fullSep)

    for i = 1, #list do
        local err = list[i]
        self:_printf('%s: %s', errType, err.func and self:_formatFunctionName(err.func) or '')
        self:_print(self._thinSep)
        self:_print(err.formattedError)
        self:_print()
    end
end

---Writes the test name to the output.
---@param func omi.test.FunctionRecord
function TextTestResult:startTest(func)
    TestResult.startTest(self, func)

    if self._verbosity >= 2 then
        self:_write(concat { self:_formatFunctionName(func), ' ... ' })
    end
end

---Writes test results to the output.
---@param duration number? The time the tests took in seconds.
function TextTestResult:stopTestRun(duration)
    TestResult.stopTestRun(self, duration)

    if self._verbosity > 0 then
        self:_print()
    end

    self:_printErrorList('ERROR', self.errors)
    self:_printErrorList('FAIL', self.failures)

    self:_print(self._thinSep)

    local suffix = self.testsRun ~= 1 and 's' or ''
    if duration then
        self:_printf('Ran %d test%s in %.3fs', self.testsRun, suffix, duration)
    else
        self:_printf('Ran %d test%s', self.testsRun, suffix)
    end

    self:_print()

    local result = self:wasUnsuccessful() and 'FAILED' or 'OK'
    local details = {}

    if #self.failures > 0 then
        details[#details + 1] = format('failures=%d', #self.failures)
    end

    if #self.errors > 0 then
        details[#details + 1] = format('errors=%d', #self.errors)
    end

    if #self.skipped > 0 then
        details[#details + 1] = format('skipped=%d', #self.skipped)
    end

    if #details > 0 then
        self:_printf('%s (%s)', result, concat(details, ', '))
    else
        self:_print(result)
    end

    if #self._buffer > 0 then
        self:_print()
    end

    if self._stream and self._closeStream then
        self._stream:close()
    end
end

---Adds a success and prints it to the screen.
---@param func omi.test.FunctionRecord
---@return omi.test.SuccessRecord
function TextTestResult:addSuccess(func)
    self:_writeStatus('ok', '.', func)
    return TestResult.addSuccess(self, func)
end

---Adds a skip and prints it to the output.
---@param func omi.test.FunctionRecord
---@param reason string?
---@return omi.test.SkipRecord
function TextTestResult:addSkip(func, reason)
    local status = reason and format("skipped '%s'", reason) or 'skipped'
    self:_writeStatus(status, 's', func)
    return TestResult.addSkip(self, func, reason)
end

---Adds a failure and prints it to the output.
---@param func omi.test.FunctionRecord
---@param failure omi.test.FailTestSignal
---@param traceback string?
---@return omi.test.FailRecord
function TextTestResult:addFail(func, failure, traceback)
    self:_writeStatus('FAIL', 'F', func)
    return TestResult.addFail(self, func, failure, traceback)
end

---Adds an error and prints it to the output.
---@param error unknown
---@param traceback string?
---@param func omi.test.FunctionRecord?
---@return omi.test.ErrorRecord
function TextTestResult:addError(error, traceback, func)
    self:_writeStatus('ERROR', 'E', func)
    return TestResult.addError(self, error, traceback, func)
end

---Creates a new test result type that outputs to a stream.
---@param options omi.test.RunOptions
---@return omi.test.TextTestResult
function TextTestResult:new(options)
    local this = TestResult.new(self, options)
    ---@cast this omi.test.TextTestResult

    if options.stream then
        this._stream = options.stream
    elseif options.output and io and io.open then
        local errmsg
        this._stream, errmsg = io.open(options.output, 'w+')
        this._closeStream = true
        if not this._stream then
            error(format('failed to open output file (%s)', errmsg))
        end
    elseif io and io.stdout then
        this._stream = io.stdout
    end

    this._buffer = {}

    return this
end


return TextTestResult
