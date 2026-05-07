local Sniffer = {}

local function cout(msg)
    if shared._PS99 and shared._PS99.UI and shared._PS99.UI.Log then
        shared._PS99.UI.Log(msg)
    else
        print(msg)
    end
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

    -- Blacklist extremely spammy remotes to not lag mobile devices
    local Blacklist = {
        ["PlayerPing"] = true,
        ["Breakables_PlayerMineUpdate"] = true,
        ["Pets_SetTarget"] = true,
        ["Hoverboards_Move"] = true,
        ["PerformAction"] = true,
        ["Breakables_MineUpdate"] = true,
        ["Breakables_PlayerInstaMine"] = true
    }

    local foundNet = false
    pcall(function()
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("ModuleScript") and v.Name == "Network" then
                local success, m = pcall(require, v)
                if success and type(m) == "table" and (m.Fire or m.Invoke) then
                    cout("-> Hooked Network Module at: " .. v:GetFullName())
                    foundNet = true
                    if m.Fire then
                        local oldF = m.Fire
                        m.Fire = function(...)
                            local args = {...}
                            local name = tostring(args[1])
                            if not Blacklist[name] then
                                task.spawn(function() cout("[Net.Fire] " .. name .. " | arg#: " .. tostring(#args - 1)) end)
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
                                task.spawn(function() cout("[Net.Invoke] " .. name .. " | arg#: " .. tostring(#args - 1)) end)
                            end
                            return oldI(...)
                        end
                    end
                    break
                end
            end
        end
    end)

    if not foundNet then
        cout("[Sniffer] Failed to hook module. Hooking __namecall as fallback...")
        if not hookmetamethod then return end
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                if typeof(self) == "Instance" and not Blacklist[self.Name] then
                    local args = {...}
                    local strArgs = ""
                    for i, v in ipairs(args) do
                        if type(v) == "table" then strArgs = strArgs .. "[table], " else strArgs = strArgs .. tostring(v) .. ", " end
                    end
                    local name = tostring(self.Name)
                    task.spawn(function()
                        cout(string.format("[Spy] %s | %s", name, strArgs))
                    end)
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end

return Sniffer
