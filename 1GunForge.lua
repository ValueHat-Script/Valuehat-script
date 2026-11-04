-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Gun Forge")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local killAuraEnabled = false
local autoCollectEnabled = false
local autoStageEnabled = false
local autoTrainEnabled = false
local autoRebirthEnabled = false
local targetStage = 1

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- 瞬移
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
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
        local success, pivot = pcall(function()
            return obj:GetPivot()
        end)
        if success then
            return pivot + Vector3.new(0, 3, 0)
        end
    end
    return nil
end

-- 取得指定 Stage 的 Floor
local function getStageFloorCFrame(stageNum)
    local stages = Workspace:FindFirstChild("Stages")
    if not stages then return nil end

    local stageName = "Stage" .. tostring(stageNum)
    local stage = stages:FindFirstChild(stageName)
    if not stage then return nil end

    local floor = stage:FindFirstChild("Floor") or stage:FindFirstChild("Floor", true)
    if not floor then return nil end

    return getObjectCFrame(floor)
end

-- 取得目前敵人數量
local function getEnemyCount()
    local enemyFolder = Workspace:FindFirstChild("EnemyFolder")
    if not enemyFolder then return 0 end

    local count = 0
    for _, obj in ipairs(enemyFolder:GetChildren()) do
        if obj:IsA("Model") then
            count = count + 1
        end
    end
    return count
end

-- 取得 EnemyId
local function getEnemyId(model)
    local id = model:GetAttribute("EnemyId")
    if id then return id end

    local value = model:FindFirstChild("EnemyId")
    if value and (value:IsA("NumberValue") or value:IsA("IntValue")) then
        return value.Value
    end
    return nil
end

-- 執行攻擊
local function doAttack(enemyId, cf)
    pcall(function()
        local event = ReplicatedStorage.PlusPlus.Remotes.RequestFire
        event:FireServer(enemyId, cf)
    end)
end

-- 執行 Train（固定座標）
local function doTrain()
    pcall(function()
        local event = ReplicatedStorage.PlusPlus.Remotes.RequestFire
        event:FireServer(
            nil,
            CFrame.new(101.90158081054688, 59.319232940673828, 83.023208618164062, -0.99140232801437378, 0.040390603244304657, -0.12445858120918274, 0, 0.95116531848907471, 0.3086821436882019, 0.13084852695465088, 0.30602818727493286, -0.94298756122589111)
        )
    end)
end

-- 執行 Rebirth
local function doRebirth()
    pcall(function()
        local event = ReplicatedStorage.PlusPlus.Remotes.RequestRebirth
        event:FireServer()
    end)
end

-- 觸發周圍 Prompt
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

-- Kill Aura
local function startKillAura()
    task.spawn(function()
        while killAuraEnabled do
            local enemyFolder = Workspace:FindFirstChild("EnemyFolder")
            if enemyFolder then
                for _, model in ipairs(enemyFolder:GetChildren()) do
                    if not killAuraEnabled then break end
                    if model:IsA("Model") then
                        local enemyId = getEnemyId(model)
                        local cf = getObjectCFrame(model)
                        if enemyId and cf then
                            doAttack(enemyId, cf)
                        end
                    end
                end
            end
            task.wait(0.12)
        end
    end)
end

-- Auto Collect
local function startAutoCollect()
    task.spawn(function()
        while autoCollectEnabled do
            local scrapDrops = Workspace:FindFirstChild("ScrapDrops")
            if scrapDrops then
                for _, obj in ipairs(scrapDrops:GetChildren()) do
                    if not autoCollectEnabled then break end
                    if obj.Name == "Scrap" and (obj:IsA("BasePart") or obj:IsA("Model")) then
                        local cf = getObjectCFrame(obj)
                        if cf then
                            teleportTo(cf)
                            task.wait(0.25)
                            fireNearbyPrompts(5)
                            task.wait(0.35)
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- Auto Stage
local function startAutoStage()
    task.spawn(function()
        local maxStage = tonumber(targetStage) or 1
        if maxStage < 1 then maxStage = 1 end
        if maxStage > 69 then maxStage = 69 end

        print("[Auto Stage] 目標 Stage: " .. tostring(maxStage))

        for stage = 1, maxStage do
            if not autoStageEnabled then break end

            print("[Auto Stage] ===== 進入 Stage " .. tostring(stage) .. " =====")

            local floorCF = getStageFloorCFrame(stage)
            if floorCF then
                teleportTo(floorCF)
                print("[Auto Stage] 已傳送到 Stage" .. tostring(stage) .. " Floor")
                task.wait(0.8)
            else
                warn("[Auto Stage] 找不到 Stage" .. tostring(stage) .. " 的 Floor，跳過")
                task.wait(0.5)
            end

            local waitTime = 0
            local maxWait = 45

            while autoStageEnabled and waitTime < maxWait do
                local count = getEnemyCount()
                if count == 0 then
                    print("[Auto Stage] Stage " .. tostring(stage) .. " 敵人已清空")
                    break
                end
                task.wait(0.5)
                waitTime = waitTime + 0.5
            end

            if not autoStageEnabled then break end
            task.wait(0.6)
        end

        autoStageEnabled = false
        print("[Auto Stage] 已完成，自動停止")
    end)
end

-- Auto Train
local function startAutoTrain()
    task.spawn(function()
        while autoTrainEnabled do
            doTrain()
            task.wait(0.2)
        end
    end)
end

-- Auto Rebirth
local function startAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            doRebirth()
            task.wait(3) -- 轉生間隔，可自行調整
        end
    end)
end

-- ==================== UI ====================
UI:Toggle("KillAuraToggle", "Kill Aura", function(enabled)
    killAuraEnabled = enabled
    if enabled then
        startKillAura()
        print("[Kill Aura] 已開啟")
    else
        print("[Kill Aura] 已關閉")
    end
end)

UI:Toggle("AutoCollectToggle", "Auto Collect", function(enabled)
    autoCollectEnabled = enabled
    if enabled then
        startAutoCollect()
        print("[Auto Collect] 已開啟")
    else
        print("[Auto Collect] 已關閉")
    end
end)

UI:Input("StageInput", "Stage (1\~69)", "Number", function(text, entered)
    local num = tonumber(text)
    if num then
        if num < 1 then num = 1 end
        if num > 69 then num = 69 end
        targetStage = num
        print("[Stage] 已設定目標: " .. tostring(targetStage))
    end
end)

UI:Toggle("AutoStageToggle", "Auto Stage", function(enabled)
    autoStageEnabled = enabled
    if enabled then
        startAutoStage()
        print("[Auto Stage] 已開啟")
    else
        print("[Auto Stage] 已關閉")
    end
end)

UI:Toggle("AutoTrainToggle", "Auto Train", function(enabled)
    autoTrainEnabled = enabled
    if enabled then
        startAutoTrain()
        print("[Auto Train] 已開啟")
    else
        print("[Auto Train] 已關閉")
    end
end)

UI:Toggle("AutoRebirthToggle", "Auto Rebirth", function(enabled)
    autoRebirthEnabled = enabled
    if enabled then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
