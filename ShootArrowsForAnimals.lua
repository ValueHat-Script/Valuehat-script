-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Shoot Arrows For Animals")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local bestThrowEnabled = false
local equipBestEnabled = false
local autoUpgradeEnabled = false
local autoTrainBonusEnabled = false

-- 取得遠端事件
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local shotFolder = remotes and remotes:FindFirstChild("Shot")
local shotStart = shotFolder and shotFolder:FindFirstChild("Start")
local shotComplete = shotFolder and shotFolder:FindFirstChild("Complete")

local plotFolder = remotes and remotes:FindFirstChild("Plot")
local equipBestRemote = plotFolder and plotFolder:FindFirstChild("EquipBest")
local sellAllRemote = plotFolder and plotFolder:FindFirstChild("SellAll")

local trainingFolder = remotes and remotes:FindFirstChild("Training")
local trainingUpgradeRemote = trainingFolder and trainingFolder:FindFirstChild("Upgrade")

-- 觸發 PlayerGui.TrainingGui.Bonus.TapBonus
local function triggerTapBonus()
    local playerGui = LP:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local trainingGui = playerGui:FindFirstChild("TrainingGui")
    if not trainingGui then return end

    local bonusFolder = trainingGui:FindFirstChild("Bonus")
    if not bonusFolder then return end

    local tapBonus = bonusFolder:FindFirstChild("TapBonus")
    if not tapBonus then return end

    if tapBonus:IsA("GuiButton") then
        if not tapBonus.Visible then return end

        local fired = false
        if typeof(getconnections) == "function" then
            for _, conn in ipairs(getconnections(tapBonus.MouseButton1Click)) do
                if conn.Fire then
                    conn:Fire()
                    fired = true
                end
            end
            for _, conn in ipairs(getconnections(tapBonus.Activated)) do
                if conn.Fire then
                    conn:Fire()
                    fired = true
                end
            end
        end

        if not fired and VirtualInputManager then
            local pos = tapBonus.AbsolutePosition
            local size = tapBonus.AbsoluteSize
            local x = pos.X + size.X * 0.5
            local y = pos.Y + size.Y * 0.5
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end
    elseif tapBonus:IsA("BindableEvent") then
        tapBonus:Fire()
    elseif tapBonus:IsA("RemoteEvent") then
        tapBonus:FireServer()
    end
end

-- ==================== Best Throw 迴圈 ====================
task.spawn(function()
    while true do
        if bestThrowEnabled and shotStart and shotComplete then
            pcall(function()
                shotStart:InvokeServer(0.0098407018059532749)
                task.wait(0.1)
                shotComplete:InvokeServer({
                    Skipped = true
                })
            end)
        end
        task.wait(0.2)
    end
end)

-- ==================== Equip Best 迴圈 ====================
task.spawn(function()
    while true do
        if equipBestEnabled and equipBestRemote then
            pcall(function()
                equipBestRemote:InvokeServer()
            end)
        end
        task.wait(0.5)
    end
end)

-- ==================== Auto Upgrade 迴圈 ====================
task.spawn(function()
    while true do
        if autoUpgradeEnabled and trainingUpgradeRemote then
            pcall(function()
                trainingUpgradeRemote:InvokeServer()
            end)
        end
        task.wait(0.25)
    end
end)

-- ==================== Auto Train Bonus 迴圈 ====================
task.spawn(function()
    while true do
        if autoTrainBonusEnabled then
            pcall(triggerTapBonus)
        end
        task.wait(0.15)
    end
end)

-- ==================== UI ====================
UI:Toggle("BestThrowToggle", "Best Throw", function(enabled)
    bestThrowEnabled = enabled
    if enabled then
        print("[Best Throw] 已開啟")
    else
        print("[Best Throw] 已關閉")
    end
end)

UI:Toggle("EquipBestToggle", "Equip Best", function(enabled)
    equipBestEnabled = enabled
    if enabled then
        print("[Equip Best] 已開啟")
    else
        print("[Equip Best] 已關閉")
    end
end)

UI:Toggle("AutoUpgradeToggle", "Auto Upgrade", function(enabled)
    autoUpgradeEnabled = enabled
    if enabled then
        print("[Auto Upgrade] 已開啟")
    else
        print("[Auto Upgrade] 已關閉")
    end
end)

UI:Toggle("AutoTrainBonusToggle", "Auto Train Bonus", function(enabled)
    autoTrainBonusEnabled = enabled
    if enabled then
        print("[Auto Train Bonus] 已開啟")
    else
        print("[Auto Train Bonus] 已關閉")
    end
end)

UI:Button("SellAllBtn", "Sell All", function()
    if sellAllRemote then
        pcall(function()
            sellAllRemote:InvokeServer()
            print("[Sell All] 已執行全部販售！")
        end)
    else
        warn("[Sell All] 找不到 ReplicatedStorage.Remotes.Plot.SellAll！")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

