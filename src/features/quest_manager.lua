local QuestManager = {}
local SaveData = shared._PS99.Core.SaveData

function QuestManager.GetActiveQuests()
    return SaveData.GetGoals()
end

function QuestManager.GetQuestPlan()
    local plan = {}

    for _, questData in ipairs(QuestManager.GetActiveQuests()) do
        local action = "review"

        if questData.complete then
            action = "ready"
        elseif questData.type == "BreakBreakables" then
            action = "farm_breakables"
        elseif questData.type == "HatchPets" then
            action = "hatch"
        elseif questData.type == "CollectDiamonds" then
            action = "collect_diamonds"
        elseif questData.type == "UsePotions" then
            action = "use_potions"
        elseif questData.type == "UpgradeEnchants" then
            action = "upgrade_enchants"
        end

        table.insert(plan, {
            id = questData.id,
            type = questData.type,
            progress = questData.progress,
            amount = questData.amount,
            complete = questData.complete,
            action = action,
        })
    end

    return plan
end

function QuestManager.FormatQuestPlan()
    local lines = {}
    local plan = QuestManager.GetQuestPlan()

    if #plan == 0 then
        return "No quests found in the current data source."
    end

    for _, quest in ipairs(plan) do
        table.insert(lines, string.format(
            "%s | %s | %s/%s | %s",
            tostring(quest.id),
            tostring(quest.type),
            tostring(quest.progress),
            tostring(quest.amount),
            tostring(quest.action)
        ))
    end

    return table.concat(lines, "\n")
end

return QuestManager
