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

-- Noclip 狀態
local noclipEnabled = false

-- 輪播佇列與紀錄
local keyQueue = {}
local currentKeyIndex = 1

local boxQueue = {}
local currentBoxIndex = 1

local paperQueue = {}
local currentPaperIndex = 1

local safeQueue = {}
local currentSafeIndex = 1

local box2Queue = {}
local currentBox2Index = 1

local evilRoomQueue = {}
local currentEvilRoomIndex = 1

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

-- ==================== Noclip 穿牆邏輯 ====================
RunService.Stepped:Connect(function()
    if noclipEnabled then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ==================== 重新整理並取得 Key 清單 ====================
local function refreshKeyQueue()
    keyQueue = {}

    local success = pcall(function()
        local server = Workspace:FindFirstChild("Server")
        if not server then return end
        local spawnedItems = server:FindFirstChild("SpawnedItems")
        if not spawnedItems then return end

        for _, obj in ipairs(spawnedItems:GetChildren()) do
            if obj.Name == "Key" and (obj:IsA("Model") or obj:IsA("BasePart")) then
                table.insert(keyQueue, obj)
            end
        end
    end)

    if not success or #keyQueue == 0 then
        warn("[TP to key] 找不到 workspace.Server.SpawnedItems 或裡面沒有找到任何 Key[span_0](start_span)[span_0](end_span)！")
        return false
    end

    currentKeyIndex = 1
    print("[TP to key] 已重置/載入 Key 清單，共 " .. tostring(#keyQueue) .. " 個")
    return true
end

-- ==================== 重新整理並取得 Box 清單 ====================
local function refreshBoxQueue()
    boxQueue = {}

    local success = pcall(function()
        local server = Workspace:FindFirstChild("Server")
        if not server then return end
        local spawnedItems = server:FindFirstChild("SpawnedItems")
        if not spawnedItems then return end

        for _, obj in ipairs(spawnedItems:GetChildren()) do
            if string.find(obj.Name, "Box") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                table.insert(boxQueue, obj)
            end
        end
    end)

    if not success or #boxQueue == 0 then
        warn("[TP to Box] 找不到 workspace.Server.SpawnedItems 或裡面沒有找到任何 Box[span_1](start_span)[span_1](end_span)！")
        return false
    end

    currentBoxIndex = 1
    print("[TP to Box] 已重置/載入 Box 清單，共 " .. tostring(#boxQueue) .. " 個")
    return true
end

-- ==================== 重新整理並取得 Paper 清單 ====================
local function refreshPaperQueue()
    paperQueue = {}

    local success = pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "HintPaper" and (obj:IsA("BasePart") or obj:IsA("Model")) then
                table.insert(paperQueue, obj)
            end
        end
    end)

    if not success or #paperQueue == 0 then
        warn("[TP to Paper] 找不到任何 HintPaper[span_2](start_span)[span_2](end_span) 物件！")
        return false
    end

    currentPaperIndex = 1
    print("[TP to Paper] 已重置/載入 Paper 清單，共 " .. tostring(#paperQueue) .. " 個")
    return true
end

-- ==================== 重新整理並取得 Safe 清單 ====================
local function refreshSafeQueue()
    safeQueue = {}

    local success = pcall(function()
        local server = Workspace:FindFirstChild("Server")
        if not server then return end
        local mapGenerated = server:FindFirstChild("MapGenerated")
        if not mapGenerated then return end
        local rooms = mapGenerated:FindFirstChild("Rooms")
        if not rooms then return end

        for _, room in ipairs(rooms:GetChildren()) do
            local props = room:FindFirstChild("Props")
            if props then
                for _, prop in ipairs(props:GetChildren()) do
                    if prop.Name == "Safe" and (prop:IsA("Model") or prop:IsA("BasePart")) then
                        table.insert(safeQueue, prop)
                    end
                end
            end
        end
    end)

    if not success or #safeQueue == 0 then
        warn("[TP safe] 找不到任何 Safe 保險箱物件[span_3](start_span)[span_3](end_span)！")
        return false
    end

    currentSafeIndex = 1
    print("[TP safe] 已重置/載入 Safe 清單，共 " .. tostring(#safeQueue) .. " 個")
    return true
end

-- ==================== 重新整理並取得 Box2 清單 ====================
local function refreshBox2Queue()
    box2Queue = {}

    local success = pcall(function()
        local server = Workspace:FindFirstChild("Server")
        if not server then return end
        local spawnedItems = server:FindFirstChild("SpawnedItems")
        if not spawnedItems then return end

        for _, obj in ipairs(spawnedItems:GetChildren()) do
            if obj.Name == "OfudaBox2" and (obj:IsA("Model") or obj:IsA("BasePart")) then
                table.insert(box2Queue, obj)
            end
        end
    end)

    if not success or #box2Queue == 0 then
        warn("[TP to box2] 找不到 workspace.Server.SpawnedItems 或裡面沒有找到任何 OfudaBox2[span_4](start_span)[span_4](end_span)！")
        return false
    end

    currentBox2Index = 1
    print("[TP to box2] 已重置/載入 Box2 清單，共 " .. tostring(#box2Queue) .. " 個")
    return true
end

-- ==================== 重新整理並取得 Evil Room 清單 ====================
local function refreshEvilRoomQueue()
    evilRoomQueue = {}

    local success = pcall(function()
        local server = Workspace:FindFirstChild("Server")
        if not server then return end
        local mapGenerated = server:FindFirstChild("MapGenerated")
        if not mapGenerated then return end
        local rooms = mapGenerated:FindFirstChild("Rooms")
        if not rooms then return end

        for _, room in ipairs(rooms:GetChildren()) do
            local eventArea = room:FindFirstChild("EventArea")
            if eventArea and (eventArea:IsA("Model") or eventArea:IsA("BasePart")) then
                table.insert(evilRoomQueue, eventArea)
            end
        end
    end)

    if not success or #evilRoomQueue == 0 then
        warn("[TP Evil Room] 找不到任何 EventArea 物件！")
        return false
    end

    currentEvilRoomIndex = 1
    print("[TP Evil Room] 已重置/載入 Evil Room 清單，共 " .. tostring(#evilRoomQueue) .. " 個")
    return true
end

-- ==================== TP to key 輪播邏輯 ====================
local function tpNextKey()
    if #keyQueue == 0 or currentKeyIndex > #keyQueue then
        local success = refreshKeyQueue()
        if not success then return end
    end

    local currentKey = keyQueue[currentKeyIndex]

    if currentKey and currentKey.Parent then
        local targetCFrame = nil
        if currentKey:IsA("BasePart") then
            targetCFrame = currentKey.CFrame
        elseif currentKey:IsA("Model") then
            local targetPart = currentKey.PrimaryPart or currentKey:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentKey:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP to key] [%d/%d] 已傳送到 Key: %s", currentKeyIndex, #keyQueue, currentKey.Name))
            currentKeyIndex = currentKeyIndex + 1
        else
            warn("[TP to key] 該 Key 找不到有效座標，跳過")
            currentKeyIndex = currentKeyIndex + 1
            tpNextKey()
        end
    else
        currentKeyIndex = currentKeyIndex + 1
        tpNextKey()
    end
end

-- ==================== TP to Box 輪播邏輯 ====================
local function tpNextBox()
    if #boxQueue == 0 or currentBoxIndex > #boxQueue then
        local success = refreshBoxQueue()
        if not success then return end
    end

    local currentBox = boxQueue[currentBoxIndex]

    if currentBox and currentBox.Parent then
        local targetCFrame = nil
        if currentBox:IsA("BasePart") then
            targetCFrame = currentBox.CFrame
        elseif currentBox:IsA("Model") then
            local targetPart = currentBox.PrimaryPart or currentBox:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentBox:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP to Box] [%d/%d] 已傳送到 Box: %s", currentBoxIndex, #boxQueue, currentBox.Name))
            currentBoxIndex = currentBoxIndex + 1
        else
            warn("[TP to Box] 該 Box 找不到有效座標，跳過")
            currentBoxIndex = currentBoxIndex + 1
            tpNextBox()
        end
    else
        currentBoxIndex = currentBoxIndex + 1
        tpNextBox()
    end
end

-- ==================== TP to Paper 輪播邏輯 ====================
local function tpNextPaper()
    if #paperQueue == 0 or currentPaperIndex > #paperQueue then
        local success = refreshPaperQueue()
        if not success then return end
    end

    local currentPaper = paperQueue[currentPaperIndex]

    if currentPaper and currentPaper.Parent then
        local targetCFrame = nil
        if currentPaper:IsA("BasePart") then
            targetCFrame = currentPaper.CFrame
        elseif currentPaper:IsA("Model") then
            local targetPart = currentPaper.PrimaryPart or currentPaper:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentPaper:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP to Paper] [%d/%d] 已傳送到 Paper: %s", currentPaperIndex, #paperQueue, currentPaper.Name))
            currentPaperIndex = currentPaperIndex + 1
        else
            warn("[TP to Paper] 該 Paper 找不到有效座標，跳過")
            currentPaperIndex = currentPaperIndex + 1
            tpNextPaper()
        end
    else
        currentPaperIndex = currentPaperIndex + 1
        tpNextPaper()
    end
end

-- ==================== TP safe 輪播邏輯 ====================
local function tpNextSafe()
    if #safeQueue == 0 or currentSafeIndex > #safeQueue then
        local success = refreshSafeQueue()
        if not success then return end
    end

    local currentSafe = safeQueue[currentSafeIndex]

    if currentSafe and currentSafe.Parent then
        local targetCFrame = nil
        if currentSafe:IsA("BasePart") then
            targetCFrame = currentSafe.CFrame
        elseif currentSafe:IsA("Model") then
            local targetPart = currentSafe.PrimaryPart or currentSafe:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentSafe:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP safe] [%d/%d] 已傳送到 Safe: %s", currentSafeIndex, #safeQueue, currentSafe.Name))
            currentSafeIndex = currentSafeIndex + 1
        else
            warn("[TP safe] 該 Safe 找不到有效座標，跳過")
            currentSafeIndex = currentSafeIndex + 1
            tpNextSafe()
        end
    else
        currentSafeIndex = currentSafeIndex + 1
        tpNextSafe()
    end
end

-- ==================== TP to box2 輪播邏輯 ====================
local function tpNextBox2()
    if #box2Queue == 0 or currentBox2Index > #box2Queue then
        local success = refreshBox2Queue()
        if not success then return end
    end

    local currentBox2 = box2Queue[currentBox2Index]

    if currentBox2 and currentBox2.Parent then
        local targetCFrame = nil
        if currentBox2:IsA("BasePart") then
            targetCFrame = currentBox2.CFrame
        elseif currentBox2:IsA("Model") then
            local targetPart = currentBox2.PrimaryPart or currentBox2:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentBox2:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP to box2] [%d/%d] 已傳送到 Box2: %s", currentBox2Index, #box2Queue, currentBox2.Name))
            currentBox2Index = currentBox2Index + 1
        else
            warn("[TP to box2] 該 Box2 找不到有效座標，跳過")
            currentBox2Index = currentBox2Index + 1
            tpNextBox2()
        end
    else
        currentBox2Index = currentBox2Index + 1
        tpNextBox2()
    end
end

-- ==================== TP Evil Room 輪播邏輯 ====================
local function tpNextEvilRoom()
    if #evilRoomQueue == 0 or currentEvilRoomIndex > #evilRoomQueue then
        local success = refreshEvilRoomQueue()
        if not success then return end
    end

    local currentArea = evilRoomQueue[currentEvilRoomIndex]

    if currentArea and currentArea.Parent then
        local targetCFrame = nil
        if currentArea:IsA("BasePart") then
            targetCFrame = currentArea.CFrame
        elseif currentArea:IsA("Model") then
            local targetPart = currentArea.PrimaryPart or currentArea:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentArea:GetPivot()
        end

        if targetCFrame then
            teleportTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP Evil Room] [%d/%d] 已傳送到 EventArea: %s", currentEvilRoomIndex, #evilRoomQueue, currentArea.Parent.Name))
            currentEvilRoomIndex = currentEvilRoomIndex + 1
        else
            warn("[TP Evil Room] 該 EventArea 找不到有效座標，跳過")
            currentEvilRoomIndex = currentEvilRoomIndex + 1
            tpNextEvilRoom()
        end
    else
        currentEvilRoomIndex = currentEvilRoomIndex + 1
        tpNextEvilRoom()
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] PETAPETA", "TikTok: ValueHat")

-- Noclip 開關
HubWindow:CreateToggle("Noclip", false, function(on)
    noclipEnabled = on
    if on then
        print("[Noclip] 已開啟")
    else
        print("[Noclip] 已關閉")
    end
end)

-- TP to key 按鈕
HubWindow:CreateButton("TP to key", function()
    tpNextKey()
end)

-- TP to Box 按鈕
HubWindow:CreateButton("TP to Box", function()
    tpNextBox()
end)

-- TP to Paper 按鈕
HubWindow:CreateButton("TP to Paper", function()
    tpNextPaper()
end)

-- TP safe 按鈕
HubWindow:CreateButton("TP safe", function()
    tpNextSafe()
end)

-- TP to box2 按鈕
HubWindow:CreateButton("TP to box2", function()
    tpNextBox2()
end)

-- TP Evil Room 按鈕
HubWindow:CreateButton("TP Evil Room", function()
    tpNextEvilRoom()
end)

print("[ValueHat] Complete Teleport Hub with Noclip script loaded successfully!")
