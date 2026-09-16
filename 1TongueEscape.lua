local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer

-- ==================== 載入 ValueHat GUI ====================
local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
local Hub = UIModule.CreateWindow("+1 Tongue Escape", "TikTok: ValueHat")

local Config = {
	AutoTongue = false,
	AutoRebirth = false,
	AutoWins = false,
	AntiAFK = false,
	BypassPause = false
}

-- 載入遊戲資源與 Remotes
local Events = ReplicatedStorage:WaitForChild("Events", 10)
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)

-- 載入設定檔模組 (用於計算 Rebirth 需求)
local Shared = Modules and Modules:FindFirstChild("Shared") and require(Modules.Shared) or {}

-- Helper 函數：取得玩家數據 (Leaderstats / Attributes)
local function Stat(name)
	local leaderstats = Player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild(name) then
		return leaderstats[name].Value
	end
	return Player:GetAttribute(name) or 0
end

-- Helper 函數：取得角色部件
local function CharacterParts()
	local char = Player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if root and hum and hum.Health > 0 then
		return char, root, hum
	end
	return nil
end

-- Helper 函數：安全觸發 RemoteEvent
local function FireRemote(name, ...)
	if Events then
		local remote = Events:FindFirstChild(name)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(...)
		end
	end
end

-- ==================== 1. 自動伸舌頭 (Auto Tongue) ====================
task.spawn(function()
	while true do
		task.wait(0.05)
		if Config.AutoTongue then
			if CharacterParts() then
				FireRemote("AddTongue")
			end
		end
	end
end)

-- ==================== 2. 自動轉生 (Auto Rebirth) ====================
task.spawn(function()
	while true do
		task.wait(1)
		if Config.AutoRebirth then
			local reqLevel = Shared.levelForRebirth and Shared.levelForRebirth(Stat("Rebirths")) or 0
			if Stat("Level") >= reqLevel then
				local remoteFunc = Events and Events:FindFirstChild("RequestRebirth")
				if remoteFunc and remoteFunc:IsA("RemoteFunction") then
					pcall(function()
						remoteFunc:InvokeServer()
					end)
				end
			end
		end
	end
end)

-- ==================== 3. 自動刷勝場 (Auto Wins) ====================
local winMisses = 0

local function BestWinButton()
	local map = workspace:FindFirstChild("Map")
	local giveWins = map and map:FindFirstChild("GiveWins")
	local row = giveWins and giveWins:FindFirstChild("OneWin")
	if not row then return nil end

	local best, bestAmount = nil, -1
	for _, model in pairs(row:GetChildren()) do
		local amount = tonumber(model:GetAttribute("WinAmount")) or 0
		if model:IsA("Model") and amount > bestAmount then
			best, bestAmount = model, amount
		end
	end
	return best
end

task.spawn(function()
	while true do
		task.wait(0.2)
		if Config.AutoWins then
			local char, root, hum = CharacterParts()
			local model = BestWinButton()
			
			if char and root and hum and model then
				local pivot = model:GetPivot()
				local touch = model:FindFirstChild("Touch")

				if not touch then
					pcall(function()
						Player:RequestStreamAroundAsync(pivot.Position, 3)
					end)
					touch = model:FindFirstChild("Touch")
				end

				local beforeWins = Stat("Wins")
				local usedTouch = false

				-- 嘗試使用觸發 (TouchInterest)
				if touch and touch:IsA("BasePart") and type(firetouchinterest) == "function" and winMisses < 2 then
					usedTouch = pcall(function()
						firetouchinterest(root, touch, 0)
						task.wait(0.1)
						if root.Parent and touch.Parent then
							firetouchinterest(root, touch, 1)
						end
					end)
				end

				-- 觸發失敗時進行座標傳送
				if not usedTouch then
					local target = touch and touch.CFrame or pivot
					hum.Sit = false
					if (root.Position - target.Position).Magnitude < 12 then
						char:PivotTo(target + Vector3.new(0, 7, 14))
						task.wait(0.15)
					end
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					char:PivotTo(target + Vector3.new(0, 3, 0))
				end

				-- 等待勝場增加判定
				local deadline = os.clock() + 1.2
				repeat
					task.wait(0.1)
				until not Config.AutoWins or Stat("Wins") > beforeWins or os.clock() >= deadline

				if Stat("Wins") > beforeWins then
					winMisses = 0
				else
					winMisses = winMisses + 1
				end
			end
		end
	end
end)

-- ==================== 4. 防掛機 (Anti-AFK) 模組 ====================
local afkConnection = nil
local function SetAntiAFK(enabled)
	if afkConnection then
		afkConnection:Disconnect()
		afkConnection = nil
	end

	if enabled then
		afkConnection = Player.Idled:Connect(function()
			if Config.AntiAFK then
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end
		end)
	end
end

-- ==================== 5. 繞過加載暫停 (Bypass Pause) 模組 ====================
local pauseConnection = nil
local function SetBypassPause(enabled)
	if pauseConnection then
		pauseConnection:Disconnect()
		pauseConnection = nil
	end

	if enabled then
		pcall(function()
			if type(sethiddenproperty) == "function" then
				sethiddenproperty(workspace, "StreamingIntegrityMode", Enum.StreamingIntegrityMode.Disabled)
			end
			GuiService:SetGameplayPausedNotificationEnabled(false)
		end)

		pauseConnection = Player:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
			if Config.BypassPause and Player.GameplayPaused then
				pcall(function()
					if type(sethiddenproperty) == "function" then
						sethiddenproperty(Player, "GameplayPaused", false)
					end
				end)
			end
		end)
	end
end

-- ==================== GUI 控制開關設定 ====================
Hub:CreateToggle("Auto Train", false, function(isOn)
	Config.AutoTongue = isOn
end)

Hub:CreateToggle("Auto Rebirth", false, function(isOn)
	Config.AutoRebirth = isOn
end)

Hub:CreateToggle("Auto Wins", false, function(isOn)
	Config.AutoWins = isOn
end)

Hub:CreateToggle("Anti-AFK", false, function(isOn)
	Config.AntiAFK = isOn
	SetAntiAFK(isOn)
end)

Hub:CreateToggle("Bypass Pause", false, function(isOn)
	Config.BypassPause = isOn
	SetBypassPause(isOn)
end)
