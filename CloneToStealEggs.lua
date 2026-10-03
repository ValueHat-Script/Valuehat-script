-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數
local selectedArea = ""
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false

-- 即時傳送
local function teleportTo(cframe)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cframe
    end
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

-- 掃描 Areas
local areaList = {}
local areasFolder = workspace:FindFirstChild("Areas")

if areasFolder then
    for _, child in ipairs(areasFolder:GetChildren()) do
        if child:IsA("BasePart") or child:IsA("Model") then
            table.insert(areaList, child.Name)
        end
    end
    table.sort(areaList)
end

if #areaList == 0 then
    areaList = {"Blossom", "Cave", "Desert", "Galaxy", "Green", "Jurassic", "Ocean", "Volcano", "Winter"}
end

selectedArea = areaList[1]

local function getAreaBounds(areaName)
    local areas = workspace:FindFirstChild("Areas")
    if not areas then return nil end

    local area = areas:FindFirstChild(areaName)
    if not area then return nil end

    local part = area
    if area:IsA("Model") then
        part = area.PrimaryPart or area:FindFirstChildWhichIsA("BasePart", true)
    end
    if not part or not part:IsA("BasePart") then return nil end

    local pos = part.Position
    local size = part.Size
    local half = size / 2

    return {
        min = Vector3.new(pos.X - half.X, pos.Y - half.Y - 50, pos.Z - half.Z),
        max = Vector3.new(pos.X + half.X, pos.Y + half.Y + 50, pos.Z + half.Z),
        part = part
    }
end

local function isInBounds(pos, bounds)
    if not pos or not bounds then return false end
    return pos.X >= bounds.min.X and pos.X <= bounds.max.X
        and pos.Y >= bounds.min.Y and pos.Y <= bounds.max.Y
        and pos.Z >= bounds.min.Z and pos.Z <= bounds.max.Z
end

local function getAreaEggs(areaName)
    local list = {}
    local bounds = getAreaBounds(areaName)
    if not bounds then return list end

    local spawnedBases = workspace:FindFirstChild("SpawnedBases") or workspace

    for _, base in ipairs(spawnedBases:GetChildren()) do
        local baseCF = getCFrame(base)
        if baseCF and isInBounds(baseCF.Position, bounds) then
            for _, desc in ipairs(base:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local parent = desc.Parent
                    local cf = getCFrame(parent) or getCFrame(desc.Parent and desc.Parent.Parent)
                    if cf and isInBounds(cf.Position, bounds) then
                        table.insert(list, {
                            prompt = desc,
                            cframe = cf,
                            model = parent
                        })
                    end
                end
            end
        end
    end

    if #list == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local parent = obj.Parent
                local cf = getCFrame(parent)
                if cf and isInBounds(cf.Position, bounds) then
                    local name = (parent and parent.Name or ""):lower()
                    if name:find("egg") or name:find("star") or name:find("pick") then
                        table.insert(list, {
                            prompt = obj,
                            cframe = cf,
                            model = parent
                        })
                    end
                end
            end
        end
    end

    return list
end

local function getReturnCFrame()
    local model22 = workspace:FindFirstChild("Model22")
    if model22 then
        local part = model22:FindFirstChild("Part")
        if part and part:IsA("BasePart") then
            return part.CFrame
        end
        local anyPart = model22:FindFirstChildWhichIsA("BasePart", true)
        if anyPart then
            return anyPart.CFrame
        end
    end
    return nil
end

-- ==================== 找自己的 Plot ====================

local function getMyPlot()
    local myName = LocalPlayer.Name
    local myDisplay = LocalPlayer.DisplayName
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc.Name:find("FloatingPlotSign") then
                if desc.Name:find(myName, 1, true) or desc.Name:find(myDisplay, 1, true) then
                    return plot
                end
            end
            if desc:IsA("TextLabel") then
                local text = desc.Text or ""
                if text:find(myName, 1, true) or text:find(myDisplay, 1, true) then
                    return plot
                end
            end
            if desc.Name:find(myName, 1, true) or desc.Name:find(myDisplay, 1, true) then
                return plot
            end
        end
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local closest, closestDist = nil, math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            local surface = plot:FindFirstChild("PlotSurface") or plot:FindFirstChild("PlotSurface", true)
            local cf = surface and getCFrame(surface) or getCFrame(plot)
            if cf then
                local dist = (cf.Position - root.Position).Magnitude
                if dist < closestDist and dist < 80 then
                    closestDist = dist
                    closest = plot
                end
            end
        end
        if closest then return closest end
    end

    return nil
end

local function getPlotSurfaceCFrame()
    local plot = getMyPlot()
    if not plot then return nil end

    local surface = plot:FindFirstChild("PlotSurface")
        or plot:FindFirstChild("PlotSurface", true)

    if not surface then return nil end

    local cf = getCFrame(surface)
    if cf then
        return cf * CFrame.new(0, 1, 0)
    end
    return nil
end

-- ==================== Remote 共用 ====================

local function getServiceRF(serviceName, remoteName)
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local index = packages:FindFirstChild("_Index")
        if index then
            for _, child in ipairs(index:GetChildren()) do
                if child.Name:find("sleitnick_knit") then
                    local knit = child:FindFirstChild("knit")
                    local services = knit and knit:FindFirstChild("Services")
                    local service = services and services:FindFirstChild(serviceName)
                    local rf = service and service:FindFirstChild("RF")
                    if rf then
                        local remote = rf:FindFirstChild(remoteName)
                        if remote then return remote end
                    end
                end
            end
        end
    end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == remoteName and (obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent")) then
            return obj
        end
    end

    return nil
end

-- ==================== Auto Place ====================

local function getEggTools()
    local eggs = {}

    local function check(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("egg") or item.Name:find("Egg")) then
                local entityId = item:GetAttribute("EntityId") or item:GetAttribute("Uid") or item:GetAttribute("Id")
                if typeof(entityId) == "string" and #entityId > 10 then
                    table.insert(eggs, {tool = item, entityId = entityId})
                end
            end
        end
    end

    check(LocalPlayer:FindFirstChild("Backpack"))
    check(LocalPlayer.Character)

    return eggs
end

local function equipEggTool(tool)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not tool then return false end

    humanoid:UnequipTools()
    task.wait(0.1)
    humanoid:EquipTool(tool)
    task.wait(0.25)
    return true
end

local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local placeCF = getPlotSurfaceCFrame()
            local remote = getServiceRF("EggService", "PlaceEgg")
            local eggs = getEggTools()

            if placeCF and remote and #eggs > 0 then
                local chosen = eggs[math.random(1, #eggs)]

                if equipEggTool(chosen.tool) then
                    pcall(function()
                        remote:InvokeServer(chosen.entityId, placeCF)
                    end)

                    task.wait(0.4)

                    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:UnequipTools()
                    end
                end
            else
                if not placeCF then warn("[Auto Place] 找不到 PlotSurface") end
                if not remote then warn("[Auto Place] 找不到 PlaceEgg") end
                if #eggs == 0 then warn("[Auto Place] 沒有 Egg Tool") end
                task.wait(2)
            end

            task.wait(1.2)
        end
    end)
end

-- ==================== Auto Hatch（只孵 Ready!） ====================

local function isEggReady(eggModel)
    if not eggModel then return false end

    local billboard = eggModel:FindFirstChild("PlacedEggBillboard", true)
    if billboard then
        local timer = billboard:FindFirstChild("Timer")
        if timer and timer:IsA("TextLabel") then
            local text = (timer.Text or ""):lower()
            if text:find("ready") then
                return true
            end
        end
    end

    for _, desc in ipairs(eggModel:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local text = (desc.Text or ""):lower()
            if text:find("ready") then
                return true
            end
        end
    end

    return false
end

local function getPlacedEggsForHatch()
    local list = {}
    local plot = getMyPlot()
    if not plot then
        warn("[Auto Hatch] 找不到自己的 Plot")
        return list
    end

    local eggsFolder = plot:FindFirstChild("Eggs")
    if not eggsFolder then
        eggsFolder = plot:FindFirstChild("Eggs", true)
    end
    if not eggsFolder then
        warn("[Auto Hatch] Plot 裡找不到 Eggs 資料夾")
        return list
    end

    for _, child in ipairs(eggsFolder:GetChildren()) do
        if child:IsA("Model") and isEggReady(child) then
            local entityId = child:GetAttribute("EntityId")
                or child:GetAttribute("Uid")
                or child:GetAttribute("Id")

            table.insert(list, {
                model = child,
                entityId = (typeof(entityId) == "string" and #entityId > 10) and entityId or nil
            })
        end
    end

    return list
end

local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            local eggs = getPlacedEggsForHatch()
            local remote = getServiceRF("EggService", "HatchEgg")

            if #eggs > 0 then
                for _, data in ipairs(eggs) do
                    if not autoHatchEnabled then break end

                    if isEggReady(data.model) then
                        if remote and data.entityId then
                            pcall(function()
                                remote:InvokeServer(data.entityId)
                            end)
                        end

                        local prompt = data.model:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                        end
                    end

                    task.wait(0.4)
                end
            else
                task.wait(2)
            end

            task.wait(1.2)
        end
    end)
end

-- ==================== Equip Best ====================

local function equipBest()
    local remote = getServiceRF("AnimalService", "EquipBest")
    if remote then
        pcall(function()
            remote:InvokeServer()
        end)
    else
        warn("[Equip Best] 找不到 AnimalService.RF.EquipBest")
    end
end

local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            equipBest()
            task.wait(2)
        end
    end)
end

-- ==================== UI ====================

local Hub = UIModule.CreateWindow("Clone to steal eggs", "TikTok: ValueHat")

Hub:CreateDropdown("Select Area", areaList, selectedArea, function(v)
    selectedArea = v
end)

local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local eggs = getAreaEggs(selectedArea)

            if #eggs > 0 then
                local chosen = eggs[math.random(1, #eggs)]
                local cf = chosen.cframe
                local prompt = chosen.prompt

                if cf then
                    teleportTo(cf * CFrame.new(0, 3, 0))
                    task.wait(0.4)

                    if prompt and prompt.Enabled then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                        task.wait(0.35)
                    else
                        local character = LocalPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            for _, p in ipairs(workspace:GetDescendants()) do
                                if p:IsA("ProximityPrompt") and p.Enabled then
                                    local pos = getCFrame(p.Parent)
                                    if pos and (pos.Position - root.Position).Magnitude < 12 then
                                        pcall(function()
                                            fireproximityprompt(p)
                                        end)
                                        task.wait(0.35)
                                        break
                                    end
                                end
                            end
                        end
                    end

                    local ret = getReturnCFrame()
                    if ret then
                        teleportTo(ret * CFrame.new(0, 3, 0))
                    end
                    task.wait(0.4)
                end
            else
                warn("[Auto Egg] Area 「" .. selectedArea .. "」 找不到 Egg")
                task.wait(2)
            end

            task.wait(0.6)
        end
    end)
end

Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then startAutoEgg() end
end)

Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then startAutoPlace() end
end)

Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then startAutoHatch() end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        equipBest()
        startEquipBest()
    end
end)
