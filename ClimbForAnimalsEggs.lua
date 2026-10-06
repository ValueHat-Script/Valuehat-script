-- 動態載入 ValueHatGui UI 模組
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[Error] UI 模組載入失敗：", UIModule)
    return
end

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 遠端事件/函式 (Remote Functions)
local placeEvent, hatchEvent, equipBestEvent

pcall(function()
    placeEvent = ReplicatedStorage.src.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.EggPlacementService.RF.RequestToPlace
end)

pcall(function()
    hatchEvent = ReplicatedStorage.src.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.EggHatchService.RF.Hatch
end)

pcall(function()
    equipBestEvent = ReplicatedStorage.src.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.AnimalLoadoutService.RF.Request
end)

-- 區域列表
local zoneList = {
    "Forest",
    "Desert",
    "Divine Heights",
    "Crystal Mines",
    "Celestial",
    "Jungle",
    "Mystic Isles",
    "Ocean",
    "PreHistoric",
    "Winter"
}

-- 變數
local selectedZone = zoneList[1]
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false

-- 取得物件 CFrame
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

-- 傳送角色
local function teleportTo(cframe)
    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    pcall(function()
        character:PivotTo(cframe)
    end)

    task.wait()
    if root and root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- 傳送回 SafeZone
local function teleportToSafeZone()
    local safeZone = workspace:FindFirstChild("SafeZone")
    if safeZone then
        local cf = getCFrame(safeZone)
        if cf then
            teleportTo(cf * CFrame.new(0, 3, 0))
        else
            warn("[Auto Egg] 無法取得 SafeZone 的 CFrame")
        end
    else
        warn("[Auto Egg] 在 workspace 中找不到 SafeZone")
    end
end

-- 尋找自己的 Base (顯示 YOUR BASE)
local function getMyBase()
    local basesFolder = workspace:FindFirstChild("Structures") and workspace.Structures:FindFirstChild("Bases")

    if not basesFolder then
        basesFolder = workspace:FindFirstChild("Bases") or workspace:FindFirstChild("Plots")
    end

    if basesFolder then
        for _, base in ipairs(basesFolder:GetChildren()) do
            for _, desc in ipairs(base:GetDescendants()) do
                if desc:IsA("TextLabel") and (desc.Name == "PlayerName" or desc.Name:find("Player")) then
                    local text = desc.Text:upper()
                    if text:find("YOUR BASE") or text:find(LocalPlayer.Name:upper()) then
                        return base
                    end
                end
            end
        end
    end
    return nil
end

-- ==================== Equip Best 相關邏輯 ====================

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            if equipBestEvent then
                pcall(function()
                    equipBestEvent:InvokeServer("EquipBest", nil)
                end)
            else
                warn("[Equip Best] 找不到 AnimalLoadoutService 遠端物件！")
            end
            task.wait(2)
        end
    end)
end

-- ==================== Auto Hatch 相關邏輯 ====================

local function getPlacedEggIDs()
    local eggIDs = {}
    local base = getMyBase()
    if not base then return eggIDs end

    local placedEggsFolder = base:FindFirstChild("PlacedEggs", true)
    if placedEggsFolder then
        for _, eggModel in ipairs(placedEggsFolder:GetChildren()) do
            if eggModel:IsA("Model") or eggModel:IsA("BasePart") then
                local id = eggModel:GetAttribute("UUID") 
                    or eggModel:GetAttribute("EggId") 
                    or eggModel:GetAttribute("ID")
                    or eggModel.Name

                table.insert(eggIDs, id)
            end
        end
    end
    return eggIDs
end

local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            if hatchEvent then
                local placedEggIDs = getPlacedEggIDs()

                if #placedEggIDs > 0 then
                    for _, eggID in ipairs(placedEggIDs) do
                        if not autoHatchEnabled then break end

                        pcall(function()
                            hatchEvent:InvokeServer(eggID)
                        end)

                        task.wait(0.3)
                    end
                else
                    task.wait(1.5)
                end
            else
                warn("[Auto Hatch] 找不到 EggHatchService 遠端物件！")
                task.wait(2)
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== Auto Place 相關邏輯 ====================

local function getEggTools()
    local tools = {}
    local function scanContainer(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local handler = item:GetAttribute("Handler")
                local refName = item:GetAttribute("ReferenceName")
                
                if (handler == "Egg" or item.Name:lower():find("egg")) and refName then
                    table.insert(tools, {
                        tool = item,
                        referenceName = refName
                    })
                end
            end
        end
    end

    scanContainer(LocalPlayer:FindFirstChild("Backpack"))
    scanContainer(LocalPlayer.Character)
    return tools
end

local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local base = getMyBase()
            if base then
                local homeObj = base:FindFirstChild("Home", true)
                if homeObj then
                    local homeCF = getCFrame(homeObj)
                    local eggTools = getEggTools()

                    if #eggTools > 0 and homeCF and placeEvent then
                        local selected = eggTools[math.random(1, #eggTools)]
                        local character = LocalPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                        local offsetX = math.random(-10, 10)
                        local offsetZ = math.random(-10, 10)
                        local randomCFrame = homeCF * CFrame.new(offsetX, 0, offsetZ)

                        if humanoid and selected.tool.Parent ~= character then
                            humanoid:EquipTool(selected.tool)
                            task.wait(0.2)
                        end

                        pcall(function()
                            placeEvent:InvokeServer(selected.referenceName, randomCFrame)
                        end)

                        task.wait(0.5)
                    else
                        task.wait(1.5)
                    end
                else
                    warn("[Auto Place] 在 Base 中找不到 Home 物件")
                    task.wait(2)
                end
            else
                warn("[Auto Place] 找不到顯示 Your Base 的領域")
                task.wait(2)
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== Auto Egg 相關邏輯 ====================

local function getEggsInZone(zoneName)
    local list = {}
    local spawnedEggs = workspace:FindFirstChild("SpawnedEggs")
    if not spawnedEggs then return list end

    local zoneFolder = spawnedEggs:FindFirstChild(zoneName)
    if not zoneFolder then return list end

    for _, child in ipairs(zoneFolder:GetChildren()) do
        if child:IsA("Model") and child.Name ~= "Nest" then
            table.insert(list, child)
        end
    end

    return list
end

local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local eggs = getEggsInZone(selectedZone)

            if #eggs > 0 then
                local egg = eggs[math.random(1, #eggs)]
                local cf = getCFrame(egg)

                if cf then
                    teleportTo(cf * CFrame.new(0, 3, 0))
                    task.wait(0.35)

                    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                        task.wait(0.4)
                    else
                        local character = LocalPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            for _, p in ipairs(egg:GetDescendants()) do
                                if p:IsA("ProximityPrompt") and p.Enabled then
                                    pcall(function()
                                        fireproximityprompt(p)
                                    end)
                                    task.wait(0.4)
                                    break
                                end
                            end
                        end
                    end

                    teleportToSafeZone()
                    task.wait(1)
                end
            else
                warn("[Auto Egg] 在區域 " .. selectedZone .. " 中找不到可採集的蛋 (非 Nest)")
                task.wait(2)
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== UI 建立 ====================

local Hub = UIModule.CreateWindow("Climb for animals eggs", "TikTok: ValueHat")

-- Select Zone 選單
Hub:CreateDropdown("Select Zone", zoneList, selectedZone, function(v)
    selectedZone = v
    print("[Select Zone] 已切換區域至:", selectedZone)
end)

-- Auto Egg 開關
Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then
        startAutoEgg()
    end
end)

-- Auto Place 開關
Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then
        startAutoPlace()
    end
end)

-- Auto Hatch 開關
Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then
        startAutoHatch()
    end
end)

-- Equip Best 開關
Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        startEquipBest()
    end
end)

print("[ValueHat] Equip Best feature added successfully")
