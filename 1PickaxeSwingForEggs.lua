local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local instantEggEnabled = false
local autoPlaceEnabled = false
local autoOpenEnabled = false
local equipBestEnabled = false
local zoneIndex = 1

-- 依照影片正確排序的區域順序
local hardcodedZones = {
    "Forest", "Rock", "Desert", "Jungle", "Snow", 
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic", "Blossom"
}

-- 傳送
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = cf
        end
    end
end

-- 取得指定的傳送點 (workspace.NewMap.Model.__OBJECTS.Build.MainMap.Bases.Part)
local function getTargetBasePartCF()
    local newMap = Workspace:FindFirstChild("NewMap")
    if newMap then
        local model = newMap:FindFirstChild("Model")
        if model then
            local objects = model:FindFirstChild("__OBJECTS")
            if objects then
                local build = objects:FindFirstChild("Build")
                if build then
                    local mainMap = build:FindFirstChild("MainMap")
                    if mainMap then
                        local bases = mainMap:FindFirstChild("Bases")
                        if bases then
                            local part = bases:FindFirstChild("Part")
                            if part and part:IsA("BasePart") then
                                return part.CFrame
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- 取得區域資訊 (CFrame + Size)
local function getZoneInfo(zoneName)
    local newMap = Workspace:FindFirstChild("NewMap")
    local zoneBounds = newMap and newMap:FindFirstChild("ZoneBounds") or Workspace:FindFirstChild("ZoneBounds")
    if not zoneBounds then return nil end

    local zone = zoneBounds:FindFirstChild(zoneName)
    if not zone then return nil end

    local cf, size

    if zone:IsA("BasePart") then
        cf = zone.CFrame
        size = zone.Size
    elseif zone:IsA("Model") then
        if zone.PrimaryPart then
            cf = zone.PrimaryPart.CFrame
            size = zone.PrimaryPart.Size
        else
            local best, bestSize = nil, 0
            for _, d in ipairs(zone:GetDescendants()) do
                if d:IsA("BasePart") and d.Size.Magnitude > bestSize then
                    best = d
                    bestSize = d.Size.Magnitude
                end
            end
            if best then
                cf = best.CFrame
                size = best.Size
            else
                cf = zone:GetPivot()
                size = Vector3.new(120, 60, 120)
            end
        end
    end

    return cf, size
end

-- 找蛋的 Prompt
local function findEggPrompt(eggModel)
    if not eggModel then return nil end
    local prompt = eggModel:FindFirstChild("StealPrompt", true)
    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end
    return eggModel:FindFirstChildWhichIsA("ProximityPrompt", true)
end

-- 取得蛋位置
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

-- Instant Steal Egg 主迴圈：偵測 Live.Friends 內的蛋，範圍內觸發後立刻傳送回指定位置
local function startInstantStealEgg()
    task.spawn(function()
        while instantEggEnabled do
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                task.wait(1)
                continue
            end

            local live = Workspace:FindFirstChild("Live")
            local friends = live and live:FindFirstChild("Friends")
            
            if friends then
                for _, obj in ipairs(friends:GetChildren()) do
                    if not instantEggEnabled then break end
                    if obj:IsA("Model") then
                        local eggCf = getEggCFrame(obj)
                        if eggCf then
                            local pos1 = Vector2.new(eggCf.Position.X, eggCf.Position.Z)
                            local pos2 = Vector2.new(hrp.Position.X, hrp.Position.Z)
                            local dist = (pos1 - pos2).Magnitude

                            if dist <= 8 then
                                local prompt = findEggPrompt(obj)
                                if prompt then
                                    pcall(function()
                                        fireproximityprompt(prompt)
                                        print("[Instant Steal] 成功觸發蛋: " .. obj.Name)
                                    end)

                                    -- 觸發完後立刻傳送到指定位置
                                    local targetCF = getTargetBasePartCF()
                                    if targetCF then
                                        teleportTo(targetCF + Vector3.new(0, 3, 0))
                                    end
                                    
                                    task.wait(0.5)
                                    break
                                end
                            end
                        end
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

-- 取得玩家在 Plots 中的 Base 座標
local function getPlayerBasePosition()
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local owner = plot:FindFirstChild("owner")
            if owner and (owner:IsA("StringValue") or owner:IsA("ObjectValue") or owner:IsA("ValueBase")) then
                if tostring(owner.Value) == LocalPlayer.Name then
                    local basePart = plot:FindFirstChild("Base", true)
                    if basePart and basePart:IsA("BasePart") then
                        return basePart.Position
                    end
                end
            end
        end
    end
    return nil
end

-- 自動裝備有 Egg 字樣的 Tool 並取得 friendUID
local function getEggToolInfo()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local function checkItem(item)
        if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
            local friendUID = item:GetAttribute("friendUID")
            if friendUID then
                return item, friendUID
            end
        end
    end

    if character then
        for _, child in ipairs(character:GetChildren()) do
            local tool, uid = checkItem(child)
            if tool and uid then return tool, uid end
        end
    end

    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            local tool, uid = checkItem(child)
            if tool and uid then
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid:EquipTool(tool)
                end
                return tool, uid
            end
        end
    end

    return nil, nil
end

-- Auto Place 主迴圈
local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local basePos = getPlayerBasePosition()
            local _, friendUID = getEggToolInfo()

            if basePos and friendUID then
                pcall(function()
                    local placeEvent = ReplicatedStorage.SharedModules.Network.Remotes["Place Friend"]
                    if placeEvent then
                        placeEvent:FireServer(friendUID, basePos.X, basePos.Z)
                    end
                end)
            end

            task.wait(2)
        end
    end)
end

-- Auto Open 主迴圈：從 Live.PlayerFriends 中讀取玩家自己的資料夾並開箱
local function startAutoOpen()
    task.spawn(function()
        while autoOpenEnabled do
            local live = Workspace:FindFirstChild("Live")
            local playerFriends = live and live:FindFirstChild("PlayerFriends")
            
            if playerFriends then
                local playerFolder = playerFriends:FindFirstChild(LocalPlayer.Name)
                if playerFolder then
                    local openEvent = ReplicatedStorage.SharedModules.Network.Remotes:FindFirstChild("Open Lucky Block")
                    if openEvent then
                        for _, obj in ipairs(playerFolder:GetChildren()) do
                            if not autoOpenEnabled then break end
                            pcall(function()
                                openEvent:FireServer(obj.Name)
                            end)
                            task.wait(0.2)
                        end
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
                local equipEvent = ReplicatedStorage.SharedModules.Network.Remotes:FindFirstChild("Equip Best")
                if equipEvent then
                    equipEvent:FireServer()
                end
            end)
            task.wait(2)
        end
    end)
end

-- UI
local Hub = UIModule.CreateWindow("+1 Pickaxe Swing For Eggs", "TikTok: ValueHat")

Hub:CreateButton("Next Zone", function()
    zoneIndex = zoneIndex + 1
    if zoneIndex > #hardcodedZones then
        zoneIndex = 1
    end
    local zoneName = hardcodedZones[zoneIndex]
    local cf, size = getZoneInfo(zoneName)
    if cf then
        teleportTo(cf + Vector3.new(0, 5, 0))
        print("[Zone] 已傳送到: " .. zoneName)
    else
        warn("[Zone] 找不到區域: " .. zoneName)
    end
end)

Hub:CreateToggle("Instant Steal Egg", false, function(on)
    instantEggEnabled = on
    if on then
        print("[Instant Steal Egg] 已開啟")
        startInstantStealEgg()
    else
        print("[Instant Steal Egg] 已關閉")
    end
end)

Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then
        print("[Auto Place] 已開啟")
        startAutoPlace()
    else
        print("[Auto Place] 已關閉")
    end
end)

Hub:CreateToggle("Auto Open", false, function(on)
    autoOpenEnabled = on
    if on then
        print("[Auto Open] 已開啟")
        startAutoOpen()
    else
        print("[Auto Open] 已關閉")
    end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        print("[Equip Best] 已開啟")
        startEquipBest()
    else
        print("[Equip Best] 已關閉")
    end
end)
