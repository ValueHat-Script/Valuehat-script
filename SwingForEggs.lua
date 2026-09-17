-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Swing For Eggs", "TikTok: ValueHat")

-- 變數設定
local selectedZone = "Zone 1"
local autoEggEnabled = false
local autoEquipBestEnabled = false

-- Zone 選單列表
local zoneList = {
    "Zone 1", "Zone 2", "Zone 3", "Zone 4", "Zone 5",
    "Zone 6", "Zone 7", "Zone 8", "Zone 9"
}

-- UI 下拉選單
Hub:CreateDropdown("Select Zone", zoneList, "Zone 1", function(selected)
    selectedZone = selected
    print("[Auto Egg] 已選擇: " .. selected)
end)

-- UI 開關：Auto Egg
Hub:CreateToggle("Auto Egg", false, function(isOn)
    autoEggEnabled = isOn
    print("[Auto Egg] 開關狀態: " .. tostring(isOn))
end)

-- UI 開關：Auto Equip Best
Hub:CreateToggle("Auto Equip Best", false, function(isOn)
    autoEquipBestEnabled = isOn
    print("[Auto Equip Best] 開關狀態: " .. tostring(isOn))
end)

-- UI 按鈕：Sell Inventory
Hub:CreateButton("Sell Inventory", function()
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        local sellEvent = eventsFolder and eventsFolder:FindFirstChild("RequestSell")
        
        if sellEvent and sellEvent:IsA("RemoteEvent") then
            sellEvent:FireServer("Inventory")
            print("[Sell Inventory] 已送出出售請求！")
        else
            warn("[Sell Inventory] 找不到 RequestSell 事件！")
        end
    end)
end)

-- 自動裝備最佳寵物邏輯
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    while true do
        task.wait(1)
        if autoEquipBestEnabled then
            pcall(function()
                local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                local equipEvent = eventsFolder and eventsFolder:FindFirstChild("EquipBestPets")
                
                if equipEvent and equipEvent:IsA("RemoteEvent") then
                    equipEvent:FireServer()
                end
            end)
        end
    end
end)

-- 尋找目標 Zone 資料夾
local function FindZoneFolder(zoneStr)
    local targetName = (zoneStr == "Zone 1") and "EggSpawn" or zoneStr:gsub("%s+", "")
    
    -- 搜尋整個 Workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and (obj.Name == targetName or obj.Name == zoneStr) then
            return obj
        end
    end
    return nil
end

-- 自動偷蛋主邏輯
task.spawn(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    while true do
        task.wait(0.5)
        if autoEggEnabled then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if not hrp then
                warn("[Auto Egg] 找不到玩家的 HumanoidRootPart！")
            else
                local zoneFolder = FindZoneFolder(selectedZone)
                
                if not zoneFolder then
                    warn("[Auto Egg] 找不到區域資料夾: " .. selectedZone .. " (請確認 F9 中地圖名稱)")
                else
                    -- 尋找 SpawnedEgg 或帶有 ProximityPrompt 的物件
                    local targetEgg = nil
                    for _, desc in ipairs(zoneFolder:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            targetEgg = desc.Parent
                            break
                        end
                    end

                    if not targetEgg then
                        warn("[Auto Egg] 在 " .. zoneFolder.Name .. " 裡面找不到 SpawnedEgg / ProximityPrompt！")
                    else
                        print("[Auto Egg] 成功找到蛋: " .. targetEgg:GetFullName() .. "，準備傳送...")
                        
                        -- 1. 傳送到蛋的位置
                        local targetCF = targetEgg:IsA("Model") and targetEgg:GetPivot() or targetEgg.CFrame
                        
                        -- 嘗試多種傳送方式
                        hrp.CFrame = targetCF * CFrame.new(0, 3, 0)
                        if character:FindFirstChild("PivotTo") then
                            character:PivotTo(targetCF * CFrame.new(0, 3, 0))
                        end
                        
                        task.wait(0.2)

                        -- 2. 觸發互動 Prompt
                        local promptFound = false
                        for _, prompt in ipairs(targetEgg:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") then
                                fireproximityprompt(prompt)
                                promptFound = true
                                print("[Auto Egg] 已觸發 ProximityPrompt！")
                            end
                        end

                        -- 3. 傳送回 Baseplate
                        if promptFound then
                            task.wait(0.2)
                            local baseplate = workspace:FindFirstChild("Baseplate", true) or workspace:FindFirstChild("SpawnLocation", true)
                            if baseplate and baseplate:IsA("BasePart") then
                                hrp.CFrame = baseplate.CFrame * CFrame.new(0, 5, 0)
                                print("[Auto Egg] 已傳送回 Baseplate！")
                            else
                                warn("[Auto Egg] 找不到 Baseplate 或 SpawnLocation 回程點！")
                            end
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end)
