local QuestManager = {}
local Network = shared._PS99.Core.Network
local SaveData = shared._PS99.Core.SaveData

local UI = shared._PS99.UI

-- This feature will handle parsing goals and automating them
function QuestManager.GetActiveQuests()
    return SaveData.GetGoals()
end

function QuestManager.AutoCompleteQuests()
    local activeQuests = QuestManager.GetActiveQuests()
    for id, questData in pairs(activeQuests) do
        local qType = questData.Type
        local progress = questData.Progress or 0
        local amountNeeded = questData.Amount or questData.Goal or 1
        
        if progress < amountNeeded then
            QuestManager.DispatchQuestAction(qType, questData)
        end
    end
end

-- Route different quest types to their respective actions
function QuestManager.DispatchQuestAction(questType, questData)
    -- We now know questType is an integer (e.g. 14, 40, 42, 44)
    -- Until we map these IDs to actual actions, we just log them if UI exists
end

-- Rank Up Logic
function QuestManager.CheckRankUp()
    -- Attempt to claim any pending rank rewards (1 to 100 is safe range to attempt)
    -- If it fails, nothing bad happens usually.
    for i = 1, 99 do
        -- Typically PS99 rewards are claimed per index
        -- Network.Fire("Ranks_ClaimReward", i)
    end
    
    -- Attempt rank up
    Network.Fire("Ranks_RankUp")
end

return QuestManager
