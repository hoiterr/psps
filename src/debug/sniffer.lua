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
            if type(v) == "table" and rawget(v, "Goals") and rawget(v, "Rank") then
                data = v
                break
            end
        end
    end

    if not data then
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

    if not hookmetamethod then
        cout("[Sniffer] Your executor lacks hookmetamethod. Cannot spy.")
        return
    end

    cout("[Sniffer] Hooking __namecall to spy on Network...")
    isSpying = true

    local NetworkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Network", 5)
    
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

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            if self:IsDescendantOf(NetworkFolder) and not Blacklist[self.Name] then
                local args = {...}
                local strArgs = ""
                for i, v in ipairs(args) do
                    if type(v) == "table" then
                        strArgs = strArgs .. "[table]" .. (i < #args and ", " or "")
                    else
                        strArgs = strArgs .. tostring(v) .. (i < #args and ", " or "")
                    end
                end
                cout(string.format("[Spy] %s | %s", self.Name, strArgs))
            end
        end
        return oldNamecall(self, ...)
    end)
    cout("[Sniffer] Spy Hooked. Performing game actions will log remotes here.")
end

return Sniffer
