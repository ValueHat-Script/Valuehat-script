-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Throw a Seed")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local x2TrainEnabled = false
local equipBestEnabled = false

-- 強化版模擬滑鼠點擊（點擊螢幕正中央 + 確保按住時間足夠讓遊戲偵測）
local function simulateClick()
    local camera = workspace.CurrentCamera
    local centerX = camera and (camera.ViewportSize.X / 2) or 500
    local centerY = camera and (camera.ViewportSize.Y / 2) or 500

    -- 優先使用 VirtualInputManager 點擊螢幕正中央（避開 UI 遮擋）
    local vimSuccess = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait(0.08) -- 確保按住 0.08 秒讓遊戲影格穩定捕捉
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    end)

    -- 若 VirtualInputManager 無法使用，則退回執行器內建函數或 VirtualUser
    if not vimSuccess then
        if mouse1press and mouse1release then
            mouse1press()
            task.wait(0.08)
            mouse1release()
        elseif mouse1click then
            mouse1click()
        else
            VirtualUser:Button1Down(Vector2.new(centerX, centerY))
            task.wait(0.08)
            VirtualUser:Button1Up(Vector2.new(centerX, centerY))
        end
    end
end

-- 1. Best Throw 單次執行功能
local function executeBestThrow()
    task.spawn(function()
        local success, err = pcall(function()
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                error("找不到角色的 HumanoidRootPart")
            end

            local launchStrip = workspace.Map.Canyon.LaunchStrip
            local targetCFrame
            if launchStrip:IsA("BasePart") then
                targetCFrame = launchStrip.CFrame
            elseif launchStrip:IsA("Model") then
                targetCFrame = launchStrip:GetPivot()
            else
                error("LaunchStrip 不是可傳送的物件類型")
            end

            -- 1. 傳送到 LaunchStrip 上方
            rootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)

            -- 2. 第一次點擊：等待 0.9 秒
            task.wait(0.9)
            simulateClick()

            -- 3. 第二次點擊：等待 1.5 秒
            task.wait(2.82)
            simulateClick()
        end)
        
        if success then
            print("[Best Throw] 執行成功（已完成兩次強化點擊）！")
        else
            warn("[Best Throw] 執行發生錯誤:", err)
        end
    end)
end

-- 2. Equip Best
local function doEquipBest()
    pcall(function()
        local event = ReplicatedStorage.Remotes.Request
        event:InvokeServer("PlaceBest", {})
    end)
end

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            doEquipBest()
            task.wait(1)
        end
    end)
end

-- 3. x2 Train
local function doX2Train()
    pcall(function()
        local offer = LocalPlayer.PlayerGui:FindFirstChild("XPBoostHud")
        offer = offer and offer:FindFirstChild("XPOffer")

        if offer then
            pcall(firesignal, offer.Activated)
        end
    end)
end

local function startX2Train()
    task.spawn(function()
        while x2TrainEnabled do
            doX2Train()
            task.wait(1)
        end
    end)
end

-- ==================== UI ====================
-- Best Throw 按鈕
UI:Button("BestThrowButton", "Best Throw", function()
    executeBestThrow()
end)

-- Equip Best 開關
UI:Toggle("EquipBestToggle", "Equip Best", function(enabled)
    equipBestEnabled = enabled
    if enabled then
        startEquipBest()
        print("[Equip Best] 已開啟")
    else
        print("[Equip Best] 已關閉")
    end
end)

-- x2 Train 開關
UI:Toggle("X2TrainToggle", "x2 Train", function(enabled)
    x2TrainEnabled = enabled
    if enabled then
        startX2Train()
        print("[x2 Train] 已開啟")
    else
        print("[x2 Train] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
