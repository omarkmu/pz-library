local class = require 'class'
local split = string.split

---@class omi.DelimitedList : omi.Class
---@field private _cached string
---@field private _delimiter string
---@field private _table table?
---@field private _key string?
---@field private _list string[]
local DelimitedList = class()

---@class omi.DelimitedListOptions
---@field source string? The initial source string. If a table is given, this will be interpreted as the source key to use.
---@field table table? The source table to use to check for the source string.
---@field delimiter string? The delimiter.


---Updates the delimited list by comparing with the underlying string.
---If the string is the same, this has no effect.
---@param str string?
---@return string[] list
function DelimitedList:update(str)
    if not str and self._table and self._key then
        str = self._table[self._key]
    elseif not str then
        str = ''
    end

    str = tostring(str):trim()
    if str == self._cached then
        return self._list
    end

    local list = self._list
    table.wipe(list)

    local elements = split(str, self._delimiter)
    for i = 1, #elements do
        local el = elements[i]:trim()
        if el ~= '' then
            list[#list + 1] = el
        end
    end

    self._cached = str
    return list
end

---Returns the underlying list.
---@return string[]
function DelimitedList:list()
    if self._table and self._key then
        -- if it's in a table, auto-update
        self:update()
    end

    return self._list
end

---Creates a new delimited list.
---@param options omi.DelimitedListOptions?
---@return omi.DelimitedList
function DelimitedList:new(options)
    ---@type omi.DelimitedList
    local this = setmetatable({}, self)
    options = options or {}

    this._cached = ''
    this._list = {}
    this._delimiter = options.delimiter or ';'

    if options.table then
        this._table = options.table
        this._key = options.source
    elseif options.source then
        this:update(options.source)
    end

    return this
end


return DelimitedList
