-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 服務
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameHandShake = ReplicatedStorage.Remotes.GameHandShake
local EquipBestAnimals = ReplicatedStorage.Remotes.EquipBestAnimals
local SellAnimal = ReplicatedStorage.Remotes.SellAnimal

-- 變數
local autoPlayEnabled = false
local autoEquipBestEnabled = false
local autoSellEnabled = false

-- 建立主視窗
local Hub = UIModule.CreateWindow("Shuffle an egg", "TikTok: ValueHat")

-- Auto Play Game 邏輯
local function startAutoPlay()
    task.spawn(function()
        while autoPlayEnabled do
            -- 開始洗牌
            GameHandShake:FireServer("StartShuffle")
            task.wait(1.2)

            -- 選擇杯子（固定選第 2 個）
            GameHandShake:FireServer("PickCup", 2)
            -- 想隨機選杯子可改成：
            -- GameHandShake:FireServer("PickCup", math.random(1, 3))

            task.wait(2.5)
        end
    end)
end

-- Auto Equip Best 邏輯
local function startAutoEquipBest()
    task.spawn(function()
        while autoEquipBestEnabled do
            EquipBestAnimals:FireServer()
            task.wait(3)  -- 每 3 秒自動裝備一次最佳動物
        end
    end)
end

-- Auto Sell 邏輯
local function startAutoSell()
    task.spawn(function()
        while autoSellEnabled do
            SellAnimal:FireServer("SellAllAnimals")
            task.wait(5)  -- 每 5 秒自動賣出所有動物（可自行調整）
        end
    end)
end

-- Auto Play Game 開關
Hub:CreateToggle("Auto Play Game", false, function(isOn)
    autoPlayEnabled = isOn
    if autoPlayEnabled then
        startAutoPlay()
    end
end)

-- Auto Equip Best 開關
Hub:CreateToggle("Auto Equip Best", false, function(isOn)
    autoEquipBestEnabled = isOn
    if autoEquipBestEnabled then
        startAutoEquipBest()
    end
end)

-- Auto Sell 開關
Hub:CreateToggle("Auto Sell", false, function(isOn)
    autoSellEnabled = isOn
    if autoSellEnabled then
        startAutoSell()
    end
end)
