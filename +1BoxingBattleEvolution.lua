-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Boxing Battle Evolution")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AuraClick = Remotes:WaitForChild("AuraClick")
local RebirthRequest = Remotes:WaitForChild("RebirthRequest")

local WIN_INTERVAL = 1       -- Win Farm 每次傳送的間隔（秒）
local WIN_HEIGHT = 3         -- 傳送時高於 Win 的距離（studs）
local TRAIN_INTERVAL = 0.1   -- Auto Train 發送間隔（秒），0 = 每幀
local REBIRTH_INTERVAL = 5   -- Auto Rebirth 發送間隔（秒）

local winFarm = false
local autoTrain = false
local autoRebirth = false

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPos(obj)
    if obj:IsA("Model") then
        return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
end

UI:Toggle("Toggle", "Win Farm", function(enabled)
    winFarm = enabled
    if not enabled then return end

    task.spawn(function()
        while winFarm do
            local stage = workspace:FindFirstChild("Stage15")
            local win = stage and stage:FindFirstChild("Win")
            local pos = win and getPos(win)
            local root = getRoot()

            if pos and root then
                root.CFrame = CFrame.new(pos + Vector3.new(0, WIN_HEIGHT, 0))
                root.AssemblyLinearVelocity = Vector3.zero
            elseif not win then
                print("[WinFarm] 找不到 workspace.Stage15.Win")
            end

            task.wait(WIN_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Auto Train", function(enabled)
    autoTrain = enabled
    if not enabled then return end

    task.spawn(function()
        while autoTrain do
            pcall(function()
                AuraClick:FireServer()
            end)
            task.wait(TRAIN_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Auto Rebirth", function(enabled)
    autoRebirth = enabled
    if not enabled then return end

    task.spawn(function()
        while autoRebirth do
            pcall(function()
                RebirthRequest:FireServer()
            end)
            task.wait(REBIRTH_INTERVAL)
        end
    end)
end)
