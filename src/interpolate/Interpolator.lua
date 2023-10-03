local table = table
local unpack = unpack or table.unpack
local newrandom = newrandom
local class = require 'class'
local utils = require 'utils'
local entry = require 'interpolate/entry'
local MultiMap = require 'interpolate/MultiMap'
local InterpolatorLibraries = require 'interpolate/Libraries'
local InterpolationParser = require 'interpolate/Parser'
local NodeType = InterpolationParser.NodeType


---Handles string interpolation.
---@class omi.interpolate.Interpolator : omi.Class
---@field protected _tokens table<string, unknown>
---@field protected _functions table<string, function>
---@field protected _library table<string, function>
---@field protected _built omi.interpolate.Node[]
---@field protected _allowTokens boolean
---@field protected _allowMultiMaps boolean
---@field protected _allowFunctions boolean
---@field protected _allowCharacterEntities boolean
---@field protected _requireCustomTokenUnderscore boolean
---@field protected _parser omi.interpolate.Parser
---@field protected _rand Random?
local Interpolator = class()

---@type omi.interpolate.Libraries
Interpolator.Libraries = InterpolatorLibraries

---@class omi.interpolate.Options
---@field pattern string? The initial format string of the interpolator.
---@field allowTokens boolean? Whether tokens should be interpreted. If false, tokens will be treated as text.
---@field allowCharacterEntities boolean? Whether character entities should be interpreted. If false, they will be treated as text.
---@field allowMultiMaps boolean? Whether at-maps should be interpreted. If false, they will be treated as text.
---@field allowFunctions boolean? Whether functions should be interpreted. If false, they will be treated as text.
---@field requireCustomTokenUnderscore boolean? Whether custom tokens should require a leading underscore.
---@field libraryInclude table<string, boolean>? Set of library functions or modules to allow. If absent, all will be allowed.
---@field libraryExclude table<string, boolean>? Set of library functions or modules to exclude. If absent, none will be excluded.


---Merges a table of parts.
---If only one part is present, it is returned as-is. Otherwise, the parts are stringified and concatenated.
---@param parts table
---@return unknown
local function mergeParts(parts)
    if #parts == 1 then
        return parts[1]
    end

    return utils.concat(parts)
end


---Evaluates a tree node.
---@param node omi.interpolate.Node The input tree node.
---@param target table? Table to which the result will be appended.
---@return table #Returns the table provided for `target`.
---@protected
function Interpolator:evaluateNode(node, target)
    target = target or {}

    local type = node.type
    local result
    if type == NodeType.text then
        result = node.value
    elseif self._allowTokens and type == NodeType.token then
        result = self:token(node.value)
    elseif self._allowMultiMaps and type == NodeType.at_expression then
        ---@cast node omi.interpolate.AtExpressionNode
        result = self:evaluateAtExpression(node)
    elseif self._allowFunctions and type == NodeType.call then
        ---@cast node omi.interpolate.CallNode
        result = self:evaluateCallNode(node)
    end

    if result then
        target[#target + 1] = self:convert(result)
    end

    return target
end

---Evaluates a node array as a single expression.
---This is used for handling at-map key/value expressions.
---@param nodes omi.interpolate.ValueNode[]
---@return unknown?
---@protected
function Interpolator:evaluateNodeArray(nodes)
    if not nodes then
        return
    end

    local parts = {}
    for _, child in ipairs(nodes) do
        self:evaluateNode(child, parts)
    end

    return mergeParts(parts)
end

---Evaluates an at map expression.
---@param node omi.interpolate.AtExpressionNode
---@return omi.interpolate.MultiMap
---@protected
function Interpolator:evaluateAtExpression(node)
    if not node.entries then
        return MultiMap:new()
    end

    ---@type omi.interpolate.entry[]
    local entries = {}
    for _, e in ipairs(node.entries) do
        local key = self:evaluateNodeArray(e.key)
        local value = self:evaluateNodeArray(e.value)

        if value and not e.key then
            if utils.isinstance(value, MultiMap) then
                -- @(@(A;B) @(C)) → @(A;B;C)
                ---@cast value omi.interpolate.MultiMap
                for entryKey, entryValue in value:pairs() do
                    if self:toBoolean(entryKey) then
                        entries[#entries + 1] = entry(entryKey, entryValue)
                    end
                end
            else
                -- @(A) → @(A:A)
                local keyValue = tostring(value)
                if self:toBoolean(keyValue) then
                    entries[#entries + 1] = entry(keyValue, value)
                end
            end
        elseif utils.isinstance(key, MultiMap) then
            -- @(@(A;B): C) → @(A:C;B:C)
            ---@cast key omi.interpolate.MultiMap
            for _, entryValue in key:pairs() do
                local keyValue = tostring(entryValue)
                if self:toBoolean(keyValue) then
                    entries[#entries + 1] = entry(keyValue, value)
                end
            end
        elseif self:toBoolean(key) then
            -- @(A:B)
            entries[#entries + 1] = entry(key, value)
        end
    end

    return MultiMap:new(entries)
end

---Evaluates a function call expression.
---@param node omi.interpolate.CallNode
---@return unknown?
---@protected
function Interpolator:evaluateCallNode(node)
    local args = {}

    for i, argument in ipairs(node.args) do
        local parts = {}

        for _, child in ipairs(argument) do
            self:evaluateNode(child, parts)
        end

        args[i] = self:convert(mergeParts(parts))
    end

    return self:execute(node.value, args)
end

---Returns a random number.
---@param m integer?
---@param n integer?
---@return number
function Interpolator:random(m, n)
    -- for testing in other environments
    if math.random then
        if m and n then
            return math.random(math.floor(m), math.floor(n))
        elseif m then
            return math.random(math.floor(m))
        end

        return math.random()
    end

    if not self._rand then
        self._rand = newrandom()
    end

    return self._rand:random(m, n)
end

---Returns a random element from a table of options.
---@param options table
---@return unknown?
function Interpolator:randomChoice(options)
    if #options == 0 then
        return
    end

    -- for testing in other environments
    if math.random then
        return options[math.random(#options)]
    end

    if not self._rand then
        self._rand = newrandom()
    end

    return options[self._rand:random(#options)]
end

---Sets the random seed for this interpolator.
---@param seed unknown
function Interpolator:randomseed(seed)
    if math.randomseed then
        -- enable testing in other environments
        seed = tonumber(seed)
        if seed then
            math.randomseed(seed)
        end

        return
    end

    if not self._rand then
        self._rand = newrandom()
    end

    self._rand:seed(seed)
end

---Performs string interpolation and returns a string.
---@param tokens table? Interpolation tokens. If excluded, the current tokens will be unchanged.
---@return string
function Interpolator:interpolate(tokens)
    return tostring(self:interpolateRaw(tokens))
end

---Performs string interpolation.
---@param tokens table? Interpolation tokens. If excluded, the current tokens will be unchanged.
---@return string
function Interpolator:interpolateRaw(tokens)
    if tokens then
        self._tokens = tokens
    end

    local parts = {}
    for _, node in ipairs(self._built) do
        self:evaluateNode(node, parts)
    end

    return mergeParts(parts)
end

---Converts a value to a type that can be used in interpolation functions.
---@param value unknown
---@return unknown
function Interpolator:convert(value)
    if type(value) == 'string' then
        return value
    end

    if utils.isinstance(value, MultiMap) then
        return self._allowMultiMaps and value or tostring(value)
    end

    if not value then
        return ''
    end

    return tostring(value)
end

---Converts a value to a boolean using interpolator logic.
---@param value unknown
function Interpolator:toBoolean(value)
    if utils.isinstance(value, MultiMap) then
        value = tostring(value)
    end

    return value and value ~= ''
end

---Resolves a function given its name.
---@param name string
---@return function?
function Interpolator:getFunction(name)
    return self._functions[name] or self._library[name]
end

---Executes an interpolation function.
---@param name string
---@param args unknown[]
---@return unknown?
function Interpolator:execute(name, args)
    name = name:lower()
    local func = self:getFunction(name)
    if not func then
        return
    end

    return func(self, unpack(args))
end

---Gets the value of an interpolation token.
---@param token unknown
---@return unknown
function Interpolator:token(token)
    return self._tokens[token]
end

---Sets the value of an interpolation token.
---@param token unknown
---@param value unknown
function Interpolator:setToken(token, value)
    self._tokens[token] = value
end

---Sets the value of an interpolation token with additional validation.
---This is called by the $set interpolator function.
---@param token unknown
---@param value unknown
function Interpolator:setTokenValidated(token, value)
    if self._requireCustomTokenUnderscore and not utils.startsWith(token, '_') and self._tokens[token] == nil then
        return
    end

    self:setToken(token, self:convert(value))
end

---Sets the interpolation pattern to use and builds the interpolation tree.
---@param pattern string
function Interpolator:setPattern(pattern)
    pattern = pattern or ''

    if not self._parser then
        self._parser = self:createParser(pattern)
    else
        self._parser:reset(pattern)
    end

    self._built = self._parser:postprocess(self._parser:parse())
end

---Sets library functions which should be allowed and disallowed.
---@param include table<string, true>? A set of functions or modules to allow.
---@param exclude table<string, true>? A set of functions or modules to disallow.
function Interpolator:loadLibraries(include, exclude)
    self._library = InterpolatorLibraries:load(include, exclude)
end

---Creates a parser for this interpolator.
---@param pattern string
---@return omi.interpolate.Parser
---@protected
function Interpolator:createParser(pattern)
    return InterpolationParser:new(pattern, {
        allowTokens = self._allowTokens,
        allowFunctions = self._allowFunctions,
        allowAtExpressions = self._allowMultiMaps,
        allowCharacterEntities = self._allowCharacterEntities,
    })
end

---Creates a new interpolator.
---@param options omi.interpolate.Options?
---@return omi.interpolate.Interpolator
function Interpolator:new(options)
    options = options or {}

    ---@type omi.interpolate.Interpolator
    local this = setmetatable({}, self)

    this._tokens = {}
    this._functions = {}
    this._library = {}
    this._built = {}
    this._allowTokens = utils.default(options.allowTokens, true)
    this._allowMultiMaps = utils.default(options.allowMultiMaps, true)
    this._allowFunctions = utils.default(options.allowFunctions, true)
    this._allowCharacterEntities = utils.default(options.allowCharacterEntities, true)
    this._requireCustomTokenUnderscore = utils.default(options.requireCustomTokenUnderscore, true)

    this:loadLibraries(options.libraryInclude, options.libraryExclude)
    this:setPattern(options.pattern)

    return this
end


return Interpolator
