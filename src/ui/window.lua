local UI = {}

function UI.Init()
    -- Typically you would use a UI Library here, like Rayfield or Orion
    -- Example loading Rayfield:
    -- local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    print("[UI] Initializing interface...")
    
    -- Mock UI setup
    local player = game.Players.LocalPlayer
    local gui = Instance.new("ScreenGui", player.PlayerGui)
    gui.Name = "PS99_AutoRankHub"
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "PS99 Auto Rank Hub"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    
    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0, 200, 0, 40)
    toggleBtn.Position = UDim2.new(0.5, -100, 0.5, -40)
    toggleBtn.Text = "Toggle Auto Rank"

    local debugBtn = Instance.new("TextButton", frame)
    debugBtn.Size = UDim2.new(0, 200, 0, 40)
    debugBtn.Position = UDim2.new(0.5, -100, 0.5, 10)
    debugBtn.Text = "Run Sniffer (F9)"
    
    local active = false
    toggleBtn.MouseButton1Click:Connect(function()
        active = not active
        toggleBtn.Text = active and "Auto Rank: ON" or "Auto Rank: OFF"
        
        if active then
            -- Starts loop in QuestManager
            spawn(function()
                while active and task.wait(1) do
                    shared._PS99.Features.QuestManager.AutoCompleteQuests()
                    shared._PS99.Features.QuestManager.CheckRankUp()
                end
            end)
        end
    end)

    debugBtn.MouseButton1Click:Connect(function()
        if shared._PS99.Debug and shared._PS99.Debug.Sniffer then
            shared._PS99.Debug.Sniffer.Init()
        end
    end)
end

return UI
