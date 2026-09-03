-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("+1 Strength To Grow your arm", "TikTok: ValueHat")

--------------------------------------------------
-- Services & Variables
--------------------------------------------------
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Toggle 狀態與線程控制
local autoBestBrainrotEnabled = false
local autoBrainrotThread = nil
local hitWallThread = nil

local autoTrainEnabled = false
local autoTrainThread = nil

local autoRebirthEnabled = false
local autoRebirthThread = nil

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

--------------------------------------------------
-- Safe Target Finder (僅保留 Area21 Part)
--------------------------------------------------
local function getTargetAreas()
    local areas = {}
    
    local artScene = nil
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:FindFirstChild("LevelMap2") then
            artScene = child
            break
        end
    end

    if not artScene then
        warn("[ValueHat] 未找到包含 LevelMap2 的美術場景！")
        return areas
    end

    local levelMap = artScene:FindFirstChild("LevelMap2")
    local mapFolder = levelMap and levelMap:FindFirstChild("map")

    if mapFolder then
        -- 僅取得 Area21 (Map9)
        local map9 = mapFolder:FindFirstChild("Map9")
        if map9 then
            local area21 = map9:FindFirstChild("Area21")
            if area21 then 
                table.insert(areas, area21) 
            end
        end
    end

    return areas
end

--------------------------------------------------
-- Pure Prompt Triggering (無移動)
--------------------------------------------------
local function triggerPrompt(prompt, targetName)
    if not prompt or not prompt.Parent then return end

    pcall(function()
        print("[ValueHat] 正在觸發 (Area21): " .. tostring(targetName))
        
        -- 解除視線與距離限制，確保遠距離直接觸發
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 999999

        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

--------------------------------------------------
-- Main Scanning Loop (Auto Best Brainrot)
--------------------------------------------------
local function startAutoBestBrainrot()
    if autoBrainrotThread then
        task.cancel(autoBrainrotThread)
        autoBrainrotThread = nil
    end

    autoBrainrotThread = task.spawn(function()
        while autoBestBrainrotEnabled do
            local targetAreas = getTargetAreas()
            local foundPrompt = false

            for _, areaPart in ipairs(targetAreas) do
                for _, childModel in ipairs(areaPart:GetChildren()) do
                    if childModel:IsA("Model") then
                        for _, descendant in ipairs(childModel:GetDescendants()) do
                            if descendant:IsA("ProximityPrompt") and descendant.Enabled then
                                foundPrompt = true
                                triggerPrompt(descendant, childModel.Name)
                                task.wait(0.2)
                                if not autoBestBrainrotEnabled then break end
                            end
                        end
                    end
                    if not autoBestBrainrotEnabled then break end
                end
                if not autoBestBrainrotEnabled then break end
            end

            if not foundPrompt then
                task.wait(1)
            end

            task.wait(0.5)
        end
    end)
end

--------------------------------------------------
-- Parallel Hit Wall Loop
--------------------------------------------------
local function startHitWall()
    if hitWallThread then
        task.cancel(hitWallThread)
        hitWallThread = nil
    end

    hitWallThread = task.spawn(function()
        while autoBestBrainrotEnabled do
            pcall(function()
                RemoteEvent:FireServer({
                    {
                        "\x18",
                        {
                            "HitWall",
                            "BlockWall1"
                        }
                    }
                })
            end)
            task.wait(0.1)
        end
    end)
end

--------------------------------------------------
-- Auto Train Loop
--------------------------------------------------
local function startAutoTrain()
    if autoTrainThread then
        task.cancel(autoTrainThread)
        autoTrainThread = nil
    end

    autoTrainThread = task.spawn(function()
        while autoTrainEnabled do
            pcall(function()
                RemoteEvent:FireServer({
                    {
                        "\x15",
                        {
                            "Train"
                        }
                    }
                })
            end)
            task.wait()
        end
    end)
end

--------------------------------------------------
-- Auto Rebirth Loop (獨立平行執行)
--------------------------------------------------
local function startAutoRebirth()
    if autoRebirthThread then
        task.cancel(autoRebirthThread)
        autoRebirthThread = nil
    end

    autoRebirthThread = task.spawn(function()
        while autoRebirthEnabled do
            pcall(function()
                RemoteEvent:FireServer({
                    {
                        "\x10",
                        {
                            "Rebirth"
                        }
                    }
                })
            end)
            task.wait(1)
        end
    end)
end

--------------------------------------------------
-- UI Build
--------------------------------------------------
Hub:CreateToggle("Auto Best Brainrot", autoBestBrainrotEnabled, function(isOn)
    autoBestBrainrotEnabled = isOn
    if isOn then
        startAutoBestBrainrot()
        startHitWall()
    else
        if autoBrainrotThread then
            task.cancel(autoBrainrotThread)
            autoBrainrotThread = nil
        end
        if hitWallThread then
            task.cancel(hitWallThread)
            hitWallThread = nil
        end
    end
end)

Hub:CreateToggle("Auto Train", autoTrainEnabled, function(isOn)
    autoTrainEnabled = isOn
    if isOn then
        startAutoTrain()
    else
        if autoTrainThread then
            task.cancel(autoTrainThread)
            autoTrainThread = nil
        end
    end
end)

Hub:CreateToggle("Auto Rebirth", autoRebirthEnabled, function(isOn)
    autoRebirthEnabled = isOn
    if isOn then
        startAutoRebirth()
    else
        if autoRebirthThread then
            task.cancel(autoRebirthThread)
            autoRebirthThread = nil
        end
    end
end)
