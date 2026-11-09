-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Deogle Arena")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.KillAllSettings = {
    FireRateDelay = 0.04,
    TargetPart = "Head",
    PanicHealthThreshold = 40
}

local autoKill = false
local CurrentShotTargets = {}
local DeagleController = nil

pcall(function()
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
    DeagleController = require(PlayerScripts:WaitForChild("ModuleLoader"):WaitForChild("DeagleController"))
end)

local function IsAliveAndValid(model)
    if not model or not model:IsA("Model") or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return false end

    local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    if not rootPart then return false end

    if model:FindFirstChild("Dead") or model:GetAttribute("IsDead") == true then return false end
    return true
end

local function GetAllPotentialTargets()
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsAliveAndValid(player.Character) then
            if not (player.Team and player.Team == LocalPlayer.Team) then
                table.insert(targets, player.Character)
            end
        end
    end

    local queue = {workspace}
    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, child in ipairs(current:GetChildren()) do
            if child:IsA("Model") and IsAliveAndValid(child) then
                if not table.find(targets, child) and not Players:GetPlayerFromCharacter(child) then
                    table.insert(targets, child)
                end
            elseif child:IsA("Folder") or child.Name:lower():find("bot") or child.Name:lower():find("npc") then
                table.insert(queue, child)
            end
        end
    end

    return targets
end

local function IsTargetVisible(targetPart, myRootPart)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    params.IgnoreWater = true

    local origin = myRootPart.Position
    return workspace:Raycast(origin, targetPart.Position - origin, params) == nil
end

-- 依目標速度與延遲預測位置
local function GetPredictedPosition(targetPart)
    local character = targetPart.Parent
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

    if rootPart and rootPart:IsA("BasePart") then
        local ping = LocalPlayer:GetNetworkPing() or 0.03
        return targetPart.Position + rootPart.AssemblyLinearVelocity * (ping * 1.85)
    end
    return targetPart.Position
end

local function Shoot(aimPosition)
    pcall(function()
        if typeof(DeagleController.Shoot) == "function" then
            DeagleController.Shoot(aimPosition)
        elseif typeof(DeagleController.Fire) == "function" then
            DeagleController.Fire(aimPosition)
        end
    end)
end

local function GetTargetPart(child)
    return child:FindFirstChild(_G.KillAllSettings.TargetPart) or child:FindFirstChild("Head")
end

local function ExecuteAutomatedSweep()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    local myHum = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    if not myChar or not myRoot or not myHum or not DeagleController then return end

    local isVulnerable = (myHum.Health / myHum.MaxHealth * 100) <= _G.KillAllSettings.PanicHealthThreshold

    if typeof(DeagleController) == "table" then
        DeagleController.ShootCooldownUntil = 0
        DeagleController.CanShoot = true
        DeagleController.CurrentSpread = 0
        if DeagleController.WeaponStats then
            DeagleController.WeaponStats.Spread = 0
        end
    end

    table.clear(CurrentShotTargets)
    local pool = GetAllPotentialTargets()

    table.sort(pool, function(a, b)
        local rootA = a:FindFirstChild("HumanoidRootPart") or a:FindFirstChild("Torso")
        local rootB = b:FindFirstChild("HumanoidRootPart") or b:FindFirstChild("Torso")
        if rootA and rootB then
            return (myRoot.Position - rootA.Position).Magnitude < (myRoot.Position - rootB.Position).Magnitude
        end
        return false
    end)

    if isVulnerable then
        -- 血量低：只打一個目標，優先挑看得到的
        local fired = false
        for _, child in ipairs(pool) do
            local part = GetTargetPart(child)
            if part and IsTargetVisible(part, myRoot) then
                CurrentShotTargets[part] = true
                Shoot(GetPredictedPosition(part))
                fired = true
                break
            end
        end
        if not fired then
            for _, child in ipairs(pool) do
                local part = GetTargetPart(child)
                if part then
                    CurrentShotTargets[part] = true
                    Shoot(GetPredictedPosition(part))
                    break
                end
            end
        end
    else
        for _, child in ipairs(pool) do
            local part = GetTargetPart(child)
            if part then
                CurrentShotTargets[part] = true
                Shoot(GetPredictedPosition(part))
            end
        end
    end
end

-- Raycast hook：只安裝一次，關閉開關時直接走原本的 Raycast
local success, DeagleShared = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("DeagleShared"))
end)

if success and DeagleShared and DeagleShared.Raycast then
    local oldRaycast = DeagleShared.Raycast
    DeagleShared.Raycast = function(p1, p2, p3, ...)
        if autoKill then
            for targetPart in pairs(CurrentShotTargets) do
                if targetPart and targetPart.Parent and IsAliveAndValid(targetPart.Parent) then
                    return {
                        Instance = targetPart,
                        Position = GetPredictedPosition(targetPart),
                        Normal = Vector3.new(0, 1, 0),
                        Material = Enum.Material.Plastic
                    }
                end
            end
        end
        return oldRaycast(p1, p2, p3, ...)
    end
end

UI:Toggle("Toggle", "Auto Kill", function(enabled)
    autoKill = enabled
    if not enabled then
        table.clear(CurrentShotTargets)
        return
    end

    task.spawn(function()
        while autoKill do
            pcall(ExecuteAutomatedSweep)
            task.wait(_G.KillAllSettings.FireRateDelay)
        end
    end)
end)
