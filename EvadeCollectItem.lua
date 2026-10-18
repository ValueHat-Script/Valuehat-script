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

local autoCollectEnabled = false
local visited = {} -- 記錄每個 Part/Visual 已傳送幾次

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 瞬移
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
    end
end

-- 取得 Visual 的位置 (CFrame)
local function getObjectCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        return obj:GetPivot()
    end
    return nil
end

-- 取得所有名為 "Visual" 的物件
local function getVisualObjects()
    local visuals = {}
    
    -- 優先從 workspace.Effects 尋找
    local effects = Workspace:FindFirstChild("Effects")
    local searchContainer = effects or Workspace
    
    for _, obj in ipairs(searchContainer:GetDescendants()) do
        if obj.Name == "Visual" then
            table.insert(visuals, obj)
        end
    end
    
    return visuals
end

-- Auto Collect 主迴圈
local function startAutoCollect()
    task.spawn(function()
        while autoCollectEnabled do
            local visuals = getVisualObjects()
            
            if #visuals > 0 then
                local teleportedAny = false
                
                for _, visualObj in ipairs(visuals) do
                    if not autoCollectEnabled then break end
                    
                    local cf = getObjectCFrame(visualObj)
                    if cf then
                        local key = tostring(cf.Position)
                        local count = visited[key] or 0
                        
                        -- 每個 Visual 傳送最多 3 次
                        if count < 3 then
                            visited[key] = count + 1
                            teleportedAny = true
                            
                            teleportTo(cf + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                        end
                    end
                end
                
                if not autoCollectEnabled then break end
                
                -- 全部都傳滿 3 次後，清空記錄重新開始
                if not teleportedAny then
                    visited = {}
                    task.wait(1.5)
                else
                    task.wait(0.6)
                end
            else
                warn("[Collect Item] 找不到 Visual 物件")
                task.wait(2)
            end
        end
    end)
end

-- ==================== UI ====================
local Hub = UIModule.CreateWindow("Evade", "TikTok: ValueHat")

Hub:CreateToggle("Collect Item", false, function(on)
    autoCollectEnabled = on
    if on then
        visited = {}
        startAutoCollect()
        print("[Collect Item] 已開啟 (目標: Visual)")
    else
        print("[Collect Item] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
