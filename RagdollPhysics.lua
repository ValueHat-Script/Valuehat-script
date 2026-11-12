-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Ragdoll Physics")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shooter = ReplicatedStorage:WaitForChild("Shooter", 20)

local S = { gp = false, sb = false }
local O = {}
local pass

local function req(name)
    local inst = Shooter and Shooter:FindFirstChild(name)
    if not inst then return nil end
    local ok, m = pcall(require, inst)
    if ok and type(m) == "table" then return m end
    return nil
end

-- 從各面板模組的 upvalue 裡找遊戲自己的 pass 物件
local function find_pass()
    local order = { "MinigunTrial", "WeaponsPanel", "SandboxPanel", "HUD", "SideBar", "MainMenu", "Sandbox", "TracerPass" }
    for _, name in ipairs(order) do
        local m = req(name)
        if m then
            for _, fn in pairs(m) do
                if type(fn) == "function" then
                    for i = 1, 40 do
                        local ok, v = pcall(debug.getupvalue, fn, i)
                        if not ok then break end
                        if type(v) == "table" then
                            local c = rawget(v, "ctx")
                            if type(c) == "table" then
                                local p = rawget(c, "pass")
                                if type(p) == "table" and type(rawget(p, "isOwned")) == "function" then
                                    return p
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function apply_gp(on)
    pass = pass or find_pass()
    if pass then
        if on then
            if not O.is_owned then O.is_owned = pass.isOwned end
            pass.isOwned = function() return true end
        elseif O.is_owned then
            pass.isOwned = O.is_owned
        end
    end

    local gate = req("PassGate")
    if gate then
        if on then
            if not O.gate then
                O.gate = { wait = gate.wait, owned = gate.owned, confirm = gate.confirm }
            end
            gate.wait = function() return true end
            gate.owned = function() return true end
            gate.confirm = function() return true end
        elseif O.gate then
            gate.wait, gate.owned, gate.confirm = O.gate.wait, O.gate.owned, O.gate.confirm
        end
    end

    local tracer = req("TracerPass")
    if tracer and type(tracer.isOwned) == "function" then
        if on then
            if not O.tracer then O.tracer = tracer.isOwned end
            tracer.isOwned = function() return true end
        elseif O.tracer then
            tracer.isOwned = O.tracer
        end
    end

    S.gp = on
    print("[Gamepasses]", on and "ON" or "OFF", "| pass:", pass ~= nil)
end

local function apply_sb(on)
    local sandbox = req("Sandbox")
    if sandbox then
        pcall(sandbox.forceOwned, on)
        pcall(sandbox.setActive, on)
        S.sb = on and sandbox.active == true
    end
    print("[Sandbox]", on and "ON" or "OFF", "| active:", S.sb)
end

-- 攔截 UserOwnsGamePassAsync（只安裝一次，由 S.gp 控制）
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "UserOwnsGamePassAsync" and S.gp then
            return true
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

UI:Toggle("Toggle", "All Gamepasses", function(enabled)
    apply_gp(enabled)
end)

UI:Toggle("Toggle", "Sandbox Gamepasses", function(enabled)
    apply_sb(enabled)
end)

UI:Status("Status", "Tik Tok: ValueHat")
