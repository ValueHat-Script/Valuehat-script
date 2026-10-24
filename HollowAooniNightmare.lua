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

local collectPumpkinEnabled = false

-- 觸發周圍指定距離（預設 5 格）內的 ProximityPrompt
local function firePromptsInRadius(position, radius)
    radius = radius or 5
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            local parent = descendant.Parent
            if parent and parent:IsA("BasePart") then
                local distance = (parent.Position - position).Magnitude
                if distance <= radius then
                    fireproximityprompt(descendant)
                end
            end
        end
    end
end

-- ==================== Collect Pumpkin 邏輯 ====================
task.spawn(function()
    while true do
        if collectPumpkinEnabled then
            pcall(function()
                local school = Workspace:FindFirstChild("School")
                if school then
                    local christmasItem = school:FindFirstChild("ChristmasItem")
                    if christmasItem then
                        local character = LocalPlayer.Character
                        local hrp = character and character:FindFirstChild("HumanoidRootPart")

                        if hrp then
                            for _, child in ipairs(christmasItem:GetChildren()) do
                                if not collectPumpkinEnabled then break end

                                if child:IsA("Model") then
                                    -- 取得 Model 的位置（原點或 PrimaryPart）
                                    local targetPos = child:GetPivot().Position
                                    
                                    -- 1. 傳送角色到 Model 位置（稍微往上一點避免卡住）
                                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                                    task.wait(0.1)

                                    -- 2. 觸發周圍 5 格內的 Prompt
                                    firePromptsInRadius(targetPos, 5)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] Aooni Nightmare", "TikTok: ValueHat")

Hub:CreateToggle("Collect Pumpkin", false, function(on)
    collectPumpkinEnabled = on
    if on then
        print("[Collect Pumpkin] 已開啟")
    else
        print("[Collect Pumpkin] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
