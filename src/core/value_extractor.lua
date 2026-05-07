-- src/core/value_extractor.lua
local ValueExtractor = {}

local function dumpKeys(t, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 3
    if depth > maxDepth or type(t) ~= "table" then return "" end
    
    local lines = {}
    local indent = string.rep("  ", depth)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
        if count > 40 then
            table.insert(lines, indent .. "... (" .. count .. "+ keys)")
            break
        end
        local kStr = tostring(k)
        local vType = type(v)
        if vType == "table" then
            local subCount = 0
            for _ in pairs(v) do subCount = subCount + 1 end
            table.insert(lines, indent .. "[" .. kStr .. "] = {table, " .. subCount .. " keys}")
            if depth < maxDepth then
                local nested = dumpKeys(v, depth + 1, maxDepth)
                if nested ~= "" then
                    table.insert(lines, nested)
                end
            end
        elseif vType == "number" then
            table.insert(lines, indent .. "[" .. kStr .. "] = " .. v)
        elseif vType == "boolean" then
            table.insert(lines, indent .. "[" .. kStr .. "] = " .. tostring(v))
        elseif vType == "string" then
            local s = tostring(v):sub(1, 50)
            table.insert(lines, indent .. "[" .. kStr .. "] = \"" .. s .. "\"")
        elseif vType == "function" then
            table.insert(lines, indent .. "[" .. kStr .. "] = function")
        else
            table.insert(lines, indent .. "[" .. kStr .. "] = " .. vType)
        end
    end
    return table.concat(lines, "\n")
end

local function findVal(t, keys)
    if type(t) ~= "table" then return nil end
    for _, k in ipairs(keys) do
        local v = t[k]
        if v == nil then
            -- case-insensitive fallback
            for k2, v2 in pairs(t) do
                if type(k2) == "string" and k2:lower() == k:lower() then
                    v = v2
                    break
                end
            end
        end
        if v == nil then return nil end
        t = v
    end
    return t
end

function ValueExtractor.Normalize(source)
    local diagnostics = {}

    if type(source) ~= "table" then
        return {
            ok = false,
            diagnostics = {"Source is not a table, got: " .. type(source)},
            rank = 1, stars = 0, maxZone = nil, goals = {}, raw = source,
        }
    end

    -- Dump ALL top-level keys for reverse engineering
    table.insert(diagnostics, "=== TOP-LEVEL KEYS ===")
    for k, v in pairs(source) do
        table.insert(diagnostics, "  [" .. tostring(k) .. "] = " .. type(v))
    end

    -- Try known PS99 save data paths
    local data = source
    local foundPath = false
    
    -- PS99 uses require(Library.Client.Save).Get()
    -- The returned table often has keys like: "Pet", "Hoverboard", "Booth", "Ultimate", plus stats
    for _, path in ipairs({
        {"Data"},
        {"PlayerData"},
        {"Save"},
        {"Profile", "Data"},
        {"LocalPlayer", "Data"},
        {"Stats"},
        {"PlayerSave"},
    }) do
        local cursor = source
        local ok = true
        for _, key in ipairs(path) do
            if type(cursor) ~= "table" then ok = false; break end
            local val = cursor[key]
            if val == nil then
                for k2, v2 in pairs(cursor) do
                    if type(k2) == "string" and k2:lower() == key:lower() then
                        val = v2
                        break
                    end
                end
            end
            if val == nil then ok = false; break end
            cursor = val
        end
        if ok and type(cursor) == "table" then
            data = cursor
            foundPath = true
            table.insert(diagnostics, "Using path: " .. table.concat(path, "."))
            table.insert(diagnostics, dumpKeys(data, 0, 2))
            break
        end
    end

    if not foundPath then
        table.insert(diagnostics, "No known path matched. Dumping source:")
        table.insert(diagnostics, dumpKeys(source, 0, 2))
    end

    -- Extract rank, stars, maxZone using flexible matching
    local rank = findVal(data, {"Rank"}) or findVal(data, {"rank"}) or
                 findVal(data, {"CurrentRank"}) or findVal(data, {"Stats", "Rank"}) or 1
    
    local stars = findVal(data, {"Stars"}) or findVal(data, {"stars"}) or
                  findVal(data, {"RankStars"}) or findVal(data, {"Stats", "Stars"}) or 0
    
    local maxZone = findVal(data, {"MaxZone"}) or findVal(data, {"maxZone"}) or
                    findVal(data, {"BestZone"}) or findVal(data, {"Zone"}) or
                    findVal(data, {"Stats", "MaxZone"})

    -- Deep scan for goals/quests
    local goals = {}
    local function scanForGoals(t, depth, seen)
        if type(t) ~= "table" or depth > 4 then return end
        seen = seen or {}
        if seen[t] then return end
        seen[t] = true
        
        for k, v in pairs(t) do
            if type(v) == "table" then
                -- Check if this table looks like a goals container
                local questCount = 0
                local hasQuestFields = false
                for _, sub in pairs(v) do
                    if type(sub) == "table" then
                        questCount = questCount + 1
                        if sub.Type or sub.type or sub.Progress or sub.progress or 
                           sub.Amount or sub.amount or sub.Target or sub.target then
                            hasQuestFields = true
                        end
                    end
                end
                
                if hasQuestFields and questCount > 0 then
                    table.insert(diagnostics, 
                        "Found goals at key [" .. tostring(k) .. "] with " .. questCount .. " entries")
                    for id, g in pairs(v) do
                        table.insert(goals, {
                            id = tostring(id),
                            type = tostring(g.Type or g.type or g.Name or g.name or "Unknown"),
                            progress = tonumber(g.Progress or g.progress or g.Current or g.current or 0) or 0,
                            amount = tonumber(g.Amount or g.amount or g.Target or g.target or 1) or 1,
                            complete = (g.Complete == true or g.complete == true or 
                                       (tonumber(g.Progress or g.progress or 0) or 0) >= 
                                       (tonumber(g.Amount or g.amount or 1) or 1)),
                        })
                    end
                end
                
                scanForGoals(v, depth + 1, seen)
            end
        end
    end
    scanForGoals(data, 0)
    
    if #goals == 0 then
        table.insert(diagnostics, "No goals found in any sub-table.")
    end

    return {
        ok = true,
        diagnostics = diagnostics,
        rank = tonumber(rank) or 1,
        stars = tonumber(stars) or 0,
        maxZone = tonumber(maxZone),
        goals = goals,
        raw = source,
    }
end

function ValueExtractor.FormatSummary(parsed)
    local lines = {}
    table.insert(lines, "Rank: " .. tostring(parsed.rank))
    table.insert(lines, "Stars: " .. tostring(parsed.stars))
    table.insert(lines, "MaxZone: " .. tostring(parsed.maxZone or "unknown"))
    table.insert(lines, "Goals found: " .. tostring(#(parsed.goals or {})))
    
    for _, note in ipairs(parsed.diagnostics or {}) do
        table.insert(lines, note)
    end
    
    for _, goal in ipairs(parsed.goals or {}) do
        table.insert(lines, string.format(
            "  [%s] %s: %s/%s %s",
            tostring(goal.id),
            tostring(goal.type),
            tostring(goal.progress),
            tostring(goal.amount),
            goal.complete and "COMPLETE" or ""
        ))
    end
    
    return table.concat(lines, "\n")
end

return ValueExtractor
