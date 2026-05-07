local REPO_URL = "https://raw.githubusercontent.com/hoiterr/psps/main"

shared._PS99 = shared._PS99 or { Core = {}, Features = {}, UI = {} }

local function loadModule(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(REPO_URL .. path))()
    end)
    if not success then
        warn("[PS99 Loader] Failed to load " .. path .. ": " .. tostring(result))
    end
    return result
end

-- Load Core First
shared._PS99.Core.Utils = loadModule("/src/core/utils.lua")
shared._PS99.Core.Network = loadModule("/src/core/network.lua")
shared._PS99.Core.SaveData = loadModule("/src/core/savedata.lua")

-- Load Features
shared._PS99.Features.QuestManager = loadModule("/src/features/quest_manager.lua")
shared._PS99.Features.Farming = loadModule("/src/features/farming.lua")

-- Load UI
shared._PS99.UI = loadModule("/src/ui/window.lua")

print("[PS99 Loader] Loaded successfully!")
return shared._PS99
