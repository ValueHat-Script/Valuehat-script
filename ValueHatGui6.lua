-- --- 1. 建立 UI 主視窗 (:CreateWindow) ---
function UIModule.CreateWindow(titleText, footerText)
	local self = setmetatable({}, UIModule)

	local ApexHub = Instance.new("ScreenGui")
	ApexHub.Name = GUI_NAME
	ApexHub.Parent = CoreGui
	ApexHub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ApexHub.IgnoreGuiInset = true
	self.Gui = ApexHub

	-- ★ 陰影光暈 (真正的外光暈)
	local Shadow = Instance.new("ImageLabel")
	Shadow.Name = "Shadow"
	Shadow.BackgroundTransparency = 1
	Shadow.Image = "rbxassetid://6014261993"          -- 常用的柔和陰影圖
	Shadow.ImageColor3 = Color3.fromRGB(0, 140, 255)  -- 光暈顏色（藍色）
	Shadow.ImageTransparency = 0.45                   -- 透明度（越小越亮）
	Shadow.ScaleType = Enum.ScaleType.Slice
	Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	Shadow.ZIndex = 1
	Shadow.Parent = ApexHub

	-- 主面板
	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Parent = ApexHub
	Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	Main.BorderSizePixel = 0
	Main.Position = UDim2.new(0.5, -130, 0.5, -200)
	Main.Size = UDim2.new(0, 260, 0, 100)
	Main.Active = true
	Main.ZIndex = 2
	Main.ClipsDescendants = true

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 12)
	UICorner.Parent = Main

	-- 同步陰影位置與大小
	local function syncShadow()
		local p, s = Main.Position, Main.Size
		Shadow.Position = UDim2.new(p.X.Scale, p.X.Offset - 22, p.Y.Scale, p.Y.Offset - 18)
		Shadow.Size     = UDim2.new(s.X.Scale, s.X.Offset + 44, s.Y.Scale, s.Y.Offset + 46)
	end
	Main:GetPropertyChangedSignal("Position"):Connect(syncShadow)
	Main:GetPropertyChangedSignal("Size"):Connect(syncShadow)
	syncShadow()

	-- 內層邊框（可選，讓邊緣更清楚）
	local UIStroke = Instance.new("UIStroke")
	UIStroke.Name = "Border"
	UIStroke.Thickness = 1.5
	UIStroke.Color = Color3.fromRGB(0, 140, 255)
	UIStroke.Transparency = 0.3
	UIStroke.Parent = Main

	-- 標題文字
	local Title = Instance.new("TextLabel")
	Title.Parent = Main
	Title.Size = UDim2.new(1, -45, 0, 36)
	Title.Position = UDim2.new(0, 12, 0, 2)
	Title.Text = titleText or "MY HUB"
	Title.TextColor3 = Color3.fromRGB(255, 220, 50)
	Title.Font = Enum.Font.FredokaOne
	Title.BackgroundTransparency = 1
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.ZIndex = 3
	applyTextSettings(Title, 10, 20)

	self.TitleLabel = Title

	local TitleStroke = Instance.new("UIStroke")
	TitleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	TitleStroke.Thickness = 2.5
	TitleStroke.Color = Color3.fromRGB(0, 0, 0)
	TitleStroke.Parent = Title

	-- 標題分隔線
	local Separator = Instance.new("Frame")
	Separator.Name = "Separator"
	Separator.Size = UDim2.new(1, -24, 0, 1)
	Separator.Position = UDim2.new(0, 12, 0, 40)
	Separator.BackgroundColor3 = Color3.fromRGB(0, 100, 220)
	Separator.BorderSizePixel = 0
	Separator.ZIndex = 3
	Separator.Parent = Main

	local SeparatorGradient = Instance.new("UIGradient")
	SeparatorGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.7)
	}
	SeparatorGradient.Parent = Separator

	-- 內容容器
	local Content = Instance.new("ScrollingFrame")
	Content.Parent = Main
	Content.Position = UDim2.new(0, 12, 0, 48)
	Content.Size = UDim2.new(1, -24, 0, 0)
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel = 0
	Content.ScrollBarThickness = 0
	Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Content.CanvasSize = UDim2.new(0, 0, 0, 0)
	Content.ZIndex = 3
	self.Content = Content

	local UIList = Instance.new("UIListLayout")
	UIList.Parent = Content
	UIList.Padding = UDim.new(0, 8)
	UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	self.UIList = UIList

	-- 右上角縮小按鈕
	local isMinimized = false
	local MINIMIZED_SIZE = UDim2.new(0, 260, 0, 44)

	local MinBtn = Instance.new("TextButton")
	MinBtn.Size = UDim2.new(0, 22, 0, 22)
	MinBtn.Position = UDim2.new(1, -30, 0, 10)
	MinBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	MinBtn.Text = "-"
	MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	MinBtn.Font = Enum.Font.FredokaOne
	MinBtn.TextSize = 16
	MinBtn.ZIndex = 4
	MinBtn.Parent = Main

	local MinBtnCorner = Instance.new("UICorner")
	MinBtnCorner.CornerRadius = UDim.new(0, 6)
	MinBtnCorner.Parent = MinBtn

	local MinBtnStroke = Instance.new("UIStroke")
	MinBtnStroke.Thickness = 1.5
	MinBtnStroke.Color = Color3.fromRGB(0, 0, 0)
	MinBtnStroke.Parent = MinBtn

	addHoverEffect(MinBtn, Color3.fromRGB(25, 25, 35), Color3.fromRGB(40, 40, 55))

	-- 自動調整高度
	local TITLE_PADDING = 56
	local MAX_HEIGHT = 350

	local function updateMainSize()
		if not isMinimized then
			local contentHeight = UIList.AbsoluteContentSize.Y
			local targetContentHeight = math.min(contentHeight, MAX_HEIGHT)

			Content.Size = UDim2.new(1, -24, 0, targetContentHeight)
			Main.Size = UDim2.new(0, 260, 0, targetContentHeight + TITLE_PADDING)
		end
	end
	self.UpdateSize = updateMainSize
	UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMainSize)

	-- 縮小功能
	MinBtn.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			Content.Visible = false
			Separator.Visible = false
			Main.Size = MINIMIZED_SIZE
			MinBtn.Text = "+"
		else
			Content.Visible = true
			Separator.Visible = true
			updateMainSize()
			MinBtn.Text = "-"
		end
	end)

	-- 拖曳邏輯
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
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- 頁尾標籤
	if footerText then
		local Footer = Instance.new("TextLabel")
		Footer.Size = UDim2.new(0.9, 0, 0, 20)
		Footer.BackgroundTransparency = 1
		Footer.Text = footerText
		Footer.TextColor3 = Color3.fromRGB(0, 255, 200)
		Footer.Font = Enum.Font.FredokaOne
		Footer.ZIndex = 3
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
