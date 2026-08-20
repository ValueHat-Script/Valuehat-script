-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui2.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Become a Billionaire", "TikTok: ValueHat")

--------------------------------------------------
-- 變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoFireTouchEnabled = false

--------------------------------------------------
-- 超低負載全圖 Fire Touch (極致分流)
--------------------------------------------------
task.spawn(function()
    while true do
        if AutoFireTouchEnabled then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")

                if hrp then
                    local count = 0
                    for _, descendant in ipairs(Workspace:GetDescendants()) do
                        if not AutoFireTouchEnabled then break end

                        if descendant:IsA("TouchTransmitter") then
                            local parentPart = descendant.Parent
                            if parentPart and parentPart:IsA("BasePart") then
                                firetouchinterest(hrp, parentPart, 0)
                                firetouchinterest(hrp, parentPart, 1)

                                count = count + 1
                                -- 關鍵：每觸發 1 個就暫停 1 幀，保證 100% 不卡頓
                                if count % 1 == 0 then
                                    task.wait()
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1) -- 一輪結束後休息 1 秒
    end
end)

--------------------------------------------------
-- UI 控制項
--------------------------------------------------

Hub:CreateToggle("Auto Collect Money", false, function(isOn)
    AutoFireTouchEnabled = isOn
end)
