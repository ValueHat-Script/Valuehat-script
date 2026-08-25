-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Build Base To Survive Verity", "TikTok: ValueHat")

--------------------------------------------------
-- 變數設定
--------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AutoAmmoEnabled = false
local WalkSpeedValue = 16 -- Roblox 預設 WalkSpeed 為 16
local HipHeightValue = 2 -- Roblox 預設 HipHeight 約為 2

-- 圖片中的武器名稱清單 (做備用匹配)
local TargetGunNames = {
    "AK47", "Blaster", "Exo Gun", "Falsity Gun", "Kawaii Gun", 
    "Laser Gun", "Minigun", "OP Gun", "Rifle Blaster", "Shotgun", 
    "Sniper", "Spooky Gun"
}

--------------------------------------------------
-- 核心功能邏輯
--------------------------------------------------

-- 1. 速度與 HipHeight 每幀鎖定保護 (防止被遊戲腳本重置)
RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if humanoid.WalkSpeed ~= WalkSpeedValue then
                humanoid.WalkSpeed = WalkSpeedValue
            end
            if humanoid.HipHeight ~= HipHeightValue then
                humanoid.HipHeight = HipHeightValue
            end
        end
    end
end)

-- 輔助函式：判斷是否為目標槍枝
local function IsTargetGun(item)
    if not item:IsA("Tool") then return false end
    
    for _, name in ipairs(TargetGunNames) do
        if string.find(item.Name, name) then
            return true
        end
    end
    
    if string.find(item.Name, "Gun") or string.find(item.Name, "Blaster") then
        return true
    end

    return false
end

-- 2. Auto Ammo 核心邏輯
task.spawn(function()
    while true do
        if AutoAmmoEnabled then
            pcall(function()
                local targets = {}

                local gunsFolder = ReplicatedStorage:FindFirstChild("Guns")
                if gunsFolder then
                    for _, item in ipairs(gunsFolder:GetChildren()) do
                        table.insert(targets, item)
                    end
                end

                if LocalPlayer and LocalPlayer:FindFirstChild("Backpack") then
                    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        table.insert(targets, item)
                    end
                end

                if LocalPlayer and LocalPlayer.Character then
                    for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
                        table.insert(targets, item)
                    end
                end

                for _, item in ipairs(targets) do
                    if IsTargetGun(item) then
                        item:SetAttribute("_ammo", math.huge)
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

--------------------------------------------------
-- UI 控制項
--------------------------------------------------

-- 1. WalkSpeed 移動速度滑桿 (範圍: 16 ~ 300，預設: 16)
Hub:CreateSlider("Walk Speed", 16, 300, 16, function(val)
    WalkSpeedValue = val
end)

-- 2. HipHeight 角色高度滑桿 (範圍: 0 ~ 50，預設: 2)
Hub:CreateSlider("Hip Height", 0, 50, 2, function(val)
    HipHeightValue = val
end)

-- 3. Auto Ammo 開關
Hub:CreateToggle("INF Ammo", false, function(isOn)
    AutoAmmoEnabled = isOn
end)
