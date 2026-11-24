local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua"))().Init("Pixel Arena")

local Plrs = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local CG = game:GetService("CoreGui")
local SG = game:GetService("StarterGui")
local LP = Plrs.LocalPlayer
local cam = workspace.CurrentCamera

local getu = debug.getupvalues or getupvalues
local setu = debug.setupvalue or setupvalue

if not getu or not setu then
	pcall(SG.SetCore, SG, "SendNotification", {Title = "ValueHat", Text = "getupvalues unsupported", Duration = 4})
	return
end

-- ==================== 總開關與設定 (預設關閉，由 UI 控制) ====================
local S = {
	Enabled = false,
	Auto = false,
	Delay = 0.05,
	Part = "Head",
	Chance = 100,
	Range = 1500,
	Players = true,
	Bots = true,
	Dummies = true,
	Box = true,
	Tracer = true,
	Health = true,
	Dist = true,
	TracerColor = Color3.fromRGB(255, 40, 40),
	BoxColor = Color3.fromRGB(255, 48, 58),
}
getgenv().CleusSA = S

-- ==================== 模組與網路事件初始化 ====================
local t0 = os.clock()
while LP:GetAttribute("Shooter_Client_Loaded") ~= true and os.clock() - t0 < 40 do
	task.wait(0.1)
end

local Mods = RS:WaitForChild("Modules", 30)
if not Mods then return end

local function req(par, name, timeout)
	local inst = par:WaitForChild(name, timeout or 30)
	if not inst then return nil end
	local s = os.clock()
	while os.clock() - s < (timeout or 30) do
		local ok, res = pcall(require, inst)
		if ok then return res end
		task.wait(0.2)
	end
	return nil
end

local AutoShoot = req(Mods, "AutoShootModule")
local Crosshair = req(Mods, "CrosshairView", 15)
if not AutoShoot then return end

local Sync = RS:FindFirstChild("SystemResources")
	and RS.SystemResources:FindFirstChild("BufferCache")
	and RS.SystemResources.BufferCache:FindFirstChild("RequestActionSync")
if not Sync then
	Sync = RS:WaitForChild("SystemResources", 20)
		and RS.SystemResources:WaitForChild("BufferCache", 20)
		and RS.SystemResources.BufferCache:WaitForChild("RequestActionSync", 20)
end
if not Sync then return end

local FBullet = RS:FindFirstChild("Events")
	and RS.Events:FindFirstChild("RemoteEvents")
	and RS.Events.RemoteEvents:FindFirstChild("ReplicateFakeBullet")

local Shoot
for _, uv in pairs(getu(AutoShoot.OnShoot)) do
	if typeof(uv) == "function" then
		for _, i in pairs(getu(uv)) do
			if i == Sync then
				Shoot = uv
				break
			end
		end
	end
	if Shoot then break end
end
if not Shoot then
	pcall(SG.SetCore, SG, "SendNotification", {Title = "ValueHat", Text = "shoot func not found", Duration = 4})
	return
end

-- ==================== 目標搜尋與渲染輔助 ====================
local drawn = false
pcall(function()
	local l = Drawing.new("Line")
	l:Remove()
	drawn = true
end)

local hit = {position = Vector3.zero, instance = nil, model = nil, humanoid = nil, headshot = false}
local hits = {hit}

local origin = Vector3.zero
local bM, bP, bH, bPos, bScore
local lastPos
local bots, dummies

local function partOf(model)
	if S.Part == "Head" then
		return model:FindFirstChild("Head") or model:FindFirstChild("HeadHitbox")
			or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
	end
	return model:FindFirstChild(S.Part) or model:FindFirstChild("HumanoidRootPart")
end

local function scan(model)
	if not model or model == LP.Character or not model:IsDescendantOf(workspace) then return end
	if model:GetAttribute("CurrentHighlight") == "SpawnProtection" then return end
	local h = model:FindFirstChildOfClass("Humanoid")
	if h and h.Health <= 0 then return end
	local p = partOf(model)
	if not p or not p:IsA("BasePart") then return end
	local pos = p.Position
	local dx, dy, dz = pos.X - origin.X, pos.Y - origin.Y, pos.Z - origin.Z
	local d = dx * dx + dy * dy + dz * dz
	if d > S.Range * S.Range then return end
	if not bScore or d < bScore then
		bScore = d
		bM = model
		bP = p
		bH = h
		bPos = pos
	end
end

local function find(o)
	cam = workspace.CurrentCamera
	if not cam then return false end
	origin = o
	bM, bP, bH, bPos, bScore = nil, nil, nil, nil, nil
	local ranged = LP:GetAttribute("InShootingRange") == true

	if S.Players then
		for _, p in ipairs(Plrs:GetPlayers()) do
			if p ~= LP and p:GetAttribute("Deployed") ~= false then
				if ranged or p:GetAttribute("InShootingRange") == true then
					scan(p.Character)
				end
			end
		end
	end
	if S.Bots then
		if not bots or not bots.Parent then bots = workspace:FindFirstChild("BotCharacters") end
		if bots then
			for _, m in ipairs(bots:GetChildren()) do
				if m:IsA("Model") then scan(m) end
			end
		end
	end
	if S.Dummies then
		if not dummies or not dummies.Parent then
			local sr = workspace:FindFirstChild("Shooting Range")
			dummies = sr and sr:FindFirstChild("Dummies") or nil
		end
		if dummies then
			for _, m in ipairs(dummies:GetChildren()) do
				if m:IsA("Model") then scan(m) end
			end
		end
	end
	return bM ~= nil
end

local function line(t, c)
	local l = Drawing.new("Line")
	l.Thickness = t
	l.Color = c
	l.Transparency = 1
	l.Visible = false
	return l
end

local tracers = {}

local function tracer(pos)
	if not drawn or not S.Tracer or not S.Enabled then return end
	local ok, l = pcall(line, 1.4, S.TracerColor)
	if not ok then return end
	table.insert(tracers, {l = l, p = pos, t = os.clock()})
end

local hlPool, hlHeld = {}, {}
local hlRoot = Instance.new("Folder")
hlRoot.Name = "esp_hl"
hlRoot.Parent = (gethui and gethui()) or CG

local function highlight(model, on)
	local h = hlHeld[model]
	if on and S.Enabled then
		if not h then
			h = table.remove(hlPool) or Instance.new("Highlight")
			h.FillColor = Color3.fromRGB(255, 40, 50)
			h.FillTransparency = 0.78
			h.OutlineColor = Color3.fromRGB(255, 70, 80)
			h.OutlineTransparency = 0.05
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.Parent = hlRoot
			hlHeld[model] = h
		end
		h.Adornee = model
		h.Enabled = true
	elseif h then
		h.Enabled = false
		h.Adornee = nil
		hlHeld[model] = nil
		table.insert(hlPool, h)
	end
end

-- ==================== 代理與自動射擊迴圈 ====================
local ProxySync = {}
function ProxySync:FireServer(payload, ...)
	if S.Enabled and typeof(payload) == "table" and payload.origin and payload.direction and payload.hits then
		if S.Chance >= 100 or math.random(1, 100) <= S.Chance then
			if find(payload.origin) then
				payload.direction = (bPos - payload.origin).Unit
				payload.hitPosition = nil
				payload.hitInstance = nil
				hit.position = bPos
				hit.instance = bP
				hit.model = bM
				hit.humanoid = bH
				hit.headshot = bP.Name == "Head" or bP.Name == "HeadHitbox"
				payload.hits = hits
				lastPos = bPos
				tracer(bPos)
				if Crosshair and Crosshair.hitmarker then
					pcall(Crosshair.hitmarker, hit.headshot)
				end
			else
				lastPos = nil
			end
		end
	end
	return Sync:FireServer(payload, ...)
end

local ProxyBullet = {}
function ProxyBullet:FireServer(cf, vec, dist, ...)
	if S.Enabled and lastPos and typeof(cf) == "CFrame" then
		local d = lastPos - cf.Position
		local m = d.Magnitude
		if m > 0.5 then
			vec = d / m
			dist = m
		end
	end
	if FBullet then
		return FBullet:FireServer(cf, vec, dist, ...)
	end
	return nil
end

local orig = {}
local ok = false
for i, uv in pairs(getu(Shoot)) do
	if uv == Sync then
		orig[i] = uv
		setu(Shoot, i, ProxySync)
		ok = true
	elseif uv == FBullet then
		orig[i] = uv
		setu(Shoot, i, ProxyBullet)
	end
end
if not ok then return end

task.spawn(function()
	while true do
		task.wait(S.Delay)
		if S.Enabled and S.Auto and Shoot then
			if not pcall(Shoot, AutoShoot) then pcall(Shoot) end
		end
	end
end)

-- ==================== ESP 繪製管理 ====================
local entries = {}

local function entry(model)
	local e = entries[model]
	if e then return e end
	e = {b = {}}
	for i = 1, 8 do e.b[i] = line(1, S.BoxColor) end
	e.hb = line(3, Color3.fromRGB(10, 10, 10))
	e.hf = line(3, Color3.fromRGB(70, 255, 130))
	if drawn then
		e.d = Drawing.new("Text")
		e.d.Size = 12
		e.d.Color = Color3.fromRGB(255, 225, 225)
		e.d.Center = true
		e.d.Outline = true
		e.d.OutlineColor = Color3.fromRGB(0, 0, 0)
		e.d.Visible = false
	end
	entries[model] = e
	return e
end

local function hide(e)
	for _, l in ipairs(e.b) do l.Visible = false end
	e.hb.Visible = false
	e.hf.Visible = false
	if e.d then e.d.Visible = false end
end

local function drop(model)
	local e = entries[model]
	if not e then return end
	entries[model] = nil
	highlight(model, false)
	for _, l in ipairs(e.b) do pcall(function() l:Remove() end) end
	pcall(function() e.hb:Remove() end)
	pcall(function() e.hf:Remove() end)
	if e.d then pcall(function() e.d:Remove() end) end
end

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function render(model)
	local h = model:FindFirstChildOfClass("Humanoid")
	if h and h.Health <= 0 then
		local e = entries[model]
		if e then hide(e) end
		highlight(model, false)
		return
	end

	local okb, cf, sz = pcall(model.GetBoundingBox, model)
	if not okb or not cf or not sz then return end
	if (cf.Position - cam.CFrame.Position).Magnitude > 2000 then
		local e = entries[model]
		if e then hide(e) end
		highlight(model, false)
		return
	end

	local vp = cam.ViewportSize
	local x0, y0, x1, y1
	local vis = true

	for xi = -0.5, 0.5, 1 do
		for yi = -0.5, 0.5, 1 do
			for zi = -0.5, 0.5, 1 do
				local w = cf:PointToWorldSpace(Vector3.new(sz.X * xi, sz.Y * yi, sz.Z * zi))
				local sp, on = cam:WorldToViewportPoint(w)
				if on then
					x0 = math.min(x0 or sp.X, sp.X)
					x1 = math.max(x1 or sp.X, sp.X)
					y0 = math.min(y0 or sp.Y, sp.Y)
					y1 = math.max(y1 or sp.Y, sp.Y)
				elseif sp.Z > 0 then
					x0 = math.min(x0 or sp.X, clamp(sp.X, 0, vp.X))
					x1 = math.max(x1 or sp.X, clamp(sp.X, 0, vp.X))
					y0 = math.min(y0 or sp.Y, clamp(sp.Y, 0, vp.Y))
					y1 = math.max(y1 or sp.Y, clamp(sp.Y, 0, vp.Y))
				else
					vis = false
				end
			end
		end
	end

	if not vis or not x0 then
		local e = entries[model]
		if e then hide(e) end
		highlight(model, false)
		return
	end

	x0 = clamp(x0 - 2, 0, vp.X)
	x1 = clamp(x1 + 2, 0, vp.X)
	y0 = clamp(y0 - 2, 0, vp.Y)
	y1 = clamp(y1 + 2, 0, vp.Y)

	local w = x1 - x0
	local hh = y1 - y0
	if w < 2 or hh < 3 then return end

	local e = entry(model)
	local seg = math.min(w, hh) * 0.22

	local pts = {
		{Vector2.new(x0, y0), Vector2.new(x0 + seg, y0)},
		{Vector2.new(x0, y0), Vector2.new(x0, y0 + seg)},
		{Vector2.new(x1, y0), Vector2.new(x1 - seg, y0)},
		{Vector2.new(x1, y0), Vector2.new(x1, y0 + seg)},
		{Vector2.new(x1, y1), Vector2.new(x1 - seg, y1)},
		{Vector2.new(x1, y1), Vector2.new(x1, y1 - seg)},
		{Vector2.new(x0, y1), Vector2.new(x0 + seg, y1)},
		{Vector2.new(x0, y1), Vector2.new(x0, y1 - seg)},
	}
	for i = 1, 8 do
		local l = e.b[i]
		l.From = pts[i][1]
		l.To = pts[i][2]
		l.Color = S.BoxColor
		l.Visible = true
	end

	if S.Health and h then
		local frac = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
		local bx = x0 - 6
		e.hb.Visible = true
		e.hb.From = Vector2.new(bx, y0)
		e.hb.To = Vector2.new(bx, y1)
		e.hf.Visible = frac > 0.01
		e.hf.From = Vector2.new(bx, y1 - hh * frac)
		e.hf.To = Vector2.new(bx, y1)
		e.hf.Color = Color3.fromRGB(255, 55, 55):Lerp(Color3.fromRGB(70, 255, 130), frac)
	else
		e.hb.Visible = false
		e.hf.Visible = false
	end

	if e.d then
		if S.Dist then
			local dist = math.floor((cf.Position - cam.CFrame.Position).Magnitude + 0.5)
			e.d.Text = tostring(dist) .. "m"
			e.d.Position = Vector2.new((x0 + x1) * 0.5, y1 + 4)
			e.d.Visible = true
		else
			e.d.Visible = false
		end
	end

	highlight(model, true)
end

Run.RenderStepped:Connect(function()
	cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize

	for i = #tracers, 1, -1 do
		local t = tracers[i]
		local age = os.clock() - t.t
		if age > 0.42 or not S.Enabled then
			pcall(function() t.l:Remove() end)
			table.remove(tracers, i)
		else
			local sp, on = cam:WorldToViewportPoint(t.p)
			t.l.Visible = on
			if on then
				t.l.From = Vector2.new(vp.X * 0.5, vp.Y - 24)
				t.l.To = Vector2.new(sp.X, sp.Y)
				t.l.Transparency = 1 - age / 0.42
			end
		end
	end

	-- 關閉開關時隱藏所有 ESP 畫面
	if not S.Enabled then
		for model, e in pairs(entries) do
			hide(e)
			highlight(model, false)
		end
		return
	end

	local live = {}

	for _, p in ipairs(Plrs:GetPlayers()) do
		local c = p.Character
		if p ~= LP and c and c:IsDescendantOf(workspace)
			and c:GetAttribute("CurrentHighlight") ~= "SpawnProtection" then
			live[c] = true
			render(c)
		end
	end

	if not bots or not bots.Parent then bots = workspace:FindFirstChild("BotCharacters") end
	if bots then
		for _, m in ipairs(bots:GetChildren()) do
			if m:IsA("Model") and m:IsDescendantOf(workspace)
				and m:GetAttribute("CurrentHighlight") ~= "SpawnProtection" then
				live[m] = true
				render(m)
			end
		end
	end

	if not dummies or not dummies.Parent then
		local sr = workspace:FindFirstChild("Shooting Range")
		dummies = sr and sr:FindFirstChild("Dummies") or nil
	end
	if dummies then
		for _, m in ipairs(dummies:GetChildren()) do
			if m:IsA("Model") then
				live[m] = true
				render(m)
			end
		end
	end

	for model, e in pairs(entries) do
		if not live[model] then
			if model.Parent then
				hide(e)
				highlight(model, false)
			else
				drop(model)
			end
		end
	end
end)

local function watch(p)
	if p == LP then return end
	p.CharacterRemoving:Connect(function(c)
		task.wait(0.2)
		drop(c)
	end)
end

for _, p in ipairs(Plrs:GetPlayers()) do watch(p) end
Plrs.PlayerAdded:Connect(watch)
Plrs.PlayerRemoving:Connect(function(p)
	if p.Character then drop(p.Character) end
end)

-- ==================== UI 控制設定 ====================
local function onAutoPlayerToggle(enabled)
	S.Enabled = enabled
	S.Auto = enabled
	if not enabled then
		lastPos = nil
	end
	print("[Auto player]", enabled and "已開啟" or "已關閉")
end

UI:Toggle("AutoPlayerToggle", "Auto Kill", onAutoPlayerToggle)
UI:Status("Status", "Tik Tok: ValueHat")

print("[ValueHat] Auto player loaded!")
