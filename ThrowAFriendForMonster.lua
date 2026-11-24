-- ValueHat Gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Throw a Friend for Monster")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local autoThrow = false
local autoEquipBest = false
local autoX2Train = false

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local remotesFolder = sharedFolder:WaitForChild("Remotes")
local throwRemote = remotesFolder:WaitForChild("Throw")
local monsterRemote = remotesFolder:WaitForChild("Monster")
local standRemote = remotesFolder:WaitForChild("Stand")

-- ==================== Auto Throw 循環 ====================
task.spawn(function()
    while true do
        if autoThrow and throwRemote then
            pcall(function()
                throwRemote:FireServer("Tap", math.huge)
            end)
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== Equip Best 循環 ====================
task.spawn(function()
    while true do
        if autoEquipBest and monsterRemote then
            pcall(function()
                monsterRemote:FireServer("EquipBest")
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== x2 Train 循環 ====================
task.spawn(function()
    while true do
        if autoX2Train and standRemote then
            pcall(function()
                standRemote:FireServer("Boost")
            end)
            task.wait()
        else
            task.wait(0.2)
        end
    end
end)

-- ==================== UI ====================
UI:Toggle("AutoThrowToggle", "Auto Throw", function(enabled)
    autoThrow = enabled
    if enabled then
        print("[Auto Throw] 已開啟")
    else
        print("[Auto Throw] 已關閉")
    end
end)

UI:Toggle("EquipBestToggle", "Equip Best", function(enabled)
    autoEquipBest = enabled
    if enabled then
        print("[Equip Best] 已開啟循環")
    else
        print("[Equip Best] 已關閉循環")
    end
end)

UI:Toggle("X2TrainToggle", "x2 Train", function(enabled)
    autoX2Train = enabled
    if enabled then
        print("[x2 Train] 已開啟循環")
    else
        print("[x2 Train] 已關閉循環")
    end
end)

UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Auto Throw loaded!")
