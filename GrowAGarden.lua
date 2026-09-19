-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("[20] Grow a Garden", "TikTok: ValueHat")

-- 服務與玩家設定
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 變數設定
local autoGivePlantsEnabled = false

-- UI 開關：Auto Give Plants
Hub:CreateToggle("Auto Give Plants", false, function(isOn)
    autoGivePlantsEnabled = isOn
    print("[Auto Give Plants] 開關狀態: " .. tostring(isOn))
end)

-- 自動提交植物主邏輯 (GiveAll Event)
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    while true do
        task.wait(0.1)
        if autoGivePlantsEnabled then
            pcall(function()
                local anniversaryFolder = ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("Anniversary20th")
                local giveAllEvent = anniversaryFolder and anniversaryFolder:FindFirstChild("GiveAll")
                
                if giveAllEvent and giveAllEvent:IsA("RemoteEvent") then
                    giveAllEvent:FireServer()
                else
                    -- 備用直接存取路徑
                    local directEvent = ReplicatedStorage.GameEvents.Anniversary20th.GiveAll
                    if directEvent then
                        directEvent:FireServer()
                    end
                end
            end)
        end
    end
end)
