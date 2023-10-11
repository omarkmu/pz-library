local deepEquals
local rawget = rawget
local getmetatable = getmetatable
local unpack = unpack or table.unpack ---@diagnostic disable-line: deprecated


---Utilities related to types.
---@class omi.utils.type
local utils = {}


---Checks two values for deep equality.
---@param t1 unknown
---@param t2 unknown
---@param seen table<table, boolean>
---@return boolean
deepEquals = function(t1, t2, seen)
    if type(t1) ~= 'table' then
        return t1 == t2
    elseif type(t1) ~= type(t2) then
        return false
    end

    local t1Meta = getmetatable(t1)
    local t2Meta = getmetatable(t2)

    if seen[t1] then
        return seen[t1] == t2
    end

    if (t1Meta and rawget(t1, '__eq')) or (t2Meta and rawget(t2, '__eq')) then
        return t1 == t2
    end

    local visitedKeys = {}
    seen[t1] = t2
    seen[t2] = t1

    for k, v in pairs(t1) do
        visitedKeys[k] = true
        if not deepEquals(v, t2[k], seen) then
            return false
        end
    end

    for k, v in pairs(t2) do
        if not visitedKeys[k] and not deepEquals(t1[k], v, seen) then
            return false
        end
    end

    return true
end


---Creates a new function given arguments that precede any provided arguments when `func` is called.
---@param func any
---@param ... unknown
---@return function
function utils.bind(func, ...)
    local nArgs = select('#', ...)
    local boundArgs = { ... }

    return function(...)
        local args = { unpack(boundArgs, 1, nArgs) }
        local nNewArgs = select('#', ...)
        for i = 1, nNewArgs do
            args[nArgs + i] = select(i, ...)
        end

        return func(unpack(args, 1, nArgs + nNewArgs))
    end
end

---Checks whether two objects have equivalent values.
---For non-tables, this is equivalent to an equality check.
---Comparison is done by comparing every element.
---Assumes keys are not relevant for deep equality.
---@param t1 unknown
---@param t2 unknown
---@return boolean
function utils.deepEquals(t1, t2)
    return deepEquals(t1, t2, {})
end

---Returns `value` if non-nil. Otherwise, returns `default`.
---@generic T
---@param value? `T`
---@param default T
---@return T
function utils.default(value, default)
    if value ~= nil then
        return value
    end

    return default
end

---Traverses the metatable chain to determine whether an object is an instance of a class.
---@param obj table?
---@param cls table?
---@return boolean
function utils.isinstance(obj, cls)
    if not obj or not cls then
        return false
    end

    local seen = {}
    local meta = getmetatable(obj)
    while meta and not seen[meta] do
        if type(meta) ~= 'table' then
            return false
        end

        if rawget(meta, '__index') == cls then
            return true
        end

        seen[meta] = true
        meta = getmetatable(meta)
    end

    return false
end


return utils
