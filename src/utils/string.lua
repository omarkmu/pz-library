---Module containing utilities related to formatting and handling strings.
---@class omi.utils.string
local utils = {}


---Tests if a table is empty or has only keys from 1 to #t.
---@param t table
local function isArray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end

    return true
end

---Stringifies a non-table value.
---@param value unknown
---@return string
local function stringifyPrimitive(value)
    if type(value) == 'string' then
        return string.format('%q', value)
    end

    return tostring(value)
end

---Stringifies a table.
---@param t table
---@param seen table
---@param pretty boolean?
---@param depth number?
---@param maxDepth number?
---@return string
local function stringifyTable(t, seen, pretty, depth, maxDepth)
    depth = depth or 1
    maxDepth = maxDepth or 5

    local mt = getmetatable(t)
    if mt and mt.__tostring then
        return tostring(t)
    end

    if seen[t] then
        return '{...}'
    end

    seen[t] = true

    local isNumeric = isArray(t)
    local space = pretty and '\n' or ' '
    local tab = pretty and string.rep('    ', depth) or ''
    local keyEnd = pretty and '] = ' or ']='

    local result = {
        '{',
        space,
    }

    local iter = isNumeric and ipairs or pairs
    local isFirst = true

    for k, v in iter(t) do
        if not isFirst then
            result[#result+1] = ','
            result[#result+1] = space
        end

        isFirst = false

        result[#result+1] = tab

        if not isNumeric then
            result[#result+1] = '['
            if type(k) == 'table' then
                -- don't show table keys
                result[#result+1] = '{...}'
            else
                result[#result+1] = stringifyPrimitive(k)
            end

            result[#result+1] = keyEnd
        end

        if type(v) == 'table' then
            result[#result+1] = stringifyTable(v, seen, pretty, depth + 1, maxDepth)
        else
            result[#result+1] = stringifyPrimitive(v)
        end
    end

    result[#result+1] = pretty and (space .. string.rep('    ', depth - 1)) or space
    result[#result+1] = '}'

    return table.concat(result)
end

---Returns text that's safe for use in a pattern.
---@param text string
---@return string
function utils.escape(text)
    return (text:gsub('([[%]%+-*?().^$])', '%%%1'))
end

---Removes whitespace from either side of a string.
---@param text string
---@return string
function utils.trim(text)
    return (text:gsub('^%s*(.-)%s*$', '%1'))
end

---Removes whitespace from the start of a string.
---@param text string
---@return string
function utils.trimleft(text)
    return (text:gsub('^%s*(.+)', '%1'))
end

---Removes whitespace from the end of a string.
---@param text string
---@return string
function utils.trimright(text)
    return (text:gsub('(.-)%s*$', '%1'))
end

---Returns true if `text` contains `other`.
---@param text string
---@param other string
---@return boolean
function utils.contains(text, other)
    if not other then
        return false
    elseif #other == 0 then
        return true
    end

    return text:find(other, 1, true) ~= nil
end

---Returns whether a string starts with another string.
---@param text string
---@param other string
---@return boolean
function utils.startsWith(text, other)
    if not other then
        return false
    end

    return text:sub(1, #other) == other
end

---Returns whether a string ends with another string.
---@param text string
---@param other string
---@return boolean
function utils.endsWith(text, other)
    if not other then
        return false
    elseif #other == 0 then
        return true
    end

    return text:sub(-#other) == other
end

---Stringifies a value for display.
---For non-tables, this is equivalent to `tostring.`
---Tables will stringify their values unless a `__tostring` method is present on their metatable.
---@param value unknown
---@param pretty boolean? If true, tables will include newlines and tabs.
---@param maxDepth number? Maximum table depth. Defaults to 5.
function utils.stringify(value, pretty, maxDepth)
    if type(value) ~= 'table' then
        return tostring(value)
    end

    return stringifyTable(value, {}, pretty, 1, maxDepth)
end


return utils
