-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local autoStageEnabled = false

-- ==================== Auto Stage 邏輯 ====================
task.spawn(function()
    while true do
        if autoStageEnabled then
            pcall(function()
                local zones = Workspace:FindFirstChild("Zones")
                if zones then
                    local stages = zones:FindFirstChild("Stages")
                    if stages then
                        local character = LocalPlayer.Character
                        local hrp = character and character:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            -- 依序尋找 1 到 11 的 Stage Part
                            for i = 1, 11 do
                                if not autoStageEnabled then break end
                                
                                local stagePart = stages:FindFirstChild(tostring(i))
                                if stagePart and stagePart:IsA("BasePart") then
                                    -- 傳送到該 Stage 的位置上方
                                    hrp.CFrame = stagePart.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(1) -- 在每個 Stage 停留 1 秒（可依需求自行調整秒數）
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

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] +1 Speed keyboard Escape", "TikTok: ValueHat")

Hub:CreateToggle("Auto Stage", false, function(on)
    autoStageEnabled = on
    if on then
        print("[Auto Stage] 已開啟 (依序傳送 1~11)")
    else
        print("[Auto Stage] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
