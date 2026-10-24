-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local aimbotEnabled = false
local aimbotConnection = nil

-- 平滑瞄準設定 (數值越小越平滑，1 為瞬間鎖定)
local AIM_SMOOTHNESS = 1

-- ==================== 尋找世界距離最近的玩家頭部 ====================
local function getClosestPlayerHead()
    local closestHead = nil
    local shortestDistance = math.huge

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            local targetRoot = character:FindFirstChild("HumanoidRootPart")

            -- 確保目標存活且頭部與 RootPart 存在
            if humanoid and humanoid.Health > 0 and head and targetRoot then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    -- 計算世界座標的距離（與玩家角色的真實距離）
                    local distance = (myRoot.Position - targetRoot.Position).Magnitude

                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestHead = head
                    end
                end
            end
        end
    end

    return closestHead
end

-- ==================== Aimbot 主迴圈 (鏡頭 + 角色轉向) ====================
local function setAimbot(enabled)
    if enabled then
        if not aimbotConnection then
            aimbotConnection = RunService.RenderStepped:Connect(function()
                if not aimbotEnabled then return end
                
                local targetHead = getClosestPlayerHead()
                if targetHead then
                    local myCharacter = LocalPlayer.Character
                    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

                    -- 1. 更新鏡頭角度 (Camera)
                    local cameraTargetCFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(cameraTargetCFrame, AIM_SMOOTHNESS)

                    -- 2. 同步更新角色身體轉向 (Character HumanoidRootPart)
                    if myRoot then
                        local lookAtPos = Vector3.new(targetHead.Position.X, myRoot.Position.Y, targetHead.Position.Z)
                        local rootTargetCFrame = CFrame.new(myRoot.Position, lookAtPos)
                        myRoot.CFrame = myRoot.CFrame:Lerp(rootTargetCFrame, AIM_SMOOTHNESS)
                    end
                end
            end)
        end
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

-- ==================== UI 介面設定 ====================
local Hub = UIModule.CreateWindow("[Hollow] Murder Duels", "TikTok: ValueHat")

-- 新增 Aimbot 開關
Hub:CreateToggle("Aimbot", false, function(on)
    aimbotEnabled = on
    setAimbot(on)
    if on then
        print("[Aimbot] 已開啟")
    else
        print("[Aimbot] 已關閉")
    end
end)

print("[ValueHat] Aimbot with Character Rotation loaded successfully!")
