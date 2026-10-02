-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數
local selectedZone = "1"
local autoEggEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false
local upgradePenEnabled = false
local upgradeTableEnabled = false

-- 即時傳送
local function teleportTo(cframe)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cframe
    end
end

-- ==================== Zone / Auto Egg ====================

local function getZonesFolder()
    return workspace:FindFirstChild("Zones")
end

local function findZoneByNumber(num)
    local zones = getZonesFolder()
    if not zones then return nil end

    local target = "Zone" .. tostring(num)
    for _, child in ipairs(zones:GetChildren()) do
        if child.Name == target or child.Name:match("^" .. target .. "_") then
            return child
        end
    end
    return nil
end

local zoneList = {}
for i = 1, 11 do
    table.insert(zoneList, tostring(i))
end

local function getReturnCFrame()
    local safeZone = workspace:FindFirstChild("SafeZone")
    if not safeZone then return nil end

    if safeZone:IsA("BasePart") then
        return safeZone.CFrame
    elseif safeZone:IsA("Model") then
        return safeZone:GetPivot()
    end

    local part = safeZone:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame
    end
    return nil
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

local function getZoneEggModels(zoneNum)
    local list = {}
    local zone = findZoneByNumber(zoneNum)
    if not zone then return list end

    local eggBeds = zone:FindFirstChild("EggBeds")
    if not eggBeds then return list end

    for _, bed in ipairs(eggBeds:GetChildren()) do
        for _, child in ipairs(bed:GetChildren()) do
            if child:IsA("Model") then
                table.insert(list, child)
            end
        end
    end

    return list
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

    for _, obj in ipairs(workspace:GetDescendants()) do
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

    pcall(function()
        prompt:InputHoldBegin()
    end)

    task.wait(1.3)

    pcall(function()
        prompt:InputHoldEnd()
    end)

    pcall(function()
        fireproximityprompt(prompt)
    end)
end

-- ==================== Auto Hatch ====================

local function getPlacedEggModels()
    local list = {}

    local placedEggs = workspace:FindFirstChild("PlacedEggs", true)
    if placedEggs then
        for _, child in ipairs(placedEggs:GetChildren()) do
            if child:IsA("Model") then
                local uid = child:GetAttribute("Uid")
                if typeof(uid) == "string" and #uid > 10 then
                    table.insert(list, {model = child, uid = uid})
                end
            end
        end
    end

    if #list == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local uid = obj:GetAttribute("Uid")
                if typeof(uid) == "string" and #uid > 10 then
                    table.insert(list, {model = obj, uid = uid})
                end
            end
        end
    end

    return list
end

local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            local eggs = getPlacedEggModels()
            local eggRemotes = ReplicatedStorage:FindFirstChild("EggRemotes")
            local remote = eggRemotes and eggRemotes:FindFirstChild("HatchEgg")

            if remote and #eggs > 0 then
                for _, data in ipairs(eggs) do
                    if not autoHatchEnabled then break end

                    pcall(function()
                        remote:InvokeServer(data.uid)
                    end)

                    task.wait(0.35)
                end
            else
                if not remote then
                    warn("[Auto Hatch] 找不到 EggRemotes.HatchEgg")
                end
                if #eggs == 0 then
                    warn("[Auto Hatch] 找不到有 Uid 的 Egg Model")
                end
                task.wait(2)
            end

            task.wait(1.5)
        end
    end)
end

-- ==================== Equip Best ====================

local function equipBest()
    local petRemotes = ReplicatedStorage:FindFirstChild("PetRemotes")
    local remote = petRemotes and petRemotes:FindFirstChild("EquipBest")
    if remote then
        pcall(function()
            remote:InvokeServer()
        end)
    end
end

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            equipBest()
            task.wait(2)
        end
    end)
end

-- ==================== Upgrade Pen ====================

local function upgradePen()
    local petRemotes = ReplicatedStorage:FindFirstChild("PetRemotes")
    local remote = petRemotes and petRemotes:FindFirstChild("UpgradePen")
    if remote then
        pcall(function()
            remote:InvokeServer()
        end)
    end
end

local function startUpgradePen()
    task.spawn(function()
        while upgradePenEnabled do
            upgradePen()
            task.wait(1.5)
        end
    end)
end

-- ==================== Upgrade Table ====================

local function upgradeTable()
    local tableRemotes = ReplicatedStorage:FindFirstChild("TableRemotes")
    local remote = tableRemotes and tableRemotes:FindFirstChild("Upgrade")
    if remote then
        pcall(function()
            remote:InvokeServer()
        end)
    end
end

local function startUpgradeTable()
    task.spawn(function()
        while upgradeTableEnabled do
            upgradeTable()
            task.wait(1.5)
        end
    end)
end

-- ==================== UI ====================

local Hub = UIModule.CreateWindow("Steal Animal Egg", "TikTok: ValueHat")

Hub:CreateDropdown("Select Zone", zoneList, selectedZone, function(v)
    selectedZone = v
end)

local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local models = getZoneEggModels(selectedZone)

            if #models > 0 then
                local eggModel = models[math.random(1, #models)]
                local cf = getCFrame(eggModel)

                if cf then
                    teleportTo(cf * CFrame.new(0, 4, 0))
                    task.wait(0.35)

                    local prompt = waitForPrompt(eggModel)

                    if prompt and autoEggEnabled then
                        firePromptHold(prompt)
                        task.wait(0.3)
                    end

                    local ret = getReturnCFrame()
                    if ret then
                        teleportTo(ret * CFrame.new(0, 3, 0))
                    end
                    task.wait(0.4)
                end
            else
                warn("[Auto Egg] Zone" .. selectedZone .. " 找不到 Egg Model")
                task.wait(2)
            end

            task.wait(0.6)
        end
    end)
end

Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then startAutoEgg() end
end)

Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then startAutoHatch() end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        equipBest()
        startEquipBest()
    end
end)

Hub:CreateToggle("Upgrade Pen", false, function(on)
    upgradePenEnabled = on
    if on then
        upgradePen()
        startUpgradePen()
    end
end)

Hub:CreateToggle("Upgrade Table", false, function(on)
    upgradeTableEnabled = on
    if on then
        upgradeTable()
        startUpgradeTable()
    end
end)
