-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數
local selectedStage = "1"
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false

-- 取得 EggService RemoteEvent
local function getEggRemote()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if not packages then return nil end
    local index = packages:FindFirstChild("_Index")
    if not index then return nil end
    local networker = index:FindFirstChild("leifstout_networker@0.3.1")
    if not networker then return nil end
    local net = networker:FindFirstChild("networker")
    if not net then return nil end
    local remotes = net:FindFirstChild("_remotes")
    if not remotes then return nil end
    local eggService = remotes:FindFirstChild("EggService")
    if not eggService then return nil end
    return eggService:FindFirstChild("RemoteEvent")
end

-- 取得所有可使用的蛋 Tool（Backpack + Character）
local function getEggTools()
    local eggs = {}

    local function checkContainer(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("Egg") then
                local id = item:GetAttribute("Id")
                if typeof(id) == "string" and #id > 10 then
                    table.insert(eggs, item)
                end
            end
        end
    end

    checkContainer(LocalPlayer.Backpack)
    checkContainer(LocalPlayer.Character)

    return eggs
end

-- 取得 Stages 資料夾
local function getStagesFolder()
    local required = workspace:FindFirstChild("REQUIRED")
    if required then
        local instances = required:FindFirstChild("Instances")
        if instances then
            local stages = instances:FindFirstChild("Stages")
            if stages then
                return stages
            end
        end
    end
    return workspace:FindFirstChild("Stages")
end

-- 自動掃描可用 Stage
local stageList = {}
local stagesFolder = getStagesFolder()

if stagesFolder then
    for _, child in ipairs(stagesFolder:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            table.insert(stageList, child.Name)
        end
    end
    table.sort(stageList, function(a, b)
        return (tonumber(a) or 0) < (tonumber(b) or 0)
    end)
end

if #stageList == 0 then
    for i = 1, 20 do
        table.insert(stageList, tostring(i))
    end
end

selectedStage = stageList[1] or "1"

-- 建立主視窗
local Hub = UIModule.CreateWindow("Survive Lava for animals", "TikTok: ValueHat")

-- Select Stages 下拉選單
Hub:CreateDropdown("Select Stages", stageList, selectedStage, function(selected)
    selectedStage = selected
end)

-- 取得角色 RootPart
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- 傳送函式
local function teleportTo(cf)
    local root = getRoot()
    if root then
        root.CFrame = cf
    end
end

-- 尋找最近的 Egg Model
local function findNearestEgg(fromPos, maxDistance)
    maxDistance = maxDistance or 100
    local nearest = nil
    local nearestDist = maxDistance

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Egg" then
            local pivot = obj:GetPivot()
            local dist = (pivot.Position - fromPos).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    return nearest
end

-- 取得返回點 (Map.Builds 的第 16 個)
local function getReturnCFrame()
    local required = workspace:FindFirstChild("REQUIRED")
    if not required then return nil end
    local instances = required:FindFirstChild("Instances")
    if not instances then return nil end
    local map = instances:FindFirstChild("Map")
    if not map then return nil end
    local builds = map:FindFirstChild("Builds")
    if not builds then return nil end

    local children = builds:GetChildren()
    local target = children[16]
    if not target then return nil end

    if target:IsA("BasePart") then
        return target.CFrame
    elseif target:IsA("Model") then
        return target:GetPivot()
    end
    return nil
end

-- 尋找自己的 Plot（優先匹配 DisplayName / Name）
local function getMyPlot()
    local plotsFolder = workspace:FindFirstChild("Plots")
        or (workspace:FindFirstChild("REQUIRED") and workspace.REQUIRED:FindFirstChild("Instances") and workspace.REQUIRED.Instances:FindFirstChild("Plots"))
        or workspace:FindFirstChild("Tycoons")
        or workspace:FindFirstChild("Bases")

    if not plotsFolder then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:lower():find("plot") or obj.Name:lower():find("base") or obj.Name:lower():find("tycoon") then
                plotsFolder = obj
                break
            end
        end
    end

    if not plotsFolder then return nil end

    local myName = LocalPlayer.Name
    local myDisplayName = LocalPlayer.DisplayName

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                local text = desc.Text
                if text == myDisplayName or text == myName then
                    return plot
                end
            end
        end
        if plot.Name == myName or plot.Name == myDisplayName then
            return plot
        end
    end

    return nil
end

-- 取得自己 Plot 的放置座標
local function getMyPlotPlacePosition()
    local myPlot = getMyPlot()
    if not myPlot then return nil end

    -- 優先找常見的放置表面
    local preferredNames = {"Plate", "Floor", "Base", "Ground", "Platform", "Plot", "BaseRoot"}
    for _, name in ipairs(preferredNames) do
        local part = myPlot:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then
            return part.Position + Vector3.new(0, 1, 0)  -- 稍微抬高一點
        end
    end

    -- 找不到就用 Plot 的中心點
    if myPlot:IsA("Model") then
        return myPlot:GetPivot().Position + Vector3.new(0, 1, 0)
    elseif myPlot:IsA("BasePart") then
        return myPlot.Position + Vector3.new(0, 1, 0)
    end

    -- 最後嘗試找任何 BasePart
    for _, desc in ipairs(myPlot:GetDescendants()) do
        if desc:IsA("BasePart") then
            return desc.Position + Vector3.new(0, 1, 0)
        end
    end

    return nil
end

-- 在自己的 Plot 中尋找 Ready 的蛋並觸發（不傳送）
local function hatchReadyEggsInMyPlot()
    local myPlot = getMyPlot()
    if not myPlot then return end

    for _, obj in ipairs(myPlot:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower() == "egg" or obj.Name:lower():find("egg")) then
            local isReady = false
            for _, desc in ipairs(obj:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                    if desc.Text:lower():find("ready") then
                        isReady = true
                        break
                    end
                end
            end

            if isReady then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    fireproximityprompt(prompt)
                    task.wait(0.35)
                end
            end
        end
    end
end

-- Auto Egg 主邏輯
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local stages = getStagesFolder()
            if not stages then
                task.wait(1)
                continue
            end

            local stageFolder = stages:FindFirstChild(selectedStage)
            if not stageFolder then
                task.wait(1)
                continue
            end

            local spawns = stageFolder:FindFirstChild("Spawns")
            if not spawns then
                task.wait(1)
                continue
            end

            local spawnPart = spawns:FindFirstChild("1")
            if not spawnPart then
                task.wait(1)
                continue
            end

            local spawnCF = spawnPart:IsA("BasePart") and spawnPart.CFrame or spawnPart:GetPivot()
            teleportTo(spawnCF * CFrame.new(0, 3, 0))
            task.wait(0.4)

            local root = getRoot()
            if root then
                local egg = findNearestEgg(root.Position, 80)

                if egg then
                    local eggCF = egg:GetPivot()
                    teleportTo(eggCF * CFrame.new(0, 3, 0))
                    task.wait(0.35)

                    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        fireproximityprompt(prompt)
                    end
                    task.wait(0.3)
                end
            end

            local returnCF = getReturnCFrame()
            if returnCF then
                teleportTo(returnCF * CFrame.new(0, 3, 0))
            end

            task.wait(1.2)
        end
    end)
end

-- Auto Place 主邏輯（自動裝備 + 放到自己 Plot 座標）
local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local remote = getEggRemote()
            local eggTools = getEggTools()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local placePos = getMyPlotPlacePosition()

            if remote and #eggTools > 0 and humanoid and placePos then
                local selectedTool = eggTools[math.random(1, #eggTools)]
                local eggId = selectedTool:GetAttribute("Id")

                -- 1. 自動裝備
                humanoid:EquipTool(selectedTool)
                task.wait(0.25)

                -- 2. 放置到自己 Plot 的座標
                remote:FireServer("placeEgg", eggId, placePos)
                task.wait(0.3)

                -- 3. 取消裝備
                humanoid:UnequipTools()
            end

            task.wait(1.2)
        end
    end)
end

-- Auto Hatch 主邏輯（不傳送，直接觸發 Ready 蛋）
local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            hatchReadyEggsInMyPlot()
            task.wait(1.5)
        end
    end)
end

-- Auto Egg 開關
Hub:CreateToggle("Auto Egg", false, function(isOn)
    autoEggEnabled = isOn
    if autoEggEnabled then
        startAutoEgg()
    end
end)

-- Auto Place 開關
Hub:CreateToggle("Auto Place", false, function(isOn)
    autoPlaceEnabled = isOn
    if autoPlaceEnabled then
        startAutoPlace()
    end
end)

-- Auto Hatch 開關
Hub:CreateToggle("Auto Hatch", false, function(isOn)
    autoHatchEnabled = isOn
    if autoHatchEnabled then
        startAutoHatch()
    end
end)
