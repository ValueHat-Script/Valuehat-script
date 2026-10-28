-- 動態載入 ValueHatGui UI 模組
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[Error] UI 模組載入失敗，請檢查網路或鏈接：", UIModule)
    return
end

-- 服務
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 變數
local currentIndex = 1
local collectCakeEnabled = false

-- 即時傳送
local function teleportTo(cframe)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cframe
    end
end

-- 取得物件 CFrame
local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local best, size = nil, 0
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") and d.Size.Magnitude > size then
                best, size = d, d.Size.Magnitude
            end
        end
        if best then return best.CFrame end
        return obj:GetPivot()
    end
    return nil
end

-- 取得所有 HollowKey 的列表
local function getHollowKeys()
    local keys = {}
    local gk = workspace:FindFirstChild("GameKeeper")
    local map = gk and gk:FindFirstChild("Map")
    local items = map and map:FindFirstChild("Items")
    
    if items then
        for _, obj in ipairs(items:GetChildren()) do
            if string.find(string.lower(obj.Name), "hollowkey") then
                table.insert(keys, obj)
            end
        end
    end
    return keys
end

-- 觸發收集互動 (ProximityPrompt 或 TouchInterest)
local function triggerCollect(obj)
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            pcall(function()
                desc.HoldDuration = 0
                if fireproximityprompt then
                    fireproximityprompt(desc)
                else
                    desc:InputHoldBegin()
                    desc:InputHoldEnd()
                end
            end)
        elseif desc:IsA("TouchTransmitter") and desc.Parent and desc.Parent:IsA("BasePart") then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    firetouchinterest(hrp, desc.Parent, 0)
                    firetouchinterest(hrp, desc.Parent, 1)
                end
            end)
        end
    end
end

-- 自動收集 Cake 迴圈邏輯
local function startCollectCake()
    task.spawn(function()
        while collectCakeEnabled do
            local holder = workspace:FindFirstChild("HollowCakesHolder")
            local slices = holder and holder:FindFirstChild("CakeSlices")
            
            local found = false
            if slices then
                for _, obj in ipairs(slices:GetChildren()) do
                    if not collectCakeEnabled then break end
                    
                    if obj:IsA("Model") then
                        local cf = getCFrame(obj)
                        if cf then
                            found = true
                            teleportTo(cf + Vector3.new(0, 3, 0))
                            task.wait(0.4)
                            triggerCollect(obj)
                            task.wait(0.5)
                        end
                    end
                end
            end
            
            if not found then
                task.wait(1)
            end
            task.wait(0.5)
        end
    end)
end

-- UI 介面設定
local Hub = UIModule.CreateWindow("[Hollow] Banana Eat", "TikTok: ValueHat")

Hub:CreateButton("Collect Hollow Key", function()
    local keys = getHollowKeys()
    if #keys == 0 then
        warn("[Collect] 找不到任何 HollowKey")
        return
    end
    
    if currentIndex > #keys then
        currentIndex = 1
    end
    
    local keyObj = keys[currentIndex]
    local cf = getCFrame(keyObj)
    
    if cf then
        teleportTo(cf + Vector3.new(0, 3, 0))
        task.wait(0.3)
        triggerCollect(keyObj)
    end
    
    currentIndex = currentIndex + 1
end)

Hub:CreateToggle("Collect Cake", false, function(on)
    collectCakeEnabled = on
    if on then
        startCollectCake()
    end
end)
