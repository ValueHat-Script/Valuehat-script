-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Power Fruit Evolution")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Islands = workspace.__STRUCTURALS.Islands
local Net = ReplicatedStorage:WaitForChild("_Net")
local EnemyKilled = Net:WaitForChild("EnemyKilled")
local EndRun = Net:WaitForChild("EndRun")
local AttackTick = Net:WaitForChild("AttackTick")
local TryRebirth = Net:WaitForChild("TryRebirth")

local SPAWN_WAIT = 5
local KILL_DELAY = 1
local CLEAR_CONFIRM = 3
local STAGE_DELAY = 0.5
local TELEPORT_HEIGHT = 25
local RESEND_INTERVAL = 3
local SEED_WAIT = 5
local SEED_COUNT = 4
local PROMPT_RANGE = 5
local SEED_STEP_DELAY = 0.3
local ROUND_DELAY = 1
local TRAIN_INTERVAL = 0.1
local REBIRTH_INTERVAL = 2  -- Auto Rebirth 嘗試間隔（秒）

local selectedStage = 1
local stageFarm = false
local fastTrain = false
local autoRebirth = false

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getIsland(n)
    local island = Islands:FindFirstChild(tostring(n))
    if island then return island end

    local list = Islands:GetChildren()
    table.sort(list, function(a, b)
        local na, nb = tonumber(a.Name:match("%d+")), tonumber(b.Name:match("%d+"))
        if na and nb then return na < nb end
        return a.Name < b.Name
    end)
    return list[n]
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

local function teleportToStage(n)
    local island = getIsland(n)
    local root = getRoot()
    local pos = island and getPos(island)
    if not island then print("[StageFarm] 找不到島:", n) end
    if root and pos then
        root.CFrame = CFrame.new(pos + Vector3.new(0, TELEPORT_HEIGHT, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    return false
end

local function countEnemies()
    local folder = workspace:FindFirstChild("_LocalEnemies")
    if not folder then return 0 end
    local count = 0
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            count += 1
        end
    end
    return count
end

local function sendKill(stage, count)
    local ids = {}
    for i = 1, count do
        ids[i] = i
    end
    local ok, err = pcall(function()
        EnemyKilled:FireServer(stage, ids)
    end)
    print("[StageFarm] EnemyKilled | Stage:", stage, "| 數量:", count, "| 成功:", ok, err or "")
end

local function firePromptsNear(root)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local pos = d.Parent and getPos(d.Parent)
            if pos and (pos - root.Position).Magnitude <= PROMPT_RANGE then
                d.HoldDuration = 0
                fireproximityprompt(d)
            end
        end
    end
end

local function collectSeeds()
    local folder = workspace:FindFirstChild("_SeedDrops")

    local waited = 0
    while stageFarm and (not folder or #folder:GetChildren() == 0) and waited < SEED_WAIT do
        task.wait(0.2)
        waited += 0.2
        folder = workspace:FindFirstChild("_SeedDrops")
    end
    if not folder then
        print("[StageFarm] 找不到 _SeedDrops")
        return
    end

    local seeds = {}
    for _, s in ipairs(folder:GetChildren()) do
        if #seeds >= SEED_COUNT then break end
        table.insert(seeds, s)
    end
    print("[StageFarm] 偵測到種子:", #seeds)

    for _, seed in ipairs(seeds) do
        if not stageFarm then break end
        local root = getRoot()
        local pos = seed.Parent and getPos(seed)
        if root and pos then
            root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            root.AssemblyLinearVelocity = Vector3.zero
            task.wait(SEED_STEP_DELAY)
            firePromptsNear(root)
            task.wait(SEED_STEP_DELAY)
        end
    end
end

UI:Input("Input", "Select Stage", "Number", function(text, entered)
    local n = tonumber(text)
    if n then
        selectedStage = math.clamp(math.floor(n), 1, 24)
        print("[StageFarm] Select Stage:", selectedStage)
    end
end)

UI:Toggle("Toggle", "Stage Farm", function(enabled)
    stageFarm = enabled
    if not enabled then return end

    task.spawn(function()
        while stageFarm do
            for stage = 1, selectedStage do
                if not stageFarm then break end

                teleportToStage(stage)

                local waited = 0
                while stageFarm and countEnemies() == 0 and waited < SPAWN_WAIT do
                    task.wait(0.2)
                    waited += 0.2
                end
                print("[StageFarm] Stage", stage, "偵測到敵人:", countEnemies())

                if countEnemies() > 0 then
                    task.wait(KILL_DELAY)

                    local lastSend = 0
                    local emptySince = nil

                    while stageFarm do
                        local count = countEnemies()

                        if count > 0 then
                            if emptySince ~= nil or os.clock() - lastSend >= RESEND_INTERVAL then
                                sendKill(stage, count)
                                lastSend = os.clock()
                            end
                            emptySince = nil
                        else
                            emptySince = emptySince or os.clock()
                            if os.clock() - emptySince >= CLEAR_CONFIRM then
                                break
                            end
                        end

                        task.wait(0.2)
                    end
                end

                if stageFarm and stage == selectedStage and countEnemies() == 0 then
                    collectSeeds()
                    if stageFarm then
                        local ok, err = pcall(function()
                            EndRun:FireServer()
                        end)
                        print("[StageFarm] EndRun | 成功:", ok, err or "")
                        task.wait(ROUND_DELAY)
                    end
                end

                task.wait(STAGE_DELAY)
            end
            task.wait(STAGE_DELAY)
        end
    end)
end)

UI:Toggle("Toggle", "Fast Train", function(enabled)
    fastTrain = enabled
    if not enabled then return end

    task.spawn(function()
        while fastTrain do
            AttackTick:FireServer(true)
            task.wait(TRAIN_INTERVAL)
        end
    end)
end)

UI:Toggle("Toggle", "Auto Rebirth", function(enabled)
    autoRebirth = enabled
    if not enabled then return end

    task.spawn(function()
        while autoRebirth do
            local ok, result = pcall(function()
                return TryRebirth:InvokeServer()
            end)
            print("[AutoRebirth] 成功:", ok, "| 回傳:", result)
            task.wait(REBIRTH_INTERVAL)
        end
    end)
end)
