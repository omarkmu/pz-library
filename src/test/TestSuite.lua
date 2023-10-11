local class = require 'class'

---Base class for test suites.
---@class omi.test.TestSuite : omi.Class
---@field protected _cases omi.test.TestCase[]
local TestSuite = class()


---Returns an iterator over the test suite's cases.
function TestSuite:cases()
    return ipairs(self._cases)
end

---Creates a new test suite.
---@param cases omi.test.TestCase[]
---@return omi.test.TestSuite
function TestSuite:new(cases)
    ---@type omi.test.TestSuite
    local this = setmetatable({}, self)

    this._cases = cases

    return this
end

return TestSuite
