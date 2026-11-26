-- ==================== ValueHat Gui 5 初始化 ====================
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("Wake Up an Animal")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local submitNoteEvent = remotesFolder:WaitForChild("SubmitNote")
local animalsEvent = remotesFolder:WaitForChild("Animals")
local upgradeTrainerEvent = remotesFolder:WaitForChild("UpgradeTrainer")

local autoAnimalEnabled = false
local equipBestEnabled = false
local autoSpinEnabled = false
local upgradeTrainerEnabled = false

-- ==================== Auto Animal 循環 ====================
local function runAutoAnimal()
    pcall(function()
        submitNoteEvent:InvokeServer(1)
    end)
end

task.spawn(function()
    while true do
        if autoAnimalEnabled then
            runAutoAnimal()
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Equip Best 循環 ====================
local function runEquipBest()
    pcall(function()
        animalsEvent:InvokeServer("placeBest", nil)
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

-- ==================== Auto Spin 邏輯 ====================
local function getSpinTarget()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end
    local trainerBonus = playerGui:FindFirstChild("TrainerBonus", true)
    if not trainerBonus then return nil end
    return trainerBonus:FindFirstChild("Spin", true)
end

local function triggerSpin()
    pcall(function()
        local spinObj = getSpinTarget()
        if not spinObj then return end

        if spinObj:IsA("GuiButton") then
            if firesignal then
                pcall(function() firesignal(spinObj.MouseButton1Click) end)
                pcall(function() firesignal(spinObj.Activated) end)
            end
            if spinObj.Activate then
                pcall(function() spinObj:Activate() end)
            end
        elseif spinObj:IsA("RemoteEvent") then
            spinObj:FireServer()
        elseif spinObj:IsA("RemoteFunction") then
            spinObj:InvokeServer()
        elseif spinObj:IsA("ProximityPrompt") then
            if fireproximityprompt then
                fireproximityprompt(spinObj)
            else
                spinObj:InputHoldBegin()
                task.wait(spinObj.HoldDuration or 0)
                spinObj:InputHoldEnd()
            end
        end
    end)
end

task.spawn(function()
    while true do
        if autoSpinEnabled then
            triggerSpin()
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Upgrade Trainer 循環 ====================
local function runUpgradeTrainer()
    pcall(function()
        upgradeTrainerEvent:InvokeServer()
    end)
end

task.spawn(function()
    while true do
        if upgradeTrainerEnabled then
            runUpgradeTrainer()
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Sell All 邏輯 ====================
local function runSellAll()
    pcall(function()
        animalsEvent:InvokeServer("sellAll", nil)
    end)
    print("[Sell All] 已執行出售全部")
end

-- ==================== UI 設定 ====================
local function onAutoAnimalToggle(enabled)
    autoAnimalEnabled = enabled
    if enabled then
        print("[Auto Animal] 已開啟")
    else
        print("[Auto Animal] 已關閉")
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

local function onAutoSpinToggle(enabled)
    autoSpinEnabled = enabled
    if enabled then
        print("[Auto Spin] 已開啟")
    else
        print("[Auto Spin] 已關閉")
    end
end

local function onUpgradeTrainerToggle(enabled)
    upgradeTrainerEnabled = enabled
    if enabled then
        print("[Upgrade Trainer] 已開啟")
    else
        print("[Upgrade Trainer] 已關閉")
    end
end

UI:Toggle("AutoAnimalToggle", "Auto Animal", onAutoAnimalToggle)
UI:Toggle("EquipBestToggle", "Equip Best", onEquipBestToggle)
UI:Toggle("AutoSpinToggle", "Auto Train Bonus", onAutoSpinToggle)
UI:Toggle("UpgradeTrainerToggle", "Upgrade Trainer", onUpgradeTrainerToggle)
UI:Button("SellAllBtn", "Sell All", runSellAll)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Auto Animal, Equip Best, Auto Spin, Upgrade Trainer & Sell All script loaded!")
