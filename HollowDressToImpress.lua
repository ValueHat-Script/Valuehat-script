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
local LocalPlayer = Players.LocalPlayer

-- 輪播佇列與紀錄 (Collect Orbs)
local orbQueue = {}
local currentOrbIndex = 1

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

-- ==================== 觸發 ProximityPrompt 邏輯 ====================
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

-- ==================== Auto Fuel 執行一次邏輯 ====================
local function executeAutoFuel()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvents then
            local event1 = remoteEvents:FindFirstChild("TriggerLanternPrompt")
            if event1 then
                event1:FireServer()
            end

            local event2 = remoteEvents:FindFirstChild("TriggerFuelPrompt")
            if event2 then
                event2:FireServer()
            end
            print("[Auto Fuel] 已執行一次")
        else
            warn("[Auto Fuel] 找不到 RemoteEvents！")
        end
    end)
end

-- ==================== 刷新與取得所有 workspace.FuelOrb Part ====================
local function refreshOrbQueue()
    orbQueue = {}

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "FuelOrb" and (obj:IsA("BasePart") or obj:IsA("Model")) then
            table.insert(orbQueue, obj)
        end
    end

    if #orbQueue == 0 then
        warn("[Collect Orbs] workspace 中沒有找到任何名為 FuelOrb 的物件！")
        return false
    end

    currentOrbIndex = 1
    print("[Collect Orbs] 已重置/載入 FuelOrb 清單，共 " .. tostring(#orbQueue) .. " 個光球")
    return true
end

-- ==================== Collect Orbs (不重複輪播) 邏輯 ====================
local function tpNextOrb()
    if #orbQueue == 0 or currentOrbIndex > #orbQueue then
        local success = refreshOrbQueue()
        if not success then return end
    end

    local currentOrb = orbQueue[currentOrbIndex]

    if currentOrb and currentOrb.Parent then
        local targetCFrame = nil
        if currentOrb:IsA("BasePart") then
            targetCFrame = currentOrb.CFrame
        elseif currentOrb:IsA("Model") then
            local targetPart = currentOrb.PrimaryPart or currentOrb:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentOrb:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            task.wait(0.2)

            triggerPromptsInObject(currentOrb)
            if currentOrb.Parent then
                triggerPromptsInObject(currentOrb.Parent)
            end

            print(string.format("[Collect Orbs] [%d/%d] 已傳送到 FuelOrb: %s", currentOrbIndex, #orbQueue, currentOrb.Name))
            currentOrbIndex = currentOrbIndex + 1
        else
            warn("[Collect Orbs] FuelOrb " .. currentOrb.Name .. " 找不到座標，跳過")
            currentOrbIndex = currentOrbIndex + 1
            tpNextOrb()
        end
    else
        currentOrbIndex = currentOrbIndex + 1
        tpNextOrb()
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Dress To Impress", "TikTok: ValueHat")

-- Auto Fuel 按鈕 (按一下執行一次)
HubWindow:CreateButton("Auto Fuel", function()
    executeAutoFuel()
end)

-- Collect Orbs 按鈕
HubWindow:CreateButton("Collect Orbs", function()
    tpNextOrb()
end)

print("[ValueHat] Auto Fuel & Collect Orbs script loaded successfully!")
