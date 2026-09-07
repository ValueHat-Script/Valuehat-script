-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗並清理舊組件
local Hub = UIModule.CreateWindow("Volleyball Legend", "TikTok: ValueHat")
Hub:Clear()

-- 核心變數與服務
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BALL_NAME = "CLIENT_BALL"
local HitboxEnabled = false
local HitboxSize = 15
local MIN_SIZE = 6
local MAX_SIZE = 50

local Hitboxes = {}
local TrackedBalls = {}
local TouchingParts = {}

-- Speed 鎖定相關變數
local currentSpeed = 16
local speedEnabled = false

---------------------------------------------------------
-- Speed 強制寫入邏輯 (防止被遊戲蓋過)
---------------------------------------------------------

-- 每幀更新，防止遊戲腳本修改速度
RunService.Stepped:Connect(function()
    if speedEnabled and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = currentSpeed
        end
    end
end)

---------------------------------------------------------
-- Hitbox 核心邏輯處理
---------------------------------------------------------

local function isBall(object)
    return object:IsA("Model") and string.find(object.Name, BALL_NAME, 1, true) ~= nil
end

local function getBallPart(ballModel)
    if ballModel.PrimaryPart then return ballModel.PrimaryPart end
    return ballModel:FindFirstChildWhichIsA("BasePart", true)
end

local function onHitboxTouched(ballModel, touchedPart)
    if touchedPart:IsDescendantOf(ballModel) then return end
end

local function removeHitbox(ballModel)
    local hitbox = Hitboxes[ballModel]
    if hitbox and hitbox.Parent then 
        hitbox:Destroy() 
    end
    Hitboxes[ballModel] = nil
    TouchingParts[ballModel] = nil
end

local function createHitbox(ballModel)
    if not HitboxEnabled then return end
    if not ballModel or not ballModel.Parent then return end
    
    local ballPart = getBallPart(ballModel)
    if not ballPart then return end
    
    local existing = Hitboxes[ballModel]
    if existing and existing.Parent then
        existing.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        return
    end
    
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Shape = Enum.PartType.Ball
    hitbox.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
    hitbox.CFrame = ballPart.CFrame
    hitbox.Color = Color3.fromRGB(50, 255, 100)
    hitbox.Material = Enum.Material.ForceField
    hitbox.Transparency = 0.65
    hitbox.CanCollide = false
    hitbox.CanTouch = true
    hitbox.CanQuery = true
    hitbox.CastShadow = false
    hitbox.Massless = true
    hitbox.Anchored = false
    hitbox.Parent = ballModel
    
    local weld = Instance.new("WeldConstraint")
    weld.Name = "Hitbox"
    weld.Part0 = ballPart
    weld.Part1 = hitbox
    weld.Parent = hitbox
    
    Hitboxes[ballModel] = hitbox
    TouchingParts[ballModel] = {}
    
    hitbox.Touched:Connect(function(otherPart)
        if HitboxEnabled then onHitboxTouched(ballModel, otherPart) end
    end)
end

local function trackBall(ballModel)
    if TrackedBalls[ballModel] then return end
    TrackedBalls[ballModel] = true
    if HitboxEnabled then createHitbox(ballModel) end
    
    ballModel.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            removeHitbox(ballModel)
            TrackedBalls[ballModel] = nil
        end
    end)
end

local function scanForBalls()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if isBall(object) then trackBall(object) end
    end
end

local function enableHitboxes()
    HitboxEnabled = true
    for ballModel in pairs(TrackedBalls) do
        if ballModel.Parent then createHitbox(ballModel) end
    end
end

local function disableHitboxes()
    HitboxEnabled = false
    for ballModel in pairs(Hitboxes) do 
        removeHitbox(ballModel) 
    end
    table.clear(Hitboxes)
    table.clear(TouchingParts)
end

local function setHitboxSize(size)
    HitboxSize = math.clamp(math.round(size), MIN_SIZE, MAX_SIZE)
    for ballModel, hitbox in pairs(Hitboxes) do
        if ballModel.Parent and hitbox.Parent then
            hitbox.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        else
            Hitboxes[ballModel] = nil
        end
    end
end

---------------------------------------------------------
-- UI 控制組件 (ValueHatGui 語法)
---------------------------------------------------------

-- 1. Hitbox 開關 Toggle
Hub:CreateToggle("Enable Ball Hitbox", false, function(isOn)
    if isOn then 
        enableHitboxes() 
    else 
        disableHitboxes() 
    end
end)

-- 2. Ball Hitbox 大小 Slider 滑桿
Hub:CreateSlider("Ball Hitbox Size", MIN_SIZE, MAX_SIZE, HitboxSize, function(value)
    setHitboxSize(value)
end)

-- 3. WalkSpeed 速度滑桿 (最高 50)
Hub:CreateSlider("WalkSpeed (Max 50)", 16, 50, 16, function(value)
    currentSpeed = value
    speedEnabled = true
    
    -- 立即套用一次
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
    end
end)

---------------------------------------------------------
-- 監聽與迴圈
---------------------------------------------------------

RunService.Heartbeat:Connect(function()
    if not HitboxEnabled then return end
    for ballModel, hitbox in pairs(Hitboxes) do
        if not ballModel.Parent or not hitbox.Parent then
            removeHitbox(ballModel)
            continue
        end
        
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = { ballModel }
        
        local currentParts = {}
        for _, part in ipairs(Workspace:GetPartsInPart(hitbox, overlapParams)) do
            currentParts[part] = true
            local previousParts = TouchingParts[ballModel]
            if previousParts and not previousParts[part] then
                onHitboxTouched(ballModel, part)
            end
        end
        TouchingParts[ballModel] = currentParts
    end
end)

Workspace.DescendantAdded:Connect(function(object)
    if isBall(object) then trackBall(object) end
end)

-- 啟動初始掃描
scanForBalls()
