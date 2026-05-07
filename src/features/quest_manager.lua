local QuestManager = {}
local Network = shared._PS99.Core.Network
local SaveData = shared._PS99.Core.SaveData

-- This feature will handle parsing goals and automating them
function QuestManager.GetActiveQuests()
    -- Big Games stores active goals in SaveData.Goals
    -- They usually look like: [{ Type = "BreakBreakables", Amount = 100, Progress = 25 }]
    return SaveData.GetGoals()
end

function QuestManager.AutoCompleteQuests()
    local activeQuests = QuestManager.GetActiveQuests()
    for id, questData in pairs(activeQuests) do
        -- Check what type of quest it is
        local qType = questData.Type
        local progress = questData.Progress or 0
        local amountNeeded = questData.Amount or 1
        
        if progress < amountNeeded then
            QuestManager.DispatchQuestAction(qType, questData)
        else
            -- Might be ready to claim or just completed automatically
            -- Claim remote can vary, e.g., "Goals_Claim"
            Network.Fire("Goals_Claim", id)
        end
    end
end

-- Route different quest types to their respective actions
function QuestManager.DispatchQuestAction(questType, questData)
    print("[AutoRank] Handling Quest:", questType)
    
    if questType == "BreakBreakables" then
        -- Teleport to highest area and break coins
        
    elseif questType == "HatchPets" then
        -- Go to best egg and hatch it
        
    elseif questType == "CollectDiamonds" then
        -- Break diamond breakables
        
    elseif questType == "UsePotions" then
        -- Pop low tier potions based on required amount
        
    elseif questType == "UpgradeEnchants" then
        -- Go to enchant machine
        
    else
        warn("[AutoRank] Unhandled Quest Type:", questType)
    end
end

-- Rank Up Logic
function QuestManager.CheckRankUp()
    -- Call the Rank Up remote if stars are maxed out for current rank
    -- Note: you need to find the exact remote for this, typically "Rank_Up"
    Network.Fire("Rank_Up")
end

return QuestManager
