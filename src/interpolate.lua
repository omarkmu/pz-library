---Module containing functionality for string interpolation.
---@class omi.interpolate
local interpolate = {}

---@type omi.interpolate.Parser
interpolate.Parser = require 'interpolate/Parser'

---@type omi.interpolate.Interpolator
interpolate.Interpolator = require 'interpolate/Interpolator'

---@type omi.interpolate.MultiMap
interpolate.MultiMap = require 'interpolate/MultiMap'


---Performs string interpolation.
---@param text string
---@param tokens table?
---@param options omi.interpolate.Options?
---@return string
function interpolate.interpolate(text, tokens, options)
    ---@type omi.interpolate.Interpolator
    local interpolator = interpolate.Interpolator:new(options)
    interpolator:setPattern(text)

    return interpolator:interpolate(tokens)
end


setmetatable(interpolate, {
    __call = function(self, ...) return self.interpolate(...) end,
})

---@diagnostic disable-next-line: cast-type-mismatch
---@cast interpolate omi.interpolate | (fun(text: string, tokens: table?, options: omi.interpolate.Options?): string)
return interpolate
