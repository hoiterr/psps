local SaveData = {}

-- [[ Save Data Scraper ]]
-- In PS99, the LocalPlayer's save data contains everything (Quest progress, inventory, ranks).
-- It is usually managed by a ModuleScript called "Save" inside ReplicatedStorage.Library.Client
-- However, getting it via GC (Garbage Collection) is the most robust method for exploits.

local function GetSaveData()
    local gc = getgc and getgc(true) or {}
    for _, v in ipairs(gc) do
        if type(v) == "table" and rawget(v, "Save") then
            -- We are looking for a table that has goals/quests in it, or is the main overarching save
            if type(v.Save) == "table" and rawget(v.Save, "Get") then
                -- Some frameworks use Library.Save.Get()
                local success, data = pcall(function() return v.Save.Get() end)
                if success and type(data) == "table" and data.Goals then
                    return data
                end
            end
        end
        -- Fallback: Look for a table that straight up has "Goals" or "Rank" fields
        if type(v) == "table" and rawget(v, "Goals") and rawget(v, "Rank") then
            return v
        end
    end
    
    -- Fallback 2: require the library directly
    pcall(function()
        local lib = require(game:GetService("ReplicatedStorage").Library)
        if lib and lib.Save and lib.Save.Get then
            return lib.Save.Get()
        end
    end)
    
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
