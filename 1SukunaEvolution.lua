-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("+1 Sukuna Evolution")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local TELEPORT_HEIGHT = 3   -- 傳送時高於 WinPad 的距離（studs）
local CLEAR_CONFIRM = 1     -- MyEnemies 連續沒有 Model 幾秒，才算清完
local SPAWN_WAIT = 2        -- 傳送後先等幾秒，讓敵人生成

local selectedStage = 1
local autoStage = false
local autoClick = false
local autoRebirth = false

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos(obj)
    if obj:IsA("Model") then
        return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
end

local function getStagesFolder()
    local map = workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Stages")
end

local function getSortedStages()
    local folder = getStagesFolder()
    if not folder then return {} end
    local list = folder:GetChildren()
    table.sort(list, function(a, b)
        local na, nb = tonumber(a.Name:match("%d+")), tonumber(b.Name:match("%d+"))
        if na and nb then return na < nb end
        return a.Name < b.Name
    end)
    return list
end

local stageNames = {}
local indexByName = {}
for i, s in ipairs(getSortedStages()) do
    table.insert(stageNames, s.Name)
    indexByName[s.Name] = i
end
if #stageNames == 0 then
    warn("[Auto Stage] 找不到 workspace.Map.Stages")
    stageNames = {"(找不到 Stage)"}
end

local function getStage(n)
    return getSortedStages()[n]
end

-- 傳送到指定物件
local function teleportToObj(targetObj, offsetY)
    local root = getRoot()
    if not root or not targetObj then return false end

    local pos = getPos(targetObj)
    if not pos then
        local part = targetObj:FindFirstChildWhichIsA("BasePart", true)
        pos = part and part.Position
    end

    if pos then
        root.CFrame = CFrame.new(pos + Vector3.new(0, offsetY or TELEPORT_HEIGHT, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    return false
end

-- 傳送到指定 Stage 的 Pads 中的 WinPad / PadWins 懸空
local function teleportToStageWinPad(n)
    local stageName = string.format("Stage%02d", n)
    local success, pad = pcall(function()
        local pads = workspace.Map.Stages[stageName].Pads
        return pads:FindFirstChild("WinPad") or pads:FindFirstChild("PadWins") or pads:FindFirstChildWhichIsA("BasePart")
    end)

    if success and pad then
        print("[Auto Stage] 傳送到 " .. stageName .. ".Pads 的 WinPad 上方懸空")
        return teleportToObj(pad, TELEPORT_HEIGHT)
    else
        warn("[Auto Stage] 找不到 workspace.Map.Stages." .. stageName .. ".Pads 中的 WinPad，嘗試尋找 Floor...")
        local stage = getStage(n)
        local floor = stage and stage:FindFirstChild("Floor", true)
        if floor then
            return teleportToObj(floor, TELEPORT_HEIGHT)
        end
    end
    return false
end

-- 計算場上「活著的」敵人數量
local function countEnemies()
    local folder = workspace:FindFirstChild("MyEnemies")
    if not folder then return 0 end
    local n = 0
    for _, c in ipairs(folder:GetChildren()) do
        if c:IsA("Model") then
            local hum = c:FindFirstChildWhichIsA("Humanoid")
            if not hum or hum.Health > 0 then
                n += 1
            end
        end
    end
    return n
end

local function waitCleared()
    local emptySince = nil
    while autoStage do
        if countEnemies() > 0 then
            emptySince = nil
        else
            emptySince = emptySince or os.clock()
            if os.clock() - emptySince >= CLEAR_CONFIRM then
                return true
            end
        end
        task.wait(0.2)
    end
    return false
end

-- 領取最終關卡獎勵
local function claimPadWins(stageIndex)
    local stageName = string.format("Stage%02d", stageIndex)
    local success, padWins = pcall(function()
        return workspace.Map.Stages[stageName].Pads.PadWins
    end)
    
    if success and padWins then
        print("[Auto Stage] 成功找到 " .. stageName .. ".Pads.PadWins，傳送中...")
        teleportToObj(padWins, TELEPORT_HEIGHT)
        task.wait(0.3)
    else
        warn("[Auto Stage] 找不到 workspace.Map.Stages." .. stageName .. ".Pads.PadWins")
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local claimPad = remotes and remotes:FindFirstChild("ClaimPad")
    if claimPad then
        print("[Auto Stage] 正在觸發 ClaimPad('PadWins')...")
        claimPad:FireServer("PadWins")
    else
        warn("[Auto Stage] 找不到 ReplicatedStorage.Remotes.ClaimPad")
    end
end

-- Auto Click 迴圈邏輯
local function startAutoClick()
    task.spawn(function()
        while autoClick do
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local clickEvent = remotes and remotes:FindFirstChild("Click")
                if clickEvent then
                    clickEvent:FireServer()
                end
            end)
            task.wait(0.05)
        end
    end)
end

-- Auto Rebirth 迴圈邏輯
local function startAutoRebirth()
    task.spawn(function()
        while autoRebirth do
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local rebirthEvent = remotes and remotes:FindFirstChild("Rebirth")
                if rebirthEvent then
                    rebirthEvent:FireServer()
                end
            end)
            task.wait(1)
        end
    end)
end

-- ==================== UI 介面設定 ====================
UI:Dropdown("Dropdown", "Select Stage", stageNames, function(selected)
    selectedStage = indexByName[selected] or 1
    print("[Auto Stage] Select Stage:", selected)
end)

UI:Toggle("Toggle", "Auto Stage", function(enabled)
    autoStage = enabled
    if not enabled then return end

    task.spawn(function()
        while autoStage do
            for stage = 1, selectedStage do
                if not autoStage then break end

                local stageObj = getStage(stage)
                local stageName = stageObj and stageObj.Name or string.format("Stage%02d", stage)

                print("[Auto Stage] 前往", stageName, "(", stage, "/", selectedStage, ")")
                teleportToStageWinPad(stage)

                task.wait(SPAWN_WAIT)
                if not waitCleared() then break end

                print("[Auto Stage]", stageName, "敵人已清空！")

                if stage == selectedStage then
                    claimPadWins(stage)
                    task.wait(1)
                end
            end
            print("[Auto Stage] 一輪完成，準備進入下一輪...")
            task.wait(1)
        end
        print("[Auto Stage] 已停止")
    end)
end)

UI:Toggle("AutoClickToggle", "Auto Click", function(enabled)
    autoClick = enabled
    if enabled then
        startAutoClick()
        print("[Auto Click] 已開啟")
    else
        print("[Auto Click] 已關閉")
    end
end)

UI:Toggle("AutoRebirthToggle", "Auto Rebirth", function(enabled)
    autoRebirth = enabled
    if enabled then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

UI:Status("Status", "Tik Tok: ValueHat")
