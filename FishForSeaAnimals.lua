-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Fish For Sea Animals")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local autoFish = false
local autoEquipBest = false
local autoTrainBonus = false
local autoUpgradeBarbell = false
local autoUpgradeBase = false
local autoRebirth = false

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local castRemote = remotesFolder:WaitForChild("Cast")
local landRemote = remotesFolder:WaitForChild("Land")
local equipBestRemote = remotesFolder:WaitForChild("EquipBest")
local upgradeBarbellRemote = remotesFolder:WaitForChild("UpgradeBarbell")
local upgradePenRemote = remotesFolder:WaitForChild("UpgradePen")
local sellAllRemote = remotesFolder:WaitForChild("SellAll")
local rebirthRemote = remotesFolder:WaitForChild("Rebirth")

local function getBoostBubble()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    local boostGui = playerGui:FindFirstChild("BoostGui")
    local spot = boostGui and boostGui:FindFirstChild("Spot")
    return spot and spot:FindFirstChild("Bubble")
end

local function triggerTrainBonus()
    local bubble = getBoostBubble()
    if not bubble then return end

    if bubble:IsA("GuiButton") then
        if not bubble.Visible then return end

        if typeof(firesignal) == "function" then
            pcall(function()
                firesignal(bubble.MouseButton1Click)
            end)
            pcall(function()
                firesignal(bubble.Activated)
            end)
            return
        end

        local fired = false
        if typeof(getconnections) == "function" then
            for _, conn in ipairs(getconnections(bubble.MouseButton1Click)) do
                if conn.Fire then
                    conn:Fire()
                    fired = true
                end
            end
            for _, conn in ipairs(getconnections(bubble.Activated)) do
                if conn.Fire then
                    conn:Fire()
                    fired = true
                end
            end
        end

        if not fired and VirtualInputManager then
            local pos = bubble.AbsolutePosition
            local size = bubble.AbsoluteSize
            local x = pos.X + size.X * 0.5
            local y = pos.Y + size.Y * 0.5
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end
    elseif bubble:IsA("BindableEvent") then
        bubble:Fire()
    elseif bubble:IsA("RemoteEvent") then
        bubble:FireServer()
    end
end

-- ==================== Auto Fish: Cast 迴圈 ====================
task.spawn(function()
    while true do
        if autoFish then
            pcall(function()
                castRemote:InvokeServer(0.98384517454542264)
            end)
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Auto Fish: Land 迴圈 ====================
task.spawn(function()
    while true do
        if autoFish then
            pcall(function()
                landRemote:InvokeServer(true)
            end)
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Equip Best 循環 ====================
task.spawn(function()
    while true do
        if autoEquipBest and equipBestRemote then
            pcall(function()
                equipBestRemote:FireServer()
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Train Bonus 循環 ====================
task.spawn(function()
    while true do
        if autoTrainBonus then
            pcall(triggerTrainBonus)
            task.wait(0.2)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Upgrade Barbell 循環 ====================
task.spawn(function()
    while true do
        if autoUpgradeBarbell and upgradeBarbellRemote then
            pcall(function()
                upgradeBarbellRemote:FireServer()
            end)
            task.wait(0.3)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Upgrade Base 循環 ====================
task.spawn(function()
    while true do
        if autoUpgradeBase and upgradePenRemote then
            pcall(function()
                upgradePenRemote:FireServer()
            end)
            task.wait(0.3)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Auto Rebirth 循環 ====================
task.spawn(function()
    while true do
        if autoRebirth and rebirthRemote then
            pcall(function()
                rebirthRemote:FireServer()
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== UI ====================
UI:Toggle("AutoFishToggle", "Auto Fish", function(enabled)
    autoFish = enabled
    if enabled then
        print("[Auto Fish] 已開啟")
    else
        print("[Auto Fish] 已關閉")
    end
end)

UI:Toggle("EquipBestToggle", "Equip Best", function(enabled)
    autoEquipBest = enabled
    if enabled then
        print("[Equip Best] 已開啟循環")
    else
        print("[Equip Best] 已關閉循環")
    end
end)

UI:Toggle("TrainBonusToggle", "Train Bonus", function(enabled)
    autoTrainBonus = enabled
    if enabled then
        print("[Train Bonus] 已開啟")
    else
        print("[Train Bonus] 已關閉")
    end
end)

UI:Toggle("UpgradeBarbellToggle", "Upgrade Barbell", function(enabled)
    autoUpgradeBarbell = enabled
    if enabled then
        print("[Upgrade Barbell] 已開啟")
    else
        print("[Upgrade Barbell] 已關閉")
    end
end)

UI:Toggle("UpgradeBaseToggle", "Upgrade Base", function(enabled)
    autoUpgradeBase = enabled
    if enabled then
        print("[Upgrade Base] 已開啟")
    else
        print("[Upgrade Base] 已關閉")
    end
end)

UI:Toggle("AutoRebirthToggle", "Auto Rebirth", function(enabled)
    autoRebirth = enabled
    if enabled then
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

UI:Button("SellAllBtn", "Sell All", function()
    if sellAllRemote then
        pcall(function()
            sellAllRemote:FireServer()
            print("[Sell All] 已執行 SellAll")
        end)
    else
        warn("[Sell All] 找不到 ReplicatedStorage.Remotes.SellAll！")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Auto Fish loaded!")
