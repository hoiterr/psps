repeat task.wait() until game:IsLoaded()
shared._PS99 = shared._PS99 or { Core = {}, Features = {}, UI = {}, Debug = {}, Fixtures = {} }

do
local Utils = {}

function Utils.FormatNumber(n)
    if not n then return "0" end
    n = tostring(n)
    return n:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function Utils.DeepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = Utils.DeepCopy(v)
    end
    return copy
end



    shared._PS99.Core.Utils = Utils
end

do
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



    shared._PS99.Core.ValueExtractor = ValueExtractor
end

do
local SampleSaveData = {
    Profile = {
        Data = {
            Rank = 8,
            Stars = 17,
            MaxZone = 42,
            Goals = {
                daily_1 = {
                    Type = "BreakBreakables",
                    Progress = 37,
                    Amount = 100,
                },
                daily_2 = {
                    Type = "HatchPets",
                    Progress = 12,
                    Amount = 25,
                },
                daily_3 = {
                    Type = "CollectDiamonds",
                    Progress = 5000,
                    Amount = 5000,
                    Complete = true,
                },
            },
        },
    },
}



    shared._PS99.Fixtures.SampleSaveData = SampleSaveData
end

do
local SaveData = {}

local ValueExtractor = shared._PS99.Core.ValueExtractor

local currentSource = nil
local currentParsed = nil

local function parseSource(source)
    currentSource = source
    currentParsed = ValueExtractor.Normalize(source)
    return currentParsed
end

function SaveData.SetSource(source)
    return parseSource(source)
end

function SaveData.UseSample()
    if shared._PS99.Fixtures and shared._PS99.Fixtures.SampleSaveData then
        return parseSource(shared._PS99.Fixtures.SampleSaveData)
    end

    return parseSource({})
end

function SaveData.GetParsed()
    if currentParsed then return currentParsed end
    return SaveData.UseSample()
end

function SaveData.GetGoals()
    return SaveData.GetParsed().goals or {}
end

function SaveData.GetRank()
    return SaveData.GetParsed().rank or 1
end

function SaveData.GetStars()
    return SaveData.GetParsed().stars or 0
end

function SaveData.GetMaxZone()
    return SaveData.GetParsed().maxZone
end

function SaveData.GetSummary()
    return ValueExtractor.FormatSummary(SaveData.GetParsed())
end

function SaveData.GetRawSource()
    return currentSource
end



    shared._PS99.Core.SaveData = SaveData
end

do
local Sniffer = {}

local SaveData = shared._PS99.Core.SaveData
local ValueExtractor = shared._PS99.Core.ValueExtractor

local function cout(msg)
    if shared._PS99 and shared._PS99.UI and shared._PS99.UI.Log then
        shared._PS99.UI.Log(msg)
    else
        print(msg)
    end
end

local function printLines(text)
    for line in tostring(text):gmatch("([^\n]+)") do
        cout(line)
    end
end

function Sniffer.ParseSource(source, label)
    cout("======== [VALUE PARSE] ========")
    cout("Source: " .. tostring(label or "custom table"))

    local parsed = SaveData.SetSource(source)
    printLines(ValueExtractor.FormatSummary(parsed))

    cout("======== [QUEST PLAN] ========")
    if shared._PS99.Features and shared._PS99.Features.QuestManager then
        printLines(shared._PS99.Features.QuestManager.FormatQuestPlan())
    else
        cout("QuestManager is not loaded.")
    end

    cout("===============================")
    return parsed
end

function Sniffer.DumpSampleData()
    if not (shared._PS99.Fixtures and shared._PS99.Fixtures.SampleSaveData) then
        cout("[Parser] Sample fixture is not loaded.")
        return nil
    end

    return Sniffer.ParseSource(shared._PS99.Fixtures.SampleSaveData, "sample_savedata.lua")
end

function Sniffer.DumpCurrentData()
    return Sniffer.ParseSource(SaveData.GetRawSource() or {}, "current source")
end

function Sniffer.SpyNetwork()
    cout("[Parser] Remote spying is disabled in this safe debug build.")
    cout("[Parser] Use Sniffer.ParseSource(table) with a pasted or fixture table instead.")
end



    shared._PS99.Debug.Sniffer = Sniffer
end

do
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



    shared._PS99.Features.QuestManager = QuestManager
end

do
local Farming = {}

function Farming.GetBreakables()
    return {}
end

function Farming.TeleportToBestArea()
    print("[Farming] Disabled in safe parser build.")
end

function Farming.AttackBreakable()
    print("[Farming] Disabled in safe parser build.")
end



    shared._PS99.Features.Farming = Farming
end

do
local UI = {}
UI.LogScroll = nil
UI.LogCounter = 0
UI.AllLogsText = ""

function UI.Log(msg)
    local text = " " .. tostring(msg)
    print(text)
    UI.AllLogsText = UI.AllLogsText .. text .. "\n"
    if not UI.LogScroll then return end

    local success, err = pcall(function()
        UI.LogCounter = (UI.LogCounter or 0) + 1
        local lbl = Instance.new("TextLabel")
        lbl.Name = "LogMsg_" .. UI.LogCounter
        lbl.Size = UDim2.new(1, -10, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Code
        lbl.TextWrapped = true
        lbl.LayoutOrder = UI.LogCounter
        lbl.Parent = UI.LogScroll

        task.spawn(function()
            task.wait(0.1)
            if UI.LogScroll then
                UI.LogScroll.CanvasPosition = Vector2.new(0, 999999)
            end
        end)
    end)

    if not success then
        print("[UI.Log Error]", err)
    end
end

local function makeButton(parent, text, position, size, color)
    local button = Instance.new("TextButton", parent)
    button.Size = size
    button.Position = position
    button.Text = text
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
    return button
end

function UI.Init()
    local player = game:GetService("Players").LocalPlayer

    local parentGUI = nil
    pcall(function() if gethui then parentGUI = gethui() end end)
    if not parentGUI then pcall(function() parentGUI = game:GetService("CoreGui") end) end
    if not parentGUI then parentGUI = player:WaitForChild("PlayerGui") end

    if parentGUI:FindFirstChild("PS99_ValueParser") then
        parentGUI.PS99_ValueParser:Destroy()
    end

    UI.LogCounter = 0
    UI.AllLogsText = ""

    local gui = Instance.new("ScreenGui")
    gui.Name = "PS99_ValueParser"
    gui.ResetOnSpawn = false
    gui.Parent = parentGUI

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 440, 0, 360)
    frame.Position = UDim2.new(0.5, -220, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = " Value Parser"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    title.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    local sampleBtn = makeButton(
        frame,
        "Parse Sample",
        UDim2.new(0, 10, 0, 50),
        UDim2.new(0.33, -12, 0, 38),
        Color3.fromRGB(40, 120, 180)
    )

    local currentBtn = makeButton(
        frame,
        "Parse Current",
        UDim2.new(0.33, 6, 0, 50),
        UDim2.new(0.34, -12, 0, 38),
        Color3.fromRGB(80, 120, 80)
    )

    local copyBtn = makeButton(
        frame,
        "Copy Logs",
        UDim2.new(0.67, 2, 0, 50),
        UDim2.new(0.33, -12, 0, 38),
        Color3.fromRGB(40, 150, 120)
    )

    local planBtn = makeButton(
        frame,
        "Quest Plan",
        UDim2.new(0, 10, 0, 96),
        UDim2.new(1, -20, 0, 32),
        Color3.fromRGB(120, 90, 40)
    )

    UI.LogScroll = Instance.new("ScrollingFrame", frame)
    UI.LogScroll.Size = UDim2.new(1, -20, 1, -150)
    UI.LogScroll.Position = UDim2.new(0, 10, 0, 140)
    UI.LogScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    UI.LogScroll.ScrollBarThickness = 4
    UI.LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", UI.LogScroll).CornerRadius = UDim.new(0, 4)

    local layout = Instance.new("UIListLayout", UI.LogScroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    sampleBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpSampleData()
        end
    end)

    currentBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpCurrentData()
        end
    end)

    planBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Features and shared._PS99.Features.QuestManager then
            UI.Log("======== [QUEST PLAN] ========")
            for line in shared._PS99.Features.QuestManager.FormatQuestPlan():gmatch("([^\n]+)") do
                UI.Log(line)
            end
        end
    end)

    copyBtn.MouseButton1Click:Connect(function()
        local success = pcall(function()
            if setclipboard then
                setclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard.")
            elseif toclipboard then
                toclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard.")
            else
                UI.Log("Clipboard copying is not available in this environment.")
            end
        end)
        if not success then UI.Log("Failed to copy logs.") end
    end)

    UI.Log("UI initialized. Parse a fixture or call Sniffer.ParseSource(table).")
end



    shared._PS99.UI = UI
end


if shared._PS99.UI and shared._PS99.UI.Init then
    shared._PS99.UI.Init()
end

print("[PS99 Bundle] Loaded safe parser build successfully.")

