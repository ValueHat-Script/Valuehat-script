-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Jump For Cases")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local MIN_SPEED = 20
local MAX_SPEED = 200
local velocitySpeed = MIN_SPEED

local autoPerfectJump = false
local autoCollectMoney = false
local upgradeAllAnimals = false

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local requestKickRemote = remotesFolder:WaitForChild("RequestKick")
local requestBasePadRemote = remotesFolder:WaitForChild("RequestBasePad")
local requestSlotLevelRemote = remotesFolder:WaitForChild("RequestSlotLevel")
local requestSlotSignSyncRemote = remotesFolder:WaitForChild("RequestSlotSignSync")

local function getChar()
    return LocalPlayer.Character
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    local root = getRoot()
    if not hum or not root or not root.Parent or hum.Health <= 0 then return end

    local moveDir = hum.MoveDirection
    if moveDir.Magnitude > 0 then
        local currentVel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(
            moveDir.X * velocitySpeed,
            currentVel.Y,
            moveDir.Z * velocitySpeed
        )
    end
end)

-- 取得 workspace.Map.JumpZone 的座標
local function getJumpZonePosition()
    local map = Workspace:FindFirstChild("Map")
    local jumpZone = map and map:FindFirstChild("JumpZone")
    if not jumpZone then
        warn("[Auto Perfect Jump] 找不到 workspace.Map.JumpZone！")
        return nil
    end

    if jumpZone:IsA("BasePart") then
        return jumpZone.Position + Vector3.new(0, 3, 0)
    elseif jumpZone:IsA("Model") then
        local cf, size = jumpZone:GetBoundingBox()
        return cf.Position + Vector3.new(0, size.Y * 0.5 + 3, 0)
    else
        for _, obj in ipairs(jumpZone:GetDescendants()) do
            if obj:IsA("BasePart") then
                return obj.Position + Vector3.new(0, 3, 0)
            end
        end
    end

    return nil
end

-- 傳送角色到 workspace.Map.JumpZone
local function teleportToJumpZone()
    local root = getRoot()
    if not root then
        warn("[Auto Perfect Jump] 找不到 HumanoidRootPart！")
        return false
    end

    local targetPos = getJumpZonePosition()
    if targetPos then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(targetPos)
        return true
    end

    return false
end

-- ==================== Auto Perfect Jump 迴圈 ====================
task.spawn(function()
    while true do
        if autoPerfectJump then
            pcall(function()
                requestKickRemote:FireServer({
                    tier = "Perfect"
                })
            end)
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Auto Collect Money 迴圈 ====================
task.spawn(function()
    while true do
        if autoCollectMoney and requestBasePadRemote then
            pcall(function()
                requestBasePadRemote:FireServer("Collect")
            end)
            task.wait(0.25)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Upgrade All Animals 迴圈 (Slot 1 ~ 30) ====================
task.spawn(function()
    while true do
        if upgradeAllAnimals and requestSlotLevelRemote then
            for slotIndex = 1, 30 do
                if not upgradeAllAnimals then break end
                pcall(function()
                    requestSlotLevelRemote:FireServer({
                        slot = slotIndex
                    })
                end)
                task.wait(0.05)
            end
            task.wait(0.2)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== UI ====================
UI:Toggle("AutoPerfectJumpToggle", "Auto Perfect Jump", function(enabled)
    autoPerfectJump = enabled

    if enabled then
        print("[Auto Perfect Jump] 已開啟，傳送至 workspace.Map.JumpZone")
        teleportToJumpZone()
    else
        print("[Auto Perfect Jump] 已關閉")
    end
end)

UI:Toggle("AutoCollectMoneyToggle", "Auto Collect Money", function(enabled)
    autoCollectMoney = enabled
    if enabled then
        print("[Auto Collect Money] 已開啟")
    else
        print("[Auto Collect Money] 已關閉")
    end
end)

UI:Toggle("UpgradeAllAnimalsToggle", "Upgrade All Animals", function(enabled)
    upgradeAllAnimals = enabled
    if enabled then
        print("[Upgrade All Animals] 已開啟 (Slot 1~30)")
    else
        print("[Upgrade All Animals] 已關閉")
    end
end)

UI:Slider("SpeedSlider", "Speed", MIN_SPEED, MAX_SPEED, MIN_SPEED, function(value)
    velocitySpeed = tonumber(value) or MIN_SPEED
end)

UI:Button("PlaceBestBtn", "Place Best", function()
    if requestBasePadRemote then
        pcall(function()
            requestBasePadRemote:FireServer("PlaceMode", "Highest")
            print("[Place Best] 已執行 PlaceMode -> Highest")
        end)
    else
        warn("[Place Best] 找不到 ReplicatedStorage.Remotes.RequestBasePad！")
    end
end)

UI:Button("UpgradeBaseBtn", "Upgrade Base", function()
    if requestSlotSignSyncRemote then
        pcall(function()
            requestSlotSignSyncRemote:FireServer()
            print("[Upgrade Base] 已執行 RequestSlotSignSync")
        end)
    else
        warn("[Upgrade Base] 找不到 ReplicatedStorage.Remotes.RequestSlotSignSync！")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded!")
