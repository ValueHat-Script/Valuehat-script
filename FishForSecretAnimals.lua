-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Fish For Secret Animals")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local TARGET_POS = Vector3.new(-121, 87, 39)
local isRunningBestFish = false
local autoEquipBest = false
local autoX2Train = false
local autoUpgradeAll = false

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local fillPenRemote = remotesFolder:WaitForChild("FillPen")
local buyTierRemote = remotesFolder:WaitForChild("BuyTier")

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportToTarget(pos)
    local root = getRoot()
    if not root or not root.Parent then
        warn("[Best Fish] 找不到 HumanoidRootPart！")
        return false
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(pos)
    return true
end

local function clickScreenCenter()
    local camera = Workspace.CurrentCamera
    local x, y = 500, 300

    if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
        x = camera.ViewportSize.X * 0.5
        y = camera.ViewportSize.Y * 0.5
    end

    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        end)
        task.wait(0.03)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end
end

local function resolveClickable(obj)
    if not obj then return nil end
    if obj:IsA("GuiButton") or obj:IsA("BindableEvent") or obj:IsA("RemoteEvent") then
        return obj
    end
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("GuiButton") or desc:IsA("BindableEvent") or desc:IsA("RemoteEvent") then
            return desc
        end
    end
    return obj
end

local function getDoubleTrainObject()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    local trainingGui = playerGui:FindFirstChild("TrainingGui")
    local doubleObj = trainingGui and trainingGui:FindFirstChild("Double")
    return resolveClickable(doubleObj)
end

local function triggerX2Train()
    local target = getDoubleTrainObject()
    if not target then return end

    if target:IsA("GuiButton") then
        if not target.Visible or not target.Active then return end

        local triggered = false
        if typeof(firesignal) == "function" then
            for _, sigName in ipairs({ "MouseButton1Click", "Activated" }) do
                local sig = target[sigName]
                if sig and pcall(function() firesignal(sig) end) then
                    triggered = true
                end
            end
        end

        if typeof(getconnections) == "function" then
            for _, sigName in ipairs({ "MouseButton1Click", "Activated" }) do
                local sig = target[sigName]
                if sig then
                    local ok, conns = pcall(getconnections, sig)
                    if ok and type(conns) == "table" then
                        for _, conn in ipairs(conns) do
                            if conn.Fire and pcall(function() conn:Fire() end) then
                                triggered = true
                            end
                        end
                    end
                end
            end
        end

        if not triggered and VirtualInputManager then
            local pos = target.AbsolutePosition
            local size = target.AbsoluteSize
            if size.X > 0 and size.Y > 0 then
                local x = pos.X + size.X * 0.5
                local y = pos.Y + size.Y * 0.5
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                end)
                task.wait(0.03)
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                end)
            end
        end
    elseif target:IsA("BindableEvent") then
        pcall(function() target:Fire() end)
    elseif target:IsA("RemoteEvent") then
        pcall(function() target:FireServer() end)
    end
end

-- ==================== Equip Best 循環 ====================
task.spawn(function()
    while true do
        if autoEquipBest and fillPenRemote then
            pcall(function()
                fillPenRemote:FireServer()
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== x2 Train 循環 ====================
task.spawn(function()
    while true do
        if autoX2Train then
            pcall(triggerX2Train)
            task.wait(0.25)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Upgrade All 循環 ====================
task.spawn(function()
    while true do
        if autoUpgradeAll and buyTierRemote then
            pcall(function()
                buyTierRemote:InvokeServer("Pen")
            end)
            task.wait(0.15)
            pcall(function()
                buyTierRemote:InvokeServer("Bar")
            end)
            task.wait(0.35)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== UI ====================
UI:Button("BestFishBtn", "Best Animal", function()
    if isRunningBestFish then return end
    isRunningBestFish = true

    task.spawn(function()
        local ok = teleportToTarget(TARGET_POS)
        if ok then
            task.wait(2)
            clickScreenCenter()
            print("[Best Fish] 已傳送至 (-121, 87, 39)、等待 2 秒並點擊螢幕")
        end
        isRunningBestFish = false
    end)
end)

UI:Toggle("EquipBestToggle", "Equip Best", function(enabled)
    autoEquipBest = enabled
    if enabled then
        print("[Equip Best] 已開啟循環")
    else
        print("[Equip Best] 已關閉循環")
    end
end)

UI:Toggle("X2TrainToggle", "x2 Train", function(enabled)
    autoX2Train = enabled
    if enabled then
        print("[x2 Train] 已開啟循環")
    else
        print("[x2 Train] 已關閉循環")
    end
end)

UI:Toggle("UpgradeAllToggle", "Upgrade All", function(enabled)
    autoUpgradeAll = enabled
    if enabled then
        print("[Upgrade All] 已開啟循環 (Pen + Bar)")
    else
        print("[Upgrade All] 已關閉循環")
    end
end)

UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Best Fish loaded!")
