-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local noclipEnabled = false
local noclipConnection

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

-- ==================== 傳送函數 ====================
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

-- ==================== TP Generator 邏輯 ====================
local function tpGenerator()
    local maze = Workspace:FindFirstChild("Maze")
    if maze then
        local generators = maze:FindFirstChild("Generators")
        if generators then
            for _, obj in ipairs(generators:GetChildren()) do
                if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                    teleportTo(obj.CFrame + Vector3.new(0, 3, 0))
                    print("[TP Generator] 已傳送到: " .. obj.Name)
                    return
                elseif obj:IsA("Model") then
                    local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        teleportTo(targetPart.CFrame + Vector3.new(0, 3, 0))
                        print("[TP Generator] 已傳送到模型: " .. obj.Name)
                        return
                    end
                end
            end
            warn("[TP Generator] 在 Generators 中找不到任何可傳送的物件！")
        else
            warn("[TP Generator] 找不到 workspace.Maze.Generators 資料夾！")
        end
    else
        warn("[TP Generator] 找不到 workspace.Maze！")
    end
end

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] Sleep Paralysis", "TikTok: ValueHat")

-- 新增 Noclip 開關
Hub:CreateToggle("Noclip", false, function(on)
    noclipEnabled = on
    setNoclip(on)
    if on then
        print("[Noclip] 已開啟")
    else
        print("[Noclip] 已關閉")
    end
end)

-- 新增 TP Generator 按鈕
Hub:CreateButton("TP Generator", function()
    tpGenerator()
end)

print("[ValueHat] Script loaded successfully!")
