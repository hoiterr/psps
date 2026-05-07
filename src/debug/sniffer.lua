local Sniffer = {}

local SaveData = shared._PS99.Core.SaveData
local ValueExtractor = shared._PS99.Core.ValueExtractor
local SchemaMapper = shared._PS99.Core.SchemaMapper

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

function Sniffer.ParseSource(source, label)
    cout("======== [VALUE PARSE] ========")
    cout("Source: " .. tostring(label or "custom table"))

    local parsed = SaveData.SetSource(source)
    printLines(ValueExtractor.FormatSummary(parsed))

    cout("======== [SCHEMA MAP] ========")
    if SchemaMapper then
        printLines(SchemaMapper.Format(SchemaMapper.Map(source)))
    else
        cout("SchemaMapper is not loaded.")
    end

    cout("======== [QUEST PLAN] ========")
    if shared._PS99.Features and shared._PS99.Features.QuestManager then
        printLines(shared._PS99.Features.QuestManager.FormatQuestPlan())
    else
        cout("QuestManager is not loaded.")
    end

    cout("======== [RANK PLAN] ========")
    if shared._PS99.Features and shared._PS99.Features.RankPlanner then
        printLines(shared._PS99.Features.RankPlanner.FormatPlan())
    else
        cout("RankPlanner is not loaded.")
    end

    cout("===============================")
    return parsed
end

function Sniffer.DumpSampleData()
    if not (shared._PS99.Fixtures and shared._PS99.Fixtures.SampleSaveData) then
        cout("[Parser] Sample fixture is not loaded.")
        return nil
    end

    return Sniffer.ParseSource(shared._PS99.Fixtures.SampleSaveData, "sample_savedata.lua")
end

function Sniffer.DumpCurrentData()
    return Sniffer.ParseSource(SaveData.GetRawSource() or {}, "current source")
end

function Sniffer.SpyNetwork()
    cout("[Parser] Remote spying is disabled in this safe debug build.")
    cout("[Parser] Use Sniffer.ParseSource(table) with a pasted or fixture table instead.")
end

return Sniffer
