local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local zones = {"Ancient", "Candy", "Crystal", "Desert", "Haunted", "Heaven", "Jungle", "Meadow", "Snow", "Space", "Volcano"}
local selectedZone = zones[1]
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false

local customSpawnCf = CFrame.new(198, 4, 277)

local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = cf
        end
    end
end

-- Auto Egg 邏輯
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local guardVisuals = Workspace:FindFirstChild("_GuardVisuals")
            local zoneModel = guardVisuals and guardVisuals:FindFirstChild(selectedZone)
            
            if zoneModel then
                local targetCf = zoneModel:GetPivot() or (zoneModel:IsA("Model") and zoneModel.PrimaryPart and zoneModel.PrimaryPart.CFrame)
                if targetCf then
                    teleportTo(targetCf + Vector3.new(0, 5, 0))
                    task.wait(1.5)
                end

                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local eggs = {}
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and string.find(string.lower(obj.Name), "egg") then
                            local eggCf = obj:GetPivot()
                            if eggCf then
                                local dist = (eggCf.Position - hrp.Position).Magnitude
                                if dist < 150 then
                                    table.insert(eggs, {model = obj, cf = eggCf, dist = dist})
                                end
                            end
                        end
                    end
                    
                    table.sort(eggs, function(a, b)
                        return a.dist < b.dist
                    end)

                    for _, eggData in ipairs(eggs) do
                        if not autoEggEnabled then break end
                        
                        teleportTo(eggData.cf + Vector3.new(0, 3, 0))
                        task.wait(0.5)
                        
                        for _, part in ipairs(eggData.model:GetDescendants()) do
                            local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and fireproximityprompt then
                                fireproximityprompt(prompt)
                            end
                        end
                        
                        task.wait(0.3)
                        teleportTo(customSpawnCf)
                        task.wait(1)
                    end
                end
            end
            teleportTo(customSpawnCf)
            task.wait(1.5)
        end
    end)
end

-- Auto Place 邏輯 (只放名稱含有 Egg 的 Tool)
local function startAutoPlace()
    task.spawn(function()
        local placeEvent = ReplicatedStorage:FindFirstChild("_Net") and ReplicatedStorage._Net:FindFirstChild("PlacePet")
        
        while autoPlaceEnabled do
            if placeEvent then
                local itemsToPlace = {}
                local searchContainers = {LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}
                
                for _, container in ipairs(searchContainers) do
                    if container then
                        for _, item in ipairs(container:GetChildren()) do
                            -- 只處理名稱含有 "Egg" 的 Tool
                            if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
                                local uid = item:GetAttribute("petUID") or item:GetAttribute("UID")
                                if not uid then
                                    local uidObj = item:FindFirstChild("petUID") or item:FindFirstChild("UID")
                                    if uidObj then
                                        uid = uidObj.Value
                                    end
                                end
                                if uid then
                                    table.insert(itemsToPlace, uid)
                                end
                            end
                        end
                    end
                end
                
                for _, uid in ipairs(itemsToPlace) do
                    if not autoPlaceEnabled then break end
                    pcall(function()
                        placeEvent:FireServer(uid, -48.102119445800781, -8.845088005065918)
                    end)
                    task.wait(0.5)
                end
            end
            task.wait(1)
        end
    end)
end

-- Auto Hatch 邏輯 (修正路徑 + 自動找自己名字)
local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            local openEggEvent = ReplicatedStorage:FindFirstChild("_Net") and ReplicatedStorage._Net:FindFirstChild("OpenEgg")
            
            if openEggEvent then
                local playerName = LocalPlayer.Name
                
                -- 正確路徑: Workspace.Live.PlayerFriends 或直接找 PlayerFriends
                local live = Workspace:FindFirstChild("Live")
                local playerFriends = (live and live:FindFirstChild("PlayerFriends")) or Workspace:FindFirstChild("PlayerFriends")
                
                local targetFolder = playerFriends and playerFriends:FindFirstChild(playerName)
                
                if targetFolder then
                    for _, child in ipairs(targetFolder:GetChildren()) do
                        if not autoHatchEnabled then break end
                        
                        local eggId = child.Name
                        -- GUID 通常很長，過濾一下
                        if eggId and #eggId > 10 then
                            pcall(function()
                                openEggEvent:FireServer(eggId)
                            end)
                            task.wait(0.25)
                        end
                    end
                end
            end
            task.wait(0.8)
        end
    end)
end

-- Equip Best 邏輯
local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            local equipEvent = ReplicatedStorage:FindFirstChild("_Net") and ReplicatedStorage._Net:FindFirstChild("EquipBestPets")
            if equipEvent then
                pcall(function()
                    equipEvent:FireServer()
                end)
            end
            task.wait(1)
        end
    end)
end

-- UI 建置
local Hub = UIModule.CreateWindow("Lift Rock For Eggs", "TikTok: ValueHat")

Hub:CreateDropdown("Select Zone", zones, selectedZone, function(selected)
    selectedZone = selected
end)

Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then
        startAutoEgg()
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
