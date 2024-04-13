---Module containing utility functions.
---@class omi.utils : omi.utils.string, omi.utils.table, omi.utils.type
---@field json omi.utils.json
---@field DelimitedList omi.DelimitedList
local utils = {}


utils.json = require('utils/json')
utils.DelimitedList = require('DelimitedList')


local submodules = {
    require('utils/string'),
    require('utils/table'),
    require('utils/type'),
}

for i = 1, #submodules do
    for k, v in pairs(submodules[i]) do
        utils[k] = v
    end
end


return utils
