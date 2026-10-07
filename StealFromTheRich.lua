-- 動態載入 ValueHatGui UI 模組
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 模組載入失敗：", UIModule)
    return
end

print("[ValueHat] UI 載入成功")

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local LocalPlayer = Players.LocalPlayer

-- 遠端事件/函式 (Remote Event / Remote Function)
local placeAtEvent, itemLoadoutEvent
pcall(function()
    placeAtEvent = ReplicatedStorage:FindFirstChild("re_PLACE_AT")
end)

pcall(function()
    itemLoadoutEvent = ReplicatedStorage:FindFirstChild("rf_ITEM_LOADOUT")
end)

-- 變數
local selectedZone = ""
local autoCrateEnabled = false
local autoPlaceEnabled = false
local autoOpenEnabled = false
local equipBestEnabled = false
local spawnCFrame = nil

local function teleportTo(cframe)
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(cframe)
    end)
end

local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Attachment") then
        return obj.WorldCFrame
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

-- 取得安全區 CFrame：優先找 workspace["Steal Map"].Lobby["safe zone"]
local function getSafeZoneCFrame()
    local safeZoneObj = nil
    pcall(function()
        safeZoneObj = workspace["Steal Map"].Lobby["safe zone"]
    end)

    if safeZoneObj then
        local cf = getCFrame(safeZoneObj)
        if cf then
            return cf * CFrame.new(0, 3, 0)
        end
    end

    -- 備用方案：尋找原生 SpawnLocation
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("SpawnLocation") then
                safeZoneObj = obj.CFrame * CFrame.new(0, 3, 0)
                break
            end
        end
    end)
    return safeZoneObj or spawnCFrame
end

-- 尋找屬於自己的 Plot 中的 floor
local function getMyPlotFloor()
    local myUserId = LocalPlayer.UserId
    local myName = LocalPlayer.Name:lower()

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "floor" or obj:GetAttribute("IsPlotFloor") then
            local ownerId = obj:GetAttribute("OwnerUserId")
            if ownerId and tonumber(ownerId) == myUserId then
                return obj
            end

            local parentPlot = obj.Parent
            if parentPlot then
                local plotSign = parentPlot:FindFirstChild("PlotSign", true)
                if plotSign then
                    local ownerNameLabel = plotSign:FindFirstChild("OwnerName", true)
                    if ownerNameLabel and ownerNameLabel:IsA("TextLabel") then
                        if ownerNameLabel.Text:lower():find(myName) then
                            return obj
                        end
                    end
                end
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "floor" and obj:IsA("BasePart") then
            local ownerId = obj:GetAttribute("OwnerUserId")
            if ownerId and tonumber(ownerId) == myUserId then
                return obj
            end
        end
    end

    return nil
end

local function forceFirePrompt(prompt)
    if not prompt then return false end

    local oldEnabled = prompt.Enabled
    local oldMaxDist = prompt.MaxActivationDistance
    local oldHold = prompt.HoldDuration
    local oldRequires = prompt.RequiresLineOfSight

    pcall(function()
        prompt.Enabled = true
        prompt.MaxActivationDistance = 999
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
    end)

    local ok = false

    pcall(function()
        fireproximityprompt(prompt)
        ok = true
    end)
    task.wait(0.05)

    pcall(function()
        fireproximityprompt(prompt, 1)
        ok = true
    end)
    task.wait(0.05)

    pcall(function()
        ProximityPromptService:InputHoldBegin(prompt)
        task.wait(0.2)
        ProximityPromptService:InputHoldEnd(prompt)
        ok = true
    end)

    pcall(function()
        prompt.Enabled = oldEnabled
        prompt.MaxActivationDistance = oldMaxDist
        prompt.HoldDuration = oldHold
        prompt.RequiresLineOfSight = oldRequires
    end)

    return ok
end

-- ==================== Equip Best 相關邏輯 ====================

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            if not itemLoadoutEvent then
                itemLoadoutEvent = ReplicatedStorage:FindFirstChild("rf_ITEM_LOADOUT")
            end

            if itemLoadoutEvent then
                pcall(function()
                    itemLoadoutEvent:InvokeServer("placebest")
                end)
            else
                warn("[Equip Best] 找不到 rf_ITEM_LOADOUT 遠端物件！")
            end
            task.wait(2)
        end
    end)
end

-- ==================== Auto Open 相關邏輯 ====================

local function startAutoOpen()
    task.spawn(function()
        while autoOpenEnabled do
            local ok, err = pcall(function()
                local floorObj = getMyPlotFloor()
                if floorObj then
                    local foundAny = false
                    for _, child in ipairs(floorObj:GetChildren()) do
                        if child.Name == "AppraisingCrate" or child.Name:find("Crate") then
                            for _, desc in ipairs(child:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") then
                                    foundAny = true
                                    forceFirePrompt(desc)
                                    task.wait(0.15)
                                    if not autoOpenEnabled then break end
                                end
                            end
                        end
                        if not autoOpenEnabled then break end
                    end

                    if not foundAny then
                        task.wait(1.5)
                    end
                else
                    warn("[Auto Open] 找不到自己的 Plot 地板 (floor)")
                    task.wait(2)
                end
            end)

            if not ok then
                warn("[Auto Open] 執行錯誤：", err)
                task.wait(1)
            end

            task.wait(0.3)
        end
    end)
end

-- ==================== Auto Place 相關邏輯 ====================

local function getCrateTools()
    local tools = {}
    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("crate") then
                table.insert(tools, item)
            end
        end
    end

    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return tools
end

local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local ok, err = pcall(function()
                if not placeAtEvent then
                    placeAtEvent = ReplicatedStorage:FindFirstChild("re_PLACE_AT")
                end

                local floorObj = getMyPlotFloor()
                local crateTools = getCrateTools()

                if floorObj and #crateTools > 0 and placeAtEvent then
                    local floorCF = getCFrame(floorObj)
                    if floorCF then
                        local selectedTool = crateTools[math.random(1, #crateTools)]
                        local character = LocalPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                        if humanoid and selectedTool.Parent ~= character then
                            humanoid:EquipTool(selectedTool)
                            task.wait(0.2)
                        end

                        local offsetX = math.random(-8, 8)
                        local offsetZ = math.random(-8, 8)
                        local placePos = floorCF.Position + Vector3.new(offsetX, 1.5, offsetZ)

                        placeAtEvent:FireServer(placePos, 0)
                        task.wait(0.5)
                    end
                else
                    if not floorObj then
                        warn("[Auto Place] 找不到自己的 Plot 地板 (floor)")
                    elseif #crateTools == 0 then
                        warn("[Auto Place] 背包內沒有包含 Crate 的工具")
                    end
                    task.wait(2)
                end
            end)

            if not ok then
                warn("[Auto Place] 執行錯誤：", err)
                task.wait(1)
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== Auto Crate 相關邏輯 ====================

local function getZoneFromName(name)
    local parts = string.split(name, "_")
    if #parts >= 2 and parts[1] == "Crate" then
        return parts[2]
    end
    return nil
end

local zoneList = {}
local zoneSet = {}

local function refreshZones()
    zoneList = {}
    zoneSet = {}

    pcall(function()
        local crates = workspace:FindFirstChild("Crates")
        if not crates then return end

        for _, child in ipairs(crates:GetChildren()) do
            local zone = getZoneFromName(child.Name)
            if zone and not zoneSet[zone] then
                zoneSet[zone] = true
                table.insert(zoneList, zone)
            end
        end
        table.sort(zoneList)
    end)

    if #zoneList == 0 then
        zoneList = {
            "Angel", "Archeologist", "Astronaut", "Celebrity",
            "DemonKing", "GoldTycoon", "Grandpa", "MafiaBoss",
            "MuseumOwner", "PirateCaptain"
        }
    end

    if selectedZone == "" or not zoneSet[selectedZone] then
        selectedZone = zoneList[1]
    end
end

refreshZones()

local function getZoneCrates(zoneName)
    local list = {}
    pcall(function()
        local crates = workspace:FindFirstChild("Crates")
        if not crates then return end

        for _, child in ipairs(crates:GetChildren()) do
            if getZoneFromName(child.Name) == zoneName then
                table.insert(list, child)
            end
        end
    end)
    return list
end

local function findPromptsInModel(model)
    local prompts = {}
    local seen = {}
    if not model then return prompts end

    pcall(function()
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("ProximityPrompt") and not seen[d] then
                seen[d] = true
                table.insert(prompts, d)
            end
        end
    end)

    return prompts
end

local function findNearbyPrompts(originPos, range)
    local prompts = {}
    range = range or 15

    pcall(function()
        for _, p in ipairs(workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local parent = p.Parent
                local pos = nil

                if parent then
                    if parent:IsA("Attachment") then
                        pos = parent.WorldPosition
                    elseif parent:IsA("BasePart") then
                        pos = parent.Position
                    else
                        local cf = getCFrame(parent)
                        if cf then pos = cf.Position end
                    end
                end

                if pos and (pos - originPos).Magnitude <= range then
                    table.insert(prompts, p)
                end
            end
        end
    end)

    return prompts
end

local function collectPrompts(crate, originPos)
    local prompts = {}
    local seen = {}

    local function add(list)
        for _, p in ipairs(list) do
            if not seen[p] then
                seen[p] = true
                table.insert(prompts, p)
            end
        end
    end

    for i = 1, 5 do
        add(findPromptsInModel(crate))
        add(findNearbyPrompts(originPos, 15))

        if #prompts > 0 then
            break
        end
        task.wait(0.25)
    end

    return prompts
end

task.spawn(function()
    task.wait(1)
    pcall(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart", 5)
        if root then
            spawnCFrame = root.CFrame
        end
    end)
end)

local function startAutoCrate()
    task.spawn(function()
        while autoCrateEnabled do
            local ok, err = pcall(function()
                local crates = getZoneCrates(selectedZone)

                if #crates > 0 then
                    local crate = crates[math.random(1, #crates)]
                    local cf = getCFrame(crate)

                    if cf then
                        teleportTo(cf * CFrame.new(0, 2, 0))
                        task.wait(0.4)

                        local originPos = cf.Position
                        local character = LocalPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            originPos = root.Position
                        end

                        local prompts = collectPrompts(crate, originPos)

                        if #prompts > 0 then
                            for _, prompt in ipairs(prompts) do
                                forceFirePrompt(prompt)
                                task.wait(0.2)
                            end
                        end
                        task.wait(0.4)

                        -- 傳送回安全的 Lobby 位置
                        local retCF = getSafeZoneCFrame()
                        if retCF then
                            teleportTo(retCF)
                        end
                        task.wait(0.4)
                    end
                else
                    task.wait(2)
                end
            end)

            if not ok then
                task.wait(1)
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== UI 建立 ====================

local Hub
local uiOk, uiErr = pcall(function()
    Hub = UIModule.CreateWindow("Steal from the rich", "TikTok: ValueHat")
end)

if not uiOk or not Hub then
    warn("[ValueHat] 建立視窗失敗：", uiErr)
    return
end

print("[ValueHat] 視窗建立成功")

Hub:CreateDropdown("Select Zone", zoneList, selectedZone, function(v)
    selectedZone = v
end)

Hub:CreateToggle("Auto Crate", false, function(on)
    autoCrateEnabled = on
    if on then
        startAutoCrate()
    end
end)

-- Auto Place 開關
Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then
        startAutoPlace()
    end
end)

-- Auto Open 開關
Hub:CreateToggle("Auto Open", false, function(on)
    autoOpenEnabled = on
    if on then
        startAutoOpen()
    end
end)

-- Equip Best 開關
Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        startEquipBest()
    end
end)

print("[ValueHat] Script loaded OK with Equip Best & SafeZone Target Updated")
