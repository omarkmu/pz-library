---Utilities related to tables and functions.
---@class omi.utils.table
local utils = {}


---Returns whether the result of `func` is truthy for all values in `target`.
---@generic T
---@param predicate fun(arg: T): unknown Predicate function.
---@param target table<unknown, T> | (fun(...): T) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return boolean
function utils.all(predicate, target, ...)
    if type(target) == 'table' then
        return utils.all(predicate, pairs(target))
    end

    for _, v in target, ... do
        if not predicate(v) then
            return false
        end
    end

    return true
end

---Returns whether the result of `func` is truthy for any value in `target`.
---@generic T
---@param predicate fun(arg: T): unknown Predicate function.
---@param target table<unknown, T> | (fun(...): T) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return boolean
function utils.any(predicate, target, ...)
    if type(target) == 'table' then
        return utils.any(predicate, pairs(target))
    end

    for _, v in target, ... do
        if predicate(v) then
            return true
        end
    end

    return false
end

---Concatenates a table or stateful iterator function.
---If the input is a table, elements will be converted to strings.
---@param target table | function List or key-value iterator function.
---@param sep string? The separator to use between elements.
---@param i integer? The index at which concatenation should start.
---@param j integer? The index at which concatenation should stop.
---@return string
function utils.concat(target, sep, i, j)
    if type(target) == 'function' then
        target = utils.pack(target)
    else
        target = utils.pack(utils.map(tostring, target))
    end

    return table.concat(target, sep or '', i or 1, j or #target)
end

---Returns a shallow copy of a table.
---@param table table
---@return table
function utils.copy(table)
    local copy = {}

    for k, v in pairs(table) do
        copy[k] = v
    end

    return copy
end

---Returns an iterator with only the values in `target` for which `predicate` is truthy.
---@generic T
---@param predicate fun(value: T): unknown Predicate function.
---@param target table<unknown, T> | (fun(...): T) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return function
function utils.filter(predicate, target, ...)
    if type(target) == 'table' then
        return utils.filter(predicate, pairs(target))
    end

    local value
    local state, control = ...
    return function()
        while true do
            control, value = target(state, control)
            if control == nil then
                break
            end

            if predicate(value) then
                return control, value
            end
        end
    end
end

---Returns an iterator which maps all elements of `target` to the return value of `func`.
---@generic K
---@generic T
---@generic U
---@param func fun(value: T, key: K): U Map function.
---@param target table | (fun(...): T) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return function
function utils.map(func, target, ...)
    if type(target) == 'table' then
        return utils.map(func, pairs(target))
    end

    local value
    local state, control = ...
    return function()
        control, value = target(state, control)
        if control ~= nil then
            return control, func(value, control)
        end
    end
end

---Returns an iterator which maps all elements of `target` to the return value of `func`.
---@generic T
---@generic K
---@generic U
---@param func fun(value: T, key: K, index: integer): U Map function.
---@param target T[] | (fun(...): T) Key-value iterator function or list.
---@param ... unknown Iterator state.
---@return function
function utils.mapList(func, target, ...)
    if type(target) == 'table' then
        return utils.mapList(func, ipairs(target))
    end

    local idx = 0
    local value
    local state, control = ...
    return function()
        control, value = target(state, control)
        if control ~= nil then
            idx = idx + 1
            return idx, func(value, control, idx)
        end
    end
end

---Packs the pairs from an iterator into a table.
---@generic K
---@generic T
---@param iter fun(...): K, T Key-value iterator function.
---@param ... unknown Iterator state.
---@return table<K, T>
function utils.pack(iter, ...)
    if type(iter) == 'table' then
        return iter
    end

    local packed = {}
    for k, v in iter, ... do
        packed[k] = v
    end

    return packed
end

---Applies `acc` cumulatively to all elements of `target` and returns the final value.
---@generic K
---@generic T
---@generic U
---@param acc fun(result: U, element: T, key: K): U Reducer function.
---@param initial U? Initial value.
---@param target table | (fun(...): K, T) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return U
function utils.reduce(acc, initial, target, ...)
    if type(target) == 'table' then
        return utils.reduce(acc, initial, pairs(target))
    end

    local value = initial
    for k, v in target, ... do
        if initial == nil then
            value = v
            initial = true
        else
            value = acc(value, v, k)
        end
    end

    return value
end

---Applies `acc` cumulatively to all elements of `target` and returns the final value.
---Assumes a given table is an array and orders elements accordingly; for maps, use `reduce`.
---@generic K
---@generic T
---@generic U
---@param acc fun(result: U, element: T, key: K): U Reducer function.
---@param initial U? Initial value.
---@param target table | (fun(...): K, T) Key-value iterator function or list.
---@param ... unknown Iterator state.
---@return U
function utils.reduceList(acc, initial, target, ...)
    if type(target) == 'table' then
        return utils.reduce(acc, initial, ipairs(target))
    end

    return utils.reduce(acc, initial, target, ...)
end


return utils
