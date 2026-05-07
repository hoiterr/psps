local SaveData = {}

local SaveModuleCache = nil

local function GetSaveData()
    if SaveModuleCache then
        local suc, res = pcall(function() return SaveModuleCache.Get() end)
        if suc and res and type(res) == "table" then return res end
    end

    for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Save" then
            pcall(function()
                local m = require(v)
                if type(m) == "table" and m.Get then
                    local suc, res = pcall(function() return m.Get() end)
                    if suc and type(res) == "table" and res.Goals then
                        SaveModuleCache = m
                        return res
                    end
                end
            end)
        end
        if SaveModuleCache then
            local suc, res = pcall(function() return SaveModuleCache.Get() end)
            if suc and res and type(res) == "table" then return res end
        end
    end
    
    local gc = getgc and getgc(true) or {}
    for _, v in ipairs(gc) do
        if type(v) == "table" and rawget(v, "Goals") and rawget(v, "Rank") then
            return v
        end
    end
    
    return nil
end

-- Get current goals (quests)
function SaveData.GetGoals()
    local data = GetSaveData()
    if data and data.Goals then
        return data.Goals
    end
    return {}
end

function SaveData.GetRank()
    local data = GetSaveData()
    if data and data.Rank then
        return data.Rank
    end
    return 1
end

function SaveData.GetStars()
    local data = GetSaveData()
    if data and data.Stars then
        return data.Stars
    end
    return 0
end

return SaveData
