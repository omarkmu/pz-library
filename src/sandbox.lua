---@diagnostic disable: inject-field
local type = type
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local getSandboxOptions = getSandboxOptions


---Module containing functionality related to sandbox variables.
---@class omi.sandbox
local sandbox = {}

---Helper for retrieving custom sandbox options.
---@class omi.Sandbox
---@field protected _defaults table? Table containing default option values.
---@field protected _name string Name of a mod's sandbox variable table.
local SandboxHelper = {}


---Loads the default values for sandbox options.
function SandboxHelper:loadDefaults()
    if rawget(self, '_defaults') then
        return
    end

    local defaults = {}
    rawset(self, '_defaults', defaults)
    local options = getSandboxOptions()
    for i = 0, options:getNumOptions() - 1 do
        local opt = options:getOptionByIndex(i) ---@type unknown
        if opt:getTableName() == rawget(self, '_name') and opt.getDefaultValue then
            local name = opt:getShortName()
            defaults[name] = opt:getDefaultValue()
        end
    end
end

---Retrieves a sandbox option, or the default for that option.
---@param option string
---@return unknown?
function SandboxHelper:get(option)
    self:loadDefaults()

    local vars = SandboxVars[rawget(self, '_name')]
    local default = rawget(self, '_defaults')[option]
    if not vars or type(vars[option]) ~= type(default) then
        return default
    end

    return vars[option]
end

---Retrieves the default for a sandbox option.
---@param opt string
---@return unknown?
function SandboxHelper:getDefault(opt)
    self:loadDefaults()
    return rawget(self, '_defaults')[opt]
end


---Creates a new sandbox helper.
---@param tableName string The name of the sandbox options table.
---@return omi.Sandbox
function sandbox.new(tableName)
    return setmetatable({ _name = tableName }, SandboxHelper)
end


setmetatable(sandbox, {
    __call = function(self, ...) return self.new(...) end,
})


setmetatable(SandboxHelper, { __index = SandboxHelper.get })
sandbox.Sandbox = SandboxHelper


---@diagnostic disable-next-line: cast-type-mismatch
---@cast sandbox omi.sandbox | (fun(tableName: string): omi.Sandbox)
return sandbox
