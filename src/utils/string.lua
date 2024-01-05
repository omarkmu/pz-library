---Module containing utilities related to formatting and handling strings.
---@class omi.utils.string
local utils = {}


local iso8859Entities = {
    quot = 34,
    amp = 38,
    lt = 60,
    gt = 62,
    nbsp = 160,
    iexcl = 161,
    cent = 162,
    pound = 163,
    curren = 164,
    yen = 165,
    brvbar = 166,
    sect = 167,
    uml = 168,
    copy = 169,
    ordf = 170,
    laquo = 171,
    ['not'] = 172,
    shy = 173,
    reg = 174,
    macr = 175,
    deg = 176,
    plusmn = 177,
    sup2 = 178,
    sup3 = 179,
    acute = 180,
    micro = 181,
    para = 182,
    middot = 183,
    cedil = 184,
    sup1 = 185,
    ordm = 186,
    raquo = 187,
    frac14 = 188,
    frac12 = 189,
    frac34 = 190,
    iquest = 191,
    Agrave = 192,
    Aacute = 193,
    Acirc = 194,
    Atilde = 195,
    Auml = 196,
    Aring = 197,
    AElig = 198,
    Ccedil = 199,
    Egrave = 200,
    Eacute = 201,
    Ecirc = 202,
    Euml = 203,
    Igrave = 204,
    Iacute = 205,
    Icirc = 206,
    Iuml = 207,
    ETH = 208,
    Ntilde = 209,
    Ograve = 210,
    Oacute = 211,
    Ocirc = 212,
    Otilde = 213,
    Ouml = 214,
    times = 215,
    Oslash = 216,
    Ugrave = 217,
    Uacute = 218,
    Ucirc = 219,
    Uuml = 220,
    Yacute = 221,
    THORN = 222,
    szlig = 223,
    agrave = 224,
    aacute = 225,
    acirc = 226,
    atilde = 227,
    auml = 228,
    aring = 229,
    aelig = 230,
    ccedil = 231,
    egrave = 232,
    eacute = 233,
    ecirc = 234,
    euml = 235,
    igrave = 236,
    iacute = 237,
    icirc = 238,
    iuml = 239,
    eth = 240,
    ntilde = 241,
    ograve = 242,
    oacute = 243,
    ocirc = 244,
    otilde = 245,
    ouml = 246,
    divide = 247,
    oslash = 248,
    ugrave = 249,
    uacute = 250,
    ucirc = 251,
    uuml = 252,
    yacute = 253,
    thorn = 254,
    yuml = 255,
}


---Tests if a table is empty or has only keys from `1` to `#t`.
---@param t table
---@return boolean
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
            result[#result + 1] = ','
            result[#result + 1] = space
        end

        isFirst = false

        result[#result + 1] = tab

        if not isNumeric then
            result[#result + 1] = '['
            if type(k) == 'table' then
                -- don't show table keys
                result[#result + 1] = '{...}'
            else
                result[#result + 1] = stringifyPrimitive(k)
            end

            result[#result + 1] = keyEnd
        end

        if type(v) == 'table' then
            result[#result + 1] = stringifyTable(v, seen, pretty, depth + 1, maxDepth)
        else
            result[#result + 1] = stringifyPrimitive(v)
        end
    end

    result[#result + 1] = pretty and (space .. string.rep('    ', depth - 1)) or space
    result[#result + 1] = '}'

    return table.concat(result)
end


---Returns text that's safe for use in a pattern.
---@param text string
---@return string
function utils.escape(text)
    return (text:gsub('([[%]%+-*?().^$])', '%%%1'))
end

---Returns the value of a numeric character reference or character entity reference.
---If the value cannot be resolved, returns `nil`.
---@param entity string
---@return string?
function utils.getEntityValue(entity)
    if entity:sub(1, 1) ~= '&' or entity:sub(#entity) ~= ';' then
        return
    end

    entity = entity:sub(2, #entity - 1)
    if entity:sub(1, 1) ~= '#' then
        local value = iso8859Entities[entity]
        if value then
            return string.char(value)
        end
    end

    local hex = entity:sub(2, 2) == 'x'
    local num = entity:sub(hex and 3 or 2)

    local value = tonumber(num, hex and 16 or 10)
    if not value then
        return
    end

    local success, char = pcall(string.char, value)
    if not success then
        return
    end

    return char
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
    return (text:gsub('^%s*(.*)', '%1'))
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

    local len = #other
    return text:sub(-len) == other
end

---Stringifies a value for display.
---For non-tables, this is equivalent to `tostring.`
---Tables will stringify their values unless a `__tostring` method is present on their metatable.
---@param value unknown
---@param pretty boolean? If true, tables will include newlines and tabs.
---@param maxDepth number? Maximum table depth. Defaults to 5.
---@return string
function utils.stringify(value, pretty, maxDepth)
    if type(value) ~= 'table' then
        return tostring(value)
    end

    return stringifyTable(value, {}, pretty, 1, maxDepth)
end


return utils
