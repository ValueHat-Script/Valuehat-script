-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Steal a Superpower")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquipBest = Remotes:WaitForChild("EquipBest")
local BenchUpgrade = Remotes:WaitForChild("BenchUpgrade")
local Rebirth = Remotes:WaitForChild("Rebirth")

local KILL_RANGE = 100
local SCAN_INTERVAL = 0.3
local EQUIP_INTERVAL = 5
local UPGRADE_INTERVAL = 5
local REBIRTH_INTERVAL = 5
local CARD_NEAR_RANGE = 10    -- 角色距離 BestButton 多近才算「靠近」（studs）
local CARD_PROMPT_RANGE = 5   -- 觸發 BestButton 周圍多少 studs 內的 Prompt
local CARD_COOLDOWN = 1       -- 同一個 Prompt 再次觸發的間隔（秒）
local CARD_SCAN = 0.3         -- 偵測間隔（秒）

local instantKill = false
local autoEquip = false
local autoBarbell = false
local autoRebirth = false
local autoCard = false
local speedValue = nil

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPos(obj)
    if obj:IsA("Model") then
        return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Attachment") then
        return obj.WorldPosition
    end
end

local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function killNearbyNPCs()
    local root = getRoot()
    if not root then return end

    for _, hum in ipairs(workspace:GetDescendants()) do
        if hum:IsA("Humanoid") and hum.Health > 0 then
            local model = hum.Parent
            if model and not isPlayerCharacter(model) then
                local pos = getPos(model)
                if pos and (pos - root.Position).Magnitude <= KILL_RANGE then
                    hum.Health = 0
                end
            end
        end
    end
end

-- Equip Best Card：靠近任一 Plot 的 BestButton 時，觸發其周圍的 Prompt
local lastFired = {}

local function cardStep()
    local root = getRoot()
    if not root then return end

    local ok, bases = pcall(function() return workspace.Map.Bases end)
    if not ok or not bases then return end

    for _, plot in ipairs(bases:GetChildren()) do
        local button = plot:FindFirstChild("BestButton", true)
        local btnPos = button and getPos(button)
        if btnPos and (btnPos - root.Position).Magnitude <= CARD_NEAR_RANGE then
            for _, d in ipairs(plot:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    local pos = d.Parent and getPos(d.Parent)
                    if pos and (pos - btnPos).Magnitude <= CARD_PROMPT_RANGE then
                        local now = os.clock()
                        if now - (lastFired[d] or 0) >= CARD_COOLDOWN then
                            lastFired[d] = now
                            d.HoldDuration = 0
                            fireproximityprompt(d)
                        end
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not speedValue then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum and hum.WalkSpeed ~= speedValue then
        hum.WalkSpeed = speedValue
    end
end)

UI:Toggle("Toggle", "Instant Kill", function(enabled)
    instantKill = enabled
    if not enabled then return end

    task.spawn(function()
        while instantKill do
            killNearbyNPCs()
            task.wait(SCAN_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Equip Best", function(enabled)
    autoEquip = enabled
    if not enabled then return end

    task.spawn(function()
        while autoEquip do
            local ok, result = pcall(function()
                return EquipBest:InvokeServer()
            end)
            print("[EquipBest] 成功:", ok, "| 回傳:", result)
            task.wait(EQUIP_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Equip Best Card", function(enabled)
    autoCard = enabled
    if not enabled then return end

    task.spawn(function()
        while autoCard do
            pcall(cardStep)
            task.wait(CARD_SCAN)
        end
    end)
end)

UI:Toggle("Toggle", "Upgrade Barbell", function(enabled)
    autoBarbell = enabled
    if not enabled then return end

    task.spawn(function()
        while autoBarbell do
            local ok, err = pcall(function()
                BenchUpgrade:FireServer()
            end)
            if not ok then
                print("[UpgradeBarbell] 失敗:", err)
            end
            task.wait(UPGRADE_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Auto Rebirth", function(enabled)
    autoRebirth = enabled
    if not enabled then return end

    task.spawn(function()
        while autoRebirth do
            local ok, result = pcall(function()
                return Rebirth:InvokeServer()
            end)
            print("[AutoRebirth] 成功:", ok, "| 回傳:", result)
            task.wait(REBIRTH_INTERVAL)
        end
    end)
end)

UI:Slider("Slider", "Speed", 16, 200, 16, function(value)
    speedValue = value
end)
