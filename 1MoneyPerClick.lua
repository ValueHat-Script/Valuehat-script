-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Money Per Click")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local winFarmEnabled = false
local moneyFarmEnabled = false
local autoRebirthEnabled = false
local autoEvolveEnabled = false

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 瞬移
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

-- 取得 WinClaim 位置
local function getWinClaimCFrame()
    local world9 = Workspace:FindFirstChild("WORLD 9")
    if not world9 then return nil end

    local stages = world9:FindFirstChild("STAGES")
    if not stages then return nil end

    local stage50 = stages:FindFirstChild("Stage50")
    if not stage50 then return nil end

    local winClaim = stage50:FindFirstChild("WinClaim")
    if not winClaim then return nil end

    if winClaim:IsA("BasePart") then
        return winClaim.CFrame + Vector3.new(0, 3, 0)
    elseif winClaim:IsA("Model") then
        if winClaim.PrimaryPart then
            return winClaim.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        end
        local part = winClaim:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
        return winClaim:GetPivot() + Vector3.new(0, 3, 0)
    end

    return nil
end

-- 取得 MoneyPad135 位置
local function getMoneyPadCFrame()
    local world9 = Workspace:FindFirstChild("WORLD 9")
    if not world9 then return nil end

    local moneypadStage = world9:FindFirstChild("Moneypad Stage")
    if not moneypadStage then return nil end

    local moneyPad = moneypadStage:FindFirstChild("MoneyPad135")
    if not moneyPad then return nil end

    if moneyPad:IsA("BasePart") then
        return moneyPad.CFrame + Vector3.new(0, 3, 0)
    elseif moneyPad:IsA("Model") then
        if moneyPad.PrimaryPart then
            return moneyPad.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        end
        local part = moneyPad:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
        return moneyPad:GetPivot() + Vector3.new(0, 3, 0)
    end

    return nil
end

-- 執行 ClickToEarn
local function doClickToEarn()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild("ClickToEarn")
    if not event then return end

    pcall(function()
        event:FireServer()
    end)
end

-- 執行 Rebirth
local function doRebirth()
    local event = ReplicatedStorage:FindFirstChild("RebirthRemote")
    if not event then return end

    local success, err = pcall(function()
        event:FireServer(nil)
    end)

    if success then
        print("[Auto Rebirth] 已轉生")
    else
        warn("[Auto Rebirth] 失敗:", err)
    end
end

-- 執行 Evolve
local function doEvolve()
    local event = ReplicatedStorage:FindFirstChild("EvolveRemote")
    if not event then return end

    local success, err = pcall(function()
        event:FireServer()
    end)

    if success then
        print("[Auto Evolve] 已進化")
    else
        warn("[Auto Evolve] 失敗:", err)
    end
end

-- Win Farm 主迴圈
local function startWinFarm()
    task.spawn(function()
        while winFarmEnabled do
            local cf = getWinClaimCFrame()
            if cf then
                teleportTo(cf)
            end
            task.wait(0.5)
        end
    end)
end

-- Money Farm 主迴圈
local function startMoneyFarm()
    task.spawn(function()
        while moneyFarmEnabled do
            doClickToEarn()
            task.wait(0.1)
        end
    end)
end

-- Auto Rebirth 主迴圈
local function startAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            doRebirth()
            task.wait(3)
        end
    end)
end

-- Auto Evolve 主迴圈
local function startAutoEvolve()
    task.spawn(function()
        while autoEvolveEnabled do
            doEvolve()
            task.wait(3)
        end
    end)
end

-- ==================== UI ====================
UI:Toggle("WinFarmToggle", "Win Farm", function(enabled)
    winFarmEnabled = enabled
    if enabled then
        startWinFarm()
        print("[Win Farm] 已開啟")
    else
        print("[Win Farm] 已關閉")
    end
end)

UI:Toggle("MoneyFarmToggle", "Money Farm", function(enabled)
    moneyFarmEnabled = enabled
    if enabled then
        startMoneyFarm()
        print("[Money Farm] 已開啟")
    else
        print("[Money Farm] 已關閉")
    end
end)

UI:Button("EquipBestButton", "Equip Best", function()
    local cf = getMoneyPadCFrame()
    if cf then
        teleportTo(cf)
        print("[Equip Best] 已傳送到 MoneyPad135")
    else
        warn("[Equip Best] 找不到目標位置")
    end
end)

UI:Toggle("AutoRebirthToggle", "Auto Rebirth", function(enabled)
    autoRebirthEnabled = enabled
    if enabled then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

UI:Toggle("AutoEvolveToggle", "Auto Evolve", function(enabled)
    autoEvolveEnabled = enabled
    if enabled then
        startAutoEvolve()
        print("[Auto Evolve] 已開啟")
    else
        print("[Auto Evolve] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
