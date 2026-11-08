-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Break And Steal a Chicken Egg")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local EquipBest = ReplicatedStorage:WaitForChild("ChickenPen"):WaitForChild("EquipBest")
local RequestRebirth = ReplicatedStorage:WaitForChild("RebirthRemotes"):WaitForChild("RequestRebirth")

local RARITIES = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Ethereal", "Divine", "Cosmic", "Exotic", "Alpha"}

local TELEPORT_HEIGHT = 3    -- 傳送時高於蛋的距離（studs）
local SAFE_HEIGHT = 4        -- 傳回 Safe Zone 時高於它的距離（studs）
local NEAR_RANGE = 10        -- 蛋自身沒有 Prompt 時，搜尋周圍幾 studs 內的 Prompt
local PROMPT_RANGE = 5       -- 觸發角色周圍幾 studs 內的 Prompt
local FIRE_INTERVAL = 0.1    -- 持續觸發的間隔（秒）
local RETURN_DELAY = 1       -- 觸發後，等幾秒再傳回
local EQUIP_INTERVAL = 5     -- Equip Best 發送間隔（秒）
local REBIRTH_INTERVAL = 5   -- Auto Rebirth 發送間隔（秒）

local selectedRarity = "Common"
local autoEgg = false
local autoEquip = false
local autoRebirth = false
local returnCF = nil

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos(obj)
    if obj:IsA("Model") then
        return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Attachment") then
        return obj.WorldPosition
    end
end

-- 找 Safe Zone：名稱含 safezone / safe zone / safe_zone 的物件
local function findSafeZone()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("safezone", 1, true) or n:find("safe zone", 1, true) or n:find("safe_zone", 1, true) then
            if obj:IsA("BasePart") then
                return obj.Position
            elseif obj:IsA("Model") then
                return obj:GetPivot().Position
            else
                local part = obj:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.Position end
            end
        end
    end
    return nil
end

-- 回歸點：Safe Zone > RespawnLocation/SpawnLocation > 開啟開關時的位置
local function resolveReturnCF()
    local safePos = findSafeZone()
    if safePos then
        return CFrame.new(safePos + Vector3.new(0, SAFE_HEIGHT, 0))
    end

    warn("[Auto Egg] 找不到 Safe Zone，改用出生點")
    local spawn = LocalPlayer.RespawnLocation or workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then
        return spawn.CFrame + Vector3.new(0, 4, 0)
    end
    local root = getRoot()
    return root and root.CFrame
end

local function goBack()
    local root = getRoot()
    if root and returnCF then
        root.CFrame = returnCF
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

-- 讀取蛋的稀有度（Model 底下名為 Rarity 的 TextLabel）
local function getRarity(egg)
    local label = egg:FindFirstChild("Rarity", true)
    if label and label:IsA("TextLabel") then
        return (label.Text:gsub("^%s+", ""):gsub("%s+$", "")):lower()
    end
    return nil
end

-- 找該蛋的 Prompt：先找蛋底下，再找周圍
local function findPrompt(egg)
    local p = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if p then return p end

    local pos = getPos(egg)
    if not pos then return nil end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Parent then
            local pp = getPos(d.Parent)
            if pp and (pp - pos).Magnitude <= NEAR_RANGE then
                return d
            end
        end
    end
    return nil
end

-- 觸發角色周圍 PROMPT_RANGE 內的所有 Prompt，回傳觸發了幾個
local function fireNearbyPrompts()
    local root = getRoot()
    if not root then return 0 end

    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled and d.Parent then
            local pp = getPos(d.Parent)
            if pp and (pp - root.Position).Magnitude <= PROMPT_RANGE then
                d.HoldDuration = 0
                fireproximityprompt(d)
                count += 1
            end
        end
    end
    return count
end

-- 找離自己最近、稀有度符合的蛋
local function findNearestEgg()
    local folder = workspace:FindFirstChild("ActiveEggs")
    local root = getRoot()
    if not (folder and root) then return nil end

    local want = selectedRarity:lower()
    local best, bestDist = nil, math.huge

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") and getRarity(egg) == want then
            local pos = getPos(egg)
            if pos then
                local d = (pos - root.Position).Magnitude
                if d < bestDist then best, bestDist = egg, d end
            end
        end
    end
    return best
end

-- 處理單顆蛋：只傳送一次，持續觸發周圍 Prompt；回傳是否至少觸發過一次
local function handleEgg(egg)
    local root = getRoot()
    local pos = getPos(egg)
    if not (root and pos) then return false end

    root.CFrame = CFrame.new(pos + Vector3.new(0, TELEPORT_HEIGHT, 0))
    root.AssemblyLinearVelocity = Vector3.zero

    local fired = false

    while autoEgg do
        if fireNearbyPrompts() > 0 then
            fired = true
        end

        if fired then
            local prompt = egg.Parent and findPrompt(egg)
            if not egg.Parent or not prompt or not prompt.Parent or not prompt.Enabled then
                break
            end
        end

        task.wait(FIRE_INTERVAL)
    end

    return fired
end

UI:Dropdown("Dropdown", "Select Rarity", RARITIES, function(selected)
    selectedRarity = selected
    print("[Auto Egg] 選擇稀有度:", selected)
end)

UI:Toggle("Toggle", "Auto Egg", function(enabled)
    autoEgg = enabled

    if not enabled then
        goBack() -- 中途關閉就傳回 Safe Zone
        return
    end

    returnCF = resolveReturnCF()

    task.spawn(function()
        while autoEgg do
            local egg = findNearestEgg()
            if egg then
                local fired = handleEgg(egg)

                -- 有觸發過就一定等 RETURN_DELAY 秒再傳回 Safe Zone，之後才找下一顆
                if fired and autoEgg then
                    local t = os.clock()
                    while autoEgg and os.clock() - t < RETURN_DELAY do
                        task.wait(0.05)
                    end
                    if autoEgg then
                        goBack()
                        task.wait(0.5)
                    end
                elseif autoEgg then
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end)
end)

UI:Toggle("Toggle", "Equip Best", function(enabled)
    autoEquip = enabled
    if not enabled then return end

    task.spawn(function()
        while autoEquip do
            pcall(function()
                EquipBest:FireServer()
            end)
            task.wait(EQUIP_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Auto Rebirth", function(enabled)
    autoRebirth = enabled
    if not enabled then return end

    task.spawn(function()
        while autoRebirth do
            pcall(function()
                RequestRebirth:FireServer("rebirth")
            end)
            task.wait(REBIRTH_INTERVAL)
        end
    end)
end)
