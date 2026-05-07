local ValueExtractor = {}

local function isTable(value)
    return type(value) == "table"
end

local function clone(value, seen)
    if not isTable(value) then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do
        copy[clone(k, seen)] = clone(v, seen)
    end
    return copy
end

local function firstNumber(...)
    for _, value in ipairs({...}) do
        local n = tonumber(value)
        if n then return n end
    end
    return nil
end

local function firstValue(...)
    for _, value in ipairs({...}) do
        if value ~= nil then return value end
    end
    return nil
end

local function getPath(root, path)
    local current = root
    for _, key in ipairs(path) do
        if not isTable(current) then return nil end
        current = current[key]
        if current == nil then return nil end
    end
    return current
end

local function tableLooksLikeGoals(value)
    if not isTable(value) then return false end

    local count = 0
    for _, goal in pairs(value) do
        if isTable(goal) then
            local hasType = goal.Type or goal.type or goal.Name or goal.name or goal.GoalType or goal.goalType
            local hasTarget = goal.Amount or goal.amount or goal.Target or goal.target or goal.Required or goal.required
            local hasProgress = goal.Progress or goal.progress or goal.Current or goal.current or goal.Count or goal.count
            if hasType or hasTarget or hasProgress then
                return true
            end
        end
        count = count + 1
        if count > 30 then break end
    end

    return false
end

local function findGoals(root, depth, seen)
    if not isTable(root) or depth > 5 then return nil end
    seen = seen or {}
    if seen[root] then return nil end
    seen[root] = true

    local direct = root.Goals or root.goals or root.ActiveGoals or root.activeGoals or root.Quests or root.quests
    if tableLooksLikeGoals(direct) then return direct end

    for _, child in pairs(root) do
        if isTable(child) then
            local found = findGoals(child, depth + 1, seen)
            if found then return found end
        end
    end

    return nil
end

local function normalizeGoal(id, goal)
    if not isTable(goal) then
        return {
            id = tostring(id),
            type = "Unknown",
            progress = 0,
            amount = 1,
            raw = goal,
        }
    end

    local amount = firstNumber(goal.Amount, goal.amount, goal.Target, goal.target, goal.Required, goal.required, goal.Needed, goal.needed)
    local progress = firstNumber(goal.Progress, goal.progress, goal.Current, goal.current, goal.Count, goal.count, goal.Done, goal.done)

    return {
        id = tostring(firstValue(goal.Id, goal.id, goal.UID, goal.uid, id)),
        type = tostring(firstValue(goal.Type, goal.type, goal.GoalType, goal.goalType, goal.Name, goal.name, "Unknown")),
        progress = progress or 0,
        amount = amount or 1,
        complete = goal.Complete == true or goal.complete == true or ((progress or 0) >= (amount or 1)),
        raw = clone(goal),
    }
end

function ValueExtractor.Normalize(source)
    local diagnostics = {}

    if not isTable(source) then
        return {
            ok = false,
            diagnostics = {"Source is not a table."},
            rank = 1,
            stars = 0,
            maxZone = nil,
            goals = {},
            raw = source,
        }
    end

    local profile = source
    for _, path in ipairs({
        {"Save"},
        {"Data"},
        {"PlayerData"},
        {"Profile", "Data"},
        {"LocalPlayer", "Data"},
    }) do
        local candidate = getPath(source, path)
        if isTable(candidate) then
            profile = candidate
            table.insert(diagnostics, "Using nested data path: " .. table.concat(path, "."))
            break
        end
    end

    local goalsTable = findGoals(profile, 0) or {}
    if next(goalsTable) == nil then
        table.insert(diagnostics, "No goal-like table found.")
    end

    local goals = {}
    for id, goal in pairs(goalsTable) do
        table.insert(goals, normalizeGoal(id, goal))
    end

    table.sort(goals, function(a, b)
        return tostring(a.id) < tostring(b.id)
    end)

    local rank = firstNumber(profile.Rank, profile.rank, profile.CurrentRank, profile.currentRank, getPath(profile, {"Stats", "Rank"})) or 1
    local stars = firstNumber(profile.Stars, profile.stars, profile.RankStars, profile.rankStars, getPath(profile, {"Stats", "Stars"})) or 0
    local maxZone = firstNumber(profile.MaxZone, profile.maxZone, profile.BestZone, profile.bestZone, profile.Zone, profile.zone, getPath(profile, {"Stats", "MaxZone"}))

    return {
        ok = true,
        diagnostics = diagnostics,
        rank = rank,
        stars = stars,
        maxZone = maxZone,
        goals = goals,
        raw = clone(source),
    }
end

function ValueExtractor.FormatSummary(parsed)
    local lines = {}
    table.insert(lines, "Rank: " .. tostring(parsed.rank))
    table.insert(lines, "Stars: " .. tostring(parsed.stars))
    table.insert(lines, "MaxZone: " .. tostring(parsed.maxZone or "unknown"))
    table.insert(lines, "Goals: " .. tostring(#(parsed.goals or {})))

    for _, note in ipairs(parsed.diagnostics or {}) do
        table.insert(lines, "Note: " .. tostring(note))
    end

    for _, goal in ipairs(parsed.goals or {}) do
        table.insert(lines, string.format(
            "Goal %s | %s | %s/%s | %s",
            tostring(goal.id),
            tostring(goal.type),
            tostring(goal.progress),
            tostring(goal.amount),
            goal.complete and "complete" or "active"
        ))
    end

    return table.concat(lines, "\n")
end

return ValueExtractor
