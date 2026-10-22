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

local selectedArea = "Abyss Ocean"
local autoEggEnabled = false
local autoSkipEnabled = false
local equipBestEnabled = false

-- 區域列表
local areas = {
    "Abyss Ocean",
    "Angel",
    "Cherry Blossom",
    "Cosmic",
    "Desert",
    "Enchanted Forest",
    "Forest",
    "Jungle",
    "Lake",
    "Prehistoric",
    "Snow",
    "Titan Temple",
    "Underworld",
    "Volcano"
}

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 瞬移
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
    end
end

-- 取得返回點
local function getReturnCFrame()
    local objects = Workspace:FindFirstChild("__OBJECTS")
    if not objects then return nil end

    local build = objects:FindFirstChild("Build")
    if not build then return nil end

    local mainMap = build:FindFirstChild("MainMap")
    if not mainMap then return nil end

    local bases = mainMap:FindFirstChild("Bases")
    if not bases then return nil end

    local children = bases:GetChildren()
    local target = children[8]
    if not target then return nil end

    if target:IsA("BasePart") then
        return target.CFrame + Vector3.new(0, 3, 0)
    elseif target:IsA("Model") then
        if target.PrimaryPart then
            return target.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        end
        local part = target:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
        return target:GetPivot() + Vector3.new(0, 3, 0)
    end

    return nil
end

-- 取得區域位置
local function getAreaCFrame(areaName)
    local objects = Workspace:FindFirstChild("__OBJECTS")
    if not objects then return nil end

    local areasFolder = objects:FindFirstChild("Areas")
    if not areasFolder then return nil end

    local guardAreas = areasFolder:FindFirstChild("GuardAreas")
    if not guardAreas then return nil end

    local area = guardAreas:FindFirstChild(areaName)
    if not area then return nil end

    if area:IsA("BasePart") then
        return area.CFrame
    elseif area:IsA("Model") then
        if area.PrimaryPart then
            return area.PrimaryPart.CFrame
        end
        local part = area:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return area:GetPivot()
    end
    return nil
end

-- 取得 Model 的 CFrame
local function getModelCFrame(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.CFrame
        end
        local part = model:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return model:GetPivot()
    elseif model:IsA("BasePart") then
        return model.CFrame
    end
    return nil
end

-- 觸發周圍的 ProximityPrompt
local function fireNearbyPrompts(range)
    range = range or 15
    local hrp = getHRP()
    if not hrp then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent then
                local pos = nil
                if parent:IsA("BasePart") then
                    pos = parent.Position
                elseif parent:IsA("Model") then
                    local part = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
                    if part then
                        pos = part.Position
                    end
                end

                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if dist <= range then
                        pcall(function()
                            fireproximityprompt(obj)
                        end)
                    end
                end
            end
        end
    end
end

-- 尋找選定區域附近的 AreaEgg
local function findAreaEggs()
    local areaCF = getAreaCFrame(selectedArea)
    if not areaCF then return {} end

    local eggs = {}
    local searchRange = 300

    local eggFolder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if eggFolder then
        for _, egg in ipairs(eggFolder:GetChildren()) do
            if egg.Name:find("AreaEgg") then
                local eggCF = getModelCFrame(egg)
                if eggCF then
                    local dist = (eggCF.Position - areaCF.Position).Magnitude
                    if dist <= searchRange then
                        table.insert(eggs, {
                            model = egg,
                            cf = eggCF,
                            dist = dist
                        })
                    end
                end
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("AreaEgg") then
            local eggCF = getModelCFrame(obj)
            if eggCF then
                local dist = (eggCF.Position - areaCF.Position).Magnitude
                if dist <= searchRange then
                    local exists = false
                    for _, e in ipairs(eggs) do
                        if e.model == obj then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(eggs, {
                            model = obj,
                            cf = eggCF,
                            dist = dist
                        })
                    end
                end
            end
        end
    end

    table.sort(eggs, function(a, b)
        return a.dist < b.dist
    end)

    return eggs
end

-- 從名稱提取正確的 Egg Uid
local function extractEggUid(fullName)
    local uid = fullName:match("Egg_[%w%-]+")
    if uid then
        return uid
    end

    uid = fullName:match("_Egg_(.+)")
    if uid then
        return "Egg_" .. uid
    end

    return nil
end

-- 執行 Skip Growth Remote
local function skipGrowth(eggUid)
    local success, err = pcall(function()
        local event = ReplicatedStorage.Packages.Networking["RF/EggWorld/AskSkipGrowth"]
        event:InvokeServer(eggUid)
    end)

    if success then
        print("[Auto Skip] 成功跳過成長:", eggUid)
    else
        warn("[Auto Skip] 失敗:", err)
    end
    return success
end

-- 執行 Equip Best Remote
local function equipBest()
    local success, err = pcall(function()
        local event = ReplicatedStorage.Packages.Networking["RF/Haul/WearBest"]
        event:InvokeServer()
    end)

    if success then
        print("[Equip Best] 已裝備最佳")
    else
        warn("[Equip Best] 失敗:", err)
    end
    return success
end

-- Auto Egg 主迴圈
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local eggs = findAreaEggs()
            
            if #eggs > 0 then
                for _, eggData in ipairs(eggs) do
                    if not autoEggEnabled then break end

                    teleportTo(eggData.cf + Vector3.new(0, 4, 0))
                    task.wait(0.25)

                    fireNearbyPrompts(12)
                    task.wait(0.35)

                    local returnCF = getReturnCFrame()
                    if returnCF then
                        teleportTo(returnCF)
                    end
                    task.wait(0.5)
                end
            else
                print("[Auto Egg] 在 " .. selectedArea .. " 沒找到 AreaEgg")
                task.wait(1.5)
            end
        end
    end)
end

-- Auto Skip 主迴圈
local function startAutoSkip()
    task.spawn(function()
        while autoSkipEnabled do
            local placedFolder = Workspace:FindFirstChild("PlacedEggRenders")
            
            if placedFolder then
                local skippedAny = false
                
                for _, egg in ipairs(placedFolder:GetChildren()) do
                    if not autoSkipEnabled then break end
                    
                    if egg:IsA("Model") and (egg.Name:find("Egg_") or egg.Name:find("_Egg_")) then
                        local uid = extractEggUid(egg.Name)
                        
                        if uid then
                            skipGrowth(uid)
                            skippedAny = true
                            task.wait(0.4)
                        end
                    end
                end
                
                if not skippedAny then
                    print("[Auto Skip] 目前沒有可跳過的蛋")
                    task.wait(1.2)
                else
                    task.wait(0.6)
                end
            else
                warn("[Auto Skip] 找不到 PlacedEggRenders")
                task.wait(1.5)
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

-- ==================== UI ====================
local Hub = UIModule.CreateWindow("Divine Hatchers", "TikTok: ValueHat")

Hub:CreateDropdown("Select Area", areas, selectedArea, function(selected)
    selectedArea = selected
    print("[Select Area] 已選擇: " .. tostring(selected))
end)

Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then
        startAutoEgg()
        print("[Auto Egg] 已開啟")
    else
        print("[Auto Egg] 已關閉")
    end
end)

Hub:CreateToggle("Auto Skip", false, function(on)
    autoSkipEnabled = on
    if on then
        startAutoSkip()
        print("[Auto Skip] 已開啟")
    else
        print("[Auto Skip] 已關閉")
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

print("[ValueHat] Script loaded successfully!")
