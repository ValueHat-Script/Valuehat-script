-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 輪播佇列與紀錄
local infectionQueue = {}
local currentInfectionIndex = 1

-- ==================== 強化版角色傳送函數 ====================
local function teleportMyCharacterTo(cf)
    if not cf then return end

    pcall(function()
        local charactersFolder = Workspace:FindFirstChild("Characters")
        local myName = LocalPlayer.Name
        
        -- 優先找 workspace.Characters[myName]，找不到了話退回使用 LocalPlayer.Character
        local myCharModel = (charactersFolder and charactersFolder:FindFirstChild(myName)) or LocalPlayer.Character

        if myCharModel then
            -- 1. 使用 PivotTo 進行跨 Model 位移
            if myCharModel:IsA("Model") then
                myCharModel:PivotTo(cf)
            end

            -- 2. 針對內部根零件強制設置 CFrame 雙重保障
            local root = myCharModel:FindFirstChild("HumanoidRootPart") or myCharModel.PrimaryPart or myCharModel:FindFirstChildWhichIsA("BasePart", true)
            if root then
                root.CFrame = cf
            end

            print("[ValueHat] 成功傳送至目標位置！")
        else
            warn("[ValueHat] 找不到玩家的角色模型: " .. tostring(myName))
        end
    end)
end

-- ==================== 重新整理並取得 Objectives 清單 ====================
local function refreshInfectionQueue()
    infectionQueue = {}

    local success = pcall(function()
        local terrain = Workspace:FindFirstChildWhichIsA("Terrain") or Workspace.Terrain
        local objectives = terrain and terrain:FindFirstChild("Objectives") or Workspace:FindFirstChild("Objectives")
        
        if not objectives then return end

        for _, obj in ipairs(objectives:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                table.insert(infectionQueue, obj)
            end
        end
    end)

    if not success or #infectionQueue == 0 then
        warn("[TP to Infections] 找不到 workspace.Terrain.Objectives 或裡面沒有任何目標模型！")
        return false
    end

    currentInfectionIndex = 1
    print("[TP to Infections] 已重置/載入目標清單，共 " .. tostring(#infectionQueue) .. " 個")
    return true
end

-- ==================== TP to Infections 輪播邏輯 ====================
local function tpNextInfection()
    if #infectionQueue == 0 or currentInfectionIndex > #infectionQueue then
        local success = refreshInfectionQueue()
        if not success then return end
    end

    local currentObj = infectionQueue[currentInfectionIndex]

    if currentObj and currentObj.Parent then
        local targetCFrame = nil
        if currentObj:IsA("BasePart") then
            targetCFrame = currentObj.CFrame
        elseif currentObj:IsA("Model") then
            local targetPart = currentObj.PrimaryPart or currentObj:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or currentObj:GetPivot()
        end

        if targetCFrame then
            teleportMyCharacterTo(targetCFrame + Vector3.new(0, 3, 0))
            print(string.format("[TP to Infections] [%d/%d] 已傳送到目標: %s", currentInfectionIndex, #infectionQueue, currentObj.Name))
            currentInfectionIndex = currentInfectionIndex + 1
        else
            warn("[TP to Infections] 該目標找不到有效座標，跳過")
            currentInfectionIndex = currentInfectionIndex + 1
            tpNextInfection()
        end
    else
        currentInfectionIndex = currentInfectionIndex + 1
        tpNextInfection()
    end
end

-- ==================== Escape 傳送邏輯 ====================
local function tpEscape()
    pcall(function()
        local terrain = Workspace:FindFirstChildWhichIsA("Terrain") or Workspace.Terrain
        if not terrain then
            warn("[Escape] 找不到 Terrain！")
            return
        end

        local homeCave = terrain:FindFirstChild("HomeCave")
        if not homeCave then
            warn("[Escape] 找不到 HomeCave！")
            return
        end

        local map = homeCave:FindFirstChild("Map")
        if not map then
            warn("[Escape] 找不到 Map！")
            return
        end

        local model = map:FindFirstChild("Model")
        if not model then
            warn("[Escape] 找不到 Model！")
            return
        end

        local platform = model:FindFirstChild("Meshes/platform no siderocks")
        if not platform then
            warn("[Escape] 找不到 Meshes/platform no siderocks！")
            return
        end

        local targetCFrame = nil
        if platform:IsA("BasePart") then
            targetCFrame = platform.CFrame
        elseif platform:IsA("Model") then
            local targetPart = platform.PrimaryPart or platform:FindFirstChildWhichIsA("BasePart", true)
            targetCFrame = targetPart and targetPart.CFrame or platform:GetPivot()
        end

        if targetCFrame then
            teleportMyCharacterTo(targetCFrame + Vector3.new(0, 5, 0))
            print("[Escape] 已成功傳送到 Escape 安全區域！")
        else
            warn("[Escape] 找不到 Escape 區域的有效座標！")
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Warden", "TikTok: ValueHat")

-- TP to Infections 按鈕
HubWindow:CreateButton("TP to Infections", function()
    tpNextInfection()
end)

-- Escape 按鈕
HubWindow:CreateButton("Escape", function()
    tpEscape()
end)

print("[ValueHat] Complete Script with Escape loaded successfully!")
