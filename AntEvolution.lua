-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Ant Evolution")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local autoOrbEnabled = false
local autoEvolveEnabled = false
local autoRebirthEnabled = false
local currentSpeed = 50
local currentTween = nil

-- 目標顏色 (196, 110, 255)
local targetColor = Color3.fromRGB(196, 110, 255)

local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHumanoid()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function isTargetColor(color)
    if not color then return false end

    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)

    return math.abs(r - 196) <= 5 and math.abs(g - 110) <= 5 and math.abs(b - 255) <= 5
end

local function getTargetOrbs()
    local orbs = {}
    local clientOrbs = Workspace:FindFirstChild("ClientOrbs")
    if not clientOrbs then return orbs end

    for _, obj in ipairs(clientOrbs:GetChildren()) do
        if obj.Name == "Orb" then
            if obj:IsA("MeshPart") or obj:IsA("BasePart") then
                if isTargetColor(obj.Color) then
                    table.insert(orbs, obj)
                end
            end
        end
    end
    return orbs
end

local function getNearestOrb()
    local hrp = getHRP()
    if not hrp then return nil end

    local orbs = getTargetOrbs()
    if #orbs == 0 then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, orb in ipairs(orbs) do
        if orb and orb.Parent then
            local dist = (orb.Position - hrp.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = orb
            end
        end
    end

    return nearest
end

local function tweenTo(cf, duration)
    duration = duration or 0.7
    local hrp = getHRP()
    if not hrp or not cf then return end

    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    currentTween = TweenService:Create(hrp, tweenInfo, { CFrame = cf })
    currentTween:Play()
    currentTween.Completed:Wait()
    currentTween = nil
end

local function doEvolve()
    pcall(function()
        ReplicatedStorage.AntRemotes.Evolve:InvokeServer()
    end)
end

local function doRebirth()
    pcall(function()
        ReplicatedStorage.AntRemotes.Rebirth:InvokeServer()
    end)
end

-- Speed（持續生效，使用 AssemblyLinearVelocity）
RunService.Heartbeat:Connect(function()
    local root = getHRP()
    local humanoid = getHumanoid()
    if not root or not humanoid or humanoid.Health <= 0 then return end

    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude == 0 then return end

    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(
        moveDirection.X * currentSpeed,
        velocity.Y,
        moveDirection.Z * currentSpeed
    )
end)

local function startAutoOrb()
    task.spawn(function()
        while autoOrbEnabled do
            local nearest = getNearestOrb()
            if nearest then
                local targetCF = nearest.CFrame + Vector3.new(0, 3, 0)
                tweenTo(targetCF, 0.7)
                task.wait(0.3)
            else
                task.wait(1.5)
            end
            task.wait(0.2)
        end

        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
    end)
end

local function startAutoEvolve()
    task.spawn(function()
        while autoEvolveEnabled do
            doEvolve()
            task.wait(2)
        end
    end)
end

local function startAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            doRebirth()
            task.wait(3)
        end
    end)
end

-- ==================== UI ====================
UI:Toggle("AutoOrbToggle", "Auto Orb", function(enabled)
    autoOrbEnabled = enabled
    if enabled then
        startAutoOrb()
        print("[Auto Orb] 已開啟")
    else
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        print("[Auto Orb] 已關閉")
    end
end)

UI:Toggle("AutoEvolveToggle", "Auto Evolve", function(enabled)
    autoEvolveEnabled = enabled
    if enabled then
        startAutoEvolve()
        print("[Auto Evolve] 已開啟")
    else
        print("[Auto Evolve] 已關閉")
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

UI:Slider("SpeedSlider", "Speed", 16, 200, 50, function(value)
    currentSpeed = value
    print("[Speed] 目前速度:", value)
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
