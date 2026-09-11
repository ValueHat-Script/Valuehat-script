-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Anime Dice", "TikTok: ValueHat")

-- 核心服務
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------
-- 1. Auto Equip Best 功能
---------------------------------------------------------
local autoEquipEnabled = false

Hub:CreateToggle("Auto Equip Best", false, function(isOn)
    autoEquipEnabled = isOn

    if autoEquipEnabled then
        task.spawn(function()
            local network = ReplicatedStorage:WaitForChild("Network", 5)
            local plotService = network and network:WaitForChild("PlotService", 5)
            local reFolder = plotService and plotService:WaitForChild("RE", 5)
            local equipBestEvent = reFolder and reFolder:WaitForChild("EquipBest", 5)

            if equipBestEvent then
                while autoEquipEnabled do
                    pcall(function()
                        equipBestEvent:FireServer()
                    end)
                    task.wait(1)
                end
            else
                warn("[Auto Equip Best]: 未找到 EquipBest RemoteEvent！")
            end
        end)
    end
end)

---------------------------------------------------------
-- 2. Auto Collect Money 功能 (1~8 並列即時發送)
---------------------------------------------------------
local autoCollectEnabled = false

Hub:CreateToggle("Auto Collect Money", false, function(isOn)
    autoCollectEnabled = isOn

    if autoCollectEnabled then
        local network = ReplicatedStorage:WaitForChild("Network", 5)
        local plotService = network and network:WaitForChild("PlotService", 5)
        local reFolder = plotService and plotService:WaitForChild("RE", 5)
        local collectEvent = reFolder and reFolder:WaitForChild("CollectBalance", 5)

        if collectEvent then
            for i = 1, 100 do
                task.spawn(function()
                    while autoCollectEnabled do
                        pcall(function()
                            collectEvent:FireServer(i)
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        else
            warn("[Auto Collect Money]: 未找到 CollectBalance RemoteEvent！")
        end
    end
end)

---------------------------------------------------------
-- 3. Auto Rebirth 功能
---------------------------------------------------------
local autoRebirthEnabled = false

Hub:CreateToggle("Auto Rebirth", false, function(isOn)
    autoRebirthEnabled = isOn

    if autoRebirthEnabled then
        task.spawn(function()
            local network = ReplicatedStorage:WaitForChild("Network", 5)
            local rebirthService = network and network:WaitForChild("RebirthService", 5)
            local reFolder = rebirthService and rebirthService:WaitForChild("RE", 5)
            local rebirthEvent = reFolder and reFolder:WaitForChild("Rebirth", 5)

            if rebirthEvent then
                while autoRebirthEnabled do
                    pcall(function()
                        rebirthEvent:FireServer()
                    end)
                    task.wait(1)
                end
            else
                warn("[Auto Rebirth]: 未找到 Rebirth RemoteEvent！")
            end
        end)
    end
end)
