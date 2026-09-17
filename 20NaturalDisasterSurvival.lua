-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("[20] Natural Disaster Survival", "TikTok: ValueHat")

-- UI 按鈕：Get Pet
Hub:CreateButton("Get Pet", function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        warn("[Get Pet] 找不到玩家的 HumanoidRootPart！")
        return
    end

    -- 尋找 workspace.NPCs 資料夾
    local npcsFolder = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("NPCs", true)

    if not npcsFolder then
        warn("[Get Pet] 找不到 NPCs 資料夾！")
        return
    end

    -- 尋找 NPCs 資料夾內的第一個 Model (NPC)
    local targetNPC = nil
    for _, child in ipairs(npcsFolder:GetChildren()) do
        if child:IsA("Model") then
            targetNPC = child
            break
        end
    end

    if not targetNPC then
        warn("[Get Pet] 在 NPCs 資料夾內找不到任何 Model！")
        return
    end

    print("[Get Pet] 找到目標 NPC: " .. targetNPC.Name .. "，準備傳送...")

    -- 1. 傳送到 NPC 的位置
    local targetCF = targetNPC:GetPivot()
    hrp.CFrame = targetCF * CFrame.new(0, 3, 0)
    task.wait(0.2)

    -- 2. 嘗試觸發 NPC 內部或附近的 ProximityPrompt
    for _, prompt in ipairs(targetNPC:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt)
            print("[Get Pet] 已觸發 ProximityPrompt！")
        end
    end

    task.wait(0.3)

    -- 3. 傳送回指定位置：workspace.Tower:GetChildren()[4]:GetChildren()[3]
    pcall(function()
        local tower = workspace:FindFirstChild("Tower")
        if tower then
            local towerChildren = tower:GetChildren()
            if towerChildren[4] then
                local subChildren = towerChildren[4]:GetChildren()
                local targetPart = subChildren[3]
                
                if targetPart then
                    local returnCF = targetPart:IsA("Model") and targetPart:GetPivot() or targetPart.CFrame
                    hrp.CFrame = returnCF * CFrame.new(0, 5, 0)
                    print("[Get Pet] 成功傳送回 Tower 指定位置！")
                else
                    warn("[Get Pet] 找不到 subChildren[3]！")
                end
            else
                warn("[Get Pet] towerChildren[4] 不存在！")
            end
        else
            warn("[Get Pet] 找不到 workspace.Tower！")
        end
    end)
end)

-- UI 開關：Anti Fling (使用 Anchored 鎖定邏輯)
Hub:CreateToggle("Anti Fling", false, function(isOn)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

    if humanoidRootPart then
        humanoidRootPart.Anchored = isOn
        print("[Anti Fling] Anchored 狀態: " .. tostring(isOn))
    else
        warn("[Anti Fling] 找不到 HumanoidRootPart！")
    end
end)
