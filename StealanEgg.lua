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
local currentHipHeight = 2
local smoothSpeed = 150

-- 區域座標表
local AreaLocations = {
    ["Forest"] = Vector3.new(595, 71, -325),
    ["Lake"] = Vector3.new(740, 71, -413),
    ["Desert"] = Vector3.new(949, 71, -320),
    ["Jungle"] = Vector3.new(1184, 71, -413),
    ["Snow"] = Vector3.new(1490, 71, -316),
    ["Volcano"] = Vector3.new(1883, 71, -405),
    ["Abyss Ocean"] = Vector3.new(2280, 71, -329),
    ["Prehistoric"] = Vector3.new(2804, 71, -395),
    ["Cosmic"] = Vector3.new(3390, 71, -326),
    ["Cherry Blossom"] = Vector3.new(4027, 71, -398)
}
local selectedArea = "Forest"

local originalHumanoid = nil
local fakeHumanoid = nil
local speedConnection = nil
local autoStealThread = nil

-- Remote Function 安全取得
local AskFieldEggCarry
pcall(function()
    AskFieldEggCarry = ReplicatedStorage:WaitForChild("Packages", 5)
        :WaitForChild("Networking", 5)
        :WaitForChild("RF/EggWorld/AskFieldEggCarry", 5)
end)

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
    task.wait(0.5)
    setHipHeight(currentHipHeight)
    if acBypassEnabled then
        setupAntiCheatBypass(true)
    end
end)

--------------------------------------------------
-- 3. Speed Changer
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

-- 取得特定區域周圍（200 studs 內）的蛋，避免跑去別區
local function getGarbageEggModelsNear(areaCenter, maxDistance)
    maxDistance = maxDistance or 200 -- 搜尋範圍半徑
    local eggSlots = workspace:FindFirstChild("AreaEggSlotsClient")
    if not eggSlots or not areaCenter then return {} end

    local validEggs = {}
    for _, child in ipairs(eggSlots:GetChildren()) do
        if child:IsA("Model") and (#child.Name >= 10 or string.match(child.Name, "%x%x%x%x%x+")) then
            local eggCF = getModelCFrame(child)
            if eggCF then
                local dist = (eggCF.Position - areaCenter).Magnitude
                if dist <= maxDistance then
                    table.insert(validEggs, child)
                end
            end
        end
    end
    return validEggs
end

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
            local areaPos = AreaLocations[selectedArea]
            
            if areaPos then
                -- 1. 平滑移動至指定的區域
                local arrivedArea = smoothMoveTo(CFrame.new(areaPos), smoothSpeed)

                if arrivedArea and autoStealEnabled then
                    -- 2. 停頓 0.5 秒
                    task.wait(0.5)

                    -- 3. 嚴格限定：只尋找該區域半徑 200 studs 內的蛋
                    local eggs = getGarbageEggModelsNear(areaPos, 200)
                    
                    if #eggs > 0 then
                        local targetEgg = eggs[math.random(1, #eggs)]
                        local targetUid = targetEgg.Name
                        local targetCF = getModelCFrame(targetEgg)

                        if targetCF and AskFieldEggCarry then
                            -- 移動至該區域內的目標蛋
                            smoothMoveTo(targetCF * CFrame.new(0, 1, 0), smoothSpeed)

                            local successCarry = false
                            local retryCount = 0

                            while not successCarry and retryCount < 10 and autoStealEnabled do
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
                        end
                    end

                    -- 4. 拿完蛋後返回基地 (Base 8)
                    local baseCF = getTargetBaseCFrame()
                    if baseCF and autoStealEnabled then
                        smoothMoveTo(baseCF * CFrame.new(0, 3, 0), smoothSpeed)
                    end
                end
            else
                task.wait(1)
            end
            task.wait(0.2)
        end
    end)
end

--------------------------------------------------
-- WindUI 分頁與組件綁定
--------------------------------------------------

local MainTab = Window:Tab({ Title = "Anti-Cheat Bypass", Icon = "shield-alert" })

MainTab:Section({ Title = "Automation & Farm" })

-- 區域選擇 Dropdown
MainTab:Dropdown({
    Title = "Select Area",
    Desc = "Choose target area to travel before searching eggs.",
    Values = {
        "Forest", "Lake", "Desert", "Jungle", "Snow",
        "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom"
    },
    Value = "Forest",
    Callback = function(Option)
        if type(Option) == "table" then
            selectedArea = Option[1] or Option.Value or Option.Name or "Forest"
        elseif type(Option) == "string" then
            selectedArea = Option
        end

        WindUI:Notify({
            Title = "Area Selected",
            Content = "Target set to: " .. tostring(selectedArea),
            Duration = 2
        })
    end,
})

-- Auto Steal 開關
MainTab:Toggle({
    Title = "Auto Steal Egg",
    Desc = "Moves to selected area, pauses, triggers remote, and returns to Base 8.",
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

-- Smooth Speed 滑桿
MainTab:Slider({
    Title = "Smooth Movement Speed",
    Desc = "Adjusts the Tween speed when traveling.",
    Value = {
        Min = 10,
        Max = 1000,
        Default = 150
    },
    Step = 10,
    Callback = function(Value)
        if type(Value) == "table" then
            smoothSpeed = Value.Value or Value[1] or 150
        else
            smoothSpeed = Value
        end
    end,
})

MainTab:Section({ Title = "Anti-Cheat & Speed" })

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

PlayerTab:Slider({
    Title = "HipHeight",
    Desc = "Adjusts your character's height off the ground.",
    Value = {
        Min = 2,
        Max = 10,
        Default = 2
    },
    Step = 1,
    Callback = function(Value)
        local val = Value
        if type(Value) == "table" then
            val = Value.Value or Value[1] or 2
        end
        setHipHeight(val)
    end,
})

WindUI:Notify({
    Title = "Shard Hub Loaded",
    Content = "Anti-Cheat, Auto Steal & Custom Speed Controls Ready.",
    Duration = 4
})
--------------------------------------------------
-- Tab 3: Auto
--------------------------------------------------

local AutoTab = Window:Tab({
    Title = "Auto",
    Icon = "zap"
})

AutoTab:Section({
    Title = "Auto Automation"
})

local autoClaimIndexEnabled = false
local autoEquipBestEnabled = false

local autoClaimIndexThread = nil
local autoEquipBestThread = nil

--------------------------------------------------
-- Remote Functions
--------------------------------------------------

local AskRedeemAll
local WearBest

pcall(function()
    local Networking = ReplicatedStorage
        :WaitForChild("Packages", 5)
        :WaitForChild("Networking", 5)

    AskRedeemAll = Networking:WaitForChild("RF/Codex/AskRedeemAll", 5)
    WearBest = Networking:WaitForChild("RF/Haul/WearBest", 5)
end)

--------------------------------------------------
-- Automation Threads
--------------------------------------------------

local function startAutoClaimIndex()
    if autoClaimIndexThread then
        task.cancel(autoClaimIndexThread)
        autoClaimIndexThread = nil
    end

    autoClaimIndexThread = task.spawn(function()
        while autoClaimIndexEnabled do
            if AskRedeemAll then
                pcall(function()
                    AskRedeemAll:InvokeServer()
                end)
            end
            task.wait(2)
        end
    end)
end

local function startAutoEquipBest()
    if autoEquipBestThread then
        task.cancel(autoEquipBestThread)
        autoEquipBestThread = nil
    end

    autoEquipBestThread = task.spawn(function()
        while autoEquipBestEnabled do
            if WearBest then
                pcall(function()
                    WearBest:InvokeServer()
                end)
            end
            task.wait(2)
        end
    end)
end

--------------------------------------------------
-- Toggles
--------------------------------------------------

AutoTab:Toggle({
    Title = "Auto Claim Index Reward",
    Desc = "Automatically redeems all available index rewards.",
    Value = false,
    Callback = function(Value)
        autoClaimIndexEnabled = Value
        if Value then
            startAutoClaimIndex()
        elseif autoClaimIndexThread then
            task.cancel(autoClaimIndexThread)
            autoClaimIndexThread = nil
        end
    end,
})

AutoTab:Toggle({
    Title = "Auto Equip Best",
    Desc = "Automatically equips your best available equipment.",
    Value = false,
    Callback = function(Value)
        autoEquipBestEnabled = Value
        if Value then
            startAutoEquipBest()
        elseif autoEquipBestThread then
            task.cancel(autoEquipBestThread)
            autoEquipBestThread = nil
        end
    end,
})
