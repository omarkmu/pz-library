local class = require 'class'

local signal = {}


---Signal for test status.
---@class omi.test.Signal : omi.Class
---@field protected _message string? A message about the test status.
local TestSignal = class()

---Creates a new test signal with the specified message.
---@param message unknown
---@return omi.test.Signal
function TestSignal:new(message)
    ---@type omi.test.Signal
    local this = setmetatable({}, self)
    if message ~= nil then
        message = tostring(message)
    end

    this._message = message

    return this
end

---Converts the test signal to a string.
---@param self omi.test.Signal
---@return string
TestSignal.__tostring = function(self)
    return self._message or ''
end


---Signals a skipped test.
---@class omi.test.SkipTestSignal : omi.test.Signal
local Skip = TestSignal:derive()
Skip.__tostring = TestSignal.__tostring

---Returns the reason the test was skipped.
---@return string?
function Skip:reason()
    return self._message
end


---Signals a test failure.
---@class omi.test.FailTestSignal : omi.test.Signal
local Fail = TestSignal:derive()
Fail.__tostring = TestSignal.__tostring

---Returns the failure message.
---@return string?
function Fail:message()
    return self._message
end


signal.Skip = Skip
signal.Fail = Fail

return signal
