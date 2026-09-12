-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Steal a Chicken", "TikTok: ValueHat")

-- 核心服務
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數設定
local selectedArea = "Lake" -- 預設區域
local autoStealEnabled = false
local autoSellEggEnabled = false
local autoUpgradeTreadmillEnabled = false
local autoUpgradeBaseEnabled = false
local autoEquipBestEnabled = false

local isStealing = false
local isStealLoopRunning = false -- 防卡住：確保背景只會存在一個偷雞主迴圈
local lastStolenNest = nil -- 記錄上一次偷過的 Nest

-- 指定 Safe 點座標
local SAFE_CFRAME = CFrame.new(-53, 33, -294)

-- 區域資料夾清單
local areaOptions = {
    "Abyss", "Beach", "Cosmic", "Crystal", 
    "Desert", "Forest", "Jungle", "Lake", 
    "Snow", "Volcano"
}

---------------------------------------------------------
-- 取得 Remote Event / Function 輔助函數
---------------------------------------------------------
local function getRemote(remoteName)
    local packages = ReplicatedStorage:FindFirstChild("packages")
    local indexFolder = packages and packages:FindFirstChild("_Index")
    
    if indexFolder then
        for _, child in ipairs(indexFolder:GetChildren()) do
            if child.Name:find("littensy_remo") then
                local remo = child:FindFirstChild("remo")
                local container = remo and remo:FindFirstChild("container")
                local targetRemote = container and container:FindFirstChild(remoteName)
                if targetRemote then
                    return targetRemote
                end
            end
        end
    end
    return nil
end

---------------------------------------------------------
-- 平滑移動 (Tween) 輔助函數
---------------------------------------------------------
local function smoothMoveTo(targetCFrame, speed)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end

    speed = speed or 400 -- 移動速度
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local timeToTravel = distance / speed

    -- 防下沉設定：清空當前速度並暫停物理動作
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    
    local origPlatformStand = humanoid.PlatformStand
    humanoid.PlatformStand = true

    local tweenInfo = TweenInfo.new(
        timeToTravel,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()

    -- 還原狀態
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    humanoid.PlatformStand = origPlatformStand

    return true
end

---------------------------------------------------------
-- 高可靠度 ProximityPrompt 觸發函數
---------------------------------------------------------
local function forceTriggerPrompt(prompt, duration)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    -- 解除 Prompt 限制（放寬距離與視線）
    prompt.Enabled = true
    prompt.MaxActivationDistance = 9999
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0

    local startTime = tick()
    duration = duration or 1.0

    while tick() - startTime < duration do
        pcall(function()
            fireproximityprompt(prompt)
        end)

        pcall(function()
            if prompt.InputHoldBegin then prompt:InputHoldBegin() end
            if prompt.InputHoldEnd then prompt:InputHoldEnd() end
        end)

        task.wait(0.05)
    end
end

---------------------------------------------------------
-- 平滑飛行 + 高可靠度偷雞核心邏輯
---------------------------------------------------------
local function executeStealChicken()
    if isStealing then return end
    isStealing = true

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not hrp then 
        isStealing = false
        return 
    end

    -- 使用指定 Safe 點座標 (-53, 33, -294)
    local returnCFrame = SAFE_CFRAME

    -- 1. 開始偷雞前，先瞬間傳送到 Safe 點
    character:PivotTo(returnCFrame)
    task.wait(0.1)

    -- 尋找 PlayZones 下對應區域的 Nests 資料夾
    local playZones = Workspace:FindFirstChild("Game") 
        and Workspace.Game:FindFirstChild("Map") 
        and Workspace.Game.Map:FindFirstChild("PlayZones")

    local currentZone = playZones and playZones:FindFirstChild(selectedArea)
    local nestsFolder = currentZone and currentZone:FindFirstChild("Nests")

    if nestsFolder then
        -- 2. 收集該區域所有開頭為 "Nest" 的有效 Model
        local availableNests = {}
        for _, nestModel in ipairs(nestsFolder:GetChildren()) do
            if nestModel.Name:sub(1, 4) == "Nest" then
                local rootPart = nestModel:FindFirstChild("Root") or nestModel:FindFirstChildWhichIsA("BasePart")
                if rootPart then
                    table.insert(availableNests, nestModel)
                end
            end
        end

        if #availableNests > 0 then
            -- 3. 優先過濾掉上一次偷過的 Nest
            local candidates = {}
            if #availableNests > 1 then
                for _, nest in ipairs(availableNests) do
                    if nest ~= lastStolenNest then
                        table.insert(candidates, nest)
                    end
                end
            else
                candidates = availableNests
            end

            -- 4. 隨機抽選一個 Nest
            local chosenNest = candidates[math.random(1, #candidates)]
            lastStolenNest = chosenNest

            local rootPart = chosenNest:FindFirstChild("Root") or chosenNest:FindFirstChildWhichIsA("BasePart")
            local prompt = chosenNest:FindFirstChildWhichIsA("ProximityPrompt", true)

            if rootPart and prompt then
                -- 5. 平滑飛往 Nest 正確座標 (速度 400)
                local targetCFrame = rootPart.CFrame
                smoothMoveTo(targetCFrame, 400)

                -- 6. 到達地點後精確貼合座標
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
                end

                -- 7. 強化版 Prompt 觸發（停留 1.0 秒多重觸發）
                forceTriggerPrompt(prompt, 1.0)

                -- 8. 完成後飛回 Safe 點 (-53, 33, -294)
                smoothMoveTo(returnCFrame, 400)

                -- 9. 回到 Safe 點後停留 3 秒再繼續
                task.wait(3.0)
            end
        end
    else
        warn("[Auto Steal]: 找不到指定區域或 Nests 資料夾: " .. tostring(selectedArea))
    end

    isStealing = false
end

---------------------------------------------------------
-- UI 開關與選擇器
---------------------------------------------------------

-- 1. 選擇區域 Dropdown
Hub:CreateDropdown("Select Area", areaOptions, "Lake", function(chosen)
    selectedArea = chosen
    lastStolenNest = nil -- 更換區域時重置歷史記錄
    print("[Auto Steal]: 目前選擇區域 -> " .. tostring(selectedArea))
end)

-- 2. 自動偷雞 Toggle (防雙重迴圈重疊卡住)
Hub:CreateToggle("Auto Steal Chicken", false, function(isOn)
    autoStealEnabled = isOn

    if autoStealEnabled then
        -- 防卡住：如果背景已有迴圈在跑，直接跳過不開新迴圈
        if isStealLoopRunning then return end
        isStealLoopRunning = true

        task.spawn(function()
            while autoStealEnabled do
                executeStealChicken()
                task.wait(0.2)
            end
            -- 當開關關閉且當前最後一輪飛完後，釋放狀態
            lastStolenNest = nil
            isStealing = false
            isStealLoopRunning = false
        end)
    end
end)

-- 3. 自動賣蛋 Toggle
Hub:CreateToggle("Auto Sell Egg", false, function(isOn)
    autoSellEggEnabled = isOn

    if autoSellEggEnabled then
        task.spawn(function()
            while autoSellEggEnabled do
                local sellRemote = getRemote("data.backpack.sellAllItems")
                if sellRemote then
                    pcall(function()
                        if sellRemote:IsA("RemoteEvent") then
                            sellRemote:FireServer("egg")
                        elseif sellRemote:IsA("RemoteFunction") then
                            sellRemote:InvokeServer("egg")
                        end
                    end)
                else
                    warn("[Auto Sell]: 找不到 sellAllItems Remote")
                end
                task.wait(1.0)
            end
        end)
    end
end)

-- 4. 自動升級跑步機 Toggle
Hub:CreateToggle("Auto Upgrade Treadmill", false, function(isOn)
    autoUpgradeTreadmillEnabled = isOn

    if autoUpgradeTreadmillEnabled then
        task.spawn(function()
            while autoUpgradeTreadmillEnabled do
                local upgradeRemote = getRemote("data.upgrades.upgrade")
                if upgradeRemote then
                    pcall(function()
                        if upgradeRemote:IsA("RemoteEvent") then
                            upgradeRemote:FireServer("treadmill", 1)
                        elseif upgradeRemote:IsA("RemoteFunction") then
                            upgradeRemote:InvokeServer("treadmill", 1)
                        end
                    end)
                else
                    warn("[Auto Upgrade]: 找不到 upgrades.upgrade Remote")
                end
                task.wait(1.0)
            end
        end)
    end
end)

-- 5. 自動升級基地 Toggle
Hub:CreateToggle("Auto Upgrade Base", false, function(isOn)
    autoUpgradeBaseEnabled = isOn

    if autoUpgradeBaseEnabled then
        task.spawn(function()
            while autoUpgradeBaseEnabled do
                local baseRemote = getRemote("data.base.upgradeBase")
                if baseRemote then
                    pcall(function()
                        if baseRemote:IsA("RemoteEvent") then
                            baseRemote:FireServer()
                        elseif baseRemote:IsA("RemoteFunction") then
                            baseRemote:InvokeServer()
                        end
                    end)
                else
                    warn("[Auto Upgrade Base]: 找不到 upgradeBase Remote")
                end
                task.wait(1.0)
            end
        end)
    end
end)

-- 6. 自動裝備最佳雞隻 Toggle
Hub:CreateToggle("Auto Equip Best", false, function(isOn)
    autoEquipBestEnabled = isOn

    if autoEquipBestEnabled then
        task.spawn(function()
            while autoEquipBestEnabled do
                local equipRemote = getRemote("data.base.equipBestChickens")
                if equipRemote then
                    pcall(function()
                        if equipRemote:IsA("RemoteEvent") then
                            equipRemote:FireServer()
                        elseif equipRemote:IsA("RemoteFunction") then
                            equipRemote:InvokeServer()
                        end
                    end)
                else
                    warn("[Auto Equip Best]: 找不到 equipBestChickens Remote")
                end
                task.wait(1.0)
            end
        end)
    end
end)
