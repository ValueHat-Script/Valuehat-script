-- ==================== ValueHat Gui 5 初始化 ====================
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("Illegal Bikes")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bikeSystem = ReplicatedStorage:WaitForChild("BikeSystem")
local remotesFolder = bikeSystem:WaitForChild("Remotes")
local combatEvent = remotesFolder:WaitForChild("Combat")

local moneyFarmEnabled = false

-- ==================== Money Farm 循環 ====================
local function runMoneyFarm()
    pcall(function()
        combatEvent:FireServer("kill")
    end)
end

task.spawn(function()
    while true do
        if moneyFarmEnabled then
            runMoneyFarm()
            task.wait(0.2)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== UI 設定 ====================
local function onMoneyFarmToggle(enabled)
    moneyFarmEnabled = enabled
    if enabled then
        print("[Money Farm] 已開啟")
    else
        print("[Money Farm] 已關閉")
    end
end

UI:Toggle("MoneyFarmToggle", "Money Farm", onMoneyFarmToggle)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Money Farm script loaded!")
