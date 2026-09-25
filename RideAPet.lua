-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("Ride A Pet", "TikTok: ValueHat")

-- 服務與玩家設定
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 變數設定
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoRebirthEnabled = false
local selectedLuck = "All"
local tweenSpeed = 500 -- Tween 移動速度 (Studs/s)

-- 常用 Luck 倍率選項
local luckOptions = {
    "All", "5", "30", "50", "100", "200", "500", "750", 
    "1K", "3K", "10K", "30K", "90K", "150K", "250K", "500K", 
    "700K", "1M", "3M", "7M", "300M", "1.5B", "100B", "300B", "1T"
}

-- 取得 Remote Events
local GameRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game")
local EggPlacedRemote = GameRemotes and GameRemotes:FindFirstChild("EggPlaced")
local RebirthRemote = GameRemotes and GameRemotes:FindFirstChild("Rebirth")

------------------------------------------------------------------
-- [ UI 元件建立 ]
------------------------------------------------------------------

-- UI 開關：Auto Egg (採集)
Hub:CreateToggle("Auto Egg", false, function(isOn)
    autoEggEnabled = isOn
    print("[Auto Egg] 開關狀態: " .. tostring(isOn))
end)

-- UI 下拉選單：Select Egg Luck
Hub:CreateDropdown("Select Egg Luck", luckOptions, "All", function(option)
    selectedLuck = option
    print("[Select Egg Luck] 當前選擇: " .. tostring(option))
end)

-- UI 開關：Auto Place Egg (自動放蛋)
Hub:CreateToggle("Auto Place Egg", false, function(isOn)
    autoPlaceEnabled = isOn
    print("[Auto Place Egg] 開關狀態: " .. tostring(isOn))
end)

-- UI 開關：Auto Rebirth (自動轉生 - 5秒冷卻)
Hub:CreateToggle("Auto Rebirth", false, function(isOn)
    autoRebirthEnabled = isOn
    print("[Auto Rebirth] 開關狀態: " .. tostring(isOn))
end)

------------------------------------------------------------------
-- [ 輔助函式：讀取蛋的 Luck 倍率數值 ]
------------------------------------------------------------------

local function GetEggLuckValue(eggModel)
    if not eggModel then return "" end

    for _, descendant in ipairs(eggModel:GetDescendants()) do
        if descendant:IsA("TextLabel") and (descendant.Name == "Luck" or descendant.Parent.Name == "EggLuck") then
            return tostring(descendant.Text):gsub("%s+", "")
        end
    end
    return ""
end

------------------------------------------------------------------
-- [ 輔助函式：自動裝備名稱含 "Egg" 的 Tool ]
------------------------------------------------------------------

local function EquipEggTool()
    local character = LocalPlayer.Character
    if not character then return false end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return false end

    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
            return true
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and string.find(string.lower(tool.Name), "egg") then
                humanoid:EquipTool(tool)
                print("[Auto Place] 已裝備蛋道具: " .. tool.Name)
                task.wait(0.1)
                return true
            end
        end
    end

    return false
end

------------------------------------------------------------------
-- [ 輔助函式：尋找玩家自己的 Plot ]
------------------------------------------------------------------

local function GetMyPlotCFrame()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local dataFolder = plot:FindFirstChild("Data")
        if dataFolder then
            local ownerVal = dataFolder:FindFirstChild("Owner")
            if ownerVal then
                local ownerName = ""
                if ownerVal:IsA("StringValue") then
                    ownerName = ownerVal.Value
                elseif ownerVal:IsA("ObjectValue") and ownerVal.Value then
                    ownerName = ownerVal.Value.Name
                elseif type(ownerVal) == "string" then
                    ownerName = ownerVal
                end

                if ownerName == LocalPlayer.Name or ownerName == LocalPlayer.DisplayName then
                    if plot:IsA("Model") then
                        return plot:GetPivot()
                    elseif plot:IsA("BasePart") then
                        return plot.CFrame
                    end
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------------
-- [ 輔助函式：Tween 移動 & ProximityPrompt 觸發 ]
------------------------------------------------------------------

local function TweenToCFrame(targetCFrame)
    local character = LocalPlayer.Character
    if not character then return false end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local distance = (targetCFrame.Position - rootPart.Position).Magnitude
    local duration = math.clamp(distance / tweenSpeed, 0.1, 10)

    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rootPart, tweenInfo, { CFrame = targetCFrame })

    tween:Play()
    tween.Completed:Wait()
    return true
end

local function ForceTriggerPrompts(model)
    if not model then return end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            pcall(function()
                descendant.Enabled = true
                descendant.HoldDuration = 0
                descendant.RequiresLineOfSight = false

                if type(fireproximityprompt) == "function" then
                    fireproximityprompt(descendant)
                    task.wait(0.05)
                    fireproximityprompt(descendant, 0)
                else
                    descendant:InputHoldBegin()
                    task.wait(0.05)
                    descendant:InputHoldEnd()
                end
            end)
        end
    end
end

------------------------------------------------------------------
-- [ Auto Rebirth 主邏輯迴圈 (5秒冷卻) ]
------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(5) -- 5 秒冷卻
        if autoRebirthEnabled and RebirthRemote then
            pcall(function()
                RebirthRemote:FireServer()
                print("[Auto Rebirth] 已執行轉生！")
            end)
        end
    end
end)

------------------------------------------------------------------
-- [ Auto Place Egg 主邏輯迴圈 ]
------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.3)
        if autoPlaceEnabled then
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if rootPart and EggPlacedRemote then
                EquipEggTool()

                pcall(function()
                    EggPlacedRemote:FireServer({
                        PlantPosition = rootPart.Position
                    })
                end)
            end
        end
    end
end)

------------------------------------------------------------------
-- [ Auto Egg 主邏輯迴圈 (含 Luck 篩選) ]
------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.5)

        if autoEggEnabled then
            local renderedEggsFolder = workspace:FindFirstChild("RenderedEggs")

            if renderedEggsFolder then
                local eggModels = {}

                for _, child in ipairs(renderedEggsFolder:GetChildren()) do
                    if child:IsA("Model") or child:IsA("BasePart") then
                        if selectedLuck == "All" then
                            table.insert(eggModels, child)
                        else
                            local luckText = GetEggLuckValue(child)
                            if string.find(string.lower(luckText), string.lower(selectedLuck)) then
                                table.insert(eggModels, child)
                            end
                        end
                    end
                end

                if #eggModels > 0 then
                    local randomEgg = eggModels[math.random(1, #eggModels)]
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                    if rootPart and randomEgg and randomEgg.Parent then
                        local targetCFrame = nil
                        if randomEgg:IsA("Model") then
                            targetCFrame = randomEgg:GetPivot()
                        elseif randomEgg:IsA("BasePart") then
                            targetCFrame = randomEgg.CFrame
                        end

                        if targetCFrame then
                            print("[Auto Egg] 採集目標: " .. randomEgg.Name .. " (Luck: " .. selectedLuck .. ")")

                            -- 1. Tween 移動至目標位置
                            TweenToCFrame(targetCFrame + Vector3.new(0, 1.5, 0))
                            task.wait(0.2)

                            -- 2. 觸發 Pickup Prompt
                            ForceTriggerPrompts(randomEgg)
                            task.wait(0.3)

                            -- 3. 返回玩家自己的 Plot
                            local myPlotCF = GetMyPlotCFrame()
                            if myPlotCF then
                                print("[Auto Egg] 返回玩家 Plot...")
                                TweenToCFrame(myPlotCF + Vector3.new(0, 3, 0))
                            else
                                warn("[Auto Egg] 找不到與玩家名字相符的 Plot！")
                            end
                            task.wait(0.3)
                        end
                    end
                else
                    task.wait(0.8)
                end
            else
                warn("[Auto Egg] 找不到 workspace.RenderedEggs！")
                task.wait(1)
            end
        end
    end
end)
