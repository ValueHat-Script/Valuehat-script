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

-- ==================== 傳送通用函數 ====================
local function teleportTo(cf)
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and cf then
            root.CFrame = cf
        end
    end
end

-- ==================== 取得 Collectable 物件的 CFrame ====================
local function getItemObject(index)
    local success, result = pcall(function()
        local neighborhood = Workspace:FindFirstChild("Happy Neighborhood")
        if not neighborhood then return nil end
        local collectables = neighborhood:FindFirstChild("Collectables")
        if not collectables then return nil end
        
        local children = collectables:GetChildren()
        return children[index]
    end)
    
    if success then
        return result
    end
    return nil
end

local function getTargetCFrame(targetObj)
    if not targetObj then return nil end
    if targetObj:IsA("BasePart") then
        return targetObj.CFrame
    elseif targetObj:IsA("Model") then
        local part = targetObj.PrimaryPart or targetObj:FindFirstChildWhichIsA("BasePart", true)
        return part and part.CFrame or targetObj:GetPivot()
    end
    return nil
end

-- ==================== 執行單次收集傳送 ====================
local function executeCollect(index)
    pcall(function()
        local itemObj = getItemObject(index)
        if itemObj then
            local cf = getTargetCFrame(itemObj)
            if cf then
                teleportTo(cf + Vector3.new(0, 3, 0))
                print(string.format("[Collect Item %d] 已傳送到: %s", index, itemObj.Name))
            else
                warn(string.format("[Collect Item %d] 找不到該物件的座標", index))
            end
        else
            warn(string.format("[Collect Item %d] 找不到對應的收集品物件", index))
        end
    end)
end

-- ==================== UI 介面設定 ====================
local HubWindow = UIModule.CreateWindow("[Hollow] Survive the killer", "TikTok: ValueHat")

-- Collect Item 1 按鈕
HubWindow:CreateButton("Collect Item 1", function()
    executeCollect(1)
end)

-- Collect Item 2 按鈕
HubWindow:CreateButton("Collect Item 2", function()
    executeCollect(2)
end)

-- Collect Item 3 按鈕
HubWindow:CreateButton("Collect Item 3", function()
    executeCollect(3)
end)

print("[ValueHat] Collect Items 1~3 Buttons script loaded successfully!")
