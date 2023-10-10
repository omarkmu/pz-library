---Module containing utility functions.
---@class omi.utils : omi.utils.string, omi.utils.table, omi.utils.type
local utils = {}


---@type omi.utils.json
utils.json = require('utils/json')


local submodules = {
    require('utils/string'),
    require('utils/table'),
    require('utils/type'),
}

for _, mod in ipairs(submodules) do
    for k, v in pairs(mod) do
        utils[k] = v
    end
end


return utils
