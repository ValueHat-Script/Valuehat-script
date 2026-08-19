-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui2.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("+1 Web Swing Escape", "TikTok: ValueHat")

--------------------------------------------------
-- 變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local AutoXpEnabled = false
local WinFarmEnabled = false
local AutoRebirthEnabled = false

local WinFarmCFrame = CFrame.new(13137, 257, 657) -- Win Farm 指定座標

--------------------------------------------------
-- Auto XP 刷經驗值邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if AutoXpEnabled then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("JumpXpEvent") then
                    remotes.JumpXpEvent:FireServer()
                end
            end)
        end
        task.wait()
    end
end)

--------------------------------------------------
-- Win Farm 自動傳送邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if WinFarmEnabled then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    hrp.CFrame = WinFarmCFrame
                end
            end)
        end
        task.wait(0.3)
    end
end)

--------------------------------------------------
-- Auto Rebirth 自動轉生邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if AutoRebirthEnabled then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("RebirthButtonEvent") then
                    remotes.RebirthButtonEvent:FireServer()
                end
            end)
        end
        task.wait(1) -- 每 1 秒檢測/觸發一次轉生，避免請求過度頻繁
    end
end)

--------------------------------------------------
-- UI 控制項
--------------------------------------------------

-- 1. Auto XP 開關
Hub:CreateToggle("Auto XP", false, function(isOn)
    AutoXpEnabled = isOn
end)

-- 2. Win Farm 開關
Hub:CreateToggle("Win Farm", false, function(isOn)
    WinFarmEnabled = isOn
end)

-- 3. Auto Rebirth 開關
Hub:CreateToggle("Auto Rebirth", false, function(isOn)
    AutoRebirthEnabled = isOn
end)
