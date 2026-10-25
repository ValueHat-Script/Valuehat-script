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
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- 輪播佇列與紀錄
local doorQueue = {}
local currentDoorIndex = 1

-- 記錄原先的 Lighting 設定（用於關閉時還原）
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient
}

-- ==================== Full Bright 邏輯 ====================
local function setFullBright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        -- 還原原本的亮度設定
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.Ambient = originalLighting.Ambient
    end
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

-- ==================== 刷新與取得所有門 ====================
local function refreshDoorQueue()
    local halloweenDoors = Workspace:FindFirstChild("HalloweenDoors")
    if not halloweenDoors then
        warn("[TP Door] 找不到 workspace.HalloweenDoors！")
        return false
    end

    doorQueue = {}
    for _, obj in ipairs(halloweenDoors:GetChildren()) do
        if obj:IsA("Model") then
            table.insert(doorQueue, obj)
        end
    end

    if #doorQueue == 0 then
        warn("[TP Door] HalloweenDoors 裡面沒有找到任何 Model！")
        return false
    end

    currentDoorIndex = 1
    print("[TP Door] 已重置/載入門清單，共 " .. tostring(#doorQueue) .. " 個門")
    return true
end

-- ==================== TP Door (不重複輪播) 邏輯 ====================
local function tpNextDoor()
    if #doorQueue == 0 or currentDoorIndex > #doorQueue then
        local success = refreshDoorQueue()
        if not success then return end
    end

    local currentDoor = doorQueue[currentDoorIndex]

    if currentDoor and currentDoor.Parent then
        local targetPart = currentDoor.PrimaryPart or currentDoor:FindFirstChildWhichIsA("BasePart", true)

        if targetPart then
            teleportTo(targetPart.CFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP Door] [%d/%d] 已傳送到門: %s", currentDoorIndex, #doorQueue, currentDoor.Name))
            currentDoorIndex = currentDoorIndex + 1
        else
            warn("[TP Door] 門 " .. currentDoor.Name .. " 內找不到基準零件，跳過該門")
            currentDoorIndex = currentDoorIndex + 1
            tpNextDoor()
        end
    else
        currentDoorIndex = currentDoorIndex + 1
        tpNextDoor()
    end
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Hunted", "TikTok: ValueHat")

-- 新增 TP Door 按鈕
HubWindow:CreateButton("TP Door", function()
    tpNextDoor()
end)

-- 新增 Full Bright 開關
HubWindow:CreateToggle("Full Bright", false, function(on)
    setFullBright(on)
    if on then
        print("[Full Bright] 已開啟")
    else
        print("[Full Bright] 已關閉")
    end
end)

print("[ValueHat] TP Door & Full Bright script loaded successfully!")
