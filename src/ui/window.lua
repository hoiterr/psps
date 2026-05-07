local UI = {}
UI.LogScroll = nil
UI.LogLayout = nil
UI.LogCounter = 0

function UI.Log(msg)
    print(tostring(msg))
    if not UI.LogScroll then return end
    
    UI.LogCounter = (UI.LogCounter or 0) + 1
    local lbl = Instance.new("TextLabel")
    lbl.Name = "LogMsg_" .. UI.LogCounter
    lbl.Size = UDim2.new(1, -10, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = " " .. tostring(msg)
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Code
    lbl.TextWrapped = true
    lbl.LayoutOrder = UI.LogCounter
    lbl.Parent = UI.LogScroll
    
    task.spawn(function()
        task.wait(0.05)
        if UI.LogLayout and UI.LogScroll then
            UI.LogScroll.CanvasSize = UDim2.new(0, 0, 0, UI.LogLayout.AbsoluteContentSize.Y + 20)
            UI.LogScroll.CanvasPosition = Vector2.new(0, UI.LogLayout.AbsoluteContentSize.Y + 1000)
        end
    end)
end

function UI.Init()
    local player = game:GetService("Players").LocalPlayer
    if player.PlayerGui:FindFirstChild("PS99_AutoRankHub") then
        player.PlayerGui.PS99_AutoRankHub:Destroy()
    end
    
    UI.LogCounter = 0
    
    local gui = Instance.new("ScreenGui", player.PlayerGui)
    gui.Name = "PS99_AutoRankHub"
    gui.ResetOnSpawn = false
    
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
    spyBtn.Size = UDim2.new(1, -20, 0, 30)
    spyBtn.Position = UDim2.new(0, 10, 0, 100)
    spyBtn.Text = "Spy Remotes (Logs to Console Below)"
    spyBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
    spyBtn.TextColor3 = Color3.new(1, 1, 1)
    spyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", spyBtn).CornerRadius = UDim.new(0, 4)
    
    UI.LogScroll = Instance.new("ScrollingFrame", frame)
    UI.LogScroll.Size = UDim2.new(1, -20, 1, -150)
    UI.LogScroll.Position = UDim2.new(0, 10, 0, 140)
    UI.LogScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    UI.LogScroll.ScrollBarThickness = 4
    Instance.new("UICorner", UI.LogScroll).CornerRadius = UDim.new(0, 4)
    
    UI.LogLayout = Instance.new("UIListLayout", UI.LogScroll)
    UI.LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    UI.LogLayout.GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UI.LogScroll.CanvasSize = UDim2.new(0, 0, 0, UI.LogLayout.AbsoluteContentSize.Y)
        UI.LogScroll.CanvasPosition = Vector2.new(0, UI.LogLayout.AbsoluteContentSize.Y + 100)
    end)
    
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
    
    UI.Log("UI Initialized. Ready to sniff data!")
end

return UI
