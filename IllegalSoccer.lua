local Players = game:GetService("Players")

local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
local Hub = UIModule.CreateWindow("Illegal Soccer", "TikTok: ValueHat")

local Config = {
	InfStamina = false
}

-- ==================== Inf Stamina 模組 ====================
local StaminaUtility = {
	hookhistory = {},
	Players = Players,
	Initialized = false
}

function StaminaUtility:safeFilterGc(t, d, i)
	local s, r = pcall(function(...)
		return filtergc(t, d, i)
	end)
	if s and r then return r end
	return warn('failed to filtergc reason: '..tostring(r))
end

function StaminaUtility:gupv(f, i)
	local s, r = pcall(function()
		return debug.getupvalue(f, i)
	end)
	if s and r then return r end
	return warn('failed to getupvalue err: '..tostring(r))
end

function StaminaUtility:safehook(o, n)
	local s, r = pcall(function(...)
		local h = hookfunction(o, n)
		self.hookhistory[h] = o
		return h
	end)
	if s and r then return r end
	return warn('failed to hookfunction err: '..tostring(r))
end

function StaminaUtility:init()
	if self.Initialized then return end
	
	if not hookfunction or not filtergc or not debug.getupvalue then
		return warn("Executor missing required functions for Inf Stamina")
	end

	self.updateSprint = self:safeFilterGc("function", {Name = "updateSprint"}, true)
	if not self.updateSprint then return end

	self.module = self:gupv(self.updateSprint, 14)
	if not self.module then return end

	self.Update = self.module.Update
	if not self.Update then return warn("failed to get Update func") end

	self.hook = self:safehook(self.Update, function(...)
		if Config.InfStamina then
			local data = select(2, ...)
			if data and rawget(data, "HasUnlimitedStamina") ~= nil then
				rawset(data, "HasUnlimitedStamina", true)
			end
		end 
		return self.hook(...)
	end)

	if self.hook then
		self.Initialized = true
		warn("Inf Stamina Hook Loaded Successfully")
	end
end

-- 預先初始化 Stamina Hook
StaminaUtility:init()

-- ==================== UI 控制開關 ====================
Hub:CreateToggle("Inf Stamina", false, function(isOn)
	Config.InfStamina = isOn
end)
