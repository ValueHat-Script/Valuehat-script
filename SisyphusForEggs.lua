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

local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false
local autoRebirthEnabled = false
local x2TrainEnabled = false

-- 尋找自己的 Plot
local function getMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local myName = LocalPlayer.Name

    for _, folder1 in ipairs(plots:GetChildren()) do
        for _, folder2 in ipairs(folder1:GetChildren()) do
            for _, obj in ipairs(folder2:GetDescendants()) do
                if obj.Name:find(myName) and obj.Name:find("FloatingPlotSign") then
                    return folder2
                end
            end
        end
    end

    return nil
end

-- 取得 Plot 裡的 Carpet CFrame
local function getCarpetCFrame(plot)
    if not plot then return nil end

    local carpet = plot:FindFirstChild("Carpet") or plot:FindFirstChild("Carpet", true)
    if carpet then
        if carpet:IsA("BasePart") then
            return carpet.CFrame
        elseif carpet:IsA("Model") then
            if carpet.PrimaryPart then
                return carpet.PrimaryPart.CFrame
            end
            local part = carpet:FindFirstChildWhichIsA("BasePart")
            if part then
                return part.CFrame
            end
        end
    end

    local parent = plot.Parent
    if parent then
        carpet = parent:FindFirstChild("Carpet")
        if carpet and carpet:IsA("BasePart") then
            return carpet.CFrame
        end
    end

    return nil
end

-- 尋找背包裡有 Egg 的 Tool
local function getEggTool()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil, nil end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("egg") or tool:GetAttribute("ItemType") == "Egg") then
            local entityId = tool:GetAttribute("EntityId")
            if entityId then
                return tool, tostring(entityId)
            end
        end
    end

    local character = LocalPlayer.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("egg") or tool:GetAttribute("ItemType") == "Egg") then
                local entityId = tool:GetAttribute("EntityId")
                if entityId then
                    return tool, tostring(entityId)
                end
            end
        end
    end

    return nil, nil
end

-- 裝備 Tool
local function equipTool(tool)
    local character = LocalPlayer.Character
    if not character or not tool then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(tool)
    end
end

-- PlaceEgg Remote
local function placeEgg(entityId, carpetCF)
    local success, err = pcall(function()
        local event = ReplicatedStorage
            .Packages
            ._Index["sleitnick_knit@1.7.0"]
            .knit
            .Services
            .EggService
            .RF
            .PlaceEgg

        event:InvokeServer(entityId, carpetCF)
    end)

    if success then
        print("[Auto Place] 成功放置:", entityId)
    else
        warn("[Auto Place] 失敗:", err)
    end
    return success
end

-- HatchEgg Remote
local function hatchEgg(eggId)
    local success, err = pcall(function()
        local event = ReplicatedStorage
            .Packages
            ._Index["sleitnick_knit@1.7.0"]
            .knit
            .Services
            .EggService
            .RF
            .HatchEgg

        event:InvokeServer(eggId)
    end)

    if success then
        print("[Auto Hatch] 成功孵化:", eggId)
    else
        warn("[Auto Hatch] 失敗:", err)
    end
    return success
end

-- EquipBest Remote
local function equipBest()
    local success, err = pcall(function()
        local event = ReplicatedStorage
            .Packages
            ._Index["sleitnick_knit@1.7.0"]
            .knit
            .Services
            .AnimalService
            .RF
            .EquipBest

        event:InvokeServer()
    end)

    if success then
        print("[Equip Best] 已裝備最佳")
    else
        warn("[Equip Best] 失敗:", err)
    end
    return success
end

-- Rebirth Remote
local function doRebirth()
    local success, err = pcall(function()
        local event = ReplicatedStorage
            .Packages
            ._Index["sleitnick_knit@1.7.0"]
            .knit
            .Services
            .RebirthService
            .RF
            .Rebirth

        event:InvokeServer()
    end)

    if success then
        print("[Auto Rebirth] 已轉生")
    else
        warn("[Auto Rebirth] 失敗:", err)
    end
    return success
end

-- 尋找 x2Strength 按鈕
local function getX2Button()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    for _, v in ipairs(playerGui:GetDescendants()) do
        if v.Name == "Button" and (v:IsA("ImageButton") or v:IsA("TextButton") or v:IsA("ImageLabel")) then
            if v.Parent and v.Parent.Name == "x2Strength" then
                return v
            end
        end
    end

    for _, v in ipairs(playerGui:GetDescendants()) do
        if v.Name == "x2Strength" then
            local btn = v:FindFirstChild("Button") or v:FindFirstChildWhichIsA("GuiButton")
            if btn then return btn end
            if v:IsA("GuiButton") then return v end
        end
    end

    return nil
end

-- Dex 風格觸發（只用 getconnections :Fire）
local function fireButtonDex(btn)
    if not btn then return false end
    if not getconnections then
        warn("[x2 Train] 此執行器不支援 getconnections")
        return false
    end

    local fired = false

    local events = {"MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated"}

    for _, eventName in ipairs(events) do
        local success, connections = pcall(function()
            return getconnections(btn[eventName])
        end)

        if success and connections then
            for _, conn in pairs(connections) do
                pcall(function()
                    if conn.Fire then
                        conn:Fire()
                        fired = true
                    elseif conn.Function then
                        conn.Function()
                        fired = true
                    end
                end)
            end
        end
    end

    return fired
end

-- 取得自己 Plot 的 Eggs
local function getPlotEggs(plot)
    if not plot then return {} end

    local eggsFolder = plot:FindFirstChild("Eggs") or plot:FindFirstChild("Eggs", true)
    if not eggsFolder then return {} end

    local eggs = {}
    for _, obj in ipairs(eggsFolder:GetChildren()) do
        if obj:IsA("Model") then
            local eggId = obj:GetAttribute("EggId")
            if eggId then
                table.insert(eggs, {
                    model = obj,
                    eggId = tostring(eggId)
                })
            end
        end
    end
    return eggs
end

-- Auto Place 主迴圈
local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local myPlot = getMyPlot()
            
            if myPlot then
                local carpetCF = getCarpetCFrame(myPlot)
                
                if carpetCF then
                    local tool, entityId = getEggTool()
                    
                    if tool and entityId then
                        equipTool(tool)
                        task.wait(0.3)
                        placeEgg(entityId, carpetCF)
                        task.wait(0.8)
                    else
                        warn("[Auto Place] 背包裡找不到有 EntityId 的 Egg Tool")
                        task.wait(1.5)
                    end
                else
                    warn("[Auto Place] 找不到 Carpet")
                    task.wait(1.5)
                end
            else
                warn("[Auto Place] 找不到自己的 Plot")
                task.wait(2)
            end
        end
    end)
end

-- Auto Hatch 主迴圈
local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            local myPlot = getMyPlot()
            
            if myPlot then
                local eggs = getPlotEggs(myPlot)
                
                if #eggs > 0 then
                    for _, eggData in ipairs(eggs) do
                        if not autoHatchEnabled then break end
                        hatchEgg(eggData.eggId)
                        task.wait(0.5)
                    end
                    task.wait(0.6)
                else
                    print("[Auto Hatch] 目前沒有可孵化的蛋")
                    task.wait(1.5)
                end
            else
                warn("[Auto Hatch] 找不到自己的 Plot")
                task.wait(2)
            end
        end
    end)
end

-- Equip Best 主迴圈
local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            equipBest()
            task.wait(2)
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

-- x2 Train 主迴圈（Dex 觸發）
local function startX2Train()
    task.spawn(function()
        while x2TrainEnabled do
            local btn = getX2Button()
            
            if btn then
                local ok = fireButtonDex(btn)
                if ok then
                    print("[x2 Train] Dex 觸發成功:", btn:GetFullName())
                else
                    warn("[x2 Train] 沒有可 Fire 的 connections")
                end
            else
                warn("[x2 Train] 找不到 x2Strength 按鈕")
            end
            
            task.wait(0.5)
        end
    end)
end

-- ==================== UI ====================
local Hub = UIModule.CreateWindow("Sisyphus For Eggs", "TikTok: ValueHat")

Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then
        startAutoPlace()
        print("[Auto Place] 已開啟")
    else
        print("[Auto Place] 已關閉")
    end
end)

Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then
        startAutoHatch()
        print("[Auto Hatch] 已開啟")
    else
        print("[Auto Hatch] 已關閉")
    end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        startEquipBest()
        print("[Equip Best] 已開啟")
    else
        print("[Equip Best] 已關閉")
    end
end)

Hub:CreateToggle("Auto Rebirth", false, function(on)
    autoRebirthEnabled = on
    if on then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

Hub:CreateToggle("x2 Train", false, function(on)
    x2TrainEnabled = on
    if on then
        startX2Train()
        print("[x2 Train] 已開啟")
    else
        print("[x2 Train] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
