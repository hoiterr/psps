repeat task.wait() until game:IsLoaded()
shared._PS99 = shared._PS99 or { Core = {}, Features = {}, UI = {}, Debug = {} }

do
local Utils = {}

function Utils.FormatNumber(n)
    if not n then return "0" end
    n = tostring(n)
    return n:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function Utils.GetPlayer()
    return game:GetService("Players").LocalPlayer
end

function Utils.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = Utils.DeepCopy(v)
        end
        copy[k] = v
    end
    return copy
end



    shared._PS99.Core.Utils = Utils
end

do
local Network = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkCache = nil

function Network.GetModule()
    if NetworkCache then return NetworkCache end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Network" then
            local success, m = pcall(require, v)
            if success and type(m) == "table" and (m.Fire or m.Invoke) then
                NetworkCache = m
                return m
            end
        end
    end
    return nil
end

local NetworkFolder = ReplicatedStorage:WaitForChild("Network", 5)

-- A robust function to fire any remote safely
function Network.Fire(remoteName, ...)
    if not NetworkFolder then return false end
    
    local remote = NetworkFolder:FindFirstChild(remoteName)
    if not remote then 
        return false 
    end
    
    if remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    elseif remote:IsA("RemoteFunction") then
        local success, result = pcall(function(...) 
            return remote:InvokeServer(...) 
        end, ...)
        
        if success then
            return result
        else
            warn("[Network] Error invoking " .. remoteName .. ":", result)
            return nil
        end
    end
    return false
end

-- A robust function to invoke any remote safely
function Network.Invoke(remoteName, ...)
    if not NetworkFolder then return false end
    
    local remote = NetworkFolder:FindFirstChild(remoteName)
    if not remote then 
        return false 
    end
    
    if remote:IsA("RemoteFunction") then
        local success, result = pcall(function(...) 
            return remote:InvokeServer(...) 
        end, ...)
        
        if success then
            return result
        else
            return nil
        end
    end
    return false
end



    shared._PS99.Core.Network = Network
end

do
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



    shared._PS99.Core.SaveData = SaveData
end

do
local Sniffer = {}

local function cout(msg)
    if shared._PS99 and shared._PS99.UI and shared._PS99.UI.Log then
        shared._PS99.UI.Log(msg)
    else
        print(msg)
    end
end

function Sniffer.DumpGoalsTypes()
    cout("======== [DUMPING GOAL CONFIGS] ========")
    local m = game:GetService("ReplicatedStorage"):FindFirstChild("Goals", true)
    
    local found = false
    -- Usually ReplicatedStorage.Library.Types.Goals
    for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Goals" then
            local success, data = pcall(require, v)
            if success and type(data) == "table" then
                found = true
                for k, goalConfig in pairs(data) do
                    local typeStr = tostring(goalConfig.Type)
                    if not goalConfig.Type and goalConfig.Name then typeStr = tostring(goalConfig.Name) end
                    cout(string.format("[%s] -> %s", tostring(k), typeStr))
                end
                break
            end
        end
    end
    
    if not found then cout("Failed to require Goals config module!") end
    cout("========================================")
end

function Sniffer.DumpSaveData()
    cout("======== [PS99 SAVE UNPACKED] ========")
    
    local data = nil
    
    local foundSave = false
    -- Attempt 1: Dynamic Module Search
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Save" then
            pcall(function()
                local m = require(v)
                if type(m) == "table" and m.Get then
                    local suc, res = pcall(function() return m.Get() end)
                    if suc and type(res) == "table" and res.Goals then
                        data = res
                        foundSave = true
                        cout("-> Found true Save module at: " .. v:GetFullName())
                    end
                end
            end)
        end
        if foundSave then break end
    end
    
    -- Attempt 2: GC (Garbage Collection) Scan
    if not data then
        local gc = getgc and getgc(true) or {}
        for _, v in ipairs(gc) do
            if type(v) == "table" and rawget(v, "Save") then
                if type(v.Save) == "table" and rawget(v.Save, "Get") then
                    local suc, res = pcall(function() return v.Save.Get() end)
                    if suc and type(res) == "table" then
                        data = res
                        break
                    end
                end
            end
            -- Fallbacks
            if type(v) == "table" and rawget(v, "Goals") and rawget(v, "uid") then
                data = v
                break
            end
        end
    end

    local function scanForGoals()
        local gc = getgc and getgc(true) or {}
        for _, v in ipairs(gc) do
            if type(v) == "table" and rawget(v, "Goals") and type(rawget(v, "Goals")) == "table" then
                for id, goal in pairs(rawget(v, "Goals")) do
                    if type(goal) == "table" and rawget(goal, "Type") then
                        return rawget(v, "Goals")
                    end
                end
            end
        end
        return nil
    end

    if not data then
        cout("[Sniffer] Trying aggressive scan for active goals...")
        local activeGoals = scanForGoals()
        
        -- Lets also dump the local player's attributes just in case
        local p = game:GetService("Players").LocalPlayer
        if p then
            cout(string.format("Player Info: %s (MaxZone/Rank might be on attributes)", p.Name))
            for k, v in pairs(p:GetAttributes()) do
                if string.find(string.lower(tostring(k)), "rank") or string.find(string.lower(tostring(k)), "zone") then
                    cout("Attr -> " .. tostring(k) .. ": " .. tostring(v))
                end
            end
        end

        if activeGoals then
            cout("--- ACTIVE GOALS ---")
            local gCount = 0
            for id, goal in pairs(activeGoals) do
                gCount = gCount + 1
                cout(string.format("--- ID: %s ---", tostring(id)))
                for k,v in pairs(goal) do
                    cout(string.format("  %s: %s", tostring(k), tostring(v)))
                end
            end
            if gCount == 0 then cout("Found goals object but it is empty.") end
            cout("======================================")
            return
        end

        cout("[Sniffer] Could not find SaveData via Library or GC!")
        return
    end

    cout("Rank: " .. tostring(data.Rank))
    cout("Stars: " .. tostring(data.Stars))
    cout("MaxZone: " .. tostring(data.MaxZone))
    cout("--- ACTIVE GOALS ---")
    local goals = data.Goals or {}
    local goalCount = 0
    for id, goal in pairs(goals) do
        goalCount = goalCount + 1
        cout(string.format("--- ID: %s ---", tostring(id)))
        for k,v in pairs(goal) do
            cout(string.format("  %s: %s", tostring(k), tostring(v)))
        end
    end
    if goalCount == 0 then
        cout("No active goals found in SaveData.")
    end
    cout("======================================")
end

local isSpying = false
function Sniffer.SpyNetwork()
    if isSpying then 
        cout("[Sniffer] Spy already active!")
        return 
    end
    isSpying = true

    cout("[Sniffer] Scanning ReplicatedStorage for Network/Save modules...")

    local Blacklist = {
        ["PlayerPing"] = true,
        ["Hoverboards_Move"] = true,
        ["World_PlayerMoved"] = true,
        ["State_Update"] = true
    }

    pcall(function()
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("ModuleScript") and v.Name == "Network" then
                local success, m = pcall(require, v)
                if success and type(m) == "table" and (m.Fire or m.Invoke) then
                    cout("-> Hooked Network Module at: " .. v:GetFullName())
                    if m.Fire then
                        local oldF = m.Fire
                        m.Fire = function(...)
                            local args = {...}
                            local name = tostring(args[1])
                            if not Blacklist[name] then
                                local tStr = ""
                                for i=2, math.min(#args, 4) do tStr = tStr .. type(args[i]) .. ", " end
                                task.spawn(function() cout("[Net.F] " .. name .. " | " .. tStr) end)
                            end
                            return oldF(...)
                        end
                    end
                    if m.Invoke then
                        local oldI = m.Invoke
                        m.Invoke = function(...)
                            local args = {...}
                            local name = tostring(args[1])
                            if not Blacklist[name] then
                                local tStr = ""
                                for i=2, math.min(#args, 4) do tStr = tStr .. type(args[i]) .. ", " end
                                task.spawn(function() cout("[Net.I] " .. name .. " | " .. tStr) end)
                            end
                            return oldI(...)
                        end
                    end
                    break
                end
            end
        end
    end)

    cout("[Sniffer] Hooking __namecall as fallback/global grab...")
    if not hookmetamethod then 
        cout("[Sniffer] hookmetamethod missing!")
        return 
    end
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if type(method) == "string" then
            local m = method:lower()
            if m == "fireserver" or m == "invokeserver" then
                if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) and not Blacklist[self.Name] then
                    local args = {...}
                    local tStr = ""
                    for i=1, math.min(#args, 5) do 
                        if type(args[i]) == "table" then tStr = tStr .. "[table], " else tStr = tStr .. tostring(args[i]) .. ", " end
                    end
                    local name = tostring(self.Name)
                    task.spawn(function()
                        cout("[Spy NC] " .. name .. " | " .. tStr)
                    end)
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end



    shared._PS99.Debug.Sniffer = Sniffer
end

do
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
        -- Our extracted remote is exactly "Ranks_ClaimReward"
        Network.Fire("Ranks_ClaimReward", i)
    end
    
    -- Attempt rank up using the exact remote "Ranks_RankUp"
    Network.Fire("Ranks_RankUp")
end



    shared._PS99.Features.QuestManager = QuestManager
end

do
local Farming = {}
local Network = shared._PS99.Core.Network

-- Get all currently loaded breakables in the active zone
function Farming.GetBreakables()
    local breakables = {}
    local workspaceBreakables = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Breakables")
    
    if workspaceBreakables then
        for _, b in pairs(workspaceBreakables:GetChildren()) do
            if b:GetAttribute("Health") and b:GetAttribute("Health") > 0 then
                table.insert(breakables, b)
            end
        end
    end
    return breakables
end

-- Teleport to the best unlocked area
function Farming.TeleportToBestArea()
    -- Big Games zone teleports are usually handled locally
    -- Typically, 'Map' or 'Zones' folder holds the CFrame
    -- We can fire a teleport remote or locally tween
    print("[Farming] Teleporting to best area...")
    local bestZone = "Spawn" -- Stub: You will need logic to determine highest unlocked zone
    Network.Fire("TeleportToZone", bestZone)
end

function Farming.AttackBreakable(breakableId)
    -- Join breakable remote
    Network.Fire("Breakables_PlayerInstaMine", breakableId) -- or "Breakables_Join"
end



    shared._PS99.Features.Farming = Farming
end

do
local UI = {}
UI.LogScroll = nil
UI.LogLayout = nil
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

function UI.Init()
    local player = game:GetService("Players").LocalPlayer
    
    local parentGUI = nil
    pcall(function() if gethui then parentGUI = gethui() end end)
    if not parentGUI then pcall(function() parentGUI = game:GetService("CoreGui") end) end
    if not parentGUI then parentGUI = player:WaitForChild("PlayerGui") end

    if parentGUI:FindFirstChild("PS99_AutoRankHub") then
        parentGUI.PS99_AutoRankHub:Destroy()
    end
    
    UI.LogCounter = 0
    UI.AllLogsText = ""
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "PS99_AutoRankHub"
    gui.ResetOnSpawn = false
    gui.Parent = parentGUI
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 420, 0, 360)
    frame.Position = UDim2.new(0.5, -210, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = " PS99 Auto Rank Hub (Dev Analyzer)"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    title.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)
    
    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0.45, 0, 0, 40)
    toggleBtn.Position = UDim2.new(0, 10, 0, 50)
    toggleBtn.Text = "Auto Rank: OFF"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

    local debugBtn = Instance.new("TextButton", frame)
    debugBtn.Size = UDim2.new(0.45, 0, 0, 40)
    debugBtn.Position = UDim2.new(0.55, -10, 0, 50)
    debugBtn.Text = "Extract Memory"
    debugBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
    debugBtn.TextColor3 = Color3.new(1, 1, 1)
    debugBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", debugBtn).CornerRadius = UDim.new(0, 4)

    local spyBtn = Instance.new("TextButton", frame)
    spyBtn.Size = UDim2.new(0.7, -15, 0, 30)
    spyBtn.Position = UDim2.new(0, 10, 0, 100)
    spyBtn.Text = "Spy Remotes"
    spyBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
    spyBtn.TextColor3 = Color3.new(1, 1, 1)
    spyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", spyBtn).CornerRadius = UDim.new(0, 4)

    local copyBtn = Instance.new("TextButton", frame)
    copyBtn.Size = UDim2.new(0.3, -5, 0, 30)
    copyBtn.Position = UDim2.new(0.7, 5, 0, 100)
    copyBtn.Text = "Copy Logs"
    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 120)
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)
    
    local goalsBtn = Instance.new("TextButton", frame)
    goalsBtn.Size = UDim2.new(1, -20, 0, 30)
    goalsBtn.Position = UDim2.new(0, 10, 0, 140)
    goalsBtn.Text = "Dump Goal Types (For AutoRank)"
    goalsBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 40)
    goalsBtn.TextColor3 = Color3.new(1, 1, 1)
    goalsBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", goalsBtn).CornerRadius = UDim.new(0, 4)
    
    UI.LogScroll = Instance.new("ScrollingFrame", frame)
    UI.LogScroll.Size = UDim2.new(1, -20, 1, -190)
    UI.LogScroll.Position = UDim2.new(0, 10, 0, 180)
    UI.LogScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    UI.LogScroll.ScrollBarThickness = 4
    UI.LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", UI.LogScroll).CornerRadius = UDim.new(0, 4)
    
    UI.LogLayout = Instance.new("UIListLayout", UI.LogScroll)
    UI.LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local active = false
    toggleBtn.MouseButton1Click:Connect(function()
        active = not active
        toggleBtn.Text = active and "Auto Rank: ON" or "Auto Rank: OFF"
        toggleBtn.BackgroundColor3 = active and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(180, 40, 40)
        
        if active then
            UI.Log("Started AutoRank loop...")
            task.spawn(function()
                while active and task.wait(1) do
                    if shared._PS99.Features and shared._PS99.Features.QuestManager then
                        shared._PS99.Features.QuestManager.AutoCompleteQuests()
                        shared._PS99.Features.QuestManager.CheckRankUp()
                    end
                end
            end)
        else
            UI.Log("Stopped AutoRank loop.")
        end
    end)

    debugBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpSaveData()
        end
    end)

    spyBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.SpyNetwork()
        end
    end)

    goalsBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpGoalsTypes()
        end
    end)

    copyBtn.MouseButton1Click:Connect(function()
        local success = pcall(function()
            if setclipboard then
                setclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard!")
            elseif toclipboard then
                toclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard!")
            else
                UI.Log("Executor does not support clipboard copying.")
            end
        end)
        if not success then UI.Log("Failed to copy logs.") end
    end)
    
    UI.Log("UI Initialized. Ready to sniff data!")
end



    shared._PS99.UI = UI
end


-- Autostart UI
if shared._PS99.UI and shared._PS99.UI.Init then
    shared._PS99.UI.Init()
end

print("[PS99 Bundle] Loaded successfully!")
