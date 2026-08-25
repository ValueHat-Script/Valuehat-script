-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Save Your Cat", "TikTok: ValueHat")

--------------------------------------------------
-- 變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoSeedEnabled = false
local AutoButtonEnabled = false
local TargetSeedCFrame = CFrame.new(-7225, 60, 1607)
local SavedOriginalCFrame = nil -- 用於記錄開啟時的原座標

--------------------------------------------------
-- 輔助函式：從 Model 名稱提取數字
--------------------------------------------------
local function GetModelNumber(name)
    local num = name:match("%d+")
    return num and tonumber(num) or nil
end

--------------------------------------------------
-- Auto Button 核心邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if AutoButtonEnabled then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local tycoonFolder = Workspace:FindFirstChild("TycoonButtons")

                if hrp and tycoonFolder then
                    local buttons = {}

                    for _, model in ipairs(tycoonFolder:GetChildren()) do
                        if not AutoButtonEnabled then break end
                        if model:IsA("Model") then
                            local triggerPart = model:FindFirstChild("TriggerPart")
                            if triggerPart and triggerPart:IsA("BasePart") and triggerPart:FindFirstChildOfClass("TouchTransmitter") then
                                local num = GetModelNumber(model.Name)
                                if num then
                                    table.insert(buttons, { model = model, part = triggerPart, number = num })
                                end
                            end
                        end
                    end

                    table.sort(buttons, function(a, b)
                        return a.number < b.number
                    end)

                    for _, item in ipairs(buttons) do
                        if not AutoButtonEnabled then break end

                        local currentHrP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if currentHrP and item.part and item.part.Parent then
                            currentHrP.CFrame = item.part.CFrame
                            task.wait(0.15)
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

--------------------------------------------------
-- Auto Seed 核心邏輯 (傳送到目的停 1 秒，再傳回來，冷卻 2 秒)
--------------------------------------------------
task.spawn(function()
    while true do
        if AutoSeedEnabled then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if hrp and SavedOriginalCFrame then
                    -- 1. 傳送到目的
                    hrp.CFrame = TargetSeedCFrame
                    
                    -- 2. 在目的停留 1 秒（期間若關閉開關則立即中斷）
                    local elapsed = 0
                    while elapsed < 1.0 do
                        if not AutoSeedEnabled then break end
                        task.wait(0.1)
                        elapsed = elapsed + 0.1
                    end

                    -- 3. 傳送回原座標
                    if AutoSeedEnabled and hrp then
                        hrp.CFrame = SavedOriginalCFrame
                    end
                end
            end)
            task.wait(2.0) -- 冷卻時間 2 秒
        else
            task.wait(0.2)
        end
    end
end)

--------------------------------------------------
-- UI 控制項
--------------------------------------------------

-- 1. Auto Seed 開關 (按下時記錄當前座標)
Hub:CreateToggle("Auto Seed", false, function(isOn)
    AutoSeedEnabled = isOn
    if isOn and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            SavedOriginalCFrame = hrp.CFrame -- 記錄開啟開關時的當前座標
        end
    end
end)

-- 2. Auto Button 開關
Hub:CreateToggle("Auto Button", false, function(isOn)
    AutoButtonEnabled = isOn
end)
