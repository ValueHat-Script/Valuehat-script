-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Steal a PC")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PenPanel = ReplicatedStorage:WaitForChild("SAP"):WaitForChild("Remotes"):WaitForChild("PenPanel")

local ZONE_MARGIN = 10      -- 區域邊界外擴範圍(studs)
local TELEPORT_HEIGHT = 3   -- 傳送時高於 Box 的距離
local SAFE_POSITION = Vector3.new(-1, 3, 49) -- 傳回的固定座標
local PROMPT_RANGE = 5      -- 觸發角色周圍幾 studs 內的 Prompt
local FIRE_INTERVAL = 0.05  -- 持續觸發的間隔(秒)
local RETURN_DELAY = 0.2    -- 觸發完後，等幾秒再傳回
local RETURN_STAY = 1       -- 傳回後停留幾秒，再去下一顆
local SKIP_TIME = 10        -- 處理過的 Box 幾秒內不再選
local EQUIP_INTERVAL = 5    -- Equip Best 呼叫間隔(秒)
local BUBBLE_INTERVAL = 0.1 -- Auto Train Bubbles 點擊間隔(秒)

local selectedZone = nil
local autoPC = false
local autoEquip = false
local autoBubbles = false
local skipped = setmetatable({}, {__mode = "k"})

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

-- 傳回固定座標
local function goSafe()
    local root = getRoot()
    if not root then return end
    root.CFrame = CFrame.new(SAFE_POSITION)
    root.AssemblyLinearVelocity = Vector3.zero
end

-- 取得區域的範圍(支援 Part、Model、Folder)
local function getBounds(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame, obj.Size
    elseif obj:IsA("Model") then
        return obj:GetBoundingBox()
    end

    local minV, maxV
    for _, p in ipairs(obj:GetDescendants()) do
        if p:IsA("BasePart") then
            local cf, s = p.CFrame, p.Size
            local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
            local half = Vector3.new(
                math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
                math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
                math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
            ) / 2
            local lo, hi = cf.Position - half, cf.Position + half
            minV = minV and Vector3.new(math.min(minV.X, lo.X), math.min(minV.Y, lo.Y), math.min(minV.Z, lo.Z)) or lo
            maxV = maxV and Vector3.new(math.max(maxV.X, hi.X), math.max(maxV.Y, hi.Y), math.max(maxV.Z, hi.Z)) or hi
        end
    end
    if not minV then return nil end
    return CFrame.new((minV + maxV) / 2), maxV - minV
end

local function getZonesFolder()
    local map = workspace:FindFirstChild("SAPMap")
    return map and map:FindFirstChild("Zones")
end

-- 選單:workspace.SAPMap.Zones 底下的區域(排除 End),依名稱數字排序
local zoneNames = {}
local zones = getZonesFolder()
if zones then
    for _, z in ipairs(zones:GetChildren()) do
        if z.Name:lower() ~= "end" then
            table.insert(zoneNames, z.Name)
        end
    end
    table.sort(zoneNames, function(a, b)
        local na, nb = tonumber(a:match("%d+")), tonumber(b:match("%d+"))
        if na and nb then return na < nb end
        return a < b
    end)
else
    warn("[Auto PC] 找不到 workspace.SAPMap.Zones")
    zoneNames = {"(找不到區域)"}
end

local function inZone(pos, cf, size)
    local rel = cf:PointToObjectSpace(pos)
    return math.abs(rel.X) <= size.X / 2 + ZONE_MARGIN
        and math.abs(rel.Y) <= size.Y / 2 + ZONE_MARGIN
        and math.abs(rel.Z) <= size.Z / 2 + ZONE_MARGIN
end

-- 偵測選擇區域內的所有 Box,依離自己的距離由近到遠排序
local function detectBoxes()
    local folder = getZonesFolder()
    local zone = folder and selectedZone and folder:FindFirstChild(selectedZone)
    local boxes = workspace:FindFirstChild("SAPBoxes")
    local root = getRoot()
    if not (zone and boxes and root) then return {} end

    local cf, size = getBounds(zone)
    if not cf then return {} end

    local list, now = {}, os.clock()
    for _, box in ipairs(boxes:GetChildren()) do
        if not (skipped[box] and now - skipped[box] < SKIP_TIME) then
            local pos = getPos(box)
            if pos and inZone(pos, cf, size) then
                table.insert(list, {box = box, dist = (pos - root.Position).Magnitude})
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

-- 觸發角色周圍 PROMPT_RANGE 內的 Prompt,回傳觸發數量
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

-- 找這顆 Box 自己的 Prompt
local function findBoxPrompt(box)
    return box:FindFirstChildWhichIsA("ProximityPrompt", true)
end

-- 處理單顆 Box:只傳送一次並持續觸發;只看該 Box 自己的 Prompt 判斷是否觸發完
local function handleBox(box)
    local root = getRoot()
    local pos = getPos(box)
    if not (root and pos) then return false end

    root.CFrame = CFrame.new(pos + Vector3.new(0, TELEPORT_HEIGHT, 0))
    root.AssemblyLinearVelocity = Vector3.zero

    local fired = false
    while autoPC and box.Parent do
        fireNearbyPrompts()

        local p = findBoxPrompt(box)
        if p then
            fired = true
            if not p.Enabled then break end
        elseif fired then
            break
        end
        task.wait(FIRE_INTERVAL)
    end

    skipped[box] = os.clock()
    return fired
end

-- 點擊 GUI 按鈕
local function pressButton(btn)
    pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Down)
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            firesignal(btn.MouseButton1Up)
        elseif getconnections then
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
        end
    end)
end

-- 找 PlayerGui 裡 TrainingBubbles 底下所有可見的 Bubble 按鈕
local function findBubbles()
    local list = {}
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return list end

    for _, d in ipairs(gui:GetDescendants()) do
        if d.Name == "TrainingBubbles" then
            for _, b in ipairs(d:GetDescendants()) do
                if b.Name == "Bubble" and b:IsA("GuiButton") and b.Visible then
                    table.insert(list, b)
                end
            end
        end
    end
    return list
end

UI:Dropdown("Dropdown", "Select Zone", zoneNames, function(selected)
    selectedZone = selected
    print("[Auto PC] 選擇區域:", selected)
end)

UI:Toggle("Toggle", "Auto PC", function(enabled)
    autoPC = enabled
    if not enabled then return end

    task.spawn(function()
        while autoPC do
            local list = detectBoxes()
            if #list > 0 then
                print("[Auto PC]", selectedZone, "偵測到 Box:", #list)
                for _, item in ipairs(list) do
                    if not autoPC then break end
                    if item.box.Parent then
                        handleBox(item.box)
                        if not autoPC then break end
                        task.wait(RETURN_DELAY)
                        goSafe()
                        task.wait(RETURN_STAY)
                    end
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
            local ok, result = pcall(function()
                return PenPanel:InvokeServer("equipBest")
            end)
            print("[EquipBest] 成功:", ok, "| 回傳:", result)
            task.wait(EQUIP_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Auto Train Bubbles", function(enabled)
    autoBubbles = enabled
    if not enabled then return end

    task.spawn(function()
        while autoBubbles do
            for _, b in ipairs(findBubbles()) do
                if not autoBubbles then break end
                pressButton(b)
            end
            task.wait(BUBBLE_INTERVAL)
        end
    end)
end)
