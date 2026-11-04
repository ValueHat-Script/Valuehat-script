-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Venom Evolution")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local selectedStage = 1
local autoFarmEnabled = false
local antiDamageEnabled = false
local autoEvolveEnabled = false

local hoverConnection = nil
local antiDamageConnection = nil
local autoEvolveConnection = nil
local currentHoverCF = nil

-- Stage 列表 1~15
local stages = {}
for i = 1, 15 do
    table.insert(stages, tostring(i))
end

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- 取得玩家 Humanoid
local function getHumanoid()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- 瞬移
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

-- 取得物件 CFrame
local function getObjectCFrame(obj, yOffset)
    yOffset = yOffset or 3
    if obj:IsA("BasePart") then
        return obj.CFrame + Vector3.new(0, yOffset, 0)
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame + Vector3.new(0, yOffset, 0)
        end
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, yOffset, 0)
        end
        local success, pivot = pcall(function()
            return obj:GetPivot()
        end)
        if success then
            return pivot + Vector3.new(0, yOffset, 0)
        end
    end
    return nil
end

-- 取得 Stage 1~15 的完整資料夾名稱
local function getStageFolder(stageNum)
    local mapQuarantine = Workspace:FindFirstChild("MapQuarantine")
    if not mapQuarantine then
        warn("[Farm] 找不到 MapQuarantine")
        return nil
    end

    local num = tonumber(stageNum) or 1
    local stageNames = {
        [1] = "Stage01_Checkpoint",
        [2] = "Stage02_MotorPool",
        [3] = "Stage03_FloodlightCompound",
        [4] = "Stage04_OldTownRooftops",
        [5] = "Stage05_ChurchSquare",
        [6] = "Stage06_CommandPost",
        [7] = "Stage07_RadioPlaza",
        [8] = "Stage08_RelayStation",
        [9] = "Stage09_DishArray",
        [10] = "Stage10_TankFarm",
        [11] = "Stage11_CrackingTower",
        [12] = "Stage12_FlareStack",
        [13] = "Stage13_Breach",
        [14] = "Stage14_TheLab",
        [15] = "Stage15_TheCore"
    }

    local stageName = stageNames[num] or ("Stage" .. string.format("%02d", num))
    local stage = mapQuarantine:FindFirstChild(stageName)
    if not stage then
        warn("[Farm] 找不到 " .. stageName)
        return nil
    end
    return stage
end

-- 取得關卡起始點
local function getStageStartCFrame(stageNum)
    local num = tonumber(stageNum) or 1
    local stage = getStageFolder(num)
    if not stage then return nil end

    if num == 5 or num == 6 or (num >= 9 and num <= 12) then
        local winPad = stage:FindFirstChild("WinPad")
        if winPad then
            return getObjectCFrame(winPad, 3)
        else
            local fallback = stage:FindFirstChildWhichIsA("BasePart", true)
            if fallback then return getObjectCFrame(fallback, 3) end
        end
    else
        local children = stage:GetChildren()
        if #children >= 4 then
            return getObjectCFrame(children[4], 3)
        elseif #children > 0 then
            return getObjectCFrame(children[1], 3)
        end
    end
    
    return nil
end

-- 取得該 Stage 的 EnemyZone
local function getEnemyZoneCFrame(stageNum)
    local stage = getStageFolder(stageNum)
    if not stage then return nil end

    local enemyZone = stage:FindFirstChild("EnemyZone")
    if not enemyZone then
        enemyZone = stage:FindFirstChild("EnemyZone", true)
    end

    if not enemyZone then
        warn("[Farm] 找不到 EnemyZone in Stage" .. tostring(stageNum))
        return nil
    end

    return getObjectCFrame(enemyZone, 3)
end

-- 排除 Dummy，且確保敵人的 Health > 0 才會被加入清單
local function getValidEnemies()
    local enemies = {}
    local venomEnemies = Workspace:FindFirstChild("VenomEnemies")
    if not venomEnemies then return enemies end

    for _, model in ipairs(venomEnemies:GetChildren()) do
        if model:IsA("Model") and model.Name ~= "Dummy" then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health > 0 then
                table.insert(enemies, model)
            end
        end
    end
    return enemies
end

-- 取得 Model 下方位置
local function getModelBottomCFrame(model)
    if not model or not model.Parent then return nil end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if part then
        local heightOffset = -(part.Size.Y / 2) - 1
        return part.CFrame + Vector3.new(0, heightOffset, 0)
    end

    local success, pivot = pcall(function()
        return model:GetPivot()
    end)
    if success then
        return pivot + Vector3.new(0, -3, 0)
    end
    return nil
end

-- 開始 / 更新懸空固定
local function setHover(cf)
    if not cf then return end

    currentHoverCF = cf
    teleportTo(cf)

    if not hoverConnection then
        hoverConnection = RunService.Heartbeat:Connect(function()
            local hrp = getHRP()
            if hrp and currentHoverCF then
                hrp.CFrame = currentHoverCF
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
end

-- 停止懸空
local function stopHover()
    if hoverConnection then
        hoverConnection:Disconnect()
        hoverConnection = nil
    end
    currentHoverCF = nil
end

-- Anti Damage 功能開關邏輯
local function toggleAntiDamage(enabled)
    antiDamageEnabled = enabled
    if antiDamageEnabled then
        if not antiDamageConnection then
            antiDamageConnection = RunService.Heartbeat:Connect(function()
                local humanoid = getHumanoid()
                if humanoid then
                    if humanoid.Health < 100 then
                        humanoid.Health = 100
                    end
                end
            end)
        end
        print("[Anti Damage] 已開啟（鎖血 100）")
    else
        if antiDamageConnection then
            antiDamageConnection:Disconnect()
            antiDamageConnection = nil
        end
        print("[Anti Damage] 已關閉")
    end
end

-- Auto Evolve 功能開關邏輯
local function toggleAutoEvolve(enabled)
    autoEvolveEnabled = enabled
    if autoEvolveEnabled then
        task.spawn(function()
            local evolveEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Evolve")
            if not evolveEvent then
                warn("[Auto Evolve] 找不到 ReplicatedStorage.Remotes.Evolve")
                return
            end

            print("[Auto Evolve] 已開啟")
            while autoEvolveEnabled do
                pcall(function()
                    evolveEvent:InvokeServer()
                end)
                task.wait(1) -- 每秒嘗試進化一次，可依需求調整間隔
            end
        end)
    else
        print("[Auto Evolve] 已關閉")
    end
end

-- Auto Farm 主邏輯
local function startAutoFarm()
    task.spawn(function()
        while autoFarmEnabled do
            local stageNum = tonumber(selectedStage) or 1
            print("[Auto Farm] 目前 Stage: " .. tostring(stageNum))

            -- 1. 傳送到該關卡的起始點
            local startCF = getStageStartCFrame(stageNum)
            if startCF then
                stopHover()
                teleportTo(startCF)
                print("[Auto Farm] 已傳送到 Stage" .. tostring(stageNum) .. " 起始點")
                task.wait(0.5)
            else
                warn("[Auto Farm] 找不到起始點")
            end

            if not autoFarmEnabled then break end

            -- 2. 傳送到該 Stage 的 EnemyZone
            local enemyZoneCF = getEnemyZoneCFrame(stageNum)
            if enemyZoneCF then
                teleportTo(enemyZoneCF)
                print("[Auto Farm] 已傳送到 Stage" .. tostring(stageNum) .. " EnemyZone")
                task.wait(0.5)
            else
                warn("[Auto Farm] 找不到 EnemyZone")
            end

            if not autoFarmEnabled then break end

            -- 3. 偵測非 Dummy 且血量 > 0 的敵人，固定在下方
            while autoFarmEnabled do
                local enemies = getValidEnemies()

                if #enemies == 0 then
                    print("[Auto Farm] 非 Dummy 敵人已全部消失")
                    break
                end

                local target = enemies[1]
                local humanoid = target:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then
                    stopHover()
                else
                    local bottomCF = getModelBottomCFrame(target)
                    if bottomCF then
                        setHover(bottomCF)
                    end
                end

                task.wait(0.25)
            end

            if not autoFarmEnabled then break end

            -- 4. 敵人消失後，傳回起始點
            stopHover()
            local returnCF = getStageStartCFrame(stageNum)
            if returnCF then
                teleportTo(returnCF)
                print("[Auto Farm] 已傳回 Stage" .. tostring(stageNum) .. " 起始點")
            end

            -- 5. 等兩秒後繼續下一輪
            print("[Auto Farm] 等待 2 秒後繼續...")
            task.wait(2)
        end

        stopHover()
        print("[Auto Farm] 已關閉")
    end)
end

-- ==================== UI ====================
UI:Dropdown("StageDropdown", "Select Stage", stages, function(selected)
    selectedStage = selected
    print("[Select Stage] 已選擇: Stage" .. tostring(selected))
end)

UI:Toggle("AutoFarmToggle", "Auto Farm", function(enabled)
    autoFarmEnabled = enabled
    if enabled then
        startAutoFarm()
        print("[Auto Farm] 已開啟")
    else
        stopHover()
        print("[Auto Farm] 已關閉")
    end
end)

-- Anti Damage 開關
UI:Toggle("AntiDamageToggle", "Anti Damage", function(enabled)
    toggleAntiDamage(enabled)
end)

-- Auto Evolve 開關
UI:Toggle("AutoEvolveToggle", "Auto Evolve", function(enabled)
    toggleAutoEvolve(enabled)
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Script loaded successfully!")
