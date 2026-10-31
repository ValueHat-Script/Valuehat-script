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
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 狀態變數
local candleEspEnabled = false
local espHighlights = {}
local espTracers = {}
local speedValue = 16
local infJumpEnabled = false

-- ==================== 強化版角色傳送函數 ====================
local function teleportMyCharacterTo(cf)
    if not cf then return end

    pcall(function()
        local charactersFolder = Workspace:FindFirstChild("Characters")
        local myName = LocalPlayer.Name
        local myCharModel = (charactersFolder and charactersFolder:FindFirstChild(myName)) or LocalPlayer.Character

        if myCharModel then
            if myCharModel:IsA("Model") then
                myCharModel:PivotTo(cf)
            end

            local root = myCharModel:FindFirstChild("HumanoidRootPart") or myCharModel.PrimaryPart or myCharModel:FindFirstChildWhichIsA("BasePart", true)
            if root then
                root.CFrame = cf
            end

            print("[ValueHat] 成功傳送至目標位置！")
        else
            warn("[ValueHat] 找不到玩家的角色模型: " .. tostring(myName))
        end
    end)
end

-- ==================== 速度控制迴圈 (AssemblyLinearVelocity) ====================
RunService.Heartbeat:Connect(function()
    if speedValue <= 16 then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0 then
        local moveDirection = humanoid.MoveDirection
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(
            moveDirection.X * speedValue,
            velocity.Y,
            moveDirection.Z * speedValue
        )
    end
end)

-- ==================== 無限跳躍 (INF Jump) 邏輯 ====================
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        pcall(function()
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- ==================== 清除 ESP 與連線 ====================
local function clearCandleEsp()
    for obj, hl in pairs(espHighlights) do
        if hl then hl:Destroy() end
    end
    espHighlights = {}

    for obj, line in pairs(espTracers) do
        if line then line:Remove() end
    end
    espTracers = {}
end

-- ==================== Candle ESP 與連線邏輯 ====================
local function startCandleEsp()
    task.spawn(function()
        local targetNames = {
            ["BlueCandle"] = true,
            ["GreenCandle"] = true,
            ["RedCandle"] = true
        }

        while candleEspEnabled do
            -- 清理無效的物件
            for obj, hl in pairs(espHighlights) do
                if not obj or not obj.Parent then
                    if hl then hl:Destroy() end
                    espHighlights[obj] = nil
                    if espTracers[obj] then
                        espTracers[obj]:Remove()
                        espTracers[obj] = nil
                    end
                end
            end

            -- 尋找所有蠟燭
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if targetNames[obj.Name] and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    if candleEspEnabled then
                        -- 1. 建立 3D 框線 (Highlight)
                        if not espHighlights[obj] then
                            local hl = Instance.new("Highlight")
                            hl.Adornee = obj
                            hl.FillColor = Color3.fromRGB(255, 105, 180) -- 粉紅色
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.4
                            hl.Parent = obj
                            espHighlights[obj] = hl
                        end

                        -- 2. 建立連線 (Drawing Line)
                        if not espTracers[obj] then
                            local line = Drawing.new("Line")
                            line.Visible = false
                            line.Color = Color3.fromRGB(255, 105, 180)
                            line.Thickness = 1.5
                            line.Transparency = 0.8
                            espTracers[obj] = line
                        end
                    end
                end
            end

            task.wait(1)
        end
        clearCandleEsp()
    end)

    -- 即時更新連線座標
    RunService.RenderStepped:Connect(function()
        if not candleEspEnabled then return end

        for obj, line in pairs(espTracers) do
            if obj and obj.Parent then
                local targetPart = nil
                if obj:IsA("BasePart") then
                    targetPart = obj
                elseif obj:IsA("Model") then
                    targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                end

                if targetPart then
                    local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(vector.X, vector.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end)
end

-- ==================== TP Back (CandleIdleVFX) 邏輯 ====================
local function tpToCandleIdleVFX()
    pcall(function()
        local targetObj = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "CandleIdleVFX" then
                targetObj = obj
                break
            end
        end

        if targetObj then
            local targetCFrame = nil
            if targetObj:IsA("BasePart") then
                targetCFrame = targetObj.CFrame
            elseif targetObj:IsA("Model") then
                local part = targetObj.PrimaryPart or targetObj:FindFirstChildWhichIsA("BasePart", true)
                targetCFrame = part and part.CFrame or targetObj:GetPivot()
            elseif targetObj:IsA("Attachment") then
                targetCFrame = targetObj.WorldCFrame
            end

            if targetCFrame then
                teleportMyCharacterTo(targetCFrame + Vector3.new(0, 3, 0))
                print("[TP Back] 成功傳送到 CandleIdleVFX！")
            else
                warn("[TP Back] 找到了 CandleIdleVFX 但無法取得有效座標！")
            end
        else
            warn("[TP Back] 在 Workspace 中找不到 CandleIdleVFX！")
        end
    end)
end

-- ==================== TP Boss Arena 邏輯 ====================
local function tpBossArena()
    pcall(function()
        local loadedMap = Workspace:FindFirstChild("LoadedMap")
        if not loadedMap then
            warn("[TP Boss Arena] 找不到 LoadedMap！")
            return
        end

        local bossArena = loadedMap:FindFirstChild("BossArena")
        if not bossArena then
            warn("[TP Boss Arena] 找不到 BossArena！")
            return
        end

        local floor = bossArena:FindFirstChild("Floor")
        if not floor then
            warn("[TP Boss Arena] 找不到 Floor！")
            return
        end

        local targetCFrame = nil
        if floor:IsA("BasePart") then
            targetCFrame = floor.CFrame
        elseif floor:IsA("Model") then
            local part = floor.PrimaryPart or floor:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = part and part.CFrame or floor:GetPivot()
        end

        if targetCFrame then
            teleportMyCharacterTo(targetCFrame + Vector3.new(0, 5, 0))
            print("[TP Boss Arena] 成功傳送到 Boss Arena 地板！")
        else
            warn("[TP Boss Arena] 找不到 Floor 的有效座標！")
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Piggy", "TikTok: ValueHat")

-- Speed 滑桿 (16 ~ 100)
HubWindow:CreateSlider("Speed", 16, 100, 16, function(val)
    speedValue = val
end)

-- INF Jump 開關
HubWindow:CreateToggle("INF Jump", false, function(on)
    infJumpEnabled = on
end)

-- Candle ESP 開關 (帶線)
HubWindow:CreateToggle("Candle ESP", false, function(on)
    candleEspEnabled = on
    if on then
        startCandleEsp()
    else
        clearCandleEsp()
    end
end)

-- TP Back 按鈕
HubWindow:CreateButton("TP Back", function()
    tpToCandleIdleVFX()
end)

-- TP Boss Arena 按鈕
HubWindow:CreateButton("TP Boss Arena", function()
    tpBossArena()
end)

print("[ValueHat] Speed Slider, INF Jump, Candle ESP, TP Back & TP Boss Arena script loaded successfully!")
