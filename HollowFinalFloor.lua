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

-- ==================== 強化版角色傳送函數 ====================
local function teleportMyCharacterTo(cf)
    if not cf then return end

    pcall(function()
        local charactersFolder = Workspace:FindFirstChild("Characters")
        local myName = LocalPlayer.Name
        local myCharModel = (charactersFolder and charactersFolder:FindFirstChild(myName)) or LocalPlayer.Character

        if myCharModel then
            if myCharModel:IsA("Model") then
                myCharModel:PivotTo(cf)
            end

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

-- ==================== Final Floor Escape 座標傳送邏輯 ====================
local function tpFinalFloorEscape()
    pcall(function()
        -- 指定的固定坐標 (X: 7356, Y: 1468, Z: 541)
        local targetPosition = Vector3.new(7356, 1468, 541)
        local targetCFrame = CFrame.new(targetPosition)

        teleportMyCharacterTo(targetCFrame)
        print("[Final Floor Escape] 成功傳送到坐標: 7356, 1468, 541")
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Finale Floor", "TikTok: ValueHat")

-- Final Floor Escape 按鈕
HubWindow:CreateButton("Final Floor Escape", tpFinalFloorEscape)

print("[ValueHat] Final Floor Escape (Custom Position) script loaded successfully!")
