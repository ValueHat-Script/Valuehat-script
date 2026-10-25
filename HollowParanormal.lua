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

local collectItemEnabled = false

-- 指定要收集的目標模型名稱清單 (支援帶空格或不帶空格)
local targetItemNames = {
    ["CandyBucket"] = true,
    ["Candy Bucket"] = true,
    ["PumpkinPie"] = true,
    ["Pumpkin Pie"] = true,
    ["VampireCoffin"] = true,
    ["Vampire Coffin"] = true,
    ["BuddyPlushie"] = true,
    ["Buddy Plushie"] = true,
    ["WitchClock"] = true,
    ["Witch Clock"] = true
}

-- 傳送函數
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

-- 取得物件的 CFrame 位置
local function getObjectCFrame(object)
    if object:IsA("Model") then
        if object.PrimaryPart then return object.PrimaryPart.CFrame end
        local mainPart = object:FindFirstChild("main") or object:FindFirstChild("Main")
        if mainPart and mainPart:IsA("BasePart") then return mainPart.CFrame end
        local root = object:FindFirstChildWhichIsA("BasePart")
        if root then return root.CFrame end
        return object:GetPivot()
    elseif object:IsA("BasePart") then
        return object.CFrame
    end
    return nil
end

-- 觸發指定物件內部的 Prompt
local function triggerPromptsInObject(object)
    local mainPart = object:FindFirstChild("main") or object:FindFirstChild("Main")
    local searchTarget = mainPart or object
    
    for _, descendant in ipairs(searchTarget:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            pcall(function()
                descendant.HoldDuration = 0
                descendant.MaxActivationDistance = 32
                fireproximityprompt(descendant)
            end)
        elseif descendant:IsA("Attachment") then
            for _, child in ipairs(descendant:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    pcall(function()
                        child.HoldDuration = 0
                        child.MaxActivationDistance = 32
                        fireproximityprompt(child)
                    end)
                end
            end
        end
    end
end

-- ==================== Collect Item 主迴圈 ====================
local function startCollectItem()
    task.spawn(function()
        while collectItemEnabled do
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                -- 深度遍歷 Workspace 中的所有物件與子模型
                for _, descendant in ipairs(Workspace:GetDescendants()) do
                    if not collectItemEnabled then break end

                    -- 檢查模型名稱是否符合目標
                    if targetItemNames[descendant.Name] then
                        local itemCFrame = getObjectCFrame(descendant)
                        if itemCFrame then
                            -- 1. 先傳送到物品上方或旁邊
                            teleportTo(itemCFrame + Vector3.new(0, 3, 0))
                            task.wait(0.2) -- 稍微等待傳送穩定

                            -- 2. 再觸發 Prompt
                            triggerPromptsInObject(descendant)
                            task.wait(0.3) -- 收集後的緩衝時間
                        end
                    end
                end
            end
            
            task.wait(0.5) -- 掃描間隔
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Paranormal", "TikTok: ValueHat")

-- 新增 Collect Item 開關
HubWindow:CreateToggle("Collect Item", false, function(on)
    collectItemEnabled = on
    if on then
        print("[Collect Item] 已開啟")
        startCollectItem()
    else
        print("[Collect Item] 已關閉")
    end
end)

print("[ValueHat] Collect Item script loaded successfully!")
