-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Speed", "TikTok: ValueHat")

--------------------------------------------------
-- 服務與變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local autoMoneyEnabled = false
local antiAfkEnabled = false
local infGumAndMoneyEnabled = false

--------------------------------------------------
-- 核心邏輯實現
--------------------------------------------------

-- Auto Collect Money 迴圈邏輯
task.spawn(function()
    while true do
        if autoMoneyEnabled then
            pcall(function()
                -- 修改 PrivateStats 與技能數值
                for _, player in ipairs(Players:GetPlayers()) do
                    local privateStats = player:FindFirstChild("PrivateStats")
                    if privateStats then
                        for _, item in ipairs(privateStats:GetChildren()) do 
                            if item:IsA("IntValue") then item.Value = 100 end 
                        end
                        local skills = privateStats:FindFirstChild("SkillUpgrades")
                        if skills then 
                            for _, s in ipairs(skills:GetChildren()) do 
                                if s:IsA("IntValue") then s.Value = 100 end 
                            end 
                        end
                    end
                end
                
                -- 觸發遠端事件
                local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if Remotes then
                    if Remotes:FindFirstChild("CollectPaper") then 
                        Remotes.CollectPaper:FireServer() 
                    end
                    if Remotes:FindFirstChild("CollectTrashBag") then 
                        Remotes.CollectTrashBag:FireServer() 
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- Inf Gum and Money 迴圈邏輯
task.spawn(function()
    while true do
        if infGumAndMoneyEnabled then
            pcall(function()
                local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if Remotes and Remotes:FindFirstChild("CollectTrashBag") then
                    Remotes.CollectTrashBag:FireServer(math.huge, 962944000000000000000)
                end
            end)
        end
        task.wait(0)
    end
end)

-- Anti-AFK 防掛機邏輯
LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

--------------------------------------------------
-- ValueHat UI 按鈕綁定
--------------------------------------------------

Hub:CreateToggle("Auto Collect: Money", false, function(isOn)
    autoMoneyEnabled = isOn
end)

Hub:CreateToggle("Inf Gum and Money", false, function(isOn)
    infGumAndMoneyEnabled = isOn
end)

Hub:CreateToggle("Anti-AFK", false, function(isOn)
    antiAfkEnabled = isOn
end)
