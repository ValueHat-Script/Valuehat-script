-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("+1 Aura Climb Tower", "TikTok: ValueHat")

--------------------------------------------------
-- 服務與變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local infMoneyEnabled = false
local infWinEnabled = false

-- 取得 Remotes 遠端事件容器
local remotesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes")
local addTrophyEvent = remotesFolder:WaitForChild("AddTrophy")
local addCoachEvent = remotesFolder:WaitForChild("AddCoach")

--------------------------------------------------
-- 1. Inf Money 核心邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if infMoneyEnabled then
            pcall(function()
                if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Money") then
                    LocalPlayer.leaderstats.Money.Value = 99999999999999999999999999999
                end
            end)
        end
        task.wait()
    end
end)

--------------------------------------------------
-- 2. Inf Win 核心邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if infWinEnabled then
            pcall(function()
                addTrophyEvent:FireServer()
            end)
        end
        task.wait()
    end
end)

--------------------------------------------------
-- ValueHat UI 組件綁定
--------------------------------------------------

-- Inf Money 開關
Hub:CreateToggle("Inf Money", false, function(isOn)
    infMoneyEnabled = isOn
end)

-- Inf Win 開關
Hub:CreateToggle("Inf Win", false, function(isOn)
    infWinEnabled = isOn
end)

-- Best Pet 按鈕
Hub:CreateButton("Best Pet", function()
    pcall(function()
        addCoachEvent:FireServer("Duck")
    end)
end)
