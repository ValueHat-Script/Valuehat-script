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

local currentSpeed = 20
local speedConnection = nil

-- ==================== Speed 邏輯 ====================
local function setSpeed(value)
    currentSpeed = value
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
end

-- 持續維護 WalkSpeed，防止遊戲機制將速度覆蓋重置
if not speedConnection then
    speedConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.WalkSpeed ~= currentSpeed then
                humanoid.WalkSpeed = currentSpeed
            end
        end
    end)
end

-- ==================== 傳送通用函數 ====================
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

-- ==================== TP Back 邏輯 ====================
local function tpBack()
    local altarRock = Workspace:FindFirstChild("AltarRock")
    if altarRock then
        local altarBase = altarRock:FindFirstChild("AltarBase")
        if altarBase then
            if altarBase:IsA("BasePart") then
                teleportTo(altarBase.CFrame + Vector3.new(0, 3, 0))
                print("[TP Back] 已成功傳送到 AltarBase")
            elseif altarBase:IsA("Model") then
                local targetPart = altarBase.PrimaryPart or altarBase:FindFirstChildWhichIsA("BasePart", true)
                if targetPart then
                    teleportTo(targetPart.CFrame + Vector3.new(0, 3, 0))
                    print("[TP Back] 已成功傳送到 AltarBase (Model)")
                else
                    warn("[TP Back] AltarBase 模型內找不到可傳送的零件！")
                end
            else
                warn("[TP Back] AltarBase 型態無法識別！")
            end
        else
            warn("[TP Back] 找不到 workspace.AltarRock.AltarBase！")
        end
    else
        warn("[TP Back] 找不到 workspace.AltarRock！")
    end
end

-- ==================== TP Closet (傳送到最近的衣櫥) 邏輯 ====================
local function tpClosestCloset()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        warn("[TP Closet] 找不到玩家角色或 HumanoidRootPart！")
        return
    end

    local liminalEvent = Workspace:FindFirstChild("LiminalEvent")
    if not liminalEvent then
        warn("[TP Closet] 找不到 workspace.LiminalEvent！")
        return
    end

    local closets = liminalEvent:FindFirstChild("Closets")
    if not closets then
        warn("[TP Closet] 找不到 workspace.LiminalEvent.Closets！")
        return
    end

    local closestTarget = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(closets:GetChildren()) do
        local targetPart = nil
        if obj:IsA("Model") then
            targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        elseif obj:IsA("BasePart") then
            targetPart = obj
        end

        if targetPart then
            local distance = (root.Position - targetPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestTarget = targetPart
            end
        end
    end

    if closestTarget then
        teleportTo(closestTarget.CFrame + Vector3.new(0, 3, 0))
        print("[TP Closet] 已傳送到最近的衣櫥: " .. closestTarget.Parent.Name)
    else
        warn("[TP Closet] 在 Closets 中找不到任何可傳送的物件！")
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Demonology", "TikTok: ValueHat")

-- Speed 滑桿 (範圍 20 ~ 70，預設 20)
HubWindow:CreateSlider("Speed", 20, 70, 20, function(value)
    setSpeed(value)
    print("[Speed] 移動速度已設定為: " .. tostring(value))
end)

-- TP Back 按鈕
HubWindow:CreateButton("TP Back", function()
    tpBack()
end)

-- 新增 TP Closet 按鈕
HubWindow:CreateButton("TP Closet", function()
    tpClosestCloset()
end)

print("[ValueHat] Speed, TP Back & TP Closet script loaded successfully!")
