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
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- 變數設定
local speedValue = 30 -- 預設速度
local character, root, humanoid
local speedConnection

local espEnabled = false
local highlights = {}

-- ==================== 角色綁定與 Speed 邏輯 ====================
local function bindCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    task.spawn(bindCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(bindCharacter)

-- 速度控制迴圈（根據滑桿數值即時生效）
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

-- ==================== Generators ESP 邏輯 ====================
local function updateGeneratorESP()
    local currentRoom = Workspace:FindFirstChild("CurrentRoom")
    local halloweenMap2 = currentRoom and currentRoom:FindFirstChild("HalloweenMap2")
    local generators = halloweenMap2 and halloweenMap2:FindFirstChild("Generators")

    if espEnabled then
        if generators then
            for _, child in ipairs(generators:GetChildren()) do
                if child:IsA("Model") and not highlights[child] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ValueHatGeneratorESP"
                    highlight.FillColor = Color3.fromRGB(0, 255, 255) -- 青色填滿
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- 白色外框
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = child
                    highlights[child] = highlight
                end
            end
        end
    else
        -- 關閉時清除所有高亮
        for model, highlight in pairs(highlights) do
            if highlight then
                highlight:Destroy()
            end
        end
        highlights = {}
    end
end

-- 背景迴圈即時檢測與更新 ESP
task.spawn(function()
    while true do
        if espEnabled then
            updateGeneratorESP()
        end
        task.wait(1)
    end
end)

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] Dandy's World", "TikTok: ValueHat")

-- Speed 滑桿 (範圍改為 20 到 50，預設 30)
Hub:CreateSlider("Speed (20-40)", 20, 40, 30, function(value)
    speedValue = value
    print("[Speed] 速度調整為:", speedValue)
end)

-- Generators ESP 開關
Hub:CreateToggle("Generators ESP", false, function(on)
    espEnabled = on
    updateGeneratorESP()
    if on then
        print("[Generators ESP] 已開啟")
    else
        print("[Generators ESP] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
