local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local autoEggEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false
local x2TrainEnabled = false
local selectedArea = nil

-- 影片中出現的正確區域列表[span_0](start_span)[span_0](end_span)
local videoZones = {
    "Enchanted Meadow", "Siren Reef", "Frost Peaks", "Sphinx Desert", 
    "Dragon Mines", "Hydra Jungle", "Spirit Isles", "Primal Lands", 
    "Olympus Heights", "Inferno Caldera", "Abyssal Trench", "Storm Citadel", 
    "Crystal Sanctum", "Shadow Necropolis", "Glacier Throne", "Venom Marsh", 
    "Cosmic Rift", "Dragon Throne"
}

-- 傳送函數
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

-- 取得返回點 (workspace.Map.SafeZone.SafeZoneBaseplate)
local function getReturnPosition()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local safeZone = map:FindFirstChild("SafeZone")
        if safeZone then
            local baseplate = safeZone:FindFirstChild("SafeZoneBaseplate")
            if baseplate and baseplate:IsA("BasePart") then
                return baseplate.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.CFrame
    end
    return nil
end

-- 判斷座標是否在選擇的區域內
local function isPositionInArea(pos, areaName)
    local spawns = Workspace:FindFirstChild("Spawns")
    if not spawns then return false end
    local area = spawns:FindFirstChild(areaName)
    if not area then return false end

    local cf, size
    if area:IsA("BasePart") then
        cf, size = area.CFrame, area.Size
    elseif area:IsA("Model") then
        cf, size = area:GetBoundingBox()
    end

    if cf and size then
        local localPos = cf:PointToObjectSpace(pos)
        return math.abs(localPos.X) <= (size.X / 2) * 2 and
               math.abs(localPos.Y) <= (size.Y / 2) * 2 and
               math.abs(localPos.Z) <= (size.Z / 2) * 2
    end
    return false
end

-- 取得蛋的位置
local function getEggCFrame(egg)
    if egg:IsA("Model") then
        if egg.PrimaryPart then return egg.PrimaryPart.CFrame end
        local root = egg:FindFirstChild("RootPart") or egg:FindFirstChildWhichIsA("BasePart")
        if root then return root.CFrame end
        return egg:GetPivot()
    elseif egg:IsA("BasePart") then
        return egg.CFrame
    end
    return nil
end

-- 準確取得玩家專屬 Plot 的 CenterPoint 座標 (位於 Workspace.Map.Plots)[span_1](start_span)[span_1](end_span)[span_2](start_span)[span_2](end_span)
local function getPlayerCenterPoint()
    local map = Workspace:FindFirstChild("Map")
    local plots = map and map:FindFirstChild("Plots")
    if not plots then return nil end

    -- 方法 1：透過 PlayerName 尋找專屬 Plot
    for _, plot in ipairs(plots:GetChildren()) do
        local playerPlotSign = plot:FindFirstChild("PlayerPlotSign", true)
        if playerPlotSign then
            local playerNameText = playerPlotSign:FindFirstChild("PlayerName", true)
            if playerNameText and playerNameText:IsA("TextLabel") then
                if playerNameText.Text == LocalPlayer.Name then
                    local centerPoint = plot:FindFirstChild("CenterPoint", true)
                    if centerPoint then
                        if centerPoint:IsA("BasePart") then
                            return centerPoint.Position
                        elseif centerPoint:IsA("Attachment") then
                            return centerPoint.WorldPosition
                        elseif centerPoint:IsA("Model") then
                            return centerPoint:GetPivot().Position
                        else
                            local success, pos = pcall(function() return centerPoint.Position end)
                            if success and pos then return pos end
                        end
                    end
                end
            end
        end
    end

    -- 方法 2：如果找不到名稱標籤，則尋找距離玩家最近的 Plot 之 CenterPoint
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local closestCenter = nil
    local minDistance = math.huge

    for _, plot in ipairs(plots:GetChildren()) do
        local centerPoint = plot:FindFirstChild("CenterPoint", true)
        if centerPoint then
            local pos = nil
            if centerPoint:IsA("BasePart") then
                pos = centerPoint.Position
            elseif centerPoint:IsA("Attachment") then
                pos = centerPoint.WorldPosition
            elseif centerPoint:IsA("Model") then
                pos = centerPoint:GetPivot().Position
            else
                pcall(function() pos = centerPoint.Position end)
            end

            if pos then
                if hrp then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestCenter = pos
                    end
                else
                    return pos
                end
            end
        end
    end

    return closestCenter
end

-- 尋找並自動裝備背包中的蛋工具，並透過 EggId 取得 ID
local function equipAndGetEggId()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local targetTool = nil
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Model") then
                if item.Name:match("Egg") or item:GetAttribute("EggId") or item:FindFirstChild("EggId") then
                    targetTool = item
                    break
                end
            end
        end
    end
    
    if not targetTool and character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Model") then
                if item.Name:match("Egg") or item:GetAttribute("EggId") or item:FindFirstChild("EggId") then
                    targetTool = item
                    break
                end
            end
        end
    end
    
    if targetTool then
        if targetTool.Parent == backpack and character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and targetTool:IsA("Tool") then
                humanoid:EquipTool(targetTool)
            end
        end
        
        local attr = targetTool:GetAttribute("EggId")
        if attr then
            return tostring(attr)
        end
        
        local val = targetTool:FindFirstChild("EggId")
        if val and val:IsA("ValueBase") then
            return tostring(val.Value)
        end
        
        return targetTool.Name
    end
    return nil
end

-- Auto Egg 主迴圈
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            if selectedArea then
                local worldEggs = Workspace:FindFirstChild("WorldEggs")
                if worldEggs then
                    local found = false
                    for _, egg in ipairs(worldEggs:GetChildren()) do
                        if not autoEggEnabled then break end
                        if egg:IsA("Model") or egg:IsA("BasePart") then
                            local eggCf = getEggCFrame(egg)
                            if eggCf and isPositionInArea(eggCf.Position, selectedArea) then
                                found = true
                                local returnCF = getReturnPosition()

                                -- 1. 傳送到蛋上方 5 格
                                teleportTo(eggCf + Vector3.new(0, 5, 0))
                                task.wait(0.3)

                                -- 2. 觸發周圍 5 格內的 ProximityPrompt
                                local character = LocalPlayer.Character
                                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    for _, desc in ipairs(Workspace:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then
                                            local promptPart = desc.Parent
                                            if promptPart and promptPart:IsA("BasePart") then
                                                if (promptPart.Position - hrp.Position).Magnitude <= 5 then
                                                    pcall(function()
                                                        fireproximityprompt(desc)
                                                    end)
                                                end
                                            end
                                        end
                                    end
                                end

                                -- 3. 傳回 SafeZoneBaseplate
                                if returnCF then
                                    teleportTo(returnCF)
                                end
                                task.wait(0.6)
                                break
                            end
                        end
                    end
                    if not found then
                        task.wait(1)
                    end
                else
                    task.wait(2)
                end
            else
                task.wait(1)
            end
        end
    end)
end

-- Auto Place 主迴圈
local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local eggId = equipAndGetEggId()
            local centerPos = getPlayerCenterPoint()
            
            if eggId and centerPos then
                local event = ReplicatedStorage:FindFirstChild("SharedModules") 
                    and ReplicatedStorage.SharedModules:FindFirstChild("Net") 
                    and ReplicatedStorage.SharedModules.Net:FindFirstChild("RF/Egg_Place")
                
                if event then
                    pcall(function()
                        event:InvokeServer(eggId, centerPos)
                    end)
                    pcall(function()
                        event:InvokeServer(eggId, centerPos.X, centerPos.Z)
                    end)
                end
            end
            task.wait(1)
        end
    end)
end

-- Auto Hatch 主迴圈
local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            local penEggs = Workspace:FindFirstChild("PenEggs")
            if penEggs then
                for _, eggObj in ipairs(penEggs:GetChildren()) do
                    if not autoHatchEnabled then break end
                    
                    local eggId = nil
                    if eggObj:GetAttribute("EggId") then
                        eggId = tostring(eggObj:GetAttribute("EggId"))
                    elseif eggObj:FindFirstChild("EggId") then
                        local val = eggObj:FindFirstChild("EggId")
                        if val:IsA("ValueBase") then eggId = tostring(val.Value) end
                    else
                        local matchId = eggObj.Name:match("^Egg_(.*)")
                        if matchId then
                            eggId = matchId
                        else
                            eggId = eggObj.Name
                        end
                    end

                    if eggId then
                        pcall(function()
                            local openEvent = ReplicatedStorage:FindFirstChild("SharedModules") 
                                and ReplicatedStorage.SharedModules:FindFirstChild("Net") 
                                and ReplicatedStorage.SharedModules.Net:FindFirstChild("RF/Egg_Open")
                            if openEvent then
                                openEvent:InvokeServer(eggId)
                            end
                        end)
                        task.wait(0.4)
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- Equip Best 主迴圈
local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            pcall(function()
                local bestEvent = ReplicatedStorage:FindFirstChild("SharedModules") 
                    and ReplicatedStorage.SharedModules:FindFirstChild("Net") 
                    and ReplicatedStorage.SharedModules.Net:FindFirstChild("RF/Pen_PlaceBest")
                if bestEvent then
                    bestEvent:InvokeServer()
                end
            end)
            task.wait(1)
        end
    end)
end

-- x2 Train 主迴圈 (自動點擊 TrainingBonus)
local function startX2Train()
    task.spawn(function()
        while x2TrainEnabled do
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    local trainingBonus = playerGui:FindFirstChild("TrainingBonus", true)
                    if trainingBonus then
                        local detector = trainingBonus:FindFirstChild("Detector", true)
                        if detector then
                            -- 優先觸發 GuiButton 點擊事件或呼叫滑鼠點擊
                            for _, connection in ipairs(getconnections(detector.Activated) or {}) do
                                connection:Fire()
                            end
                            for _, connection in ipairs(getconnections(detector.MouseButton1Click) or {}) do
                                connection:Fire()
                            end
                        end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

-- 建立 ValueHat UI
local Hub = UIModule.CreateWindow("Pogo For Animals", "TikTok: ValueHat")

selectedArea = videoZones[1]

-- 下拉選單
Hub:CreateDropdown("Select Area", videoZones, selectedArea, function(selected)
    selectedArea = selected
    print("[Select Area] 已選擇: " .. tostring(selected))
end)

-- Auto Egg 開關按鈕
Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then startAutoEgg() end
end)

-- Auto Place 開關按鈕
Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then startAutoPlace() end
end)

-- Auto Hatch 開關按鈕
Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then startAutoHatch() end
end)

-- Equip Best 開關按鈕
Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then startEquipBest() end
end)

-- x2 Train 開關按鈕
Hub:CreateToggle("x2 Train", false, function(on)
    x2TrainEnabled = on
    if on then startX2Train() end
end)
