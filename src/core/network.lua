local Network = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkCache = nil

function Network.GetModule()
    if NetworkCache then return NetworkCache end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Network" then
            local success, m = pcall(require, v)
            if success and type(m) == "table" and (m.Fire or m.Invoke) then
                NetworkCache = m
                return m
            end
        end
    end
    return nil
end

local NetworkFolder = ReplicatedStorage:WaitForChild("Network", 5)

-- A robust function to fire any remote safely
function Network.Fire(remoteName, ...)
    local m = Network.GetModule()
    if m and m.Fire then
        return m.Fire(remoteName, ...)
    elseif m and m.Invoke then
        return m.Invoke(remoteName, ...)
    end

    if not NetworkFolder then return false end
    
    local remote = NetworkFolder:FindFirstChild(remoteName)
    if not remote then 
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

return Network
