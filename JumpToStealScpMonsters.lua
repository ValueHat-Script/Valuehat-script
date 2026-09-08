-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗並清理舊組件
local Hub = UIModule.CreateWindow("Jump to steal scp monster", "TikTok: ValueHat")

-- 核心服務與變數
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local isRunning = false

---------------------------------------------------------
-- 判斷 Model 是否為 Slime God
---------------------------------------------------------
local function isSlimeGod(model)
    if not model or not model:IsA("Model") then return false end

    if string.find(model.Name, "Slime God") then
        return true
    end

    local rarityObj = model:FindFirstChild("Rarity")
    if rarityObj then
        if rarityObj:IsA("StringValue") and rarityObj.Value == "Slime God" then
            return true
        end
    end

    local rarityAttr = model:GetAttribute("Rarity")
    if rarityAttr and tostring(rarityAttr) == "Slime God" then
        return true
    end

    return false
end

---------------------------------------------------------
-- 執行傳送、觸發與返回邏輯 (停留 1 秒)
---------------------------------------------------------
local function executeAutoBlock()
    if isRunning then return end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local slimesFolder = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("Slimes")
    if not slimesFolder then return end

    local targetModel = nil
    for _, model in ipairs(slimesFolder:GetChildren()) do
        if isSlimeGod(model) then
            targetModel = model
            break
        end
    end

    if not targetModel then return end

    local rootPart = targetModel:FindFirstChild("RootPart")
    if not rootPart then return end

    local prompt = rootPart:FindFirstChildWhichIsA("ProximityPrompt", true) or rootPart:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end

    isRunning = true
    local originalCFrame = hrp.CFrame

    hrp.CFrame = rootPart.CFrame * CFrame.new(0, 3, 0)

    local startTime = tick()
    while tick() - startTime < 1.0 do
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
        LocalPlayer.Character.HumanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 3, 0)
        fireproximityprompt(prompt)
        task.wait(0.1)
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
    end
    isRunning = false
end

---------------------------------------------------------
-- UI 控制組件
---------------------------------------------------------

-- 1. 自動循環檢測 Slime God Toggle
local autoLoopEnabled = false
Hub:CreateToggle("Auto Best Block", false, function(isOn)
    autoLoopEnabled = isOn
    if autoLoopEnabled then
        task.spawn(function()
            while autoLoopEnabled do
                pcall(executeAutoBlock)
                task.wait(1)
            end
        end)
    end
end)

---------------------------------------------------------
-- 2. Auto Open & Collect (開箱與領取)
---------------------------------------------------------

local autoCollectEnabled = false

Hub:CreateToggle("Auto Open & Collect", false, function(isOn)
    autoCollectEnabled = isOn
    
    if autoCollectEnabled then
        task.spawn(function()
            while autoCollectEnabled do
                pcall(function()
                    local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
                    local network = sharedModules and sharedModules:FindFirstChild("Network")
                    local remotes = network and network:FindFirstChild("Remotes")
                    
                    if remotes then
                        local openEvent = remotes:FindFirstChild("Open Lucky Block")
                        local collectEvent = remotes:FindFirstChild("Collect Earnings")

                        for i = 1, 100 do
                            if not autoCollectEnabled then break end
                            local strIndex = tostring(i)

                            if openEvent then
                                openEvent:FireServer(strIndex)
                            end
                            if collectEvent then
                                collectEvent:FireServer(strIndex)
                            end
                            
                            task.wait(0.01)
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

---------------------------------------------------------
-- 3. Auto Buy Speed +3
---------------------------------------------------------

local autoBuySpeedEnabled = false

Hub:CreateToggle("Auto Buy Speed +10", false, function(isOn)
    autoBuySpeedEnabled = isOn
    
    if autoBuySpeedEnabled then
        task.spawn(function()
            while autoBuySpeedEnabled do
                pcall(function()
                    local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
                    local network = sharedModules and sharedModules:FindFirstChild("Network")
                    local remotes = network and network:FindFirstChild("Remotes")
                    
                    if remotes then
                        local event = remotes:FindFirstChild("Buy Speed Upgrade")
                        if event then
                            event:FireServer(3)
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
end)
