---@class omi.interpolate.entry
---@field key unknown
---@field value unknown

---Returns an entry with the specified key and value.
---@param key unknown
---@param value unknown
---@return omi.interpolate.entry
return function(key, value)
    return { key = key, value = value }
end
