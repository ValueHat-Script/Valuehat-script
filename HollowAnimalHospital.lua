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
local slimeQueue = {}
local currentSlimeIndex = 1

-- ESP 狀態與物件紀錄
local slimeEspEnabled = false
local espObjects = {}

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

-- ==================== Slime ESP 與引導線邏輯 ====================
local function removeSlimeESP()
    for _, item in pairs(espObjects) do
        if item and item.Parent then
            item:Destroy()
        end
    end
    espObjects = {}
end

local function applyESP(targetObj)
    if not targetObj or targetObj:FindFirstChild("SlimeESP_Tag") then return end

    local adornPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
    if not adornPart then return end

    -- 1. Highlight 高亮效果 (粉紫色)
    local highlight = Instance.new("Highlight")
    highlight.Name = "SlimeESP_Tag"
    highlight.Adornee = targetObj
    highlight.FillColor = Color3.fromRGB(255, 105, 180) 
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = targetObj
    table.insert(espObjects, highlight)

    -- 2. BillboardGui 文字標籤
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SlimeESP_Tag"
    billboard.Adornee = adornPart
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "[ SLIME ]"
    textLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard

    billboard.Parent = targetObj
    table.insert(espObjects, billboard)

    -- 3. 3D 引導線 (Beam 效果)
    local linePart = Instance.new("Part")
    linePart.Name = "SlimeESP_Line"
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
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 105, 180))
    beam.Width0 = 0.05
    beam.Width1 = 0.05
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.2)
    beam.Parent = linePart

    table.insert(espObjects, linePart)

    -- 動態更新引導線起點 (跟隨玩家)
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

local function scanAndApplySlimeESP()
    removeSlimeESP()

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "PinkSlime" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            applyESP(obj)
        end
    end
end

local function startSlimeESP()
    task.spawn(function()
        while slimeEspEnabled do
            scanAndApplySlimeESP()
            task.wait(2)
        end
        removeSlimeESP()
    end)
end

-- ==================== 刷新與取得所有 PinkSlime ====================
local function refreshSlimeQueue()
    slimeQueue = {}

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "PinkSlime" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            table.insert(slimeQueue, obj)
        end
    end

    if #slimeQueue == 0 then
        warn("[TP Slime] workspace 中找不到任何 PinkSlime！")
        return false
    end

    currentSlimeIndex = 1
    print("[TP Slime] 已重置/載入史萊姆清單，共 " .. tostring(#slimeQueue) .. " 個")
    return true
end

-- ==================== TP Slime (純傳送，不觸發 Prompt) ====================
local function tpNextSlime()
    if #slimeQueue == 0 or currentSlimeIndex > #slimeQueue then
        local success = refreshSlimeQueue()
        if not success then return end
    end

    local currentSlime = slimeQueue[currentSlimeIndex]

    if currentSlime and currentSlime.Parent then
        local targetCFrame = nil
        if currentSlime:IsA("BasePart") then
            targetCFrame = currentSlime.CFrame
        elseif currentSlime:IsA("Model") then
            local targetPart = currentSlime.PrimaryPart or currentSlime:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentSlime:GetPivot()
        end

        if targetCFrame then
            -- 僅傳送到史萊姆上方，不呼叫任何觸發函數
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))

            print(string.format("[TP Slime] [%d/%d] 已傳送到史萊姆: %s", currentSlimeIndex, #slimeQueue, currentSlime.Name))
            currentSlimeIndex = currentSlimeIndex + 1
        else
            warn("[TP Slime] 史萊姆 " .. currentSlime.Name .. " 找不到座標，跳過")
            currentSlimeIndex = currentSlimeIndex + 1
            tpNextSlime()
        end
    else
        currentSlimeIndex = currentSlimeIndex + 1
        tpNextSlime()
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Animal Hospital", "TikTok: ValueHat")

-- Slime ESP 開關 (含引導線)
HubWindow:CreateToggle("Slime ESP", false, function(on)
    slimeEspEnabled = on
    if on then
        print("[Slime ESP] 已開啟")
        startSlimeESP()
    else
        print("[Slime ESP] 已關閉")
        removeSlimeESP()
    end
end)

-- TP Slime 按鈕 (純傳送)
HubWindow:CreateButton("TP Slime", function()
    tpNextSlime()
end)

print("[ValueHat] Slime ESP & TP Slime script loaded successfully!")
