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

local selectedArea = "AbyssOcean"
local autoEggEnabled = false
local equipBestEnabled = false

-- 區域列表
local areas = {
    "AbyssOcean",
    "Cosmic",
    "Desert",
    "Forest",
    "Jungle",
    "Lake",
    "Prehistoric",
    "Snow",
    "Volcano"
}

-- 手動指定某些區域的中心點
local customAreaCenters = {
    AbyssOcean = Vector3.new(2280, 71, -329)
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

-- 取得 StartArea 返回位置
local function getStartAreaCFrame()
    local objects = Workspace:FindFirstChild("__OBJECTS")
    if not objects then return nil end

    local areasFolder = objects:FindFirstChild("Areas")
    if not areasFolder then return nil end

    local startArea = areasFolder:FindFirstChild("StartArea")
    if not startArea then return nil end

    if startArea:IsA("BasePart") then
        return startArea.CFrame + Vector3.new(0, 3, 0)
    elseif startArea:IsA("Model") then
        if startArea.PrimaryPart then
            return startArea.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
        end
        local part = startArea:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame + Vector3.new(0, 3, 0)
        end
        return startArea:GetPivot() + Vector3.new(0, 3, 0)
    end
    return nil
end

-- 取得指定區域的中心位置
local function getAreaCenter(areaName)
    if customAreaCenters[areaName] then
        return customAreaCenters[areaName]
    end

    local objects = Workspace:FindFirstChild("__OBJECTS")
    if not objects then return nil end

    local areasFolder = objects:FindFirstChild("Areas")
    if not areasFolder then return nil end

    local guardAreas = areasFolder:FindFirstChild("GuardAreas")
    if not guardAreas then return nil end

    local area = guardAreas:FindFirstChild(areaName)
    if not area then return nil end

    if area:IsA("BasePart") then
        return area.Position
    elseif area:IsA("Model") then
        if area.PrimaryPart then
            return area.PrimaryPart.Position
        end
        local part = area:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position
        end
        return area:GetPivot().Position
    end
    return nil
end

-- 取得蛋的位置
local function getEggCFrame(egg)
    if egg:IsA("Model") then
        if egg.PrimaryPart then
            return egg.PrimaryPart.CFrame
        end
        local part = egg:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return egg:GetPivot()
    elseif egg:IsA("BasePart") then
        return egg.CFrame
    end
    return nil
end

-- 判斷這顆蛋屬於哪個區域
local function getClosestArea(eggPos)
    local closestArea = nil
    local minDist = math.huge

    for _, areaName in ipairs(areas) do
        local center = getAreaCenter(areaName)
        if center then
            local dist = (eggPos - center).Magnitude
            if dist < minDist then
                minDist = dist
                closestArea = areaName
            end
        end
    end

    return closestArea, minDist
end

-- 使用 Remote 搬運蛋
local function carryEgg(uid)
    local success, err = pcall(function()
        local event = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Eggs: RequestAreaEggCarry")
        event:InvokeServer({
            Uid = uid
        })
    end)
    
    if success then
        print("[Auto Egg] 成功搬運:", uid)
    else
        warn("[Auto Egg] Remote 失敗:", err)
    end
    return success
end

-- 使用 Remote 裝備最佳
local function equipBest()
    local success, err = pcall(function()
        local event = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Backpack: EquipBest")
        event:InvokeServer()
    end)
    
    if success then
        print("[Equip Best] 已裝備最佳")
    else
        warn("[Equip Best] 失敗:", err)
    end
    return success
end

-- 尋找屬於選定區域的蛋
local function findTargetEgg()
    local eggFolder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if not eggFolder then return nil end

    local candidates = {}

    for _, egg in ipairs(eggFolder:GetChildren()) do
        if egg.Name:find("AreaEgg_") then
            local eggCF = getEggCFrame(egg)
            if eggCF then
                local closestArea, dist = getClosestArea(eggCF.Position)
                
                if closestArea == selectedArea then
                    table.insert(candidates, {
                        egg = egg,
                        cf = eggCF,
                        dist = dist
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b)
        return a.dist < b.dist
    end)

    return candidates[1].egg, candidates[1].cf
end

-- Auto Egg 主迴圈
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local egg, eggCF = findTargetEgg()
            
            if egg and eggCF then
                teleportTo(eggCF + Vector3.new(0, 4, 0))
                task.wait(0.25)
                
                carryEgg(egg.Name)
                task.wait(0.35)
                
                local startCF = getStartAreaCFrame()
                if startCF then
                    teleportTo(startCF)
                end
                
                task.wait(0.7)
            else
                print("[Auto Egg] 目前在 " .. selectedArea .. " 沒有屬於此區域的蛋")
                task.wait(1.2)
            end
        end
    end)
end

-- Equip Best 主迴圈
local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            equipBest()
            task.wait(2) -- 每 2 秒裝備一次，可自行調整
        end
    end)
end

-- ==================== UI ====================
local Hub = UIModule.CreateWindow("Bike For Egg", "TikTok: ValueHat")

-- Select Area
Hub:CreateDropdown("Select Area", areas, selectedArea, function(selected)
    selectedArea = selected
    print("[Select Area] 已選擇: " .. tostring(selected))
end)

-- Auto Egg 開關
Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then
        startAutoEgg()
        print("[Auto Egg] 已開啟")
    else
        print("[Auto Egg] 已關閉")
    end
end)

-- Equip Best 開關
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
