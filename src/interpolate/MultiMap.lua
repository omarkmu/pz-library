local utils = require 'utils'
local class = require 'class'
local entry = require 'interpolate/entry'


---Immutable set of key-value entries which permits multiple entries with the same key.
---@class omi.interpolate.MultiMap
---@field protected _entries omi.interpolate.entry[]
---@field protected _map table<unknown, unknown>
---@diagnostic disable-next-line: assign-type-mismatch
local MultiMap = class()


---Returns an iterator for the entries in this multimap.
---@return function
function MultiMap:pairs()
    local i = 0
    return function()
        i = i + 1
        local e = self._entries[i]
        if e then
            return e.key, e.value
        end
    end
end

---Returns an iterator for the keys in this multimap.
---@return function
function MultiMap:keys()
    return utils.mapList(function(e) return e.key end, self._entries)
end

---Returns an iterator for the values in this multimap.
---@return function
function MultiMap:values()
    return utils.mapList(function(e) return e.value end, self._entries)
end

---Concatenates the stringified values of this multimap.
---@param sep string? The separator to use.
---@param i integer? The start index.
---@param j integer? The end index.
---@return string
function MultiMap:concat(sep, i, j)
    return utils.concat(utils.mapList(tostring, self:pairs()), sep, i, j)
end

---Returns the value of the first entry in the multimap.
---@return unknown?
function MultiMap:first()
    local e = self._entries[1]
    if e then
        return e.value
    end
end

---Returns the value of the last entry in the multimap.
---@return unknown?
function MultiMap:last()
    local e = self._entries[#self._entries]
    if e then
        return e.value
    end
end

---Returns the nth entry in the multimap.
---@param n integer
---@return omi.interpolate.entry?
function MultiMap:entry(n)
    local e = self._entries[n]
    if e then
        return utils.copy(e)
    end
end

---Returns the number of entries in this multimap.
---@return integer
function MultiMap:size()
    return #self._entries
end

---Returns a multimap with only the unique values from this multimap.
---@return omi.interpolate.MultiMap
function MultiMap:unique()
    local seen = {}
    local entries = {}
    for key, value in self:pairs() do
        if not seen[value] then
            entries[#entries + 1] = entry(key, value)
            seen[value] = true
        end
    end

    return MultiMap:new(entries)
end

---Returns true if there is a value associated with the given key.
---@param key unknown
---@return boolean
function MultiMap:has(key)
    return self._map[key] ~= nil
end

---Gets the first value associated with a key.
---@param key unknown The key to query.
---@param default unknown? A default value to return if there are no entries associated with the key.
---@return unknown?
function MultiMap:get(key, default)
    local list = self._map[key]
    if not list then
        return default
    end

    return list[1].value
end

---Gets a MultiMap of entries associated with a key.
---@param key unknown The key to query.
---@param default unknown? A default value to return if there are no entries associated with the key.
---@return unknown?
function MultiMap:index(key, default)
    if not self:has(key) then
        return default
    end

    return MultiMap:new(self._map[key])
end

---Creates a new multimap.
---@param ... (omi.interpolate.entry[] | omi.interpolate.MultiMap) Sources to copy entries from.
---@return omi.interpolate.MultiMap
function MultiMap:new(...)
    local this = setmetatable({}, self)

    local entries = {}
    local map = {}
    for i = 1, select('#', ...) do
        local iter
        local source = select(i, ...)

        if utils.isinstance(source, MultiMap) then
            ---@cast source omi.interpolate.MultiMap
            iter = source.pairs
        elseif type(source) == 'table' then
            iter = ipairs
        end

        if iter then
            for _, e in iter(source) do
                entries[#entries + 1] = e

                if not map[e.key] then
                    map[e.key] = {}
                end

                local mapEntries = map[e.key]
                mapEntries[#mapEntries + 1] = entry(#mapEntries + 1, e.value)
            end
        end
    end

    this._entries = entries
    this._map = map
    return this
end

MultiMap.__tostring = function(self)
    return tostring(self:first() or '')
end

MultiMap.__len = function(self)
    return self:size()
end


return MultiMap
