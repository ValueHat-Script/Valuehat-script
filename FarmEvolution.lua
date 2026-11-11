-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Farm Evolution")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local UPGRADE_INTERVAL = 5    -- Auto Upgrade Pen 發送間隔(秒)
local TREADMILL_INTERVAL = 5  -- Auto Upgrade Treadmill 呼叫間隔(秒)
local EQUIP_INTERVAL = 5      -- Equip Best 呼叫間隔(秒)

local selectedAreaName = nil
local autoEggEnabled = false
local autoUpgradeEnabled = false
local autoTreadmillEnabled = false
local autoEquipEnabled = false

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- 傳送到指定 CFrame
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

-- 取得物件座標
local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return obj:GetPivot()
    end
    return nil
end

-- 取得 StartArea 的座標
local function getStartAreaCFrame()
    local objects = Workspace:FindFirstChild("__OBJECTS")
    local areas = objects and objects:FindFirstChild("Areas")
    local startArea = areas and areas:FindFirstChild("StartArea")
    return getCFrame(startArea)
end

-- 取得指定區域的範圍 (BasePart 形式或 Model 範圍)
local function getAreaPart(areaName)
    local objects = Workspace:FindFirstChild("__OBJECTS")
    local areas = objects and objects:FindFirstChild("Areas")
    local guardAreas = areas and areas:FindFirstChild("GuardAreas")
    if guardAreas then
        local areaObj = guardAreas:FindFirstChild(areaName)
        if areaObj then
            return areaObj
        end
    end
    return nil
end

-- 檢查點是否在區域 (Part) 內部
local function isPositionInArea(pos, areaObj)
    if not areaObj then return false end

    if areaObj:IsA("BasePart") then
        local localPos = areaObj.CFrame:PointToObjectSpace(pos)
        local size = areaObj.Size
        if math.abs(localPos.X) <= size.X / 2 and
           math.abs(localPos.Y) <= size.Y / 2 and
           math.abs(localPos.Z) <= size.Z / 2 then
            return true
        end
    elseif areaObj:IsA("Model") then
        local cf, size = areaObj:GetBoundingBox()
        local localPos = cf:PointToObjectSpace(pos)
        if math.abs(localPos.X) <= size.X / 2 and
           math.abs(localPos.Y) <= size.Y / 2 and
           math.abs(localPos.Z) <= size.Z / 2 then
            return true
        end
    end

    -- 備用方案：如果沒有體積或無法判定，改用距離判定
    local areaCf = getCFrame(areaObj)
    if areaCf and (areaCf.Position - pos).Magnitude <= 60 then
        return true
    end

    return false
end

-- 取得 GuardAreas 的所有選項名稱
local areaOptions = {}
pcall(function()
    local objects = Workspace:FindFirstChild("__OBJECTS")
    local areas = objects and objects:FindFirstChild("Areas")
    local guardAreas = areas and areas:FindFirstChild("GuardAreas")
    if guardAreas then
        for _, child in ipairs(guardAreas:GetChildren()) do
            table.insert(areaOptions, child.Name)
        end
    end
end)

if #areaOptions == 0 then
    areaOptions = {"Area1", "Area2"}
end

-- 觸發範圍內的 ProximityPrompt
local function triggerNearbyPrompts(position, radius)
    local triggeredCount = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local promptPos = nil
            if parent and parent:IsA("BasePart") then
                promptPos = parent.Position
            elseif parent and parent:IsA("Model") then
                local cf = getCFrame(parent)
                if cf then promptPos = cf.Position end
            end

            if promptPos and (promptPos - position).Magnitude <= radius then
                pcall(function()
                    fireproximityprompt(obj)
                    triggeredCount = triggeredCount + 1
                end)
            end
        end
    end
    print("[Auto Egg] 已觸發周圍 Prompt 數量:", triggeredCount)
end

-- Auto Egg 主邏輯
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            pcall(function()
                if not selectedAreaName then
                    task.wait(1)
                    return
                end

                local eggSlotsClient = Workspace:FindFirstChild("AreaEggSlotsClient")
                local targetAreaObj = getAreaPart(selectedAreaName)

                if not eggSlotsClient or not targetAreaObj then
                    task.wait(1)
                    return
                end

                -- 檢查每個蛋是否在所選區域內
                for _, egg in ipairs(eggSlotsClient:GetChildren()) do
                    if not autoEggEnabled then break end
                    if egg:IsA("Model") then
                        local eggCf = getCFrame(egg)
                        if eggCf then
                            if isPositionInArea(eggCf.Position, targetAreaObj) then
                                print("[Auto Egg] 發現區域內的蛋，開始傳送互動")

                                -- 1. 傳送到蛋上方
                                teleportTo(eggCf + Vector3.new(0, 3, 0))
                                task.wait(0.4)

                                -- 2. 觸發周圍 5 範圍內的 Prompt
                                local hrp = getHRP()
                                if hrp then
                                    triggerNearbyPrompts(hrp.Position, 5)
                                end
                                task.wait(0.4)

                                -- 3. 傳回 StartArea
                                local startCf = getStartAreaCFrame()
                                if startCf then
                                    teleportTo(startCf + Vector3.new(0, 3, 0))
                                end

                                task.wait(0.5)
                            end
                        end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

-- Auto Upgrade Pen 主邏輯
local function startAutoUpgrade()
    task.spawn(function()
        local ok, event = pcall(function()
            return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking"):WaitForChild("RE/Homestead/AskBaseTierRaise", 5)
        end)
        if not ok or not event then
            warn("[Auto Upgrade Pen] 找不到 RE/Homestead/AskBaseTierRaise")
            return
        end

        while autoUpgradeEnabled do
            pcall(function()
                event:FireServer()
            end)
            task.wait(UPGRADE_INTERVAL)
        end
    end)
end

-- Auto Upgrade Treadmill 主邏輯
local function startAutoTreadmill()
    task.spawn(function()
        local ok, event = pcall(function()
            return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking"):WaitForChild("RF/Treadmill/AskTierRaise", 5)
        end)
        if not ok or not event then
            warn("[Auto Upgrade Treadmill] 找不到 RF/Treadmill/AskTierRaise")
            return
        end

        while autoTreadmillEnabled do
            local success, result = pcall(function()
                return event:InvokeServer("Sci-FiTreadmill")
            end)
            print("[Auto Upgrade Treadmill] 成功:", success, "| 回傳:", result)
            task.wait(TREADMILL_INTERVAL)
        end
    end)
end

-- Equip Best 主邏輯
local function startAutoEquip()
    task.spawn(function()
        local ok, event = pcall(function()
            return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking"):WaitForChild("RF/Haul/WearBest", 5)
        end)
        if not ok or not event then
            warn("[Equip Best] 找不到 RF/Haul/WearBest")
            return
        end

        while autoEquipEnabled do
            local success, result = pcall(function()
                return event:InvokeServer()
            end)
            print("[Equip Best] 成功:", success, "| 回傳:", result)
            task.wait(EQUIP_INTERVAL)
        end
    end)
end

-- ==================== UI 設定 ====================
UI:Dropdown("AreaDropdown", "Select Area", areaOptions, function(selected)
    selectedAreaName = selected
    print("[Auto Egg] 已選擇區域:", selectedAreaName)
end)

UI:Toggle("AutoEggToggle", "Auto Egg", function(enabled)
    autoEggEnabled = enabled
    if enabled then
        startAutoEgg()
        print("[Auto Egg] 已開啟")
    else
        print("[Auto Egg] 已關閉")
    end
end)

UI:Toggle("AutoUpgradeToggle", "Auto Upgrade Pen", function(enabled)
    autoUpgradeEnabled = enabled
    if enabled then
        startAutoUpgrade()
        print("[Auto Upgrade Pen] 已開啟")
    else
        print("[Auto Upgrade Pen] 已關閉")
    end
end)

UI:Toggle("AutoTreadmillToggle", "Auto Upgrade Treadmill", function(enabled)
    autoTreadmillEnabled = enabled
    if enabled then
        startAutoTreadmill()
        print("[Auto Upgrade Treadmill] 已開啟")
    else
        print("[Auto Upgrade Treadmill] 已關閉")
    end
end)

UI:Toggle("EquipBestToggle", "Equip Best", function(enabled)
    autoEquipEnabled = enabled
    if enabled then
        startAutoEquip()
        print("[Equip Best] 已開啟")
    else
        print("[Equip Best] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Auto Egg Script loaded successfully!")
