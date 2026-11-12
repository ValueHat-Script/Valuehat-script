-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Impossible Hill Climb")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local autoWinEnabled = false

-- 取得玩家 HumanoidRootPart
local function getHRP()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- 傳送到指定 CFrame
local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

-- 取得物件 CFrame (支援 BasePart 與 Model)
local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.CFrame
        end
        return obj:GetPivot()
    end
    return nil
end

-- 取得 GoalPad 的 CFrame 座標
local function getGoalPadCFrame()
    local success, result = pcall(function()
        local map = Workspace:WaitForChild("Map", 2)
        local hillClimb = map and map:WaitForChild("HillClimb", 2)
        local summit = hillClimb and hillClimb:WaitForChild("Summit", 2)
        local finalWinPad = summit and summit:WaitForChild("FinalWinPad", 2)
        local goalPad = finalWinPad and finalWinPad:WaitForChild("GoalPad", 2)
        
        return getCFrame(goalPad)
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Auto Win 循環邏輯
local function startAutoWin()
    task.spawn(function()
        while autoWinEnabled do
            pcall(function()
                local goalCf = getGoalPadCFrame()
                if goalCf then
                    -- 傳送到 GoalPad 上方 3 單位
                    teleportTo(goalCf + Vector3.new(0, 3, 0))
                else
                    warn("[Auto Win] 找不到 workspace.Map.HillClimb.Summit.FinalWinPad.GoalPad")
                end
            end)
            task.wait(0.5)
        end
    end)
end

-- ==================== UI 介面設定 ====================
UI:Toggle("AutoWinToggle", "Auto Win", function(enabled)
    autoWinEnabled = enabled
    if enabled then
        startAutoWin()
        print("[Auto Win] 已開啟")
    else
        print("[Auto Win] 已關閉")
    end
end)

UI:Status("Status", "TikTok: ValueHat")

print("[ValueHat] Auto Win Script loaded successfully!")
