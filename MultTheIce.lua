-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui2.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("🔥Mult The Ice", "TikTok: ValueHat")

--------------------------------------------------
-- 變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoMedalEnabled = false
local AutoSellEnabled = false
local AutoCollectEnabled = false
local TargetCFrame = CFrame.new(-725, 7, 5683)


task.spawn(function()
    while true do
        if AutoMedalEnabled then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    hrp.CFrame = TargetCFrame
                end
            end)
        end
        task.wait(0.3)
    end
end)


task.spawn(function()
    while true do
        if AutoSellEnabled then
            pcall(function()
                local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                if eventsFolder and eventsFolder:FindFirstChild("SellAll") then
                    eventsFolder.SellAll:InvokeServer()
                end
            end)
        end
        task.wait(1)
    end
end)


task.spawn(function()
    while true do
        if AutoCollectEnabled then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local parent = obj.Parent
                            
                            if parent and parent:IsA("BasePart") then
                                if (parent.Position - hrp.Position).Magnitude < 20 then
                                    fireproximityprompt(obj)
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




Hub:CreateToggle("Auto Medal", false, function(isOn)
    AutoMedalEnabled = isOn
end)


Hub:CreateToggle("Auto Sell", false, function(isOn)
    AutoSellEnabled = isOn
end)


Hub:CreateToggle("Auto Collect Item", false, function(isOn)
    AutoCollectEnabled = isOn
end)
