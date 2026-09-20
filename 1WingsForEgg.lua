-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("+1 Wings For Egg", "TikTok: ValueHat")

-- 服務與玩家設定
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數設定
local selectedZone = "Forest"
local autoEggEnabled = false
local autoBestEnabled = false
local detectRadius = 100 -- 以角色為中心偵測蛋的半徑 (100 Studs)

-- 正確的 8 個區域列表
local zoneList = {
    "Forest",
    "Beach",
    "Desert",
    "Arctic",
    "Volcano",
    "Void",
    "Cloudlands",
    "Deep Ocean"
}

-- UI 下拉選單：Select Zone
Hub:CreateDropdown("Select Zone", zoneList, "Forest", function(selected)
    selectedZone = selected
    print("[Auto Egg] 已選擇目標區域: " .. tostring(selected))
end)

-- UI 開關：Auto Egg
Hub:CreateToggle("Auto Egg", false, function(isOn)
    autoEggEnabled = isOn
    print("[Auto Egg] 開關狀態: " .. tostring(isOn))
end)

-- UI 開關：Auto Best
Hub:CreateToggle("Auto Best", false, function(isOn)
    autoBestEnabled = isOn
    print("[Auto Best] 開關狀態: " .. tostring(isOn))
end)

-- Auto Best 主邏輯 (獨立背景任務)
task.spawn(function()
    while true do
        task.wait(5) -- 每 5 秒自動發送一次 Equip Best
        if autoBestEnabled then
            pcall(function()
                local remotesFolder = ReplicatedStorage:FindFirstChild("SharedModules")
                    and ReplicatedStorage.SharedModules:FindFirstChild("Network")
                    and ReplicatedStorage.SharedModules.Network:FindFirstChild("Remotes")
                
                if remotesFolder then
                    local equipBestRemote = remotesFolder:FindFirstChild("Equip Best")
                    if equipBestRemote then
                        equipBestRemote:FireServer()
                        print("[Auto Best] 已觸發 Equip Best Remote")
                    end
                end
            end)
        end
    end
end)

-- 取得返回點位置 (workspace.MAPPARTS.GroundSign)
local function GetReturnCFrame()
    local mapParts = workspace:FindFirstChild("MAPPARTS")
    if mapParts then
        local groundSign = mapParts:FindFirstChild("GroundSign")
        if groundSign then
            return groundSign:IsA("Model") and groundSign:GetPivot() or groundSign.CFrame
        end
    end
    return nil
end

-- 根據區域名稱，動態取得對應的 Model 容器
local function GetZoneModel(zoneName)
    local mapFolder = workspace:FindFirstChild("Map") or workspace:FindFirstChild("MAP")
    if not mapFolder then return nil end

    -- 特殊區域路徑：workspace.Map.GuardianSpawns
    if zoneName == "Volcano" or zoneName == "Void" or zoneName == "Cloudlands" then
        local guardianSpawns = mapFolder:FindFirstChild("GuardianSpawns")
        if guardianSpawns then
            return guardianSpawns:FindFirstChild(zoneName)
        end
    else
        -- 一般區域路徑：workspace.Map.Ground
        local groundFolder = mapFolder:FindFirstChild("Ground")
        if groundFolder then
            return groundFolder:FindFirstChild(zoneName)
        end
    end

    return nil
end

-- 精準取得目標區域 CFrame
local function GetZoneCFrame(zoneModel)
    if not zoneModel then return nil end

    if zoneModel:IsA("Model") and zoneModel.PrimaryPart then
        return zoneModel.PrimaryPart.CFrame
    end

    if zoneModel:IsA("Model") then
        local cframe, _ = zoneModel:GetBoundingBox()
        if cframe and cframe.Position.Magnitude > 1 then
            return cframe
        end
        return zoneModel:GetPivot()
    elseif zoneModel:IsA("BasePart") then
        return zoneModel.CFrame
    end

    local firstPart = zoneModel:FindFirstChildWhichIsA("BasePart", true)
    if firstPart then
        return firstPart.CFrame
    end

    return nil
end

-- 安全傳送角色函式（向上偏移 5 單位避免卡地板）
local function SafeTeleport(character, targetCFrame, heightOffset)
    if not character or not targetCFrame then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    local offset = heightOffset or 5 -- 預設往上抬高 5 單位
    local finalCFrame = targetCFrame + Vector3.new(0, offset, 0)

    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = finalCFrame
    end
    
    if character:FindFirstChild("PivotTo") then
        character:PivotTo(finalCFrame)
    end
end

-- 安全觸發 ProximityPrompt 函式
local function SafelyFirePrompt(prompt)
    if prompt and prompt.Enabled and type(fireproximityprompt) == "function" then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    end
end

-- 重置角色狀態
local function ResetCharacterState(character)
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")

    if hrp then
        hrp.Anchored = false
    end

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

-- 搜尋以角色當前位置為中心、半徑 100 內名稱包含 "Egg" 的 Model，並依距離「由近到遠」排序
local function GetNearbyEggModelsSorted(hrpPosition, maxDistance, zoneModel)
    local nearbyEggs = {}

    -- 1. 優先搜尋選定區域容器內的 Egg
    local searchContainer = zoneModel or workspace
    for _, obj in ipairs(searchContainer:GetDescendants()) do
        if obj:IsA("Model") and string.find(obj.Name:lower(), "egg") then
            local eggPos = obj:GetPivot().Position
            local dist = (hrpPosition - eggPos).Magnitude

            if dist <= maxDistance then
                table.insert(nearbyEggs, {
                    model = obj,
                    distance = dist
                })
            end
        end
    end

    -- 2. 如果選定區域容器內沒找到，退回搜尋全 workspace
    if #nearbyEggs == 0 and zoneModel ~= nil then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and string.find(obj.Name:lower(), "egg") then
                local eggPos = obj:GetPivot().Position
                local dist = (hrpPosition - eggPos).Magnitude

                if dist <= maxDistance then
                    table.insert(nearbyEggs, {
                        model = obj,
                        distance = dist
                    })
                end
            end
        end
    end

    -- 依照距離由近到遠排序 (優先傳送最近的蛋)
    table.sort(nearbyEggs, function(a, b)
        return a.distance < b.distance
    end)

    return nearbyEggs
end

-- 自動偷蛋主邏輯
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoEggEnabled then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                local zoneModel = GetZoneModel(selectedZone)
                local zoneCF = GetZoneCFrame(zoneModel)

                -- Step 1: 先傳送到區域 (特定區域使用 GuardianSpawns，其他使用 Ground)
                if zoneCF then
                    print("[Auto Egg] 1. 正在傳送到區域 [" .. selectedZone .. "] (向上偏移 5 單位)...")
                    SafeTeleport(character, zoneCF, 5)
                    
                    -- 等待 0.6 秒讓地圖載入與角色座標同步
                    task.wait(0.6)
                else
                    warn("[Auto Egg] 找不到區域 Model: " .. tostring(selectedZone))
                end

                -- Step 2: 抵達區域後，以角色最新位置為中心，偵測半徑 100 內的所有 Egg Model
                local currentHrpPos = hrp.Position
                local nearbyEggs = GetNearbyEggModelsSorted(currentHrpPos, detectRadius, zoneModel)

                if #nearbyEggs > 0 then
                    print("[Auto Egg] 2. 偵測到 " .. #nearbyEggs .. " 個蛋，優先處理最近的蛋...")

                    for _, eggData in ipairs(nearbyEggs) do
                        if not autoEggEnabled then break end

                        local eggModel = eggData.model
                        if eggModel and eggModel.Parent then
                            print("[Auto Egg] -> 傳送至最近的蛋: " .. eggModel.Name .. " (距離: " .. math.floor(eggData.distance) .. " studs)")

                            local prompt = eggModel:FindFirstChildWhichIsA("ProximityPrompt", true)

                            -- Step 3: 傳送到蛋的位置 (向上抬高 5 單位避免卡地板)
                            local targetPart = eggModel:FindFirstChild("RootPart", true) or eggModel:FindFirstChild("Egg", true)
                            local targetCF = targetPart and targetPart.CFrame or eggModel:GetPivot()

                            SafeTeleport(character, targetCF, 5)
                            task.wait(0.4)

                            -- Step 4: 觸發 ProximityPrompt
                            if prompt then
                                print("[Auto Egg] 正在觸發 " .. prompt.Name .. "...")
                                SafelyFirePrompt(prompt)
                                task.wait(0.3)
                            else
                                warn("[Auto Egg] 蛋內部找不到 ProximityPrompt！")
                            end

                            -- Step 5: 傳送回 workspace.MAPPARTS.GroundSign (向上抬高 5 單位)
                            local returnCF = GetReturnCFrame()
                            if returnCF then
                                SafeTeleport(character, returnCF, 5)
                                print("[Auto Egg] 已傳送回 GroundSign！")
                            else
                                warn("[Auto Egg] 找不到 workspace.MAPPARTS.GroundSign！")
                            end

                            -- Step 6: 解鎖角色狀態
                            ResetCharacterState(character)

                            -- Step 7: 休息 2 秒後繼續下一輪
                            print("[Auto Egg] 休息 2 秒後繼續下一輪...")
                            task.wait(2)
                        end
                    end
                else
                    print("[Auto Egg] 抵達區域 [" .. selectedZone .. "] 後，半徑 100 內未偵測到 Egg Model，1 秒後重試...")
                    task.wait(1)
                end
            end
        end
    end
end)
