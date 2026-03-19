--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    SlaoqUILib  v1.2                             ║
    ║        Dark Minimal UI Library for Roblox  (Luau)               ║
    ║                                                                  ║
    ║  Uso — ModuleScript:                                             ║
    ║    local UI = require(game.ReplicatedStorage.SlaoqUILib)        ║
    ║                                                                  ║
    ║  Uso — loadstring:                                               ║
    ║    local UI = loadstring(game:HttpGet("RAW_URL"))()             ║
    ║                                                                  ║
    ║  GuiParent (config):                                             ║
    ║    GuiParent = "CoreGui"   <- padrao                            ║
    ║    GuiParent = "PlayerGui"                                       ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────────────────────
-- COR HELPER
-- Color3.fromHex NAO EXISTE no Luau nativo — use esta funcao no seu codigo
-- Exemplo: SlaoqUILib.hex("ff0000")  ou  local hex = SlaoqUILib.hex
-- ─────────────────────────────────────────────────────────────────────────────
local function hex(str)
	str = str:gsub("#", "")
	local r = tonumber(str:sub(1,2), 16) / 255
	local g = tonumber(str:sub(3,4), 16) / 255
	local b = tonumber(str:sub(5,6), 16) / 255
	return Color3.new(r, g, b)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CORES PADRAO
-- ─────────────────────────────────────────────────────────────────────────────
local DefaultColors = {
	Bg      = hex("000000"),
	Surface = hex("080808"),
	Card    = hex("101010"),
	Card2   = hex("0c0c0c"),
	Border  = hex("1c1c1c"),
	Border2 = hex("252525"),
	Text    = hex("d8d8d8"),
	Muted   = hex("999999"),
	Dim     = hex("666666"),
	White   = hex("ffffff"),
	Green   = hex("00ff88"),
	Green2  = hex("00cc66"),
	Red     = hex("c0392b"),
	Red2    = hex("e74c3c"),
	Yellow  = hex("ffcc00"),
	Orange  = hex("ff8800"),
	Purple  = hex("aa66ff"),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- CONFIG PADRAO
-- ─────────────────────────────────────────────────────────────────────────────
local DefaultConfig = {
	AppName          = "MY APP",
	AppSubtitle      = "Subtitle",
	AppVersion       = "1.0",
	LogoImage        = "",        -- rbxassetid://XXXXX ou ""
	GuiParent        = "CoreGui", -- "CoreGui" | "PlayerGui"
	WindowWidth      = 820,
	WindowHeight     = 540,
	SidebarWidth     = 180,
	Font             = Enum.Font.GothamBold,
	FontRegular      = Enum.Font.Gotham,
	TweenSpeed       = 0.18,
	BarTweenSpeed    = 0.22,
	MobileBreakpoint = 600,
	Pages = {
		{ Icon = "", Name = "Dashboard" },
		{ Icon = "", Name = "Settings"  },
		{ Icon = "", Name = "Logs"      },
		{ Icon = "", Name = "History"   },
	},
}

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPERS INTERNOS
-- ─────────────────────────────────────────────────────────────────────────────
local function Create(class, props)
	local ok, obj = pcall(Instance.new, class)
	if not ok then
		warn("[SlaoqUILib] Instance.new('" .. class .. "') falhou: " .. tostring(obj))
		return nil
	end
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				pcall(function() obj[k] = v end)
			end
		end
		if props.Parent then obj.Parent = props.Parent end
	end
	return obj
end

local function Tween(obj, time, props, eStyle, eDir)
	if not obj or not pcall(function() return obj.Parent end) then return nil end
	local info = TweenInfo.new(
		time   or 0.18,
		eStyle or Enum.EasingStyle.Quint,
		eDir   or Enum.EasingDirection.Out
	)
	local ok, t = pcall(TweenService.Create, TweenService, obj, info, props)
	if ok and t then t:Play(); return t end
	return nil
end

local function Corner(parent, r)
	if not parent then return end
	Create("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function Stroke(parent, color, thickness)
	if not parent then return end
	Create("UIStroke", {
		Color     = color     or DefaultColors.Border2,
		Thickness = thickness or 1,
		Parent    = parent,
	})
end

local function Padding(parent, top, bot, left, right)
	if not parent then return end
	Create("UIPadding", {
		PaddingTop    = UDim.new(0, top   or 8),
		PaddingBottom = UDim.new(0, bot   or 8),
		PaddingLeft   = UDim.new(0, left  or 10),
		PaddingRight  = UDim.new(0, right or 10),
		Parent        = parent,
	})
end

local function Spacer(parent, order, h)
	if not parent then return end
	Create("Frame", {
		Size                   = UDim2.fromOffset(1, h or 8),
		BackgroundTransparency = 1,
		LayoutOrder            = order or 0,
		Parent                 = parent,
	})
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CLASSE PRINCIPAL
-- ─────────────────────────────────────────────────────────────────────────────
local SlaoqUILib = {}
SlaoqUILib.__index = SlaoqUILib

function SlaoqUILib.new(userConfig)
	local self = setmetatable({}, SlaoqUILib)

	-- Merge config
	self.Config = {}
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

	self._pages     = {}
	self._pageIndex = 1
	self._navBtns   = {}
	self._conns     = {}
	self._orderCnt  = {}

	-- ── Parent da GUI ──────────────────────────────────────────────────────
	local guiParent
	if cfg.GuiParent == "PlayerGui" then
		local ok, pg = pcall(function()
			return LocalPlayer:WaitForChild("PlayerGui", 10)
		end)
		guiParent = (ok and pg) or LocalPlayer.PlayerGui
	else
		guiParent = CoreGui
	end

	-- ── ScreenGui ──────────────────────────────────────────────────────────
	local screenGui = Create("ScreenGui", {
		Name           = cfg.AppName:gsub("%s+", "_") .. "_UI",
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder   = 999,
		Parent         = guiParent,
	})
	if cfg.GuiParent == "PlayerGui" then
		pcall(function() screenGui.IgnoreGuiInset = true end)
	end
	self.ScreenGui = screenGui

	-- ── Janela ─────────────────────────────────────────────────────────────
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

	-- ── Auto-scale responsivo ──────────────────────────────────────────────
	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp       = cam.ViewportSize
		local isMobile = vp.X < cfg.MobileBreakpoint or UserInputService.TouchEnabled
		local s = math.min(
			math.clamp(vp.X / 1920, 0.42, 1.0),
			math.clamp(vp.Y / 1080, 0.42, 1.0)
		)
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
			self:_setSidebarCollapsed(sw < 80)
		end
	end
	table.insert(self._conns,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

	-- ── TitleBar ───────────────────────────────────────────────────────────
	local titleBar = Create("Frame", {
		Name             = "TitleBar",
		Size             = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = C.Bg,
		BorderSizePixel  = 0,
		ZIndex           = 10,
		Parent           = win,
	})
	Create("Frame", {
		Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
		BackgroundColor3 = C.Border, BorderSizePixel = 0, ZIndex = 10, Parent = titleBar,
	})
	self.TitleBar = titleBar

	Create("TextLabel", {
		Text = cfg.AppName, Font = cfg.Font, TextSize = 11, TextColor3 = C.White,
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12,5),
		Size = UDim2.new(0.65,0,0,14), TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11, Parent = titleBar,
	})
	Create("TextLabel", {
		Text = "v"..tostring(cfg.AppVersion), Font = cfg.FontRegular, TextSize = 9,
		TextColor3 = C.Dim, BackgroundTransparency = 1, Position = UDim2.fromOffset(12,20),
		Size = UDim2.new(0.65,0,0,12), TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11, Parent = titleBar,
	})

	local minBtn = Create("TextButton", {
		Text = "-", Font = cfg.FontRegular, TextSize = 18, TextColor3 = C.Muted,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1,-40,0.5,0), Size = UDim2.fromOffset(36,36),
		AutoButtonColor = false, ZIndex = 11, Parent = titleBar,
	})
	minBtn.MouseEnter:Connect(function() Tween(minBtn,0.1,{TextColor3=C.White}) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn,0.1,{TextColor3=C.Muted}) end)
	minBtn.Activated:Connect(function() self:ToggleVisibility() end)

	local closeBtn = Create("TextButton", {
		Text = "x", Font = cfg.Font, TextSize = 12, TextColor3 = C.Muted,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1,-4,0.5,0), Size = UDim2.fromOffset(36,36),
		AutoButtonColor = false, ZIndex = 11, Parent = titleBar,
	})
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn,0.1,{TextColor3=C.Red2}) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn,0.1,{TextColor3=C.Muted}) end)
	closeBtn.Activated:Connect(function() self:Destroy() end)

	-- Drag (mouse + touch)
	do
		local dragging, dragStart, winStart = false, nil, nil
		titleBar.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
			or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = inp.Position; winStart = win.Position
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
			win.Position = UDim2.new(
				winStart.X.Scale, winStart.X.Offset + d.X,
				winStart.Y.Scale, winStart.Y.Offset + d.Y)
		end))
	end

	-- ── Body ───────────────────────────────────────────────────────────────
	local body = Create("Frame", {
		Name = "Body", Position = UDim2.fromOffset(0,36),
		Size = UDim2.new(1,0,1,-36), BackgroundTransparency = 1, Parent = win,
	})
	self.Body = body

	-- ── Sidebar ────────────────────────────────────────────────────────────
	local sidebar = Create("Frame", {
		Name = "Sidebar", Size = UDim2.new(0,cfg.SidebarWidth,1,0),
		BackgroundColor3 = C.Bg, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 5, Parent = body,
	})
	Create("Frame", {
		Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0),
		BackgroundColor3 = C.Border, BorderSizePixel = 0, ZIndex = 6, Parent = sidebar,
	})
	self._sidebar = sidebar

	local sideScroll = Create("ScrollingFrame", {
		Name = "SideScroll", Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 5, Parent = sidebar,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sideScroll,
	})
	Padding(sideScroll, 12, 12, 6, 6)

	-- Logo area
	local logoArea = Create("Frame", {
		Name = "LogoArea", Size = UDim2.new(1,0,0,84),
		BackgroundTransparency = 1, LayoutOrder = 0, Parent = sideScroll,
	})
	local logoImg = Create("ImageLabel", {
		Name = "Logo", AnchorPoint = Vector2.new(0.5,0),
		Position = UDim2.new(0.5,0,0,4), Size = UDim2.fromOffset(44,44),
		BackgroundColor3 = hex("000000"),
		BackgroundTransparency = cfg.LogoImage ~= "" and 1 or 0,
		Image = cfg.LogoImage or "", ZIndex = 6, Parent = logoArea,
	})
	Corner(logoImg, 22)
	if cfg.LogoImage == "" then
		Stroke(logoImg, C.Border2, 1.5)
		Create("TextLabel", {
			Text = string.upper(string.sub(cfg.AppName,1,1)),
			Font = cfg.Font, TextSize = 20, TextColor3 = C.White,
			BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), ZIndex = 7, Parent = logoImg,
		})
	end
	self.LogoImage = logoImg

	local sideNameLbl = Create("TextLabel", {
		Name = "SideName", Text = cfg.AppName, Font = cfg.Font, TextSize = 10,
		TextColor3 = C.White, BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0,53), Size = UDim2.new(1,0,0,14),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = logoArea,
	})
	local sideSubLbl = Create("TextLabel", {
		Name = "SideSub", Text = cfg.AppSubtitle, Font = cfg.FontRegular, TextSize = 9,
		TextColor3 = C.Muted, BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0,68), Size = UDim2.new(1,0,0,12),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = logoArea,
	})
	self._sideNameLbl = sideNameLbl
	self._sideSubLbl  = sideSubLbl

	Create("Frame", {
		Size = UDim2.new(0.85,0,0,1), BackgroundColor3 = C.Border,
		BorderSizePixel = 0, LayoutOrder = 1, Parent = sideScroll,
	})
	Spacer(sideScroll, 2, 8)

	-- Barra indicadora animada
	local barIndicator = Create("Frame", {
		Name = "BarIndicator", Size = UDim2.fromOffset(3,28),
		AnchorPoint = Vector2.new(0,0.5), Position = UDim2.fromOffset(2,0),
		BackgroundColor3 = C.White, BorderSizePixel = 0,
		ZIndex = 9, Visible = false, Parent = sidebar,
	})
	Corner(barIndicator, 3)
	self._barIndicator = barIndicator

	-- Nav buttons
	for i, page in ipairs(cfg.Pages) do
		table.insert(self._navBtns, self:_makeNavBtn(page, i, sideScroll))
	end
	Spacer(sideScroll, #cfg.Pages + 10, 8)

	-- ── Content Area ────────────────────────────────────────────────────────
	local contentArea = Create("Frame", {
		Name = "ContentArea",
		Position = UDim2.new(0, cfg.SidebarWidth, 0, 0),
		Size = UDim2.new(1, -cfg.SidebarWidth, 1, 0),
		BackgroundColor3 = C.Surface, BorderSizePixel = 0,
		ClipsDescendants = true, Parent = body,
	})
	self._contentArea = contentArea
	table.insert(self._conns, sidebar:GetPropertyChangedSignal("Size"):Connect(function()
		local sw = sidebar.Size.X.Offset
		contentArea.Position = UDim2.new(0,sw,0,0)
		contentArea.Size     = UDim2.new(1,-sw,1,0)
	end))

	-- ── Toast de notificacao ────────────────────────────────────────────────
	local notifFrame = Create("Frame", {
		Name = "Notif", AnchorPoint = Vector2.new(0.5,1),
		Position = UDim2.new(0.5,0,1,60), Size = UDim2.fromOffset(320,44),
		BackgroundColor3 = C.Card, BorderSizePixel = 0, ZIndex = 100, Parent = win,
	})
	Corner(notifFrame, 8)
	Stroke(notifFrame, C.Border2, 1)
	local notifText = Create("TextLabel", {
		Text = "", Font = cfg.FontRegular, TextSize = 11, TextColor3 = C.Text,
		BackgroundTransparency = 1, Size = UDim2.fromScale(1,1),
		TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true,
		ZIndex = 101, Parent = notifFrame,
	})
	Padding(notifFrame, 6, 6, 12, 12)
	self._notifFrame = notifFrame
	self._notifText  = notifText

	-- Inicializa
	self:_buildPages()
	self:SetPage(1)
	task.defer(updateScale)

	return self
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NAV BUTTON
-- ─────────────────────────────────────────────────────────────────────────────
function SlaoqUILib:_makeNavBtn(page, index, parent)
	local C, cfg = self.Config.Colors, self.Config

	local frame = Create("Frame", {
		Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
		LayoutOrder = index + 2, Parent = parent,
	})
	local hoverBg = Create("Frame", {
		Size = UDim2.new(1,-8,1,-4), Position = UDim2.fromOffset(4,2),
		BackgroundColor3 = C.White, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 5, Parent = frame,
	})
	Corner(hoverBg, 6)

	local hasIcon = page.Icon and page.Icon ~= ""
	if hasIcon then
		Create("ImageLabel", {
			Size = UDim2.fromOffset(16,16), Position = UDim2.fromOffset(10,9),
			BackgroundTransparency = 1, Image = page.Icon, ZIndex = 6, Parent = frame,
		})
	else
		local dot = Create("Frame", {
			Size = UDim2.fromOffset(5,5), Position = UDim2.fromOffset(14,15),
			BackgroundColor3 = C.Dim, BorderSizePixel = 0, ZIndex = 6, Parent = frame,
		})
		Corner(dot, 3)
	end

	local lx = hasIcon and 32 or 26
	local textLabel = Create("TextLabel", {
		Text = page.Name, Font = cfg.Font, TextSize = 11, TextColor3 = C.Muted,
		BackgroundTransparency = 1, Position = UDim2.fromOffset(lx,0),
		Size = UDim2.new(1,-(lx+8),1,0), TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = frame,
	})
	local hitbox = Create("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1), AutoButtonColor = false, ZIndex = 7, Parent = frame,
	})
	hitbox.MouseEnter:Connect(function()
		if self._pageIndex ~= index then
			Tween(hoverBg,   0.12, { BackgroundTransparency = 0.94 })
			Tween(textLabel, 0.12, { TextColor3 = C.Text })
		end
	end)
	hitbox.MouseLeave:Connect(function()
		if self._pageIndex ~= index then
			Tween(hoverBg,   0.12, { BackgroundTransparency = 1 })
			Tween(textLabel, 0.12, { TextColor3 = C.Muted })
		end
	end)
	hitbox.Activated:Connect(function() self:SetPage(index) end)

	return { Frame = frame, HoverBg = hoverBg, TextLabel = textLabel }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PAGINAS
-- ─────────────────────────────────────────────────────────────────────────────
function SlaoqUILib:_buildPages()
	local C = self.Config.Colors
	for i = 1, #self.Config.Pages do
		local pageFrame = Create("Frame", {
			Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
			Visible = false, Parent = self._contentArea,
		})
		local scroll = Create("ScrollingFrame", {
			Name = "PageScroll", Size = UDim2.fromScale(1,1),
			BackgroundTransparency = 1, ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.Border2,
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = pageFrame,
		})
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0), Parent = scroll,
		})
		Padding(scroll, 20, 20, 22, 22)
		self._pages[i]    = { Frame = pageFrame, Scroll = scroll }
		self._orderCnt[i] = 100
	end
end

function SlaoqUILib:SetPage(index)
	local cfg, C = self.Config, self.Config.Colors
	if self._pages[self._pageIndex] then
		self._pages[self._pageIndex].Frame.Visible = false
	end
	local old = self._navBtns[self._pageIndex]
	if old then
		Tween(old.TextLabel, cfg.TweenSpeed, { TextColor3 = C.Muted })
		Tween(old.HoverBg,   cfg.TweenSpeed, { BackgroundTransparency = 1 })
	end
	self._pageIndex = index
	if self._pages[index] then
		self._pages[index].Frame.Visible = true
	end
	local nb = self._navBtns[index]
	if nb then
		Tween(nb.TextLabel, cfg.TweenSpeed, { TextColor3 = C.White })
		Tween(nb.HoverBg,   cfg.TweenSpeed, { BackgroundTransparency = 0.93 })
		self:_animBar(nb.Frame)
	end
end

function SlaoqUILib:_animBar(targetFrame)
	local bar = self._barIndicator
	if not bar or not targetFrame then return end
	task.defer(function()
		local ok, relY = pcall(function()
			return targetFrame.AbsolutePosition.Y
			     - self._sidebar.AbsolutePosition.Y
			     + targetFrame.AbsoluteSize.Y * 0.5
		end)
		if not ok then return end
		bar.Visible = true
		local cfg = self.Config
		local t = Tween(bar, cfg.BarTweenSpeed*0.45,
			{ Size = UDim2.fromOffset(3,0) },
			Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		if t then
			t.Completed:Connect(function()
				if bar and bar.Parent then
					bar.Position = UDim2.new(0,2,0,relY)
					Tween(bar, cfg.BarTweenSpeed*0.6,
						{ Size = UDim2.fromOffset(3,28) },
						Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
			end)
		end
	end)
end

function SlaoqUILib:_setSidebarCollapsed(collapsed)
	if self._sideNameLbl then self._sideNameLbl.Visible = not collapsed end
	if self._sideSubLbl  then self._sideSubLbl.Visible  = not collapsed end
	for _, nb in ipairs(self._navBtns) do
		if nb.TextLabel then nb.TextLabel.Visible = not collapsed end
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPERS DE ACESSO
-- ─────────────────────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────────────────────
-- COMPONENTES PUBLICOS
-- ─────────────────────────────────────────────────────────────────────────────

function SlaoqUILib:AddSectionHeader(pageIndex, title, subtitle)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local frame = Create("Frame", {
		Size = UDim2.new(1,0,0, subtitle and 48 or 28),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(pageIndex), Parent = scroll,
	})
	Create("TextLabel", {
		Text = title, Font = cfg.Font, TextSize = 18, TextColor3 = C.White,
		BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
	})
	if subtitle then
		Create("TextLabel", {
			Text = subtitle, Font = cfg.FontRegular, TextSize = 11, TextColor3 = C.Muted,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0,24),
			Size = UDim2.new(1,0,0,16), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
		})
	end
	Create("Frame", {
		Size = UDim2.new(1,0,0,1), BackgroundColor3 = C.Border, BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(pageIndex), Parent = scroll,
	})
	Spacer(scroll, self:_nextOrder(pageIndex), 10)
end

-- cards = { {Label="X", Value="0", Unit=""}, ... }
function SlaoqUILib:AddMetricRow(pageIndex, cards)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local row = Create("Frame", {
		Size = UDim2.new(1,0,0,74), BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(pageIndex), Parent = scroll,
	})
	Create("UIGridLayout", {
		CellSize = UDim2.new(1/#cards,-6,1,0),
		CellPaddingHorizontal = UDim.new(0,6),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
	})
	local objects = {}
	for i, card in ipairs(cards) do
		local f = Create("Frame", {
			BackgroundColor3 = C.Card, BorderSizePixel = 0,
			ZIndex = 2, LayoutOrder = i, Parent = row,
		})
		Corner(f,10); Stroke(f,C.Border,1); Padding(f,10,10,14,10)
		Create("TextLabel", {
			Text = card.Label or "", Font = cfg.Font, TextSize = 9, TextColor3 = C.Muted,
			BackgroundTransparency = 1, Size = UDim2.new(1,0,0,13),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = f,
		})
		local valLbl = Create("TextLabel", {
			Text = card.Value or "-", Font = cfg.Font, TextSize = 20, TextColor3 = C.White,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0,14),
			Size = UDim2.new(1,0,0,26), TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3, Parent = f,
		})
		if card.Unit and card.Unit ~= "" then
			Create("TextLabel", {
				Text = card.Unit, Font = cfg.FontRegular, TextSize = 9, TextColor3 = C.Dim,
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0,42),
				Size = UDim2.new(1,0,0,12), TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3, Parent = f,
			})
		end
		local ib = Create("TextButton", {
			Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
			ZIndex=4,AutoButtonColor=false,Parent=f,
		})
		ib.MouseEnter:Connect(function() Tween(f,0.12,{BackgroundColor3=C.Card2}) end)
		ib.MouseLeave:Connect(function() Tween(f,0.12,{BackgroundColor3=C.Card }) end)
		objects[i] = { Frame = f, ValueLabel = valLbl }
	end
	Spacer(scroll, self:_nextOrder(pageIndex), 10)
	return objects
end

function SlaoqUILib:SetMetricValue(cardObj, value)
	if cardObj and cardObj.ValueLabel then
		cardObj.ValueLabel.Text = tostring(value)
	end
end

-- state: "on" | "off" | "idle"
function SlaoqUILib:CreateStatusBadge(parent, state)
	local C, cfg = self.Config.Colors, self.Config
	local map = {
		on   = {text="ON",  bg=hex("00cc66"),bgA=0.90,tc=C.Green2,bc=hex("00cc66")},
		off  = {text="OFF", bg=hex("e74c3c"),bgA=0.90,tc=C.Red2,  bc=hex("e74c3c")},
		idle = {text="IDLE",bg=hex("ffcc00"),bgA=0.93,tc=C.Yellow, bc=hex("ffcc00")},
	}
	local s = map[state or "idle"]
	local frame = Create("Frame", {
		Name="StatusBadge", Size=UDim2.fromOffset(52,20),
		BackgroundColor3=s.bg, BackgroundTransparency=s.bgA,
		BorderSizePixel=0, Parent=parent,
	})
	Corner(frame,9); Stroke(frame,s.bc,1)
	local lbl = Create("TextLabel", {
		Text=s.text, Font=cfg.Font, TextSize=9, TextColor3=s.tc,
		BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=2, Parent=frame,
	})
	local badge = {Frame=frame,Label=lbl,_map=map}
	function badge:SetState(ns)
		local sp=self._map[ns]; if not sp then return end
		Tween(self.Frame,0.15,{BackgroundColor3=sp.bg,BackgroundTransparency=sp.bgA})
		self.Label.Text=sp.text; self.Label.TextColor3=sp.tc
	end
	return badge
end

-- style: "primary"|"danger"|"warning"|"ghost"
function SlaoqUILib:AddButton(pageIndex, text, style, callback)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local styles = {
		primary={bg=C.White, tc=C.Bg,   hov=hex("dddddd")},
		danger ={bg=C.Red,   tc=C.White,hov=C.Red2},
		warning={bg=C.Yellow,tc=C.Bg,   hov=C.Orange},
		ghost  ={bg=C.Card,  tc=C.Text, hov=C.Card2},
	}
	local s = styles[style or "primary"]
	local btn = Create("TextButton", {
		Text=text, Font=cfg.Font, TextSize=12, TextColor3=s.tc,
		BackgroundColor3=s.bg, BorderSizePixel=0,
		Size=UDim2.new(0,140,0,38), AutoButtonColor=false,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Corner(btn,8)
	btn.MouseEnter:Connect(function() Tween(btn,0.12,{BackgroundColor3=s.hov}) end)
	btn.MouseLeave:Connect(function() Tween(btn,0.12,{BackgroundColor3=s.bg}) end)
	if callback then btn.Activated:Connect(callback) end
	Spacer(scroll,self:_nextOrder(pageIndex),8)
	return btn
end

-- defs = { {Text="",Style="primary",Width=140,Callback=fn}, ... }
function SlaoqUILib:AddButtonRow(pageIndex, defs)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local styles = {
		primary={bg=C.White, tc=C.Bg,   hov=hex("dddddd")},
		danger ={bg=C.Red,   tc=C.White,hov=C.Red2},
		warning={bg=C.Yellow,tc=C.Bg,   hov=C.Orange},
		ghost  ={bg=C.Card,  tc=C.Text, hov=C.Card2},
	}
	local row = Create("Frame", {
		Size=UDim2.new(1,0,0,42), BackgroundTransparency=1,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Create("UIListLayout", {
		FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,8), Parent=row,
	})
	local btns={}
	for i, d in ipairs(defs) do
		local s=styles[d.Style or "primary"]
		local btn=Create("TextButton", {
			Text=d.Text or "", Font=cfg.Font, TextSize=12,
			TextColor3=s.tc, BackgroundColor3=s.bg,
			BorderSizePixel=0, Size=UDim2.fromOffset(d.Width or 140,38),
			AutoButtonColor=false, LayoutOrder=i, Parent=row,
		})
		Corner(btn,8)
		btn.MouseEnter:Connect(function() Tween(btn,0.12,{BackgroundColor3=s.hov}) end)
		btn.MouseLeave:Connect(function() Tween(btn,0.12,{BackgroundColor3=s.bg}) end)
		if d.Callback then btn.Activated:Connect(d.Callback) end
		btns[i]=btn
	end
	Spacer(scroll,self:_nextOrder(pageIndex),10)
	return btns
end

function SlaoqUILib:AddToggle(pageIndex, label, default, callback)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local row = Create("Frame", {
		Size=UDim2.new(1,0,0,34), BackgroundTransparency=1,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Create("TextLabel", {
		Text=label, Font=cfg.FontRegular, TextSize=12, TextColor3=C.Text,
		BackgroundTransparency=1, Size=UDim2.new(1,-56,1,0),
		TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
	})
	local state = default == true
	local track = Create("Frame", {
		AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
		Size=UDim2.fromOffset(36,20),
		BackgroundColor3=state and C.White or C.Card,
		BorderSizePixel=0, Parent=row,
	})
	Corner(track,10); Stroke(track,C.Border2,1)
	local knob = Create("Frame", {
		AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0, state and 18 or 2, 0.5, 0),
		Size=UDim2.fromOffset(16,16),
		BackgroundColor3=state and C.Bg or C.Muted,
		BorderSizePixel=0, Parent=track,
	})
	Corner(knob,8)
	local hitbox=Create("TextButton", {
		Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
		ZIndex=5,AutoButtonColor=false,Parent=track,
	})
	hitbox.Activated:Connect(function()
		state=not state
		Tween(track,0.15,{BackgroundColor3=state and C.White or C.Card})
		Tween(knob, 0.15,{
			Position=UDim2.new(0,state and 18 or 2,0.5,0),
			BackgroundColor3=state and C.Bg or C.Muted,
		})
		if callback then callback(state) end
	end)
	Spacer(scroll,self:_nextOrder(pageIndex),6)
	local toggle={Track=track,Knob=knob}
	function toggle:SetState(v)
		state=v
		Tween(track,0.15,{BackgroundColor3=v and C.White or C.Card})
		Tween(knob, 0.15,{
			Position=UDim2.new(0,v and 18 or 2,0.5,0),
			BackgroundColor3=v and C.Bg or C.Muted,
		})
	end
	function toggle:GetState() return state end
	return toggle
end

function SlaoqUILib:AddInput(pageIndex, labelText, placeholder, callback)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	if labelText then
		Create("TextLabel", {
			Text=labelText, Font=cfg.FontRegular, TextSize=11, TextColor3=C.Muted,
			BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
		})
	end
	local box=Create("TextBox", {
		Text="", PlaceholderText=placeholder or "",
		Font=cfg.FontRegular, TextSize=12, TextColor3=C.Text,
		PlaceholderColor3=C.Dim, BackgroundColor3=C.Card,
		BorderSizePixel=0, Size=UDim2.new(1,0,0,36),
		ClearTextOnFocus=false,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Corner(box,6); Stroke(box,C.Border2,1); Padding(box,0,0,12,12)
	box.Focused:Connect(function()  Tween(box,0.12,{BackgroundColor3=C.Card2}) end)
	box.FocusLost:Connect(function(enter)
		Tween(box,0.12,{BackgroundColor3=C.Card})
		if callback then callback(box.Text,enter) end
	end)
	Spacer(scroll,self:_nextOrder(pageIndex),8)
	return box
end

function SlaoqUILib:AddCard(pageIndex, title)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local card=Create("Frame", {
		Name="Card", Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card, BorderSizePixel=0,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Corner(card,10); Stroke(card,C.Border,1)
	local inner=Create("Frame", {
		Name="Inner", Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1, Parent=card,
	})
	Padding(inner,14,14,16,16)
	Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),Parent=inner})
	if title then
		Create("TextLabel", {
			Text=string.upper(title), Font=cfg.Font, TextSize=9, TextColor3=C.Muted,
			BackgroundTransparency=1, Size=UDim2.new(1,0,0,14),
			TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=-1, Parent=inner,
		})
	end
	Spacer(scroll,self:_nextOrder(pageIndex),10)
	return inner
end

function SlaoqUILib:AddLogConsole(pageIndex, height)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local frame=Create("Frame", {
		Size=UDim2.new(1,0,0,height or 180), BackgroundColor3=C.Card,
		BorderSizePixel=0, ClipsDescendants=true,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Corner(frame,8); Stroke(frame,C.Border2,1)
	local textBox=Create("TextBox", {
		Text="", Font=Enum.Font.Code, TextSize=11, TextColor3=C.Text,
		BackgroundTransparency=1, Size=UDim2.fromScale(1,1),
		MultiLine=true, TextEditable=false,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextYAlignment=Enum.TextYAlignment.Bottom,
		ClearTextOnFocus=false, TextWrapped=true, ZIndex=2, Parent=frame,
	})
	Padding(textBox,8,8,10,10)
	Spacer(scroll,self:_nextOrder(pageIndex),10)
	local levelColors={
		INFO   ="rgb(153,153,153)", SUCCESS="rgb(0,255,136)",
		WARN   ="rgb(255,204,0)",   ERROR  ="rgb(231,76,60)",
		DEBUG  ="rgb(170,102,255)", SNIPE  ="rgb(255,255,255)",
	}
	local console={Frame=frame,TextBox=textBox,_lines={}}
	function console:Log(message,level)
		level=(level or "INFO"):upper()
		local col=levelColors[level] or levelColors.INFO
		local ts=os.date("%H:%M:%S")
		local line=string.format(
			'<font color="rgb(68,68,68)">[%s]</font> <font color="%s">%s</font>',
			ts,col,message)
		table.insert(self._lines,line)
		if #self._lines>300 then table.remove(self._lines,1) end
		self.TextBox.Text=table.concat(self._lines,"\n")
	end
	function console:Clear() self._lines={}; self.TextBox.Text="" end
	return console
end

function SlaoqUILib:AddLabel(pageIndex, text, style)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	local styles={
		title   ={size=16,color=C.White, font=cfg.Font},
		subtitle={size=13,color=C.Text,  font=cfg.Font},
		body    ={size=12,color=C.Text,  font=cfg.FontRegular},
		muted   ={size=11,color=C.Muted, font=cfg.FontRegular},
		caption ={size=9, color=C.Dim,   font=cfg.FontRegular},
	}
	local s=styles[style or "body"]
	return Create("TextLabel", {
		Text=text, Font=s.font, TextSize=s.size, TextColor3=s.color,
		BackgroundTransparency=1, Size=UDim2.new(1,0,0,s.size+6),
		TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
end

function SlaoqUILib:AddSeparator(pageIndex, spacing)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local sp=spacing or 6
	Spacer(scroll,self:_nextOrder(pageIndex),sp)
	Create("Frame", {
		Size=UDim2.new(1,0,0,1), BackgroundColor3=self.Config.Colors.Border,
		BorderSizePixel=0, LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	Spacer(scroll,self:_nextOrder(pageIndex),sp)
end

function SlaoqUILib:AddDropdown(pageIndex, labelText, options, callback)
	local scroll = self:GetPage(pageIndex); if not scroll then return end
	local C, cfg = self.Config.Colors, self.Config
	if labelText then
		Create("TextLabel", {
			Text=labelText, Font=cfg.FontRegular, TextSize=11, TextColor3=C.Muted,
			BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
		})
	end
	local selected=options[1] or ""; local open=false
	local container=Create("Frame", {
		Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
		LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll,
	})
	local dropBtn=Create("TextButton", {
		Text=selected.."  v", Font=cfg.FontRegular, TextSize=12, TextColor3=C.Text,
		BackgroundColor3=C.Card, BorderSizePixel=0,
		Size=UDim2.new(1,0,0,36), AutoButtonColor=false, Parent=container,
	})
	Corner(dropBtn,6); Stroke(dropBtn,C.Border2,1); Padding(dropBtn,0,0,12,12)
	local listH=#options*32
	local optList=Create("Frame", {
		Position=UDim2.fromOffset(0,38), Size=UDim2.new(1,0,0,0),
		BackgroundColor3=C.Card2, BorderSizePixel=0,
		ClipsDescendants=true, ZIndex=20, Visible=false, Parent=container,
	})
	Corner(optList,6); Stroke(optList,C.Border2,1)
	Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=optList})
	for i,opt in ipairs(options) do
		local ob=Create("TextButton", {
			Text=opt, Font=cfg.FontRegular, TextSize=12, TextColor3=C.Text,
			BackgroundColor3=C.Card2, BackgroundTransparency=1,
			BorderSizePixel=0, Size=UDim2.new(1,0,0,32),
			AutoButtonColor=false, LayoutOrder=i, Parent=optList,
		})
		Padding(ob,0,0,12,12)
		ob.MouseEnter:Connect(function() Tween(ob,0.1,{BackgroundTransparency=0.85}) end)
		ob.MouseLeave:Connect(function() Tween(ob,0.1,{BackgroundTransparency=1}) end)
		ob.Activated:Connect(function()
			selected=opt; dropBtn.Text=opt.."  v"; open=false
			Tween(optList,0.15,{Size=UDim2.new(1,0,0,0)})
			task.delay(0.15,function() if optList and optList.Parent then optList.Visible=false end end)
			if callback then callback(opt) end
		end)
	end
	dropBtn.Activated:Connect(function()
		open=not open; optList.Visible=true
		if open then
			Tween(optList,0.18,{Size=UDim2.new(1,0,0,listH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		else
			Tween(optList,0.15,{Size=UDim2.new(1,0,0,0)})
			task.delay(0.15,function() if optList and optList.Parent then optList.Visible=false end end)
		end
	end)
	Spacer(scroll,self:_nextOrder(pageIndex),8)
	return {Button=dropBtn,List=optList,GetSelected=function() return selected end}
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICACAO / VISIBILIDADE / DESTRUICAO
-- ─────────────────────────────────────────────────────────────────────────────
function SlaoqUILib:ShowNotification(message, style, duration)
	local C=self.Config.Colors
	local cols={info=C.Text,success=C.Green2,warning=C.Yellow,error=C.Red2}
	self._notifText.Text      =message
	self._notifText.TextColor3=cols[style or "info"] or C.Text
	Tween(self._notifFrame,0.25,{Position=UDim2.new(0.5,0,1,-14)},
		Enum.EasingStyle.Back,Enum.EasingDirection.Out)
	task.delay(duration or 3.5,function()
		if self._notifFrame and self._
