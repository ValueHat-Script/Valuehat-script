-- 安全載入 UI (帶詳細錯誤捕捉)
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗！請檢查執行器是否支援 loadstring，或網路連線是否正常。錯誤訊息: " .. tostring(UIModule))
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 強化版角色傳送函數
local function teleportMyCharacterTo(cf)
    if not cf then return end

    pcall(function()
        local charactersFolder = Workspace:FindFirstChild("Characters")
        local myName = LocalPlayer.Name
        local myCharModel = (charactersFolder and charactersFolder:FindFirstChild(myName)) or LocalPlayer.Character

        if myCharModel then
            if myCharModel:IsA("Model") then
                myCharModel:PivotTo(cf)
            end

            local root = myCharModel:FindFirstChild("HumanoidRootPart") or myCharModel.PrimaryPart or myCharModel:FindFirstChildWhichIsA("BasePart", true)
            if root then
                root.CFrame = cf
            end
        end
    end)
end

-- 取得物件座標
local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local best, size = nil, 0
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") and d.Size.Magnitude > size then
                best, size = d, d.Size.Magnitude
            end
        end
        if best then return best.CFrame end
        return obj:GetPivot()
    end
    return nil
end

-- ==================== Find Bear 邏輯 ====================
local function findSingleBear()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "R26EventBear" then
            return obj
        end
    end
    return nil
end

local function findAndCollectBear()
    task.spawn(function()
        local bear = findSingleBear()
        if not bear then
            warn("[Find Bear] 找不到任何 R26EventBear！")
            return
        end

        local bearCf = getCFrame(bear)
        if bearCf then
            -- 1. 傳送到 R26EventBear
            teleportMyCharacterTo(bearCf + Vector3.new(0, 3, 0))
            print("[Find Bear] 正在傳送到 R26EventBear")
            
            -- 2. 等待一小段時間模擬觸發互動
            task.wait(0.6)

            -- 3. 傳送回 workspace.Bed
            local bed = Workspace:FindFirstChild("Bed")
            if bed then
                local bedCf = getCFrame(bed)
                if bedCf then
                    teleportMyCharacterTo(bedCf + Vector3.new(0, 3, 0))
                    print("[Find Bear] 成功傳回 workspace.Bed！")
                else
                    warn("[Find Bear] 找不到 workspace.Bed 的有效座標！")
                end
            else
                warn("[Find Bear] 在 Workspace 中找不到 Bed！")
            end
        else
            warn("[Find Bear] 無法取得該 Bear 的座標！")
        end
    end)
end

-- ==================== Token 1 邏輯 ====================
local function tokenOneTeleport()
    task.spawn(function()
        local map = Workspace:FindFirstChild("Map")
        local altar = map and map:FindFirstChild("CheeseAltar")
        
        if not altar then
            warn("[Token 1] 找不到 CheeseAltar！")
            return
        end

        -- 1. 傳送到 Items.Item
        local items = altar:FindFirstChild("Items")
        local item = items and items:FindFirstChild("Item")
        
        if item then
            local itemCf = getCFrame(item)
            if itemCf then
                teleportMyCharacterTo(itemCf + Vector3.new(0, 3, 0))
                print("[Token 1] 已傳送到 Item")
            else
                warn("[Token 1] 無法取得 Item 座標！")
            end
        else
            warn("[Token 1] 找不到 Item！")
        end

        -- 等待 0.6 秒
        task.wait(0.6)

        -- 2. 傳送到 Base.Detect
        local base = altar:FindFirstChild("Base")
        local detect = base and base:FindFirstChild("Detect")
        
        if detect then
            local detectCf = getCFrame(detect)
            if detectCf then
                teleportMyCharacterTo(detectCf + Vector3.new(0, 3, 0))
                print("[Token 1] 已傳送到 Detect")
            else
                warn("[Token 1] 無法取得 Detect 座標！")
            end
        else
            warn("[Token 1] 找不到 Detect！")
        end
    end)
end

-- ==================== Token 2 邏輯 ====================
local function tokenTwoTeleport()
    task.spawn(function()
        local map = Workspace:FindFirstChild("Map")
        local memory = map and map:FindFirstChild("Memory")
        
        if not memory then
            warn("[Token 2] 找不到 Memory！")
            return
        end

        -- 1. 傳送到 workspace.Map.Memory.Item
        local item = memory:FindFirstChild("Item")
        if item then
            local itemCf = getCFrame(item)
            if itemCf then
                teleportMyCharacterTo(itemCf + Vector3.new(0, 3, 0))
                print("[Token 2] 已傳送到 Memory.Item")
            else
                warn("[Token 2] 無法取得 Memory.Item 座標！")
            end
        else
            warn("[Token 2] 找不到 Memory.Item！")
        end

        -- 等待 0.6 秒
        task.wait(0.6)

        -- 2. 傳送到 workspace.Map.Memory.Base
        local base = memory:FindFirstChild("Base")
        if base then
            local baseCf = getCFrame(base)
            if baseCf then
                teleportMyCharacterTo(baseCf + Vector3.new(0, 3, 0))
                print("[Token 2] 已傳送到 Memory.Base")
            else
                warn("[Token 2] 無法取得 Memory.Base 座標！")
            end
        else
            warn("[Token 2] 找不到 Memory.Base！")
        end
    end)
end

-- ==================== Token 3 邏輯 ====================
local function tokenThreeTeleport()
    task.spawn(function()
        local map = Workspace:FindFirstChild("Map")
        local stage = map and map:FindFirstChild("Stage")
        local loneHouseZone = stage and stage:FindFirstChild("LoneHouseZone")
        local barn = loneHouseZone and loneHouseZone:FindFirstChild("Barn")
        
        if not barn then
            warn("[Token 3] 找不到 Barn！")
            return
        end

        local children = barn:GetChildren()
        local targetObj = children[283]
        
        if targetObj then
            local targetCf = getCFrame(targetObj)
            if targetCf then
                teleportMyCharacterTo(targetCf + Vector3.new(0, 3, 0))
                print("[Token 3] 已成功傳送到 Barn 第 283 個物件")
            else
                warn("[Token 3] 找到了第 283 個物件，但無法取得有效座標！")
            end
        else
            warn("[Token 3] Barn 底下的子物件數量不足 283 個！")
        end
    end)
end

-- ==================== Token 4 邏輯 ====================
local function tokenFourTeleport()
    task.spawn(function()
        local map = Workspace:FindFirstChild("Map")
        local painting = map and map:FindFirstChild("Painting")
        local models = painting and painting:FindFirstChild("Models")
        local targetObj = models and models:FindFirstChild("1")
        
        if targetObj then
            local targetCf = getCFrame(targetObj)
            if targetCf then
                teleportMyCharacterTo(targetCf + Vector3.new(0, 3, 0))
                print("[Token 4] 已成功傳送到 Painting.Models[\"1\"]")
            else
                warn("[Token 4] 找到了 Painting.Models[\"1\"]，但無法取得有效座標！")
            end
        else
            warn("[Token 4] 找不到 workspace.Map.Painting.Models[\"1\"]！")
        end
    end)
end

-- ==================== TP Back 邏輯 ====================
local function tpBackTeleport()
    task.spawn(function()
        local map = Workspace:FindFirstChild("Map")
        local stage = map and map:FindFirstChild("Stage")
        local altar = stage and stage:FindFirstChild("Altar")
        local targetObj = altar and altar:FindFirstChild("TBB_Altar")
        
        if targetObj then
            local targetCf = getCFrame(targetObj)
            if targetCf then
                teleportMyCharacterTo(targetCf + Vector3.new(0, 3, 0))
                print("[TP Back] 已成功傳送到 TBB_Altar")
            else
                warn("[TP Back] 找到了 TBB_Altar，但無法取得有效座標！")
            end
        else
            warn("[TP Back] 找不到 workspace.Map.Stage.Altar.TBB_Altar！")
        end
    end)
end

-- ==================== Finish Speedrun 邏輯 ====================
local function finishSpeedrunTeleport()
    task.spawn(function()
        local chaseSequence = Workspace:FindFirstChild("ChaseSequence")
        local targetObj = chaseSequence and chaseSequence:FindFirstChild("TheFinishLine")
        
        if targetObj then
            local targetCf = getCFrame(targetObj)
            if targetCf then
                teleportMyCharacterTo(targetCf + Vector3.new(0, 3, 0))
                print("[Finish Speedrun] 已成功傳送到 TheFinishLine")
            else
                warn("[Finish Speedrun] 找到了 TheFinishLine，但無法取得有效座標！")
            end
        else
            warn("[Finish Speedrun] 找不到 workspace.ChaseSequence.TheFinishLine！")
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Bear", "TikTok: ValueHat")

HubWindow:CreateButton("Find Bear", function()
    findAndCollectBear()
end)

HubWindow:CreateButton("Token 1", function()
    tokenOneTeleport()
end)

HubWindow:CreateButton("Token 2", function()
    tokenTwoTeleport()
end)

HubWindow:CreateButton("Token 3", function()
    tokenThreeTeleport()
end)

HubWindow:CreateButton("Token 4", function()
    tokenFourTeleport()
end)

HubWindow:CreateButton("TP Back", function()
    tpBackTeleport()
end)

HubWindow:CreateButton("Finish Speedrun", function()
    finishSpeedrunTeleport()
end)

print("[ValueHat] Find Bear, Tokens 1-4, TP Back & Finish Speedrun script loaded successfully!")
