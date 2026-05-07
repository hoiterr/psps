local Utils = {}

function Utils.FormatNumber(n)
    if not n then return "0" end
    n = tostring(n)
    return n:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function Utils.GetPlayer()
    return game:GetService("Players").LocalPlayer
end

function Utils.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = Utils.DeepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

return Utils
