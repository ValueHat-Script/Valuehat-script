-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Hit a Golf Ball", "TikTok: ValueHat")

-- 變數設定
local moneyFarmEnabled = false
local autoBestHitEnabled = false
local autoRebirthEnabled = false

-- UI 開關：Money Farm
Hub:CreateToggle("Money Farm", false, function(isOn)
    moneyFarmEnabled = isOn
end)

-- UI 開關：Auto Best Hit
Hub:CreateToggle("Auto Best Hit", false, function(isOn)
    autoBestHitEnabled = isOn
end)

-- UI 開關：Auto Rebirth
Hub:CreateToggle("Auto Rebirth", false, function(isOn)
    autoRebirthEnabled = isOn
end)

-- Money Farm 邏輯：Swing 迴圈
task.spawn(function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    while true do
        task.wait()
        if moneyFarmEnabled then
            local golfRemotes = replicatedStorage:FindFirstChild("GolfRemotes")
            local swingEvent = golfRemotes and golfRemotes:FindFirstChild("Swing")
            if swingEvent then
                pcall(function()
                    swingEvent:FireServer(1)
                end)
            end
        end
    end
end)

-- Money Farm 邏輯：StopShot 迴圈
task.spawn(function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    while true do
        task.wait()
        if moneyFarmEnabled then
            local golfRemotes = replicatedStorage:FindFirstChild("GolfRemotes")
            local stopShotEvent = golfRemotes and golfRemotes:FindFirstChild("StopShot")
            if stopShotEvent then
                pcall(function()
                    stopShotEvent:FireServer()
                end)
            end
        end
    end
end)

-- Auto Best Hit 邏輯：Swing 迴圈
task.spawn(function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    while true do
        task.wait()
        if autoBestHitEnabled then
            local golfRemotes = replicatedStorage:FindFirstChild("GolfRemotes")
            local swingEvent = golfRemotes and golfRemotes:FindFirstChild("Swing")
            if swingEvent then
                pcall(function()
                    swingEvent:FireServer(1)
                end)
            end
        end
    end
end)

-- Auto Rebirth 邏輯：DoRebirth 迴圈
task.spawn(function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    while true do
        task.wait(0.5) -- 每 0.5 秒發送一次轉生，可視需要調整間隔
        if autoRebirthEnabled then
            local golfRemotes = replicatedStorage:FindFirstChild("GolfRemotes")
            local rebirthEvent = golfRemotes and golfRemotes:FindFirstChild("DoRebirth")
            if rebirthEvent then
                pcall(function()
                    rebirthEvent:FireServer()
                end)
            end
        end
    end
end)
