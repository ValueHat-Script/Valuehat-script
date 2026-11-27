-- ==================== ValueHat Gui 5 初始化 ====================
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("Hyper Realistic Ragdoll")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hrrNet = ReplicatedStorage:WaitForChild("HRR_Net")
local requestRemote = hrrNet:WaitForChild("Request")

-- ==================== Give KOs 邏輯 ====================
local function giveKOs()
    task.spawn(function()
        local ok, res = pcall(function()
            return requestRemote:InvokeServer("ReportKOs", 1000)
        end)

        if ok then
            print("[Give KOs] 已發送 ReportKOs (10000)！回傳:", res)
        else
            warn("[Give KOs] 發送失敗:", res)
        end
    end)
end

-- ==================== UI 設定 ====================
UI:Button("GiveKOsBtn", "Give KOs", giveKOs)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Give KOs script loaded!")
