local REPO_URL = "https://raw.githubusercontent.com/hoiterr/psps/main"

shared._PS99 = shared._PS99 or { Core = {}, Features = {}, UI = {}, Debug = {}, Fixtures = {} }

local function loadModule(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(REPO_URL .. path))()
    end)
    if not success then
        warn("[PS99 Loader] Failed to load " .. path .. ": " .. tostring(result))
    end
    return result
end

print("[PS99 Loader] Fetching modules from " .. REPO_URL)

shared._PS99.Core.Utils = loadModule("/src/core/utils.lua")
shared._PS99.Core.ValueExtractor = loadModule("/src/core/value_extractor.lua")
shared._PS99.Fixtures.SampleSaveData = loadModule("/src/fixtures/sample_savedata.lua")
shared._PS99.Core.SaveData = loadModule("/src/core/savedata.lua")

shared._PS99.Debug.Sniffer = loadModule("/src/debug/sniffer.lua")

shared._PS99.Features.QuestManager = loadModule("/src/features/quest_manager.lua")
shared._PS99.Features.Farming = loadModule("/src/features/farming.lua")

shared._PS99.UI = loadModule("/src/ui/window.lua")

if shared._PS99.UI and shared._PS99.UI.Init then
    shared._PS99.UI.Init()
end

print("[PS99 Loader] Loaded safe parser build successfully.")
return shared._PS99
