-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Anime Eyes")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local selectedStage = 1
local autoFarmEnabled = false
local autoAttackEnabled = false
local autoTrainEnabled = false
local autoRebirthEnabled = false
local hoverConnection = nil
local currentStage = 1
local currentHoverCF = nil

-- 階段列表 1\~15
local stages = {}
for i = 1, 15 do
    table.insert(stages, tostring(i))
end

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
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

-- 取得指定 Stage 的 PadGold 位置（懸空）
local function getPadGoldCFrame(stageNum)
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end

    local stagesFolder = map:FindFirstChild("Stages")
    if not stagesFolder then return nil end

    local stage = stagesFolder:FindFirstChild("Stage" .. tostring(stageNum))
    if not stage then return nil end

    local padGold = stage:FindFirstChild("PadGold")
    if not padGold then return nil end

    local pad = padGold:FindFirstChild("Pad")
    if pad and pad:IsA("BasePart") then
        return pad.CFrame + Vector3.new(0, 8, 0)
    end

    if padGold:IsA("BasePart") then
        return padGold.CFrame + Vector3.new(0, 8, 0)
    elseif padGold:IsA("Model") then
        if padGold.PrimaryPart then
            return padGold.PrimaryPart.CFrame + Vector3.new(0, 8, 0)
        end
        local part = padGold:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 8, 0)
        end
        return padGold:GetPivot() + Vector3.new(0, 8, 0)
    end

    return nil
end

-- 檢查 MyEnemies 是否還有 Model
local function hasEnemies()
    local myEnemies = Workspace:FindFirstChild("MyEnemies")
    if not myEnemies then return false end

    for _, obj in ipairs(myEnemies:GetChildren()) do
        if obj:IsA("Model") then
            return true
        end
    end
    return false
end

-- 取得 Model 的位置
local function getModelPosition(model)
    if model.PrimaryPart then
        return model.PrimaryPart.Position
    end
    local part = model:FindFirstChildWhichIsA("BasePart")
    if part then
        return part.Position
    end
    return model:GetPivot().Position
end

-- 開始 / 更新懸空位置
local function setHover(cf)
    if not cf then return end

    currentHoverCF = cf
    teleportTo(cf)

    if not hoverConnection then
        hoverConnection = RunService.Heartbeat:Connect(function()
            local hrp = getHRP()
            if hrp and currentHoverCF then
                hrp.CFrame = currentHoverCF
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end
end

-- 停止懸空
local function stopHover()
    if hoverConnection then
        hoverConnection:Disconnect()
        hoverConnection = nil
    end
    currentHoverCF = nil
end

-- 執行攻擊
local function doAttack()
    local myEnemies = Workspace:FindFirstChild("MyEnemies")
    if not myEnemies then return end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild("Cast")
    if not event then return end

    for _, enemy in ipairs(myEnemies:GetChildren()) do
        if enemy:IsA("Model") then
            local pos = getModelPosition(enemy)
            if pos then
                pcall(function()
                    event:FireServer("attack", pos, nil)
                end)
            end
        end
    end
end

-- 執行 Train
local function doTrain()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild("Train")
    if not event then return end

    pcall(function()
        event:FireServer()
    end)
end

-- 觸發 Bubble 按鈕
local function fireBubble()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj.Name == "Bubble" and (obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel")) then
            if getconnections then
                pcall(function()
                    for _, conn in pairs(getconnections(obj.MouseButton1Click)) do
                        if conn.Fire then
                            conn:Fire()
                        elseif conn.Function then
                            conn.Function()
                        end
                    end
                end)
            end

            pcall(function()
                firesignal(obj.MouseButton1Click)
            end)

            pcall(function()
                if obj.Activated then
                    firesignal(obj.Activated)
                end
            end)
        end
    end
end

-- 執行 Rebirth
local function doRebirth()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild("Rebirth")
    if not event then return end

    local success, err = pcall(function()
        event:InvokeServer()
    end)

    if success then
        print("[Auto Rebirth] 已轉生")
    else
        warn("[Auto Rebirth] 失敗:", err)
    end
end

-- Auto Farm 主邏輯
local function startAutoFarm()
    task.spawn(function()
        while autoFarmEnabled do
            currentStage = 1
            local targetStage = tonumber(selectedStage) or 15

            print("[Auto Farm] 開始新一輪，目標 Stage:", targetStage)

            while autoFarmEnabled and currentStage <= targetStage do
                local padCF = getPadGoldCFrame(currentStage)

                if padCF then
                    print("[Auto Farm] 傳送到 Stage" .. currentStage)
                    setHover(padCF)
                    task.wait(0.5)

                    print("[Auto Farm] 開始偵測 Stage" .. currentStage .. " 的敵人")
                    while autoFarmEnabled do
                        task.wait(0.4)

                        if not hasEnemies() then
                            print("[Auto Farm] Stage" .. currentStage .. " 敵人已清空")
                            break
                        end
                    end

                    if not autoFarmEnabled then break end
                    currentStage = currentStage + 1
                else
                    warn("[Auto Farm] 找不到 Stage" .. currentStage .. " 的 PadGold")
                    task.wait(0.5)
                    currentStage = currentStage + 1
                end
            end

            if not autoFarmEnabled then break end

            stopHover()
            print("[Auto Farm] 本輪完成，等待 1 秒後重新開始...")
            task.wait(1)
        end

        stopHover()
        print("[Auto Farm] 已關閉")
    end)
end

-- Auto Attack 主邏輯
local function startAutoAttack()
    task.spawn(function()
        while autoAttackEnabled do
            doAttack()
            task.wait(0.5)
        end
    end)
end

-- Auto Train & Tap 主邏輯
local function startAutoTrain()
    task.spawn(function()
        while autoTrainEnabled do
            doTrain()
            fireBubble()
            task.wait(0.1)
        end
    end)
end

-- Auto Rebirth 主邏輯
local function startAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            doRebirth()
            task.wait(3) -- 每 3 秒嘗試一次
        end
    end)
end

-- ==================== UI ====================
UI:Dropdown("StageDropdown", "Select Stage", stages, function(selected)
    selectedStage = selected
    print("[Select Stage] 已選擇: Stage" .. tostring(selected))
end)

UI:Toggle("AutoFarmToggle", "Auto Farm", function(enabled)
    autoFarmEnabled = enabled
    if enabled then
        startAutoFarm()
        print("[Auto Farm] 已開啟")
    else
        stopHover()
        print("[Auto Farm] 已關閉")
    end
end)

UI:Toggle("AutoAttackToggle", "Auto Attack", function(enabled)
    autoAttackEnabled = enabled
    if enabled then
        startAutoAttack()
        print("[Auto Attack] 已開啟")
    else
        print("[Auto Attack] 已關閉")
    end
end)

UI:Toggle("AutoTrainToggle", "Auto Train & Tap", function(enabled)
    autoTrainEnabled = enabled
    if enabled then
        startAutoTrain()
        print("[Auto Train & Tap] 已開啟")
    else
        print("[Auto Train & Tap] 已關閉")
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
