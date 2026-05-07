local RankPlanner = {}
local SaveData = shared._PS99.Core.SaveData

local function completionRatio(goal)
    local amount = tonumber(goal.amount) or 1
    if amount <= 0 then return 1 end
    return math.min((tonumber(goal.progress) or 0) / amount, 1)
end

function RankPlanner.GetPlan()
    local parsed = SaveData.GetParsed()
    local goals = parsed.goals or {}
    local complete = 0
    local active = {}

    for _, goal in ipairs(goals) do
        if goal.complete then
            complete = complete + 1
        else
            table.insert(active, {
                id = goal.id,
                type = goal.type,
                progress = goal.progress,
                amount = goal.amount,
                ratio = completionRatio(goal),
            })
        end
    end

    table.sort(active, function(a, b)
        if a.ratio == b.ratio then
            return tostring(a.id) < tostring(b.id)
        end
        return a.ratio > b.ratio
    end)

    return {
        rank = parsed.rank,
        stars = parsed.stars,
        maxZone = parsed.maxZone,
        goalsTotal = #goals,
        goalsComplete = complete,
        goalsRemaining = #active,
        activeGoals = active,
        readyForReview = #goals > 0 and #active == 0,
    }
end

function RankPlanner.FormatPlan()
    local plan = RankPlanner.GetPlan()
    local lines = {}

    table.insert(lines, "Rank: " .. tostring(plan.rank))
    table.insert(lines, "Stars: " .. tostring(plan.stars))
    table.insert(lines, "MaxZone: " .. tostring(plan.maxZone or "unknown"))
    table.insert(lines, string.format(
        "Goals: %s/%s complete",
        tostring(plan.goalsComplete),
        tostring(plan.goalsTotal)
    ))

    if plan.readyForReview then
        table.insert(lines, "Status: all known goals are complete; review rank-up readiness manually.")
    elseif plan.goalsRemaining == 0 then
        table.insert(lines, "Status: no goals found in the current data source.")
    else
        table.insert(lines, "Next focus:")
        for i, goal in ipairs(plan.activeGoals) do
            if i > 5 then break end
            table.insert(lines, string.format(
                "%s | %s | %s/%s | %d%%",
                tostring(goal.id),
                tostring(goal.type),
                tostring(goal.progress),
                tostring(goal.amount),
                math.floor((goal.ratio or 0) * 100)
            ))
        end
    end

    return table.concat(lines, "\n")
end

return RankPlanner
