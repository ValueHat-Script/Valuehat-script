-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- RemoteFunctions 定位
local combatServices = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")

local StartRF = combatServices:WaitForChild("Start")
local BeginRoundRF = combatServices:WaitForChild("BeginRound")
local WakeUpRF = combatServices:WaitForChild("WakeUp")
local CaughtRF = combatServices:WaitForChild("Caught")
local ProceedTransitionRF = combatServices:WaitForChild("ProceedTransition")
local FinishRF = combatServices:WaitForChild("Finish")
local ClaimRunEggRF = combatServices:WaitForChild("ClaimRunEgg")

-- Egg Service
local eggServices = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("EggService")
    :WaitForChild("RF")

local PlaceEggRF = eggServices:WaitForChild("PlaceEgg")

-- Animal Service
local animalServices = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("AnimalService")
    :WaitForChild("RF")

local EquipBestRF = animalServices:WaitForChild("EquipBest")

-- 控制變數
local selectedRound = 1
local autoPlayEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false
local x2TrainEnabled = false

-- 選項列表 1 ~ 7
local roundList = {}
for i = 1, 7 do
    table.insert(roundList, tostring(i))
end

-- ==================== x2 Train 邏輯 ====================

local function clickButton(btn)
    if not btn then return end
    
    -- 1. 優先使用 Executor 支持的 firesignal
    if firesignal then
        if btn.Activated then
            pcall(function() firesignal(btn.Activated) end)
        end
        if btn.MouseButton1Click then
            pcall(function() firesignal(btn.MouseButton1Click) end)
        end
        if btn.MouseButton1Down then
            pcall(function() firesignal(btn.MouseButton1Down) end)
        end
    else
        -- 2. 備用方案: 發送 VirtualUser / Event 點擊
        pcall(function()
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                conn:Fire()
            end
            for _, conn in ipairs(getconnections(btn.Activated)) do
                conn:Fire()
            end
        end)
    end
end

local function startX2Train()
    task.spawn(function()
        while x2TrainEnabled do
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                -- 尋找 x2Speed 下的 Button 或是名為 Button/x2Speed 的按鈕
                local targetBtn = nil
                
                -- 精準位置搜尋: SpeedEffect -> LeftContainer -> Currency -> Speed -> x2Speed -> Button
                for _, gui in ipairs(playerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        local x2SpeedObj = gui:FindFirstChild("x2Speed", true)
                        if x2SpeedObj then
                            targetBtn = x2SpeedObj:FindFirstChild("Button") or x2SpeedObj
                            if targetBtn then break end
                        end
                    end
                end

                -- 按鈕點擊
                if targetBtn and targetBtn:IsA("GuiButton") then
                    clickButton(targetBtn)
                end
            end

            task.wait(0.1)
        end
    end)
end

-- ==================== Equip Best 邏輯 ====================

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            pcall(function()
                EquipBestRF:InvokeServer()
            end)
            task.wait(2)
        end
    end)
end

-- ==================== Plot 輔助邏輯 ====================

local function getMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("SurfaceGui") or desc:IsA("TextButton") then
                if desc.Text and (desc.Text:find("Your base") or desc.Text:find(LocalPlayer.Name)) then
                    return plot
                end
            end
        end

        if plot.Name:find(LocalPlayer.Name) or plot:GetAttribute("Owner") == LocalPlayer.UserId then
            return plot
        end
    end

    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("SignPlaceholder", true)
        if sign and sign:FindFirstChildWhichIsA("TextLabel", true) then
            local label = sign:FindFirstChildWhichIsA("TextLabel", true)
            if label.Text:find("Your base") or label.Text:find(LocalPlayer.Name) then
                return plot
            end
        end
    end

    return nil
end

local function getMyPlotSurface()
    local myPlot = getMyPlot()
    if myPlot then
        return myPlot:FindFirstChild("PlotSurface", true)
    end
    return nil
end

-- ==================== Auto Hatch 邏輯 (判斷 Ready!) ====================

local function isEggReady(eggModel)
    local billboard = eggModel:FindFirstChild("PlacedEggBillboard", true)
    if billboard then
        local timerLabel = billboard:FindFirstChild("Timer", true)
        if timerLabel and (timerLabel:IsA("TextLabel") or timerLabel:IsA("TextButton")) then
            if timerLabel.Text and timerLabel.Text:find("Ready") then
                return true
            end
        end
    end

    for _, desc in ipairs(eggModel:GetDescendants()) do
        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text then
            if desc.Name == "Timer" and desc.Text:find("Ready") then
                return true
            end
        end
    end

    return false
end

local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            local myPlot = getMyPlot()
            if myPlot then
                local eggsFolder = myPlot:FindFirstChild("Eggs", true)
                if eggsFolder then
                    for _, eggModel in ipairs(eggsFolder:GetChildren()) do
                        if not autoHatchEnabled then break end

                        if isEggReady(eggModel) then
                            for _, desc in ipairs(eggModel:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") then
                                    pcall(function()
                                        fireproximityprompt(desc)
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end
            else
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local model = obj:FindFirstAncestorOfClass("Model")
                        if model and isEggReady(model) then
                            pcall(function()
                                fireproximityprompt(obj)
                            end)
                        end
                    end
                end
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== Auto Place 邏輯 (僅限裝備 Egg) ====================

local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local character = LocalPlayer.Character
            local backpack = LocalPlayer:FindFirstChild("Backpack")

            if character and backpack then
                local plotSurface = getMyPlotSurface()

                if plotSurface then
                    local targetCFrame = plotSurface:IsA("BasePart") and plotSurface.CFrame or plotSurface:GetPivot()

                    local eggTool = nil

                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name:lower():find("egg") then
                            eggTool = tool
                            break
                        end
                    end

                    if not eggTool then
                        for _, tool in ipairs(character:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name:lower():find("egg") then
                                eggTool = tool
                                break
                            end
                        end
                    end

                    if eggTool then
                        local entityId = eggTool:GetAttribute("EntityId") or eggTool.Name

                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid and eggTool.Parent == backpack then
                            humanoid:EquipTool(eggTool)
                            task.wait(0.2)
                        end

                        pcall(function()
                            PlaceEggRF:InvokeServer(entityId, targetCFrame)
                        end)
                    end
                else
                    warn("[Auto Place] 找不到您的 PlotSurface Base")
                end
            end

            task.wait(1)
        end
    end)
end

-- ==================== Auto Play 邏輯 ====================

local function startClaimRunEggBackground()
    task.spawn(function()
        while autoPlayEnabled do
            pcall(function()
                ClaimRunEggRF:InvokeServer()
            end)
            task.wait()
        end
    end)
end

local function startAutoPlay()
    startClaimRunEggBackground()

    task.spawn(function()
        while autoPlayEnabled do
            local loops = tonumber(selectedRound) or 1

            pcall(function()
                StartRF:InvokeServer()
            end)
            task.wait(2)

            for i = 1, loops do
                if not autoPlayEnabled then break end

                pcall(function()
                    BeginRoundRF:InvokeServer()
                end)
                task.wait(0.2)

                pcall(function()
                    WakeUpRF:InvokeServer()
                end)
                task.wait(0.2)

                pcall(function()
                    CaughtRF:InvokeServer()
                end)
                task.wait(0.2)

                pcall(function()
                    ProceedTransitionRF:InvokeServer()
                end)
                task.wait(0.5)
            end

            if autoPlayEnabled then
                pcall(function()
                    FinishRF:InvokeServer()
                end)
            end

            task.wait(1)
        end
    end)
end

-- ==================== UI 介面 ====================

local Hub = UIModule.CreateWindow("Don't steal my eggs", "TikTok: ValueHat")

Hub:CreateDropdown("Select Round", roundList, tostring(selectedRound), function(v)
    selectedRound = tonumber(v) or 1
end)

Hub:CreateToggle("Auto Play", false, function(on)
    autoPlayEnabled = on
    if on then
        startAutoPlay()
    end
end)

Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then
        startAutoPlace()
    end
end)

Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then
        startAutoHatch()
    end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        startEquipBest()
    end
end)

Hub:CreateToggle("x2 Train", false, function(on)
    x2TrainEnabled = on
    if on then
        startX2Train()
    end
end)
