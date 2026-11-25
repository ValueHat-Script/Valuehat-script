-- ==================== ValueHat Gui 5 初始化 ====================
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("Cast For Fish")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local castEvent = remotesFolder:WaitForChild("Cast")
local equipBestEvent = remotesFolder:WaitForChild("EquipBest")
local trainBonusEvent = remotesFolder:WaitForChild("TrainBonus")
local buyDumbbellEvent = remotesFolder:WaitForChild("BuyDumbbell")
local sellAllEvent = remotesFolder:WaitForChild("SellAll")

local autoFishEnabled = false
local equipBestEnabled = false
local x2TrainEnabled = false
local upgradeDumbbellEnabled = false

-- ==================== Auto Fish 循環 ====================
local function runAutoFish()
    pcall(function()
        castEvent:InvokeServer(20, false)
    end)
end

task.spawn(function()
    while true do
        if autoFishEnabled then
            runAutoFish()
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Equip Best 循環 ====================
local function runEquipBest()
    pcall(function()
        equipBestEvent:InvokeServer()
    end)
end

task.spawn(function()
    while true do
        if equipBestEnabled then
            runEquipBest()
            task.wait(1)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== x2 Train 循環 ====================
local function runX2Train()
    pcall(function()
        trainBonusEvent:FireServer()
    end)
end

task.spawn(function()
    while true do
        if x2TrainEnabled then
            runX2Train()
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Upgrade Dumbbell 循環 ====================
local function runUpgradeDumbbell()
    pcall(function()
        buyDumbbellEvent:InvokeServer()
    end)
end

task.spawn(function()
    while true do
        if upgradeDumbbellEnabled then
            runUpgradeDumbbell()
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Sell All 邏輯 ====================
local function runSellAll()
    pcall(function()
        sellAllEvent:InvokeServer()
    end)
    print("[Sell All] 已執行出售全部")
end

-- ==================== UI 設定 ====================
local function onAutoFishToggle(enabled)
    autoFishEnabled = enabled
    if enabled then
        print("[Auto Fish] 已開啟")
    else
        print("[Auto Fish] 已關閉")
    end
end

local function onEquipBestToggle(enabled)
    equipBestEnabled = enabled
    if enabled then
        print("[Equip Best] 已開啟")
    else
        print("[Equip Best] 已關閉")
    end
end

local function onX2TrainToggle(enabled)
    x2TrainEnabled = enabled
    if enabled then
        print("[x2 Train] 已開啟")
    else
        print("[x2 Train] 已關閉")
    end
end

local function onUpgradeDumbbellToggle(enabled)
    upgradeDumbbellEnabled = enabled
    if enabled then
        print("[Upgrade Dumbbell] 已開啟")
    else
        print("[Upgrade Dumbbell] 已關閉")
    end
end

UI:Toggle("AutoFishToggle", "Auto Fish", onAutoFishToggle)
UI:Toggle("EquipBestToggle", "Equip Best", onEquipBestToggle)
UI:Toggle("X2TrainToggle", "x2 Train", onX2TrainToggle)
UI:Toggle("UpgradeDumbbellToggle", "Upgrade Dumbbell", onUpgradeDumbbellToggle)
UI:Button("SellAllBtn", "Sell All", runSellAll)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Full Hub script loaded!")
