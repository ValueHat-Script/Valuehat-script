local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
local Hub = UIModule.CreateWindow("Steal and Hatch Anime Egg", "TikTok: ValueHat")

local Config = {
	AutoEgg = false,
	AutoPlace = false,
	AutoEquipBest = false,
	AutoRebirth = false,
	SelectedRarity = "Common",
	Delay = 0.4,
	ScanRadius = 5, -- 搜尋角色周圍 ProximityPrompt 的半徑範圍 (Studs)
	ReturnPosition = Vector3.new(546, 71, -299) -- 指定傳回座標
}

local function GetRoot()
	local char = Player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- 觸發 ProximityPrompt
local function FirePrompt(prompt)
	if typeof(fireproximityprompt) == "function" then
		fireproximityprompt(prompt)
	else
		prompt:InputHoldBegin()
		task.wait(prompt.HoldDuration)
		prompt:InputHoldEnd()
	end
end

-- 搜尋並觸發角色周圍半徑內的 ProximityPrompt
local function FireNearbyPrompts(rootPart)
	if not rootPart then return end
	
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled then
			local parentPart = descendant.Parent
			local promptPos = nil

			if parentPart:IsA("BasePart") then
				promptPos = parentPart.Position
			elseif parentPart:IsA("Attachment") then
				promptPos = parentPart.WorldPosition
			elseif parentPart:IsA("Model") and parentPart.PrimaryPart then
				promptPos = parentPart.PrimaryPart.Position
			end

			if promptPos then
				local distance = (rootPart.Position - promptPos).Magnitude
				if distance <= Config.ScanRadius then
					FirePrompt(descendant)
				end
			end
		end
	end
end

-- 取得 Model 的可傳送 CFrame
local function GetTargetCFrame(model)
	local attachment = model:FindFirstChildWhichIsA("Attachment", true)
	if attachment then
		return attachment.WorldCFrame
	end

	if model:IsA("Model") then
		if model.PrimaryPart then
			return model.PrimaryPart.CFrame
		else
			local part = model:FindFirstChildWhichIsA("BasePart", true)
			if part then return part.CFrame end
		end
	elseif model:IsA("BasePart") then
		return model.CFrame
	end
	return nil
end

local function AutoEgg()
	while Config.AutoEgg do
		local root = GetRoot()
		local liveEggsFolder = Workspace:FindFirstChild("LiveAreaEggs")

		if root and liveEggsFolder then
			-- 掃描 LiveAreaEggs 下的所有 Model
			for _, model in ipairs(liveEggsFolder:GetDescendants()) do
				if not Config.AutoEgg then break end

				if model:IsA("Model") then
					-- 讀取 Model 的 Attribute "Rarity"
					local rarityAttr = model:GetAttribute("Rarity")

					if not rarityAttr then
						local rValue = model:FindFirstChild("Rarity", true)
						if rValue and rValue:IsA("ValueBase") then
							rarityAttr = rValue.Value
						end
					end

					-- 比對稀有度
					if rarityAttr and string.lower(tostring(rarityAttr)) == string.lower(Config.SelectedRarity) then
						local targetCF = GetTargetCFrame(model)

						if targetCF then
							-- 1. 傳送到蛋的位置
							root.CFrame = targetCF * CFrame.new(0, 2, 0)
							task.wait(Config.Delay)

							-- 2. 觸發角色周圍半徑內的 ProximityPrompt
							FireNearbyPrompts(root)
							task.wait(Config.Delay)

							-- 3. 傳回指定的 (546, 71, -299) 座標
							root.CFrame = CFrame.new(Config.ReturnPosition)
							
							-- 4. 等待 1.5 秒再繼續下一輪
							task.wait(1.5)
						end
					end
				end
			end
		end
		task.wait(1)
	end
end

-- 自動放置蛋 (Auto Place)
local function AutoPlace()
	while Config.AutoPlace do
		local root = GetRoot()
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		
		if root and gameRemotes then
			local placeEvent = gameRemotes:FindFirstChild("PlaceEgg")
			if placeEvent and placeEvent:IsA("RemoteEvent") then
				placeEvent:FireServer(root.Position)
			end
		end
		task.wait(0.5)
	end
end

-- 自動裝備最佳寵物 (Auto Equip Best)
local function AutoEquipBest()
	while Config.AutoEquipBest do
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes then
			local equipEvent = gameRemotes:FindFirstChild("EquipBestPets")
			if equipEvent and equipEvent:IsA("RemoteFunction") then
				equipEvent:InvokeServer()
			end
		end
		task.wait(1)
	end
end

-- 自動轉生 (Auto Rebirth)
local function AutoRebirth()
	while Config.AutoRebirth do
		local rebirthRemotes = ReplicatedStorage:FindFirstChild("RebirthRemotes")
		if rebirthRemotes then
			local requestEvent = rebirthRemotes:FindFirstChild("Request")
			if requestEvent and requestEvent:IsA("RemoteEvent") then
				requestEvent:FireServer("Rebirth")
			end
		end
		task.wait(1)
	end
end

-- UI 下拉選單與開關
Hub:CreateDropdown("Select Rarity", {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Cosmic",
	"Secret",
	"Eternal",
	"Divine"
}, "Common", function(selected)
	Config.SelectedRarity = selected
end)

Hub:CreateToggle("Auto Egg", false, function(isOn)
	Config.AutoEgg = isOn
	if isOn then
		task.spawn(AutoEgg)
	end
end)

Hub:CreateToggle("Auto Place", false, function(isOn)
	Config.AutoPlace = isOn
	if isOn then
		task.spawn(AutoPlace)
	end
end)

Hub:CreateToggle("Auto Equip Best", false, function(isOn)
	Config.AutoEquipBest = isOn
	if isOn then
		task.spawn(AutoEquipBest)
	end
end)

Hub:CreateToggle("Auto Rebirth", false, function(isOn)
	Config.AutoRebirth = isOn
	if isOn then
		task.spawn(AutoRebirth)
	end
end)
