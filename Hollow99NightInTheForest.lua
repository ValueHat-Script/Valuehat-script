-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local autoFuelEnabled = false
local collectFlowersEnabled = false
local noclipEnabled = false
local noclipConnection = nil

-- ==================== Noclip 邏輯 ====================
local function setNoclip(enabled)
    if enabled then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

-- ==================== Velocity Speed 邏輯 (僅滑桿) ====================
local speedValue = 0
local speedConnection = nil

local function updateSpeedVelocity(value)
    speedValue = value

    if speedValue > 0 then
        if not speedConnection then
            speedConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local root = character:FindFirstChild("HumanoidRootPart")

                    if root and humanoid and humanoid.Health > 0 then
                        local moveDirection = humanoid.MoveDirection
                        local velocity = root.AssemblyLinearVelocity

                        root.AssemblyLinearVelocity = Vector3.new(
                            moveDirection.X * speedValue,
                            velocity.Y,
                            moveDirection.Z * speedValue
                        )
                    end
                end
            end)
        end
    else
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
    end
end

-- ==================== Auto Fuel 邏輯 ====================
local utility = {
    RequestStartDraggingItem = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("RequestStartDraggingItem"),
    StopDraggingItem = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("StopDraggingItem"),
    Items = Workspace:FindFirstChild("Items"),
    MainFire = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Campground") and Workspace.Map.Campground:FindFirstChild("MainFire")
}

utility.BringAllToFire = function(self)
    if not self.Items then self.Items = Workspace:FindFirstChild("Items") end
    if not self.MainFire then 
        local camp = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Campground")
        if camp then self.MainFire = camp:FindFirstChild("MainFire") end
    end
    if not self.RequestStartDraggingItem and ReplicatedStorage:FindFirstChild("RemoteEvents") then
        self.RequestStartDraggingItem = ReplicatedStorage.RemoteEvents:FindFirstChild("RequestStartDraggingItem")
    end
    if not self.StopDraggingItem and ReplicatedStorage:FindFirstChild("RemoteEvents") then
        self.StopDraggingItem = ReplicatedStorage.RemoteEvents:FindFirstChild("StopDraggingItem")
    end

    if not (self.Items and self.MainFire and self.RequestStartDraggingItem and self.StopDraggingItem) then
        return warn("[Auto Fuel] 找不到必要的遊戲物件或 RemoteEvents！")
    end

    local success, errormessage = pcall(function()
        local fuels = self.Items:QueryDescendants("[$BurnFuel]")
        for _, fuelsource in ipairs(fuels) do
            if not autoFuelEnabled then break end
            self.RequestStartDraggingItem:FireServer(fuelsource)
            fuelsource:MoveTo(self.MainFire:GetPivot().Position)
            self.StopDraggingItem:FireServer(fuelsource)
        end
    end)

    if success then
        return "success"
    else
        return warn("error: "..tostring(errormessage))
    end
end

local function startAutoFuel()
    task.spawn(function()
        while autoFuelEnabled do
            utility:BringAllToFire()
            task.wait(1)
        end
    end)
end

-- ==================== Collect Flowers (專注 Hollow Flower) 邏輯 ====================
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

local function triggerPromptsInObject(object)
    for _, descendant in ipairs(object:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            pcall(function()
                descendant.HoldDuration = 0
                descendant.MaxActivationDistance = 32
                fireproximityprompt(descendant)
            end)
        end
    end
end

local function startCollectFlowers()
    task.spawn(function()
        while collectFlowersEnabled do
            local hollowMap = Workspace:FindFirstChild("HollowMap")
            if hollowMap then
                local landmarks = hollowMap:FindFirstChild("Landmarks")
                if landmarks then
                    for _, descendant in ipairs(landmarks:GetDescendants()) do
                        if not collectFlowersEnabled then break end

                        if descendant.Name == "Hollow Flower" then
                            local targetPart = nil
                            local targetCFrame = nil

                            if descendant:IsA("Model") then
                                targetPart = descendant.PrimaryPart or descendant:FindFirstChildWhichIsA("BasePart", true)
                                targetCFrame = targetPart and targetPart.CFrame or descendant:GetPivot()
                            elseif descendant:IsA("BasePart") then
                                targetCFrame = descendant.CFrame
                            end

                            if targetCFrame then
                                teleportTo(targetCFrame + Vector3.new(0, 3, 0))
                                task.wait(0.2)

                                triggerPromptsInObject(descendant)
                                if descendant.Parent then
                                    triggerPromptsInObject(descendant.Parent)
                                end
                                task.wait(0.3)
                            end
                        end
                    end
                else
                    warn("[Collect Flowers] 找不到 workspace.HollowMap.Landmarks！")
                end
            else
                warn("[Collect Flowers] 找不到 workspace.HollowMap！")
            end
            
            task.wait(1)
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] 99 Night in the forest", "TikTok: ValueHat")

-- Speed 滑桿 (範圍 0 ~ 200，預設 0 為關閉)
HubWindow:CreateSlider("Speed", 0, 200, 0, function(value)
    updateSpeedVelocity(value)
    print("[Speed] 移動速度已調整為: " .. tostring(value))
end)

-- Noclip 開關
HubWindow:CreateToggle("Noclip", false, function(on)
    noclipEnabled = on
    setNoclip(on)
    if on then
        print("[Noclip] 已開啟")
    else
        print("[Noclip] 已關閉")
    end
end)

-- Auto Fuel 開關
HubWindow:CreateToggle("Auto Fuel", false, function(on)
    autoFuelEnabled = on
    if on then
        print("[Auto Fuel] 已開啟")
        startAutoFuel()
    else
        print("[Auto Fuel] 已關閉")
    end
end)

-- Collect Flowers 開關 (精準觸發 Hollow Flower)
HubWindow:CreateToggle("Collect Flowers", false, function(on)
    collectFlowersEnabled = on
    if on then
        print("[Collect Flowers] 已開啟")
        startCollectFlowers()
    else
        print("[Collect Flowers] 已關閉")
    end
end)

print("[ValueHat] Speed, Noclip, Auto Fuel & Collect Flowers script loaded successfully!")
