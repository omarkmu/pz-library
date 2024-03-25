---Module containing functionality for string interpolation.
---@class omi.interpolate
---@field Parser omi.interpolate.Parser
---@field Interpolator omi.interpolate.Interpolator
---@field MultiMap omi.interpolate.MultiMap
local interpolate = {}

interpolate.Parser = require 'interpolate/Parser'
interpolate.Interpolator = require 'interpolate/Interpolator'
interpolate.MultiMap = require 'interpolate/MultiMap'


---Performs string interpolation.
---@param text string
---@param tokens table?
---@param options omi.interpolate.Options?
---@return string
function interpolate.interpolate(text, tokens, options)
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
