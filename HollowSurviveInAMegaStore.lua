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

-- 輪播佇列與紀錄
local chestQueue = {}
local currentChestIndex = 1

local currentHipHeight = 2
local hipHeightConnection = nil

-- ==================== HipHeight 邏輯 ====================
local function setHipHeight(value)
    currentHipHeight = value
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HipHeight = value
        end
    end
end

-- 持續維護 HipHeight，防止遊戲機制覆蓋重置
if not hipHeightConnection then
    hipHeightConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.HipHeight ~= currentHipHeight then
                humanoid.HipHeight = currentHipHeight
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

-- ==================== TP Back 邏輯 ====================
local function tpBack()
    local map = Workspace:FindFirstChild("Map")
    if not map then
        warn("[TP Back] 找不到 workspace.Map！")
        return
    end

    local util = map:FindFirstChild("Util")
    if not util then
        warn("[TP Back] 找不到 workspace.Map.Util！")
        return
    end

    local cauldron = util:FindFirstChild("Cauldron")
    if not cauldron then
        warn("[TP Back] 找不到 workspace.Map.Util.Cauldron！")
        return
    end

    local model = cauldron:FindFirstChild("Model")
    if not model then
        warn("[TP Back] 找不到 workspace.Map.Util.Cauldron.Model！")
        return
    end

    local cauldronVisual = model:FindFirstChild("_CauldronVisual")
    if cauldronVisual then
        local targetPart = nil
        if cauldronVisual:IsA("BasePart") then
            targetPart = cauldronVisual
        elseif cauldronVisual:IsA("Model") then
            targetPart = cauldronVisual.PrimaryPart or cauldronVisual:FindFirstChildWhichIsA("BasePart", true)
        end

        if targetPart then
            teleportTo(targetPart.CFrame + Vector3.new(0, 3, 0))
            print("[TP Back] 已成功傳送到 _CauldronVisual")
        else
            warn("[TP Back] _CauldronVisual 內找不到可傳送的零件！")
        end
    else
        warn("[TP Back] 找不到 workspace.Map.Util.Cauldron.Model._CauldronVisual！")
    end
end

-- ==================== 刷新與取得所有 PumpkinChest ====================
local function refreshChestQueue()
    local map = Workspace:FindFirstChild("Map")
    if not map then return false end

    local util = map:FindFirstChild("Util")
    if not util then return false end

    local pumpkinChests = util:FindFirstChild("PumpkinChests")
    if not pumpkinChests then return false end

    chestQueue = {}
    for _, obj in ipairs(pumpkinChests:GetChildren()) do
        if obj:IsA("Model") then
            table.insert(chestQueue, obj)
        end
    end

    if #chestQueue == 0 then return false end

    currentChestIndex = 1
    print("[TP Pumpkin Chest] 已重置/載入南瓜寶箱清單，共 " .. tostring(#chestQueue) .. " 個寶箱")
    return true
end

-- ==================== TP Pumpkin Chest (不重複輪播) 邏輯 ====================
local function tpNextPumpkinChest()
    if #chestQueue == 0 or currentChestIndex > #chestQueue then
        local success = refreshChestQueue()
        if not success then
            warn("[TP Pumpkin Chest] 找不到 PumpkinChests 或裡面沒有 Model！")
            return
        end
    end

    local currentChest = chestQueue[currentChestIndex]

    if currentChest and currentChest.Parent then
        local targetPart = currentChest.PrimaryPart or currentChest:FindFirstChildWhichIsA("BasePart", true)
        local targetCFrame = targetPart and targetPart.CFrame or currentChest:GetPivot()

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            task.wait(0.2)

            triggerPromptsInObject(currentChest)
            if currentChest.Parent then
                triggerPromptsInObject(currentChest.Parent)
            end

            print(string.format("[TP Pumpkin Chest] [%d/%d] 已傳送到寶箱: %s", currentChestIndex, #chestQueue, currentChest.Name))
            currentChestIndex = currentChestIndex + 1
        else
            warn("[TP Pumpkin Chest] 寶箱 " .. currentChest.Name .. " 內找不到基準零件，跳過")
            currentChestIndex = currentChestIndex + 1
            tpNextPumpkinChest()
        end
    else
        currentChestIndex = currentChestIndex + 1
        tpNextPumpkinChest()
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Survive in a mega store", "TikTok: ValueHat")

-- 新增 HipHeight 滑桿 (範圍 0 ~ 10，預設 2)
HubWindow:CreateSlider("HipHeight", 0, 20, 2, function(value)
    setHipHeight(value)
    print("[HipHeight] 懸浮高度已調整為: " .. tostring(value))
end)

-- TP Pumpkin Chest 按鈕
HubWindow:CreateButton("TP Pumpkin Chest", function()
    tpNextPumpkinChest()
end)

-- TP Back 按鈕
HubWindow:CreateButton("TP Back", function()
    tpBack()
end)

print("[ValueHat] HipHeight Slider, TP Pumpkin Chest & TP Back script loaded successfully!")
