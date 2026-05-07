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

return SaveData
