-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Steal Eggs From Tsunami")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local GuardAreas = workspace.__OBJECTS.Areas.GuardAreas
local NestEggs = workspace.NestEggs
local UpgradePen = ReplicatedStorage.UpgradePen
local UpgradeTreadmill = ReplicatedStorage.UpgradeTreadmill
local PetAction = ReplicatedStorage.PetAction

local PROMPT_RANGE = 5
local AREA_MARGIN = 10
local ROUND_DELAY = 0.5
local UPGRADE_COOLDOWN = 5
local EQUIP_COOLDOWN = 5

local autoEgg = false
local autoUpgrade = false
local autoTreadmill = false
local autoEquip = false
local selectedArea = nil

local function getPos(obj)
    if obj:IsA("Model") then
        return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
end

local function getBounds(area)
    if area:IsA("Model") then
        return area:GetBoundingBox()
    elseif area:IsA("BasePart") then
        return area.CFrame, area.Size
    end
end

local function inArea(pos, cf, size)
    local rel = cf:PointToObjectSpace(pos)
    return math.abs(rel.X) <= size.X / 2 + AREA_MARGIN
        and math.abs(rel.Y) <= size.Y / 2 + AREA_MARGIN
        and math.abs(rel.Z) <= size.Z / 2 + AREA_MARGIN
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function firePromptsNear(root)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local p = d.Parent
            local pos = p and ((p:IsA("Attachment") and p.WorldPosition) or getPos(p))
            if pos and (pos - root.Position).Magnitude <= PROMPT_RANGE then
                d.HoldDuration = 0
                fireproximityprompt(d)
            end
        end
    end
end

-- 找自己的 Plot：比對告示牌文字與 Name / DisplayName
local function findMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local myNames = {
        LocalPlayer.Name:lower(),
        LocalPlayer.DisplayName:lower(),
    }

    for i = 1, 7 do
        local plot = plots:FindFirstChild(tostring(i))
        local sign = plot
            and plot:FindFirstChild("PlotSign")
            and plot.PlotSign:FindFirstChild("PlayerPlotSign")
        local label = sign
            and sign:FindFirstChild("Frame")
            and sign.Frame:FindFirstChild("PlayerName")
        if label then
            local text = tostring(label.Text):lower()
            for _, n in ipairs(myNames) do
                if n ~= "" and text:find(n, 1, true) then
                    return plot
                end
            end
        end
    end
    return nil
end

local function findMyPetArea()
    local plot = findMyPlot()
    local toUpdate = plot and plot:FindFirstChild("ToUpdate")
    return toUpdate and toUpdate:FindFirstChild("PetArea")
end

local function getReturnCF(fallback)
    local petArea = findMyPetArea()
    if petArea then
        local pos = getPos(petArea)
        if not pos then
            local part = petArea:FindFirstChildWhichIsA("BasePart", true)
            pos = part and part.Position
        end
        if pos then
            return CFrame.new(pos + Vector3.new(0, 4, 0))
        end
    end
    local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then
        return spawn.CFrame + Vector3.new(0, 4, 0)
    end
    return fallback
end

local names = {}
for _, area in ipairs(GuardAreas:GetChildren()) do
    table.insert(names, area.Name)
end

UI:Dropdown("Dropdown", "Select Area", names, function(selected)
    selectedArea = selected
end)

UI:Toggle("Toggle", "Auto Egg", function(enabled)
    autoEgg = enabled
    if not enabled then return end

    task.spawn(function()
        local startRoot = getRoot()
        local fallbackCF = startRoot and startRoot.CFrame

        while autoEgg do
            local area = selectedArea and GuardAreas:FindFirstChild(selectedArea)
            local cf, size
            if area then
                cf, size = getBounds(area)
            end

            local didWork = false
            for _, egg in ipairs(NestEggs:GetChildren()) do
                if not autoEgg then break end
                local root = getRoot()
                local pos = getPos(egg)
                if root and pos and (not cf or inArea(pos, cf, size)) then
                    didWork = true
                    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                    task.wait(0.15)
                    firePromptsNear(root)
                    task.wait(0.15)

                    root = getRoot()
                    local returnCF = getReturnCF(fallbackCF)
                    if root and returnCF then
                        root.CFrame = returnCF
                    end
                    task.wait(ROUND_DELAY)
                end
            end

            if not didWork then
                task.wait(1)
            end
        end
    end)
end)

UI:Toggle("Toggle", "Upgrade Pen", function(enabled)
    autoUpgrade = enabled
    if not enabled then return end

    task.spawn(function()
        while autoUpgrade do
            UpgradePen:FireServer()
            task.wait(UPGRADE_COOLDOWN)
        end
    end)
end)

UI:Toggle("Toggle", "Upgrade Treadmill", function(enabled)
    autoTreadmill = enabled
    if not enabled then return end

    task.spawn(function()
        while autoTreadmill do
            UpgradeTreadmill:FireServer()
            task.wait(UPGRADE_COOLDOWN)
        end
    end)
end)

UI:Toggle("Toggle", "Equip Best", function(enabled)
    autoEquip = enabled
    if not enabled then return end

    task.spawn(function()
        while autoEquip do
            PetAction:FireServer("EquipBest")
            task.wait(EQUIP_COOLDOWN)
        end
    end)
end)
