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
    
    -- Attempt 1: Direct Library require (Most common standard in Pet Sim)
    local success, Library = pcall(function() return require(game:GetService("ReplicatedStorage").Library) end)
    if success and type(Library) == "table" and Library.Save and Library.Save.Get then
        local suc, res = pcall(function() return Library.Save.Get() end)
        if suc and res and type(res) == "table" then
            data = res
        end
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
                cout(string.format("ID: %s | Type: %s | Prog: %s/%s", 
                    tostring(id), tostring(goal.Type), tostring(goal.Progress or 0), tostring(goal.Amount or goal.Goal or "?")))
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
        cout(string.format("ID: %s | Type: %s | Progress: %s/%s | Stars: %s", 
            tostring(id), 
            tostring(goal.Type), 
            tostring(goal.Progress or 0), 
            tostring(goal.Amount or goal.Goal or "?"), 
            tostring(goal.Stars or "?")
        ))
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

    local Library
    pcall(function() Library = require(game:GetService("ReplicatedStorage").Library) end)
    
    if Library and Library.Network then
        cout("[Sniffer] Hooking Library.Network module directly (Bypasses executor limits!)")
        
        local oldFire = Library.Network.Fire
        if oldFire then
            Library.Network.Fire = function(...)
                local args = {...}
                local name = tostring(args[1])
                if not Blacklist[name] then
                    local strArgs = ""
                    for i=2, #args do
                        if type(args[i]) == "table" then
                            strArgs = strArgs .. "[table], "
                        else
                            strArgs = strArgs .. tostring(args[i]) .. ", "
                        end
                    end
                    task.spawn(function() cout(string.format("[Spy-F] %s | %s", name, strArgs)) end)
                end
                return oldFire(...)
            end
        end
        
        local oldInvoke = Library.Network.Invoke
        if oldInvoke then
            Library.Network.Invoke = function(...)
                local args = {...}
                local name = tostring(args[1])
                if not Blacklist[name] then
                    local strArgs = ""
                    for i=2, #args do
                        if type(args[i]) == "table" then
                            strArgs = strArgs .. "[table], "
                        else
                            strArgs = strArgs .. tostring(args[i]) .. ", "
                        end
                    end
                    task.spawn(function() cout(string.format("[Spy-I] %s | %s", name, strArgs)) end)
                end
                return oldInvoke(...)
            end
        end
        cout("[Sniffer] Module Hooked successfully!")
        return
    end

    if not hookmetamethod then
        cout("[Sniffer] Fallback: executor lacks hookmetamethod. Cannot spy.")
        return
    end

    cout("[Sniffer] Hooking __namecall as fallback...")
    local NetworkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Network", 5)

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            if typeof(self) == "Instance" and not Blacklist[self.Name] then
                local args = {...}
                local strArgs = ""
                for i, v in ipairs(args) do
                    if type(v) == "table" then
                        strArgs = strArgs .. "[table]" .. (i < #args and ", " or "")
                    else
                        strArgs = strArgs .. tostring(v) .. (i < #args and ", " or "")
                    end
                end
                local name = self.Name
                task.spawn(function()
                    cout(string.format("[Spy] %s | %s", name, strArgs))
                end)
            end
        end
        return oldNamecall(self, ...)
    end)
    cout("[Sniffer] Spy Hooked via __namecall.")
end

return Sniffer
