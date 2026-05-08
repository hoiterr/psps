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

return Sniffer
