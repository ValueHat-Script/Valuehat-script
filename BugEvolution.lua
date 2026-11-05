-- ValueHat Gui 5
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local UI = UIModule.Init("Bug Evolution")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local autoOrbEnabled = false
local killAuraEnabled = false
local espEnabled = false
local speedEnabled = false
local currentSpeed = 50
local speedConnection = nil
local lines = {}

local targetColor = Color3.fromRGB(255, 110, 220)

local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHumanoid()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

local function isTargetColor(color)
    if not color then return false end

    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)

    return math.abs(r - 255) <= 5 and math.abs(g - 110) <= 5 and math.abs(b - 220) <= 5
end

local function getTargetOrbs()
    local orbs = {}
    local orbFolder = Workspace:FindFirstChild("Orbs")
    if not orbFolder then return orbs end

    for _, obj in ipairs(orbFolder:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Orb" then
            if isTargetColor(obj.Color) then
                table.insert(orbs, obj)
            end
        end
    end
    return orbs
end

local function doAttack(target)
    pcall(function()
        local event = ReplicatedStorage.Remotes.Attack
        event:FireServer(target)
    end)
end

local function getWorkspacePlayers()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local model = Workspace:FindFirstChild(player.Name)
            if model and model:IsA("Model") then
                table.insert(list, model)
            end
        end
    end
    return list
end

-- ==================== Speed ====================
local function startSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end

    speedConnection = RunService.Heartbeat:Connect(function()
        if not speedEnabled then return end

        local root = getHRP()
        local humanoid = getHumanoid()
        if not root or not humanoid or humanoid.Health <= 0 then return end

        local moveDirection = humanoid.MoveDirection
        local velocity = root.AssemblyLinearVelocity

        root.AssemblyLinearVelocity = Vector3.new(
            moveDirection.X * currentSpeed,
            velocity.Y,
            moveDirection.Z * currentSpeed
        )
    end)
end

local function stopSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
end

-- ==================== Player ESP (畫線) ====================
local function createLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1.5
    line.Transparency = 1
    return line
end

local function toggleESP(state)
    espEnabled = state

    if not espEnabled then
        for _, line in pairs(lines) do
            line.Visible = false
            line:Remove()
        end
        lines = {}
    end
end

RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not lines[player] then
                lines[player] = createLine()
            end

            local line = lines[player]
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and humanoid and humanoid.Health > 0 then
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.From = screenCenter
                    line.To = Vector2.new(vector.X, vector.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if lines[player] then
        lines[player]:Remove()
        lines[player] = nil
    end
end)

-- Auto Orb
local function startAutoOrb()
    task.spawn(function()
        while autoOrbEnabled do
            local orbs = getTargetOrbs()
            if #orbs == 0 then
                task.wait(1.5)
            else
                for _, orb in ipairs(orbs) do
                    if not autoOrbEnabled then break end
                    if orb and orb.Parent then
                        teleportTo(orb.CFrame + Vector3.new(0, 3, 0))
                        task.wait(0.45)
                    end
                end
            end
            task.wait(0.6)
        end
    end)
end

-- Kill Aura
local function startKillAura()
    task.spawn(function()
        while killAuraEnabled do
            local targets = getWorkspacePlayers()
            for _, target in ipairs(targets) do
                if not killAuraEnabled then break end
                if target and target.Parent then
                    doAttack(target)
                end
            end
            task.wait(0.2)
        end
    end)
end

-- ==================== UI ====================
UI:Toggle("AutoOrbToggle", "Auto Orb", function(enabled)
    autoOrbEnabled = enabled
    if enabled then
        startAutoOrb()
        print("[Auto Orb] 已開啟")
    else
        print("[Auto Orb] 已關閉")
    end
end)

UI:Toggle("KillAuraToggle", "Kill Aura", function(enabled)
    killAuraEnabled = enabled
    if enabled then
        startKillAura()
        print("[Kill Aura] 已開啟")
    else
        print("[Kill Aura] 已關閉")
    end
end)

UI:Toggle("ESPToggle", "Player ESP (Lines)", function(enabled)
    toggleESP(enabled)
    if enabled then
        print("[ESP] 已開啟")
    else
        print("[ESP] 已關閉")
    end
end)

UI:Slider("SpeedSlider", "Speed", 16, 200, 50, function(value)
    currentSpeed = value
    print("[Speed] 目前速度:", value)
end)

UI:Toggle("SpeedToggle", "Speed Enable", function(enabled)
    speedEnabled = enabled
    if enabled then
        startSpeed()
        print("[Speed] 已開啟，速度:", currentSpeed)
    else
        stopSpeed()
        print("[Speed] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
