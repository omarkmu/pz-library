local require, __bundle_register = (function(_require)
    local require
    local loadingPlaceholder = {}
    local modules = {}
    local loaded = {}

    require = function(name)
        local ret = loaded[name]
        if loadingPlaceholder == ret then
            return
        elseif ret == nil then
            if not modules[name] then
                return _require(name)
            end

            loaded[name] = loadingPlaceholder
            ret = modules[name](require)

            if ret == nil then
                loaded[name] = true
            else
                loaded[name] = ret
            end
        end

        return ret
    end

    return require, function(name, body)
        if not modules[name] then
            modules[name] = body
        end
    end
end)(require)
