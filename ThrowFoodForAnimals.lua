-- 安全載入 UI (帶詳細錯誤捕捉)
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗！請檢查執行器是否支援 loadstring，或網路連線是否正常。錯誤訊息: " .. tostring(UIModule))
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 狀態變數
local perfectThrowEnabled = false
local equipBestEnabled = false
local tapBonusEnabled = false

-- ==================== Perfect Throw 邏輯 ====================
local function startPerfectThrow()
    task.spawn(function()
        while perfectThrowEnabled do
            pcall(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                
                -- 1. Throw_Start
                local eventStart = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Throw_Start")
                if eventStart then
                    eventStart:InvokeServer()
                end

                -- 2. Throw_Resolve
                local eventResolve = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Throw_Resolve")
                if eventResolve then
                    eventResolve:InvokeServer(1)
                end

                -- 3. Throw_Complete
                local eventComplete = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Throw_Complete")
                if eventComplete then
                    eventComplete:InvokeServer()
                end
            end)
            task.wait()
        end
    end)
end

-- ==================== Equip Best 邏輯 ====================
local function startEquipBest()
    task.spawn(function()
        while equipBestEnabled do
            pcall(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local event = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Plot_EquipBest")
                if event then
                    event:InvokeServer()
                end
            end)
            task.wait(1)
        end
    end)
end

-- ==================== 自動點擊 TapBonus 邏輯 ====================
local function startTapBonus()
    task.spawn(function()
        while tapBonusEnabled do
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local trainingSeq = playerGui and playerGui:FindFirstChild("TrainingSequence")
                local tapBonusLayer = trainingSeq and trainingSeq:FindFirstChild("TapBonusLayer")
                local tapBonusBtn = tapBonusLayer and tapBonusLayer:FindFirstChild("TapBonus")

                if tapBonusBtn then
                    if tapBonusBtn:IsA("GuiButton") then
                        for _, connection in ipairs(getconnections(tapBonusBtn.Activated)) do
                            connection:Fire()
                        end
                        for _, connection in ipairs(getconnections(tapBonusBtn.MouseButton1Click)) do
                            connection:Fire()
                        end
                    elseif tapBonusBtn:IsA("GuiObject") then
                        if typeof(firesignal) == "function" then
                            firesignal(tapBonusBtn.MouseButton1Click)
                            firesignal(tapBonusBtn.Activated)
                        end
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ==================== Sell All 邏輯 ====================
local function sellAllTrigger()
    task.spawn(function()
        pcall(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local event = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Plot_SellAll")
            if event then
                event:InvokeServer()
                print("[Sell All] 成功執行賣出全部！")
            else
                warn("[Sell All] 找不到 Plot_SellAll 事件！")
            end
        end)
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("Throw Food for Animals", "TikTok: ValueHat")

HubWindow:CreateToggle("Perfect Throw", false, function(on)
    perfectThrowEnabled = on
    if on then
        startPerfectThrow()
        print("[Perfect Throw] 已開啟")
    else
        print("[Perfect Throw] 已關閉")
    end
end)

HubWindow:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        startEquipBest()
        print("[Equip Best] 已開啟")
    else
        print("[Equip Best] 已關閉")
    end
end)

HubWindow:CreateToggle("x2 Train", false, function(on)
    tapBonusEnabled = on
    if on then
        startTapBonus()
        print("[TapBonus] 已開啟")
    else
        print("[TapBonus] 已關閉")
    end
end)

HubWindow:CreateButton("Sell All", function()
    sellAllTrigger()
end)

print("[ValueHat] Perfect Throw, Equip Best, TapBonus & Sell All script loaded successfully!")
