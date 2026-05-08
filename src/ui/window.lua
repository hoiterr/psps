local UI = {}
UI.LogScroll = nil
UI.LogLayout = nil
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

function UI.Init()
    local player = game:GetService("Players").LocalPlayer
    
    local parentGUI = nil
    pcall(function() if gethui then parentGUI = gethui() end end)
    if not parentGUI then pcall(function() parentGUI = game:GetService("CoreGui") end) end
    if not parentGUI then parentGUI = player:WaitForChild("PlayerGui") end

    if parentGUI:FindFirstChild("PS99_AutoRankHub") then
        parentGUI.PS99_AutoRankHub:Destroy()
    end
    
    UI.LogCounter = 0
    UI.AllLogsText = ""
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "PS99_AutoRankHub"
    gui.ResetOnSpawn = false
    gui.Parent = parentGUI
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 420, 0, 360)
    frame.Position = UDim2.new(0.5, -210, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = " PS99 Auto Rank Hub (Dev Analyzer)"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    title.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)
    
    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0.45, 0, 0, 40)
    toggleBtn.Position = UDim2.new(0, 10, 0, 50)
    toggleBtn.Text = "Auto Rank: OFF"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

    local debugBtn = Instance.new("TextButton", frame)
    debugBtn.Size = UDim2.new(0.45, 0, 0, 40)
    debugBtn.Position = UDim2.new(0.55, -10, 0, 50)
    debugBtn.Text = "Extract Memory"
    debugBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
    debugBtn.TextColor3 = Color3.new(1, 1, 1)
    debugBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", debugBtn).CornerRadius = UDim.new(0, 4)

    local spyBtn = Instance.new("TextButton", frame)
    spyBtn.Size = UDim2.new(0.7, -15, 0, 30)
    spyBtn.Position = UDim2.new(0, 10, 0, 100)
    spyBtn.Text = "Spy Remotes"
    spyBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
    spyBtn.TextColor3 = Color3.new(1, 1, 1)
    spyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", spyBtn).CornerRadius = UDim.new(0, 4)

    local copyBtn = Instance.new("TextButton", frame)
    copyBtn.Size = UDim2.new(0.3, -5, 0, 30)
    copyBtn.Position = UDim2.new(0.7, 5, 0, 100)
    copyBtn.Text = "Copy Logs"
    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 120)
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)
    
    local goalsBtn = Instance.new("TextButton", frame)
    goalsBtn.Size = UDim2.new(1, -20, 0, 30)
    goalsBtn.Position = UDim2.new(0, 10, 0, 140)
    goalsBtn.Text = "Dump Goal Types (For AutoRank)"
    goalsBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 40)
    goalsBtn.TextColor3 = Color3.new(1, 1, 1)
    goalsBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", goalsBtn).CornerRadius = UDim.new(0, 4)
    
    UI.LogScroll = Instance.new("ScrollingFrame", frame)
    UI.LogScroll.Size = UDim2.new(1, -20, 1, -190)
    UI.LogScroll.Position = UDim2.new(0, 10, 0, 180)
    UI.LogScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    UI.LogScroll.ScrollBarThickness = 4
    UI.LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", UI.LogScroll).CornerRadius = UDim.new(0, 4)
    
    UI.LogLayout = Instance.new("UIListLayout", UI.LogScroll)
    UI.LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local active = false
    toggleBtn.MouseButton1Click:Connect(function()
        active = not active
        toggleBtn.Text = active and "Auto Rank: ON" or "Auto Rank: OFF"
        toggleBtn.BackgroundColor3 = active and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(180, 40, 40)
        
        if active then
            UI.Log("Started AutoRank loop...")
            task.spawn(function()
                while active and task.wait(1) do
                    if shared._PS99.Features and shared._PS99.Features.QuestManager then
                        shared._PS99.Features.QuestManager.AutoCompleteQuests()
                        shared._PS99.Features.QuestManager.CheckRankUp()
                    end
                end
            end)
        else
            UI.Log("Stopped AutoRank loop.")
        end
    end)

    debugBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpSaveData()
        end
    end)

    spyBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.SpyNetwork()
        end
    end)

    goalsBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.DumpGoalsTypes()
        end
    end)

    copyBtn.MouseButton1Click:Connect(function()
        local success = pcall(function()
            if setclipboard then
                setclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard!")
            elseif toclipboard then
                toclipboard(UI.AllLogsText)
                UI.Log("Logs copied to clipboard!")
            else
                UI.Log("Executor does not support clipboard copying.")
            end
        end)
        if not success then UI.Log("Failed to copy logs.") end
    end)
    
    UI.Log("UI Initialized. Ready to sniff data!")
end

return UI
