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

local collectCandyEnabled = false

-- 傳送函數
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

-- 觸發 Part 內部的 ProximityPrompt
local function triggerPromptsInPart(part)
    for _, descendant in ipairs(part:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            pcall(function()
                descendant.HoldDuration = 0
                descendant.MaxActivationDistance = 32
                fireproximityprompt(descendant)
            end)
        elseif descendant:IsA("Attachment") then
            for _, child in ipairs(descendant:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    pcall(function()
                        child.HoldDuration = 0
                        child.MaxActivationDistance = 32
                        fireproximityprompt(child)
                    end)
                end
            end
        end
    end
end

-- ==================== Collect Candy 主迴圈 ====================
local function startCollectCandy()
    task.spawn(function()
        while collectCandyEnabled do
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                local currentMap = Workspace:FindFirstChild("CurrentMap")
                if currentMap then
                    local mapPickups = currentMap:FindFirstChild("MapPickups")
                    if mapPickups then
                        local lowFolder = mapPickups:FindFirstChild("Low")
                        if lowFolder then
                            for _, part in ipairs(lowFolder:GetChildren()) do
                                if not collectCandyEnabled then break end

                                if part:IsA("BasePart") then
                                    -- 檢查 Part 裡面是否有名為 "Candy" 的 Model 或物件
                                    local hasCandy = false
                                    for _, child in ipairs(part:GetChildren()) do
                                        if child.Name == "Candy" then
                                            hasCandy = true
                                            break
                                        end
                                    end

                                    -- 如果有 Candy 模型，則傳送過去並觸發互動
                                    if hasCandy then
                                        teleportTo(part.CFrame + Vector3.new(0, 3, 0))
                                        task.wait(0.2) -- 等待傳送穩定
                                        triggerPromptsInPart(part)
                                        task.wait(0.3) -- 收集緩衝時間
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            task.wait(0.5) -- 掃描間隔
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Duck Duck", "TikTok: ValueHat")

-- 新增 Collect Candy 開關
HubWindow:CreateToggle("Collect Candy", false, function(on)
    collectCandyEnabled = on
    if on then
        print("[Collect Candy] 已開啟")
        startCollectCandy()
    else
        print("[Collect Candy] 已關閉")
    end
end)

print("[ValueHat] Collect Candy script loaded successfully!")
