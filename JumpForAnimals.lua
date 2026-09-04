-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("jump for animals", "TikTok: ValueHat")

-- 變數設定
local selectedRarity = "Common"
local selectedArea = "Meadow 1"
local autoEggEnabled = false
local autoTrainEnabled = false

-- 追蹤最後一次收到信號的時間
local lastSignalTime = tick()

-- 稀有度清單
local rarities = {
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Divine",
    "Celestial",
    "Eternal",
    "Exclusive"
}

-- 地區選單清單
local areaList = {
    "Celestial Heights 1", "Celestial Heights 2",
    "Coral Reef 1", "Coral Reef 2",
    "Crystal Mines 1", "Crystal Mines 2",
    "Desert 1", "Desert 2",
    "Jungle 1", "Jungle 2",
    "Meadow 1", "Meadow 2",
    "Mystic Isles 1", "Mystic Isles 2",
    "Prehistoric 1", "Prehistoric 2",
    "Winter 1", "Winter 2"
}

-- 解析選擇項目
local function parseAreaSelection(selection)
    local rawName, num = selection:match("^(.-)%s*(%d+)$")
    if not rawName then
        return selection, "1"
    end
    
    local nameMap = {
        ["Celestial Heights"] = "Celestial Heights",
        ["Coral Reef"] = "Coral Reef",
        ["Crystal Mines"] = "Crystal Mines",
        ["Desert"] = "Desert",
        ["Jungle"] = "Jungle",
        ["Meadow"] = "Meadow",
        ["Mystic Isles"] = "Mystic Isles",
        ["Prehistoric"] = "Prehistoric",
        ["Winter"] = "Winter"
    }
    
    return nameMap[rawName] or rawName, num
end

-- 取得玩家重生點
local function getPlayerSpawnCFrame()
    local player = game.Players.LocalPlayer
    
    if player.RespawnLocation and player.RespawnLocation:IsA("BasePart") then
        return player.RespawnLocation.CFrame
    end
    
    local spawn = workspace:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("Spawn", true)
    if spawn and spawn:IsA("BasePart") then
        return spawn.CFrame
    end
    
    local plots = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Bases")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local owner = plot:FindFirstChild("Owner") or plot:GetAttribute("Owner")
            if (owner and tostring(owner.Value or owner) == player.Name) or plot.Name == player.Name then
                local plotSpawn = plot:FindFirstChild("SpawnLocation", true) or plot:FindFirstChild("Spawn", true)
                if plotSpawn and plotSpawn:IsA("BasePart") then
                    return plotSpawn.CFrame
                end
                return plot:GetPivot()
            end
        end
    end
    
    return nil
end

-- 監聽 SquatBonusRequest 的 OnClientEvent
local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("Remotes", 5)
local squatEvent = remotes and remotes:WaitForChild("SquatBonusRequest", 5)

if squatEvent then
    squatEvent.OnClientEvent:Connect(function(action, num)
        -- 當觸發 "Activated" 或收到對應Remote信號時，重置計時器
        lastSignalTime = tick()
    end)
end

-- UI 下拉選單：Select Rarity
Hub:CreateDropdown("Select Rarity", rarities, "Common", function(selected)
    selectedRarity = selected
end)

-- UI 下拉選單：Select Area
Hub:CreateDropdown("Select Area", areaList, "Meadow 1", function(selected)
    selectedArea = selected
end)

-- UI 按鈕：Teleport to Selected Area
Hub:CreateButton("Teleport to Selected Area", function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return end
    
    local stageName, subKey = parseAreaSelection(selectedArea)
    local stagesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Stages")
    local stageFolder = stagesFolder and stagesFolder:FindFirstChild(stageName)
    
    if stageFolder then
        local targetCF = nil
        local spawners = stageFolder:FindFirstChild("Spawners")
        if spawners and spawners:FindFirstChild(subKey) then
            targetCF = spawners[subKey]:GetPivot()
        else
            targetCF = stageFolder:GetPivot()
        end
        
        if targetCF then
            hrp.CFrame = targetCF * CFrame.new(0, 5, 0)
        end
    end
end)

-- UI 開關：Auto Egg
Hub:CreateToggle("Auto Egg", false, function(isOn)
    autoEggEnabled = isOn
end)

-- UI 開關：Auto Train x2
Hub:CreateToggle("Auto Train x2", false, function(isOn)
    autoTrainEnabled = isOn
    if isOn then
        lastSignalTime = tick()
    end
end)

-- Auto Train x2 邏輯 (持續發送數字，收到 OnClientEvent 時重新計算 7 秒時間)
task.spawn(function()
    local currentBonusNumber = 1
    
    while true do
        if autoTrainEnabled then
            lastSignalTime = tick()
            
            -- 持續檢查時間距離最後一次觸發/重置是否未滿 7 秒
            while autoTrainEnabled and (tick() - lastSignalTime < 7) do
                local event = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("SquatBonusRequest")
                
                if event then
                    pcall(function()
                        event:FireServer(currentBonusNumber)
                    end)
                end
                task.wait(0.1) -- 每 0.1 秒發送一次
            end
            
            -- 超過 7 秒沒收到新的 Reset 信號時，數字 +1
            if autoTrainEnabled then
                currentBonusNumber = currentBonusNumber + 1
            end
        else
            task.wait(0.2)
        end
    end
end)

-- 自動觸發 ProximityPrompt 邏輯（偷蛋完傳回重生點）
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoEggEnabled then
            local player = game.Players.LocalPlayer
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            
            local stageName, subKey = parseAreaSelection(selectedArea)
            local stagesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Stages")
            local stageFolder = stagesFolder and stagesFolder:FindFirstChild(stageName)
            
            if hrp and stageFolder then
                local searchContainers = {}
                local spawnedEggs = stageFolder:FindFirstChild("SpawnedEggs")
                local spawners = stageFolder:FindFirstChild("Spawners")
                local targetSpawnerPart = spawners and spawners:FindFirstChild(subKey)
                
                if spawnedEggs then table.insert(searchContainers, spawnedEggs) end
                if targetSpawnerPart then table.insert(searchContainers, targetSpawnerPart) end
                
                for _, container in ipairs(searchContainers) do
                    if not autoEggEnabled then break end
                    
                    for _, model in ipairs(container:GetChildren()) do
                        if not autoEggEnabled then break end
                        
                        if model:IsA("Model") then
                            local rarityAttr = model:GetAttribute("Rarity")
                            
                            if model.Name == selectedRarity or (rarityAttr and tostring(rarityAttr) == selectedRarity) then
                                local promptFound = false
                                
                                hrp.CFrame = model:GetPivot() * CFrame.new(0, 3, 0)
                                task.wait(0.15)
                                
                                for _, descendant in ipairs(model:GetDescendants()) do
                                    if descendant:IsA("ProximityPrompt") then
                                        fireproximityprompt(descendant)
                                        promptFound = true
                                    end
                                end
                                
                                if promptFound then
                                    task.wait(0.1)
                                    local spawnCFrame = getPlayerSpawnCFrame()
                                    if spawnCFrame me then
                                        hrp.CFrame = spawnCFrame * CFrame.new(0, 3, 0)
                                    end
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
