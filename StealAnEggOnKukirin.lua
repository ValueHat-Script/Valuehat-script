local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local selectedZone = "1"
local autoEggEnabled = false
local equipBestEnabled = false

local zoneList = {}
for i = 1, 10 do
    table.insert(zoneList, tostring(i))
end

local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = cf
        end
    end
end

local function getSafeZoneCF()
    local safeZone = Workspace:FindFirstChild("SafeZone")
    if safeZone then
        return safeZone:GetPivot() or (safeZone:IsA("Model") and safeZone.PrimaryPart and safeZone.PrimaryPart.CFrame) or safeZone.CFrame
    end
    return CFrame.new(0, 5, 0)
end

local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Attachment") then
        return obj.WorldCFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local best, size = nil, 0
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") and d.Size.Magnitude > size then
                best, size = d, d.Size.Magnitude
            end
        end
        if best then return best.CFrame end
        return obj:GetPivot()
    end
    return nil
end

local function findZoneModel(zoneNum)
    local name = "L" .. tostring(zoneNum)
    local spawns = Workspace:FindFirstChild("EggHeistSpawns")
    if spawns then
        return spawns:FindFirstChild(name)
    end
    return nil
end

local function findEggPrompt(eggModel)
    if not eggModel then return nil end

    local eggUnion = eggModel:FindFirstChild("EggUnion", true)
    if eggUnion then
        local promptAt = eggUnion:FindFirstChild("EggPromptAt", true)
        if promptAt then
            local prompt = promptAt:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then return prompt end
        end
    end

    local prompt = eggModel:FindFirstChild("EggPrompt", true)
    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end

    return eggModel:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function findNearbyPrompt(range)
    range = range or 18
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, closestDist = nil, range

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local pos = nil

            if parent and parent:IsA("BasePart") then
                pos = parent.Position
            elseif parent and parent:IsA("Model") then
                local cf = getCFrame(parent)
                if cf then pos = cf.Position end
            elseif parent and parent:IsA("Attachment") then
                pos = parent.WorldPosition
            end

            if pos then
                local dist = (pos - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end

    return closest
end

local function waitForPrompt(eggModel)
    while autoEggEnabled do
        local prompt = findEggPrompt(eggModel)
        if prompt then return prompt end

        prompt = findNearbyPrompt(18)
        if prompt then return prompt end

        task.wait(0.15)
    end
    return nil
end

local function firePromptHold(prompt)
    if not prompt then return end

    local holdTime = prompt.HoldDuration
    if holdTime <= 0 then
        holdTime = 0.5
    end

    pcall(function()
        prompt:InputHoldBegin()
    end)

    task.wait(holdTime + 0.05)

    pcall(function()
        prompt:InputHoldEnd()
    end)

    pcall(function()
        fireproximityprompt(prompt)
    end)
end

local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local zoneModel = findZoneModel(selectedZone)

            if zoneModel then
                local zoneCf = getCFrame(zoneModel)
                if zoneCf then
                    teleportTo(zoneCf + Vector3.new(0, 5, 0))
                    task.wait(0.8)
                end

                local eggs = {}
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if hrp then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and string.find(string.lower(obj.Name), "egg") then
                            local eggCf = getCFrame(obj)
                            if eggCf then
                                local dist = (eggCf.Position - hrp.Position).Magnitude
                                if dist < 150 then
                                    table.insert(eggs, {model = obj, cf = eggCf, dist = dist})
                                end
                            end
                        end
                    end
                end

                if #eggs > 0 then
                    local eggData = eggs[math.random(1, #eggs)]

                    teleportTo(eggData.cf + Vector3.new(0, 3, 0))
                    task.wait(0.3)

                    local prompt = waitForPrompt(eggData.model)

                    if prompt and autoEggEnabled then
                        firePromptHold(prompt)
                        task.wait(0.3)
                    end

                    teleportTo(getSafeZoneCF())
                    task.wait(1)
                else
                    warn("[Auto Egg] Zone L" .. selectedZone .. " 附近找不到蛋")
                    teleportTo(getSafeZoneCF())
                    task.wait(1.5)
                end
            else
                warn("[Auto Egg] 找不到 Zone: EggHeistSpawns.L" .. selectedZone)
                task.wait(2)
            end

            task.wait(0.5)
        end
    end)
end

-- Equip Best
local function equipBest()
    local Event = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Reliable")
    if Event then
        pcall(function()
            Event:FireServer({
                E = 3986368133,
                P = {},
                R = "20"
            })
        end)
    else
        warn("[Equip Best] Remotes.Reliable not found")
    end
end

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            equipBest()
            task.wait(3) -- 每 3 秒自動裝備一次，可自行調整間隔
        end
    end)
end

-- UI
local Hub = UIModule.CreateWindow("Steal an egg on kukirin", "TikTok: ValueHat")

Hub:CreateDropdown("Select Zone", zoneList, selectedZone, function(v)
    selectedZone = v
end)

Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then
        startAutoEgg()
    end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        startEquipBest()
    end
end)
