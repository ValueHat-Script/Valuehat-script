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

-- ESP 狀態與物件紀錄
local chestEspEnabled = false
local espObjects = {}
local tracerConnection = nil

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

-- ==================== Chest ESP 與引導線邏輯 ====================
local function removeChestESP()
    if tracerConnection then
        tracerConnection:Disconnect()
        tracerConnection = nil
    end

    for _, item in pairs(espObjects) do
        if item and item.Parent then
            item:Destroy()
        end
    end
    espObjects = {}
end

local function applyESP(targetObj)
    if not targetObj or targetObj:FindFirstChild("ChestESP_Tag") then return end

    local adornPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
    if not adornPart then return end

    -- 1. Highlight 高亮效果
    local highlight = Instance.new("Highlight")
    highlight.Name = "ChestESP_Tag"
    highlight.Adornee = targetObj
    highlight.FillColor = Color3.fromRGB(0, 255, 255) -- 青色
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = targetObj
    table.insert(espObjects, highlight)

    -- 2. BillboardGui 文字標籤
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChestESP_Tag"
    billboard.Adornee = adornPart
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "[ CHEST ]"
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard

    billboard.Parent = targetObj
    table.insert(espObjects, billboard)

    -- 3. 3D 引導線 (Beam 效果)
    local linePart = Instance.new("Part")
    linePart.Name = "ChestESP_Line"
    linePart.Size = Vector3.new(0.1, 0.1, 0.1)
    linePart.Transparency = 1
    linePart.Anchored = true
    linePart.CanCollide = false
    linePart.Parent = Workspace

    local attachment0 = Instance.new("Attachment", linePart)
    local attachment1 = Instance.new("Attachment", adornPart)

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
    beam.Width0 = 0.05
    beam.Width1 = 0.05
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.2)
    beam.Parent = linePart

    table.insert(espObjects, linePart)

    -- 動態更新引導線起點 (跟隨玩家角色)
    local conn = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and linePart and linePart.Parent then
            linePart.CFrame = char.HumanoidRootPart.CFrame
        end
    end)
    table.insert(espObjects, {
        Destroy = function()
            if conn then conn:Disconnect() end
        end
    })
end

local function scanAndApplyChestESP()
    removeChestESP()

    local pickups = Workspace:FindFirstChild("Pickups")
    if not pickups then return end

    local chestFolder = pickups:FindFirstChild("Chest")
    if not chestFolder then return end

    for _, obj in ipairs(chestFolder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            applyESP(obj)
        end
    end
end

local function startChestESP()
    task.spawn(function()
        while chestEspEnabled do
            scanAndApplyChestESP()
            task.wait(2)
        end
        removeChestESP()
    end)
end

-- ==================== 刷新與取得所有 Chest ====================
local function refreshChestQueue()
    local pickups = Workspace:FindFirstChild("Pickups")
    if not pickups then
        warn("[TP Chest] 找不到 workspace.Pickups！")
        return false
    end

    local chestFolder = pickups:FindFirstChild("Chest")
    if not chestFolder then
        warn("[TP Chest] 找不到 workspace.Pickups.Chest！")
        return false
    end

    chestQueue = {}
    for _, obj in ipairs(chestFolder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            table.insert(chestQueue, obj)
        end
    end

    if #chestQueue == 0 then
        warn("[TP Chest] Chest 資料夾裡面沒有找到任何 Model 或 BasePart！")
        return false
    end

    currentChestIndex = 1
    print("[TP Chest] 已重置/載入寶箱清單，共 " .. tostring(#chestQueue) .. " 個寶箱")
    return true
end

-- ==================== TP Chest (不重複輪播) 邏輯 ====================
local function tpNextChest()
    if #chestQueue == 0 or currentChestIndex > #chestQueue then
        local success = refreshChestQueue()
        if not success then return end
    end

    local currentChest = chestQueue[currentChestIndex]

    if currentChest and currentChest.Parent then
        local targetCFrame = nil
        if currentChest:IsA("BasePart") then
            targetCFrame = currentChest.CFrame
        elseif currentChest:IsA("Model") then
            local targetPart = currentChest.PrimaryPart or currentChest:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentChest:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            task.wait(0.2)

            triggerPromptsInObject(currentChest)
            if currentChest.Parent then
                triggerPromptsInObject(currentChest.Parent)
            end

            print(string.format("[TP Chest] [%d/%d] 已傳送到寶箱: %s", currentChestIndex, #chestQueue, currentChest.Name))
            currentChestIndex = currentChestIndex + 1
        else
            warn("[TP Chest] 寶箱 " .. currentChest.Name .. " 內找不到基準零件，跳過")
            currentChestIndex = currentChestIndex + 1
            tpNextChest()
        end
    else
        currentChestIndex = currentChestIndex + 1
        tpNextChest()
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Moo Moo mystery", "TikTok: ValueHat")

-- 新增 Chest ESP (含引導線) 開關
HubWindow:CreateToggle("Chest ESP", false, function(on)
    chestEspEnabled = on
    if on then
        print("[Chest ESP] 已開啟 (含引導線)")
        startChestESP()
    else
        print("[Chest ESP] 已關閉")
        removeChestESP()
    end
end)

-- 新增 TP Chest 按鈕
HubWindow:CreateButton("TP Chest", function()
    tpNextChest()
end)

print("[ValueHat] Chest ESP with Tracers & TP Chest script loaded successfully!")
