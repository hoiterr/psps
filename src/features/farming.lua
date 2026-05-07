local Farming = {}
local Network = shared._PS99.Core.Network

-- Get all currently loaded breakables in the active zone
function Farming.GetBreakables()
    local breakables = {}
    local workspaceBreakables = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Breakables")
    
    if workspaceBreakables then
        for _, b in pairs(workspaceBreakables:GetChildren()) do
            if b:GetAttribute("Health") and b:GetAttribute("Health") > 0 then
                table.insert(breakables, b)
            end
        end
    end
    return breakables
end

-- Teleport to the best unlocked area
function Farming.TeleportToBestArea()
    -- Big Games zone teleports are usually handled locally
    -- Typically, 'Map' or 'Zones' folder holds the CFrame
    -- We can fire a teleport remote or locally tween
    print("[Farming] Teleporting to best area...")
    local bestZone = "Spawn" -- Stub: You will need logic to determine highest unlocked zone
    Network.Fire("TeleportToZone", bestZone)
end

function Farming.AttackBreakable(breakableId)
    -- Join breakable remote
    Network.Fire("Breakables_PlayerInstaMine", breakableId) -- or "Breakables_Join"
end

return Farming
