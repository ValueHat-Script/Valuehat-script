local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")


local WorldData = {
    ["World 1"] = {
        Teleport = CFrame.new(682, 37, -2),
        Path = "Zones.Zone_13.SpawnZone"
    },
    ["World 2"] = {
        Teleport = CFrame.new(942, 37, 1704),
        Path = "Zones.Zone_24.SpawnZone"
    },
    ["World 3"] = {
        Teleport = CFrame.new(942, 37, 3468),
        Path = "Zones.Zone_35.SpawnZone"
    },
    ["World 4"] = {
        Teleport = CFrame.new(954, 37, 5216),
        Path = "Zones.Zone_46.SpawnZone"
    }
}

local AutoTrainSettings = { Enabled = false }
local AutoCollectSettings = { Enabled = false, SelectedWorld = "World 1" }
local AutoSellSettings = { Enabled = false }
local AutoRebirthSettings = { Enabled = false }
local NoclipSettings = { Enabled = false }
local IsBackpackFull = false

local NotificationEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")["acecateer_knit@1.7.2"].knit.Services.NotificationService.RE.NotificationRequested
local TeleportToSpawnEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")["acecateer_knit@1.7.2"].knit.Services.BaseTeleportService.RF.TeleportToSpawn

-- 建立視窗
local Window = OrionLib:MakeWindow({
	Name = "+1 Cut Grass Adventrue",
	HidePremium = false,
	SaveConfig = false,
	ConfigFolder = "BigHubConfig",
	IntroEnabled = true,
	IntroText = "Follow For More - by TikTok ValueHat"
})

local Tab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})


local function safeTeleport(targetCFrame)
    local character = Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(targetCFrame)
    end
end

local function isPurchasePromptOpen()
    local isPromptActive = false
    pcall(function() isPromptActive = MarketplaceService:GetSunsettingPromptActive() end)
    local gui = CoreGui:FindFirstChild("PurchasePrompt")
    if gui then
        local frame = gui:FindFirstChild("ProductPurchaseContainer", true) or gui:FindFirstChild("Animator", true)
        if frame and frame.Visible then return true end
    end
    return isPromptActive
end

local function getObjectFromPath(path)
    local parts = string.split(path, ".")
    local current = Workspace
    for _, name in pairs(parts) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

RunService.Stepped:Connect(function()
    if NoclipSettings.Enabled then
        local character = Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)


task.spawn(function()
    pcall(function()
        NotificationEvent.OnClientEvent:Connect(function(message)
            if typeof(message) == "string" and message:find("You can't carry more items") then
                if not IsBackpackFull then
                    IsBackpackFull = true
                    pcall(function() TeleportToSpawnEvent:InvokeServer() end)
                end
            end
        end)
    end)
end)

task.spawn(function()
    local ClickEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")["acecateer_knit@1.7.2"].knit.Services.StrengthService.RE.ClickRequested
    while true do
        if AutoTrainSettings.Enabled then
            pcall(function() ClickEvent:FireServer() end)
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    local RebirthEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")["acecateer_knit@1.7.2"].knit.Services.RebirtService.RE.RebirthButtonClicked
    while true do
        if AutoRebirthSettings.Enabled then
            pcall(function() RebirthEvent:FireServer() end)
        end
        task.wait(3)
    end
end)


task.spawn(function()
    local SellEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")["acecateer_knit@1.7.2"].knit.Services.DataService.RF.SellAllBackpackLoot
    while true do
        if AutoSellSettings.Enabled then
            pcall(function()
                SellEvent:InvokeServer()
                IsBackpackFull = false
            end)
        end
        task.wait(1)
    end
end)


task.spawn(function()
    while true do
        if AutoCollectSettings.Enabled then
            if IsBackpackFull or isPurchasePromptOpen() then
                task.wait(1)
            else
                local character = Players.LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local cfg = WorldData[AutoCollectSettings.SelectedWorld]
                    safeTeleport(cfg.Teleport)
                    task.wait(0.8)

                    local spawnZone = getObjectFromPath(cfg.Path)
                    if spawnZone then
                        for _, meshObj in pairs(spawnZone:GetChildren()) do
                            if not AutoCollectSettings.Enabled or IsBackpackFull or isPurchasePromptOpen() then break end
                            local attachment = meshObj:FindFirstChild("PickupPromptAttachment", true)
                            if attachment then
                                local prompt = attachment:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    safeTeleport(attachment.WorldCFrame * CFrame.new(0, 2, 0))
                                    task.wait(0.3)
                                    if not isPurchasePromptOpen() then
                                        fireproximityprompt(prompt)
                                    end
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

Tab:AddToggle({ Name = "Noclip", Default = false, Callback = function(Value) NoclipSettings.Enabled = Value end })
Tab:AddToggle({ Name = "Auto Train", Default = false, Callback = function(Value) AutoTrainSettings.Enabled = Value end })
Tab:AddToggle({ Name = "Auto Rebirth", Default = false, Callback = function(Value) AutoRebirthSettings.Enabled = Value end })

Tab:AddDropdown({
	Name = "Select World",
	Default = "World 1",
	Options = {"World 1", "World 2", "World 3", "World 4"},
	Callback = function(Value) AutoCollectSettings.SelectedWorld = Value end    
})

Tab:AddToggle({ Name = "Auto Collect", Default = false, Callback = function(Value) AutoCollectSettings.Enabled = Value end })
Tab:AddToggle({ Name = "Auto Sell", Default = false, Callback = function(Value) AutoSellSettings.Enabled = Value end })

OrionLib:Init()
