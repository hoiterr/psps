local UI = {}
UI.LogScroll = nil
UI.LogCounter = 0
UI.AllLogsText = ""

function UI.Log(msg)
    local text = " " .. tostring(msg)
    print(text)
    UI.AllLogsText = UI.AllLogsText .. text .. "\n"
    if not UI.LogScroll then return end

    local success, err = pcall(function()
        UI.LogCounter = (UI.LogCounter or 0) + 1
        local lbl = Instance.new("TextLabel")
        lbl.Name = "LogMsg_" .. UI.LogCounter
        lbl.Size = UDim2.new(1, -10, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Code
        lbl.TextWrapped = true
        lbl.LayoutOrder = UI.LogCounter
        lbl.Parent = UI.LogScroll

        task.spawn(function()
            task.wait(0.1)
            if UI.LogScroll then
                UI.LogScroll.CanvasPosition = Vector2.new(0, 999999)
            end
        end)
    end)

    if not success then
        print("[UI.Log Error]", err)
    end
end

local function makeButton(parent, text, position, size, color)
    local button = Instance.new("TextButton", parent)
    button.Size = size
    button.Position = position
    button.Text = text
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
    return button
end

function UI.Init()
    local player = game:GetService("Players").LocalPlayer

    local parentGUI = nil
    pcall(function() if gethui then parentGUI = gethui() end end)
    if not parentGUI then pcall(function() parentGUI = game:GetService("CoreGui") end) end
    if not parentGUI then parentGUI = player:WaitForChild("PlayerGui") end

    if parentGUI:FindFirstChild("PS99_ValueParser") then
        parentGUI.PS99_ValueParser:Destroy()
    end

    UI.LogCounter = 0
    UI.AllLogsText = ""

    local gui = Instance.new("ScreenGui")
    gui.Name = "PS99_ValueParser"
    gui.ResetOnSpawn = false
    gui.Parent = parentGUI

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 440, 0, 360)
    frame.Position = UDim2.new(0.5, -220, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = " Value Parser"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    title.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    local sampleBtn = makeButton(
        frame,
        "Parse Sample",
        UDim2.new(0, 10, 0, 50),
        UDim2.new(0.33, -12, 0, 38),
        Color3.fromRGB(40, 120, 180)
    )

    local currentBtn = makeButton(
        frame,
        "Parse Current",
        UDim2.new(0.33, 6, 0, 50),
        UDim2.new(0.34, -12, 0, 38),
        Color3.fromRGB(80, 120, 80)
    )

    local copyBtn = makeButton(
        frame,
        "Copy Logs",
        UDim2.new(0.67, 2, 0, 50),
        UDim2.new(0.33, -12, 0, 38),
        Color3.fromRGB(40, 150, 120)
    )

    local planBtn = makeButton(
        frame,
        "Quest Plan",
        UDim2.new(0, 10, 0, 96),
        UDim2.new(1, -20, 0, 32),
        Color3.fromRGB(120, 90, 40)
    )

    UI.LogScroll = Instance.new("ScrollingFrame", frame)
    UI.LogScroll.Size = UDim2.new(1, -20, 1, -150)
    UI.LogScroll.Position = UDim2.new(0, 10, 0, 140)
    UI.LogScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    UI.LogScroll.ScrollBarThickness = 4
    UI.LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", UI.LogScroll).CornerRadius = UDim.new(0, 4)

    local layout = Instance.new("UIListLayout", UI.LogScroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    sampleBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpSampleData()
        end
    end)

    currentBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpCurrentData()
        end
    end)

    planBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Features and shared._PS99.Features.QuestManager then
            UI.Log("======== [QUEST PLAN] ========")
            for line in shared._PS99.Features.QuestManager.FormatQuestPlan():gmatch("([^\n]+)") do
                UI.Log(line)
            end
        end
    end)

    copyBtn.MouseButton1Click:Connect(function()
        local success = pcall(function()
            if setclipboard then
                setclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard.")
            elseif toclipboard then
                toclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard.")
            else
                UI.Log("Clipboard copying is not available in this environment.")
            end
        end)
        if not success then UI.Log("Failed to copy logs.") end
    end)

    UI.Log("UI initialized. Parse a fixture or call Sniffer.ParseSource(table).")
end

return UI
