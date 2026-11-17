-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Throw Key For Cars")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local autoUpgradeEnabled = false
local autoBonusEnabled = false
local autoEquipBestEnabled = false

-- 取得 NexFunction 遠端事件
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local NexFunction = remotes and remotes:FindFirstChild("NexFunction")

-- 取得 StarterArea 的目標座標
local function getStarterAreaPosition()
    local starterArea = Workspace:FindFirstChild("StarterArea")
    if not starterArea then
        warn("[Best Throw] 找不到 workspace.StarterArea！")
        return nil
    end

    if starterArea:IsA("BasePart") then
        return starterArea.Position + Vector3.new(0, 3, 0)
    elseif starterArea:IsA("Model") then
        local cf, size = starterArea:GetBoundingBox()
        return cf.Position + Vector3.new(0, size.Y * 0.5 + 3, 0)
    else
        for _, obj in ipairs(starterArea:GetDescendants()) do
            if obj:IsA("BasePart") then
                return obj.Position + Vector3.new(0, 3, 0)
            end
        end
    end

    return nil
end

-- 傳送到指定座標的函數
local function teleportToStarterArea()
    local char = LP.Character
    if not char then return false end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local targetPos = getStarterAreaPosition()
    if targetPos then
        rootPart.CFrame = CFrame.new(targetPos)
        print("[Best Throw] 已成功傳送到 StarterArea！")
        return true
    end
    
    return false
end

-- 模擬點擊螢幕中央最下面的函數
local function simulateScreenClick()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local viewportSize = cam.ViewportSize
    -- 設定為螢幕中央最下方 (X 為正中間，Y 接近底部 30 像素處)
    local clickX = viewportSize.X * 0.5
    local clickY = viewportSize.Y - 30

    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
    
    print("[Best Throw] 已自動點擊螢幕中央最下方！")
end

-- ==================== Auto Upgrade Bar 迴圈 ====================
task.spawn(function()
    while true do
        if autoUpgradeEnabled and NexFunction then
            pcall(function()
                NexFunction:InvokeServer(
                    "BarService",
                    "Upgrade",
                    {
                        n = 0
                    }
                )
            end)
        end
        task.wait(0.2)
    end
end)

-- ==================== Auto Equip Best 迴圈 ====================
task.spawn(function()
    while true do
        if autoEquipBestEnabled and NexFunction then
            pcall(function()
                NexFunction:InvokeServer(
                    "InventoryService",
                    "EquipBest",
                    {
                        n = 0
                    }
                )
            end)
        end
        task.wait(0.5)
    end
end)

-- ==================== Auto Train Bonus 迴圈 ====================
task.spawn(function()
    while true do
        if autoBonusEnabled then
            pcall(function()
                local playerGui = LP:FindFirstChild("PlayerGui")
                if playerGui then
                    local trainingSeq = playerGui:FindFirstChild("TrainingSequence")
                    if trainingSeq then
                        local bonus = trainingSeq:FindFirstChild("Bonus")
                        if bonus then
                            if bonus:IsA("TextButton") or bonus:IsA("ImageButton") then
                                for _, conn in ipairs(getconnections(bonus.MouseButton1Click)) do
                                    conn:Fire()
                                end
                                for _, conn in ipairs(getconnections(bonus.Activated)) do
                                    conn:Fire()
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- ==================== UI ====================
UI:Button("BestThrowBtn", "Best Throw", function()
    print("[Best Throw] 按鈕已按下：開始傳送並等待 1.4 秒...")
    
    task.spawn(function()
        -- 1. 先傳送到 workspace.StarterArea
        teleportToStarterArea()
        
        -- 2. 等待 1.4 秒
        task.wait(1.4)
        
        -- 3. 自動點擊螢幕中央最下方
        simulateScreenClick()
    end)
end)

UI:Button("SellAllBtn", "Sell All", function()
    if NexFunction then
        pcall(function()
            NexFunction:InvokeServer(
                "SellService",
                "SellAll",
                {
                    n = 0
                }
            )
            print("[Sell All] 已成功執行一鍵販售！")
        end)
    else
        warn("[Sell All] 找不到 NexFunction 遠端事件！")
    end
end)

UI:Toggle("AutoUpgradeToggle", "Auto Upgrade Bar", function(enabled)
    autoUpgradeEnabled = enabled
    if enabled then
        print("[Auto Upgrade Bar] 已開啟")
    else
        print("[Auto Upgrade Bar] 已關閉")
    end
end)

UI:Toggle("AutoEquipBestToggle", "Auto Equip Best", function(enabled)
    autoEquipBestEnabled = enabled
    if enabled then
        print("[Auto Equip Best] 已開啟")
    else
        print("[Auto Equip Best] 已關閉")
    end
end)

UI:Toggle("AutoBonusToggle", "Auto Train Bonus", function(enabled)
    autoBonusEnabled = enabled
    if enabled then
        print("[Auto Train Bonus] 已開啟")
    else
        print("[Auto Train Bonus] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
