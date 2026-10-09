local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local mobPegaEvent = ReplicatedStorage:WaitForChild("Arena"):WaitForChild("Remotos"):WaitForChild("MobPega")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local clickEvent = remotesFolder and remotesFolder:WaitForChild("Click", 5)
local rebirthEvent = remotesFolder and remotesFolder:FindFirstChild("Rebirth")

local antiDamageEnabled = false
local autoStrengthEnabled = false
local autoRebirthEnabled = false

local oldNamecall
if hookmetamethod then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if antiDamageEnabled and self == mobPegaEvent and (method == "FireServer" or method == "fireServer") then
            return nil
        end
        return oldNamecall(self, ...)
    end)
end

local function toggleAntiDamage(state)
    antiDamageEnabled = state
    if getconnections then
        for _, conn in ipairs(getconnections(mobPegaEvent.OnClientEvent)) do
            if state then
                conn:Disable()
            else
                conn:Enable()
            end
        end
    end
end

local function startAutoStrength()
    task.spawn(function()
        while autoStrengthEnabled do
            if clickEvent then
                pcall(function()
                    clickEvent:FireServer()
                end)
            else
                local evt = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Click")
                if evt then
                    clickEvent = evt
                    pcall(function()
                        clickEvent:FireServer()
                    end)
                end
            end
            task.wait()
        end
    end)
end

local function startAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            local evt = rebirthEvent
            if not evt then
                evt = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Rebirth")
                if evt then
                    rebirthEvent = evt
                end
            end
            if evt then
                pcall(function()
                    evt:FireServer()
                end)
            end
            task.wait(0.5)
        end
    end)
end

local function setHipHeight(value)
    local num = tonumber(value)
    if not num then return end
    if num < 1 then num = 1 end
    if num > 10 then num = 10 end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HipHeight = num
    end
end

local Hub = UIModule.CreateWindow("Anti Damage Hub", "TikTok: ValueHat")

Hub:CreateToggle("Anti Damage", false, function(on)
    toggleAntiDamage(on)
end)

Hub:CreateToggle("Auto Strength", false, function(on)
    autoStrengthEnabled = on
    if on then
        startAutoStrength()
    end
end)

Hub:CreateToggle("Auto Rebirth", false, function(on)
    autoRebirthEnabled = on
    if on then
        startAutoRebirth()
    end
end)

Hub:CreateInput("HipHeight", "1\~10", function(text, enterPressed)
    if enterPressed then
        setHipHeight(text)
    end
end)
