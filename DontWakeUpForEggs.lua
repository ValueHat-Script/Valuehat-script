-- 動態載入 ValueHatGui UI 模組
local success, UIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"))()
end)

if not success or not UIModule then
    warn("[Error] UI 模組載入失敗：", UIModule)
    return
end

-- 服務
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 遠端事件 (Remote Events)
local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local openEggRemote = remotes and remotes:FindFirstChild("OpenEgg")
local placeEggRemote = remotes and remotes:FindFirstChild("PlaceEgg")
local equipBestRemote = remotes and remotes:FindFirstChild("EquipBestAnimals")

-- 變數
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoHatchEnabled = false
local equipBestEnabled = false
local selectedRarity = "All"
local lastEgg = nil
local ragdollUpDetected = false

-- 稀有度選單列表（包含 Historic）
local rarityList = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Secret", "Antarctic", "Historic"}

-- 座標
local RETURN_POSITION = Vector3.new(2, -39, 701)
local WALK_TARGET = Vector3.new(2, -39, 709)

-- 即時傳送
local function teleportTo(cframe)
    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    pcall(function()
        character:PivotTo(cframe)
    end)

    task.wait()
    if root and root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

local function getCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Attachment") then
        return obj.WorldCFrame
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        end
        local best, size = nil, 0
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") and d.Size.Magnitude > size then
                best, size = d, d.Size.Magnitude
            end
        end
        if best then return best.CFrame end
        return obj:GetPivot()
    end
    return nil
end

-- 取得蛋的稀有度標籤文字 (路徑: PickableBillboard.RarityLabel.Text)
local function getEggRarity(egg)
    local billboard = egg:FindFirstChild("PickableBillboard", true)
    if billboard then
        local rarityLabel = billboard:FindFirstChild("RarityLabel", true)
        if rarityLabel and rarityLabel:IsA("TextLabel") then
            return rarityLabel.Text
        end
    end
    return nil
end

-- 取得符合當前選擇條件的 WildEggs
local function getWildEggs()
    local list = {}
    local folder = workspace:FindFirstChild("WildEggRender")
    if not folder then return list end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child.Name:find("WildEgg") then
            if selectedRarity == "All" then
                table.insert(list, child)
            else
                local rarity = getEggRarity(child)
                if rarity and rarity:lower() == selectedRarity:lower() then
                    table.insert(list, child)
                end
            end
        end
    end

    return list
end

local function findPrompt(egg)
    if not egg then return nil end
    return egg:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function walkTo(position)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    humanoid:MoveTo(position)

    local start = tick()
    while (root.Position - position).Magnitude > 4 and tick() - start < 8 do
        if not autoEggEnabled then break end
        humanoid:MoveTo(position)
        task.wait(0.2)
    end
end

-- ==================== RagdollUp 偵測 ====================

local function setupRagdollUpListener()
    if not remotes then return end

    local remote = remotes:FindFirstChild("RagdollUp")
    if remote and remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function()
            ragdollUpDetected = true
        end)
    end

    remotes.ChildAdded:Connect(function(child)
        if child.Name == "RagdollUp" and child:IsA("RemoteEvent") then
            child.OnClientEvent:Connect(function()
                ragdollUpDetected = true
            end)
        end
    end)

    if getrawmetatable and setreadonly and newcclosure and getnamecallmethod then
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()

            if (method == "FireServer" or method == "FireClient")
                and typeof(self) == "Instance"
                and self.Name == "RagdollUp" then
                ragdollUpDetected = true
            end

            return oldNamecall(self, ...)
        end)

        setreadonly(mt, true)
    end
end

setupRagdollUpListener()

local function waitForRagdollUp()
    ragdollUpDetected = false
    while autoEggEnabled do
        if ragdollUpDetected then
            ragdollUpDetected = false
            return true
        end
        task.wait(0.1)
    end
    return false
end

-- ==================== Base 與工具搜尋 ====================

local function getMyBase()
    local playerName = LocalPlayer.Name

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text then
            if obj.Text:find(playerName) then
                local current = obj
                for _ = 1, 12 do
                    if not current or current == workspace then break end
                    if current.Name == "Base" or current:FindFirstChild("Plot") then
                        return current
                    end
                    if current.Name == "BaseUI" and current.Parent then
                        return current.Parent
                    end
                    current = current.Parent
                end
            end
        end
    end
    return nil
end

local function getFloorPosition(base)
    if not base then return nil end

    local plot = base:FindFirstChild("Plot")
    local floor = (plot and plot:FindFirstChild("Floor")) or base:FindFirstChild("Floor", true)
    if not floor then return nil end

    if floor:IsA("BasePart") then
        return floor.Position + Vector3.new(0, 1, 0)
    end

    local part = floor:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position + Vector3.new(0, 1, 0)
    end

    local cf = getCFrame(floor)
    if cf then
        return cf.Position + Vector3.new(0, 1, 0)
    end
    return nil
end

local function getEggTools()
    local list = {}

    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("egg") then
                local uid = item:GetAttribute("UID")
                    or item:GetAttribute("Uid")
                    or item:GetAttribute("EntityId")
                    or item:GetAttribute("Id")

                if not uid then
                    local uidVal = item:FindFirstChild("UID") or item:FindFirstChild("Uid")
                    if uidVal and uidVal:IsA("ValueBase") then
                        uid = uidVal.Value
                    end
                end

                if typeof(uid) == "string" and #uid > 8 then
                    table.insert(list, {
                        tool = item,
                        name = item.Name,
                        uid = uid,
                    })
                end
            end
        end
    end

    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return list
end

-- ==================== Auto Equip Best 邏輯 ====================

local function equipBestAnimals()
    if equipBestRemote then
        pcall(function()
            equipBestRemote:FireServer()
        end)
    end
end

-- ==================== Auto Place 邏輯 ====================

local function startAutoPlace()
    task.spawn(function()
        while autoPlaceEnabled do
            local base = getMyBase()
            local floorPos = getFloorPosition(base)
            local eggs = getEggTools()
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if base and floorPos and #eggs > 0 and placeEggRemote and humanoid then
                local selected = eggs[math.random(1, #eggs)]

                humanoid:EquipTool(selected.tool)
                task.wait(0.3)

                pcall(function()
                    placeEggRemote:FireServer(selected.name, floorPos, selected.uid)
                end)
                task.wait(0.45)

                humanoid:UnequipTools()
            else
                task.wait(1.5)
            end

            task.wait(1.2)
        end
    end)
end

-- ==================== Auto Hatch 邏輯 ====================

local function getPlacedEggUUIDs()
    local uuids = {}
    local base = getMyBase()
    if not base then return uuids end

    local eggsFolder = base:FindFirstChild("Eggs", true)
    if eggsFolder then
        for _, child in ipairs(eggsFolder:GetChildren()) do
            if #child.Name >= 20 or child.Name:find("-") then
                table.insert(uuids, child.Name)
            end
        end
    end
    return uuids
end

local function startAutoHatch()
    task.spawn(function()
        while autoHatchEnabled do
            if openEggRemote then
                local eggUUIDs = getPlacedEggUUIDs()

                if #eggUUIDs > 0 then
                    for _, uuid in ipairs(eggUUIDs) do
                        if not autoHatchEnabled then break end
                        pcall(function()
                            openEggRemote:FireServer(uuid)
                        end)
                        task.wait(0.2)
                    end
                else
                    task.wait(1.5)
                end
            else
                warn("[Auto Hatch] 未找到 OpenEgg 遠端事件")
                task.wait(2)
            end

            task.wait(0.5)
        end
    end)
end

-- ==================== UI 與主要流程 ====================

local Hub = UIModule.CreateWindow("Don't wake up for eggs", "TikTok: ValueHat")

-- 新增 Select Rarity 下拉選單（切換時即時生效）
Hub:CreateDropdown("Select Rarity", rarityList, selectedRarity, function(v)
    selectedRarity = v
    print("[Select Rarity] 已切換稀有度為:", selectedRarity)
end)

local function startAutoEgg()
    task.spawn(function()
        while autoEggEnabled do
            -- 即時取得當前 selectedRarity 符合條件的蛋
            local eggs = getWildEggs()

            if #eggs > 0 then
                local egg = eggs[math.random(1, #eggs)]
                local cf = getCFrame(egg)

                if cf then
                    lastEgg = egg

                    -- 1. 傳送到蛋
                    teleportTo(cf * CFrame.new(0, 3, 0))
                    task.wait(0.35)

                    -- 2. 觸發 Prompt
                    local prompt = findPrompt(egg)
                    if prompt and prompt.Enabled then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                        task.wait(0.4)
                    else
                        local character = LocalPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                            for _, p in ipairs(workspace:GetDescendants()) do
                                if p:IsA("ProximityPrompt") and p.Enabled then
                                    local pos = getCFrame(p.Parent)
                                    if pos and (pos.Position - root.Position).Magnitude < 12 then
                                        pcall(function()
                                            fireproximityprompt(p)
                                        end)
                                        task.wait(0.4)
                                        break
                                    end
                                end
                            end
                        end
                    end

                    -- 3. 傳回 (2, -39, 701)
                    teleportTo(CFrame.new(RETURN_POSITION))
                    task.wait(0.3)

                    -- 4. 等 RagdollUp
                    if waitForRagdollUp() then
                        -- 5. 回到剛才的蛋
                        task.wait(0.8)
                        if not autoEggEnabled then break end

                        if lastEgg and lastEgg.Parent then
                            local eggCF = getCFrame(lastEgg)
                            if eggCF then
                                teleportTo(eggCF * CFrame.new(0, 3, 0))
                                task.wait(0.35)

                                local prompt2 = findPrompt(lastEgg)
                                if prompt2 and prompt2.Enabled then
                                    pcall(function()
                                        fireproximityprompt(prompt2)
                                    end)
                                    task.wait(0.4)
                                end
                            end
                        end

                        -- 6. 走路到 (2, -39, 709)
                        walkTo(WALK_TARGET)
                        task.wait(0.3)
                    end
                end
            else
                warn("[Auto Egg] 目前找不到符合 " .. selectedRarity .. " 條件的 WildEgg，等待中...")
                task.wait(1.5)
            end

            task.wait(0.5)
        end
    end)
end

Hub:CreateToggle("Auto Egg", false, function(on)
    autoEggEnabled = on
    if on then startAutoEgg() end
end)

Hub:CreateToggle("Auto Place", false, function(on)
    autoPlaceEnabled = on
    if on then startAutoPlace() end
end)

Hub:CreateToggle("Auto Hatch", false, function(on)
    autoHatchEnabled = on
    if on then startAutoHatch() end
end)

Hub:CreateToggle("Equip Best", false, function(on)
    equipBestEnabled = on
    if on then
        equipBestAnimals()
    end
end)

print("[ValueHat] Script loaded successfully")
