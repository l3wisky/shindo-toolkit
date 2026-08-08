return function(value, children)
    local instance = {
        Value = value,
        children = children or {},
    }

    function instance:FindFirstChild(name)
        return self.children[name]
    end

    return instance
end
