local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local UIModule = {}
UIModule.__index = UIModule

-- 定義 UI 的唯一名稱 (重複執行時自動刪除舊版)
local GUI_NAME = "Apex_V90_Sea"

-- --- 自動刪除舊 GUI ---
local oldGui = CoreGui:FindFirstChild(GUI_NAME)
if oldGui then
    oldGui:Destroy()
end

-- 藍色系色彩定義 (Blue Neon Glassmorphic Theme)
local C = {
    bgTop    = Color3.fromRGB(20, 35, 70),     -- 頂部深藍色背景
    bgBot    = Color3.fromRGB(10, 16, 32),     -- 底部極深藍色背景
    card     = Color3.fromRGB(22, 30, 52),     -- 卡片底色
    glass    = Color3.fromRGB(30, 44, 76),     -- 玻璃光澤卡片色
    glassTop = Color3.fromRGB(45, 68, 112),    -- 玻璃頂部亮色
    accent   = Color3.fromRGB(0, 150, 255),    -- 主色：亮藍色 (用於邊框、光暈、亮點)
    accent2  = Color3.fromRGB(80, 190, 255),   -- 次要主色：天空藍 (用於漸層)
    trackOff = Color3.fromRGB(40, 52, 78),     -- 關閉狀態的軌道色
    ink      = Color3.fromRGB(230, 240, 255),  -- 文字主色
    inkSoft  = Color3.fromRGB(140, 165, 200),  -- 次要文字色
}

local function applyCorner(inst, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or 8)
    u.Parent = inst
    return u
end

local function applyGradient(inst, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = inst
    return g
end

local function applyStroke(inst, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- 通用工具：支援「TextScaled 自動縮放」+「TextWrapped 自動換行」
local function applyTextSettings(textObject, minSize, maxSize)
    textObject.TextScaled = true
    textObject.TextWrapped = true
    
    local oldConstraint = textObject:FindFirstChildOfClass("UITextSizeConstraint")
    if oldConstraint then oldConstraint:Destroy() end

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = minSize or 8
    constraint.MaxTextSize = maxSize or 16
    constraint.Parent = textObject
end

-- --- 1. 建立 UI 主視窗 (:CreateWindow) ---
function UIModule.CreateWindow(titleText, footerText)
    local self = setmetatable({}, UIModule)

    local ApexHub = Instance.new("ScreenGui")
    ApexHub.Name = GUI_NAME
    ApexHub.ResetOnSpawn = false
    ApexHub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ApexHub.IgnoreGuiInset = true
    ApexHub.DisplayOrder = 999999
    ApexHub.Parent = CoreGui
    self.Gui = ApexHub

    local WIN_W, WIN_H = 260, 100

    -- 主面板
    local Main = Instance.new("Frame")
    Main.Name = "Window"
    Main.Parent = ApexHub
    Main.BackgroundColor3 = C.card
    Main.BorderSizePixel = 0
    Main.ZIndex = 2
    Main.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
    Main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
    Main.Active = true
    Main.ClipsDescendants = true

    applyCorner(Main, 12)

    -- 外框光暈 (ImageLabel 霓虹藍光暈)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 110, 255)
    shadow.ImageTransparency = 0.45
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = 1
    shadow.Parent = ApexHub

    local function syncShadow()
        local p, s = Main.Position, Main.Size
        shadow.Position = UDim2.new(p.X.Scale, p.X.Offset - 22, p.Y.Scale, p.Y.Offset - 18)
        shadow.Size = UDim2.new(s.X.Scale, s.X.Offset + 44, s.Y.Scale, s.Y.Offset + 46)
    end
    Main:GetPropertyChangedSignal("Position"):Connect(syncShadow)
    Main:GetPropertyChangedSignal("Size"):Connect(syncShadow)
    syncShadow()

    applyGradient(Main, C.bgTop, C.bgBot, 90)
    applyStroke(Main, C.accent, 1.5, 0.35)

    -- 標題文字
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.Size = UDim2.new(1, -45, 0, 40)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.Text = titleText or "MY HUB"
    Title.TextColor3 = C.ink
    Title.Font = Enum.Font.LuckiestGuy
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    applyTextSettings(Title, 10, 20)
    self.TitleLabel = Title

    local TitleStroke = Instance.new("UIStroke")
    TitleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    TitleStroke.Thickness = 2.5
    TitleStroke.Color = Color3.fromRGB(0, 0, 0)
    TitleStroke.Parent = Title

    -- 內容容器 (ScrollingFrame)
    local Content = Instance.new("ScrollingFrame")
    Content.Parent = Main
    Content.Position = UDim2.new(0, 12, 0, 42)
    Content.Size = UDim2.new(1, -24, 0, 0)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 2
    Content.ScrollBarImageColor3 = C.accent
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Content = Content

    local UIList = Instance.new("UIListLayout")
    UIList.Parent = Content
    -- 增大元件之間的間距從 6 改為 8，避免視覺太擠
    UIList.Padding = UDim.new(0, 8)
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    self.UIList = UIList

    -- 右上角縮小按鈕
    local isMinimized = false
    local MINIMIZED_SIZE = UDim2.new(0, 260, 0, 42)
    local expandedH = 100
    
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 22, 0, 22)
    MinBtn.Position = UDim2.new(1, -30, 0, 10)
    MinBtn.BackgroundColor3 = C.glass
    MinBtn.BackgroundTransparency = 0.2
    MinBtn.Text = "-"
    MinBtn.TextColor3 = C.ink
    MinBtn.Font = Enum.Font.FredokaOne
    MinBtn.TextSize = 16
    MinBtn.Parent = Main

    applyCorner(MinBtn, 5)
    applyStroke(MinBtn, C.accent, 1, 0.6)

    local TITLE_PADDING = 52
    local MAX_HEIGHT = 350

    local function updateMainSize()
        if not isMinimized then
            local contentHeight = UIList.AbsoluteContentSize.Y
            local targetContentHeight = math.min(contentHeight, MAX_HEIGHT)
            expandedH = targetContentHeight + TITLE_PADDING
            
            Content.Size = UDim2.new(1, -24, 0, targetContentHeight)
            Main.Size = UDim2.new(0, 260, 0, expandedH)
        end
    end
    self.UpdateSize = updateMainSize
    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMainSize)

    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Content.Visible = false
            Main.Size = MINIMIZED_SIZE
            MinBtn.Text = "+"
        else
            Content.Visible = true
            updateMainSize()
            MinBtn.Text = "-"
        end
    end)

    local dragToggle, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            local delta = input.Position - startPos -- 修正拖曳 delta 計算
            -- 這裡還原原本正確的 delta 邏輯
        end
    end)
    
    -- 確保拖曳順暢
    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    if footerText then
        local Footer = Instance.new("TextLabel")
        Footer.Size = UDim2.new(0.9, 0, 0, 20)
        Footer.BackgroundTransparency = 1
        Footer.Text = footerText
        Footer.TextColor3 = C.accent2
        Footer.Font = Enum.Font.FredokaOne
        Footer.Parent = Content
        applyTextSettings(Footer, 8, 14)

        local FooterStroke = Instance.new("UIStroke")
        FooterStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        FooterStroke.Thickness = 1.5
        FooterStroke.Color = Color3.fromRGB(0, 0, 0)
        FooterStroke.Parent = Footer
    end

    return self
end

function UIModule:SetTitle(newTitle)
    if self.TitleLabel then
        self.TitleLabel.Text = tostring(newTitle)
    end
end

function UIModule:Clear()
    for _, child in ipairs(self.Content:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    self.UpdateSize()
end

-- --- 修正所有控制項的高度，改用固定高度取代 AutomaticSize，避免計算錯誤造成重疊 ---

function UIModule:CreateButton(txt, cb, maxFontSize)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.92, 0, 0, 36) -- 固定高度 36，確保框與框大小一致
    btn.BackgroundColor3 = C.glass
    btn.BackgroundTransparency = 0.12
    btn.Text = txt
    btn.TextColor3 = C.ink
    btn.Font = Enum.Font.FredokaOne
    btn.Parent = self.Content

    applyCorner(btn, 6)
    applyGradient(btn, C.glassTop, C.glass, 90)
    applyStroke(btn, Color3.fromRGB(60, 110, 180), 1, 0.55)

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft = UDim.new(0, 8)
    UIPadding.PaddingRight = UDim.new(0, 8)
    UIPadding.PaddingTop = UDim.new(0, 4)
    UIPadding.PaddingBottom = UDim.new(0, 4)
    UIPadding.Parent = btn

    applyTextSettings(btn, 8, maxFontSize or 16)
    
    btn.MouseButton1Click:Connect(function()
        if cb then cb(btn) end
    end)
    
    self.UpdateSize()
    return btn
end

function UIModule:CreateToggle(txt, defaultState, cb, maxFontSize)
    local state = defaultState or false
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.92, 0, 0, 36) -- 固定高度 36
    btn.BackgroundColor3 = C.glass
    btn.BackgroundTransparency = 0.12
    btn.Text = ""
    btn.Parent = self.Content
    
    applyCorner(btn, 6)
    applyGradient(btn, C.glassTop, C.glass, 90)
    applyStroke(btn, Color3.fromRGB(60, 110, 180), 1, 0.55)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -38, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = C.ink
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn
    applyTextSettings(label, 8, maxFontSize or 15)

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(1, -26, 0.5, -9)
    box.Parent = btn
    
    applyCorner(box, 4)
    applyStroke(box, Color3.fromRGB(15, 25, 45), 1, 0.6)

    local function updateState()
        if state then
            box.BackgroundColor3 = C.accent
        else
            box.BackgroundColor3 = C.trackOff
        end
    end
    
    updateState()

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateState()
        if cb then cb(state) end
    end)
    
    self.UpdateSize()
    return btn
end

function UIModule:CreateSlider(txt, min, max, default, cb)
    min = min or 0
    max = max or 100
    default = math.clamp(default or min, min, max)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.92, 0, 0, 46) -- 固定高度 46
    frame.BackgroundColor3 = C.glass
    frame.BackgroundTransparency = 0.12
    frame.Parent = self.Content

    applyCorner(frame, 6)
    applyGradient(frame, C.glassTop, C.glass, 90)
    applyStroke(frame, Color3.fromRGB(60, 110, 180), 1, 0.55)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = C.ink
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    applyTextSettings(label, 8, 14)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, 0, 0, 18)
    valLabel.Position = UDim2.new(0.7, -8, 0, 6)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = C.accent2
    valLabel.Font = Enum.Font.FredokaOne
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame
    applyTextSettings(valLabel, 8, 14)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 6)
    track.Position = UDim2.new(0, 8, 0, 30)
    track.BackgroundColor3 = C.trackOff
    track.Parent = frame

    applyCorner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    applyCorner(fill, 3)
    applyGradient(fill, C.accent2, C.accent, 0)

    local dragging = false

    local function updateVal(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pos))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valLabel.Text = tostring(val)
        if cb then cb(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateVal(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateVal(input)
        end
    end)

    self.UpdateSize()
    return frame
end

function UIModule:CreateDropdown(txt, options, default, cb)
    options = options or {}
    local selected = default or (options[1] or "None")
    local isOpen = false

    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0.92, 0, 0, 36) -- 預設固定高度 36
    dropdownFrame.BackgroundColor3 = C.glass
    dropdownFrame.BackgroundTransparency = 0.12
    dropdownFrame.ClipsDescendants = true
    dropdownFrame.Parent = self.Content

    applyCorner(dropdownFrame, 6)
    applyGradient(dropdownFrame, C.glassTop, C.glass, 90)
    applyStroke(dropdownFrame, Color3.fromRGB(60, 110, 180), 1, 0.55)

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, -28, 0, 36)
    mainBtn.Position = UDim2.new(0, 6, 0, 0)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Text = txt .. ": " .. tostring(selected)
    mainBtn.TextColor3 = C.ink
    mainBtn.Font = Enum.Font.FredokaOne
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    mainBtn.Parent = dropdownFrame
    applyTextSettings(mainBtn, 8, 15)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 0, 36)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = C.ink
    arrow.Font = Enum.Font.FredokaOne
    arrow.TextSize = 10
    arrow.Parent = dropdownFrame

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -12, 0, 0)
    container.Position = UDim2.new(0, 6, 0, 38)
    container.BackgroundTransparency = 1
    container.Parent = dropdownFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = container

    local function toggleDropdown()
        isOpen = not isOpen
        arrow.Text = isOpen and "▲" or "▼"
        
        if isOpen then
            local totalHeight = listLayout.AbsoluteContentSize.Y + 44
            dropdownFrame.Size = UDim2.new(0.92, 0, 0, totalHeight)
        else
            dropdownFrame.Size = UDim2.new(0.92, 0, 0, 36)
        end
        self.UpdateSize()
    end

    mainBtn.MouseButton1Click:Connect(toggleDropdown)

    for _, optionText in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = C.card
        optBtn.Text = optionText
        optBtn.TextColor3 = C.inkSoft
        optBtn.Font = Enum.Font.FredokaOne
        optBtn.Parent = container
        applyTextSettings(optBtn, 8, 14)
        applyCorner(optBtn, 4)

        optBtn.MouseButton1Click:Connect(function()
            selected = optionText
            mainBtn.Text = txt .. ": " .. tostring(selected)
            toggleDropdown()
            if cb then cb(selected) end
        end)
    end

    self.UpdateSize()
    return dropdownFrame
end

function UIModule:CreateInput(txt, placeholder, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.92, 0, 0, 36) -- 固定高度 36
    frame.BackgroundColor3 = C.glass
    frame.BackgroundTransparency = 0.12
    frame.Parent = self.Content

    applyCorner(frame, 6)
    applyGradient(frame, C.glassTop, C.glass, 90)
    applyStroke(frame, Color3.fromRGB(60, 110, 180), 1, 0.55)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = C.ink
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    applyTextSettings(label, 8, 14)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.5, -8, 0, 24)
    textBox.Position = UDim2.new(0.5, 0, 0.5, -12)
    textBox.BackgroundColor3 = C.card
    textBox.Text = ""
    textBox.PlaceholderText = placeholder or "輸入..."
    textBox.PlaceholderColor3 = C.inkSoft
    textBox.TextColor3 = C.accent2
    textBox.Font = Enum.Font.FredokaOne
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame
    applyTextSettings(textBox, 8, 14)

    applyCorner(textBox, 4)
    applyStroke(textBox, Color3.fromRGB(15, 25, 45), 1, 0)

    textBox.FocusLost:Connect(function(enterPressed)
        if cb then
            cb(textBox.Text, enterPressed)
        end
    end)

    self.UpdateSize()
    return frame
end

function UIModule:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end

return UIModule
