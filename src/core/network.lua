local Network = {}

function Network.Fire(remoteName)
    print("[Network] Disabled in safe parser build: " .. tostring(remoteName))
    return false
end

return Network
