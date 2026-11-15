-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("BloxNG")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local autoCrushEnabled = false
local autoGroundEnabled = false
local currentTweens = {}
local groundConnection = nil

-- 高處高度
local CRUSH_HEIGHT = 500
-- Tween 時間
local TWEEN_TIME = 1.2
-- 往下壓的力度
local GROUND_FORCE = -250

local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getVehicle()
    local character = LocalPlayer.Character
    if not character then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    local seat = humanoid.SeatPart
    if not seat then return nil end

    local model = seat:FindFirstAncestorOfClass("Model")
    if model and model ~= character then
        return model
    end

    return nil
end

local function cancelTweens()
    for _, tw in ipairs(currentTweens) do
        pcall(function()
            tw:Cancel()
        end)
    end
    currentTweens = {}
end

-- Tween 到指定高度
local function crushTween(height)
    height = height or CRUSH_HEIGHT

    local hrp = getHRP()
    if not hrp then return end

    cancelTweens()

    local vehicle = getVehicle()
    local targetY = height
    local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    if vehicle then
        local primary = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
        if primary then
            local offsetY = targetY - primary.Position.Y

            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    local goal = {
                        CFrame = part.CFrame + Vector3.new(0, offsetY, 0)
                    }
                    local tw = TweenService:Create(part, tweenInfo, goal)
                    table.insert(currentTweens, tw)
                    tw:Play()
                end
            end

            if #currentTweens > 0 then
                currentTweens[1].Completed:Wait()
            end
            print("[Crush] 已 Tween 連人帶車到高度:", targetY)
        else
            local goal = { CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z) }
            local tw = TweenService:Create(hrp, tweenInfo, goal)
            table.insert(currentTweens, tw)
            tw:Play()
            tw.Completed:Wait()
            print("[Crush] 已 Tween 到高度:", targetY)
        end
    else
        local goal = { CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z) }
        local tw = TweenService:Create(hrp, tweenInfo, goal)
        table.insert(currentTweens, tw)
        tw:Play()
        tw.Completed:Wait()
        print("[Crush] 已 Tween 到高度:", targetY)
    end

    currentTweens = {}
end

-- 持續往下壓
local function startGroundCrush()
    if groundConnection then
        groundConnection:Disconnect()
        groundConnection = nil
    end

    groundConnection = RunService.Heartbeat:Connect(function()
        if not autoGroundEnabled then return end

        local vehicle = getVehicle()
        if vehicle then
            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.new(
                        part.AssemblyLinearVelocity.X,
                        GROUND_FORCE,
                        part.AssemblyLinearVelocity.Z
                    )
                end
            end
        else
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    GROUND_FORCE,
                    hrp.AssemblyLinearVelocity.Z
                )
            end
        end
    end)
end

local function stopGroundCrush()
    if groundConnection then
        groundConnection:Disconnect()
        groundConnection = nil
    end
end

-- Auto Crush 主迴圈
local function startAutoCrush()
    task.spawn(function()
        while autoCrushEnabled do
            crushTween(CRUSH_HEIGHT)
            print("[Auto Crush] 等待 15 秒後繼續...")
            task.wait(15)
        end
        cancelTweens()
    end)
end

-- ==================== UI ====================
UI:Input("HeightInput", "Height", "Number", function(text, entered)
    local num = tonumber(text)
    if num then
        CRUSH_HEIGHT = num
        print("[Height] 已設定高度:", CRUSH_HEIGHT)
    end
end)

UI:Button("TPHeightButton", "TP Height", function()
    task.spawn(function()
        crushTween(CRUSH_HEIGHT)
    end)
end)

UI:Toggle("AutoCrushToggle", "Auto Crush", function(enabled)
    autoCrushEnabled = enabled
    if enabled then
        startAutoCrush()
        print("[Auto Crush] 已開啟")
    else
        cancelTweens()
        print("[Auto Crush] 已關閉")
    end
end)

UI:Toggle("AutoGroundToggle", "Auto Ground Crush", function(enabled)
    autoGroundEnabled = enabled
    if enabled then
        startGroundCrush()
        print("[Auto Ground Crush] 已開啟（持續往下壓）")
    else
        stopGroundCrush()
        print("[Auto Ground Crush] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
