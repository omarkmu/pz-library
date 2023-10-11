---@diagnostic disable: inject-field
local setmetatable = setmetatable


---Base class for lightweight classes.
---@class omi.Class
local Class = {}

---Module containing functionality related to creating lightweight classes.
---@class omi.class
local class = {}


---Creates a new class.
local function createClass(cls, base)
    if not base then
        base = Class
    end

    cls = cls or {}
    cls.__index = cls
    base.__index = base

    return setmetatable(cls, base)
end


---Creates a new subclass.
---@param cls table?
---@return omi.Class
function Class:derive(cls)
    return class.derive(self, cls)
end

---Creates a new subclass.
---@param base table
---@param cls table?
---@return omi.Class
function class.derive(base, cls)
    return createClass(cls, base)
end

---Creates a new class.
---@param cls table?
---@return omi.Class
function class.new(cls)
    return createClass(cls)
end


setmetatable(class, {
    __call = function(self, ...) return self.new(...) end,
})


---@diagnostic disable-next-line: cast-type-mismatch
---@cast class omi.class | (fun(cls: table?): omi.Class)
return class
