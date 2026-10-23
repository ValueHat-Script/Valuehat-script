-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local autoButtonEnabled = false
local collectCoinEnabled = false
local autoBuyStickerEnabled = false

-- ==================== 尋找玩家的 Tycoon 邏輯 ====================
local function getMyTycoon()
    local accountName = LocalPlayer.Name:lower()
    local displayName = LocalPlayer.DisplayName:lower()

    -- 遍歷 Tycoon1 到 Tycoon9
    for i = 1, 9 do
        local tycoon = Workspace:FindFirstChild("Tycoon" .. i)
        if tycoon then
            local owner = tycoon:FindFirstChild("Owner")
            if owner and owner:IsA("ObjectValue") and owner.Value then
                local ownerName = owner.Value.Name:lower()
                if ownerName == accountName or ownerName == displayName then
                    print("[Tycoon] 找到玩家的 Tycoon:", tycoon.Name)
                    return tycoon
                end
            end
        end
    end

    -- 備用方案：如果 Owner 是 StringValue 的情況
    for i = 1, 9 do
        local tycoon = Workspace:FindFirstChild("Tycoon" .. i)
        if tycoon then
            local owner = tycoon:FindFirstChild("Owner")
            if owner and owner:IsA("StringValue") then
                local ownerName = owner.Value:lower()
                if ownerName == accountName or ownerName == displayName then
                    print("[Tycoon] 找到玩家的 Tycoon (String):", tycoon.Name)
                    return tycoon
                end
            end
        end
    end

    warn("[Tycoon] 找不到屬於自己的 Tycoon")
    return nil
end

-- ==================== Auto Button 邏輯 ====================
task.spawn(function()
    while true do
        if autoButtonEnabled then
            pcall(function()
                local myTycoon = getMyTycoon()
                if myTycoon then
                    local halloweenPlot = myTycoon:FindFirstChild("HalloweenPlot")
                    if halloweenPlot then
                        local buttonsFolder = halloweenPlot:FindFirstChild("Buttons")
                        if buttonsFolder then
                            for _, folder in ipairs(buttonsFolder:GetChildren()) do
                                if folder:IsA("Folder") then
                                    for _, model in ipairs(folder:GetChildren()) do
                                        if model:IsA("Model") then
                                            local buttonPart = model:FindFirstChild("Button")
                                            if buttonPart and buttonPart:IsA("BasePart") then
                                                local character = LocalPlayer.Character
                                                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                                                if hrp then
                                                    firetouchinterest(hrp, buttonPart, 0)
                                                    task.wait()
                                                    firetouchinterest(hrp, buttonPart, 1)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ==================== Collect Coin 邏輯 ====================
task.spawn(function()
    while true do
        if collectCoinEnabled then
            pcall(function()
                local drops = Workspace:FindFirstChild("Drops")
                if drops then
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if hrp then
                        for _, child in ipairs(drops:GetChildren()) do
                            if not collectCoinEnabled then break end
                            if child:IsA("BasePart") then
                                hrp.CFrame = child.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==================== Auto Buy Sticker Pack 邏輯 ====================
task.spawn(function()
    while true do
        if autoBuyStickerEnabled then
            pcall(function()
                local stickerEvent = ReplicatedStorage:FindFirstChild("Core") 
                    and ReplicatedStorage.Core:FindFirstChild("RemoteRequest") 
                    and ReplicatedStorage.Core.RemoteRequest:FindFirstChild("PlayerStickers.PurchasePack")
                
                if stickerEvent then
                    stickerEvent:InvokeServer("Halloween2026", "Common")
                end
            end)
        end
        task.wait(1) -- 每 1 秒自動購買一次貼紙包
    end
end)

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] Sell Lemon", "TikTok: ValueHat")

Hub:CreateToggle("Auto Button", false, function(on)
    autoButtonEnabled = on
    if on then
        print("[Auto Button] 已開啟")
    else
        print("[Auto Button] 已關閉")
    end
end)

Hub:CreateToggle("Collect Coin", false, function(on)
    collectCoinEnabled = on
    if on then
        print("[Collect Coin] 已開啟")
    else
        print("[Collect Coin] 已關閉")
    end
end)

Hub:CreateToggle("Auto Buy Sticker Pack", false, function(on)
    autoBuyStickerEnabled = on
    if on then
        print("[Auto Buy Sticker Pack] 已開啟")
    else
        print("[Auto Buy Sticker Pack] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
