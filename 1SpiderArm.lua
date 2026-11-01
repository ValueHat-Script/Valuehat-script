local success, UIModule = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui6.lua'))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗！")
    return
end

local UI = UIModule.Init("+1 Spider Arm")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 狀態變數
local selectedStageName = "Stage1"
local autoWinEnabled = false
local autoTrainEnabled = false
local autoTrainBonusEnabled = false
local autoRebirthEnabled = false
local fixedSpeed = 300 -- 固定移動速度

-- 以固定速度 300 進行 Tween 移動的函數
local function tweenMyCharacterSpeed300(targetCf)
    if not targetCf then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        if not root then return end

        local distance = (root.Position - targetCf.Position).Magnitude
        local duration = distance / fixedSpeed
        if duration < 0.05 then duration = 0.05 end

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCf})
        
        tween:Play()
        tween.Completed:Wait()
    end)
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

-- 產生 Stage 1 ~ 13 的選項列表
local stageOptions = {}
for i = 1, 13 do
    table.insert(stageOptions, "Stage" .. i)
end

-- 格式化 Stage 名稱 (相容 Stage1 與 Stage01)
local function getStageFolder(stagesFolder, stageName)
    local target = stagesFolder:FindFirstChild(stageName)
    if target then return target end

    local num = tonumber(stageName:match("%d+"))
    if num then
        local formattedName = string.format("Stage%02d", num)
        target = stagesFolder:FindFirstChild(formattedName)
        if target then return target end
    end
    return nil
end

-- ==================== Auto Win 邏輯 ====================
local function startAutoWin()
    task.spawn(function()
        while autoWinEnabled do
            pcall(function()
                local mapFolder = Workspace:FindFirstChild("Map")
                local stagesFolder = mapFolder and mapFolder:FindFirstChild("Stages")
                if not stagesFolder then return end

                local targetStage = getStageFolder(stagesFolder, selectedStageName)
                if not targetStage then return end

                local endPads = targetStage:FindFirstChild("EndPads")
                if not endPads then return end

                local targetPad = endPads:FindFirstChild("WinPad") or endPads
                local padCf = getCFrame(targetPad)

                if padCf then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        -- 1. 先往上升空 60 單位
                        local upCf = root.CFrame + Vector3.new(0, 60, 0)
                        tweenMyCharacterSpeed300(upCf)

                        -- 2. 高空高速移動至終點上方
                        local highTargetCf = CFrame.new(padCf.Position + Vector3.new(0, 60, 0))
                        tweenMyCharacterSpeed300(highTargetCf)

                        -- 3. 降落到 WinPad / EndPad 上
                        tweenMyCharacterSpeed300(padCf + Vector3.new(0, 3, 0))

                        -- 4. 到達 WinPad 後等待 1 秒再繼續下一輪
                        task.wait(1)
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

-- ==================== Auto Train 邏輯 ====================
local function startAutoTrain()
    task.spawn(function()
        local trainEvent = ReplicatedStorage:FindFirstChild("Armature") 
            and ReplicatedStorage.Armature:FindFirstChild("TrainNet")
            
        while autoTrainEnabled do
            if trainEvent then
                pcall(function()
                    trainEvent:FireServer("steps", math.huge)
                end)
            end
            task.wait(0.1)
        end
    end)
end

-- ==================== Auto Train Bonus 邏輯 ====================
local function startAutoTrainBonus()
    task.spawn(function()
        while autoTrainBonusEnabled do
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, desc in ipairs(playerGui:GetDescendants()) do
                        if desc.Name == "Circle" and (desc:IsA("TextButton") or desc:IsA("ImageButton")) then
                            for _, connection in ipairs(getconnections(desc.MouseButton1Click)) do
                                connection:Fire()
                            end
                            for _, connection in ipairs(getconnections(desc.Activated)) do
                                connection:Fire()
                            end
                        end
                    end
                end
            end)
            task.wait(0.2)
        end
    end)
end

-- ==================== Auto Rebirth 邏輯 ====================
local function startAutoRebirth()
    task.spawn(function()
        local rebirthEvent = ReplicatedStorage:FindFirstChild("Armature") 
            and ReplicatedStorage.Armature:FindFirstChild("RebirthNet")
            
        while autoRebirthEnabled do
            if rebirthEvent then
                pcall(function()
                    rebirthEvent:FireServer("rebirth")
                end)
            end
            task.wait(1) -- 每秒嘗試轉生一次
        end
    end)
end

-- ==================== UI 設定 ====================
UI:Dropdown("Dropdown", "Select Stage", stageOptions, function(selected)
    selectedStageName = selected
    print("[Auto Win] 已選擇關卡:", selected)
end)

UI:Toggle("Toggle", "Auto Win", function(enabled)
    autoWinEnabled = enabled
    if enabled then
        startAutoWin()
        print("[Auto Win] 已開啟")
    else
        print("[Auto Win] 已關閉")
    end
end)

UI:Toggle("ToggleTrain", "Auto Train", function(enabled)
    autoTrainEnabled = enabled
    if enabled then
        startAutoTrain()
        print("[Auto Train] 已開啟")
    else
        print("[Auto Train] 已關閉")
    end
end)

UI:Toggle("ToggleTrainBonus", "Auto Train Bonus", function(enabled)
    autoTrainBonusEnabled = enabled
    if enabled then
        startAutoTrainBonus()
        print("[Auto Train Bonus] 已開啟")
    else
        print("[Auto Train Bonus] 已關閉")
    end
end)

-- 新增 Auto Rebirth 開關
UI:Toggle("ToggleRebirth", "Auto Rebirth", function(enabled)
    autoRebirthEnabled = enabled
    if enabled then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

UI:Status("Status", "TikTok:ValueHat")
