-- src/core/savedata.lua
local SaveData = {}

local SaveModuleCache = nil
local RawSource = nil
local LastNormalized = nil

-- Try to get the raw save data table from PS99 memory
local function GetSaveData()
    -- Try cached module first
    if SaveModuleCache then
        local suc, res = pcall(function() return SaveModuleCache.Get() end)
        if suc and type(res) == "table" then return res end
    end

    -- Scan ReplicatedStorage for a ModuleScript named "Save"
    for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Save" then
            pcall(function()
                local m = require(v)
                if type(m) == "table" and m.Get then
                    local suc, res = pcall(function() return m.Get() end)
                    if suc and type(res) == "table" then
                        SaveModuleCache = m
                        return res
                    end
                end
            end)
        end
        if SaveModuleCache then
            local suc, res = pcall(function() return SaveModuleCache.Get() end)
            if suc and type(res) == "table" then return res end
        end
    end

    -- Try direct ReplicatedStorage path
    local success, result = pcall(function()
        return require(game:GetService("ReplicatedStorage").Library.Client.Save).Get()
    end)
    if success and type(result) == "table" then
        SaveModuleCache = require(game:GetService("ReplicatedStorage").Library.Client.Save)
        return result
    end

    -- Last resort: GC scan for tables with known patterns
    local gc = getgc and getgc(true) or {}
    for _, v in ipairs(gc) do
        if type(v) == "table" then
            local keyCount = 0
            for _ in pairs(v) do keyCount = keyCount + 1 end
            if keyCount > 5 then
                -- Check if it looks like a save data table
                local hasNested = false
                for _, sub in pairs(v) do
                    if type(sub) == "table" then hasNested = true; break end
                end
                if hasNested then
                    -- Check if a Get() method exists on the parent
                    for k2, v2 in pairs(v) do
                        if type(k2) == "string" and k2:lower() == "get" and type(v2) == "function" then
                            local ok, r = pcall(function() return v2() end)
                            if ok and type(r) == "table" then return r end
                        end
                    end
                end
            end
        end
    end

    return nil
end

-- Main entry: get save data and normalize it through ValueExtractor
function SaveData.GetNormalized()
    local raw = GetSaveData()
    if not raw then
        return {
            ok = false,
            diagnostics = {"Could not retrieve save data from memory"},
            rank = 1, stars = 0, maxZone = nil, goals = {},
        }
    end

    RawSource = raw
    local ValueExtractor = shared._PS99.Core.ValueExtractor
    if not ValueExtractor then
        warn("[SaveData] ValueExtractor not loaded!")
        return {
            ok = false,
            diagnostics = {"ValueExtractor not loaded"},
            rank = 1, stars = 0, maxZone = nil, goals = {},
        }
    end

    LastNormalized = ValueExtractor.Normalize(raw)
    return LastNormalized
end

-- Set an external source (used by sniffer for testing/injection)
function SaveData.SetSource(source)
    if type(source) ~= "table" then
        warn("[SaveData] SetSource received non-table")
        return nil
    end
    RawSource = source
    local ValueExtractor = shared._PS99.Core.ValueExtractor
    if ValueExtractor then
        LastNormalized = ValueExtractor.Normalize(source)
        return LastNormalized
    end
    return {
        ok = false,
        diagnostics = {"ValueExtractor not loaded"},
        rank = 1, stars = 0, maxZone = nil, goals = {},
    }
end

function SaveData.GetRawSource()
    return RawSource
end

-- Legacy interface methods (unwrap from normalized)
function SaveData.GetGoals()
    if not LastNormalized then
        SaveData.GetNormalized()
    end
    return LastNormalized and LastNormalized.goals or {}
end

function SaveData.GetRank()
    if not LastNormalized then
        SaveData.GetNormalized()
    end
    return LastNormalized and LastNormalized.rank or 1
end

function SaveData.GetStars()
    if not LastNormalized then
        SaveData.GetNormalized()
    end
    return LastNormalized and LastNormalized.stars or 0
end

function SaveData.GetMaxZone()
    if not LastNormalized then
        SaveData.GetNormalized()
    end
    return LastNormalized and LastNormalized.maxZone
end

function SaveData.GetDiagnostics()
    if not LastNormalized then
        SaveData.GetNormalized()
    end
    return LastNormalized and LastNormalized.diagnostics or {}
end

return SaveData
