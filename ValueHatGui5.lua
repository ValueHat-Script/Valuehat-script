-- =====================================================================
-- ⚡ VALUEHAT CYBERPUNK UI LIBRARY (GitHub Open-Source Template)
-- =====================================================================

local ValueHatUI = {}

function ValueHatUI.Init()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    -- 防止重複執行畫面疊加
    if CoreGui:FindFirstChild("TechCyberGui") then
        CoreGui.TechCyberGui:Destroy()
    end

    -- 建立主 ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TechCyberGui"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    -- 預先計算總高度 (動態不留白)
    local TITLE_HEIGHT = 32
    local TOTAL_CONTENT_HEIGHT = 10 + 30 + 6 + 30 + 6 + 30 + 6 + 40 + 6 + 45 + 6 + 22 + 10
    local INITIAL_HEIGHT = TITLE_HEIGHT + TOTAL_CONTENT_HEIGHT

    -- 🌟 放大版九宮格漸層藍紫色光暈陰影 (ImageLabel Shadow)
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Parent = ScreenGui
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageColor3 = Color3.fromRGB(0, 140, 255)
    Shadow.ImageTransparency = 0.35
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = 0
    Shadow.Position = UDim2.new(0.5, -110 - 25, 0.5, -INITIAL_HEIGHT / 2 - 25)
    Shadow.Size = UDim2.new(0, 220 + 50, 0, INITIAL_HEIGHT + 50)

    -- 主視窗背景
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 26)
    MainFrame.BackgroundTransparency = 0
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -INITIAL_HEIGHT / 2)
    MainFrame.Size = UDim2.new(0, 220, 0, INITIAL_HEIGHT)
    MainFrame.Active = true
    MainFrame.Draggable = false
    MainFrame.ZIndex = 1

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = MainFrame
    UIStroke.Color = Color3.fromRGB(0, 110, 230)
    UIStroke.Transparency = 0
    UIStroke.Thickness = 1.5

    -- 頂部標題列
    local TitleBar = Instance.new("Frame")
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(16, 24, 44)
    TitleBar.BackgroundTransparency = 0
    TitleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
    TitleBar.ZIndex = 2

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 6)
    TitleCorner.Parent = TitleBar

    local TitleStroke = Instance.new("UIStroke")
    TitleStroke.Parent = TitleBar
    TitleStroke.Color = Color3.fromRGB(0, 100, 200)
    TitleStroke.Transparency = 0.3
    TitleStroke.Thickness = 1

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = TitleBar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 8, 0, 0)
    TitleLabel.Size = UDim2.new(0.75, 0, 1, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "⚡ VALUEHAT"
    TitleLabel.TextColor3 = Color3.fromRGB(190, 220, 255)
    TitleLabel.TextSize = 11
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 3

    -- 同步陰影位置與大小函數
    local function syncShadow(targetSize)
        Shadow.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset - 25, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset - 25)
        Shadow.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset + 50, targetSize.Y.Scale, targetSize.Y.Offset + 50)
    end
    syncShadow(MainFrame.Size)

    -- 拖曳系統
    local dragging, dragStart, startPos, activeInput = false, nil, nil, nil
    TitleBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeInput then
            dragging, activeInput, dragStart, startPos = true, input, input.Position, MainFrame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input == activeInput then dragging, activeInput = false, nil end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == activeInput then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            syncShadow(MainFrame.Size)
        end
    end)

    -- 內容容器
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = MainFrame
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 0, 0, TITLE_HEIGHT)
    ContentContainer.Size = UDim2.new(1, 0, 1, -TITLE_HEIGHT)
    ContentContainer.ClipsDescendants = true
    ContentContainer.ZIndex = 2

    -- 收合/展開按鈕
    local ToggleCollapseBtn = Instance.new("TextButton")
    ToggleCollapseBtn.Parent = TitleBar
    ToggleCollapseBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 130)
    ToggleCollapseBtn.BackgroundTransparency = 0
    ToggleCollapseBtn.Position = UDim2.new(1, -26, 0.5, -10)
    ToggleCollapseBtn.Size = UDim2.new(0, 20, 0, 20)
    ToggleCollapseBtn.Font = Enum.Font.GothamBold
    ToggleCollapseBtn.Text = "-"
    ToggleCollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCollapseBtn.TextSize = 14
    ToggleCollapseBtn.ZIndex = 3

    local TCBRCorner = Instance.new("UICorner")
    TCBRCorner.CornerRadius = UDim.new(0, 4)
    TCBRCorner.Parent = ToggleCollapseBtn

    local isCollapsed = false
    ToggleCollapseBtn.MouseButton1Click:Connect(function()
        isCollapsed = not isCollapsed
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if isCollapsed then
            ToggleCollapseBtn.Text = "+"
            local targetSize = UDim2.new(0, 220, 0, TITLE_HEIGHT)
            TweenService:Create(MainFrame, tweenInfo, {Size = targetSize}):Play()
            TweenService:Create(Shadow, tweenInfo, {Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset + 50, targetSize.Y.Scale, targetSize.Y.Offset + 50)}):Play()
        else
            ToggleCollapseBtn.Text = "-"
            local targetSize = UDim2.new(0, 220, 0, INITIAL_HEIGHT)
            TweenService:Create(MainFrame, tweenInfo, {Size = targetSize}):Play()
            TweenService:Create(Shadow, tweenInfo, {Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset + 50, targetSize.Y.Scale, targetSize.Y.Offset + 50)}):Play()
        end
    end)


    -- ==================== 🛠️ 元件建構子函數庫 ====================

    local Library = {}

    function Library:Button(name, text, yPos, callback)
        local btnContainer = Instance.new("Frame")
        btnContainer.Name = name .. "_Container"
        btnContainer.Parent = ContentContainer
        btnContainer.BackgroundColor3 = Color3.fromRGB(16, 28, 52)
        btnContainer.Position = UDim2.new(0.05, 0, 0, yPos)
        btnContainer.Size = UDim2.new(0.9, 0, 0, 30)
        btnContainer.ZIndex = 2

        local containerCorner = Instance.new("UICorner")
        containerCorner.CornerRadius = UDim.new(0, 4)
        containerCorner.Parent = btnContainer

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Parent = btnContainer
        btnStroke.Color = Color3.fromRGB(0, 120, 220)
        btnStroke.Thickness = 1.5

        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Parent = btnContainer
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(180, 210, 255)
        btn.TextSize = 10
        btn.ZIndex = 3

        btn.MouseButton1Click:Connect(function()
            local flashInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local resetInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(btnContainer, flashInfo, {BackgroundColor3 = Color3.fromRGB(0, 140, 255)}):Play()
            TweenService:Create(btn, flashInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            task.delay(0.1, function()
                TweenService:Create(btnContainer, resetInfo, {BackgroundColor3 = Color3.fromRGB(16, 28, 52)}):Play()
                TweenService:Create(btn, resetInfo, {TextColor3 = Color3.fromRGB(180, 210, 255)}):Play()
            end)
            if callback then callback() end
        end)
    end

    function Library:Toggle(name, text, yPos, callback)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Name = name
        toggleFrame.Parent = ContentContainer
        toggleFrame.BackgroundColor3 = Color3.fromRGB(16, 28, 52)
        toggleFrame.Position = UDim2.new(0.05, 0, 0, yPos)
        toggleFrame.Size = UDim2.new(0.9, 0, 0, 30)
        toggleFrame.ZIndex = 2

        local tfCorner = Instance.new("UICorner")
        tfCorner.CornerRadius = UDim.new(0, 4)
        tfCorner.Parent = toggleFrame

        local tfStroke = Instance.new("UIStroke")
        tfStroke.Parent = toggleFrame
        tfStroke.Color = Color3.fromRGB(0, 120, 220)
        tfStroke.Thickness = 1.5

        local label = Instance.new("TextLabel")
        label.Parent = toggleFrame
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 8, 0, 0)
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = text
        label.TextColor3 = Color3.fromRGB(180, 210, 255)
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3

        local switchBg = Instance.new("Frame")
        switchBg.Parent = toggleFrame
        switchBg.BackgroundColor3 = Color3.fromRGB(24, 40, 70)
        switchBg.BorderSizePixel = 0
        switchBg.Position = UDim2.new(1, -38, 0.5, -9)
        switchBg.Size = UDim2.new(0, 32, 0, 18)
        switchBg.ZIndex = 3

        local sbCorner = Instance.new("UICorner")
        sbCorner.CornerRadius = UDim.new(1, 0)
        sbCorner.Parent = switchBg

        local knob = Instance.new("Frame")
        knob.Parent = switchBg
        knob.BackgroundColor3 = Color3.fromRGB(150, 180, 220)
        knob.BorderSizePixel = 0
        knob.Position = UDim2.new(0, 2, 0.5, -7)
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.ZIndex = 4

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local state = false
        local clickBtn = Instance.new("TextButton")
        clickBtn.Parent = toggleFrame
        clickBtn.BackgroundTransparency = 1
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.Text = ""
        clickBtn.ZIndex = 5

        clickBtn.MouseButton1Click:Connect(function()
            state = not state
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            if state then
                TweenService:Create(switchBg, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 120, 220)}):Play()
                TweenService:Create(knob, tweenInfo, {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            else
                TweenService:Create(switchBg, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 40, 70)}):Play()
                TweenService:Create(knob, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(150, 180, 220)}):Play()
            end
            callback(state)
        end)
    end

    function Library:Dropdown(name, text, options, yPos, callback)
        local dropFrame = Instance.new("Frame")
        dropFrame.Name = name
        dropFrame.Parent = ContentContainer
        dropFrame.BackgroundColor3 = Color3.fromRGB(16, 28, 52)
        dropFrame.Position = UDim2.new(0.05, 0, 0, yPos)
        dropFrame.Size = UDim2.new(0.9, 0, 0, 30)
        dropFrame.ClipsDescendants = false
        dropFrame.ZIndex = 5

        local dfCorner = Instance.new("UICorner")
        dfCorner.CornerRadius = UDim.new(0, 4)
        dfCorner.Parent = dropFrame

        local dfStroke = Instance.new("UIStroke")
        dfStroke.Parent = dropFrame
        dfStroke.Color = Color3.fromRGB(0, 120, 220)
        dfStroke.Thickness = 1.5

        local label = Instance.new("TextLabel")
        label.Parent = dropFrame
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 8, 0, 0)
        label.Size = UDim2.new(1, -25, 0, 30)
        label.Font = Enum.Font.GothamSemibold
        label.Text = text .. ": " .. options[1]
        label.TextColor3 = Color3.fromRGB(180, 210, 255)
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6

        local arrow = Instance.new("TextLabel")
        arrow.Parent = dropFrame
        arrow.BackgroundTransparency = 1
        arrow.Position = UDim2.new(1, -22, 0, 0)
        arrow.Size = UDim2.new(0, 20, 0, 30)
        arrow.Font = Enum.Font.GothamBold
        arrow.Text = "▼"
        arrow.TextColor3 = Color3.fromRGB(150, 180, 220)
        arrow.TextSize = 9
        arrow.ZIndex = 6

        local isOpen = false
        local optionHeight = 26
        local maxVisibleOptions = 4
        local calculatedListHeight = #options * optionHeight
        local maxListHeight = maxVisibleOptions * optionHeight
        local finalShowHeight = calculatedListHeight > maxListHeight and maxListHeight or calculatedListHeight
        local totalFrameHeight = 30 + finalShowHeight

        local listContainer = Instance.new("ScrollingFrame")
        listContainer.Parent = dropFrame
        listContainer.BackgroundColor3 = Color3.fromRGB(14, 24, 44)
        listContainer.BorderSizePixel = 0
        listContainer.Position = UDim2.new(0, 0, 0, 30)
        listContainer.Size = UDim2.new(1, 0, 0, 0)
        listContainer.CanvasSize = UDim2.new(0, 0, 0, calculatedListHeight)
        listContainer.ScrollBarThickness = 3
        listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
        listContainer.Visible = false
        listContainer.ZIndex = 10

        local listStroke = Instance.new("UIStroke")
        listStroke.Parent = listContainer
        listStroke.Color = Color3.fromRGB(0, 120, 220)
        listStroke.Thickness = 1

        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Parent = listContainer
            optBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 68)
            optBtn.BorderSizePixel = 0
            optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * optionHeight)
            optBtn.Size = UDim2.new(1, 0, 0, optionHeight - 2)
            optBtn.Font = Enum.Font.Gotham
            optBtn.Text = opt
            optBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
            optBtn.TextSize = 10
            optBtn.ZIndex = 11

            optBtn.MouseButton1Click:Connect(function()
                label.Text = text .. ": " .. opt
                isOpen = false
                listContainer.Visible = false
                TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.9, 0, 0, 30)}):Play()
                TweenService:Create(listContainer, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                arrow.Text = "▼"
                callback(opt)
            end)
        end

        listContainer.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                listContainer.CanvasPosition = Vector2.new(0, math.clamp(listContainer.CanvasPosition.Y - (input.Position.Z * 20), 0, math.max(0, calculatedListHeight - finalShowHeight)))
            end
        end)

        local mainBtn = Instance.new("TextButton")
        mainBtn.Parent = dropFrame
        mainBtn.BackgroundTransparency = 1
        mainBtn.Size = UDim2.new(1, 0, 0, 30)
        mainBtn.Text = ""
        mainBtn.ZIndex = 7

        mainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            if isOpen then
                listContainer.Visible = true
                TweenService:Create(dropFrame, tweenInfo, {Size = UDim2.new(0.9, 0, 0, totalFrameHeight)}):Play()
                TweenService:Create(listContainer, tweenInfo, {Size = UDim2.new(1, 0, 0, finalShowHeight)}):Play()
                arrow.Text = "▲"
            else
                TweenService:Create(dropFrame, tweenInfo, {Size = UDim2.new(0.9, 0, 0, 30)}):Play()
                local tw = TweenService:Create(listContainer, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)})
                tw:Play()
                tw.Completed:Wait()
                if not isOpen then listContainer.Visible = false end
                arrow.Text = "▼"
            end
        end)
    end

    function Library:Slider(name, text, min, max, default, yPos, callback)
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Name = name
        sliderFrame.Parent = ContentContainer
        sliderFrame.BackgroundColor3 = Color3.fromRGB(16, 28, 52)
        sliderFrame.Position = UDim2.new(0.05, 0, 0, yPos)
        sliderFrame.Size = UDim2.new(0.9, 0, 0, 40)
        sliderFrame.ZIndex = 2

        local sfCorner = Instance.new("UICorner")
        sfCorner.CornerRadius = UDim.new(0, 4)
        sfCorner.Parent = sliderFrame

        local sfStroke = Instance.new("UIStroke")
        sfStroke.Parent = sliderFrame
        sfStroke.Color = Color3.fromRGB(0, 120, 220)
        sfStroke.Thickness = 1.5

        local label = Instance.new("TextLabel")
        label.Parent = sliderFrame
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 8, 0, 2)
        label.Size = UDim2.new(1, -16, 0, 16)
        label.Font = Enum.Font.GothamSemibold
        label.Text = text .. ": " .. default
        label.TextColor3 = Color3.fromRGB(180, 210, 255)
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 3

        local track = Instance.new("Frame")
        track.Parent = sliderFrame
        track.BackgroundColor3 = Color3.fromRGB(24, 40, 70)
        track.BorderSizePixel = 0
        track.Position = UDim2.new(0, 10, 0, 24)
        track.Size = UDim2.new(1, -20, 0, 6)
        track.ZIndex = 3

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Parent = track
        fill.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.ZIndex = 4

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local sliderDragging = false
        local sliderInput = nil

        local function updateSlider(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + ((max - min) * pos))
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = text .. ": " .. value
            callback(value)
        end

        track.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not sliderInput then
                sliderDragging = true
                    sliderInput = input
                updateSlider(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input == sliderInput then
                sliderDragging = false
                sliderInput = nil
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if sliderDragging and input == sliderInput then
                updateSlider(input)
            end
        end)
    end

    function Library:Input(name, titleText, placeholder, yPos, callback)
        local inputFrame = Instance.new("Frame")
        inputFrame.Name = name
        inputFrame.Parent = ContentContainer
        inputFrame.BackgroundColor3 = Color3.fromRGB(16, 28, 52)
        inputFrame.Position = UDim2.new(0.05, 0, 0, yPos)
        inputFrame.Size = UDim2.new(0.9, 0, 0, 45)
        inputFrame.ZIndex = 2

        local ifCorner = Instance.new("UICorner")
        ifCorner.CornerRadius = UDim.new(0, 4)
        ifCorner.Parent = inputFrame

        local ifStroke = Instance.new("UIStroke")
        ifStroke.Parent = inputFrame
        ifStroke.Color = Color3.fromRGB(0, 120, 220)
        ifStroke.Thickness = 1.5

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = inputFrame
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 8, 0, 2)
        titleLabel.Size = UDim2.new(1, -16, 0, 16)
        titleLabel.Font = Enum.Font.GothamSemibold
        titleLabel.Text = titleText
        titleLabel.TextColor3 = Color3.fromRGB(180, 210, 255)
        titleLabel.TextSize = 10
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 3

        local textBox = Instance.new("TextBox")
        textBox.Parent = inputFrame
        textBox.BackgroundColor3 = Color3.fromRGB(12, 20, 38)
        textBox.BorderSizePixel = 0
        textBox.Position = UDim2.new(0, 6, 0, 20)
        textBox.Size = UDim2.new(1, -12, 0, 20)
        textBox.Font = Enum.Font.Gotham
        textBox.PlaceholderText = placeholder
        textBox.PlaceholderColor3 = Color3.fromRGB(100, 130, 170)
        textBox.Text = ""
        textBox.TextColor3 = Color3.fromRGB(220, 240, 255)
        textBox.TextSize = 10
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        textBox.ZIndex = 3

        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 3)
        tbCorner.Parent = textBox

        textBox.FocusLost:Connect(function(enterPressed)
            callback(textBox.Text, enterPressed)
        end)
    end

    function Library:Status(name, text, yPos)
        local statusContainer = Instance.new("Frame")
        statusContainer.Name = name .. "_Container"
        statusContainer.Parent = ContentContainer
        statusContainer.BackgroundColor3 = Color3.fromRGB(14, 22, 40)
        statusContainer.Position = UDim2.new(0.05, 0, 0, yPos)
        statusContainer.Size = UDim2.new(0.9, 0, 0, 22)
        statusContainer.ZIndex = 2

        local scCorner = Instance.new("UICorner")
        scCorner.CornerRadius = UDim.new(0, 4)
        scCorner.Parent = statusContainer

        local scStroke = Instance.new("UIStroke")
        scStroke.Parent = statusContainer
        scStroke.Color = Color3.fromRGB(0, 150, 255)
        scStroke.Thickness = 1.5

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = name
        statusLabel.Parent = statusContainer
        statusLabel.BackgroundTransparency = 1
        statusLabel.Position = UDim2.new(0, 8, 0, 0)
        statusLabel.Size = UDim2.new(1, -16, 1, 0)
        statusLabel.Font = Enum.Font.Code
        statusLabel.Text = text
        statusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        statusLabel.TextSize = 9
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.ZIndex = 3
    end

    return Library
end

return ValueHatUI
               
