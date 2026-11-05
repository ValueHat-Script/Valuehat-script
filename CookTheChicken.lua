-- ValueHat gui 5
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Cook The Chicken")

local Remotes = game:GetService("ReplicatedStorage").Remotes
local SwingEvent = Remotes.SpatulaSwing
local CollectEvent = Remotes.CollectCash

local fastSwing = false
local autoCalculate = false
local autoCollect = false

UI:Toggle("Toggle", "Fast Swing", function(enabled)
    fastSwing = enabled
    if enabled then
        task.spawn(function()
            while fastSwing do
                SwingEvent:FireServer(0)
                task.wait()
            end
        end)
    end
end)

UI:Toggle("Toggle", "Auto Calculate", function(enabled)
    autoCalculate = enabled
    if enabled then
        task.spawn(function()
            while autoCalculate do
                local body = workspace.Props.SmackConverter:FindFirstChild("Body")
                local prompt = body and body:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    fireproximityprompt(prompt)
                end
                task.wait(0.1)
            end
        end)
    end
end)

UI:Toggle("Toggle", "Auto Collect Money", function(enabled)
    autoCollect = enabled
    if enabled then
        task.spawn(function()
            while autoCollect do
                CollectEvent:FireServer(workspace.Props.SmackConverter)
                task.wait(0.5)
            end
        end)
    end
end)
