local Network = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkFolder = ReplicatedStorage:WaitForChild("Network", 10)
if not NetworkFolder then
    warn("[Network] Could not find ReplicatedStorage.Network")
end

-- A robust function to fire any remote safely
function Network.Fire(remoteName, ...)
    if not NetworkFolder then return false end
    
    local remote = NetworkFolder:FindFirstChild(remoteName)
    if not remote then 
        warn("[Network] Remote not found:", remoteName)
        return false 
    end
    
    if remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    elseif remote:IsA("RemoteFunction") then
        local success, result = pcall(function(...) 
            return remote:InvokeServer(...) 
        end, ...)
        
        if success then
            return result
        else
            warn("[Network] Error invoking " .. remoteName .. ":", result)
            return nil
        end
    end
    return false
end

-- Big Games typically uses a generic FireEvent or Invoke method for some systems.
-- Some scripts use require() on their Network module, this allows us to hook easily in the future.
return Network
