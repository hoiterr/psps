-- src/debug/sniffer.lua - PS99 Memory Scanner
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

local function isStatsTable(t)
    if type(t) ~= "table" then return false end
    local keys = {}
    for k in pairs(t) do
        if type(k) == "string" then keys[k:lower()] = true end
    end
    local hints = {"rank", "stars", "maxzone", "zone", "coins", "gems", "diamonds", "goals", "quests"}
    local matches = 0
    for _, h in ipairs(hints) do
        if keys[h] then matches = matches + 1 end
    end
    return matches >= 2
end

function Sniffer.ExtractMemory()
    cout("======== [MEMORY SCAN] ========")
    
    -- Method 1: Direct require (PS99 specific)
    cout("Trying: require(Library.Client.Save).Get()...")
    local success, saveModule = pcall(function()
        return require(game:GetService("ReplicatedStorage").Library.Client.Save)
    end)
    if success and type(saveModule) == "table" then
        local ok, saveData = pcall(function() return saveModule.Get() end)
        if ok and type(saveData) == "table" then
            cout("SUCCESS - got save data via direct require!")
            local parsed = SaveData.SetSource(saveData)
            printLines(ValueExtractor.FormatSummary(parsed))
            return parsed
        end
    end
    
    -- Method 2: GC scan
    cout("Trying: getgc() scan...")
    local candidates = {}
    for _, obj in pairs(getgc()) do
        if type(obj) == "table" then
            if isStatsTable(obj) then
                table.insert(candidates, obj)
            end
        end
    end
    cout("Found " .. #candidates .. " candidate tables in GC")
    
    -- Also look for Save module with Get() function
    for _, obj in pairs(getgc()) do
        if type(obj) == "table" then
            for k, v in pairs(obj) do
                if type(k) == "string" and k:lower() == "get" and type(v) == "function" then
                    local ok, result = pcall(function() return obj.Get() end)
                    if ok and type(result) == "table" and isStatsTable(result) then
                        cout("Found Save module in GC with Get() returning stats")
                        table.insert(candidates, result)
                    end
                    break
                end
            end
        end
    end
    
    if #candidates == 0 then
        cout("No candidates found. Save data might not be loaded yet.")
        return nil
    end
    
    local bestResult = nil
    local bestScore = -1
    
    for i, c in ipairs(candidates) do
        cout("--- Candidate " .. i .. " ---")
        local parsed = SaveData.SetSource(c)
        local score = #(parsed.goals or {}) * 10
        if parsed.rank and parsed.rank > 1 then score = score + 5 end
        if parsed.stars and parsed.stars >= 0 then score = score + 3 end
        
        if score > bestScore then
            bestScore = score
            bestResult = parsed
        end
    end
    
    if bestResult then
        cout("======== [BEST RESULT] ========")
        printLines(ValueExtractor.FormatSummary(bestResult))
    end
    
    return bestResult
end

function Sniffer.FullScan()
    return Sniffer.ExtractMemory()
end

-- Keep the original interface
function Sniffer.ParseSource(source, label)
    cout("======== [VALUE PARSE] ========")
    cout("Source: " .. tostring(label or "custom"))
    local parsed = SaveData.SetSource(source)
    printLines(ValueExtractor.FormatSummary(parsed))
    return parsed
end

if success and type(saveModule) == "table" then
        local ok, saveData = pcall(function() return saveModule.Get() end)
        if ok and type(saveData) == "table" then
            cout("SUCCESS - got save data via direct require!")
            -- Try ValueExtractor directly first for diagnostics
            local ValueExtractor = shared._PS99.Core.ValueExtractor
            if ValueExtractor then
                local result = ValueExtractor.Normalize(saveData)
                printLines(ValueExtractor.FormatSummary(result))
            else
                cout("ValueExtractor not available, dumping raw keys:")
                for k, v in pairs(saveData) do
                    cout("  [" .. tostring(k) .. "] = " .. type(v))
                end
            end
            -- Also cache via SaveData
            SaveData.SetSource(saveData)
            return result
        end
    end

function Sniffer.DumpCurrentData()
    return Sniffer.ParseSource(SaveData.GetRawSource() or {}, "current")
end

return Sniffer
