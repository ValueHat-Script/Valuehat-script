-- 動態載入 WindUI UI 模組
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 建立主視窗
local Window = WindUI:CreateWindow({
    Title = "Steal an Egg | by ValueHat",
    Icon = "shield",
    Author = "",
    Folder = "v",
    Size = UDim2.fromOffset(580, 480),
    Transparent = true,
    Theme = "Dark"
})

--------------------------------------------------
-- 服務與變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local acBypassEnabled = false
local speedChangerEnabled = false
local autoStealEnabled = false
local fixedSpeed = 500
local currentHipHeight = 2 -- 預設 HipHeight
local smoothSpeed = 150 -- 預設平滑移動速度 (studs/s)

local originalHumanoid = nil
local fakeHumanoid = nil
local speedConnection = nil
local autoStealThread = nil

-- Remote Function 設定
local AskFieldEggCarry = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("Networking")
    :WaitForChild("RF/EggWorld/AskFieldEggCarry")

--------------------------------------------------
-- 1. HipHeight 設置與維護邏輯
--------------------------------------------------
local function setHipHeight(val)
    currentHipHeight = val
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, hum in ipairs(char:GetChildren()) do
            if hum:IsA("Humanoid") then
                hum.HipHeight = val
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    setHipHeight(currentHipHeight)
end)

--------------------------------------------------
-- 2. Anti-Cheat Bypass 核心邏輯
--------------------------------------------------
local function setupAntiCheatBypass(enable)
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if enable then
        if hum and hum ~= fakeHumanoid then
            hum.Archivable = true
            fakeHumanoid = hum:Clone()
            fakeHumanoid.Name = "Humanoid_Bypass"
            fakeHumanoid.Parent = char
            
            originalHumanoid = hum
            originalHumanoid.Parent = nil
            
            workspace.CurrentCamera.CameraSubject = fakeHumanoid
        end
    else
        if originalHumanoid then
            originalHumanoid.Parent = char
            workspace.CurrentCamera.CameraSubject = originalHumanoid
            originalHumanoid = nil
        end
        if fakeHumanoid then
            fakeHumanoid:Destroy()
            fakeHumanoid = nil
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if acBypassEnabled then
        task.wait(0.5)
        setupAntiCheatBypass(true)
    end
end)

--------------------------------------------------
-- 3. Speed Changer (鎖定為 500 速度)
--------------------------------------------------
local function updateSpeedLock()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end

    if speedChangerEnabled then
        speedConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = fixedSpeed
            end
        end)
    else
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
        end
    end
end

--------------------------------------------------
-- 4. Smooth 移動與 Auto Steal 邏輯
--------------------------------------------------

-- 取得物件主體 CFrame (相容 Model 或 Part)
local function getModelCFrame(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.CFrame
        else
            return model:GetPivot()
        end
    elseif model:IsA("BasePart") then
        return model.CFrame
    end
    return nil
end

-- Smooth 移動函式 (Tween)
local function smoothMoveTo(targetCFrame, moveSpeed)
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    moveSpeed = moveSpeed or smoothSpeed
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / moveSpeed

    if duration <= 0.05 then
        root.CFrame = targetCFrame
        return true
    end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    
    tween:Play()
    
    local completed = false
    local conn
    conn = tween.Completed:Connect(function()
        completed = true
        if conn then conn:Disconnect() end
    end)

    while not completed and autoStealEnabled do
        task.wait(0.05)
    end

    if not autoStealEnabled then
        tween:Cancel()
        return false
    end

    return true
end

-- 取得亂碼蛋 Model 列表
local function getGarbageEggModels()
    local eggSlots = workspace:FindFirstChild("AreaEggSlotsClient")
    if not eggSlots then return {} end

    local validEggs = {}
    for _, child in ipairs(eggSlots:GetChildren()) do
        if child:IsA("Model") then
            if #child.Name >= 10 or string.match(child.Name, "%x%x%x%x%x+") then
                table.insert(validEggs, child)
            end
        end
    end
    return validEggs
end

-- 取得指定的基地目標
local function getTargetBaseCFrame()
    local success, base = pcall(function()
        return workspace.__OBJECTS.Build.MainMap.Bases:GetChildren()[8]
    end)
    
    if success and base then
        return getModelCFrame(base)
    end
    return nil
end

-- Auto Steal 核心迴圈
local function startAutoSteal()
    if autoStealThread then
        task.cancel(autoStealThread)
        autoStealThread = nil
    end

    autoStealThread = task.spawn(function()
        while autoStealEnabled do
            local eggs = getGarbageEggModels()
            
            if #eggs > 0 then
                local targetEgg = eggs[math.random(1, #eggs)]
                local targetUid = targetEgg.Name
                local targetCF = getModelCFrame(targetEgg)

                if targetCF then
                    local arrivalCF = targetCF * CFrame.new(0, 1, 0)
                    
                    -- 1. Smooth 移動至該蛋
                    local arrived = smoothMoveTo(arrivalCF, smoothSpeed)

                    if arrived and autoStealEnabled then
                        local successCarry = false
                        local retryCount = 0
                        local maxRetries = 10 -- 最多重試 10 次

                        -- 2. 輪詢確認 Remote 執行結果與狀態
                        while not successCarry and retryCount < maxRetries and autoStealEnabled do
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if root then
                                root.CFrame = arrivalCF
                            end

                            local success, result = pcall(function()
                                return AskFieldEggCarry:InvokeServer({
                                    Uid = targetUid
                                })
                            end)

                            if success and (result == true or result == "Success") then
                                successCarry = true
                            else
                                retryCount = retryCount + 1
                                task.wait(0.1)
                            end
                        end

                        -- 3. 返回指定基地
                        local baseCF = getTargetBaseCFrame()
                        if baseCF and autoStealEnabled then
                            smoothMoveTo(baseCF * CFrame.new(0, 3, 0), smoothSpeed)
                        end
                        
                        task.wait(0.2)
                    end
                end
            else
                task.wait(1)
            end
            task.wait(0.1)
        end
    end)
end

--------------------------------------------------
-- WindUI 分頁與組件綁定
--------------------------------------------------

-- Tab 1: Anti-Cheat Bypass & Automation
local MainTab = Window:Tab({ Title = "Anti-Cheat Bypass", Icon = "shield-alert" })

MainTab:Section({ Title = "Automation & Farm" })

-- Auto Steal 開關
MainTab:Toggle({
    Title = "Auto Steal Egg",
    Desc = "Smoothly moves to eggs, triggers remote with retry verification, and returns to Base 8.",
    Value = false,
    Callback = function(Value)
        autoStealEnabled = Value
        if Value then
            startAutoSteal()
        elseif autoStealThread then
            task.cancel(autoStealThread)
            autoStealThread = nil
        end

        WindUI:Notify({
            Title = "Auto Steal",
            Content = Value and "Auto Steal started." or "Auto Steal stopped.",
            Duration = 3
        })
    end,
})

-- Smooth Speed 平滑移動速度滑桿
MainTab:Slider({
    Title = "Smooth Movement Speed",
    Desc = "Adjusts the Tween speed when traveling to eggs and returning to Base.",
    Value = {
        Min = 10,
        Max = 1000,
        Default = 150
    },
    Step = 10,
    Callback = function(Value)
        smoothSpeed = Value
    end,
})

MainTab:Section({ Title = "Anti-Cheat & Speed" })

-- 1. Enable Anti-Cheat Bypass 開關
MainTab:Toggle({
    Title = "Enable Anti-Cheat Bypass",
    Desc = "Replaces the Humanoid so the server's WalkSpeed governor writes to a dead object.",
    Value = false,
    Callback = function(Value)
        acBypassEnabled = Value
        setupAntiCheatBypass(Value)
        
        WindUI:Notify({
            Title = "Anti-Cheat",
            Content = Value and "Humanoid replaced, bypass active." or "Bypass disabled.",
            Duration = 3
        })
    end,
})

-- 2. Speed Changer 開關
MainTab:Toggle({
    Title = "Speed Changer",
    Desc = "Locks WalkSpeed to 500 every frame. Requires Bypass active.",
    Value = false,
    Callback = function(Value)
        speedChangerEnabled = Value
        updateSpeedLock()
        
        WindUI:Notify({
            Title = "Speed",
            Content = Value and "Speed locked to 500 studs/s." or "Speed Changer disabled.",
            Duration = 3
        })
    end,
})

-- 3. TP Tool 按鈕
MainTab:Button({
    Title = "Get TP Tool",
    Desc = "Gives you a Teleport Tool in your backpack.",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-TP-TOOL-213424"))()
        end)
        
        WindUI:Notify({
            Title = "TP Tool Received",
            Content = "Check your inventory/backpack for the TP Tool.",
            Duration = 3
        })
    end,
})

-- Tab 2: Local Player
local PlayerTab = Window:Tab({ Title = "Local Player", Icon = "user" })

PlayerTab:Section({ Title = "Humanoid Settings" })

-- HipHeight 滑桿
PlayerTab:Slider({
    Title = "HipHeight",
    Desc = "Adjusts your character's height off the ground.",
    Value = {
        Min = 0,
        Max = 50,
        Default = 2
    },
    Step = 1,
    Callback = function(Value)
        setHipHeight(Value)
    end,
})

WindUI:Notify({
    Title = "Shard Hub Loaded",
    Content = "Anti-Cheat, Auto Steal & Custom Speed Controls Ready.",
    Duration = 4
})
