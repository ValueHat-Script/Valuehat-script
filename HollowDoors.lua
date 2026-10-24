-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local speedValue = 30 -- 預設速度
local character, root, humanoid
local speedConnection
local fullBrightEnabled = false

-- 用於恢復原本的 Lighting 設定
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- 綁定角色與組件
local function bindCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    task.spawn(bindCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(bindCharacter)

-- 速度控制迴圈
speedConnection = RunService.Heartbeat:Connect(function()
    if not root or not humanoid or humanoid.Health <= 0 then
        return
    end

    local moveDirection = humanoid.MoveDirection
    local velocity = root.AssemblyLinearVelocity

    root.AssemblyLinearVelocity = Vector3.new(
        moveDirection.X * speedValue,
        velocity.Y,
        moveDirection.Z * speedValue
    )
end)

-- Full Bright 邏輯
local function updateFullBright()
    if fullBrightEnabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
end

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] Doors", "TikTok: ValueHat")

-- Speed 滑桿 (範圍 20 到 100，預設 30)
Hub:CreateSlider("Speed (20-100)", 20, 100, 30, function(value)
    speedValue = value
    print("[Speed] 速度調整為:", speedValue)
end)

-- 新增 Full Bright 開關
Hub:CreateToggle("Full Bright", false, function(on)
    fullBrightEnabled = on
    updateFullBright()
    if on then
        print("[Full Bright] 已開啟")
    else
        print("[Full Bright] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
