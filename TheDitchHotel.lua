-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("The Ditch Hotel")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local TELEPORT_HEIGHT = 3   -- 傳送時高於目標的距離（studs）

local speedValue = nil   -- nil = 尚未拖動滑桿，不去動 WalkSpeed
local propConn = nil
local noclipEnabled = false
local noclipConn = nil

local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- 監聽 WalkSpeed 變化，被遊戲改掉就立刻改回來
local function hook(hum)
    if propConn then
        propConn:Disconnect()
        propConn = nil
    end
    if not hum then return end

    propConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if speedValue and hum.WalkSpeed ~= speedValue then
            hum.WalkSpeed = speedValue
        end
    end)

    if speedValue then
        hum.WalkSpeed = speedValue
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    hook(hum)
end)

hook(getHumanoid())

RunService.Heartbeat:Connect(function()
    if not speedValue then return end
    local hum = getHumanoid()
    if hum and hum.WalkSpeed ~= speedValue then
        hum.WalkSpeed = speedValue
    end
end)

-- Noclip 開關控制
local function setNoclip(state)
    noclipEnabled = state
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end

    if noclipEnabled then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- 關閉時恢復身體主要部位的碰撞
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function getTargetPos(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        return obj:GetPivot().Position
    end
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position
end

UI:Slider("Slider", "Speed", 16, 200, 16, function(value)
    speedValue = value
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = value
        if not propConn then hook(hum) end
    end
end)

UI:Toggle("NoclipToggle", "Noclip", false, function(state)
    setNoclip(state)
    print("[Noclip]", state and "已開啟" or "已關閉")
end)

UI:Button("Button", "Escape", function()
    local root = getRoot()
    local map = workspace:FindFirstChild("Map")
    local target = map and map:FindFirstChild("Escape")
    if not target then
        warn("[Escape] 找不到 workspace.Map.Escape")
        return
    end

    local pos = getTargetPos(target)
    if root and pos then
        root.CFrame = CFrame.new(pos + Vector3.new(0, TELEPORT_HEIGHT, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        print("[Escape] 已傳送")
    end
end)

UI:Status("Status", "Tik Tok: ValueHat")
