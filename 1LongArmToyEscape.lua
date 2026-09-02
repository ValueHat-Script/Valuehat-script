-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("+1 Long arm toy escape", "TikTok: ValueHat")

--------------------------------------------------
-- 服務與變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local autoWinEnabled = false
local autoTrainEnabled = false

local autoWinThread = nil
local autoTrainThread = nil

--------------------------------------------------
-- 功能邏輯 (Auto Win & Auto Train)
--------------------------------------------------

-- 1. Auto Win 邏輯
local function startAutoWin()
    if autoWinThread then
        task.cancel(autoWinThread)
        autoWinThread = nil
    end

    autoWinThread = task.spawn(function()
        while autoWinEnabled do
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local target = workspace:FindFirstChild("Generated")
                        and workspace.Generated:FindFirstChild("Progression")
                        and workspace.Generated.Progression:FindFirstChild("WinBoxes")
                        and workspace.Generated.Progression.WinBoxes:FindFirstChild("WinBoxNormal_Stage11")
                        and workspace.Generated.Progression.WinBoxes.WinBoxNormal_Stage11:FindFirstChild("Win")

                    if target then
                        if target:IsA("BasePart") then
                            char.HumanoidRootPart.CFrame = target.CFrame
                        elseif target:IsA("Model") then
                            char.HumanoidRootPart.CFrame = target:GetPivot()
                        end
                    end
                end
            end)
            task.wait(0.5) -- 防止崩潰與頻繁傳送
        end
    end)
end

-- 2. Auto Train 邏輯
local function startAutoTrain()
    if autoTrainThread then
        task.cancel(autoTrainThread)
        autoTrainThread = nil
    end

    autoTrainThread = task.spawn(function()
        local event = ReplicatedStorage:WaitForChild("RuntimeRemoteEvents", 5)
            and ReplicatedStorage.RuntimeRemoteEvents:WaitForChild("LongEarningIntentEvent", 5)

        while autoTrainEnabled do
            if event then
                pcall(function()
                    event:FireServer(true)
                end)
            end
            task.wait() -- 對應 while wait() do
        end
    end)
end

--------------------------------------------------
-- UI 控制項選單
--------------------------------------------------

-- Auto Win Toggle
Hub:CreateToggle("Win Farm", false, function(isOn)
    autoWinEnabled = isOn
    if isOn then
        startAutoWin()
    else
        if autoWinThread then
            task.cancel(autoWinThread)
            autoWinThread = nil
        end
    end
end)

-- Auto Train Toggle
Hub:CreateToggle("Auto Train", false, function(isOn)
    autoTrainEnabled = isOn
    if isOn then
        startAutoTrain()
    else
        if autoTrainThread then
            task.cancel(autoTrainThread)
            autoTrainThread = nil
        end
    end
end)
