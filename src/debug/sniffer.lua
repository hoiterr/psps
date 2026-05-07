local Sniffer = {}

function Sniffer.DumpSaveData()
    print("======== [PS99 SAVE UNPACKED] ========")
    
    local gc = getgc and getgc(true) or {}
    local data = nil
    
    for _, v in ipairs(gc) do
        if type(v) == "table" and rawget(v, "Save") then
            if type(v.Save) == "table" and rawget(v.Save, "Get") then
                local success, res = pcall(function() return v.Save.Get() end)
                if success and type(res) == "table" then
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

    if not data then
        warn("[Sniffer] Could not find SaveData in GC!")
        return
    end

    print("Rank:", data.Rank)
    print("Stars:", data.Stars)
    print("MaxZone:", data.MaxZone)
    print("\n--- ACTIVE GOALS ---")
    local goals = data.Goals or {}
    for id, goal in pairs(goals) do
        print(string.format("ID: %s | Type: %s | Progress: %s/%s | Stars: %s", 
            tostring(id), 
            tostring(goal.Type), 
            tostring(goal.Progress or 0), 
            tostring(goal.Amount or goal.Goal or "?"), 
            tostring(goal.Stars or "?")
        ))
    end
    print("======================================")
end

function Sniffer.SpyNetwork()
    if not hookmetamethod then
        warn("[Sniffer] Your executor does not support hookmetamethod. Cannot log remotes.")
        return
    end

    print("[Sniffer] Hooking __namecall to spy on Network...")
    local NetworkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Network", 5)
    
    -- Very spammy remotes we don't care about when reverse engineering quests
    local Blacklist = {
        ["PlayerPing"] = true,
        ["Breakables_PlayerMineUpdate"] = true,
        ["Pets_SetTarget"] = true,
        ["Hoverboards_Move"] = true,
        ["PerformAction"] = true
    }

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            if self:IsDescendantOf(NetworkFolder) and not Blacklist[self.Name] then
                local args = {...}
                local strArgs = ""
                for i, v in ipairs(args) do
                    strArgs = strArgs .. tostring(v) .. (i < #args and ", " or "")
                end
                print(string.format("[Spy] %s | Method: %s | Args: %s", self.Name, method, strArgs))
            end
        end
        return oldNamecall(self, ...)
    end)
    print("[Sniffer] Network hooked. Open console (F9) to watch remotes as you play!")
end

function Sniffer.Init()
    print("[Sniffer] Initializing Debug Tools...")
    Sniffer.DumpSaveData()
    Sniffer.SpyNetwork()
end

return Sniffer
