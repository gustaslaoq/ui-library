local SlaoqUILib = {}
SlaoqUILib.__index = SlaoqUILib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local function fromHex(h)
	h = h:gsub("#", "")
	return Color3.new(
		tonumber(h:sub(1,2), 16) / 255,
		tonumber(h:sub(3,4), 16) / 255,
		tonumber(h:sub(5,6), 16) / 255
	)
end

local function Create(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function Tween(obj, time, props, es, ed)
	if not obj then return end
	local t = TweenService:Create(obj,
		TweenInfo.new(time or 0.18, es or Enum.EasingStyle.Quint, ed or Enum.EasingDirection.Out),
		props)
	t:Play()
	return t
end

local function Stroke(parent, color, thick, trans)
	return Create("UIStroke", {
		Color        = color,
		Thickness    = thick or 1,
		Transparency = trans or 0,
		Parent       = parent,
	})
end

local function Corner(parent, r)
	return Create("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function Pad(parent, t, b, l, r)
	return Create("UIPadding", {
		PaddingTop    = UDim.new(0, t or 8),
		PaddingBottom = UDim.new(0, b or 8),
		PaddingLeft   = UDim.new(0, l or 10),
		PaddingRight  = UDim.new(0, r or 10),
		Parent        = parent,
	})
end

local function Gap(parent, order, h)
	return Create("Frame", {
		Size                   = UDim2.fromOffset(1, h or 8),
		BackgroundTransparency = 1,
		LayoutOrder            = order,
		Parent                 = parent,
	})
end

local DefaultColors = {
	Bg      = fromHex("000000"),
	Surface = fromHex("080808"),
	Card    = fromHex("101010"),
	Card2   = fromHex("0c0c0c"),
	Border  = fromHex("1c1c1c"),
	Border2 = fromHex("252525"),
	Text    = fromHex("d8d8d8"),
	Muted   = fromHex("999999"),
	Dim     = fromHex("666666"),
	White   = fromHex("ffffff"),
	Green   = fromHex("00ff88"),
	Green2  = fromHex("00cc66"),
	Red     = fromHex("c0392b"),
	Red2    = fromHex("e74c3c"),
	Yellow  = fromHex("ffcc00"),
	Orange  = fromHex("ff8800"),
	Purple  = fromHex("aa66ff"),
	Primary = fromHex("ffffff"),
}

local DefaultConfig = {
	AppName          = "MY APP",
	AppSubtitle      = "Subtitle",
	AppVersion       = "1.0",
	LogoImage        = "",
	GuiParent        = "CoreGui",
	WindowWidth      = 820,
	WindowHeight     = 540,
	SidebarWidth     = 180,
	Pages            = {
		{ Icon = "", Name = "Dashboard" },
		{ Icon = "", Name = "Settings"  },
		{ Icon = "", Name = "Logs"      },
		{ Icon = "", Name = "History"   },
	},
	Font             = Enum.Font.GothamBold,
	FontRegular      = Enum.Font.Gotham,
	TweenSpeed       = 0.18,
	BarTweenSpeed    = 0.22,
	MobileBreakpoint = 600,
}

function SlaoqUILib.new(userConfig)
	local self    = setmetatable({}, SlaoqUILib)
	self.Config   = {}
	for k, v in pairs(DefaultConfig) do self.Config[k] = v end
	self.Config.Colors = {}
	for k, v in pairs(DefaultColors) do self.Config.Colors[k] = v end

	if userConfig then
		for k, v in pairs(userConfig) do
			if k == "Colors" and type(v) == "table" then
				for ck, cv in pairs(v) do self.Config.Colors[ck] = cv end
			elseif k == "Pages" then
				self.Config.Pages = v
			else
				self.Config[k] = v
			end
		end
	end

	local C   = self.Config.Colors
	local cfg = self.Config

	self._pages      = {}
	self._pageIndex  = 1
	self._navBtns    = {}
	self._conns      = {}
	self._orderCnt   = {}

	local guiParent
	if cfg.GuiParent == "PlayerGui" then
		guiParent = LocalPlayer:WaitForChild("PlayerGui")
	else
		guiParent = CoreGui
	end

	local screenGui = Create("ScreenGui", {
		Name           = cfg.AppName .. "_UI",
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder   = 999,
		Parent         = guiParent,
	})
	pcall(function() screenGui.IgnoreGuiInset = true end)
	self.ScreenGui = screenGui

	local win = Create("Frame", {
		Name             = "Window",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(0.5, 0.5),
		Size             = UDim2.fromOffset(cfg.WindowWidth, cfg.WindowHeight),
		BackgroundColor3 = C.Bg,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		Parent           = screenGui,
	})
	Corner(win, 12)
	Stroke(win, C.Border2, 1)
	self.Window = win

	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp       = cam.ViewportSize
		local isMobile = vp.X < cfg.MobileBreakpoint or UserInputService.TouchEnabled
		local s        = math.min(math.clamp(vp.X/1920, 0.42, 1), math.clamp(vp.Y/1080, 0.42, 1))
		local w, h
		if isMobile then
			w = math.floor(vp.X * 0.97)
			h = math.floor(vp.Y * 0.94)
		else
			w = math.floor(cfg.WindowWidth  * s)
			h = math.floor(cfg.WindowHeight * s)
		end
		win.Size = UDim2.fromOffset(w, h)
		if self._sidebar then
			local sw = (isMobile or s < 0.6) and 46 or math.floor(cfg.SidebarWidth * s)
			self._sidebar.Size = UDim2.new(0, sw, 1, 0)
			self:_collapseLabels(sw < 80)
		end
	end

	table.insert(self._conns,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

	local titleBar = Create("Frame", {
		Name             = "TitleBar",
		Size             = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = C.Bg,
		BorderSizePixel  = 0,
		ZIndex           = 10,
		Parent           = win,
	})
	Create("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = C.Border,
		BorderSizePixel  = 0,
		ZIndex           = 10,
		Parent           = titleBar,
	})
	self.TitleBar = titleBar

	Create("TextLabel", {
		Text                   = cfg.AppName,
		Font                   = cfg.Font,
		TextSize               = 11,
		TextColor3             = C.White,
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(12, 6),
		Size                   = UDim2.new(0.7, 0, 0, 14),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 11,
		Parent                 = titleBar,
	})
	Create("TextLabel", {
		Text                   = "v" .. cfg.AppVersion,
		Font                   = cfg.FontRegular,
		TextSize               = 9,
		TextColor3             = C.Dim,
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(12, 21),
		Size                   = UDim2.new(0.7, 0, 0, 12),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 11,
		Parent                 = titleBar,
	})

	local minBtn = Create("TextButton", {
		Text                   = "-",
		Font                   = cfg.FontRegular,
		TextSize               = 18,
		TextColor3             = C.Muted,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -40, 0.5, 0),
		Size                   = UDim2.fromOffset(36, 36),
		ZIndex                 = 11,
		AutoButtonColor        = false,
		Parent                 = titleBar,
	})
	minBtn.MouseEnter:Connect(function() Tween(minBtn, 0.12, {TextColor3 = C.White}) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn, 0.12, {TextColor3 = C.Muted}) end)
	minBtn.Activated:Connect(function() self:ToggleVisibility() end)
	self.MinButton = minBtn

	local closeBtn = Create("TextButton", {
		Text                   = "x",
		Font                   = cfg.Font,
		TextSize               = 12,
		TextColor3             = C.Muted,
		BackgroundTransparency = 1,
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -4, 0.5, 0),
		Size                   = UDim2.fromOffset(36, 36),
		ZIndex                 = 11,
		AutoButtonColor        = false,
		Parent                 = titleBar,
	})
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, 0.12, {TextColor3 = C.Red2}) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, 0.12, {TextColor3 = C.Muted}) end)
	closeBtn.Activated:Connect(function() self:Destroy() end)
	self.CloseButton = closeBtn

	do
		local dragging, dragStart, winStart = false, nil, nil
		titleBar.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
			or inp.UserInputType == Enum.UserInputType.Touch then
				dragging  = true
				dragStart = inp.Position
				winStart  = win.Position
			end
		end)
		titleBar.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
			or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		table.insert(self._conns, UserInputService.InputChanged:Connect(function(inp)
			if not dragging then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseMovement
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = inp.Position - dragStart
			win.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + d.X, winStart.Y.Scale, winStart.Y.Offset + d.Y)
		end))
	end

	local body = Create("Frame", {
		Name                   = "Body",
		Position               = UDim2.fromOffset(0, 36),
		Size                   = UDim2.new(1, 0, 1, -36),
		BackgroundTransparency = 1,
		Parent                 = win,
	})
	self.Body = body

	local sidebar = Create("Frame", {
		Name             = "Sidebar",
		Size             = UDim2.new(0, cfg.SidebarWidth, 1, 0),
		BackgroundColor3 = C.Bg,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 5,
		Parent           = body,
	})
	Create("Frame", {
		Size             = UDim2.new(0, 1, 1, 0),
		Position         = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = C.Border,
		BorderSizePixel  = 0,
		ZIndex           = 6,
		Parent           = sidebar,
	})
	self._sidebar = sidebar

	local sideScroll = Create("ScrollingFrame", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness     = 0,
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		Parent                 = sidebar,
	})
	Create("UIListLayout", {
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Padding             = UDim.new(0, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent              = sideScroll,
	})
	Pad(sideScroll, 12, 12, 6, 6)

	local logoFrame = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 82),
		BackgroundTransparency = 1,
		LayoutOrder            = 0,
		Parent                 = sideScroll,
	})
	local logoImg = Create("ImageLabel", {
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, 0, 0, 4),
		Size                   = UDim2.fromOffset(44, 44),
		BackgroundColor3       = fromHex("000000"),
		BackgroundTransparency = cfg.LogoImage ~= "" and 1 or 0,
		Image                  = cfg.LogoImage,
		Parent                 = logoFrame,
	})
	Corner(logoImg, 22)
	if cfg.LogoImage == "" then
		Stroke(logoImg, C.Border2, 1.5)
		Create("TextLabel", {
			Text                   = string.upper(string.sub(cfg.AppName, 1, 1)),
			Font                   = cfg.Font,
			TextSize               = 20,
			TextColor3             = C.White,
			BackgroundTransparency = 1,
			Size                   = UDim2.fromScale(1, 1),
			Parent                 = logoImg,
		})
	end
	self.LogoImage = logoImg

	local sideNameLbl = Create("TextLabel", {
		Text                   = cfg.AppName,
		Font                   = cfg.Font,
		TextSize               = 10,
		TextColor3             = C.White,
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 0, 0, 52),
		Size                   = UDim2.new(1, 0, 0, 14),
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 6,
		Parent                 = logoFrame,
	})
	local sideSubLbl = Create("TextLabel", {
		Text                   = cfg.AppSubtitle,
		Font                   = cfg.FontRegular,
		TextSize               = 9,
		TextColor3             = C.Muted,
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 0, 0, 67),
		Size                   = UDim2.new(1, 0, 0, 12),
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 6,
		Parent                 = logoFrame,
	})
	self._sideNameLbl = sideNameLbl
	self._sideSubLbl  = sideSubLbl

	Create("Frame", {
		Size             = UDim2.new(0.85, 0, 0, 1),
		BackgroundColor3 = C.Border,
		BorderSizePixel  = 0,
		LayoutOrder      = 1,
		Parent           = sideScroll,
	})
	Gap(sideScroll, 2, 8)

	local barIndicator = Create("Frame", {
		Size             = UDim2.fromOffset(3, 28),
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.fromOffset(2, 0),
		BackgroundColor3 = C.White,
		BorderSizePixel  = 0,
		ZIndex           = 9,
		Visible          = false,
		Parent           = sidebar,
	})
	Corner(barIndicator, 3)
	self._bar = barIndicator

	for i, page in ipairs(cfg.Pages) do
		local btn = self:_makeNavBtn(page, i, sideScroll)
		table.insert(self._navBtns, btn)
	end
	Gap(sideScroll, #cfg.Pages + 10, 8)

	local contentArea = Create("Frame", {
		Name             = "Content",
		Position         = UDim2.new(0, cfg.SidebarWidth, 0, 0),
		Size             = UDim2.new(1, -cfg.SidebarWidth, 1, 0),
		BackgroundColor3 = C.Surface,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		Parent           = body,
	})
	self._content = contentArea

	table.insert(self._conns, sidebar:GetPropertyChangedSignal("Size"):Connect(function()
		local sw = sidebar.Size.X.Offset
		contentArea.Position = UDim2.new(0, sw, 0, 0)
		contentArea.Size     = UDim2.new(1, -sw, 1, 0)
	end))

	local notifFrame = Create("Frame", {
		AnchorPoint      = Vector2.new(0.5, 1),
		Position         = UDim2.new(0.5, 0, 1, 60),
		Size             = UDim2.fromOffset(320, 44),
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		ZIndex           = 100,
		Parent           = win,
	})
	Corner(notifFrame, 8)
	Stroke(notifFrame, C.Border2, 1)
	local notifText = Create("TextLabel", {
		Text                   = "",
		Font                   = cfg.FontRegular,
		TextSize               = 11,
		TextColor3             = C.Text,
		BackgroundTransparency = 1,
		Size                   = UDim2.fromScale(1, 1),
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextWrapped            = true,
		ZIndex                 = 101,
		Parent                 = notifFrame,
	})
	Pad(notifFrame, 6, 6, 12, 12)
	self._notifFrame = notifFrame
	self._notifText  = notifText

	self:_initPages()
	self:SetPage(1)
	updateScale()

	return self
end

function SlaoqUILib:_makeNavBtn(page, index, parent)
	local C   = self.Config.Colors
	local cfg = self.Config

	local frame = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder            = index + 2,
		Parent                 = parent,
	})
	local hoverBg = Create("Frame", {
		Size                   = UDim2.new(1, -8, 1, -4),
		Position               = UDim2.fromOffset(4, 2),
		BackgroundColor3       = C.White,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ZIndex                 = 5,
		Parent                 = frame,
	})
	Corner(hoverBg, 6)

	local hasIcon = page.Icon and page.Icon ~= ""
	if hasIcon then
		Create("ImageLabel", {
			Size                   = UDim2.fromOffset(16, 16),
			Position               = UDim2.fromOffset(10, 9),
			BackgroundTransparency = 1,
			Image                  = page.Icon,
			ZIndex                 = 6,
			Parent                 = frame,
		})
	else
		local dot = Create("Frame", {
			Size             = UDim2.fromOffset(5, 5),
			Position         = UDim2.fromOffset(13, 15),
			BackgroundColor3 = C.Dim,
			BorderSizePixel  = 0,
			ZIndex           = 6,
			Parent           = frame,
		})
		Corner(dot, 3)
	end

	local lx  = hasIcon and 32 or 26
	local lbl = Create("TextLabel", {
		Text                   = page.Name,
		Font                   = cfg.Font,
		TextSize               = 11,
		TextColor3             = C.Muted,
		BackgroundTransparency = 1,
		Position               = UDim2.fromOffset(lx, 0),
		Size                   = UDim2.new(1, -(lx + 8), 1, 0),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 6,
		Parent                 = frame,
	})

	local click = Create("TextButton", {
		Text                   = "",
		BackgroundTransparency = 1,
		Size                   = UDim2.fromScale(1, 1),
		ZIndex                 = 7,
		AutoButtonColor        = false,
		Parent                 = frame,
	})
	click.MouseEnter:Connect(function()
		if self._pageIndex ~= index then
			Tween(hoverBg, 0.12, {BackgroundTransparency = 0.95})
			Tween(lbl,     0.12, {TextColor3 = C.Text})
		end
	end)
	click.MouseLeave:Connect(function()
		if self._pageIndex ~= index then
			Tween(hoverBg, 0.12, {BackgroundTransparency = 1})
			Tween(lbl,     0.12, {TextColor3 = C.Muted})
		end
	end)
	click.Activated:Connect(function() self:SetPage(index) end)

	return {Frame = frame, HoverBg = hoverBg, Lbl = lbl}
end

function SlaoqUILib:_initPages()
	local C = self.Config.Colors
	for i = 1, #self.Config.Pages do
		local frame = Create("Frame", {
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible                = false,
			Parent                 = self._content,
		})
		local scroll = Create("ScrollingFrame", {
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScrollBarThickness     = 3,
			ScrollBarImageColor3   = C.Border2,
			CanvasSize             = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize    = Enum.AutomaticSize.Y,
			Parent                 = frame,
		})
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 0),
			Parent    = scroll,
		})
		Pad(scroll, 20, 20, 22, 22)
		self._pages[i]    = {Frame = frame, Scroll = scroll}
		self._orderCnt[i] = 100
	end
end

function SlaoqUILib:SetPage(index)
	local cfg = self.Config
	local C   = cfg.Colors
	if self._pages[self._pageIndex] then
		self._pages[self._pageIndex].Frame.Visible = false
	end
	local old = self._navBtns[self._pageIndex]
	if old then
		Tween(old.Lbl,     cfg.TweenSpeed, {TextColor3 = C.Muted})
		Tween(old.HoverBg, cfg.TweenSpeed, {BackgroundTransparency = 1})
	end
	self._pageIndex = index
	if self._pages[index] then
		self._pages[index].Frame.Visible = true
	end
	local nb = self._navBtns[index]
	if nb then
		Tween(nb.Lbl,     cfg.TweenSpeed, {TextColor3 = C.White})
		Tween(nb.HoverBg, cfg.TweenSpeed, {BackgroundTransparency = 0.93})
		self:_animateBar(nb.Frame)
	end
end

function SlaoqUILib:_animateBar(targetFrame)
	local bar = self._bar
	if not bar or not targetFrame then return end
	local ok, relY = pcall(function()
		return targetFrame.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + targetFrame.AbsoluteSize.Y * 0.5
	end)
	if not ok then return end
	bar.Visible = true
	local cfg = self.Config
	local t1 = Tween(bar, cfg.BarTweenSpeed * 0.45, {Size = UDim2.fromOffset(3, 0)},
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	if t1 then
		t1.Completed:Connect(function()
			bar.Position = UDim2.new(0, 2, 0, relY)
			Tween(bar, cfg.BarTweenSpeed * 0.6, {Size = UDim2.fromOffset(3, 28)},
				Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end
end

function SlaoqUILib:_collapseLabels(collapsed)
	if self._sideNameLbl then self._sideNameLbl.Visible = not collapsed end
	if self._sideSubLbl  then self._sideSubLbl.Visible  = not collapsed end
	for _, nb in ipairs(self._navBtns) do
		if nb.Lbl then nb.Lbl.Visible = not collapsed end
	end
end

function SlaoqUILib:_nextOrder(pi)
	self._orderCnt[pi] = (self._orderCnt[pi] or 100) + 1
	return self._orderCnt[pi]
end

function SlaoqUILib:GetPage(index)
	return self._pages[index] and self._pages[index].Scroll or nil
end

function SlaoqUILib:GetRawPage(index)
	return self._pages[index] and self._pages[index].Frame or nil
end

function SlaoqUILib:AddSectionHeader(pi, title, subtitle)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local frame = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, subtitle and 46 or 28),
		BackgroundTransparency = 1,
		LayoutOrder            = self:_nextOrder(pi),
		Parent                 = scroll,
	})
	Create("TextLabel", {
		Text                   = title,
		Font                   = cfg.Font,
		TextSize               = 18,
		TextColor3             = C.White,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 22),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})
	if subtitle then
		Create("TextLabel", {
			Text                   = subtitle,
			Font                   = cfg.FontRegular,
			TextSize               = 11,
			TextColor3             = C.Muted,
			BackgroundTransparency = 1,
			Position               = UDim2.fromOffset(0, 24),
			Size                   = UDim2.new(1, 0, 0, 16),
			TextXAlignment         = Enum.TextXAlignment.Left,
			Parent                 = frame,
		})
	end
	Create("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.Border,
		BorderSizePixel  = 0,
		LayoutOrder      = self:_nextOrder(pi),
		Parent           = scroll,
	})
	Gap(scroll, self:_nextOrder(pi), 10)
end

function SlaoqUILib:AddMetricRow(pi, cards)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local row = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 74),
		BackgroundTransparency = 1,
		LayoutOrder            = self:_nextOrder(pi),
		Parent                 = scroll,
	})
	Create("UIGridLayout", {
		CellSize              = UDim2.new(1/#cards, -6, 1, 0),
		CellPaddingHorizontal = UDim.new(0, 6),
		SortOrder             = Enum.SortOrder.LayoutOrder,
		Parent                = row,
	})
	local objects = {}
	for i, card in ipairs(cards) do
		local f = Create("Frame", {
			BackgroundColor3 = C.Card,
			BorderSizePixel  = 0,
			ZIndex           = 2,
			LayoutOrder      = i,
			Parent           = row,
		})
		Corner(f, 10)
		Stroke(f, C.Border, 1)
		Pad(f, 10, 10, 14, 10)
		Create("TextLabel", {
			Text                   = card.Label or "",
			Font                   = cfg.Font,
			TextSize               = 9,
			TextColor3             = C.Muted,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 13),
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 3,
			Parent                 = f,
		})
		local valLbl = Create("TextLabel", {
			Text                   = card.Value or "---",
			Font                   = cfg.Font,
			TextSize               = 20,
			TextColor3             = C.White,
			BackgroundTransparency = 1,
			Position               = UDim2.fromOffset(0, 14),
			Size                   = UDim2.new(1, 0, 0, 26),
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 3,
			Parent                 = f,
		})
		if card.Unit and card.Unit ~= "" then
			Create("TextLabel", {
				Text                   = card.Unit,
				Font                   = cfg.FontRegular,
				TextSize               = 9,
				TextColor3             = C.Dim,
				BackgroundTransparency = 1,
				Position               = UDim2.fromOffset(0, 42),
				Size                   = UDim2.new(1, 0, 0, 12),
				TextXAlignment         = Enum.TextXAlignment.Left,
				ZIndex                 = 3,
				Parent                 = f,
			})
		end
		local ib = Create("TextButton", {
			Text = "", BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), ZIndex = 4,
			AutoButtonColor = false, Parent = f,
		})
		ib.MouseEnter:Connect(function() Tween(f, 0.12, {BackgroundColor3 = C.Card2}) end)
		ib.MouseLeave:Connect(function() Tween(f, 0.12, {BackgroundColor3 = C.Card})  end)
		objects[i] = {Frame = f, ValueLabel = valLbl}
	end
	Gap(scroll, self:_nextOrder(pi), 10)
	return objects
end

function SlaoqUILib:SetMetricValue(cardObj, value)
	if cardObj and cardObj.ValueLabel then
		cardObj.ValueLabel.Text = tostring(value)
	end
end

function SlaoqUILib:CreateStatusBadge(parent, state)
	local C, cfg = self.Config.Colors, self.Config
	local sp = {
		on   = {text="ON",   bg=Color3.fromRGB(0,204,102),  bgA=0.90, tc=C.Green2, bdr=Color3.fromRGB(0,204,102)},
		off  = {text="OFF",  bg=Color3.fromRGB(230,50,50),  bgA=0.90, tc=C.Red2,   bdr=Color3.fromRGB(230,50,50)},
		idle = {text="IDLE", bg=Color3.fromRGB(220,180,0),  bgA=0.93, tc=C.Yellow, bdr=Color3.fromRGB(220,180,0)},
	}
	local s = sp[state or "idle"]
	local frame = Create("Frame", {
		Size                   = UDim2.fromOffset(52, 20),
		BackgroundColor3       = s.bg,
		BackgroundTransparency = s.bgA,
		BorderSizePixel        = 0,
		Parent                 = parent,
	})
	Corner(frame, 9)
	Stroke(frame, s.bdr, 1, 0.75)
	local lbl = Create("TextLabel", {
		Text                   = s.text,
		Font                   = cfg.Font,
		TextSize               = 9,
		TextColor3             = s.tc,
		BackgroundTransparency = 1,
		Size                   = UDim2.fromScale(1, 1),
		ZIndex                 = 2,
		Parent                 = frame,
	})
	local badge = {Frame=frame, Label=lbl, _sp=sp}
	function badge:SetState(ns)
		local p = self._sp[ns]; if not p then return end
		Tween(self.Frame, 0.15, {BackgroundColor3=p.bg, BackgroundTransparency=p.bgA})
		self.Label.Text = p.text; self.Label.TextColor3 = p.tc
	end
	return badge
end

function SlaoqUILib:AddButtonRow(pi, defs)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local row = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		LayoutOrder            = self:_nextOrder(pi),
		Parent                 = scroll,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder     = Enum.SortOrder.LayoutOrder,
		Padding       = UDim.new(0, 8),
		Parent        = row,
	})
	local styles = {
		primary = {bg=C.White,  tc=C.Bg,    hov=Color3.fromRGB(210,210,210)},
		danger  = {bg=C.Red,    tc=C.White, hov=C.Red2},
		warning = {bg=C.Yellow, tc=C.Bg,    hov=C.Orange},
		ghost   = {bg=C.Card,   tc=C.Text,  hov=C.Card2},
	}
	local btns = {}
	for i, def in ipairs(defs) do
		local s = styles[def.Style or "primary"]
		local btn = Create("TextButton", {
			Text             = def.Text or "",
			Font             = cfg.Font,
			TextSize         = 12,
			TextColor3       = s.tc,
			BackgroundColor3 = s.bg,
			BorderSizePixel  = 0,
			Size             = UDim2.fromOffset(def.Width or 130, 38),
			AutoButtonColor  = false,
			LayoutOrder      = i,
			Parent           = row,
		})
		Corner(btn, 8)
		btn.MouseEnter:Connect(function() Tween(btn, 0.12, {BackgroundColor3=s.hov}) end)
		btn.MouseLeave:Connect(function() Tween(btn, 0.12, {BackgroundColor3=s.bg})  end)
		if def.Callback then btn.Activated:Connect(def.Callback) end
		btns[i] = btn
	end
	Gap(scroll, self:_nextOrder(pi), 10)
	return btns
end

function SlaoqUILib:AddButton(pi, text, style, callback)
	local btns = self:AddButtonRow(pi, {{Text=text, Style=style or "primary", Callback=callback}})
	return btns and btns[1]
end

function SlaoqUILib:AddToggle(pi, label, default, callback)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local row = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder            = self:_nextOrder(pi),
		Parent                 = scroll,
	})
	Create("TextLabel", {
		Text                   = label or "",
		Font                   = cfg.FontRegular,
		TextSize               = 12,
		TextColor3             = C.Text,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -60, 1, 0),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = row,
	})
	local state = default == true
	local track = Create("Frame", {
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, 0, 0.5, 0),
		Size             = UDim2.fromOffset(36, 20),
		BackgroundColor3 = state and C.White or C.Card,
		BorderSizePixel  = 0,
		Parent           = row,
	})
	Corner(track, 10)
	Stroke(track, C.Border2, 1)
	local knob = Create("Frame", {
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.new(0, state and 18 or 2, 0.5, 0),
		Size             = UDim2.fromOffset(16, 16),
		BackgroundColor3 = state and C.Bg or C.Muted,
		BorderSizePixel  = 0,
		Parent           = track,
	})
	Corner(knob, 8)
	local click = Create("TextButton", {
		Text="", BackgroundTransparency=1, Size=UDim2.fromScale(1,1),
		ZIndex=5, AutoButtonColor=false, Parent=track,
	})
	click.Activated:Connect(function()
		state = not state
		Tween(track, 0.15, {BackgroundColor3 = state and C.White or C.Card})
		Tween(knob,  0.15, {Position=UDim2.new(0, state and 18 or 2, 0.5, 0), BackgroundColor3=state and C.Bg or C.Muted})
		if callback then callback(state) end
	end)
	Gap(scroll, self:_nextOrder(pi), 6)
	local toggle = {Track=track, Knob=knob}
	function toggle:SetState(v)
		state = v
		Tween(self.Track, 0.15, {BackgroundColor3=v and C.White or C.Card})
		Tween(self.Knob,  0.15, {Position=UDim2.new(0, v and 18 or 2, 0.5, 0), BackgroundColor3=v and C.Bg or C.Muted})
	end
	function toggle:GetState() return state end
	return toggle
end

function SlaoqUILib:AddInput(pi, labelText, placeholder, callback)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	if labelText then
		Create("TextLabel", {
			Text                   = labelText,
			Font                   = cfg.FontRegular,
			TextSize               = 11,
			TextColor3             = C.Muted,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 16),
			TextXAlignment         = Enum.TextXAlignment.Left,
			LayoutOrder            = self:_nextOrder(pi),
			Parent                 = scroll,
		})
	end
	local box = Create("TextBox", {
		Text              = "",
		PlaceholderText   = placeholder or "",
		Font              = cfg.FontRegular,
		TextSize          = 12,
		TextColor3        = C.Text,
		PlaceholderColor3 = C.Dim,
		BackgroundColor3  = C.Card,
		BorderSizePixel   = 0,
		Size              = UDim2.new(1, 0, 0, 36),
		ClearTextOnFocus  = false,
		LayoutOrder       = self:_nextOrder(pi),
		Parent            = scroll,
	})
	Corner(box, 6)
	Stroke(box, C.Border2, 1)
	Pad(box, 0, 0, 12, 12)
	box.Focused:Connect(function()    Tween(box, 0.12, {BackgroundColor3=C.Card2}) end)
	box.FocusLost:Connect(function(e) Tween(box, 0.12, {BackgroundColor3=C.Card}); if callback then callback(box.Text, e) end end)
	Gap(scroll, self:_nextOrder(pi), 8)
	return box
end

function SlaoqUILib:AddCard(pi, title)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local card = Create("Frame", {
		Size          = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		LayoutOrder   = self:_nextOrder(pi),
		Parent        = scroll,
	})
	Corner(card, 10)
	Stroke(card, C.Border, 1)
	local inner = Create("Frame", {
		Size          = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent        = card,
	})
	Pad(inner, 14, 14, 16, 16)
	Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8), Parent=inner})
	if title then
		Create("TextLabel", {
			Text                   = string.upper(title),
			Font                   = cfg.Font,
			TextSize               = 9,
			TextColor3             = C.Muted,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 14),
			TextXAlignment         = Enum.TextXAlignment.Left,
			LayoutOrder            = -1,
			Parent                 = inner,
		})
	end
	Gap(scroll, self:_nextOrder(pi), 10)
	return inner
end

function SlaoqUILib:AddLogConsole(pi, height)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C = self.Config.Colors
	local frame = Create("Frame", {
		Size             = UDim2.new(1, 0, 0, height or 180),
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		LayoutOrder      = self:_nextOrder(pi),
		Parent           = scroll,
	})
	Corner(frame, 8)
	Stroke(frame, C.Border2, 1)
	local textBox = Create("TextBox", {
		Text             = "",
		Font             = Enum.Font.Code,
		TextSize         = 11,
		TextColor3       = C.Text,
		BackgroundTransparency = 1,
		Size             = UDim2.fromScale(1, 1),
		MultiLine        = true,
		TextEditable     = false,
		TextXAlignment   = Enum.TextXAlignment.Left,
		TextYAlignment   = Enum.TextYAlignment.Bottom,
		ClearTextOnFocus = false,
		TextWrapped      = true,
		ZIndex           = 2,
		Parent           = frame,
	})
	Pad(textBox, 8, 8, 10, 10)
	Gap(scroll, self:_nextOrder(pi), 10)
	local console = {Frame=frame, TextBox=textBox, _lines={}}
	function console:Log(message, level)
		local ts   = os.date("%H:%M:%S")
		local lv   = string.upper(level or "INFO")
		local line = ("[%s][%s] %s"):format(ts, lv, tostring(message))
		table.insert(self._lines, line)
		if #self._lines > 300 then table.remove(self._lines, 1) end
		self.TextBox.Text = table.concat(self._lines, "\n")
	end
	function console:Clear()
		self._lines = {}
		self.TextBox.Text = ""
	end
	return console
end

function SlaoqUILib:AddLabel(pi, text, style)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local styles = {
		title    = {size=16, color=C.White, font=cfg.Font},
		subtitle = {size=13, color=C.Text,  font=cfg.Font},
		body     = {size=12, color=C.Text,  font=cfg.FontRegular},
		muted    = {size=11, color=C.Muted, font=cfg.FontRegular},
		caption  = {size=9,  color=C.Dim,   font=cfg.FontRegular},
	}
	local s = styles[style or "body"]
	return Create("TextLabel", {
		Text                   = text or "",
		Font                   = s.font,
		TextSize               = s.size,
		TextColor3             = s.color,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, s.size + 8),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		LayoutOrder            = self:_nextOrder(pi),
		Parent                 = scroll,
	})
end

function SlaoqUILib:AddSeparator(pi, spacing)
	local scroll = self:GetPage(pi); if not scroll then return end
	local sp = spacing or 6
	Gap(scroll, self:_nextOrder(pi), sp)
	Create("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = self.Config.Colors.Border,
		BorderSizePixel  = 0,
		LayoutOrder      = self:_nextOrder(pi),
		Parent           = scroll,
	})
	Gap(scroll, self:_nextOrder(pi), sp)
end

function SlaoqUILib:AddDropdown(pi, labelText, options, callback)
	local scroll = self:GetPage(pi); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	if labelText then
		Create("TextLabel", {
			Text                   = labelText,
			Font                   = cfg.FontRegular,
			TextSize               = 11,
			TextColor3             = C.Muted,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 16),
			TextXAlignment         = Enum.TextXAlignment.Left,
			LayoutOrder            = self:_nextOrder(pi),
			Parent                 = scroll,
		})
	end
	local selected = options[1] or ""
	local open     = false
	local wrapper  = Create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants       = false,
		LayoutOrder            = self:_nextOrder(pi),
		ZIndex                 = 10,
		Parent                 = scroll,
	})
	local dropBtn = Create("TextButton", {
		Text             = selected .. "  v",
		Font             = cfg.FontRegular,
		TextSize         = 12,
		TextColor3       = C.Text,
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, 36),
		AutoButtonColor  = false,
		ZIndex           = 11,
		Parent           = wrapper,
	})
	Corner(dropBtn, 6)
	Stroke(dropBtn, C.Border2, 1)
	Pad(dropBtn, 0, 0, 12, 12)
	local listH = #options * 32
	local optList = Create("Frame", {
		Position         = UDim2.fromOffset(0, 38),
		Size             = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = C.Card2,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 20,
		Visible          = false,
		Parent           = wrapper,
	})
	Corner(optList, 6)
	Stroke(optList, C.Border2, 1)
	Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0), Parent=optList})
	for i, opt in ipairs(options) do
		local ob = Create("TextButton", {
			Text                   = opt,
			Font                   = cfg.FontRegular,
			TextSize               = 12,
			TextColor3             = C.Text,
			BackgroundColor3       = C.Card2,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 32),
			AutoButtonColor        = false,
			LayoutOrder            = i,
			ZIndex                 = 21,
			Parent                 = optList,
		})
		Pad(ob, 0, 0, 12, 12)
		ob.MouseEnter:Connect(function() Tween(ob, 0.1, {BackgroundTransparency=0.85}) end)
		ob.MouseLeave:Connect(function() Tween(ob, 0.1, {BackgroundTransparency=1})    end)
		ob.Activated:Connect(function()
			selected = opt
			dropBtn.Text = opt .. "  v"
			open = false
			Tween(optList, 0.14, {Size=UDim2.new(1,0,0,0)})
			task.delay(0.15, function() optList.Visible = false end)
			if callback then callback(opt) end
		end)
	end
	dropBtn.Activated:Connect(function()
		open = not open
		optList.Visible = true
		if open then
			Tween(optList, 0.18, {Size=UDim2.new(1,0,0,listH)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			Tween(optList, 0.14, {Size=UDim2.new(1,0,0,0)})
			task.delay(0.15, function() optList.Visible = false end)
		end
	end)
	Gap(scroll, self:_nextOrder(pi), 8)
	return {Button=dropBtn, List=optList, GetSelected=function() return selected end}
end

function SlaoqUILib:ShowNotification(message, style, duration)
	local C = self.Config.Colors
	local colors = {info=C.Text, success=C.Green2, warning=C.Yellow, error=C.Red2}
	self._notifText.Text       = message or ""
	self._notifText.TextColor3 = colors[style or "info"] or C.Text
	Tween(self._notifFrame, 0.25, {Position=UDim2.new(0.5,0,1,-14)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(duration or 3.5, function()
		Tween(self._notifFrame, 0.22, {Position=UDim2.new(0.5,0,1,60)})
	end)
end

function SlaoqUILib:ToggleVisibility()
	local win = self.Window
	if win.Visible and win.BackgroundTransparency < 0.5 then
		Tween(win, 0.15, {BackgroundTransparency=1})
		task.delay(0.16, function() if win and win.Parent then win.Visible = false end end)
	else
		win.Visible = true
		win.BackgroundTransparency = 1
		Tween(win, 0.15, {BackgroundTransparency=0})
	end
end

function SlaoqUILib:SetVisible(v)
	self.Window.Visible = v
	if v then self.Window.BackgroundTransparency = 0 end
end

function SlaoqUILib:Destroy()
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	if self.ScreenGui and self.ScreenGui.Parent then
		pcall(function() self.ScreenGui:Destroy() end)
	end
end

return SlaoqUILib
