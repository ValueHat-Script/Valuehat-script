-- ==================== ValueHat Gui 5 初始化 ====================
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("The Great Build")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local autoBlockLeverEnabled = false

-- ==================== 取得目標座標輔助函數 ====================
local function getTargetCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        return part and part.CFrame or obj:GetPivot()
    end
    return nil
end

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
        else
            warn("[Complete Obby] 找不到玩家的角色模型: " .. tostring(myName))
        end
    end)
end

-- ==================== Complete Obby 循序傳送邏輯 ====================
local function completeObby()
    task.spawn(function()
        pcall(function()
            local activitiesTest = Workspace:FindFirstChild("ActivitiesTest")
            if not activitiesTest then
                warn("[Complete Obby] 找不到 workspace.ActivitiesTest！")
                return
            end

            local obbyFolder = activitiesTest:FindFirstChild("Obby")
            local steps = {
                { label = "1/5 ObbyStart", obj = obbyFolder and obbyFolder:FindFirstChild("ObbyStart"), required = true },
                { label = "2/5 Checkpoint1", obj = activitiesTest:FindFirstChild("Checkpoint1"), required = false },
                { label = "3/5 Checkpoint2", obj = activitiesTest:FindFirstChild("Checkpoint2"), required = false },
                { label = "4/5 Checkpoint3", obj = activitiesTest:FindFirstChild("Checkpoint3"), required = false },
                { label = "5/5 ObbyFinish", obj = activitiesTest:FindFirstChild("ObbyFinish"), required = true },
            }

            for _, step in ipairs(steps) do
                local targetCFrame = getTargetCFrame(step.obj)
                if targetCFrame then
                    teleportMyCharacterTo(targetCFrame + Vector3.new(0, 3, 0))
                    print("[Complete Obby] 已傳送至 " .. step.label)
                    task.wait(0.25)
                elseif step.required then
                    warn("[Complete Obby] 找不到必要節點: " .. step.label)
                    return
                else
                    warn("[Complete Obby] 略過找不到的節點: " .. step.label)
                end
            end
        end)
    end)
end

-- ==================== Auto Block Lever 循環 ====================
local function triggerBlockLever()
    pcall(function()
        local hubLever = Workspace:FindFirstChild("HubLever")
        local baseDark = hubLever and hubLever:FindFirstChild("Base_Dark")
        local prompt = baseDark and baseDark:FindFirstChildOfClass("ProximityPrompt") or (baseDark and baseDark:FindFirstChild("ProximityPrompt"))

        if prompt and prompt:IsA("ProximityPrompt") then
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration or 0)
                prompt:InputHoldEnd()
            end
        end
    end)
end

task.spawn(function()
    while true do
        if autoBlockLeverEnabled then
            triggerBlockLever()
            task.wait(0.3)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== UI 設定 ====================
local function onAutoBlockLeverToggle(enabled)
    autoBlockLeverEnabled = enabled
    if enabled then
        print("[Auto Block Lever] 已開啟")
    else
        print("[Auto Block Lever] 已關閉")
    end
end

UI:Button("CompleteObbyBtn", "Complete Obby", completeObby)
UI:Toggle("AutoBlockLeverToggle", "Auto Block Lever", onAutoBlockLeverToggle)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Complete Obby & Auto Block Lever script loaded!")
