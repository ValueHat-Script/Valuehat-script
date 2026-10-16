-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local selectedStage = "Stage_01"
local autoAnimalEnabled = false
local autoCollectEnabled = false
local autoRebirthEnabled = false

-- Stage 1 \~ 10
local stages = {
    "Stage_01", "Stage_02", "Stage_03", "Stage_04", "Stage_05",
    "Stage_06", "Stage_07", "Stage_08", "Stage_09", "Stage_10"
}

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
    end
end

-- 尋找自己的 Plot
local function getMyPlot()
    local myName = LocalPlayer.Name:lower()

    for _, plot in ipairs(Workspace:GetChildren()) do
        if plot.Name:lower():find("plot_") then
            if plot.Name:lower():find(myName) then
                return plot
            end
        end
    end

    -- 備援：找最近的 Plot
    local hrp = getHRP()
    if not hrp then return nil end

    local closestPlot = nil
    local minDist = math.huge

    for _, plot in ipairs(Workspace:GetChildren()) do
        if plot.Name:lower():find("plot_") then
            local part = plot:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestPlot = plot
                end
            end
        end
    end

    return closestPlot
end

-- 取得自己 Plot 的返回位置
local function getPlotReturnCFrame()
    local myPlot = getMyPlot()
    if not myPlot then return nil end

    local floor1 = myPlot:FindFirstChild("Floor1")
    if floor1 then
        local part = floor1:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
    end

    local part = myPlot:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame + Vector3.new(0, 3, 0)
    end

    return nil
end

-- 取得指定 Stage 中的隨機 Model
local function getRandomModel(stageName)
    local gameplay = Workspace:FindFirstChild("Gameplay")
    if not gameplay then return nil end

    local itemSpawners = gameplay:FindFirstChild("ItemSpawners")
    if not itemSpawners then return nil end

    local stage = itemSpawners:FindFirstChild(stageName)
    if not stage then return nil end

    local models = {}
    for _, obj in ipairs(stage:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            table.insert(models, obj)
        end
    end

    if #models == 0 then return nil end
    return models[math.random(1, #models)]
end

-- 取得 Model 的 CFrame
local function getModelCFrame(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.CFrame
        end
        local part = model:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return model:GetPivot()
    elseif model:IsA("BasePart") then
        return model.CFrame
    end
    return nil
end

-- 觸發周圍的 ProximityPrompt
local function fireNearbyPrompts(range)
    range = range or 8
    local hrp = getHRP()
    if not hrp then return end

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local parent = desc.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (parent.Position - hrp.Position).Magnitude
                if dist <= range then
                    pcall(function()
                        fireproximityprompt(desc)
                    end)
                end
            end
        end
    end
end

-- 觸發 TouchInterest
local function fireTouchInterest(touchPart)
    local hrp = getHRP()
    if not hrp or not touchPart then return end

    pcall(function()
        firetouchinterest(touchPart, hrp, 0)
        task.wait(0.05)
        firetouchinterest(touchPart, hrp, 1)
    end)
end

-- 使用 Remote 觸發 Rebirth
local function doRebirth()
    local success, err = pcall(function()
        local event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RequestRebirth")
        event:FireServer()
    end)
    
    if success then
        print("[Auto Rebirth] 已觸發 Rebirth")
    else
        warn("[Auto Rebirth] 失敗:", err)
    end
end

-- Auto Collect 主迴圈
local function startAutoCollect()
    task.spawn(function()
        while autoCollectEnabled do
            local myPlot = getMyPlot()
            
            if myPlot then
                for _, floor in ipairs(myPlot:GetChildren()) do
                    if floor.Name:find("Floor") then
                        local slotsFolder = floor:FindFirstChild("Slots")
                        if slotsFolder then
                            for _, slot in ipairs(slotsFolder:GetChildren()) do
                                if slot.Name:find("Slot") then
                                    local collectTouch = slot:FindFirstChild("CollectTouch")
                                    if collectTouch then
                                        if collectTouch:IsA("BasePart") then
                                            fireTouchInterest(collectTouch)
                                        else
                                            local touchPart = collectTouch:FindFirstChildWhichIsA("BasePart")
                                            if touchPart then
                                                fireTouchInterest(touchPart)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                warn("[Auto Collect] 找不到自己的 Plot")
            end
            
            task.wait(0.6)
        end
    end)
end

-- Auto Animal 主迴圈（支援中途換 Stage）
local function startAutoAnimal()
    task.spawn(function()
        while autoAnimalEnabled do
            local currentStage = selectedStage
            local model = getRandomModel(currentStage)
            
            if model then
                local modelCF = getModelCFrame(model)
                if modelCF then
                    -- 1. 傳送到隨機 Model
                    teleportTo(modelCF + Vector3.new(0, 3, 0))
                    task.wait(0.25)

                    -- 2. 觸發 ProximityPrompt
                    fireNearbyPrompts(8)
                    task.wait(0.3)

                    -- 3. 傳回自己的 Plot
                    local plotCF = getPlotReturnCFrame()
                    if plotCF then
                        teleportTo(plotCF)
                    end

                    task.wait(0.5)
                else
                    task.wait(0.8)
                end
            else
                warn("[Auto Animal] 找不到 " .. currentStage .. " 的 Model")
                task.wait(1.5)
            end
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

-- ==================== UI ====================
local Hub = UIModule.CreateWindow("Skate For Animals", "TikTok: ValueHat")

-- Select Stage
Hub:CreateDropdown("Select Stage", stages, selectedStage, function(selected)
    selectedStage = selected
    print("[Select Stage] 已選擇: " .. tostring(selected))
end)

-- Auto Animal 開關
Hub:CreateToggle("Auto Animal", false, function(on)
    autoAnimalEnabled = on
    if on then
        startAutoAnimal()
        print("[Auto Animal] 已開啟")
    else
        print("[Auto Animal] 已關閉")
    end
end)

-- Auto Collect 開關
Hub:CreateToggle("Auto Collect", false, function(on)
    autoCollectEnabled = on
    if on then
        startAutoCollect()
        print("[Auto Collect] 已開啟")
    else
        print("[Auto Collect] 已關閉")
    end
end)

-- Auto Rebirth 開關
Hub:CreateToggle("Auto Rebirth", false, function(on)
    autoRebirthEnabled = on
    if on then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
