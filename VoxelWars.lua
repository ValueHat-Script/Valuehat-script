-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Voxel Wars")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local aimbotEnabled = false
local silentAimEnabled = false
local espEnabled = false
local target = nil
local FOV = 400
local aimbotSmoothness = 0.65 -- 提高 Aimbot 強度與靈敏度 (數值越高跟槍越快越強)
local predictionFactor = 0.125 -- 移動預判係數 (自動提前瞄準移動中的敵人)

-- 安全取得遠端事件與目標群組
local voxel = ReplicatedStorage:WaitForChild("Voxel", 10)
local remotes = voxel and voxel:WaitForChild("Remotes", 10)
local FireRifle = remotes and remotes:WaitForChild("FireRifle", 10)
local BotRigs = Workspace:WaitForChild("BotRigs", 10)

-- 建立 FOV 視覺化圓圈
local fovCircle = nil
if Drawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.ZIndex = 999
        fovCircle.Filled = false
        fovCircle.Thickness = 1
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 0.7
    end)
end

-- 檢查座標是否位於 workspace.SkyLobby 範圍內
local function isInSkyLobby(char)
    local skyLobby = Workspace:FindFirstChild("SkyLobby")
    if not skyLobby then return false end

    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not root then return false end
    local pos = root.Position

    if skyLobby:IsA("BasePart") then
        local rel = skyLobby.CFrame:PointToObjectSpace(pos)
        local half = skyLobby.Size * 0.5
        return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y >= -half.Y and rel.Y <= (half.Y + 30)
    elseif skyLobby:IsA("Model") then
        local cf, size = skyLobby:GetBoundingBox()
        local rel = cf:PointToObjectSpace(pos)
        local half = size * 0.5
        return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y >= -half.Y and rel.Y <= (half.Y + 30)
    else
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        local foundPart = false

        for _, obj in ipairs(skyLobby:GetDescendants()) do
            if obj:IsA("BasePart") then
                foundPart = true
                local p = obj.Position
                local s = obj.Size * 0.5
                minX = math.min(minX, p.X - s.X)
                minY = math.min(minY, p.Y - s.Y)
                minZ = math.min(minZ, p.Z - s.Z)
                maxX = math.max(maxX, p.X + s.X)
                maxY = math.max(maxY, p.Y + s.Y)
                maxZ = math.max(maxZ, p.Z + s.Z)
            end
        end

        if foundPart then
            return pos.X >= minX and pos.X <= maxX
                and pos.Z >= minZ and pos.Z <= maxZ
                and pos.Y >= minY and pos.Y <= (maxY + 30)
        end
    end

    return false
end

-- 判斷是否為有效且可攻擊的目標
local function isValidTarget(char)
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then 
        return false 
    end

    if isInSkyLobby(char) then
        return false
    end

    local plr = Players:GetPlayerFromCharacter(char)
    if plr then
        if plr == LP then return false end
        if LP.Team and plr.Team == LP.Team then return false end
        return true
    end

    if LP.Team then
        local t = char:GetAttribute("Team")
        if t then
            local teamName = typeof(t) == "Instance" and t.Name or tostring(t)
            if teamName == LP.Team.Name then
                return false
            end
        end
    end

    return true
end

-- 牆壁偵測
local function isVisible(targetPart, targetCharacter)
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    
    local origin = cam.CFrame.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LP.Character, targetCharacter}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

-- ==================== Player ESP 管理 ====================
local function clearESPFromChar(char)
    if not char then return end
    local hl = char:FindFirstChild("ValueHat_ESP_Highlight")
    if hl then hl:Destroy() end
    local head = char:FindFirstChild("Head")
    if head then
        local tag = head:FindFirstChild("ValueHat_ESP_Tag")
        if tag then tag:Destroy() end
    end
end

local function clearAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            clearESPFromChar(plr.Character)
        end
    end
end

local function updatePlayerESP()
    if not espEnabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")
            local isEnemy = not (LP.Team and plr.Team == LP.Team)
            local isAlive = hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead

            if isEnemy and isAlive and head then
                local hl = char:FindFirstChild("ValueHat_ESP_Highlight")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ValueHat_ESP_Highlight"
                    hl.FillColor = Color3.fromRGB(255, 60, 60)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.55
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = char
                end

                local tag = head:FindFirstChild("ValueHat_ESP_Tag")
                if not tag then
                    tag = Instance.new("BillboardGui")
                    tag.Name = "ValueHat_ESP_Tag"
                    tag.Size = UDim2.new(0, 140, 0, 32)
                    tag.StudsOffset = Vector3.new(0, 2.5, 0)
                    tag.AlwaysOnTop = true
                    tag.Parent = head

                    local label = Instance.new("TextLabel")
                    label.Name = "InfoLabel"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.TextStrokeTransparency = 0.3
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 13
                    label.Parent = tag
                end

                local label = tag:FindFirstChild("InfoLabel")
                if label then
                    label.Text = string.format("%s [%d]", plr.DisplayName, math.floor(hum.Health))
                end
            else
                clearESPFromChar(char)
            end
        end
    end
end

task.spawn(function()
    while true do
        if espEnabled then
            pcall(updatePlayerESP)
        end
        task.wait(0.25)
    end
end)

-- 每幀更新 FOV 圓圈、尋找目標並處理強化的 Aimbot 跟槍與預判
RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    
    if cam and fovCircle then
        fovCircle.Position = cam.ViewportSize * 0.5
        fovCircle.Radius = FOV
        fovCircle.Visible = aimbotEnabled or silentAimEnabled
    end

    if not aimbotEnabled and not silentAimEnabled then
        target = nil
        return
    end

    if not cam then
        target = nil
        return
    end

    target = nil
    local best = FOV
    local center = cam.ViewportSize * 0.5

    local function check(char)
        if not isValidTarget(char) then return end

        local head = char:FindFirstChild("Head")
        if not head then return end

        if not isVisible(head, char) then return end

        local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < best then
                best = dist
                target = head
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            check(p.Character)
        end
    end

    if BotRigs then
        for _, m in ipairs(BotRigs:GetChildren()) do
            check(m)
        end
    end

    -- 如果開啟了 Aimbot 且找到了目標，套用動態預判與高強度平滑鎖定
    if aimbotEnabled and target then
        local rootPart = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart")
        local predictedPos = target.Position
        
        -- 加入移動預判，自動計算敵人速度提前開槍
        if rootPart then
            predictedPos = predictedPos + (rootPart.AssemblyLinearVelocity * predictionFactor)
        end

        local targetCFrame = CFrame.new(cam.CFrame.Position, predictedPos)
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, aimbotSmoothness)
    end
end)

-- Hook 攻擊遠端事件 (FireRifle) 用於 Silent Aim（同步支援預判）
if FireRifle then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()

        if not checkcaller() and silentAimEnabled and self == FireRifle and method == "FireServer" then
            local args = {...}

            if target and args[1] then
                local rootPart = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart")
                local predictedPos = target.Position
                if rootPart then
                    predictedPos = predictedPos + (rootPart.AssemblyLinearVelocity * predictionFactor)
                end
                args[2] = (predictedPos - args[1]).Unit
            end

            setnamecallmethod("FireServer")
            return old(self, table.unpack(args))
        end

        return old(self, ...)
    end)
else
    warn("[Combat] 找不到 FireRifle 遠端事件！")
end

-- ==================== UI ====================
UI:Toggle("AimbotToggle", "Aimbot", function(enabled)
    aimbotEnabled = enabled
    print("[Aimbot]", enabled and "已開啟 (強化模式)" or "已關閉")
end)

UI:Toggle("SilentAimToggle", "Silent Aim", function(enabled)
    silentAimEnabled = enabled
    print("[Silent Aim]", enabled and "已開啟" or "已關閉")
end)

UI:Toggle("ESPToggle", "Player ESP", function(enabled)
    espEnabled = enabled
    if enabled then
        updatePlayerESP()
        print("[Player ESP] 已開啟")
    else
        clearAllESP()
        print("[Player ESP] 已關閉")
    end
end)

UI:Slider("FOVSlider", "FOV", 50, 1000, 400, function(value)
    FOV = value
    if fovCircle then
        fovCircle.Radius = value
    end
    print("[FOV] 目前:", value)
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
