function ACF.SimpleClass()
    return setmetatable({}, {__call = function(self, ...)
        local obj = setmetatable({}, {__index = self, __tostring = self.ToString})
        if self.__new then self.__new(obj, ...) end
        return obj
    end})
end

function ACF.InheritedClass(baseclass)
    return setmetatable({}, {__index = baseclass, __call = function(self, ...)
        local obj = setmetatable({}, {__index = self, __tostring = self.ToString})
        if self.__new then self.__new(obj, ...) end
        return obj
    end})
end

function ACF.IsTypeOf(object, type)
    return getmetatable(object).__index == type
end