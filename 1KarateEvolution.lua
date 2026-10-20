-- 安全載入 UI
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[ValueHat] UI 載入失敗")
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local autoSpiritEnabled = false
local autoGradeEnabled = false
local autoRebirthEnabled = false

-- Auto Spirit 主迴圈
local function startAutoSpirit()
    task.spawn(function()
        while autoSpiritEnabled do
            local success, err = pcall(function()
                local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StrikeBatch")
                event:FireServer(10)
            end)

            if success then
                print("[Auto Spirit] 已觸發 StrikeBatch")
            else
                warn("[Auto Spirit] 失敗:", err)
            end

            task.wait(0.5)
        end
    end)
end

-- Auto Grade 主迴圈
local function startAutoGrade()
    task.spawn(function()
        while autoGradeEnabled do
            local success, err = pcall(function()
                local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Grade")
                event:InvokeServer()
            end)

            if success then
                print("[Auto Grade] 已觸發 Grade")
            else
                warn("[Auto Grade] 失敗:", err)
            end

            task.wait(1)
        end
    end)
end

-- Auto Rebirth 主迴圈
local function startAutoRebirth()
    task.spawn(function()
        while autoRebirthEnabled do
            local success, err = pcall(function()
                local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Rebirth")
                event:InvokeServer()
            end)

            if success then
                print("[Auto Rebirth] 已觸發 Rebirth")
            else
                warn("[Auto Rebirth] 失敗:", err)
            end

            task.wait(1)
        end
    end)
end

-- ==================== UI ====================
local Hub = UIModule.CreateWindow("+1 Karate Evolution", "TikTok: ValueHat")

Hub:CreateToggle("Auto Spirit", false, function(on)
    autoSpiritEnabled = on
    if on then
        startAutoSpirit()
        print("[Auto Spirit] 已開啟")
    else
        print("[Auto Spirit] 已關閉")
    end
end)

Hub:CreateToggle("Auto Grade", false, function(on)
    autoGradeEnabled = on
    if on then
        startAutoGrade()
        print("[Auto Grade] 已開啟")
    else
        print("[Auto Grade] 已關閉")
    end
end)

Hub:CreateToggle("Auto Rebirth", false, function(on)
    autoRebirthEnabled = on
    if on then
        startAutoRebirth()
        print("[Auto Rebirth] 已開啟")
    else
        print("[Auto Rebirth] 已關閉")
    end
end)

print("[ValueHat] Script loaded successfully!")
