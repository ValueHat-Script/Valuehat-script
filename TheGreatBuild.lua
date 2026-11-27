-- ==================== ValueHat Gui 5 初始化 ====================
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("The Great Build")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local autoBlockLeverEnabled = false
local autoRingEnabled = false
local isRunningAutoRing = false

-- ==================== 取得目標座標輔助函數 ====================
local function getTargetCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") or obj:IsA("WorldModel") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        return part and part.CFrame or obj:GetPivot()
    else
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame
        end
    end
    return nil
end

-- ==================== 取得角色 Root 輔助函數 ====================
local function getCharacterRoot()
    local charactersFolder = Workspace:FindFirstChild("Characters")
    local myName = LocalPlayer.Name
    local myCharModel = (charactersFolder and charactersFolder:FindFirstChild(myName)) or LocalPlayer.Character
    if not myCharModel then return nil, nil end

    local humanoid = myCharModel:FindFirstChildOfClass("Humanoid")
    local root = myCharModel:FindFirstChild("HumanoidRootPart")
        or (myCharModel:IsA("Model") and myCharModel.PrimaryPart)
        or myCharModel:FindFirstChildWhichIsA("BasePart", true)

    return myCharModel, root, humanoid
end

-- ==================== 強化版角色傳送函數（Complete Obby 用） ====================
local function teleportMyCharacterTo(cf)
    if not cf then return false end

    local ok, err = pcall(function()
        local myCharModel, root, humanoid = getCharacterRoot()
        if not myCharModel then
            warn("[Teleport] 找不到角色模型: " .. tostring(LocalPlayer.Name))
            return
        end

        if humanoid and humanoid.Sit then
            humanoid.Sit = false
            task.wait()
        end

        for _, part in ipairs(myCharModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end

        if myCharModel:IsA("Model") then
            myCharModel:PivotTo(cf)
        end

        if root then
            root.CFrame = cf
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    if not ok then
        warn("[Teleport] 傳送發生錯誤: " .. tostring(err))
        return false
    end
    return true
end

-- ==================== Tween 連續滑動移動函數（Auto Ring 用） ====================
local RING_TWEEN_SPEED = 220 -- 每秒移動 Studs 數
local RING_MIN_TIME = 0.15   -- 單段 Tween 最短時間
local RING_MAX_TIME = 2.0    -- 單段 Tween 最長時間
local RING_STEP_DELAY = 0    -- 抵達光圈後不停頓，直接銜接下一個
local RING_LOOP_DELAY = 0    -- 跑完一輪後不停頓，直接重啟下一輪

local function tweenCharacterTo(targetCF)
    if not targetCF then return false end

    local ok, err = pcall(function()
        local myCharModel, root, humanoid = getCharacterRoot()
        if not myCharModel or not root then
            warn("[Tween] 找不到角色或 Root 部件")
            return
        end

        if humanoid and humanoid.Sit then
            humanoid.Sit = false
            task.wait()
        end

        local distance = (root.Position - targetCF.Position).Magnitude
        local duration = math.clamp(distance / math.max(RING_TWEEN_SPEED, 1), RING_MIN_TIME, RING_MAX_TIME)

        local oldAnchored = root.Anchored
        root.Anchored = false
        for _, part in ipairs(myCharModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local tween = TweenService:Create(root, tweenInfo, { CFrame = targetCF })
        local finished = false

        tween.Completed:Connect(function()
            finished = true
        end)

        tween:Play()
        while not finished do
            if not autoRingEnabled then
                tween:Cancel()
                break
            end
            task.wait()
        end

        root.Anchored = oldAnchored
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    if not ok then
        warn("[Tween] 移動發生錯誤: " .. tostring(err))
        return false
    end
    return true
end

-- ==================== Complete Obby 循序傳送邏輯 ====================
local function completeObby()
    task.spawn(function()
        pcall(function()
            local activitiesTest = Workspace:FindFirstChild("ActivitiesTest")
            if not activitiesTest then
                warn("[Complete Obby] 找不到 workspace.ActivitiesTest！")
                return
            end

            local obbyFolder = activitiesTest:FindFirstChild("Obby")
            local steps = {
                { label = "1/5 ObbyStart", obj = obbyFolder and obbyFolder:FindFirstChild("ObbyStart"), required = true },
                { label = "2/5 Checkpoint1", obj = activitiesTest:FindFirstChild("Checkpoint1"), required = false },
                { label = "3/5 Checkpoint2", obj = activitiesTest:FindFirstChild("Checkpoint2"), required = false },
                { label = "4/5 Checkpoint3", obj = activitiesTest:FindFirstChild("Checkpoint3"), required = false },
                { label = "5/5 ObbyFinish", obj = activitiesTest:FindFirstChild("ObbyFinish"), required = true },
            }

            for _, step in ipairs(steps) do
                local targetCFrame = getTargetCFrame(step.obj)
                if targetCFrame then
                    teleportMyCharacterTo(targetCFrame + Vector3.new(0, 3, 0))
                    print("[Complete Obby] 已傳送至 " .. step.label)
                    task.wait(0.25)
                elseif step.required then
                    warn("[Complete Obby] 找不到必要節點: " .. step.label)
                    return
                else
                    warn("[Complete Obby] 略過找不到的節點: " .. step.label)
                end
            end
        end)
    end)
end

-- ==================== Auto Block Lever 循環 ====================
local function triggerBlockLever()
    pcall(function()
        local hubLever = Workspace:FindFirstChild("HubLever")
        local baseDark = hubLever and hubLever:FindFirstChild("Base_Dark")
        local prompt = baseDark and baseDark:FindFirstChildOfClass("ProximityPrompt") or (baseDark and baseDark:FindFirstChild("ProximityPrompt"))

        if prompt and prompt:IsA("ProximityPrompt") then
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration or 0)
                prompt:InputHoldEnd()
            end
        end
    end)
end

task.spawn(function()
    while true do
        if autoBlockLeverEnabled then
            triggerBlockLever()
            task.wait(0.3)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Auto Ring 連續 Tween 循序移動邏輯 ====================
local function findRing(parent, name)
    return parent:FindFirstChild(name) or parent:FindFirstChild(name, true)
end

local function runAutoRingOnce()
    if isRunningAutoRing then return end
    isRunningAutoRing = true

    local ok, err = pcall(function()
        local activitiesTest = Workspace:FindFirstChild("ActivitiesTest")
        if not activitiesTest then
            warn("[Auto Ring] 找不到 workspace.ActivitiesTest")
            return
        end

        local flightTrial = activitiesTest:FindFirstChild("FlightTrial")
        if not flightTrial then
            warn("[Auto Ring] 找不到 FlightTrial")
            return
        end

        local flightRings = flightTrial:FindFirstChild("FlightRings")
        if not flightRings then
            warn("[Auto Ring] 找不到 FlightRings")
            return
        end

        local ringSequence = {}
        local startRing = findRing(flightRings, "FlightRingStart")
        if startRing then
            table.insert(ringSequence, { name = "FlightRingStart", obj = startRing })
        else
            warn("[Auto Ring] 找不到 FlightRingStart")
        end

        for i = 1, 14 do
            if not autoRingEnabled then break end
            local ringName = "FlightRing" .. tostring(i)
            local ringObj = findRing(flightRings, ringName)
            if ringObj then
                table.insert(ringSequence, { name = ringName, obj = ringObj })
            else
                warn("[Auto Ring] 找不到 " .. ringName)
            end
        end

        local finishRing = findRing(flightRings, "FlightRingFinish")
        if finishRing then
            table.insert(ringSequence, { name = "FlightRingFinish", obj = finishRing })
        else
            warn("[Auto Ring] 找不到 FlightRingFinish")
        end

        print("[Auto Ring] 共收集到光圈數量: " .. tostring(#ringSequence))
        if #ringSequence == 0 then return end

        for idx, item in ipairs(ringSequence) do
            if not autoRingEnabled then break end
            local cf = getTargetCFrame(item.obj)
            if cf then
                tweenCharacterTo(cf)
                print(string.format("[Auto Ring] (%d/%d) Tween 抵達 %s", idx, #ringSequence, item.name))
                if RING_STEP_DELAY > 0 then
                    task.wait(RING_STEP_DELAY)
                end
            else
                warn("[Auto Ring] 無法取得座標: " .. item.name)
            end
        end
    end)

    if not ok then
        warn("[Auto Ring] 執行錯誤: " .. tostring(err))
    end

    isRunningAutoRing = false
end

task.spawn(function()
    while true do
        if autoRingEnabled and not isRunningAutoRing then
            runAutoRingOnce()
            if RING_LOOP_DELAY > 0 then
                task.wait(RING_LOOP_DELAY)
            else
                task.wait()
            end
        else
            task.wait(0.1)
        end
    end
end)

-- ==================== UI 設定 ====================
local function onAutoBlockLeverToggle(enabled)
    autoBlockLeverEnabled = enabled
    if enabled then
        print("[Auto Block Lever] 已開啟")
    else
        print("[Auto Block Lever] 已關閉")
    end
end

local function onAutoRingToggle(enabled)
    autoRingEnabled = enabled
    if enabled then
        print("[Auto Ring] 已開啟")
    else
        print("[Auto Ring] 已關閉")
    end
end

UI:Button("CompleteObbyBtn", "Complete Obby", completeObby)
UI:Toggle("AutoBlockLeverToggle", "Auto Block Lever", onAutoBlockLeverToggle)
UI:Toggle("AutoRingToggle", "Auto Ring", onAutoRingToggle)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Complete Obby, Auto Block Lever & Auto Ring (Continuous Tween) script loaded!")
