-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Cut a Rock")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local selectedRarity = "Common"
local autoMineEnabled = false

-- 稀有度列表
local rarities = {
    "Common",
    "Uncommon",
    "Rare",
    "Elite",
    "Epic",
    "Legendary",
    "Mythic",
    "Divine",
    "Ancient",
    "Immortal",
    "Eternal",
    "Secret",
    "Hidden",
    "Forbidden",
    "Unknown",
    "Ascended",
    "Cosmic",
    "Ethereal",
    "Primal",
    "Supreme",
    "Limited"
}

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 安全傳送（先載入再傳送）
local function safeTeleport(cf)
    local hrp = getHRP()
    if not hrp or not cf then return false end

    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(cf.Position, 15)
    end)

    task.wait(0.35)

    hrp.CFrame = cf
    return true
end

-- 取得出生點 (workspace.SpawnAlani.SpawnLocation)
local function getSpawnCFrame()
    local spawnAlani = Workspace:FindFirstChild("SpawnAlani")
    if not spawnAlani then
        warn("[Spawn] 找不到 SpawnAlani")
        return nil
    end

    local spawnLocation = spawnAlani:FindFirstChild("SpawnLocation")
    if not spawnLocation then
        warn("[Spawn] 找不到 SpawnLocation")
        return nil
    end

    if spawnLocation:IsA("BasePart") then
        return spawnLocation.CFrame + Vector3.new(0, 3, 0)
    elseif spawnLocation:IsA("Model") then
        if spawnLocation.PrimaryPart then
            return spawnLocation.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        end
        local part = spawnLocation:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
    end

    return nil
end

-- 取得物件 CFrame
local function getObjectCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame + Vector3.new(0, 3, 0)
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        end
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
        return obj:GetPivot() + Vector3.new(0, 3, 0)
    end
    return nil
end

-- 觸發周圍指定距離的 ProximityPrompt
local function fireNearbyPrompts(range)
    range = range or 5
    local hrp = getHRP()
    if not hrp then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent then
                local pos = nil
                if parent:IsA("BasePart") then
                    pos = parent.Position
                elseif parent:IsA("Model") then
                    local part = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
                    if part then
                        pos = part.Position
                    end
                end

                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if dist <= range then
                        pcall(function()
                            fireproximityprompt(obj)
                        end)
                    end
                end
            end
        end
    end
end

-- 搜尋指定稀有度的所有 vein
local function getVeinsByRarity(rarity)
    local targetName = string.lower(rarity) .. "_vein"
    local veins = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == targetName and (obj:IsA("Model") or obj:IsA("BasePart")) then
            table.insert(veins, obj)
        end
    end

    return veins
end

-- 執行 Sell All
local function doSellAll()
    local event = ReplicatedStorage:FindFirstChild("SellEvent")
    if not event then
        warn("[Sell All] 找不到 SellEvent")
        return
    end

    local success, err = pcall(function()
        event:FireServer("SellAll")
    end)

    if success then
        print("[Sell All] 已出售全部")
    else
        warn("[Sell All] 失敗:", err)
    end
end

-- Auto Mine 主迴圈
local function startAutoMine()
    task.spawn(function()
        while autoMineEnabled do
            local veins = getVeinsByRarity(selectedRarity)

            if #veins == 0 then
                warn("[Auto Mine] 找不到 " .. selectedRarity .. " 的 vein")
                task.wait(2)
            else
                print("[Auto Mine] 找到 " .. #veins .. " 個 " .. selectedRarity .. " vein")

                for _, vein in ipairs(veins) do
                    if not autoMineEnabled then break end

                    local cf = getObjectCFrame(vein)
                    if cf then
                        -- 1. 安全傳送到 vein
                        safeTeleport(cf)
                        task.wait(0.3)

                        -- 2. 觸發周圍 5 格的 Prompt
                        fireNearbyPrompts(5)
                        task.wait(0.45)

                        -- 3. 傳回出生點
                        local spawnCF = getSpawnCFrame()
                        if spawnCF then
                            safeTeleport(spawnCF)
                        end
                        task.wait(0.6)
                    end
                end
            end

            task.wait(0.8)
        end
    end)
end

-- ==================== UI ====================
UI:Dropdown("RarityDropdown", "Select Rarity", rarities, function(selected)
    selectedRarity = selected
    print("[Select Rarity] 已選擇:", selected)
end)

UI:Toggle("AutoMineToggle", "Auto Rock", function(enabled)
    autoMineEnabled = enabled
    if enabled then
        startAutoMine()
        print("[Auto Mine] 已開啟")
    else
        print("[Auto Mine] 已關閉")
    end
end)

UI:Button("SellAllButton", "Sell All", function()
    doSellAll()
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
