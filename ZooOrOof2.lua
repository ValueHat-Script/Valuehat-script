-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Zoo or oof 2", "TikTok: ValueHat")

--------------------------------------------------
-- 服務與變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local playerESPEnabled = false
local noclipEnabled = false
local autoShootEnabled = false

local playerEspObjects = {}

-- 取得 RemoteEvent 容器
local remoteEvent = ReplicatedStorage:WaitForChild("iEngine"):WaitForChild("Remotes"):WaitForChild("RemoteEvent")

-- 取得 UI 放置容器
local function getParent()
    local target
    pcall(function() target = (gethui and gethui()) or CoreGui end)
    if not target then target = LocalPlayer:WaitForChild("PlayerGui") end
    return target
end

local espScreenGui = Instance.new("ScreenGui")
espScreenGui.Name = "ValueHat_PlayerESP"
espScreenGui.ResetOnSpawn = false
espScreenGui.IgnoreGuiInset = true
espScreenGui.Parent = getParent()

--------------------------------------------------
-- 輔助功能：尋找最近目標玩家
--------------------------------------------------
local function getClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local head = plr.Character:FindFirstChild("Head") or plr.Character.PrimaryPart

            if hum and hum.Health > 0 and head then
                local screenPos, isVisible = Camera:WorldToViewportPoint(head.Position)
                if isVisible then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPlayer = plr
                    end
                end
            end
        end
    end
    return closestPlayer
end

--------------------------------------------------
-- 1. Auto Shoot (自動瞄準與射擊) 核心邏輯
--------------------------------------------------
task.spawn(function()
    while true do
        if autoShootEnabled then
            pcall(function()
                local targetPlayer = getClosestPlayerToCenter()
                if targetPlayer and targetPlayer.Character then
                    local head = targetPlayer.Character:FindFirstChild("Head") or targetPlayer.Character.PrimaryPart
                    if head then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                        
                        remoteEvent:FireServer(
                            "net",
                            "Seeker",
                            "shot",
                            {
                                {
                                    endPosition = head.Position
                                }
                            }
                        )
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

--------------------------------------------------
-- 2. Noclip (穿牆) 核心邏輯
--------------------------------------------------
RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        pcall(function()
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

--------------------------------------------------
-- 3. Player ESP 核心邏輯
--------------------------------------------------
local function destroyESP(container)
    if container then
        if container.Highlight then container.Highlight:Destroy() end
        if container.Billboard then container.Billboard:Destroy() end
    end
end

local function createPlayerESP(playerModel, plr)
    local container = {}
    local pColor = Color3.fromRGB(255, 60, 60)
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = playerModel
    highlight.FillColor = pColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = espScreenGui
    container.Highlight = highlight

    local head = playerModel:FindFirstChild("Head") or playerModel.PrimaryPart
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = espScreenGui

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = pColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 13
    textLabel.Text = plr.DisplayName
    textLabel.Parent = billboard

    container.Billboard = billboard
    container.Label = textLabel
    return container
end

task.spawn(function()
    while true do
        if playerESPEnabled then
            pcall(function()
                local currentFound = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local char = plr.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local hrp = char:FindFirstChild("HumanoidRootPart")

                        if hum and hum.Health > 0 and hrp then
                            currentFound[plr] = true
                            if not playerEspObjects[plr] then
                                playerEspObjects[plr] = createPlayerESP(char, plr)
                            else
                                if playerEspObjects[plr].Highlight.Adornee ~= char then
                                    playerEspObjects[plr].Highlight.Adornee = char
                                    local head = char:FindFirstChild("Head") or hrp
                                    playerEspObjects[plr].Billboard.Adornee = head
                                end
                            end
                        end
                    end
                end

                for plr, container in pairs(playerEspObjects) do
                    if not currentFound[plr] then
                        destroyESP(container)
                        playerEspObjects[plr] = nil
                    end
                end
            end)
        else
            for plr, container in pairs(playerEspObjects) do destroyESP(container) end
            playerEspObjects = {}
        end
        task.wait(0.5)
    end
end)

RunService.RenderStepped:Connect(function()
    if not playerESPEnabled then return end
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if myHrp then
        for plr, container in pairs(playerEspObjects) do
            if plr and plr.Character and container.Label then
                local pHrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if pHrp then
                    local dist = math.floor((myHrp.Position - pHrp.Position).Magnitude)
                    container.Label.Text = string.format("%s\n[%d m]", plr.DisplayName, dist)
                else
                    container.Label.Text = plr.DisplayName
                end
            end
        end
    end
end)

--------------------------------------------------
-- ValueHat UI 組件綁定
--------------------------------------------------

-- TP Safe Zone 按鈕
Hub:CreateButton("TP Safe Zone", function()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local safeZoneObj = Workspace.Lobby.Decorations:GetChildren()[21]
        
        if hrp and safeZoneObj then
            local targetCFrame
            if safeZoneObj:IsA("BasePart") then
                targetCFrame = safeZoneObj.CFrame
            elseif safeZoneObj:IsA("Model") then
                targetCFrame = safeZoneObj:GetPivot()
            end

            if targetCFrame then
                hrp.CFrame = targetCFrame * CFrame.new(0, 3, 0)
            end
        end
    end)
end)

-- Auto Shoot 開關
Hub:CreateToggle("Auto Shoot", false, function(isOn)
    autoShootEnabled = isOn
end)

-- Player ESP 開關
Hub:CreateToggle("Player ESP", false, function(isOn)
    playerESPEnabled = isOn
    if not isOn then
        for plr, container in pairs(playerEspObjects) do 
            destroyESP(container) 
        end
        playerEspObjects = {}
    end
end)

-- Noclip 穿牆開關
Hub:CreateToggle("Noclip", false, function(isOn)
    noclipEnabled = isOn
end)
