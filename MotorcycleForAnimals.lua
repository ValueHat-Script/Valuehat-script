-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數
local selectedZone = "1"
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoEquipBestEnabled = false
local autoClaimIndexEnabled = false

-- 返回座標
local RETURN_POSITION = Vector3.new(666, 64, -661)

-- 即時傳送
local function teleportTo(cframe)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cframe
    end
end

-- 尋找指定 Zone 的所有 Model
local function getZoneModels(zoneNumber)
    local results = {}
    local zoneStr = "Zone" .. tostring(zoneNumber)

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(zoneStr) then
            table.insert(results, obj)
        end
    end
    return results
end

-- 取得背包 + 角色上的 Egg Tools
local function getEggTools()
    local eggs = {}

    local function check(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("Egg") then
                local id = item:GetAttribute("AnimalItemId") or item:GetAttribute("Id")
                if typeof(id) == "string" and #id > 10 then
                    table.insert(eggs, item)
                end
            end
        end
    end

    check(LocalPlayer.Backpack)
    check(LocalPlayer.Character)
    return eggs
end

-- 尋找自己的 Plot
local function getMyPlot()
    local plotsFolder = nil

    local spawn = workspace:FindFirstChild("Spawn")
    if spawn then
        plotsFolder = spawn:FindFirstChild("Plots")
    end

    if not plotsFolder then
        plotsFolder = workspace:FindFirstChild("Plots")
    end

    if not plotsFolder then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Plots" and (obj:IsA("Folder") or obj:IsA("Model")) then
                plotsFolder = obj
                break
            end
        end
    end

    if not plotsFolder then return nil end

    local myName = LocalPlayer.Name
    local myDisplay = LocalPlayer.DisplayName

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        for _, desc in ipairs(plot:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                local text = desc.Text or ""
                if text:find(myName) or text:find(myDisplay) 
                    or text:find("@" .. myName) or text:find("@" .. myDisplay)
                    or text:find(myName .. "'s") or text:find(myDisplay .. "'s") then
                    return plot
                end
            end
        end
    end

    return nil
end

-- 取得 PlacementArea 座標
local function getMyPlotPosition()
    local plot = getMyPlot()
    if not plot then return nil end

    local placement = plot:FindFirstChild("PlacementArea", true)
    if placement and placement:IsA("BasePart") then
        return placement.Position + Vector3.new(0, 1.5, 0)
    end

    local preferred = {
        "Part1", "Part3", "Part4", "Part5",
        "Plate", "Floor", "Base", "Ground", "Platform"
    }

    for _, name in ipairs(preferred) do
        local part = plot:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then
            return part.Position + Vector3.new(0, 2, 0)
        end
    end

    local plotSign = plot:FindFirstChild("PlotSign", true)
    if plotSign then
        if plotSign:IsA("BasePart") then
            return plotSign.Position + Vector3.new(0, 2, 0)
        elseif plotSign:IsA("Model") then
            return plotSign:GetPivot().Position + Vector3.new(0, 2, 0)
        end
    end

    if plot:IsA("Model") then
        return plot:GetPivot().Position + Vector3.new(0, 2, 0)
    end

    for _, desc in ipairs(plot:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Size.Magnitude > 5 then
            return desc.Position + Vector3.new(0, 2, 0)
        end
    end

    return nil
end

-- Zone 列表
local zoneList = {}
for i = 1, 10 do
    table.insert(zoneList, tostring(i))
end

-- 建立主視窗
local Hub = UIModule.CreateWindow("Motorcycle For animals", "TikTok: ValueHat")

-- Select Zone
Hub:CreateDropdown("Select Zone", zoneList, selectedZone, function(selected)
    selectedZone = selected
end)

-- Auto Egg
local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            local models = getZoneModels(selectedZone)

            for _, model in ipairs(models) do
                if not autoEggEnabled then break end

                local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)

                if prompt then
                    local targetCFrame = nil
                    local promptParent = prompt.Parent

                    if promptParent:IsA("BasePart") then
                        targetCFrame = promptParent.CFrame
                    elseif promptParent:IsA("Attachment") then
                        targetCFrame = promptParent.WorldCFrame
                    else
                        targetCFrame = model:GetPivot()
                    end

                    if targetCFrame then
                        teleportTo(targetCFrame * CFrame.new(0, 3, 0))
                        task.wait(0.35)

                        fireproximityprompt(prompt)
                        task.wait(0.4)

                        teleportTo(CFrame.new(RETURN_POSITION))
                        task.wait(0.4)
                    end
                end
            end

            task.wait(1)
        end
    end)
end

-- Auto Place
local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local remote = ReplicatedStorage:FindFirstChild("Remotes") 
                and ReplicatedStorage.Remotes:FindFirstChild("AnimalRequest")

            local eggTools = getEggTools()
            local placePos = getMyPlotPosition()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if remote and #eggTools > 0 and placePos and humanoid then
                local selectedTool = eggTools[math.random(1, #eggTools)]
                local eggId = selectedTool:GetAttribute("AnimalItemId") or selectedTool:GetAttribute("Id")

                humanoid:EquipTool(selectedTool)
                task.wait(0.3)

                remote:FireServer("PlaceEgg", eggId, placePos)
                task.wait(0.45)

                humanoid:UnequipTools()
            end

            task.wait(1.3)
        end
    end)
end

-- Auto Equip Best
local function startAutoEquipBest()
    task.spawn(function()
        while autoEquipBestEnabled do
            local remote = ReplicatedStorage:FindFirstChild("Remotes") 
                and ReplicatedStorage.Remotes:FindFirstChild("AnimalRequest")

            if remote then
                remote:FireServer("EquipBest", "")
            end

            task.wait(3)
        end
    end)
end

-- Auto Claim Index Reward
local function startAutoClaimIndex()
    task.spawn(function()
        while autoClaimIndexEnabled do
            local remote = ReplicatedStorage:FindFirstChild("Remotes") 
                and ReplicatedStorage.Remotes:FindFirstChild("ClaimIndexReward")

            if remote then
                pcall(function()
                    remote:InvokeServer("All")
                end)
            end

            task.wait(5)
        end
    end)
end

-- 開關
Hub:CreateToggle("Auto Egg", false, function(isOn)
    autoEggEnabled = isOn
    if autoEggEnabled then
        startAutoEgg()
    end
end)

Hub:CreateToggle("Auto Place", false, function(isOn)
    autoPlaceEnabled = isOn
    if autoPlaceEnabled then
        startAutoPlace()
    end
end)

Hub:CreateToggle("Auto Equip Best", false, function(isOn)
    autoEquipBestEnabled = isOn
    if autoEquipBestEnabled then
        startAutoEquipBest()
    end
end)

Hub:CreateToggle("Auto Claim Index Reward", false, function(isOn)
    autoClaimIndexEnabled = isOn
    if autoClaimIndexEnabled then
        startAutoClaimIndex()
    end
end)
