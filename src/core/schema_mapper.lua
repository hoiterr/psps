local SchemaMapper = {}

local KEYWORDS = {
    "rank",
    "star",
    "zone",
    "goal",
    "quest",
    "progress",
    "amount",
    "target",
    "required",
    "complete",
}

local function isTable(value)
    return type(value) == "table"
end

local function joinPath(path)
    if #path == 0 then return "<root>" end
    local parts = {}
    for _, key in ipairs(path) do
        table.insert(parts, tostring(key))
    end
    return table.concat(parts, ".")
end

local function looksInteresting(path, key, value)
    local text = string.lower(joinPath(path) .. "." .. tostring(key))
    for _, keyword in ipairs(KEYWORDS) do
        if string.find(text, keyword, 1, true) then
            return true
        end
    end

    if isTable(value) then
        local count = 0
        local matched = 0
        for _, child in pairs(value) do
            count = count + 1
            if isTable(child) then
                if child.Type or child.type or child.Progress or child.progress or child.Amount or child.amount then
                    matched = matched + 1
                end
            end
            if count > 25 then break end
        end
        return matched > 0
    end

    return false
end

local function valuePreview(value)
    if isTable(value) then
        local count = 0
        for _ in pairs(value) do
            count = count + 1
        end
        return "table(" .. tostring(count) .. ")"
    end

    local text = tostring(value)
    if #text > 40 then
        text = string.sub(text, 1, 37) .. "..."
    end
    return text
end

local function walk(root, path, depth, seen, output, limit)
    if not isTable(root) or depth > 6 or #output >= limit then return end
    if seen[root] then return end
    seen[root] = true

    for key, value in pairs(root) do
        local childPath = {}
        for _, part in ipairs(path) do table.insert(childPath, part) end
        table.insert(childPath, key)

        if looksInteresting(path, key, value) then
            table.insert(output, {
                path = joinPath(childPath),
                valueType = type(value),
                preview = valuePreview(value),
            })
            if #output >= limit then return end
        end

        if isTable(value) then
            walk(value, childPath, depth + 1, seen, output, limit)
            if #output >= limit then return end
        end
    end
end

function SchemaMapper.Map(source, limit)
    local output = {}
    if not isTable(source) then
        return output
    end

    walk(source, {}, 0, {}, output, limit or 80)
    table.sort(output, function(a, b)
        return a.path < b.path
    end)
    return output
end

function SchemaMapper.Format(mapping)
    if not mapping or #mapping == 0 then
        return "No rank/goal-like paths found."
    end

    local lines = {}
    for _, item in ipairs(mapping) do
        table.insert(lines, string.format(
            "%s | %s | %s",
            tostring(item.path),
            tostring(item.valueType),
            tostring(item.preview)
        ))
    end
    return table.concat(lines, "\n")
end

return SchemaMapper
