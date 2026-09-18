-- 動態載入 ValueHatGui UI 模組
local UIModule = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui4.lua"
))()

-- 建立主視窗
local Hub = UIModule.CreateWindow("[20] MM2", "TikTok: ValueHat")

-- 服務與玩家設定
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 變數設定
local autoCoinEnabled = false

--------------------------------------------------
-- UI 開關：Auto Coin
--------------------------------------------------

Hub:CreateToggle("Auto Coin", false, function(isOn)
    autoCoinEnabled = isOn
end)

--------------------------------------------------
-- 取得大廳出生點位置
-- workspace.RegularLobby.Spawns:GetChildren()[8]
--------------------------------------------------

local function GetLobbySpawnCFrame()
    local regularLobby = workspace:FindFirstChild("RegularLobby")

    if not regularLobby then
        return nil
    end

    local spawns = regularLobby:FindFirstChild("Spawns")

    if not spawns then
        return nil
    end

    local spawnList = spawns:GetChildren()
    local targetSpawn = spawnList[8]

    if not targetSpawn then
        return nil
    end

    if targetSpawn:IsA("Model") then
        return targetSpawn:GetPivot()
    elseif targetSpawn:IsA("BasePart") then
        return targetSpawn.CFrame
    end

    return nil
end

--------------------------------------------------
-- 取得角色 HumanoidRootPart
--------------------------------------------------

local function GetHRP()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------
-- 取得 Coin 的 TouchPart
--------------------------------------------------

local function GetCoinTouchPart(coin)
    -- 必須是 Coin_Server
    if coin.Name ~= "Coin_Server" then
        return nil
    end

    -- 必須存在 TouchInterest
    local touchInterest = coin:FindFirstChild("TouchInterest", true)

    if not touchInterest then
        return nil
    end

    -- Coin_Server 自己就是 BasePart
    if coin:IsA("BasePart") then
        return coin
    end

    -- 否則尋找裡面的 BasePart
    local touchPart = coin:FindFirstChildWhichIsA("BasePart", true)

    if not touchPart then
        return nil
    end

    -- 確認 TouchInterest 確實存在於這個 BasePart
    local partTouchInterest = touchPart:FindFirstChild("TouchInterest")

    if not partTouchInterest then
        return nil
    end

    return touchPart
end

--------------------------------------------------
-- 收集單個 Coin
--------------------------------------------------

local function CollectCoin(coin)
    if not autoCoinEnabled then
        return
    end

    local hrp = GetHRP()

    if not hrp then
        return
    end

    -- 沒有 TouchInterest → 完全不傳送
    local touchPart = GetCoinTouchPart(coin)

    if not touchPart then
        return
    end

    print("[Auto Coin] 發現有效 Coin，準備傳送...")

    --------------------------------------------------
    -- 1. 傳送到金幣
    --------------------------------------------------

    hrp.CFrame = touchPart.CFrame
    task.wait(0.1)

    if not autoCoinEnabled then
        return
    end

    --------------------------------------------------
    -- 2. 觸發 TouchInterest
    --------------------------------------------------

    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, touchPart, 0)

            task.wait(0.05)

            firetouchinterest(hrp, touchPart, 1)
        end)
    end

    task.wait(0.1)

    if not autoCoinEnabled then
        return
    end

    --------------------------------------------------
    -- 3. 傳送回大廳出生點
    --------------------------------------------------

    local lobbyCF = GetLobbySpawnCFrame()

    if lobbyCF then
        hrp.CFrame = lobbyCF * CFrame.new(0, 3, 0)

        print("[Auto Coin] 已傳送回大廳，休息 2 秒...")
    else
        warn("[Auto Coin] 找不到 workspace.RegularLobby.Spawns:GetChildren()[8]！")
    end

    --------------------------------------------------
    -- 4. 休息 2 秒
    --------------------------------------------------

    task.wait(2)
end

--------------------------------------------------
-- 自動吃金幣主邏輯
--------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.1)

        if not autoCoinEnabled then
            continue
        end

        local hrp = GetHRP()

        if not hrp then
            continue
        end

        --------------------------------------------------
        -- 搜尋 workspace 中的 CoinContainer
        --------------------------------------------------

        local coinContainer = workspace:FindFirstChild(
            "CoinContainer",
            true
        )

        if not coinContainer then
            continue
        end

        --------------------------------------------------
        -- 掃描所有 Coin_Server
        --------------------------------------------------

        for _, coin in ipairs(coinContainer:GetChildren()) do

            if not autoCoinEnabled then
                break
            end

            --------------------------------------------------
            -- 只處理 Coin_Server
            --------------------------------------------------

            if coin.Name == "Coin_Server" then

                --------------------------------------------------
                -- 沒有 TouchInterest：
                -- 直接跳過，絕對不傳送
                --------------------------------------------------

                local touchInterest = coin:FindFirstChild(
                    "TouchInterest",
                    true
                )

                if not touchInterest then
                    continue
                end

                --------------------------------------------------
                -- 再確認真正的 TouchPart
                --------------------------------------------------

                local touchPart

                if coin:IsA("BasePart") then
                    touchPart = coin
                else
                    touchPart = coin:FindFirstChildWhichIsA(
                        "BasePart",
                        true
                    )
                end

                if not touchPart then
                    continue
                end

                --------------------------------------------------
                -- 確認 TouchPart 自己有 TouchInterest
                --------------------------------------------------

                if not touchPart:FindFirstChild("TouchInterest") then
                    continue
                end

                --------------------------------------------------
                -- 開始收集
                --------------------------------------------------

                CollectCoin(coin)
            end
        end
    end
end)

