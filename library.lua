local Lib = {}
Lib.__index = Lib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")   
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local function fromHex(h)
	h = h:gsub("#","")
	return Color3.new(
		tonumber(h:sub(1,2),16)/255,
		tonumber(h:sub(3,4),16)/255,
		tonumber(h:sub(5,6),16)/255
	)
end

local _rm = false
local _tweenMap = setmetatable({}, {__mode="k"})
local function tw(obj, t, props, es, ed)
	if not obj or not obj.Parent then return end
	local duration, style, dir
	if _rm then
		duration = math.min(t or .2, 0.06)
		style = Enum.EasingStyle.Quint
		dir = Enum.EasingDirection.Out
	else
		duration = t or .2
		style = es or Enum.EasingStyle.Quint
		dir = ed or Enum.EasingDirection.Out
	end
	local prev = _tweenMap[obj]
	if prev then
		pcall(function() prev:Cancel() end)
	end
	local ok, tween = pcall(TweenService.Create, TweenService, obj,
		TweenInfo.new(duration, style, dir), props)
	if ok and tween then
		_tweenMap[obj] = tween
		tween.Completed:Connect(function()
			if _tweenMap[obj] == tween then
				_tweenMap[obj] = nil
			end
		end)
		tween:Play()
		return tween
	end
end

local function new(class, props, parent)
	local ok, obj = pcall(Instance.new, class)
	if not ok then return end
	for k,v in pairs(props or {}) do
		if k ~= "Parent" then pcall(function() obj[k]=v end) end
	end
	if parent then obj.Parent = parent end
	return obj
end

local function corner(obj, r)
	new("UICorner",{CornerRadius=UDim.new(0,r or 8)},obj)
end

local function stroke(obj, c, th, tr)
	return new("UIStroke",{Color=c or fromHex("2a2a2a"),Thickness=th or 1,Transparency=tr or 0},obj)
end

local function pad(obj, t, b, l, r)
	new("UIPadding",{PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0)},obj)
end

local function hlist(obj, spacing, valign)
	new("UIListLayout",{
		FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,
		VerticalAlignment=valign or Enum.VerticalAlignment.Center,
		Padding=UDim.new(0,spacing or 0)
	},obj)
end

local function vlist(obj, spacing, halign)
	new("UIListLayout",{
		FillDirection=Enum.FillDirection.Vertical,
		SortOrder=Enum.SortOrder.LayoutOrder,
		HorizontalAlignment=halign or Enum.HorizontalAlignment.Left,
		Padding=UDim.new(0,spacing or 0)
	},obj)
end

-- Validation helpers
local function validateString(v, fallback)
	if typeof(v) == "string" then return v end
	return fallback or ""
end
local function validateTable(v, fallback)
	if typeof(v) == "table" then return v end
	return fallback or {}
end
local function validateCallback(v)
	if typeof(v) == "function" then return v end
	return nil
end

-- Safe call helper
local function safeCall(tag, fn, ...)
	if typeof(fn) ~= "function" then return false end
	local ok, res = pcall(fn, ...)
	return ok, res
end

local C = {
	Bg       = fromHex("060606"),
	Bg2      = fromHex("080808"),
	Sidebar  = fromHex("050505"),
	Card     = fromHex("121212"),
	Card2    = fromHex("1a1a1a"),
	Card3    = fromHex("222222"),
	Border   = fromHex("2a2a2a"),
	Border2  = fromHex("222222"),
	Border3  = fromHex("2e2e2e"),
	Text     = fromHex("d8d8d8"),
	TextDim  = fromHex("9a9a9a"),
	TextOff  = fromHex("555555"),
	White    = fromHex("ffffff"),
	Green    = fromHex("00e87a"),
	GreenBg  = fromHex("030e08"),
	Red      = fromHex("e84040"),
	RedBg    = fromHex("0e0404"),
	Yellow   = fromHex("f0c030"),
	YellowBg = fromHex("0e0b02"),
	Orange   = fromHex("f07020"),
	Blue     = fromHex("4488ff"),
	BlueBg   = fromHex("030914"),
	Purple   = fromHex("aa44ff"),
	PurpleBg = fromHex("0a0414"),
}

local function accentOrWhite(lib)
    if lib and lib.cfg and lib.cfg.AccentColor then
        return lib.cfg.AccentColor
    end
    return C.White
end

local DefaultConfig = {
	AccentColor        = nil,
	Colors             = nil,
	AppName            = "MY APP",
	AppSubtitle        = "Subtitle",
	AppVersion         = "1.0",
	LogoImage          = "rbxassetid://102126718358520",
	GuiParent          = "CoreGui",
	WindowWidth        = 920,
	WindowHeight       = 580,
	SidebarWidth       = 210,
	TweenSpeed         = 0.22,
	BarTweenSpeed      = 0.22,
	MiniModeBreakpoint = 700,
	ToggleKey          = nil,
	ShowPill           = true,
	SplashMode         = "splash",
	Debug              = false,
	Pages = {
		{Name="Dashboard"},
		{Name="Settings"},
		{Name="Logs"},
	},
	SplashTasks = {
		"Initializing runtime...",
		"Loading configuration...",
		"Preparing engine...",
		"Ready.",
	},
}

function Lib.new(userCfg)
	local self = setmetatable({}, Lib)
	self.cfg = {}
	for k,v in pairs(DefaultConfig) do self.cfg[k]=v end

	local isDemo = (userCfg == nil)

	if isDemo then
		self.cfg.AppName     = "SlaoqUILib"
		self.cfg.AppSubtitle = "Component Showcase"
		self.cfg.AppVersion  = "1.0"
		self.cfg.Pages = {
			{Name="Dashboard"},
			{Name="Inputs"},
			{Name="Components"},
			{Name="Buttons"},
			{Name="Logs"},
		}
		self.cfg.SplashTasks = {
			"Initializing SlaoqUILib...",
			"Loading components...",
			"Starting showcase...",
			"Ready.",
		}
	else
		for k,v in pairs(userCfg) do self.cfg[k]=v end
	end

	if self.cfg.Colors and type(self.cfg.Colors)=="table" then
		for k,v in pairs(self.cfg.Colors) do
			if C[k] ~= nil and type(v)=="userdata" then
				C[k]=v
			end
		end
	end

	self._pages      = {}
	self._navBtns    = {}
	self._conns      = {}
	self._tweens     = {}
	self._tasks      = {}
	self._debounces  = {}
	self._throttles  = {}
	self._cid        = 0
	self._ord        = {}
	self._pageIdx    = 1
	self._minimised  = false
	self._miniWasUsed= false
	self._mobilePill = nil
	self._preMinSize = nil
	self._minBtn     = nil
	self._minImg     = nil
	self._minFb      = nil
	self._tbFiller   = nil
	self._tbBorderLine = nil
	self._toggleKey      = (userCfg and userCfg.ToggleKey) or "K"
	self._toasts         = {}
	self._toastCount     = 0
	self._hidden         = false
	self._reduceMotion   = false
	self._simulateMobile = false
	self._settingsVisible= false
	self._kbListening    = false
	self._onDestroyFns   = {}
	self._settingsFrame  = nil
	self._settingsScroll = nil
	self._gearImg        = nil
	self._searchBtnImg   = nil
	self._searchNavUp    = nil
	self._searchNavDown  = nil
	self._searchIdx      = 0

	local guiParent = self.cfg.GuiParent == "PlayerGui"
		and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

	self._sg = new("ScreenGui",{
		Name="SlaoqUI",
		ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
		DisplayOrder=999,
	}, guiParent)
	pcall(function() self._sg.IgnoreGuiInset = true end)

	self:_buildToastSystem()
	self:_buildWindow()
	if isDemo then
		local ok, err = pcall(function() self:_runDemo() end)
		if not ok then
			self:logError("_runDemo error: "..tostring(err))
		end
	end
	self:_runSplash()

	pcall(function()
		local saved = self._loadState and self:_loadState()
		if saved then
			if saved.pageIdx and self._pages[saved.pageIdx] then
				self:SetPage(saved.pageIdx)
			end
			if saved.offsetX and saved.offsetY and not self:_useMiniMode() then
				self.Window.Position = UDim2.new(0.5, saved.offsetX, 0.5, saved.offsetY)
				self._dragTargetOX = saved.offsetX
				self._dragTargetOY = saved.offsetY
			end
		end
	end)

	-- registry of instances: last created instance is the active one for global keybinds
	Lib._instances = Lib._instances or {}
	table.insert(Lib._instances, self)
	local function isActiveInstance()
		for i = #Lib._instances, 1, -1 do
			local inst = Lib._instances[i]
			if inst and inst._sg and not inst._destroyed then
				return inst == self
			end
		end
		return true
	end

	if not UserInputService.TouchEnabled then
		self._keyConn = UserInputService.InputBegan:Connect(function(inp, gp)
			if gp then return end
			if not isActiveInstance() then return end
			local kc = tostring(inp.KeyCode):gsub("Enum%.KeyCode%.","")
			if kc == self._toggleKey and not self._kbListening then
				if UserInputService:GetFocusedTextBox() then return end
				if not self:_debounce("toggle_key",0.15) then return end
				self:ToggleVisibility()
			end
			if kc == "F" and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
				if not self._hidden then self:_openSearch() end
			end
			if kc == "Escape" and self._searchOpen then
				self:_closeSearch()
			end
		end)
	end

	return self
end

function Lib:_addConnection(conn)
	if conn then table.insert(self._conns, conn) end
	return conn
end
function Lib:_addTask(threadObj)
	if threadObj then table.insert(self._tasks, threadObj) end
	return threadObj
end
function Lib:_addTween(tweenObj)
	if tweenObj then table.insert(self._tweens, tweenObj) end
	return tweenObj
end
function Lib:_safeCall(cb, ...)
	if not validateCallback(cb) then return false end
	local args = {...}
	task.spawn(function()
		local ok, err = safeCall(nil, cb, table.unpack(args))
		if not ok then
			self:logError("callback error", nil)
		end
	end)
	return true
end
function Lib:_debounce(key, interval)
	key = tostring(key or "__")
	local now = os.clock()
	local untilTs = self._debounces[key]
	if untilTs and now < untilTs then return false end
	self._debounces[key] = now + (interval or 0.18)
	return true
end
function Lib:_throttle(key, interval)
	key = tostring(key or "__")
	local now = os.clock()
	local nextTs = self._throttles[key]
	if nextTs and now < nextTs then return false end
	self._throttles[key] = now + (interval or 0.1)
	return true
end
function Lib:IsVisible()
	return not self._hidden
end
function Lib:IsMinimised()
	return self._minimised == true
end
function Lib:_isAlive() return not self._destroyed end
function Lib:_nextCompId(name)
	self._cid = (self._cid or 0) + 1
	return (name or "Component") .. "#" .. tostring(self._cid)
end

-- Internal logging
function Lib:_log(level, msg, compId)
	local prefix = "[SlaoqUILib]"
	local id = compId and (" ["..tostring(compId).."]") or ""
	local text = string.format("%s %s%s: %s", prefix, level, id, tostring(msg))
	if level == "ERROR" then
		warn(text)
	elseif level == "WARN" then
		warn(text)
	else
		if self and self.cfg and self.cfg.Debug then
			print(text)
		end
	end
end
function Lib:logInfo(msg, compId) self:_log("INFO", msg, compId) end
function Lib:logWarn(msg, compId) self:_log("WARN", msg, compId) end
function Lib:logError(msg, compId) self:_log("ERROR", msg, compId) end

function Lib:_useMiniMode()
	if self._simulateMobile then return true end
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1920,1080)
	local bp = (self.cfg and self.cfg.MiniModeBreakpoint) or 700
	return UserInputService.TouchEnabled or vp.X < bp
end

function Lib:_runSplash()
	local cfg = self.cfg
	local mode = cfg.SplashMode or "splash"

	if mode == "none" then
		local tw2, th2
		if self._computeScale then tw2, th2 = self._computeScale()
		else tw2, th2 = cfg.WindowWidth, cfg.WindowHeight end
		self.Window.Visible = true
		self.Window.Size = UDim2.fromOffset(tw2, th2)
		self.Window.Position = UDim2.fromScale(.5,.5)
		task.defer(function()
			if self._dragHandle and not self:_useMiniMode() then
				self._dragHandle.Visible = true
				if self._syncHandle then self._syncHandle() end
			end
		end)
		return
	elseif mode == "silent" then
		self.Window.Visible = false
		task.spawn(function()
			local tw2, th2
			if self._computeScale then tw2, th2 = self._computeScale()
			else tw2, th2 = cfg.WindowWidth, cfg.WindowHeight end
			self.Window.Visible = true
			self.Window.BackgroundTransparency = 1
			self.Window.Size = UDim2.fromOffset(math.floor(tw2*0.94), math.floor(th2*0.94))
			self.Window.Position = UDim2.new(.5,0,.5,16)
			tw(self.Window,.42,{BackgroundTransparency=0,Size=UDim2.fromOffset(tw2,th2),Position=UDim2.fromScale(.5,.5)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
			task.delay(.5,function()
				if self._dragHandle and not self:_useMiniMode() then
					self._dragHandle.Visible = true
					if self._syncHandle then self._syncHandle() end
				end
			end)
		end)
		return
	end

	self.Window.Visible = false

	local card = new("Frame",{
		AnchorPoint      = Vector2.new(.5,.5),
		Position         = UDim2.new(.5,0,.52,0),
		Size             = UDim2.fromOffset(360,220),
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		ZIndex           = 600,
		BackgroundTransparency = 1,
	}, self._sg)
	corner(card, 18)
	stroke(card, C.Border2, 1)

	local logoBox = new("Frame",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,30),
		Size=UDim2.fromOffset(54,54), BackgroundTransparency=1,
		BorderSizePixel=0, ZIndex=601,
	}, card)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage,ScaleType=Enum.ScaleType.Fit,ZIndex=602},logoBox)
	else
		new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,TextSize=24,TextColor3=C.White,ZIndex=602},logoBox)
	end

	new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,98),
		Size=UDim2.new(1,-32,0,22), BackgroundTransparency=1,
		Text=cfg.AppName, Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=C.White, ZIndex=601, TextTransparency=1,
	}, card)

	new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,122),
		Size=UDim2.new(1,-32,0,15), BackgroundTransparency=1,
		Text=cfg.AppSubtitle, Font=Enum.Font.Gotham, TextSize=11,
		TextColor3=C.TextDim, ZIndex=601, TextTransparency=1,
	}, card)

	local taskLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,152),
		Size=UDim2.new(1,-32,0,14), BackgroundTransparency=1,
		Text=cfg.SplashTasks[1] or "Loading...",
		Font=Enum.Font.Gotham, TextSize=10,
		TextColor3=C.TextOff, ZIndex=601, TextTransparency=1,
	}, card)

	local barBg = new("Frame",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,176),
		Size=UDim2.new(1,-40,0,4), BackgroundColor3=C.Card3,
		BorderSizePixel=0, ZIndex=601,
	}, card)
	corner(barBg, 2)

	local barFill = new("Frame",{
		Size=UDim2.new(0,0,1,0), BackgroundColor3=C.White,
		BorderSizePixel=0, ZIndex=602,
	}, barBg)
	corner(barFill, 2)

	local tasks = cfg.SplashTasks
	local n = #tasks

	task.spawn(function()
		tw(card,.4,{BackgroundTransparency=0,Position=UDim2.fromScale(.5,.5)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		task.wait(.3)
		for _,lbl in ipairs(card:GetChildren()) do
			if lbl:IsA("TextLabel") then tw(lbl,.25,{TextTransparency=0}) end
		end
		task.wait(.25)
		for i,t in ipairs(tasks) do
			tw(taskLbl,.12,{TextTransparency=1})
			task.wait(.1)
			taskLbl.Text = t
			tw(taskLbl,.18,{TextTransparency=0})
			tw(barFill,.5,{Size=UDim2.fromScale(i/n,1)},Enum.EasingStyle.Quint)
			task.wait(.55)
		end
		task.wait(.15)
		tw(card,.3,{BackgroundTransparency=1,Position=UDim2.new(.5,0,.48,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.wait(.32)
		pcall(function() card:Destroy() end)
		local tw2, th2
		if self._computeScale then
			tw2, th2 = self._computeScale()
		else
			tw2, th2 = self.cfg.WindowWidth, self.cfg.WindowHeight
		end
		self.Window.Visible = true
		self.Window.BackgroundTransparency = 1
		self.Window.Size = UDim2.fromOffset(math.floor(tw2*0.9), math.floor(th2*0.9))
		self.Window.Position = UDim2.fromScale(.5,.5)
		tw(self.Window,.45,{BackgroundTransparency=0,Size=UDim2.fromOffset(tw2,th2)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		task.delay(.5, function()
			local isMini = self:_useMiniMode()
			if self._dragHandle and not isMini then
				self._dragHandle.Visible = true
				if self._syncHandle then self._syncHandle() end
			end
		end)
	end)
end

function Lib:_buildWindow()
	local cfg = self.cfg

	local win = new("Frame",{
		Name="Window",
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(cfg.WindowWidth,cfg.WindowHeight),
		BackgroundColor3=C.Bg,
		BorderSizePixel=0,
		ClipsDescendants=false,
	}, self._sg)
	corner(win,12)
	stroke(win,C.Border,1)
	self.Window = win

	local clip = new("Frame",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		ClipsDescendants=true,
	}, win)
	corner(clip,12)
	self._clip = clip

	local function computeScale()
		local cam = workspace.CurrentCamera
		if not cam then return cfg.WindowWidth, cfg.WindowHeight, cfg.SidebarWidth, false end
		local vp  = cam.ViewportSize
		local vpW = vp.X
		local vpH = vp.Y

		local maxW = math.min(cfg.WindowWidth, vpW * 0.94)
		local maxH = math.min(cfg.WindowHeight, vpH * 0.90)

		local sx = maxW / cfg.WindowWidth
		local sy = maxH / cfg.WindowHeight
		local s  = math.min(sx, sy)
		s = math.max(s, 0.38)

		local w  = math.floor(cfg.WindowWidth  * s)
		local h  = math.floor(cfg.WindowHeight * s)
		local sw = math.max(120, math.floor(cfg.SidebarWidth * s))

		local collapsed = sw < 100

		local isTouch = UserInputService.TouchEnabled or (self and self._simulateMobile)
		if isTouch then
			h = math.max(100, h - 52)
		end

		return w, h, sw, collapsed
	end

	local function doScale()
		-- FIX: não redimensionar enquanto escondido — evita cancelar tween do Hide()
		if self._hidden then return end
		local w, h, sw, collapsed = computeScale()
		if not self._minimised then
			win.Size = UDim2.fromOffset(w, h)
		end
		if self._sidebar then
			self._sidebar.Size = UDim2.new(0, sw, 1, 0)
			self:_setCollapsed(collapsed)
		end
	end
	self._doScale   = doScale
	self._computeScale = computeScale

	do
		local function connectCam()
			if self._viewportConn then pcall(function() self._viewportConn:Disconnect() end) end
			local cam = workspace.CurrentCamera
			if not cam then return end
			self._viewportConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				if not self._minimised then doScale() end
			end)
		end
		connectCam()
		table.insert(self._conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			task.defer(function() connectCam(); if not self._minimised then doScale() end end)
		end))
	end

	self:_buildTitleBar(clip)
	self:_buildBody(clip)
	self:_initPages()
	self._pageIdx = -1
	self:SetPage(1)
	task.defer(doScale)

	self._dragActive   = false
	self._dragTargetOX = 0
	self._dragTargetOY = 0

	local dhPillW, dhPillH = 100, 4
	local dh = new("Frame",{
		AnchorPoint = Vector2.new(.5, 0),
		Position    = UDim2.new(.5, 0, .5, 0),
		Size        = UDim2.fromOffset(dhPillW + 24, 22),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Visible = false,
	}, self._sg)
	local dhPill = new("Frame",{
		AnchorPoint = Vector2.new(.5, .5),
		Position    = UDim2.fromScale(.5, .5),
		Size        = UDim2.fromOffset(dhPillW, dhPillH),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
	}, dh)
	corner(dhPill, 3)
	self._dragHandle = dh
	self._syncHandle = function()
		if not dh or not dh.Parent then return end
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920,1080)
		local cx = vp.X * 0.5 + win.Position.X.Offset
		local cy = vp.Y * 0.5 + win.Position.Y.Offset + win.AbsoluteSize.Y * 0.5 + 14
		dh.Position = UDim2.fromOffset(cx, cy)
	end

	local lerpConn = RunService.Heartbeat:Connect(function()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920,1080)
		local tx = self._dragTargetOX
		local ty = self._dragTargetOY
		if self._dragActive then
			local wx = win.Position.X.Offset
			local wy = win.Position.Y.Offset
			local sp = 1
			local nx = wx + (tx - wx) * sp
			local ny = wy + (ty - wy) * sp
			if math.abs(nx - tx) < 0.5 then nx = tx end
			if math.abs(ny - ty) < 0.5 then ny = ty end
			win.Position = UDim2.new(0.5, nx, 0.5, ny)
		end
		if dh.Visible then
			local dhX = vp.X * 0.5 + tx
			local dhY = vp.Y * 0.5 + ty + win.AbsoluteSize.Y * 0.5 + 14
			dh.Position = UDim2.fromOffset(dhX, dhY)
		end
	end)
	table.insert(self._conns, lerpConn)

	do
		local active = false
		local ds, wsOX, wsOY
		dh.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				active = true
				ds = i.Position
				wsOX = win.Position.X.Offset
				wsOY = win.Position.Y.Offset
				self._dragTargetOX = wsOX
				self._dragTargetOY = wsOY
				self._dragActive = true
				tw(dhPill, .1, {BackgroundTransparency=0.2, Size=UDim2.fromOffset(dhPillW+14, dhPillH+2)})
			end
		end)
		dh.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				active = false
				self._dragActive = false
				win.Position = UDim2.new(0.5, self._dragTargetOX, 0.5, self._dragTargetOY)
				tw(dhPill, .18, {BackgroundTransparency=0.55, Size=UDim2.fromOffset(dhPillW, dhPillH)})
			end
		end)
		dh.MouseEnter:Connect(function()
			tw(dhPill, .12, {BackgroundTransparency=0.35, Size=UDim2.fromOffset(dhPillW+8, dhPillH+1)})
		end)
		dh.MouseLeave:Connect(function()
			if not active then
				tw(dhPill, .18, {BackgroundTransparency=0.55, Size=UDim2.fromOffset(dhPillW, dhPillH)})
			end
		end)
		table.insert(self._conns, UserInputService.InputChanged:Connect(function(i)
			if not active then return end
			if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
			local d = i.Position - ds
			local cam3 = workspace.CurrentCamera
			local vp3 = cam3 and cam3.ViewportSize or Vector2.new(1920,1080)
			self._dragTargetOX = math.clamp(wsOX + d.X, -vp3.X/2 + 100, vp3.X/2 - 100)
			self._dragTargetOY = math.clamp(wsOY + d.Y, -vp3.Y/2 + 40, vp3.Y/2 - 40)
		end))
	end
end

function Lib:_buildTitleBar(win)
	local cfg = self.cfg

	local tb = new("Frame",{
		Size=UDim2.new(1,0,0,44),
		BackgroundColor3=C.Bg2,
		BorderSizePixel=0,
		ZIndex=10,
	}, win)
	corner(tb,12)
	self._tbFiller = new("Frame",{Position=UDim2.new(0,0,1,-13),Size=UDim2.new(1,0,0,13),BackgroundColor3=C.Bg2,BorderSizePixel=0,ZIndex=10},tb)
	self._tbBorderLine = new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=10},tb)
	self.TitleBar = tb

	local left = new("Frame",{Size=UDim2.new(1,-188,1,0),BackgroundTransparency=1,ZIndex=11},tb)
	pad(left,0,0,16,0)
	hlist(left,8)

	local logoMini = new("Frame",{Size=UDim2.fromOffset(26,26),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=0},left)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage,ScaleType=Enum.ScaleType.Fit,ZIndex=12},logoMini)
	else
		new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,ZIndex=12},logoMini)
	end

	new("TextLabel",{Text=cfg.AppName,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,
		BackgroundTransparency=1,Size=UDim2.fromOffset(0,26),AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,LayoutOrder=1},left)

	local ver = new("Frame",{Size=UDim2.fromOffset(0,22),AutomaticSize=Enum.AutomaticSize.X,
		BackgroundColor3=C.Card3,BorderSizePixel=0,ZIndex=11,LayoutOrder=2},left)
	corner(ver,6)
	pad(ver,0,0,8,8)
	new("TextLabel",{Text="v"..cfg.AppVersion,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.fromOffset(0,22),AutomaticSize=Enum.AutomaticSize.X,ZIndex=12},ver)

	local right = new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
		Size=UDim2.fromOffset(188,44),BackgroundTransparency=1,ZIndex=11},tb)
	hlist(right,0)

	local function mkBtn(sym,hc,cb,lo)
		local b = new("TextButton",{Text=sym,Font=Enum.Font.GothamBold,TextSize=18,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromOffset(44,44),ZIndex=12,AutoButtonColor=false,LayoutOrder=lo},right)
		b.MouseEnter:Connect(function() tw(b,.12,{TextColor3=C.White,BackgroundTransparency=.9}) end)
		b.MouseLeave:Connect(function() tw(b,.15,{TextColor3=C.TextDim,BackgroundTransparency=1}) end)
		b.Activated:Connect(cb)
		return b
	end

	do
		local w = new("Frame",{Size=UDim2.fromOffset(44,44),BackgroundTransparency=1,ZIndex=12,LayoutOrder=0},right)
		local img = new("ImageLabel",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
			Size=UDim2.fromOffset(20,20),BackgroundTransparency=1,
			Image="rbxassetid://118685771787843",
			ImageColor3=C.Text,ScaleType=Enum.ScaleType.Fit,ZIndex=13},w)
		local btn = new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=14,AutoButtonColor=false},w)
		btn.MouseEnter:Connect(function() tw(img,.12,{ImageColor3=C.White}); tw(w,.12,{BackgroundTransparency=.93}) end)
		btn.MouseLeave:Connect(function() tw(img,.15,{ImageColor3=C.Text}); tw(w,.15,{BackgroundTransparency=1}) end)
		btn.Activated:Connect(function()
			if not self:_debounce("search_toggle",0.2) then return end
			self:_toggleSearch()
		end)
		self._searchBtnImg = img
		self._searchBtnFb  = nil
	end

	do
		local w = new("Frame",{Size=UDim2.fromOffset(44,44),BackgroundTransparency=1,ZIndex=12,LayoutOrder=1},right)
		local img = new("ImageLabel",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
			Size=UDim2.fromOffset(20,20),BackgroundTransparency=1,
			Image="rbxassetid://7059346373",
			ImageColor3=C.Text,ScaleType=Enum.ScaleType.Fit,ZIndex=13},w)
		local btn = new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=14,AutoButtonColor=false},w)
		btn.MouseEnter:Connect(function() tw(img,.12,{ImageColor3=C.White}); tw(w,.12,{BackgroundTransparency=.93}) end)
		btn.MouseLeave:Connect(function() tw(img,.15,{ImageColor3=C.Text}); tw(w,.15,{BackgroundTransparency=1}) end)
		btn.Activated:Connect(function()
			if not self:_debounce("settings_toggle",0.15) then return end
			self:_openSettings()
		end)
		self._gearImg = img
		self._gearFb  = nil
	end

	do
		local b = new("TextButton",{Text=self._minimised and "+" or "-",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=C.White,
			BackgroundTransparency=1,Size=UDim2.fromOffset(44,44),ZIndex=12,AutoButtonColor=false,LayoutOrder=2},right)
		b.MouseEnter:Connect(function() tw(b,.12,{TextColor3=C.White,BackgroundTransparency=.9}) end)
		b.MouseLeave:Connect(function() tw(b,.15,{TextColor3=C.White,BackgroundTransparency=1}) end)
		b.MouseButton1Down:Connect(function() tw(b,.08,{TextSize=15}) end)
		b.MouseButton1Up:Connect(function() tw(b,.12,{TextSize=18},Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
		b.Activated:Connect(function()
			if not self:_debounce("min_toggle",0.15) then return end
			if self._minimised then self:Maximise() else self:Minimise() end
		end)
		self._minBtn = b
		self._minImg = nil
		self._minFb  = b
	end

	do
		local b = new("TextButton",{Text="x",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromOffset(44,44),ZIndex=12,AutoButtonColor=false,LayoutOrder=3},right)
		b.MouseEnter:Connect(function() tw(b,.1,{TextColor3=C.Red,BackgroundTransparency=.9}) end)
		b.MouseLeave:Connect(function() tw(b,.15,{TextColor3=C.TextDim,BackgroundTransparency=1}) end)
		b.MouseButton1Down:Connect(function() tw(b,.08,{TextSize=15}) end)
		b.MouseButton1Up:Connect(function() tw(b,.12,{TextSize=18},Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
		b.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch then
				tw(b,.08,{TextColor3=C.Red,BackgroundTransparency=.93})
			end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch then
				tw(b,.15,{TextColor3=C.TextDim,BackgroundTransparency=1})
			end
		end)
		b.Activated:Connect(function()
			if not self:_debounce("hide_window",0.2) then return end
			self:Hide()
		end)
	end

	do
		local drag = false
		local dragged = false
		local ds, wsX, wsY
		local DRAG_DEADZONE = 4
		tb.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				-- Skip drag when clicking button area on the right (last 196px = 4×44 + 20 margin)
				local relX = i.Position.X - tb.AbsolutePosition.X
				if relX > tb.AbsoluteSize.X - 196 then return end
				drag = true
				dragged = false
				ds = i.Position
				wsX = self.Window.Position.X.Offset
				wsY = self.Window.Position.Y.Offset
			end
		end)
		tb.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				drag = false
				if self._syncHandle then self._syncHandle() end
			end
		end)
		table.insert(self._conns, UserInputService.InputChanged:Connect(function(i)
			if not drag then return end
			if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
			local d = i.Position - ds
			if not dragged then
				if math.abs(d.X) < DRAG_DEADZONE and math.abs(d.Y) < DRAG_DEADZONE then return end
				dragged = true
			end
			local nx = wsX + d.X
			local ny = wsY + d.Y
			local vp2 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
			nx = math.clamp(nx, -vp2.X/2 + 100, vp2.X/2 - 100)
			ny = math.clamp(ny, -vp2.Y/2 + 40, vp2.Y/2 - 40)
			self.Window.Position = UDim2.new(0.5, nx, 0.5, ny)
			self._dragTargetOX = nx
			self._dragTargetOY = ny
		end))
	end
end

function Lib:_buildBody(win)
	local cfg = self.cfg

	local body = new("Frame",{Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,1,-44),BackgroundTransparency=1},win)
	self._body = body

	local sidebar = new("Frame",{Size=UDim2.new(0,cfg.SidebarWidth,1,0),BackgroundColor3=C.Sidebar,BorderSizePixel=0,ClipsDescendants=true,ZIndex=5},body)
	new("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=6},sidebar)
	self._sidebar = sidebar

	local ss = new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
		ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},sidebar)
	vlist(ss,0,Enum.HorizontalAlignment.Center)
	pad(ss,18,18,8,8)

	local logoArea = new("Frame",{Size=UDim2.new(1,0,0,104),BackgroundTransparency=1,LayoutOrder=0},ss)
	self._logoArea = logoArea
	local logoWrap = new("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),
		Size=UDim2.fromOffset(52,52),BackgroundTransparency=1,BorderSizePixel=0},logoArea)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage,ScaleType=Enum.ScaleType.Fit},logoWrap)
	else
		new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,TextSize=23,TextColor3=C.White},logoWrap)
	end

	self._sideNameLbl = new("TextLabel",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,60),
		Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=cfg.AppName,
		Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,TextTruncate=Enum.TextTruncate.AtEnd},logoArea)
	self._sideSubLbl = new("TextLabel",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,80),
		Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=cfg.AppSubtitle,
		Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,TextTruncate=Enum.TextTruncate.AtEnd},logoArea)

	local divArea = new("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=1},ss)
	new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.new(.8,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},divArea)

	-- Barra na borda ESQUERDA do sidebar
	local bar = new("Frame",{Size=UDim2.fromOffset(3,0),AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.new(0,0,0,100),BackgroundColor3=accentOrWhite(self),BorderSizePixel=0,ZIndex=9,Visible=false},sidebar)
	corner(bar,2)
	self._bar = bar
	self._barAnimGen = 0

	local pageIndex = 0
	local function addNavBtn(page, parent, indented)
		pageIndex = pageIndex + 1
		self:_makeNavBtn(page, pageIndex, parent, indented)
	end

	for _, entry in ipairs(cfg.Pages) do
		if entry.Group then
			local groupPages = entry.Pages or {}
			local groupOpen = entry.DefaultOpen ~= false

			local grpBtn = new("TextButton",{
				Text="",BackgroundTransparency=1,
				Size=UDim2.new(1,0,0,36),LayoutOrder=pageIndex,
				AutoButtonColor=false,ZIndex=6,
			},ss)
			pad(grpBtn,0,0,10,10)

			local arrow=new("TextLabel",{Text="v",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
				BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
				Size=UDim2.fromOffset(18,18),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7},grpBtn)
			new("TextLabel",{Text=string.upper(entry.Group),Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
				BackgroundTransparency=1,Size=UDim2.new(1,-22,1,0),
				TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},grpBtn)

			local subContainer=new("Frame",{
				Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
				BackgroundTransparency=1,BorderSizePixel=0,
				Visible=groupOpen,
				LayoutOrder=pageIndex+1,
			},ss)
			new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},subContainer)

			for _, page in ipairs(groupPages) do
				addNavBtn(page, subContainer, true)
			end

			grpBtn.Activated:Connect(function()
				if not self:_debounce("group_"..tostring(entry.Group),0.2) then return end
				groupOpen = not groupOpen
				subContainer.Visible = groupOpen
				tw(arrow,.2,{Rotation=groupOpen and 0 or -90})
			end)
			if not groupOpen then arrow.Rotation=-90 end
		else
			addNavBtn(entry, ss, false)
		end
	end
	new("Frame",{Size=UDim2.fromOffset(1,14),BackgroundTransparency=1,LayoutOrder=pageIndex+10},ss)

	local content = new("Frame",{Position=UDim2.new(0,cfg.SidebarWidth,0,0),
		Size=UDim2.new(1,-cfg.SidebarWidth,1,0),BackgroundColor3=C.Bg2,BorderSizePixel=0,ClipsDescendants=true},body)
	self._content = content

	local sbH = 48
	local searchBar = new("Frame",{
		Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Card,
		BorderSizePixel=0,ZIndex=20,ClipsDescendants=true,
	}, content)
	new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=21},searchBar)

	new("ImageLabel",{
		AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,12,.5,0),
		Size=UDim2.fromOffset(16,16),BackgroundTransparency=1,
		Image="rbxassetid://118685771787843",
		ImageColor3=C.Text,ScaleType=Enum.ScaleType.Fit,ZIndex=22,
	}, searchBar)

	local searchBox = new("TextBox",{
		AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,36,.5,0),
		Size=UDim2.new(1,-60,0,30),
		Text="",PlaceholderText="Search in page... (Ctrl+F)",
		Font=Enum.Font.Gotham,TextSize=13,
		TextColor3=C.Text,PlaceholderColor3=C.TextOff,
		BackgroundTransparency=1,ClearTextOnFocus=false,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=22,
	}, searchBar)

	local resultLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-118,.5,0),
		Size=UDim2.fromOffset(58,30),
		Text="",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TextDim,
		BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=22,Visible=false,
	}, searchBar)

	local navUp = new("TextButton",{
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-84,.5,0),
		Size=UDim2.fromOffset(26,26),
		Text="",BackgroundColor3=C.Card3,BorderSizePixel=0,AutoButtonColor=false,ZIndex=22,Visible=false,
	}, searchBar)
	corner(navUp,6)
	do
		local img=new("ImageLabel",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
			Size=UDim2.fromOffset(14,14),BackgroundTransparency=1,
			Image="rbxasset://textures/ui/ArrowUp.png",
			ImageColor3=C.TextDim,ScaleType=Enum.ScaleType.Fit,ZIndex=23},navUp)
		local fb=new("TextLabel",{Text="^",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=23},navUp)
		img:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if img.IsLoaded and img.AbsoluteSize.X > 0 then fb.Visible = false end
		end)
		task.defer(function() if img.IsLoaded then fb.Visible = false end end)
	end

	local navDown = new("TextButton",{
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-54,.5,0),
		Size=UDim2.fromOffset(26,26),
		Text="",BackgroundColor3=C.Card3,BorderSizePixel=0,AutoButtonColor=false,ZIndex=22,Visible=false,
	}, searchBar)
	corner(navDown,6)
	do
		local img=new("ImageLabel",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
			Size=UDim2.fromOffset(14,14),BackgroundTransparency=1,
			Image="rbxasset://textures/ui/ArrowDown.png",
			ImageColor3=C.TextDim,ScaleType=Enum.ScaleType.Fit,ZIndex=23},navDown)
		local fb=new("TextLabel",{Text="v",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=23},navDown)
		img:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if img.IsLoaded and img.AbsoluteSize.X > 0 then fb.Visible = false end
		end)
		task.defer(function() if img.IsLoaded then fb.Visible = false end end)
	end

	local closeSearchBtn = new("TextButton",{
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),
		Size=UDim2.fromOffset(28,28),
		Text="x",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TextDim,
		BackgroundTransparency=1,AutoButtonColor=false,ZIndex=22,
	}, searchBar)
	closeSearchBtn.MouseEnter:Connect(function() tw(closeSearchBtn,.1,{TextColor3=C.Red}) end)
	closeSearchBtn.MouseLeave:Connect(function() tw(closeSearchBtn,.12,{TextColor3=C.TextDim}) end)

	for _,nb in ipairs({navUp,navDown}) do
		nb.MouseEnter:Connect(function() tw(nb,.1,{BackgroundColor3=C.Card2,TextColor3=C.White}) end)
		nb.MouseLeave:Connect(function() tw(nb,.12,{BackgroundColor3=C.Card3,TextColor3=C.TextDim}) end)
	end

	self._searchBar       = searchBar
	self._searchBox       = searchBox
	self._searchResultLbl = resultLbl
	self._searchNavUp     = navUp
	self._searchNavDown   = navDown
	self._searchOpen      = false
	self._searchHighlights = {}
	self._searchIdx       = 0

	-- (assignments above are canonical; no duplicate needed)

	local pagesWrap = new("Frame",{
		Position=UDim2.fromOffset(0,0),Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,ClipsDescendants=false,
	}, content)
	self._pagesWrap = pagesWrap

	table.insert(self._conns, sidebar:GetPropertyChangedSignal("Size"):Connect(function()
		local sw = sidebar.Size.X.Offset
		content.Position = UDim2.new(0,sw,0,0)
		content.Size     = UDim2.new(1,-sw,1,0)
	end))

	local nh = new("Frame",{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-10),
		Size=UDim2.new(.65,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=200},win)
	vlist(nh,6)
	self._notifHolder = nh

	closeSearchBtn.Activated:Connect(function()
		if not self:_debounce("search_close",0.15) then return end
		self:_closeSearch()
	end)
	navUp.Activated:Connect(function()
		if not self:_debounce("search_nav",0.12) then return end
		self:_searchNavigate(-1)
	end)
	navDown.Activated:Connect(function()
		if not self:_debounce("search_nav",0.12) then return end
		self:_searchNavigate(1)
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local ts = os.clock()
		self._searchDebounceTS = ts
		task.delay(0.08, function()
			if self._searchDebounceTS ~= ts then return end
			self:_doSearch(searchBox.Text)
		end)
	end)
	searchBox.FocusLost:Connect(function(enter)
		if enter then self:_doSearch(searchBox.Text) end
	end)
end

function Lib:_makeNavBtn(page,index,parent,indented)
	local fh = (UserInputService.TouchEnabled) and 48 or 40
	local frame = new("Frame",{Size=UDim2.new(1,0,0,fh),BackgroundTransparency=1,LayoutOrder=index},parent)

	local bg = new("Frame",{Size=UDim2.new(1,-8,1,-4),Position=UDim2.fromOffset(4,2),
		BackgroundColor3=C.Card2,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5},frame)
	corner(bg,8)

	local hasIcon = page.Icon and tostring(page.Icon) ~= ""
	local iconId = hasIcon and tostring(page.Icon) or nil

	local dotX = indented and 30 or 22
	local lblX = indented and 44 or 36
	local dot = new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,dotX,.5,0),
		Size=UDim2.fromOffset(6,6),BackgroundColor3=C.TextOff,BorderSizePixel=0,ZIndex=6,
		Visible=not hasIcon},frame)
	corner(dot,3)

	if hasIcon then
		local iconFrame = new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,dotX,.5,0),
			Size=UDim2.fromOffset(20,20),BackgroundTransparency=1,ZIndex=6},frame)
		local img = new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
			Image="rbxassetid://"..iconId,ImageColor3=C.TextDim,ScaleType=Enum.ScaleType.Fit,ZIndex=6},iconFrame)
		do
			local loaded = false
			img:GetPropertyChangedSignal("IsLoaded"):Connect(function()
				if img.IsLoaded then loaded = true end
			end)
			task.delay(2, function()
				if loaded or not img.Parent then return end
				-- Image failed to load after 2s - show letter fallback
				img.Image = ""
				new("TextLabel",{Text=string.upper(string.sub(page.Name,1,1)),
					Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.TextDim,
					BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
					TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7},iconFrame)
			end)
		end
		dot = {
			_img=img,
			_frame=iconFrame,
			_isIcon=true,
		}
		setmetatable(dot, {
			__index=function(t,k)
				if k=="BackgroundColor3" then return nil end
				return rawget(t,k)
			end
		})
		dot.setColor = function(col)
			if img and img.Parent then img.ImageColor3=col end
		end
		dot.setSize = function() end
	end

	local lbl = new("TextLabel",{Text=page.Name,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TextDim,
		BackgroundTransparency=1,Position=UDim2.fromOffset(lblX,0),Size=UDim2.new(1,-(lblX+8),1,0),
		TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=6},frame)

	local click = new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=7,AutoButtonColor=false},frame)
	pcall(function() click.CursorIcon = "rbxasset://SystemCursors/PointingHand" end)

	local function setDotColor(col)
		if hasIcon then
			if dot._img and dot._img.Parent then dot._img.ImageColor3=col end
		else
			tw(dot,.15,{BackgroundColor3=col})
		end
	end
	local function setDotSize(sz)
		if not hasIcon then
			tw(dot,.15,{Size=UDim2.fromOffset(sz,sz)})
		end
	end

	-- Tooltip for collapsed sidebar
	local tooltip = new("TextLabel",{
		Text=page.Name,
		Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.White,
		BackgroundColor3=C.Card2,BorderSizePixel=0,
		Size=UDim2.fromOffset(0,26),AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Left,
		Position=UDim2.new(1,8,.5,-13),
		AnchorPoint=Vector2.new(0,.5),
		ZIndex=20,Visible=false,
	},frame)
	corner(tooltip,6)
	stroke(tooltip,C.Border2,1)
	pad(tooltip,0,0,8,8)

	click.MouseEnter:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.12,{BackgroundTransparency=.9})
			tw(lbl,.12,{TextColor3=C.White})
			setDotColor(C.TextDim); setDotSize(7)
		end
		-- Show tooltip when sidebar is narrow (collapsed)
		if self._sidebar and self._sidebar.Size.X.Offset < 100 then
			tooltip.Visible = true
		end
	end)
	click.MouseLeave:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.15,{BackgroundTransparency=1})
			tw(lbl,.15,{TextColor3=C.TextDim})
			setDotColor(C.TextOff); setDotSize(6)
		end
		tooltip.Visible = false
	end)
	click.Activated:Connect(function()
		if not self:_debounce("nav_"..tostring(index),0.2) then return end
		if self._pageIdx == index and not self._settingsVisible then return end
		self:SetPage(index)
	end)
	self._navBtns[index] = {Frame=frame,Bg=bg,Lbl=lbl,Dot=dot,HasIcon=hasIcon,SetDotColor=setDotColor,SetDotSize=setDotSize,_dotX=dotX}
end

function Lib:_initPages()
	for i=1,#self.cfg.Pages do
		local frame = new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},self._pagesWrap)
		local scroll = new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
			ScrollBarThickness=5,ScrollBarImageColor3=C.Border3,ScrollBarImageTransparency=.2,
			CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
			ElasticBehavior=Enum.ElasticBehavior.Never},frame)
		new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},scroll)
		pad(scroll,16,24,16,16)
		self._pages[i] = {Frame=frame,Scroll=scroll}
		self._ord[i]   = 0
	end
end

function Lib:SetPage(index)
	if not self:_isAlive() then return end
	local cfg = self.cfg
	if index == self._pageIdx and not self._settingsVisible then return end
	self._pageGen = (self._pageGen or 0) + 1
	local gen = self._pageGen
	if self._settingsVisible then
		self._settingsVisible = false
		if self._settingsFrame then self._settingsFrame.Visible = false end
		if self._gearImg then tw(self._gearImg,.15,{ImageColor3=C.Text}) end
		
		if self._bar then self._bar.Visible = true end
	end
	self:_clearHighlights()
	if self._searchBox and self._searchBox.Text ~= "" then self._searchBox.Text = "" end
	if self._searchResultLbl then self._searchResultLbl.Text = "" end
	local oldFrame = self._pages[self._pageIdx] and self._pages[self._pageIdx].Frame
	local newFrame = self._pages[index] and self._pages[index].Frame
	local old = self._navBtns[self._pageIdx]
	if old then
		tw(old.Lbl,cfg.TweenSpeed,{TextColor3=C.TextDim})
		tw(old.Bg,cfg.TweenSpeed,{BackgroundTransparency=1})
		if old.SetDotColor then old.SetDotColor(C.TextOff) else tw(old.Dot,cfg.TweenSpeed,{BackgroundColor3=C.TextOff,Size=UDim2.fromOffset(6,6)}) end
	end
	self._pageIdx = index
	local fadeDelay = 0
	if oldFrame and oldFrame.Visible then
		fadeDelay = 0.2
		local ofs = oldFrame:FindFirstChildWhichIsA("ScrollingFrame")
		if ofs then
			tw(ofs, .18, {Position=UDim2.new(0,0,0,10)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		end
		task.delay(.2, function()
			if gen ~= self._pageGen then return end
			if oldFrame and oldFrame.Parent then
				oldFrame.Visible = false
				if ofs and ofs.Parent then
					ofs.Position = UDim2.fromOffset(0,0)
				end
			end
		end)
	end
	if newFrame then
		local nfs = newFrame:FindFirstChildWhichIsA("ScrollingFrame")
		newFrame.Visible = false
		task.delay(fadeDelay, function()
			if gen ~= self._pageGen then return end
			if not newFrame or not newFrame.Parent then return end
			if nfs and nfs.Parent then
				nfs.Position = UDim2.new(0,0,0,20)
			end
			newFrame.Visible = true
			if nfs then
				tw(nfs, .3, {Position=UDim2.fromOffset(0,0)}, Enum.EasingStyle.Quint)
			end
			if gen == self._pageGen then
				for i,p in ipairs(self._pages) do
					if p and p.Frame then p.Frame.Visible = (i == index) end
				end
			end
		end)
	end
	local nb = self._navBtns[index]
	if nb then
		tw(nb.Lbl,cfg.TweenSpeed,{TextColor3=C.White})
		tw(nb.Bg,cfg.TweenSpeed,{BackgroundTransparency=.76})
		if nb.SetDotColor then nb.SetDotColor(accentOrWhite(self)) else tw(nb.Dot,cfg.TweenSpeed,{BackgroundColor3=accentOrWhite(self),Size=UDim2.fromOffset(7,7)}) end
		self:_animBar(nb.Frame)
	end
	task.defer(function() self:SaveState() end)
end

function Lib:_animBar(target)
	if not self:_isAlive() then return end
	local bar = self._bar
	if not bar or not target then return end

	local ok, relY = pcall(function()
		local ap = target.AbsolutePosition
		local as = target.AbsoluteSize
		local sp = self._sidebar.AbsolutePosition
		if as.Y == 0 then error("Unrendered") end
		return ap.Y - sp.Y + as.Y * .5
	end)
	if not ok then
		task.defer(function()
			if self:_isAlive() then self:_animBar(target) end
		end)
		return
	end

	-- Incrementa geração para cancelar qualquer animação anterior em andamento
	self._barAnimGen = (self._barAnimGen or 0) + 1
	local gen = self._barAnimGen

	local BAR_H    = 32   -- altura total da barra expandida
	local BAR_W    = 3    -- largura da barra
	local SPEED    = self.cfg.BarTweenSpeed or 0.22

	-- Destino final: centro Y do item selecionado, borda direita do sidebar
	local destY = relY  -- posição Y central (AnchorPoint Y=.5 cuida do offset)

	bar.Visible = true

	if bar.Size.Y.Offset < 2 then
		-- Primeira vez: apenas expande direto no destino, sem colapsar
		bar.Position = UDim2.new(0, 0, 0, destY)
		bar.Size     = UDim2.fromOffset(BAR_W, 0)
		-- Expande do centro para fora (ambas as pontas simultaneamente via Size + AnchorPoint Y=.5)
		tw(bar, SPEED * 1.1, {Size = UDim2.fromOffset(BAR_W, BAR_H)},
			Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		return
	end

	-- === Fase 1: colapsar a barra atual das duas pontas até sumir ===
	-- AnchorPoint Y=.5 → reduzir Height colapsa para o centro da barra
	local collapseTime = SPEED * 0.7
	tw(bar, collapseTime, {Size = UDim2.fromOffset(BAR_W, 0)},
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	-- === Fase 2: mover (invisível) e expandir no novo destino ===
	task.delay(collapseTime, function()
		if gen ~= self._barAnimGen then return end
		if not bar or not bar.Parent then return end

		-- Teleporta para o novo Y enquanto está colapsada (tamanho 0, invisível)
		bar.Position = UDim2.new(0, 0, 0, destY)

		-- Expande das duas pontas para fora com Back easing (efeito elástico profissional)
		tw(bar, SPEED * 1.15, {Size = UDim2.fromOffset(BAR_W, BAR_H)},
			Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
end

function Lib:_setCollapsed(collapsed)
	if self._sideNameLbl then self._sideNameLbl.Visible = not collapsed end
	if self._sideSubLbl  then self._sideSubLbl.Visible  = not collapsed end
	for _,nb in ipairs(self._navBtns) do
		if not nb then continue end
		local rowH = UserInputService.TouchEnabled and 48 or 40
		if nb.Lbl then nb.Lbl.Visible = not collapsed end
		if nb.Frame then
			nb.Frame.Size = UDim2.new(1, 0, 0, rowH)
		end
		-- Reposition dot/icon: left-aligned (16px) when collapsed, restore original X when expanded
		if collapsed then
			if nb.HasIcon and nb.Dot and nb.Dot._frame then
				nb.Dot._frame.AnchorPoint = Vector2.new(.5, .5)
				nb.Dot._frame.Position = UDim2.new(0, 16, .5, 0)
				nb.Dot._frame.Size = UDim2.fromOffset(20, 20)
			elseif nb.Dot and type(nb.Dot) ~= "table" then
				nb.Dot.AnchorPoint = Vector2.new(.5, .5)
				tw(nb.Dot, .15, {Size=UDim2.fromOffset(8,8), Position=UDim2.new(0,16,.5,0)})
			end
		else
			local ox = nb._dotX or 22
			if nb.HasIcon and nb.Dot and nb.Dot._frame then
				nb.Dot._frame.AnchorPoint = Vector2.new(.5, .5)
				nb.Dot._frame.Position = UDim2.new(0, ox, .5, 0)
				nb.Dot._frame.Size = UDim2.fromOffset(20, 20)
			elseif nb.Dot and type(nb.Dot) ~= "table" then
				nb.Dot.AnchorPoint = Vector2.new(.5, .5)
				tw(nb.Dot, .15, {Size=UDim2.fromOffset(6,6), Position=UDim2.new(0,ox,.5,0)})
			end
		end
	end
	if self._logoArea then
		self._logoArea.Visible = not collapsed
	end
end

function Lib:_ensurePill()
	if self._mobilePill then return end
	local cfg = self.cfg
	local pill = new("Frame",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,24),
		Size=UDim2.fromOffset(0,38),
		AutomaticSize=Enum.AutomaticSize.X,
		BackgroundColor3=fromHex("111111"),
		BackgroundTransparency=0.18,
		BorderSizePixel=0,
		ZIndex=800,
		Visible=false,
	}, self._sg)
	corner(pill,999)
	stroke(pill,C.Border2,1)

	local pillInner = new("Frame",{
		BackgroundTransparency=1,
		Size=UDim2.fromOffset(0,38),
		AutomaticSize=Enum.AutomaticSize.X,
		ZIndex=801,
	},pill)
	hlist(pillInner,6)
	pad(pillInner,0,0,12,12)

	if cfg.LogoImage ~= "" then
		new("ImageLabel",{
			Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,
			Image=cfg.LogoImage,ScaleType=Enum.ScaleType.Fit,
			ZIndex=801,LayoutOrder=0,
		},pillInner)
	end

	new("TextLabel",{
		Text="Show Interface",
		Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,
		BackgroundTransparency=1,
		Size=UDim2.fromOffset(0,38),
		AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Left,
		ZIndex=801,LayoutOrder=1,
	},pillInner)

	local pillBtn = new("TextButton",{
		Text="",BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ZIndex=802,AutoButtonColor=false,
	},pill)

	local dragging=false; local ds, px0, py0

	local function clampPill()
		if not pill or not pill.Parent then return end
		local cam=workspace.CurrentCamera
		local vp=cam and cam.ViewportSize or Vector2.new(1920,1080)
		local pw=pill.AbsoluteSize.X
		local ph=pill.AbsoluteSize.Y
		local cx=pill.Position.X.Offset
		local cy=pill.Position.Y.Offset
		local ncx=math.clamp(cx, pw*0.5, vp.X-pw*0.5)
		local ncy=math.clamp(cy, 10, vp.Y-ph-10)
		if ncx~=cx or ncy~=cy then
			pill.Position=UDim2.new(0,ncx,0,ncy)
		end
	end

	-- Safe camera connection — CurrentCamera can be nil at load time
	local function connectPillCam()
		local cam = workspace.CurrentCamera
		if not cam then return end
		if self._pillCamConn then
			pcall(function() self._pillCamConn:Disconnect() end)
		end
		self._pillCamConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			task.defer(clampPill)
		end)
	end
	connectPillCam()
	table.insert(self._conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(connectPillCam)
		task.defer(clampPill)
	end))

	pillBtn.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			ds=i.Position
			px0=pill.Position.X.Offset
			py0=pill.Position.Y.Offset
		end
	end)
	pillBtn.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			local moved=dragging and ds and (math.abs(i.Position.X-ds.X)>6 or math.abs(i.Position.Y-ds.Y)>6)
			dragging=false
			if moved then
				-- snap pill to nearest horizontal edge
				local cam2=workspace.CurrentCamera
				local vp2=cam2 and cam2.ViewportSize or Vector2.new(1920,1080)
				local pw2=pill.AbsoluteSize.X
				local cx=pill.Position.X.Offset
				local nx2 = cx < vp2.X/2 and 20 or (vp2.X - pw2 - 20)
				tw(pill,.18,{Position=UDim2.new(0,nx2,0,pill.Position.Y.Offset)},Enum.EasingStyle.Quint)
			end
			if not moved then
				self:Show()
			end
		end
	end)
	table.insert(self._conns,UserInputService.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
		local cam=workspace.CurrentCamera
		local vp=cam and cam.ViewportSize or Vector2.new(1920,1080)
		local d=i.Position-ds
		local pw=pill.AbsoluteSize.X
		local ph=pill.AbsoluteSize.Y
		local nx=math.clamp(px0+d.X, pw*0.5, vp.X-pw*0.5)
		local ny=math.clamp(py0+d.Y, 20, vp.Y-ph-20)
		-- snap lateral when drag ends (handled in InputEnded)
		pill.Position=UDim2.new(0,nx,0,ny)
	end))

	pill.MouseEnter:Connect(function() tw(pill,.15,{BackgroundTransparency=0.05}) end)
	pill.MouseLeave:Connect(function() tw(pill,.18,{BackgroundTransparency=0.18}) end)
	pillBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			tw(pill,.08,{BackgroundTransparency=0.0})
		end
	end)
	pillBtn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			tw(pill,.2,{BackgroundTransparency=0.18})
		end
	end)

	self._mobilePill = pill
end

function Lib:Minimise()
	if self._minimised then return end
	self._minimised = true
	self._dragActive = false
	if self._searchOpen then self:_closeSearch() end

	local win  = self.Window
	local mini = self:_useMiniMode()
	self._miniWasUsed = mini

	if mini then
		if self.cfg.ShowPill ~= false then self:_ensurePill() end
		local pill = self._mobilePill
		local ws = win.AbsoluteSize
		local wox = win.Position.X.Offset
		local woy = win.Position.Y.Offset
		tw(win,.3,{
			BackgroundTransparency=1,
			Size=UDim2.fromOffset(ws.X*0.92, ws.Y*0.88),
			Position=UDim2.new(.5,wox,.5,woy+36),
		},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.32,function()
			if win and win.Parent then
				win.Visible=false
				win.Size=UDim2.fromOffset(ws.X,ws.Y)
				win.Position=UDim2.new(.5,wox,.5,woy)
				win.BackgroundTransparency=0
			end
		end)
		if pill then
			local cam=workspace.CurrentCamera
			local vp=cam and cam.ViewportSize or Vector2.new(1920,1080)
			pill.Visible=true
			pill.Position=UDim2.new(0,math.floor(vp.X*0.5),0,-60)
			pill.BackgroundTransparency=1
			tw(pill,.38,{Position=UDim2.new(0,math.floor(vp.X*0.5),0,24),BackgroundTransparency=0.18},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		end
	else
		self._preMinSize = {W=win.AbsoluteSize.X, H=win.AbsoluteSize.Y}
		if self._tbFiller then self._tbFiller.Visible = false end
		if self._tbBorderLine then self._tbBorderLine.Visible = false end
		win.BackgroundColor3 = C.Bg2
		local minBarW = math.min(self._preMinSize.W, 340)
		tw(win,.35,{Size=UDim2.fromOffset(minBarW, 44)},Enum.EasingStyle.Quint)
		task.delay(.37,function()
			if self._body then self._body.Visible = false end
		end)
		
		if self._minFb  then self._minFb.Text  = "+" end
		if self._dragHandle then self._dragHandle.Visible = false end
	end
end

function Lib:Maximise()
	if not self._minimised then return end
	self._minimised = false
	self._dragActive = false

	local win  = self.Window
	local mini = self._miniWasUsed

	if mini then
		local pill = self._mobilePill
		if pill then
			tw(pill,.2,{Position=UDim2.new(.5,0,0,-60),BackgroundTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			task.delay(.22,function()
				if pill and pill.Parent then pill.Visible=false end
			end)
		end
		win.Visible=true
		win.BackgroundTransparency=1
		win.Position = UDim2.fromScale(.5,.5)
		tw(win,.32,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
	else
		local targetW, targetH, sw, collapsed
		if self._computeScale then
			targetW, targetH, sw, collapsed = self._computeScale()
		else
			targetW, targetH, sw, collapsed = self.cfg.WindowWidth, self.cfg.WindowHeight, self.cfg.SidebarWidth, false
		end
		if self._body then self._body.Visible = true end
		win.BackgroundColor3 = C.Bg
		if self._tbFiller then self._tbFiller.Visible = true end
		if self._tbBorderLine then self._tbBorderLine.Visible = true end
		win.Position = UDim2.fromScale(.5,.5)
		self._dragTargetOX = 0
		self._dragTargetOY = 0
		if self._sidebar and sw then
			self._sidebar.Size = UDim2.new(0, sw, 1, 0)
			self:_setCollapsed(collapsed)
		end
		tw(win, .38, {Size=UDim2.fromOffset(targetW, targetH)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if self._minFb then self._minFb.Text = "-" end
		if self._dragHandle and not self:_useMiniMode() then
			self._dragHandle.Visible = true
			if self._syncHandle then self._syncHandle() end
		end
	end
end

function Lib:ToggleVisibility()
	if self._hidden or self._minimised then
		self:Show()
	else
		self:Hide()
	end
end

function Lib:Hide()
	if self._hidden then return end
	self._hidden = true
	self._dragActive = false
	if self._searchOpen then self:_closeSearch() end
	local win = self.Window
	if not win then return end
	-- If minimised, restore the full window first so the fade-out looks correct
	if self._minimised then
		self._minimised = false
		if self._minFb then self._minFb.Text = "-" end
		if self._body then self._body.Visible = true end
		win.BackgroundColor3 = C.Bg
		if self._tbFiller then self._tbFiller.Visible = true end
		if self._tbBorderLine then self._tbBorderLine.Visible = true end
		local tw2, th2
		if self._computeScale then tw2, th2 = self._computeScale()
		else tw2, th2 = self.cfg.WindowWidth, self.cfg.WindowHeight end
		win.Size = UDim2.fromOffset(tw2, th2)
	end
	-- FIX: usar geração para que Show() cancele o task.delay pendente
	self._hideGen = (self._hideGen or 0) + 1
	local gen = self._hideGen
	local ws = win.AbsoluteSize
	tw(win, .25, {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(ws.X * 0.93, ws.Y * 0.93),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	task.delay(.28, function()
		-- FIX: só esconde se ainda for a mesma operação de Hide (Show() não foi chamado)
		if gen ~= self._hideGen then return end
		if self._hidden and win and win.Parent then win.Visible = false end
	end)
	if self._dragHandle then self._dragHandle.Visible = false end

	local useMini = self:_useMiniMode()
	if useMini then
		if self.cfg.ShowPill ~= false then self:_ensurePill() end
		local pill = self._mobilePill
		if pill then
			local cam2=workspace.CurrentCamera
			local vp2=cam2 and cam2.ViewportSize or Vector2.new(1920,1080)
			pill.Visible = true
			pill.Position = UDim2.new(0,math.floor(vp2.X*0.5),0,-60)
			pill.BackgroundTransparency = 1
			tw(pill,.38,{Position=UDim2.new(0,math.floor(vp2.X*0.5),0,24),BackgroundTransparency=0.18},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		end
	else
		self:ShowNotification(
			"Press "..self._toggleKey.." to reopen the interface.",
			"info", 5, "Interface Hidden"
		)
	end
end

function Lib:Show()
	local win = self.Window
	if not win then return end
	local wasHidden = self._hidden
	-- FIX: incrementar _hideGen cancela qualquer task.delay pendente do Hide()
	self._hideGen = (self._hideGen or 0) + 1
	self._hidden = false
	if self._mobilePill then
		tw(self._mobilePill,.2,{Position=UDim2.new(.5,0,0,-60),BackgroundTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.22,function()
			if self._mobilePill and self._mobilePill.Parent then self._mobilePill.Visible=false end
		end)
	end
	self._dragActive = false
	self._dragTargetOX = 0
	self._dragTargetOY = 0
	if self._minimised then
		self._minimised = false
		
		if self._minFb  then self._minFb.Text  = "-" end
	end
	if self._body then self._body.Visible = true end
	win.BackgroundColor3 = C.Bg
	if self._tbFiller then self._tbFiller.Visible = true end
	if self._tbBorderLine then self._tbBorderLine.Visible = true end
	win.Position = UDim2.fromScale(.5, .5)

	local targetW, targetH, sw, collapsed
	if self._computeScale then
		targetW, targetH, sw, collapsed = self._computeScale()
	else
		targetW, targetH, sw, collapsed = self.cfg.WindowWidth, self.cfg.WindowHeight, self.cfg.SidebarWidth, false
	end

	if self._sidebar then
		self._sidebar.Size = UDim2.new(0, sw, 1, 0)
		self:_setCollapsed(collapsed)
	end

	if wasHidden then
		win.Size = UDim2.fromOffset(math.floor(targetW * 0.9), math.floor(targetH * 0.9))
		win.Visible = true
		win.BackgroundTransparency = 1
		tw(win, .38, {BackgroundTransparency=0, Size=UDim2.fromOffset(targetW, targetH)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	else
		win.Visible = true
		tw(win, .38, {Size=UDim2.fromOffset(targetW, targetH)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	if self._dragHandle and not self:_useMiniMode() then
		self._dragHandle.Visible = true
		if self._syncHandle then self._syncHandle() end
	end
end

function Lib:SetVisible(v)
	if v then self:Show() else self:Hide() end
end

function Lib:Shake(intensity)
	local win = self.Window
	if not win then return end
	intensity = intensity or 6
	local ox = win.Position.X.Offset
	local oy = win.Position.Y.Offset
	local sx = win.Position.X.Scale
	local sy = win.Position.Y.Scale
	task.spawn(function()
		for i=1,10 do
			local f = 1 - i/11
			local dx = (math.random()-.5)*2*intensity*f
			local dy = (math.random()-.5)*intensity*f
			win.Position = UDim2.new(sx,ox+dx,sy,oy+dy)
			task.wait(0.035)
		end
		win.Position = UDim2.new(sx,ox,sy,oy)
	end)
end

function Lib:Confirm(title, message, onConfirm, onCancel, opts)
	local sg = self._sg
	if not sg then return end
	opts = opts or {}
	local confirmText  = opts.ConfirmText  or "Confirm"
	local cancelText   = opts.CancelText   or "Cancel"
	local confirmColor = opts.ConfirmColor or C.Red
	local isDestructive = opts.Destructive ~= false
	local accentCol = isDestructive and C.Red or accentOrWhite(self)

	local container = new("Frame",{
		Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
		BorderSizePixel=0,ZIndex=900,
	},sg)

	local overlay = new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=fromHex("000000"),
		BackgroundTransparency=1,BorderSizePixel=0,ZIndex=900},container)
	local ovGrad = new("UIGradient",{
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
			ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
		},
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 0.7),
		},
		Rotation=90,
	}, overlay)

	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1280,720)
	local mw  = math.clamp(math.floor(vp.X * 0.30), 280, 400)
	local modal = new("Frame",{
		AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,18),
		Size=UDim2.fromOffset(math.floor(mw*0.9),0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,ZIndex=901,BackgroundTransparency=1,
	},container)
	corner(modal,14)
	stroke(modal,C.Border2,1)
	local modalGrad = new("UIGradient",{
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, C.Card),
			ColorSequenceKeypoint.new(1, C.Card2),
		},
		Rotation=90,
	}, modal)
	new("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},modal)

	local header=new("Frame",{Size=UDim2.new(1,0,0,68),BackgroundTransparency=1,ZIndex=902,LayoutOrder=0},modal)
	pad(header,16,8,16,16)
	hlist(header,10)
	local iconWrap=new("Frame",{Size=UDim2.fromOffset(28,28),BackgroundTransparency=1,LayoutOrder=0},header)
	local icon=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=accentCol,BorderSizePixel=0},iconWrap)
	corner(icon,8)
	new("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=fromHex("000000"),BackgroundTransparency=.9,BorderSizePixel=0},icon)
	local iconLbl=new("TextLabel",{Text=isDestructive and "!" or "i",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.Bg,
		BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center},icon)
	local titleCol=new("Frame",{Size=UDim2.new(1,-28,1,0),BackgroundTransparency=1,LayoutOrder=1},header)
	vlist(titleCol,4)
	new("TextLabel",{Text=title or "Confirm",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.White,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),TextXAlignment=Enum.TextXAlignment.Left},titleCol)
	new("TextLabel",{Text=isDestructive and "This action may affect your session" or "Please review and confirm the action",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),TextXAlignment=Enum.TextXAlignment.Left},titleCol)
	new("Frame",{Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},modal)

	local body=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=903,LayoutOrder=1},modal)
	pad(body,18,18,18,18)

	local msgLbl=new("TextLabel",{Text=message or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},body)
	-- aumento sutil da altura mínima do corpo
	new("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1},body)
	new("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},body)

	local footer=new("Frame",{Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,ZIndex=903,LayoutOrder=2},modal)
	pad(footer,12,14,16,16)
	hlist(footer,14)

	local cancelBtn=new("TextButton",{Text=cancelText,Font=Enum.Font.GothamBold,TextSize=13,
		TextColor3=C.TextDim,BackgroundColor3=C.Card2,BorderSizePixel=0,
		Size=UDim2.new(.5,-12,0,44),AutoButtonColor=false,LayoutOrder=0},footer)
	corner(cancelBtn,8)
	stroke(cancelBtn,C.Border2,1)
	cancelBtn.MouseEnter:Connect(function() tw(cancelBtn,.1,{TextColor3=C.White,BackgroundColor3=C.Card3}) end)
	cancelBtn.MouseLeave:Connect(function() tw(cancelBtn,.12,{TextColor3=C.TextDim,BackgroundColor3=C.Card2}) end)

	local confirmBtn=new("TextButton",{Text=confirmText,Font=Enum.Font.GothamBold,TextSize=13,
		TextColor3=C.White,BackgroundColor3=confirmColor,BorderSizePixel=0,
		Size=UDim2.new(.5,-12,0,44),AutoButtonColor=false,LayoutOrder=1},footer)
	corner(confirmBtn,8)
	local function lighten(col)
		return Color3.new(math.min(col.R+0.15,1),math.min(col.G+0.08,1),math.min(col.B+0.08,1))
	end
	confirmBtn.MouseEnter:Connect(function() tw(confirmBtn,.1,{BackgroundColor3=lighten(confirmColor)}) end)
	confirmBtn.MouseLeave:Connect(function() tw(confirmBtn,.12,{BackgroundColor3=confirmColor}) end)

	local function closeModal()
		tw(overlay,.2,{BackgroundTransparency=1},Enum.EasingStyle.Quint)
		tw(modal,.2,{BackgroundTransparency=1,Position=UDim2.new(.5,0,.5,28)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.22,function() pcall(function() container:Destroy() end) end)
	end

	cancelBtn.Activated:Connect(function()
		closeModal(); if onCancel then self:_safeCall(onCancel) end
	end)
	confirmBtn.Activated:Connect(function()
		closeModal(); if onConfirm then self:_safeCall(onConfirm) end
	end)

	local closeOnOverlay=new("TextButton",{
		Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
		ZIndex=900,AutoButtonColor=false,
	},overlay)
	closeOnOverlay.Activated:Connect(function()
		closeModal(); if onCancel then self:_safeCall(onCancel) end
	end)

	modal.Size = UDim2.fromOffset(mw, 0)
	tw(overlay,.22,{BackgroundTransparency=0.45},Enum.EasingStyle.Quint)
	tw(modal,.3,{BackgroundTransparency=0,Position=UDim2.fromScale(.5,.5)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end


function Lib:OnDestroy(fn)
	if type(fn)=="function" then
		table.insert(self._onDestroyFns, fn)
	end
end

function Lib:Destroy()
	self._destroyed = true
	-- stop tweens tracked globally
	for obj, twr in pairs(_tweenMap) do
		pcall(function()
			if twr then twr:Cancel() end
		end)
	end
	for _,twr in ipairs(self._tweens or {}) do
		pcall(function() if twr then twr:Cancel() end end)
	end
	-- try cancel any tracked tasks
	for _,th in ipairs(self._tasks or {}) do
		pcall(function() if task.cancel then task.cancel(th) end end)
	end
	-- instance registry cleanup
	if Lib._instances then
		for i,inst in ipairs(Lib._instances) do
			if inst == self then table.remove(Lib._instances, i) break end
		end
	end
	for _,fn in ipairs(self._onDestroyFns or {}) do pcall(fn) end
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	if self._keyConn then pcall(function() self._keyConn:Disconnect() end) end
	if self._pillCamConn then pcall(function() self._pillCamConn:Disconnect() end) end
	if self._viewportConn then pcall(function() self._viewportConn:Disconnect() end) end
	if self._sg and self._sg.Parent then
		if self.Window then
			local ws = self.Window.AbsoluteSize
			tw(self.Window,.28,{
				BackgroundTransparency=1,
				Size=UDim2.fromOffset(ws.X*.93, ws.Y*.93),
			},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		end
		task.delay(.31,function() pcall(function() self._sg:Destroy() end) end)
	end
	-- clear references
	self._conns = {}
	self._tweens = {}
	self._tasks = {}
	self._pages = {}
	self._navBtns = {}
end

function Lib:_buildToastSystem()
	local holder = new("Frame",{
		AnchorPoint   = Vector2.new(1, 1),
		Position      = UDim2.new(1, -16, 1, -16),
		Size          = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 1000,
	}, self._sg)
	new("UIListLayout",{
		FillDirection      = Enum.FillDirection.Vertical,
		SortOrder          = Enum.SortOrder.LayoutOrder,
		VerticalAlignment  = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment= Enum.HorizontalAlignment.Right,
		Padding            = UDim.new(0, 8),
	}, holder)
	self._toastHolder = holder
end

function Lib:ShowNotification(msg, style, duration, title)
	if not self:_isAlive() then return end
	if not self._toastHolder then return end
	local styleMap = {
		info    = {dot=C.Blue,   bg=C.BlueBg,   tc=C.Blue},
		success = {dot=C.Green,  bg=C.GreenBg,  tc=C.Green},
		warning = {dot=C.Yellow, bg=C.YellowBg, tc=C.Yellow},
		error   = {dot=C.Red,    bg=C.RedBg,    tc=C.Red},
		purple  = {dot=C.Purple, bg=C.PurpleBg, tc=C.Purple},
	}
	local st = styleMap[style or "info"] or styleMap.info
	self._toastCount = (self._toastCount or 0) + 1
	local lo = self._toastCount

	local wrapper = new("Frame",{
		Size          = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = lo,
		ZIndex = 1001,
	}, self._toastHolder)

	local toast = new("Frame",{
		Size          = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Card2,
		BorderSizePixel  = 0,
		ZIndex = 1002,
		Position = UDim2.fromOffset(320, 0),
	}, wrapper)
	corner(toast, 8)
	stroke(toast, C.Border2, 1)

	local inner = new("Frame",{
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, toast)
	pad(inner, 12, 12, 16, 16)
	vlist(inner, 5)

	local topRow = new("Frame",{
		Size = UDim2.new(1,0,0,16),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
	}, inner)
	hlist(topRow, 8)
	local dot = new("Frame",{
		Size=UDim2.fromOffset(8,8),BackgroundColor3=st.dot,BorderSizePixel=0,LayoutOrder=0,
	}, topRow)
	corner(dot, 4)
	new("TextLabel",{
		Text = string.upper(title or style or "info"),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = st.tc,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 1003,
		LayoutOrder = 1,
	}, topRow)

	new("TextLabel",{
		Text = msg or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = C.TextDim,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 1003,
		LayoutOrder = 1,
	}, inner)

	local pbg = new("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=C.Card3,BorderSizePixel=0,LayoutOrder=2},inner)
	corner(pbg,1)
	local pf = new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=st.dot,BorderSizePixel=0},pbg)
	corner(pf,1)

	tw(toast, .38, {Position=UDim2.fromOffset(0,0)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tw(pf, duration or 3.5, {Size=UDim2.fromScale(0,1)}, Enum.EasingStyle.Linear)

	local alive = true
	local function dismiss()
		if not alive then return end
		alive = false
		tw(toast, .22, {Position=UDim2.fromOffset(320,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(.25, function()
			if wrapper and wrapper.Parent then wrapper:Destroy() end
		end)
	end

	local clickOverlay = new("TextButton",{Text="",BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ZIndex=1004,AutoButtonColor=false},toast)
	clickOverlay.Activated:Connect(dismiss)
	task.delay(duration or 3.5, dismiss)
end

function Lib:_buildSettingsPanel()
	local frame = new("Frame",{
		Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,ZIndex=5,
	}, self._pagesWrap)
	local scroll = new("ScrollingFrame",{
		Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
		ScrollBarThickness=5,ScrollBarImageColor3=C.Border3,ScrollBarImageTransparency=.2,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		ElasticBehavior=Enum.ElasticBehavior.Never,
	},frame)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},scroll)
	pad(scroll,16,24,16,16)
	self._settingsFrame = frame
	self._settingsScroll = scroll

	local lo = 0
	local function nextLo() lo=lo+1; return lo end

	new("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
	new("TextLabel",{Text="Settings",Font=Enum.Font.GothamBold,TextSize=20,TextColor3=C.White,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nextLo()},scroll)
	new("TextLabel",{Text="Interface preferences",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	if UserInputService.TouchEnabled then
		local card = new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
			BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
		corner(card,10); stroke(card,C.Border,1); pad(card,16,16,16,16)
		new("TextLabel",{Text="Mobile device detected.\nKeybind configuration is unavailable.\nUse the floating button to show or hide the interface.",
			Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TextDim,BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
			TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},card)
		return
	end

	new("TextLabel",{Text="SHOW / HIDE KEYBIND",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,6),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	local kbRow=new("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	corner(kbRow,10); stroke(kbRow,C.Border,1); pad(kbRow,0,0,16,16)
	new("TextLabel",{Text="Toggle Interface",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-104,1,0),TextXAlignment=Enum.TextXAlignment.Left},kbRow)

	local kbBtn=new("TextButton",{Text=self._toggleKey,Font=Enum.Font.GothamBold,TextSize=11,
		TextColor3=C.White,BackgroundColor3=C.Card3,BorderSizePixel=0,
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(90,32),AutoButtonColor=false},kbRow)
	corner(kbBtn,8); stroke(kbBtn,C.Border2,1)
	pcall(function() kbBtn.CursorIcon="rbxasset://SystemCursors/PointingHand" end)
	kbRow.MouseEnter:Connect(function() tw(kbRow,.15,{BackgroundColor3=C.Card2}) end)
	kbRow.MouseLeave:Connect(function() tw(kbRow,.18,{BackgroundColor3=C.Card}) end)

	local kbListening=false
	kbBtn.Activated:Connect(function()
		if kbListening then return end
		kbListening=true; self._kbListening=true; kbBtn.Text="..."
		tw(kbBtn,.15,{BackgroundColor3=C.Card2})
	end)
	table.insert(self._conns, UserInputService.InputBegan:Connect(function(inp,gp)
		if not kbListening then return end
		if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
		local name=tostring(inp.KeyCode):gsub("Enum%.KeyCode%.","")
		if name=="Escape" then
			kbListening=false; self._kbListening=false; kbBtn.Text=self._toggleKey
			tw(kbBtn,.15,{BackgroundColor3=C.Card3}); return
		end
		self._toggleKey=name; kbBtn.Text=name; kbListening=false; self._kbListening=false
		tw(kbBtn,.15,{BackgroundColor3=C.Card3})
		self:ShowNotification("Keybind updated to: "..name,"success",3,"Settings")
	end))

	new("Frame",{Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
	new("TextLabel",{
		Text="Click the button, then press any key to rebind. Press Escape to cancel.",
		Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TextDim,BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=nextLo()},scroll)

	new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	new("TextLabel",{Text="DISPLAY",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,6),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	do
		local rmRow=new("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
		corner(rmRow,10); stroke(rmRow,C.Border,1)
		new("TextLabel",{Text="Reduce Motion",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
			BackgroundTransparency=1,Position=UDim2.new(0,16,.5,-16),Size=UDim2.new(1,-80,0,18),TextXAlignment=Enum.TextXAlignment.Left},rmRow)
		new("TextLabel",{Text="Simpler animations, no easing overshoot",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,
			BackgroundTransparency=1,Position=UDim2.new(0,16,.5,4),Size=UDim2.new(1,-80,0,14),TextXAlignment=Enum.TextXAlignment.Left},rmRow)
		local rmVal = self._reduceMotion
		local track=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),
			Size=UDim2.fromOffset(44,24),BackgroundColor3=rmVal and C.Green or C.Card3,BorderSizePixel=0},rmRow)
		corner(track,12)
		local knob=new("Frame",{AnchorPoint=Vector2.new(0,.5),
			Position=UDim2.new(0,rmVal and 22 or 2,.5,0),
			Size=UDim2.fromOffset(20,20),BackgroundColor3=rmVal and C.Bg or C.TextDim,BorderSizePixel=0},track)
		corner(knob,10)
		local rmClick=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false,ClipsDescendants=false},rmRow)
		rmClick.Activated:Connect(function()
			rmVal=not rmVal
			self._reduceMotion=rmVal
			_rm=rmVal
			tw(track,.2,{BackgroundColor3=rmVal and C.Green or C.Card3})
			tw(knob,.22,{Position=UDim2.new(0,rmVal and 22 or 2,.5,0),BackgroundColor3=rmVal and C.Bg or C.TextDim})
			self:ShowNotification(rmVal and "Reduce Motion enabled" or "Reduce Motion disabled","info",2)
		end)
		rmRow.MouseEnter:Connect(function() tw(rmRow,.15,{BackgroundColor3=C.Card2}) end)
		rmRow.MouseLeave:Connect(function() tw(rmRow,.18,{BackgroundColor3=C.Card}) end)
	end

	if not UserInputService.TouchEnabled then
		new("Frame",{Size=UDim2.new(1,0,0,8),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
		do
			local smRow=new("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
			corner(smRow,10); stroke(smRow,C.Border,1)
			new("TextLabel",{Text="Simulate Mobile",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
				BackgroundTransparency=1,Position=UDim2.new(0,16,.5,-16),Size=UDim2.new(1,-80,0,18),TextXAlignment=Enum.TextXAlignment.Left},smRow)
			new("TextLabel",{Text="Preview mobile layout (dev only)",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,
				BackgroundTransparency=1,Position=UDim2.new(0,16,.5,4),Size=UDim2.new(1,-80,0,14),TextXAlignment=Enum.TextXAlignment.Left},smRow)
			local smVal = self._simulateMobile
			local smTrack=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),
				Size=UDim2.fromOffset(44,24),BackgroundColor3=smVal and C.Yellow or C.Card3,BorderSizePixel=0},smRow)
			corner(smTrack,12)
			local smKnob=new("Frame",{AnchorPoint=Vector2.new(0,.5),
				Position=UDim2.new(0,smVal and 22 or 2,.5,0),
				Size=UDim2.fromOffset(20,20),BackgroundColor3=smVal and C.Bg or C.TextDim,BorderSizePixel=0},smTrack)
			corner(smKnob,10)
			local smClick=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false},smRow)
			smClick.Activated:Connect(function()
				smVal=not smVal
				self._simulateMobile=smVal
				tw(smTrack,.2,{BackgroundColor3=smVal and C.Yellow or C.Card3})
				tw(smKnob,.22,{Position=UDim2.new(0,smVal and 22 or 2,.5,0),BackgroundColor3=smVal and C.Bg or C.TextDim})
				if smVal then
					if self._mobilePill then
						pcall(function() self._mobilePill:Destroy() end)
						self._mobilePill = nil
					end
					if self._dragHandle then self._dragHandle.Visible = false end
				else
					if self._mobilePill then
						pcall(function() self._mobilePill:Destroy() end)
						self._mobilePill = nil
					end
					if self._dragHandle and not self._hidden then
						self._dragHandle.Visible = true
					end
				end
				if self._doScale then self._doScale() end
				self:ShowNotification(smVal and "Mobile simulation ON" or "Mobile simulation OFF","warning",2)
			end)
			smRow.MouseEnter:Connect(function() tw(smRow,.15,{BackgroundColor3=C.Card2}) end)
			smRow.MouseLeave:Connect(function() tw(smRow,.18,{BackgroundColor3=C.Card}) end)
		end
	end

	new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	new("TextLabel",{Text="DANGER ZONE",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.Red,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,6),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	do
		local unloadRow=new("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=fromHex("1a0505"),BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
		corner(unloadRow,10)
		stroke(unloadRow,fromHex("3a0808"),1)
		pad(unloadRow,0,0,16,16)
		new("TextLabel",{Text="Unload Script",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Red,
			BackgroundTransparency=1,Position=UDim2.new(0,0,.5,-16),Size=UDim2.new(1,-140,0,18),TextXAlignment=Enum.TextXAlignment.Left},unloadRow)
		new("TextLabel",{Text="Completely removes the interface",Font=Enum.Font.Gotham,TextSize=10,TextColor3=fromHex("884444"),
			BackgroundTransparency=1,Position=UDim2.new(0,0,.5,4),Size=UDim2.new(1,-140,0,13),TextXAlignment=Enum.TextXAlignment.Left},unloadRow)
		local unloadBtn=new("TextButton",{
			Text="UNLOAD",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.White,
			BackgroundColor3=C.Red,BorderSizePixel=0,AutoButtonColor=false,
			AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
			Size=UDim2.fromOffset(100,32)},unloadRow)
		corner(unloadBtn,8)
		unloadBtn.MouseEnter:Connect(function() tw(unloadBtn,.1,{BackgroundColor3=fromHex("ff5555")}) end)
		unloadBtn.MouseLeave:Connect(function() tw(unloadBtn,.12,{BackgroundColor3=C.Red}) end)
		unloadBtn.Activated:Connect(function()
			self:Confirm(
				"Unload Script",
				"This will completely remove the interface and stop all connections. This cannot be undone.",
				function() self:Destroy() end
			)
		end)
	end

	new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	new("TextLabel",{Text="ABOUT",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nextLo()},scroll)
	new("Frame",{Size=UDim2.new(1,0,0,6),BackgroundTransparency=1,LayoutOrder=nextLo()},scroll)

	local aboutCard=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=nextLo()},scroll)
	corner(aboutCard,10); stroke(aboutCard,C.Border,1); pad(aboutCard,14,14,16,16); vlist(aboutCard,6)
	local function aboutRow(label, value)
		local r=new("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,LayoutOrder=nextLo()},aboutCard)
		hlist(r,0)
		new("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromOffset(100,18),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},r)
		new("TextLabel",{Text=value,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.Text,
			BackgroundTransparency=1,Size=UDim2.new(1,-100,0,18),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},r)
	end
	aboutRow("Library","SlaoqUILib")
	aboutRow("Version","v"..self.cfg.AppVersion)
	aboutRow("App","  "..self.cfg.AppName)
end

function Lib:_openSettings()
	if not self:_isAlive() then return end
	if not self._settingsFrame then self:_buildSettingsPanel() end

	self._settingsGen = (self._settingsGen or 0) + 1
	local gen = self._settingsGen

	if self._settingsVisible then
		self._settingsVisible = false
		if self._gearImg then tw(self._gearImg,.15,{ImageColor3=C.Text}) end
		local sf = self._settingsFrame
		local sfs = sf and sf:FindFirstChildWhichIsA("ScrollingFrame")
		local nb = self._navBtns[self._pageIdx]
		if sfs then
			tw(sfs,.18,{Position=UDim2.new(0,0,0,10)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		end
		task.delay(.2,function()
			if gen ~= self._settingsGen then return end
			if sf then sf.Visible=false end
			if sfs and sfs.Parent then sfs.Position=UDim2.fromOffset(0,0) end
			local pg = self._pages[self._pageIdx]
			local pgFrame = pg and pg.Frame
			if pgFrame then
				local nfs = pgFrame:FindFirstChildWhichIsA("ScrollingFrame")
				if nfs then nfs.Position=UDim2.new(0,0,0,20) end
				pgFrame.Visible=true
				if nfs then tw(nfs,.3,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quint) end
			end
			if nb then
				tw(nb.Lbl,self.cfg.TweenSpeed,{TextColor3=C.White})
				tw(nb.Bg,self.cfg.TweenSpeed,{BackgroundTransparency=.76})
				if nb.SetDotColor then nb.SetDotColor(accentOrWhite(self)) else tw(nb.Dot,self.cfg.TweenSpeed,{BackgroundColor3=accentOrWhite(self),Size=UDim2.fromOffset(7,7)}) end
				self:_animBar(nb.Frame)
			end
		end)
		return
	end

	self._settingsVisible = true
	local old = self._navBtns[self._pageIdx]
	if old then
		tw(old.Lbl,self.cfg.TweenSpeed,{TextColor3=C.TextDim})
		tw(old.Bg,self.cfg.TweenSpeed,{BackgroundTransparency=1})
		if old.SetDotColor then old.SetDotColor(C.TextOff) else tw(old.Dot,self.cfg.TweenSpeed,{BackgroundColor3=C.TextOff,Size=UDim2.fromOffset(6,6)}) end
	end
	if self._bar then self._bar.Visible = false end
	if self._gearImg then tw(self._gearImg,.15,{ImageColor3=C.White}) end

	local curFrame = self._pages[self._pageIdx] and self._pages[self._pageIdx].Frame
	local sf = self._settingsFrame
	local sfs = sf:FindFirstChildWhichIsA("ScrollingFrame")
	if curFrame and curFrame.Visible then
		local ofs = curFrame:FindFirstChildWhichIsA("ScrollingFrame")
		if ofs then
			tw(ofs,.18,{Position=UDim2.new(0,0,0,10)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		end
		task.delay(.2,function()
			if gen ~= self._settingsGen then return end
			if curFrame and curFrame.Parent then curFrame.Visible=false end
			if ofs and ofs.Parent then ofs.Position=UDim2.fromOffset(0,0) end
			if sfs then sfs.Position=UDim2.new(0,0,0,20) end
			sf.Visible=true
			if sfs then tw(sfs,.3,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quint) end
		end)
	else
		if sfs then sfs.Position=UDim2.new(0,0,0,20) end
		sf.Visible=true
		if sfs then tw(sfs,.3,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quint) end
	end
end

function Lib:_toggleSearch()
	if self._searchOpen then self:_closeSearch() else self:_openSearch() end
end

function Lib:_openSearch()
	if not self:_isAlive() then return end
	if self._searchOpen then return end
	self._searchOpen = true
	local sbH = 48
	self._searchBar.Size = UDim2.new(1,0,0,0)
	tw(self._searchBar, 0.2, {Size=UDim2.new(1,0,0,sbH)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tw(self._pagesWrap, .25, {
		Position = UDim2.fromOffset(0,sbH),
		Size     = UDim2.new(1,0,1,-sbH),
	}, Enum.EasingStyle.Quint)
	task.delay(.28, function()
		if self._searchBox and self._searchBar.Size.Y.Offset > 0 then
			self._searchBox:CaptureFocus()
		end
	end)
	if self._searchBtnImg then tw(self._searchBtnImg,.15,{ImageColor3=C.White}) end
	if self._searchBtnFb  then tw(self._searchBtnFb,.15,{TextColor3=C.White}) end
end

function Lib:_closeSearch()
	if not self:_isAlive() then return end
	if not self._searchOpen then return end
	self._searchOpen = false
	self:_clearHighlights()
	if self._searchBox then self._searchBox.Text = "" end
	if self._searchResultLbl then self._searchResultLbl.Text = "" end
	tw(self._searchBar, .2, {Size=UDim2.new(1,0,0,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	tw(self._pagesWrap, .2, {
		Position = UDim2.fromOffset(0,0),
		Size     = UDim2.fromScale(1,1),
	}, Enum.EasingStyle.Quint)
	if self._searchBtnImg then tw(self._searchBtnImg,.15,{ImageColor3=C.Text}) end
	if self._searchBtnFb  then tw(self._searchBtnFb,.15,{TextColor3=C.Text}) end
end

function Lib:_clearHighlights()
	for _, info in ipairs(self._searchHighlights or {}) do
		pcall(function()
			if info.obj and info.obj.Parent then
				info.obj.Text = info.original
				info.obj.RichText = info.wasRich
			end
		end)
	end
	self._searchHighlights = {}
	-- Reset search UI state completely
	if self._searchResultLbl then
		self._searchResultLbl.Text = ""
		self._searchResultLbl.Visible = false
	end
	if self._searchNavUp   then self._searchNavUp.Visible   = false end
	if self._searchNavDown then self._searchNavDown.Visible = false end
end

function Lib:_searchNavigate(dir)
	local hits = self._searchHitObjs
	if not hits or #hits == 0 then return end
	-- When called with dir=1 right after _doSearch set _searchIdx=1,
	-- avoid advancing to index 2 immediately.
	if dir ~= 0 then
		self._searchIdx = self._searchIdx + dir
	end
	if self._searchIdx < 1 then self._searchIdx = #hits end
	if self._searchIdx > #hits then self._searchIdx = 1 end
	local obj = hits[self._searchIdx]
	if self._searchResultLbl then
		self._searchResultLbl.Text = self._searchIdx .. " / " .. #hits
	end
	local scroll = self._pages[self._pageIdx] and self._pages[self._pageIdx].Scroll
	if scroll and obj and obj.Parent then
		pcall(function()
			local relY = obj.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
			scroll.CanvasPosition = Vector2.new(0, math.max(0, relY - scroll.AbsoluteSize.Y * 0.3))
		end)
	end
end

function Lib:_doSearch(query)
	if not self:_isAlive() then return end
	if not self:_throttle("search", 0.08) then return end
	self:_clearHighlights()
	self._searchIdx = 0
	self._searchHitObjs = {}
	if not query or query == "" then
		if self._searchResultLbl then
			self._searchResultLbl.Text = ""
			self._searchResultLbl.Visible = false
		end
		local nu = self._searchNavUp
		local nd = self._searchNavDown
		if nu then nu.Visible = false end
		if nd then nd.Visible = false end
		return
	end

	local currentScroll = self._pages[self._pageIdx] and self._pages[self._pageIdx].Scroll
	if not currentScroll then return end

	local qLower = query:lower()
	local highlights = {}
	local hitObjs = {}

	local function isSearchable(child)
		local txt = child.Text or ""
		-- Skip blank, single-char UI symbols (-, +, x, v, ^, …)
		if #txt <= 1 then return false end
		-- Skip text that is purely ellipsis or control tokens
		if txt == "..." or txt == ".." then return false end
		-- Skip number-only labels (counters, step values, percentages)
		if txt:match("^%s*%-?%d+%s*$") then return false end
		if txt:match("^%d+%s*/%s*%d+$") then return false end
		if txt:match("^%d+%%$") then return false end
		-- Skip labels that look like section headers / category caps (e.g. "CONSOLE", "INFO")
		-- but only if very short — real content can also be uppercase
		if #txt <= 12 and txt == txt:upper() and not txt:find(" ") then return false end
		-- Skip RichText elements — modifying them would corrupt markup
		if child.RichText then return false end
		-- Opt-out via attribute
		if child:GetAttribute("SearchExclude") then return false end
		return true
	end

	local processed = 0
	local function scan(parent)
		for _, child in ipairs(parent:GetChildren()) do
			processed = processed + 1
			if processed > 2000 then return end
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				if isSearchable(child) then
					local txt = child.Text or ""
					if txt ~= "" and txt:lower():find(qLower, 1, true) then
						local wasRich = child.RichText
						local escaped = txt:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
						local accentCol = accentOrWhite(self)
						local r2 = math.floor(accentCol.R * 255)
						local g2 = math.floor(accentCol.G * 255)
						local b2 = math.floor(accentCol.B * 255)
						local highlightTag = string.format('<font color="rgb(%d,%d,%d)"><b>', r2, g2, b2)
						local result = ""
						local i = 1
						while i <= #escaped do
							local s, e = escaped:lower():find(qLower, i, true)
							if s then
								result = result .. escaped:sub(i, s-1)
								result = result .. highlightTag .. escaped:sub(s,e) .. '</b></font>'
								i = e + 1
							else
								result = result .. escaped:sub(i)
								break
							end
						end
						table.insert(highlights, {obj=child, original=txt, wasRich=wasRich})
						table.insert(hitObjs, child)
						pcall(function()
							child.RichText = true
							child.Text = result
						end)
					end
				end
			end
			scan(child)
		end
	end

	scan(currentScroll)
	self._searchHighlights = highlights
	self._searchHitObjs = hitObjs

	local total = #hitObjs
	local nu = self._searchNavUp
	local nd = self._searchNavDown
	if total == 0 then
		if self._searchResultLbl then
			self._searchResultLbl.Visible = true
			self._searchResultLbl.Text = "no results"
			tw(self._searchResultLbl, .1, {TextColor3=C.Red})
		end
		if nu then nu.Visible = false end
		if nd then nd.Visible = false end
	else
		self._searchIdx = 1
		if self._searchResultLbl then
			self._searchResultLbl.Visible = true
			self._searchResultLbl.Text = "1 / " .. total
			tw(self._searchResultLbl, .1, {TextColor3=C.Green})
		end
		if nu then nu.Visible = total > 1 end
		if nd then nd.Visible = total > 1 end
		self:_searchNavigate(0)
	end
end

function Lib:IsMobile()
	return UserInputService.TouchEnabled or self._simulateMobile
end

function Lib:IsPC()
	return not (UserInputService.TouchEnabled or self._simulateMobile)
end

function Lib:OnMobile(fn)
	if UserInputService.TouchEnabled or self._simulateMobile then fn() end
end

function Lib:OnPC(fn)
	if not (UserInputService.TouchEnabled or self._simulateMobile) then fn() end
end

function Lib:AddPlatform(config)
	local isTouch = UserInputService.TouchEnabled
	local fn = isTouch and config.Mobile or config.PC
	if fn then return fn() end
end

function Lib:AddMobileOnly(pi, buildFn)
	if UserInputService.TouchEnabled then return buildFn(pi) end
end

function Lib:AddPCOnly(pi, buildFn)
	if not UserInputService.TouchEnabled then return buildFn(pi) end
end

function Lib:AddPlatformLabel(pi, pcText, mobileText, style)
	local text = UserInputService.TouchEnabled and (mobileText or pcText) or pcText
	return self:AddLabel(pi, text, style)
end

function Lib:AddPlatformAlert(pi, title, pcMsg, mobileMsg, style)
	local msg = UserInputService.TouchEnabled and (mobileMsg or pcMsg) or pcMsg
	return self:AddAlert(pi, title, msg, style)
end

function Lib:_o(pi)
	self._ord[pi] = (self._ord[pi] or 0)+1
	return self._ord[pi]
end

function Lib:GetPage(i)
	return self._pages[i] and self._pages[i].Scroll or nil
end

function Lib:_gap(s,pi,h)
	new("Frame",{Size=UDim2.new(1,0,0,h or 10),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
end

function Lib:Notify(text, style, duration, title)
	self:ShowNotification(text, style or "info", duration or 3, title)
end

function Lib:SetPageBadge(pi, text)
	local nb = self._navBtns[pi]
	if not nb then return end
	local frame = nb.Frame
	if nb._badge then
		if text and text ~= "" then
			nb._badge.Text = tostring(text)
			nb._badge.Visible = true
		else
			nb._badge.Visible = false
		end
		return
	end
	if not text or text == "" then return end
	local badge = new("TextLabel",{
		Text=tostring(text), Font=Enum.Font.GothamBold, TextSize=9,
		TextColor3=C.White, BackgroundColor3=C.Red, BorderSizePixel=0,
		AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-2,0,2),
		Size=UDim2.fromOffset(0,14), AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Center, ZIndex=8,
	}, frame)
	corner(badge, 999)
	nb._badge = badge
end

function Lib:AddSection(pi,name)
	self:AddSectionHeader(pi,name)
end

function Lib:AddSectionHeader(pi,title,sub)
	local s=self:GetPage(pi); if not s then return end
	self:_gap(s,pi,4)
	if title then
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=20,TextColor3=C.White,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),
			TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
	end
	if sub then
		new("TextLabel",{Text=sub,Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),
			TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
	end
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	self:_gap(s,pi,20)
end

function Lib:AddMetricRow(pi,cards)
	local s=self:GetPage(pi); if not s then return end
	local n=#cards; local cols=math.min(n,3); local rows=math.ceil(n/cols)
	local H=82; local G=10

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,rows*(H+G)-G),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
	local objects={}
	for i,card in ipairs(cards) do
		local row=math.floor((i-1)/cols); local col=(i-1)%cols
		local wOff = n==1 and 0 or (col==0 or col==cols-1) and -G/2 or -G
		local f=new("Frame",{BackgroundColor3=C.Card,BorderSizePixel=0,ZIndex=2,
			Position=UDim2.new(col/cols,col>0 and G or 0,0,row*(H+G)),
			Size=UDim2.new(1/cols,wOff,0,H)},wrap)
		corner(f,10)
		stroke(f,C.Border,1)
		pad(f,14,14,16,14)
		new("TextLabel",{Text=string.upper(card.Label or ""),Font=Enum.Font.GothamBold,TextSize=9,
			TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,13),
			TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},f)
		local valLbl=new("TextLabel",{Text=tostring(card.Value or "---"),Font=Enum.Font.GothamBold,TextSize=24,
			TextColor3=C.White,BackgroundTransparency=1,Position=UDim2.fromOffset(0,16),
			Size=UDim2.new(1,0,0,32),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},f)
		if card.Unit and card.Unit~="" then
			new("TextLabel",{Text=card.Unit,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextOff,
				BackgroundTransparency=1,Position=UDim2.fromOffset(0,50),
				Size=UDim2.new(1,0,0,14),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},f)
		end
		local hov=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=4,AutoButtonColor=false},f)
		hov.MouseEnter:Connect(function() tw(f,.14,{BackgroundColor3=C.Card2}) end)
		hov.MouseLeave:Connect(function() tw(f,.16,{BackgroundColor3=C.Card}) end)
		objects[i]={Frame=f,ValueLabel=valLbl}
	end
	self:_gap(s,pi,14)
	return objects
end

function Lib:SetMetricValue(obj,val)
	if not(obj and obj.ValueLabel) then return end
	if obj.ValueLabel.Text==tostring(val) then return end
	tw(obj.ValueLabel,.08,{TextTransparency=.6})
	task.delay(.1,function()
		if obj.ValueLabel and obj.ValueLabel.Parent then
			obj.ValueLabel.Text=tostring(val)
			tw(obj.ValueLabel,.15,{TextTransparency=0})
		end
	end)
end

function Lib:AddButtonRow(pi,defs)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	defs = validateTable(defs, {})
	local row=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
	row:SetAttribute("ComponentId", self:_nextCompId("ButtonRow"))
	hlist(row,10)

	local styles={
		primary = {bg=C.White,    tc=C.Bg,    hov=fromHex("e0e0e0"),dn=fromHex("c0c0c0")},
		danger  = {bg=C.Red,      tc=C.White, hov=fromHex("ff5555"),dn=fromHex("bb2222")},
		warning = {bg=C.Yellow,   tc=C.Bg,    hov=C.Orange,         dn=fromHex("b04010")},
		ghost   = {bg=C.Card2,    tc=C.Text,  hov=C.Card3,          dn=C.Card},
		outline = {bg=C.Card,     tc=C.Text,  hov=C.Card2,          dn=C.Sidebar},
		success = {bg=C.GreenBg,  tc=C.Green, hov=fromHex("061a0d"),dn=fromHex("030a06")},
		purple  = {bg=C.PurpleBg, tc=C.Purple,hov=fromHex("150820"),dn=fromHex("0a0414")},
	}

	local btns={}
	for i,def in ipairs(defs) do
		def = validateTable(def, {})
		local st=styles[def.Style or "primary"]
		local w=def.Width or 130
		local btn=new("TextButton",{Text=def.Text or "",Font=Enum.Font.GothamBold,TextSize=12,
			TextColor3=st.tc,BackgroundColor3=st.bg,BorderSizePixel=0,
			Size=UDim2.fromOffset(w,40),AutoButtonColor=false,LayoutOrder=i},row)
		corner(btn,8)
		if def.Style=="outline" then stroke(btn,C.Border2,1) end
		btn.MouseEnter:Connect(function() tw(btn,.12,{BackgroundColor3=st.hov}) end)
		btn.MouseLeave:Connect(function() tw(btn,.15,{BackgroundColor3=st.bg}) end)
		btn.MouseButton1Down:Connect(function() tw(btn,.07,{BackgroundColor3=st.dn,Size=UDim2.fromOffset(w-4,38)}) end)
		btn.MouseButton1Up:Connect(function() tw(btn,.2,{BackgroundColor3=st.hov,Size=UDim2.fromOffset(w,40)},Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
		pcall(function() btn.CursorIcon="rbxasset://SystemCursors/PointingHand" end)
		if def.Callback then
			btn.Activated:Connect(function()
				if not self:_debounce("btnrow_"..tostring(i),0.15) then return end
				local ok = self:_safeCall(def.Callback)
				if not ok then
					local orig=st.bg
					tw(btn,.15,{BackgroundColor3=C.Red})
					task.delay(.5,function() tw(btn,.3,{BackgroundColor3=orig}) end)
				end
			end)
		end
		btns[i]=btn
	end
	self:_gap(s,pi,12)
	return btns
end

function Lib:AddButton(pi,text,style,cb)
	local r=self:AddButtonRow(pi,{{Text=text,Style=style or "primary",Callback=cb}})
	local btn=r and r[1]
	if not btn then return end
	local _originalText = text
	local _loading = false
	local obj={Button=btn,Frame=btn}
	function obj:Set(v)
		_originalText=tostring(v)
		if btn and btn.Parent and not _loading then btn.Text=_originalText end
	end
	function obj:SetEnabled(v)
		if btn and btn.Parent then
			btn.AutoButtonColor=false
			btn.Active=v==true
			btn.BackgroundTransparency=v==true and 0 or 0.5
		end
	end
	function obj:SetLoading(v)
		_loading=v==true
		if not btn or not btn.Parent then return end
		if _loading then
			btn.Text="..."
			btn.Active=false
			btn.BackgroundTransparency=0.4
		else
			btn.Text=_originalText
			btn.Active=true
			btn.BackgroundTransparency=0
		end
	end
	return obj
end

function Lib:AddToggle(pi,label,default,callback,desc)
	local s=self:GetPage(pi); if not s then return end
	local rowH = desc and 58 or 48
	local row=new("Frame",{Size=UDim2.new(1,0,0,rowH),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)
	if desc then
		new("TextLabel",{Text=label or "",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Text,
			BackgroundTransparency=1,Position=UDim2.new(0,0,0,10),Size=UDim2.new(1,-64,0,18),TextXAlignment=Enum.TextXAlignment.Left},row)
		new("TextLabel",{Text=desc,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,
			BackgroundTransparency=1,Position=UDim2.new(0,0,0,30),Size=UDim2.new(1,-64,0,14),TextXAlignment=Enum.TextXAlignment.Left},row)
	else
		new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
			BackgroundTransparency=1,Size=UDim2.new(1,-64,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)
	end

	local state=default==true
	local accentCol = accentOrWhite(self)
	local track=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(44,24),BackgroundColor3=state and accentCol or C.Card3,BorderSizePixel=0},row)
	corner(track,12)
	local tStroke=stroke(track,state and fromHex("aaaaaa") or C.Border2,1)
	-- FIX: cor do knob ON é C.White (visível), não C.Bg (fundo invisível)
	local knob=new("Frame",{AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.new(0,state and 22 or 2,.5,0),
		Size=UDim2.fromOffset(20,20),BackgroundColor3=state and C.White or C.TextDim,BorderSizePixel=0},track)
	corner(knob,10)

	-- FIX: usar um Frame intermediário como proxy para animar Position separadamente do Size,
	-- evitando que tw() cancele o tween anterior do mesmo objeto (knob).
	-- A posição é animada via um objeto separado (knobPos) e copiada para o knob via heartbeat.
	-- Solução mais simples e robusta: usar dois tweens em sub-objetos distintos.
	-- Para não refatorar tw(), simplesmente separamos os tweens em objetos diferentes:
	-- track para cor do track, tStroke para borda, knobColor (UIStroke dummy) não existe,
	-- então usamos a abordagem de animar BackgroundColor3 e Position/Size em sequência controlada.

	local _knobPressed = false

	local function applyKnobPos(v)
		-- Cancela qualquer tween de posição pendente e aplica com Back easing
		local targetPos = UDim2.new(0, v and 22 or 2, .5, 0)
		tw(knob, .26, {Position = targetPos}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	local function applyKnobColor(v)
		-- FIX: ON = C.White, OFF = C.TextDim
		tw(knob, .18, {BackgroundColor3 = v and C.White or C.TextDim}, Enum.EasingStyle.Quint)
	end

	local function apply(v, silent)
		state = v
		local ac = accentOrWhite(self)
		-- Track background e stroke
		tw(track, .22, {BackgroundColor3 = v and ac or C.Card3}, Enum.EasingStyle.Quint)
		tw(tStroke, .22, {Color = v and fromHex("aaaaaa") or C.Border2})
		-- FIX: cor do knob em objeto separado do tween de posição.
		-- Como tw() cancela tweens do mesmo objeto, animamos cor logo e posição com
		-- um pequeno delay para não se sobrescreverem — usamos task.defer para a posição.
		applyKnobColor(v)
		task.defer(applyKnobPos, v)
		if not silent and callback then self:_safeCall(callback, v) end
	end

	local click=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false},track)
	pcall(function() click.CursorIcon="rbxasset://SystemCursors/PointingHand" end)

	-- FIX: squeeze do knob usa objeto separado — aqui usamos knob diretamente mas
	-- o squeeze só afeta Size, enquanto apply() afeta Position (via defer).
	-- Para evitar conflito, o squeeze é feito inline sem tw() (direto, sem cancelar):
	click.MouseButton1Down:Connect(function()
		if _knobPressed then return end
		_knobPressed = true
		tw(knob, .07, {Size = UDim2.fromOffset(22, 18)})
	end)
	click.MouseButton1Up:Connect(function()
		_knobPressed = false
		tw(knob, .15, {Size = UDim2.fromOffset(20, 20)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	click.Activated:Connect(function()
		_knobPressed = false
		-- Restaura tamanho imediatamente antes de apply para não conflitar
		tw(knob, .15, {Size = UDim2.fromOffset(20, 20)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.defer(function() apply(not state) end)
	end)
	row.MouseEnter:Connect(function() tw(row,.12,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.15,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local t={Track=track,Knob=knob,Frame=row}
	function t:SetState(v) apply(v,true) end
	function t:GetState() return state end
	function t:Set(v) apply(v==true,true) end
	function t:Get() return state end
	return t
end

function Lib:AddCheckbox(pi,label,default,callback)
	local s=self:GetPage(pi); if not s then return end
	local state=default==true

	local row=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)

	local box=new("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),
		Size=UDim2.fromOffset(20,20),BackgroundColor3=state and accentOrWhite(self) or C.Card3,BorderSizePixel=0},row)
	corner(box,5)
	local bStroke=stroke(box,state and fromHex("aaaaaa") or C.Border2,1)

	local checkImg=new("ImageLabel",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(13,13),BackgroundTransparency=1,
		Image="rbxasset://textures/ui/CheckIcon.png",
		ImageColor3=C.Bg,ScaleType=Enum.ScaleType.Fit,
		ImageTransparency=state and 0 or 1,ZIndex=2},box)
	local check=new("TextLabel",{Text=string.char(226,156,147),Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.Bg,
		BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
		TextTransparency=1,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=3},box)

	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Position=UDim2.fromOffset(32,0),
		Size=UDim2.new(1,-32,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

	local checkIconWorks = false
	checkImg:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		if checkImg.IsLoaded and checkImg.AbsoluteSize.X > 0 then
			checkIconWorks = true
			check.TextTransparency = 1
		else
			check.TextTransparency = state and 0 or 1
		end
	end)
	task.defer(function()
		if not checkIconWorks then
			check.TextTransparency = state and 0 or 1
		end
	end)

	local function apply(v,silent)
		state=v
		local ac = accentOrWhite(self)
		tw(box,.18,{BackgroundColor3=v and ac or C.Card3},Enum.EasingStyle.Quart)
		tw(bStroke,.18,{Color=v and fromHex("aaaaaa") or C.Border2})
		tw(checkImg,.12,{ImageTransparency=v and 0 or 1})
		if not checkIconWorks then
			tw(check,.12,{TextTransparency=v and 0 or 1})
		end
		if not silent and callback then self:_safeCall(callback, v) end
	end

	local click=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false},row)
	pcall(function() click.CursorIcon="rbxasset://SystemCursors/PointingHand" end)
	click.Activated:Connect(function() apply(not state) end)
	row.MouseEnter:Connect(function() tw(row,.12,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.15,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=row,Box=box}
	function obj:SetState(v) apply(v,true) end
	function obj:GetState() return state end
	function obj:Set(v) apply(v==true,true) end
	function obj:Get() return state end
	return obj
end

function Lib:AddInput(pi,labelTxt,placeholder,callback,opts)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	opts = opts or {}
	local removeAfterFocus = opts.RemoveTextAfterFocusLost
	local clearOnFocus = opts.ClearTextOnFocus
	local multiLine = opts.MultiLine
	local textSize = opts.TextSize or 13
	if labelTxt then
		new("TextLabel",{Text=labelTxt,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
		self:_gap(s,pi,4)
	end
	local wrapH = multiLine and 80 or 44
	local wrap=new("Frame",{Size=UDim2.new(1,0,0,wrapH),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	wrap:SetAttribute("ComponentId", self:_nextCompId("Input"))
	corner(wrap,10)
	local ws=stroke(wrap,C.Border,1)
	pad(wrap,0,0,16,16)
	local box=new("TextBox",{Text="",PlaceholderText=placeholder or "",Font=Enum.Font.Gotham,TextSize=textSize,
		TextColor3=C.Text,PlaceholderColor3=C.TextOff,BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ClearTextOnFocus=clearOnFocus==true,
		TextXAlignment=Enum.TextXAlignment.Left,
		MultiLine=multiLine==true,TextWrapped=multiLine==true},wrap)
	box.Focused:Connect(function() tw(wrap,.16,{BackgroundColor3=C.Card2}); tw(ws,.16,{Color=accentOrWhite(self)}) end)
	box.FocusLost:Connect(function(enter)
		tw(wrap,.15,{BackgroundColor3=C.Card}); tw(ws,.18,{Color=C.Border})
		if callback then self:_safeCall(callback, box.Text, enter or UserInputService.TouchEnabled) end
		if removeAfterFocus then box.Text="" end
	end)
	wrap.MouseEnter:Connect(function() if not box:IsFocused() then tw(wrap,.12,{BackgroundColor3=C.Card2}) end end)
	wrap.MouseLeave:Connect(function() if not box:IsFocused() then tw(wrap,.15,{BackgroundColor3=C.Card}) end end)
	self:_gap(s,pi,10)
	local obj={TextBox=box,Frame=wrap}
	function obj:Set(v) if box and box.Parent then box.Text=tostring(v) end end
	function obj:Get() return box and box.Text or "" end
	function obj:Focus() if box and box.Parent then box:CaptureFocus() end end
	function obj:Clear() if box and box.Parent then box.Text="" end end
	return obj
end


function Lib:AddInputNumber(pi, labelTxt, opts, callback)
	if not self:_isAlive() then return end
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 999999999
	local step = opts.Step
	local placeholder = opts.Placeholder or tostring(min)
	local s=self:GetPage(pi); if not s then return end
	if labelTxt then
		new("TextLabel",{Text=labelTxt,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
		self:_gap(s,pi,4)
	end
	local wrap=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	wrap:SetAttribute("ComponentId", self:_nextCompId("InputNumber"))
	corner(wrap,10)
	local ws=stroke(wrap,C.Border,1)
	pad(wrap,0,0,16,16)
	local box=new("TextBox",{Text="",PlaceholderText=placeholder,Font=Enum.Font.Gotham,TextSize=13,
		TextColor3=C.Text,PlaceholderColor3=C.TextOff,BackgroundTransparency=1,
		Size=UDim2.new(1,-60,1,0),ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},wrap)
	box.Focused:Connect(function() tw(wrap,.16,{BackgroundColor3=C.Card2}); tw(ws,.16,{Color=accentOrWhite(self)}) end)
	local errLbl=new("TextLabel",{Text="",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.Red,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(56,20),TextXAlignment=Enum.TextXAlignment.Right},wrap)
	box.FocusLost:Connect(function(enter)
		tw(wrap,.15,{BackgroundColor3=C.Card}); tw(ws,.18,{Color=C.Border})
		local raw = box.Text:gsub("[^%d%.%-]","")
		local n = tonumber(raw)
		if n == nil then
			tw(ws,.12,{Color=C.Red})
			errLbl.Text="invalid"
		else
			if n < min then n=min elseif n > max then n=max end
			if step then n=math.floor(n/step+0.5)*step end
			box.Text=tostring(n)
			errLbl.Text=""
			if callback then self:_safeCall(callback, n, enter or UserInputService.TouchEnabled) end
		end
	end)
	wrap.MouseEnter:Connect(function() if not box:IsFocused() then tw(wrap,.12,{BackgroundColor3=C.Card2}) end end)
	wrap.MouseLeave:Connect(function() if not box:IsFocused() then tw(wrap,.15,{BackgroundColor3=C.Card}) end end)
	self:_gap(s,pi,10)
	local obj={TextBox=box,Frame=wrap}
	function obj:Set(v)
		if box and box.Parent then
			local n=tonumber(v) or min
			n=math.clamp(n,min,max)
			box.Text=tostring(n)
		end
	end
	function obj:Get() return tonumber(box.Text) or min end
	function obj:SetValid(valid, msg)
		if valid then
			tw(ws,.15,{Color=C.Green})
			errLbl.Text=msg or ""
			errLbl.TextColor3=C.Green
		else
			tw(ws,.15,{Color=C.Red})
			errLbl.Text=msg or "invalid"
			errLbl.TextColor3=C.Red
		end
	end
	return obj
end

function Lib:AddMultiSelect(pi, labelTxt, options, callback)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	options = validateTable(options, {})
	local selected = {}
	for _,opt in ipairs(options) do selected[opt]=false end

	local wrapper=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi),ClipsDescendants=false},s)
	wrapper:SetAttribute("ComponentId", self:_nextCompId("MultiSelect"))
	wrapper:SetAttribute("AriaRole","listbox")
	wrapper:SetAttribute("AriaLabel", validateString(labelTxt,"MultiSelect"))
	corner(wrapper,10)
	stroke(wrapper,C.Border,1)
	-- Stack header and expandable list vertically — critical for no-overlap
	new("UIListLayout",{
		FillDirection=Enum.FillDirection.Vertical,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,0),
	},wrapper)

	local header=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=0},wrapper)
	pad(header,0,0,16,16)
	new("TextLabel",{Text=labelTxt or "Select",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-56,1,0),TextXAlignment=Enum.TextXAlignment.Left},header)

	local countLbl=new("TextLabel",{Text="none",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-28,.5,0),
		Size=UDim2.new(.8,-40,0,20),TextXAlignment=Enum.TextXAlignment.Right,TextTruncate=Enum.TextTruncate.AtEnd},header)

	local listFrame=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.None,
		BackgroundColor3=C.Card,BorderSizePixel=0,Visible=false,LayoutOrder=1,ClipsDescendants=true},wrapper)
	-- Separator inside listFrame uses explicit position (no UIListLayout on listFrame itself)
	new("Frame",{Size=UDim2.new(1,-32,0,1),AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),
		BackgroundColor3=C.Border2,BorderSizePixel=0},listFrame)
	local listInner=new("Frame",{
		Position=UDim2.fromOffset(0,1),
		Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,BorderSizePixel=0},listFrame)
	vlist(listInner,0)

	local open=false
	local listH = 1 + math.max(#options, 1) * 40
	local toggleBtn=new("TextButton",{Text="",BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ZIndex=52,AutoButtonColor=false},header)

	local function refreshCount()
		local labels={}
		for opt,v in pairs(selected) do if v then labels[#labels+1]=tostring(opt) end end
		table.sort(labels)
		local joined = (#labels==0) and "none" or table.concat(labels,", ")
		countLbl.Text = joined
		if callback then self:_safeCall(callback, selected) end
	end

	local optionRows={}
	if #options == 0 then
		local empty=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=1},listInner)
		pad(empty,0,0,16,16)
		new("TextLabel",{Text="No options",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Left},empty)
	else
	for i,opt in ipairs(options) do
		local row=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,BorderSizePixel=0,
			LayoutOrder=i},listInner)
		row:SetAttribute("AriaRole","option")
		row:SetAttribute("AriaLabel", tostring(opt))
		pad(row,0,0,16,16)
		local hv=new("Frame",{BackgroundColor3=C.Card2,BackgroundTransparency=1,Size=UDim2.new(1,-2,1,-2),Position=UDim2.fromOffset(1,1),BorderSizePixel=0,ZIndex=52},row)
		corner(hv,8)
		local optLbl=new("TextLabel",{Text=tostring(opt),Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
			BackgroundTransparency=1,Position=UDim2.fromOffset(0,0),
			Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53},row)
		local btn=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
			ZIndex=54,AutoButtonColor=false},row)
		btn.Activated:Connect(function()
			selected[opt]=not selected[opt]
			local v=selected[opt]
			tw(hv,.18,{BackgroundTransparency=v and .2 or 1})
			refreshCount()
		end)
		btn.MouseEnter:Connect(function()
			if not selected[opt] then tw(hv,.2,{BackgroundTransparency=.2}) end
		end)
		btn.MouseLeave:Connect(function()
			if not selected[opt] then tw(hv,.22,{BackgroundTransparency=1}) end
		end)
		optionRows[i]={Row=row,Label=optLbl,Hv=hv,Key=opt}
	end
	end

	-- Arrow chevron indicator on the right side of header
	local arrowLbl=new("TextLabel",{
		Text="v",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
		BackgroundTransparency=1,
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),
		Size=UDim2.fromOffset(18,18),TextXAlignment=Enum.TextXAlignment.Center,
		ZIndex=53,
	},header)

	toggleBtn.Activated:Connect(function()
		if not self:_debounce("ms_toggle_"..tostring(labelTxt or ""),0.2) then return end
		open=not open
		tw(arrowLbl,.18,{Rotation=open and 180 or 0})
		if open then
			listFrame.Visible=true
			listFrame.Size=UDim2.new(1,0,0,0)
			tw(listFrame,.28,{Size=UDim2.new(1,0,0,listH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
			for _,entry in ipairs(optionRows) do
				local v=selected[entry.Key]
				if entry.Hv then entry.Hv.BackgroundTransparency = v and .2 or 1 end
			end
		else
			tw(listFrame,.22,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			task.delay(.19,function() if not open and listFrame and listFrame.Parent then listFrame.Visible=false end end)
		end
	end)
	header.MouseEnter:Connect(function() tw(wrapper,.15,{BackgroundColor3=C.Card2}) end)
	header.MouseLeave:Connect(function() tw(wrapper,.18,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=wrapper}
	function obj:GetSelected()
		local r={}
		for opt,v in pairs(selected) do if v then r[#r+1]=opt end end
		return r
	end
	function obj:SetSelected(tbl)
		for opt in pairs(selected) do selected[opt]=false end
		if type(tbl)=="table" then
			for _,opt in ipairs(tbl) do selected[opt]=true end
		end
		refreshCount()
	end
	function obj:IsSelected(opt) return selected[opt]==true end
	return obj
end

function Lib:AddList(pi, labelTxt, opts)
	opts = opts or {}
	local maxItems = opts.MaxItems or 50
	local itemH = opts.ItemHeight or 36
	local showIndex = opts.ShowIndex
	local s=self:GetPage(pi); if not s then return end
	local items = {}

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	-- UIListLayout ensures header and listFrame stack vertically, never overlap
	new("UIListLayout",{
		FillDirection=Enum.FillDirection.Vertical,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,0),
	},wrap)

	if labelTxt then
		local hdr=new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.Card3,BorderSizePixel=0,
			LayoutOrder=0},wrap)
		corner(hdr,10)
		-- Square off bottom corners via filler so card corners don't clip content
		new("Frame",{Position=UDim2.new(0,0,1,-6),Size=UDim2.new(1,0,0,6),BackgroundColor3=C.Card3,BorderSizePixel=0},hdr)
		pad(hdr,0,0,16,16)
		new("TextLabel",{Text=labelTxt,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Left},hdr)
	end

	local listFrame=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=1},wrap)
	vlist(listFrame,0)

	self:_gap(s,pi,8)

	local obj={Frame=wrap}
	function obj:Add(text, color)
		if #items >= maxItems then obj:RemoveAt(1) end
		local idx=#items+1
		local row=new("Frame",{Size=UDim2.new(1,0,0,itemH),BackgroundTransparency=1,
			BorderSizePixel=0,LayoutOrder=idx},listFrame)
		pad(row,0,4,16,16)
		local prefix=showIndex and (tostring(idx)..".  ") or ""
		local lbl=new("TextLabel",{Text=prefix..tostring(text),Font=Enum.Font.Gotham,TextSize=12,
			TextColor3=color or C.TextDim,BackgroundTransparency=1,
			Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
		row.BackgroundTransparency=1
		table.insert(items,{Row=row,Label=lbl,Text=text})
		return #items
	end
	function obj:RemoveAt(i)
		local item=items[i]
		if item and item.Row and item.Row.Parent then item.Row:Destroy() end
		table.remove(items,i)
	end
	function obj:Clear()
		for _,item in ipairs(items) do
			if item.Row and item.Row.Parent then item.Row:Destroy() end
		end
		items={}
	end
	function obj:GetItems()
		local r={}; for _,item in ipairs(items) do r[#r+1]=item.Text end; return r
	end
	function obj:Count() return #items end
	return obj
end

function Lib:AddTag(pi, text, style)
	local s=self:GetPage(pi); if not s then return end
	local colors={
		info    = {bg=C.BlueBg,  tc=C.Blue},
		success = {bg=C.GreenBg, tc=C.Green},
		warning = {bg=C.YellowBg,tc=C.Yellow},
		error   = {bg=C.RedBg,   tc=C.Red},
		muted   = {bg=C.Card2,   tc=C.TextDim},
		default = {bg=C.Card2,   tc=C.Text},
	}
	local st=colors[style or "default"] or colors.default
	local tag=new("TextLabel",{
		Text=" "..tostring(text).." ",
		Font=Enum.Font.GothamBold,TextSize=10,TextColor3=st.tc,
		BackgroundColor3=st.bg,BorderSizePixel=0,
		Size=UDim2.fromOffset(0,22),AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Center,
		LayoutOrder=self:_o(pi),
	},s)
	corner(tag,999)
	self:_gap(s,pi,6)
	local obj={Label=tag,Frame=tag}
	function obj:Set(v) if tag and tag.Parent then tag.Text=" "..tostring(v).." " end end
	function obj:SetStyle(newStyle)
		local ns=colors[newStyle] or colors.default
		tw(tag,.2,{BackgroundColor3=ns.bg,TextColor3=ns.tc})
		end
	return obj
end

function Lib:AddStatusBadge2(pi, label, state)
	local s=self:GetPage(pi); if not s then return end
	local stateColors={
		online  = C.Green,  offline = C.Red,
		idle    = C.Yellow, loading = C.Blue,
	}
	local row=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)
	new("TextLabel",{Text=label or "Status",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-110,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)
	local dot=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-44,.5,0),
		Size=UDim2.fromOffset(8,8),BackgroundColor3=stateColors[state or "offline"] or C.TextDim,BorderSizePixel=0},row)
	corner(dot,4)
	local stateLbl=new("TextLabel",{Text=string.upper(state or "offline"),Font=Enum.Font.GothamBold,TextSize=10,
		TextColor3=stateColors[state or "offline"] or C.TextDim,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(90,20),TextXAlignment=Enum.TextXAlignment.Right},row)
	self:_gap(s,pi,6)
	local obj={Frame=row}
	function obj:SetState(v)
		local col=stateColors[v] or C.TextDim
		tw(dot,.2,{BackgroundColor3=col})
		tw(stateLbl,.2,{TextColor3=col})
		stateLbl.Text=string.upper(v or "")
	end
	return obj
end

function Lib:AddSearchInput(pi,placeholder,callback)
	return self:AddInput(pi, nil, placeholder or "Search...", callback)
end

function Lib:AddStepper(pi,label,min,max,default,step,callback)
	local s=self:GetPage(pi); if not s then return end
	min=min or 0; max=max or 100; step=step or 1
	local val=math.clamp(default or min,min,max)

	local row=new("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)

	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-130,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

	local ctrl=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(120,34),BackgroundColor3=C.Card3,BorderSizePixel=0},row)
	corner(ctrl,8)
	stroke(ctrl,C.Border2,1)

	local function mkSBtn(txt,xA,xP,lo)
		local b=new("TextButton",{Text=txt,Font=Enum.Font.GothamBold,TextSize=15,TextColor3=C.TextDim,
			BackgroundColor3=C.Card3,BorderSizePixel=0,
			AnchorPoint=Vector2.new(xA,.5),Position=UDim2.new(xP,0,.5,0),
			Size=UDim2.fromOffset(34,34),AutoButtonColor=false,LayoutOrder=lo},ctrl)
		corner(b,8)
		b.MouseEnter:Connect(function() tw(b,.12,{BackgroundColor3=C.Card2,TextColor3=C.White}) end)
		b.MouseLeave:Connect(function() tw(b,.15,{BackgroundColor3=C.Card3,TextColor3=C.TextDim}) end)
		b.MouseButton1Down:Connect(function() tw(b,.07,{Size=UDim2.fromOffset(32,32)}) end)
		b.MouseButton1Up:Connect(function() tw(b,.15,{Size=UDim2.fromOffset(34,34)},Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
		pcall(function() b.CursorIcon="rbxasset://SystemCursors/PointingHand" end)
		return b
	end

	local minusBtn=mkSBtn("-",0,0,0)
	local plusBtn=mkSBtn("+",1,1,2)
	local valLbl=new("TextLabel",{Text=tostring(val),Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(52,34),TextXAlignment=Enum.TextXAlignment.Center},ctrl)

	local function update(delta)
		val=math.clamp(val+delta,min,max)
		tw(valLbl,.06,{TextTransparency=.7})
		task.delay(.07,function()
			if valLbl and valLbl.Parent then
				valLbl.Text=tostring(val)
				tw(valLbl,.14,{TextTransparency=0})
			end
		end)
		if callback then self:_safeCall(callback, val) end
	end

	minusBtn.Activated:Connect(function()
		if not self:_debounce("stepper_"..tostring(label or "").."_-",0.08) then return end
		update(-step)
	end)
	plusBtn.Activated:Connect(function()
		if not self:_debounce("stepper_"..tostring(label or "").."_+",0.08) then return end
		update(step)
	end)
	row.MouseEnter:Connect(function() tw(row,.12,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.15,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=row,ValueLabel=valLbl}
	function obj:GetValue() return val end
	function obj:SetValue(v) val=math.clamp(v,min,max); valLbl.Text=tostring(val) end
	return obj
end

function Lib:AddSlider(pi,label,min,max,default,callback)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	min=min or 0; max=max or 100
	if max < min then max, min = min, max end
	local range = (max - min)
	if range == 0 then range = 1 end
	default=math.clamp(default or min,min,max)

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	wrap:SetAttribute("ComponentId", self:_nextCompId("Slider"))
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	pad(wrap,12,12,16,16)

	local topRow=new("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1},wrap)
	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-50,1,0),TextXAlignment=Enum.TextXAlignment.Left},topRow)
	local valLbl=new("TextLabel",{Text=tostring(default),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
		Size=UDim2.fromOffset(50,18),TextXAlignment=Enum.TextXAlignment.Right},topRow)

	local trackBg=new("Frame",{Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,0,0,6),
		BackgroundColor3=C.Card3,BorderSizePixel=0},wrap)
	corner(trackBg,3)
	local fill=new("Frame",{Size=UDim2.fromScale((default-min)/(range),1),BackgroundColor3=C.White,BorderSizePixel=0},trackBg)
	corner(fill,3)
	local knobSl=new("Frame",{AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.new((default-min)/(range),0,.5,0),
		Size=UDim2.fromOffset(14,14),BackgroundColor3=C.White,BorderSizePixel=0,ZIndex=3},trackBg)
	corner(knobSl,7)

	local dragging=false
	local curVal = default
	local interact=new("TextButton",{Text="",BackgroundTransparency=1,
		Size=UDim2.new(1,0,1,14),Position=UDim2.fromOffset(0,-7),ZIndex=4,AutoButtonColor=false},trackBg)
	pcall(function() interact.CursorIcon="rbxasset://SystemCursors/PointingHand" end)

	local function updateVal(absX)
		local rel=math.clamp((absX-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
		local v=math.floor(min+rel*(range)+.5)
		local pct=(v-min)/(range)
		tw(fill,.06,{Size=UDim2.fromScale(pct,1)})
		tw(knobSl,.06,{Position=UDim2.new(pct,0,.5,0)})
		valLbl.Text=tostring(v)
		curVal = v
	end

	interact.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			updateVal(i.Position.X)
		end
	end)
	table.insert(self._conns,UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			if dragging and callback then self:_safeCall(callback, curVal) end
			dragging=false
		end
	end))
	table.insert(self._conns,UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			updateVal(i.Position.X)
		end
	end))
	wrap.MouseEnter:Connect(function() tw(wrap,.12,{BackgroundColor3=C.Card2}) end)
	wrap.MouseLeave:Connect(function() tw(wrap,.15,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=wrap,Fill=fill,Knob=knobSl,ValueLabel=valLbl,_min=min,_max=max}
	function obj:SetValue(v)
		v=math.clamp(v,self._min,self._max)
		local denom = (self._max - self._min)
		if denom == 0 then denom = 1 end
		local pct=(v-self._min)/denom
		tw(self.Fill,.15,{Size=UDim2.fromScale(pct,1)})
		tw(self.Knob,.15,{Position=UDim2.new(pct,0,.5,0)})
		self.ValueLabel.Text=tostring(v)
		curVal = v
	end
	return obj
end

function Lib:AddDropdown(pi,labelTxt,options,callback)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	options = validateTable(options, {})
	if labelTxt then
		new("TextLabel",{Text=labelTxt,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
		self:_gap(s,pi,4)
	end

	local selected=options[1] or ""
	local open=false
	local wrapper=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,ClipsDescendants=false,LayoutOrder=self:_o(pi),ZIndex=50},s)
	wrapper:SetAttribute("ComponentId", self:_nextCompId("Dropdown"))

	local btn=new("TextButton",{Text="",BackgroundColor3=C.Card,BorderSizePixel=0,
		Size=UDim2.new(1,0,0,44),AutoButtonColor=false,ZIndex=51},wrapper)
	corner(btn,10)
	local bStroke=stroke(btn,C.Border,1)
	pad(btn,0,0,16,16)
	hlist(btn,0)

	local selLbl=new("TextLabel",{Text=selected,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-22,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52,LayoutOrder=0},btn)
	local arrowImg=new("ImageLabel",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(12,12),BackgroundTransparency=1,
		Image="rbxasset://textures/ui/ArrowDown.png",
		ImageColor3=C.TextDim,ScaleType=Enum.ScaleType.Fit,ZIndex=53},new("Frame",{
		BackgroundTransparency=1,Size=UDim2.fromOffset(22,22),ZIndex=52,LayoutOrder=1},btn))
	local arrow=new("TextLabel",{Text="v",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
		TextXAlignment=Enum.TextXAlignment.Center,ZIndex=52},arrowImg.Parent)
	arrow.Visible = false

	local listH=math.max(#options,1)*40
	local optList=new("Frame",{Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,0,0),
		BackgroundColor3=C.Card,BorderSizePixel=0,ClipsDescendants=true,ZIndex=60,Visible=false},wrapper)
	corner(optList,10)
	stroke(optList,C.Border2,1)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},optList)
	-- separator superior para consistência com multi-select
	new("Frame",{Size=UDim2.new(1,-32,0,1),AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),
		BackgroundColor3=C.Border2,BorderSizePixel=0},optList)
	wrapper:SetAttribute("AriaRole","listbox")
	wrapper:SetAttribute("AriaLabel", validateString(labelTxt,"Dropdown"))
	optList:SetAttribute("AriaRole","list")

	local optionRows = {}
	local highlightedIndex = 0
	local function isSelectedOpt(i)
		return options[i] == selected
	end
	local function applyBaseState(i)
		local entry = optionRows[i]
		local hv = entry and entry.Hv
		if not hv then return end
		hv.BackgroundTransparency = isSelectedOpt(i) and 0.1 or 1
	end
	local function setHighlight(idx)
		for i,entry in ipairs(optionRows) do
			local hv = entry and entry.Hv
			if not hv then
			else
			if i == idx then
				tw(hv,.18,{BackgroundTransparency=.2})
			else
				tw(hv,.18,{BackgroundTransparency=isSelectedOpt(i) and .1 or 1})
			end
			end
		end
		highlightedIndex = idx
	end
	local function updateSelectedVisual()
		for i,_ in ipairs(optionRows) do
			applyBaseState(i)
		end
	end
	local keyConnOpen = nil

	if #options == 0 then
		local ob=new("TextButton",{Text="No options",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TextDim,
			BackgroundColor3=C.Card,BackgroundTransparency=1,BorderSizePixel=0,
			Size=UDim2.new(1,0,0,40),AutoButtonColor=false,LayoutOrder=1,ZIndex=61,
			TextXAlignment=Enum.TextXAlignment.Left},optList)
		pad(ob,0,0,16,16)
	else
	for i,opt in ipairs(options) do
		local row=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=i,ZIndex=61},optList)
		local hv=new("Frame",{BackgroundColor3=C.Card2,BackgroundTransparency=1,Size=UDim2.new(1,-2,1,-2),Position=UDim2.fromOffset(1,1),BorderSizePixel=0,ZIndex=60},row)
		corner(hv,8)
		new("TextLabel",{Text=opt,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
			BackgroundTransparency=1,Size=UDim2.new(1,-16,1,0),Position=UDim2.fromOffset(16,0),
			TextXAlignment=Enum.TextXAlignment.Left,ZIndex=61},row)
		row:SetAttribute("AriaRole","option")
		row:SetAttribute("AriaLabel", tostring(opt))
		local btnOpt=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=62},row)
		btnOpt.MouseEnter:Connect(function() tw(hv,.18,{BackgroundTransparency=.2}) end)
		btnOpt.MouseLeave:Connect(function()
			if options[i]==selected then tw(hv,.18,{BackgroundTransparency=.1}) else tw(hv,.2,{BackgroundTransparency=1}) end
		end)
		btnOpt.Activated:Connect(function()
			selected=opt; selLbl.Text=opt; open=false
			tw(hv,.16,{BackgroundTransparency=.1})
			tw(optList,.22,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			tw(arrow,.18,{Rotation=0})
			tw(arrowImg,.18,{Rotation=0})
			task.delay(.2,function() if optList then optList.Visible=false end end)
			if callback then self:_safeCall(callback, opt) end
			if keyConnOpen then pcall(function() keyConnOpen:Disconnect() end) end
		end)
		optionRows[i] = {Row=row, Hv=hv}
	end
	end

	btn.MouseEnter:Connect(function() tw(btn,.12,{BackgroundColor3=C.Card2}) end)
	btn.MouseLeave:Connect(function() tw(btn,.15,{BackgroundColor3=C.Card}) end)
	pcall(function() btn.CursorIcon="rbxasset://SystemCursors/PointingHand" end)
	btn.Activated:Connect(function()
		if not self:_debounce("dd_toggle_"..tostring(labelTxt or ""),0.2) then return end
		open=not open; optList.Visible=true
		if open then
			tw(optList,.28,{Size=UDim2.new(1,0,0,listH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
			tw(arrow,.2,{Rotation=180}); tw(arrowImg,.2,{Rotation=180})
			if #optionRows > 0 then
				updateSelectedVisual()
				setHighlight(1)
				if keyConnOpen then pcall(function() keyConnOpen:Disconnect() end) end
				keyConnOpen = UserInputService.InputBegan:Connect(function(i, gp)
					if gp then return end
					if not open then return end
					if i.KeyCode == Enum.KeyCode.Down then
						local nx = math.clamp(highlightedIndex+1,1,#optionRows)
						setHighlight(nx)
					elseif i.KeyCode == Enum.KeyCode.Up then
						local nx = math.clamp(highlightedIndex-1,1,#optionRows)
						setHighlight(nx)
					elseif i.KeyCode == Enum.KeyCode.Return or i.KeyCode == Enum.KeyCode.KeypadEnter then
						local entry = optionRows[highlightedIndex]
						if entry and entry.Row then
							local b = entry.Row:FindFirstChildWhichIsA("TextButton")
							if b then b:Activate() end
						end
					elseif i.KeyCode == Enum.KeyCode.Escape then
						open=false
						tw(optList,.22,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
						tw(arrow,.2,{Rotation=0}); tw(arrowImg,.2,{Rotation=0})
						task.delay(.2,function() if optList then optList.Visible=false end end)
						if keyConnOpen then pcall(function() keyConnOpen:Disconnect() end) end
					end
				end)
			end
		else
			tw(optList,.22,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			tw(arrow,.2,{Rotation=0}); tw(arrowImg,.2,{Rotation=0})
			task.delay(.2,function() if optList then optList.Visible=false end end)
			if keyConnOpen then pcall(function() keyConnOpen:Disconnect() end) end
		end
	end)

	self:_gap(s,pi,10)
	return {Button=btn,List=optList,GetSelected=function() return selected end}
end

function Lib:AddRadioGroup(pi,label,options,default,callback)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	options = validateTable(options, {})
	local selected=default or (options[1] or "")

	if label then
		new("TextLabel",{Text=label,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
		self:_gap(s,pi,4)
	end

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	wrap:SetAttribute("ComponentId", self:_nextCompId("RadioGroup"))
	corner(wrap,10)
	stroke(wrap,C.Border,1)

	local items={}
	if #options == 0 then
		local wrap=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
		corner(wrap,10)
		stroke(wrap,C.Border,1)
		pad(wrap,0,0,16,16)
		new("TextLabel",{Text="No options",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Left},wrap)
		self:_gap(s,pi,6)
		return {Frame=wrap, GetSelected=function() return "" end}
	end
	for i,opt in ipairs(options) do
		local isLast=i==#options
		local row=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=i},wrap)
		pad(row,0,0,16,16)
		if not isLast then
			new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},row)
		end

		local isActive=opt==selected
		local ac = accentOrWhite(self)
		local radio=new("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),
			Size=UDim2.fromOffset(18,18),BackgroundColor3=isActive and ac or C.Card3,BorderSizePixel=0},row)
		corner(radio,9)
		stroke(radio,isActive and fromHex("aaaaaa") or C.Border2,1)

		local dot=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
			Size=UDim2.fromOffset(isActive and 8 or 0,isActive and 8 or 0),
			BackgroundColor3=C.Bg,BorderSizePixel=0},radio)
		corner(dot,4)

		local lbl=new("TextLabel",{Text=opt,Font=Enum.Font.Gotham,TextSize=13,
			TextColor3=isActive and C.White or C.Text,BackgroundTransparency=1,
			Position=UDim2.fromOffset(28,0),Size=UDim2.new(1,-28,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

		items[opt]={Radio=radio,Dot=dot,Label=lbl}

		local click=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false},row)
		pcall(function() click.CursorIcon="rbxasset://SystemCursors/PointingHand" end)
		click.MouseEnter:Connect(function() if opt~=selected then tw(row,.12,{BackgroundTransparency=.93}) end end)
		click.MouseLeave:Connect(function() tw(row,.15,{BackgroundTransparency=1}) end)
		click.Activated:Connect(function()
			if selected==opt then return end
			for k,v in pairs(items) do
				local a=k==opt
				local ac = accentOrWhite(self)
				tw(v.Radio,.2,{BackgroundColor3=a and ac or C.Card3})
				tw(v.Dot,.2,{Size=a and UDim2.fromOffset(8,8) or UDim2.fromOffset(0,0)})
				tw(v.Label,.2,{TextColor3=a and C.White or C.Text})
			end
			selected=opt
			if callback then self:_safeCall(callback, opt) end
		end)
	end

	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},wrap)
	self:_gap(s,pi,6)
	local libSelf = self  -- capture Lib instance for use inside obj methods
	local obj={Frame=wrap}
	function obj:GetSelected() return selected end
	function obj:SetSelected(v)
		if not items[v] then return end
		for k,item in pairs(items) do
			local a=k==v
			local ac = accentOrWhite(libSelf)
			tw(item.Radio,.2,{BackgroundColor3=a and ac or C.Card3})
			tw(item.Dot,.2,{Size=a and UDim2.fromOffset(8,8) or UDim2.fromOffset(0,0)})
			tw(item.Label,.2,{TextColor3=a and C.White or C.Text})
		end
		selected=v
	end
	return obj
end

function Lib:AddColorPicker(pi,label,default,callback)
	local s=self:GetPage(pi); if not s then return end

	local function hsvToRgb(h,sv,v)
		h=h%360; local c=v*sv; local x=c*(1-math.abs((h/60)%2-1)); local m=v-c
		local r,g,b
		if h<60 then r,g,b=c,x,0 elseif h<120 then r,g,b=x,c,0
		elseif h<180 then r,g,b=0,c,x elseif h<240 then r,g,b=0,x,c
		elseif h<300 then r,g,b=x,0,c else r,g,b=c,0,x end
		return Color3.new(r+m,g+m,b+m)
	end
	local function rgbToHsv(col)
		local r,g,b=col.R,col.G,col.B
		local mx=math.max(r,g,b); local mn=math.min(r,g,b); local d=mx-mn
		local h,sv,v=0,mx==0 and 0 or d/mx,mx
		if mx~=mn then
			if mx==r then h=(g-b)/d+(g<b and 6 or 0)
			elseif mx==g then h=(b-r)/d+2 else h=(r-g)/d+4 end
			h=h*60
		end
		return h,sv,v
	end
	local function toHex(col)
		return string.format("%02x%02x%02x",math.floor(col.R*255+.5),math.floor(col.G*255+.5),math.floor(col.B*255+.5))
	end

	local initColor = type(default)=="string" and fromHex(default) or default or fromHex("4488ff")
	local hue,sat,val = rgbToHsv(initColor)
	local currentColor = initColor
	local popupOpen = false
	local activePopup = nil

	local row=new("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)

	new("TextLabel",{Text=label or "Color",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-72,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

	local preview=new("TextButton",{Text="",BackgroundColor3=currentColor,BorderSizePixel=0,
		AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(52,32),AutoButtonColor=false},row)
	corner(preview,8)
	stroke(preview,C.Border2,1)
	pcall(function() preview.CursorIcon="rbxasset://SystemCursors/PointingHand" end)

	local function closePopup()
		if not activePopup then return end
		popupOpen=false
		local p=activePopup; activePopup=nil
		tw(p,.18,{BackgroundTransparency=1,Size=UDim2.fromOffset(p.AbsoluteSize.X*0.95,p.AbsoluteSize.Y*0.95)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.2,function() if p and p.Parent then p:Destroy() end end)
	end

	local function openPopup()
		if popupOpen then closePopup(); return end
		popupOpen=true

		local SV_W,SV_H=190,120
		local PW,PH=SV_W+32,SV_H+130

		local popup=new("Frame",{
			AnchorPoint=Vector2.new(.5,.5),
			Position=UDim2.fromScale(.5,.5),
			Size=UDim2.fromOffset(PW*0.9,PH*0.9),
			BackgroundColor3=C.Card,
			BorderSizePixel=0,ZIndex=500,
			BackgroundTransparency=1,
		},self._sg)
		corner(popup,12)
		stroke(popup,C.Border2,1)
		tw(popup,.3,{BackgroundTransparency=0,Size=UDim2.fromOffset(PW,PH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		activePopup=popup

		local hexBox

		local function updatePreview()
			preview.BackgroundColor3=currentColor
			if hexBox then hexBox.Text=toHex(currentColor) end
		end
		local function applyColor()
			preview.BackgroundColor3=currentColor
			if hexBox then hexBox.Text=toHex(currentColor) end
		end
		local function commitColor()
			preview.BackgroundColor3=currentColor
			if hexBox then hexBox.Text=toHex(currentColor) end
			if callback then self:_safeCall(callback, currentColor, toHex(currentColor)) end
		end

		local svBox=new("Frame",{
			AnchorPoint=Vector2.new(.5,0),
			Position=UDim2.new(.5,0,0,16),
			Size=UDim2.fromOffset(SV_W,SV_H),
			BackgroundColor3=hsvToRgb(hue,1,1),
			BorderSizePixel=0,ZIndex=501,
			ClipsDescendants=true,
		},popup)
		corner(svBox,8)

		local wOverlay=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=502},svBox)
		new("UIGradient",{
			Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),
			Rotation=0,
		},wOverlay)

		local bOverlay=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=503},svBox)
		new("UIGradient",{
			Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),
			Rotation=90,
		},bOverlay)

		local svCursor=new("Frame",{
			AnchorPoint=Vector2.new(.5,.5),
			Position=UDim2.new(sat,0,1-val,0),
			Size=UDim2.fromOffset(14,14),
			BackgroundColor3=Color3.new(1,1,1),
			BorderSizePixel=0,ZIndex=505,
		},svBox)
		corner(svCursor,7)
		stroke(svCursor,C.Bg,2)

		local svDragging=false
		local svInteract=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=506,AutoButtonColor=false},bOverlay)

		local function updateSV(ax,ay)
			local rx=math.clamp((ax-svBox.AbsolutePosition.X)/svBox.AbsoluteSize.X,0,1)
			local ry=math.clamp((ay-svBox.AbsolutePosition.Y)/svBox.AbsoluteSize.Y,0,1)
			sat=rx; val=1-ry
			svCursor.Position=UDim2.new(rx,0,ry,0)
			currentColor=hsvToRgb(hue,sat,val)
			applyColor()
		end

		svInteract.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				svDragging=true
				updateSV(i.Position.X,i.Position.Y)
			end
		end)
		local c1=UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svDragging=false end
		end)
		local c2=UserInputService.InputChanged:Connect(function(i)
			if svDragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
				updateSV(i.Position.X,i.Position.Y)
			end
		end)

		local hueBar=new("Frame",{
			AnchorPoint=Vector2.new(.5,0),
			Position=UDim2.new(.5,0,0,16+SV_H+10),
			Size=UDim2.fromOffset(SV_W,16),
			BackgroundColor3=C.Card3,
			BorderSizePixel=0,ZIndex=501,
		},popup)
		corner(hueBar,8)
		new("UIGradient",{
			Color=ColorSequence.new({
				ColorSequenceKeypoint.new(0/6,  Color3.fromHSV(0/6,1,1)),
				ColorSequenceKeypoint.new(1/6,  Color3.fromHSV(1/6,1,1)),
				ColorSequenceKeypoint.new(2/6,  Color3.fromHSV(2/6,1,1)),
				ColorSequenceKeypoint.new(3/6,  Color3.fromHSV(3/6,1,1)),
				ColorSequenceKeypoint.new(4/6,  Color3.fromHSV(4/6,1,1)),
				ColorSequenceKeypoint.new(5/6,  Color3.fromHSV(5/6,1,1)),
				ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,1,1)),
			}),
		},hueBar)

		local hueKnob=new("Frame",{
			AnchorPoint=Vector2.new(.5,.5),
			Position=UDim2.new(hue/360,0,.5,0),
			Size=UDim2.fromOffset(8,22),
			BackgroundColor3=Color3.new(1,1,1),
			BorderSizePixel=0,ZIndex=503,
		},hueBar)
		corner(hueKnob,3)
		stroke(hueKnob,C.Bg,1)

		local hueDragging=false
		local hueInteract=new("TextButton",{Text="",BackgroundTransparency=1,
			Size=UDim2.new(1,0,1,10),Position=UDim2.fromOffset(0,-5),ZIndex=504,AutoButtonColor=false},hueBar)

		local function updateHue(ax)
			local rel=math.clamp((ax-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
			hue=rel*360
			hueKnob.Position=UDim2.new(rel,0,.5,0)
			svBox.BackgroundColor3=hsvToRgb(hue,1,1)
			currentColor=hsvToRgb(hue,sat,val)
			applyColor()
		end

		hueInteract.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				hueDragging=true
				updateHue(i.Position.X)
			end
		end)
		local c3=UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hueDragging=false end
		end)
		local c4=UserInputService.InputChanged:Connect(function(i)
			if hueDragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
				updateHue(i.Position.X)
			end
		end)

		local hexRow=new("Frame",{
			AnchorPoint=Vector2.new(.5,0),
			Position=UDim2.new(.5,0,0,16+SV_H+10+16+12),
			Size=UDim2.fromOffset(SV_W,38),
			BackgroundTransparency=1,ZIndex=501,
		},popup)
		hlist(hexRow,8)

		new("TextLabel",{Text="#",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TextDim,
			BackgroundTransparency=1,Size=UDim2.fromOffset(14,38),
			TextXAlignment=Enum.TextXAlignment.Center,ZIndex=502,LayoutOrder=0},hexRow)

		local hexWrap=new("Frame",{Size=UDim2.new(1,-90,1,0),BackgroundColor3=C.Card3,
			BorderSizePixel=0,ZIndex=502,LayoutOrder=1},hexRow)
		corner(hexWrap,8)
		local hexStroke=stroke(hexWrap,C.Border2,1)
		pad(hexWrap,0,0,10,10)
		hexBox=new("TextBox",{Text=toHex(currentColor),Font=Enum.Font.Code,TextSize=13,
			TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
			ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=503},hexWrap)
		hexBox.Focused:Connect(function() tw(hexWrap,.14,{BackgroundColor3=C.Card2}); tw(hexStroke,.14,{Color=C.Border3}) end)
		hexBox.FocusLost:Connect(function()
			tw(hexWrap,.16,{BackgroundColor3=C.Card3}); tw(hexStroke,.16,{Color=C.Border2})
			local h=hexBox.Text:gsub("[^%x]","")
			if #h==3 then h=h:sub(1,1):rep(2)..h:sub(2,2):rep(2)..h:sub(3,3):rep(2) end
			if #h==6 then
				local ok,col=pcall(fromHex,h)
				if ok and col then
					currentColor=col
					hue,sat,val=rgbToHsv(col)
					svBox.BackgroundColor3=hsvToRgb(hue,1,1)
					hueKnob.Position=UDim2.new(hue/360,0,.5,0)
					svCursor.Position=UDim2.new(sat,0,1-val,0)
					hexBox.Text=h
					preview.BackgroundColor3=col
					if callback then self:_safeCall(callback, col, h) end
				end
			else
				hexBox.Text=toHex(currentColor)
			end
		end)

		local applyBtn=new("TextButton",{Text="Apply",Font=Enum.Font.GothamBold,TextSize=12,
			TextColor3=C.Bg,BackgroundColor3=C.White,BorderSizePixel=0,
			Size=UDim2.fromOffset(64,38),AutoButtonColor=false,ZIndex=502,LayoutOrder=2},hexRow)
		corner(applyBtn,8)
		applyBtn.MouseEnter:Connect(function() tw(applyBtn,.12,{BackgroundColor3=fromHex("e0e0e0")}) end)
		applyBtn.MouseLeave:Connect(function() tw(applyBtn,.15,{BackgroundColor3=C.White}) end)
		applyBtn.Activated:Connect(function()
			commitColor()
			local cc1,cc2=c1,c2; local cc3,cc4=c3,c4
			cc1:Disconnect(); cc2:Disconnect(); cc3:Disconnect(); cc4:Disconnect()
			closePopup()
		end)

		local overlay=new("TextButton",{Text="",BackgroundTransparency=1,
			Size=UDim2.fromScale(1,1),ZIndex=499,AutoButtonColor=false},self._sg)
		overlay.Activated:Connect(function()
			overlay:Destroy()
			c1:Disconnect(); c2:Disconnect(); c3:Disconnect(); c4:Disconnect()
			closePopup()
		end)
	end

	preview.MouseEnter:Connect(function() tw(preview,.12,{Size=UDim2.fromOffset(54,34)}) end)
	preview.MouseLeave:Connect(function() tw(preview,.15,{Size=UDim2.fromOffset(52,32)}) end)
	preview.Activated:Connect(openPopup)
	row.MouseEnter:Connect(function() tw(row,.12,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.15,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=row,Preview=preview}
	function obj:GetColor() return currentColor,toHex(currentColor) end
	function obj:SetColor(c)
		if type(c)=="string" then c=fromHex(c) end
		currentColor=c; preview.BackgroundColor3=c
		hue,sat,val=rgbToHsv(c)
	end
	return obj
end

function Lib:AddCard(pi,title,subtitle)
	local s=self:GetPage(pi); if not s then return end
	local card=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(card,10)
	stroke(card,C.Border,1)
	-- Stack header and inner content via layout — eliminates overlap regardless of header height
	new("UIListLayout",{
		FillDirection=Enum.FillDirection.Vertical,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,0),
	},card)

	if title then
		local hdrH = subtitle and 54 or 42
		local hdr=new("Frame",{Size=UDim2.new(1,0,0,hdrH),BackgroundColor3=C.Card2,BorderSizePixel=0,
			LayoutOrder=0},card)
		corner(hdr,10)
		new("Frame",{Position=UDim2.new(0,0,1,-11),Size=UDim2.new(1,0,0,11),BackgroundColor3=C.Card2,BorderSizePixel=0},hdr)
		new("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},hdr)
		pad(hdr,0,0,16,16)
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,
			BackgroundTransparency=1,Position=UDim2.fromOffset(0,11),
			Size=UDim2.new(1,0,0,20),TextXAlignment=Enum.TextXAlignment.Left},hdr)
		if subtitle then
			new("TextLabel",{Text=subtitle,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TextDim,
				BackgroundTransparency=1,Position=UDim2.fromOffset(0,33),
				Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},hdr)
		end
	end

	local inner=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,LayoutOrder=1},card)
	pad(inner,14,14,16,16)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},inner)
	self:_gap(s,pi,10)
	return inner
end

function Lib:AddLogConsole(pi,height)
	local s=self:GetPage(pi); if not s then return end
	local frame=new("Frame",{Size=UDim2.new(1,0,0,height or 220),BackgroundColor3=fromHex("050505"),
		BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=self:_o(pi)},s)
	corner(frame,10)
	stroke(frame,C.Border,1)

	local hdr=new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.Card,BorderSizePixel=0},frame)
	corner(hdr,10)
	new("Frame",{Position=UDim2.new(0,0,1,-11),Size=UDim2.new(1,0,0,11),BackgroundColor3=C.Card,BorderSizePixel=0},hdr)
	new("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},hdr)
	pad(hdr,0,0,14,14)
	hlist(hdr,8)

	local dot=new("Frame",{Size=UDim2.fromOffset(7,7),BackgroundColor3=C.Green,BorderSizePixel=0,LayoutOrder=0},hdr)
	corner(dot,4)
	new("TextLabel",{Text="CONSOLE",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},hdr)

	local scroll=new("ScrollingFrame",{
		Position=UDim2.fromOffset(0,35),Size=UDim2.new(1,0,1,-35),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=5,ScrollBarImageColor3=C.Border3,ScrollBarImageTransparency=.2,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		ScrollingDirection=Enum.ScrollingDirection.Y,
		ZIndex=2,
	},frame)
	pad(scroll,6,6,12,12)
	local layout=new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)},scroll)

	self:_gap(s,pi,10)
	local lineCount=0
	local console={Frame=frame,_dot=dot,_lines={},_scroll=scroll,_layout=layout}
	local pfx={INFO="[INFO]  ",SUCCESS="[OK]    ",WARN="[WARN]  ",ERROR="[ERR]   ",SNIPE="[SNIPE] ",DEBUG="[DBG]   "}
	local colMap={INFO=C.TextDim,SUCCESS=C.Green,WARN=C.Yellow,ERROR=C.Red,SNIPE=C.Purple,DEBUG=C.Blue}

	function console:Log(msg,level)
		local lv=string.upper(level or "INFO")
		local ts=os.date("%H:%M:%S")
		local line=("%s  %s  %s"):format(ts,pfx[lv] or "[INFO]  ",tostring(msg))
		lineCount=lineCount+1
		local lbl=new("TextLabel",{
			Text=line,Font=Enum.Font.Code,TextSize=11,
			TextColor3=colMap[lv] or C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
			TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
			LayoutOrder=lineCount,ZIndex=3,
		},self._scroll)
		local children=self._scroll:GetChildren()
		local labelCount=0
		for _,c in ipairs(children) do
			if c:IsA("TextLabel") then labelCount=labelCount+1 end
		end
		if labelCount>60 then
			for _,c in ipairs(self._scroll:GetChildren()) do
				if c:IsA("TextLabel") then c:Destroy(); break end
			end
		end
		task.defer(function()
			if self._scroll and self._scroll.Parent then
				self._scroll.CanvasPosition=Vector2.new(0,math.huge)
			end
		end)
	end
	function console:Clear()
		for _,c in ipairs(self._scroll:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		lineCount=0
	end
	function console:SetActive(v) tw(self._dot,.2,{BackgroundColor3=v and C.Green or C.Red}) end
	return console
end

function Lib:AddSpinner(pi,label)
	local s=self:GetPage(pi); if not s then return end
	local row=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)
	hlist(row,12)

	local spinWrap=new("Frame",{Size=UDim2.fromOffset(22,22),BackgroundTransparency=1,LayoutOrder=0},row)

	local track=new("Frame",{
		Size=UDim2.fromOffset(22,22),BackgroundTransparency=1,BorderSizePixel=0,
		AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
	},spinWrap)
	corner(track,11)
	stroke(track,C.Border3,2)

	local ballHolder=new("Frame",{
		Size=UDim2.fromOffset(22,22),BackgroundTransparency=1,
		AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
	},spinWrap)

	local ball=new("Frame",{
		Size=UDim2.fromOffset(7,7),BackgroundColor3=C.White,BorderSizePixel=0,
		AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,0,3.5),
	},ballHolder)
	corner(ball,4)

	new("TextLabel",{Text=label or "Loading...",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,-36,1,0),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},row)

	local spinning=true
	local angle=0
	local _gen=0  -- generation counter prevents stale loops on Start()/Stop() cycles
	_gen=_gen+1; local myGen=_gen
	task.spawn(function()
		while spinning and myGen==_gen and row and row.Parent do
			angle=(angle+8)%360
			ballHolder.Rotation=angle
			task.wait(0.033)
		end
	end)

	self:_gap(s,pi,6)
	local obj={Frame=row,_spinning=true}
	function obj:Stop()
		spinning=false; obj._spinning=false
		_gen=_gen+1
		tw(ball,.3,{BackgroundColor3=C.Border3})
	end
	function obj:Start()
		if obj._spinning then return end
		obj._spinning=true; spinning=true
		_gen=_gen+1; local g=_gen
		tw(ball,.3,{BackgroundColor3=C.White})
		task.spawn(function()
			while spinning and g==_gen and row and row.Parent do
				angle=(angle+8)%360
				ballHolder.Rotation=angle
				task.wait(0.033)
			end
		end)
	end
	return obj
end

function Lib:AddLabel(pi,text,style)
	local s=self:GetPage(pi); if not s then return end
	local styles={
		title    = {size=19,color=C.White,  font=Enum.Font.GothamBold},
		subtitle = {size=14,color=C.Text,   font=Enum.Font.GothamBold},
		body     = {size=13,color=C.Text,   font=Enum.Font.Gotham},
		muted    = {size=12,color=C.TextDim,font=Enum.Font.Gotham},
		caption  = {size=10,color=C.TextOff,font=Enum.Font.Gotham},
	}
	local st=styles[style or "body"]
	local lbl=new("TextLabel",{Text=text or "",Font=st.font,TextSize=st.size,TextColor3=st.color,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,st.size+12),
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=self:_o(pi)},s)
	self:_gap(s,pi,4)
	local obj={Label=lbl}
	function obj:Set(v) if lbl and lbl.Parent then lbl.Text=tostring(v) end end
	function obj:SetColor(col) if lbl and lbl.Parent then lbl.TextColor3=col end end
	obj.Frame = lbl
	return obj
end

function Lib:AddSeparator(pi,spacing)
	local s=self:GetPage(pi); if not s then return end
	local sp=spacing or 6
	self:_gap(s,pi,sp)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	self:_gap(s,pi,sp)
end

function Lib:AddDivider(pi,text,spacing)
	local s=self:GetPage(pi); if not s then return end
	local sp=spacing or 8
	self:_gap(s,pi,sp)
	if text and text~="" then
		local row=new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
		new("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),
			Size=UDim2.new(.36,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},row)
		new("TextLabel",{Text=string.upper(text),Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
			BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
			Size=UDim2.new(.24,0,1,0),TextXAlignment=Enum.TextXAlignment.Center},row)
		new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
			Size=UDim2.new(.36,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},row)
	else
		new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	end
	self:_gap(s,pi,sp)
end

function Lib:AddParagraph(pi,title,content)
	local s=self:GetPage(pi); if not s then return end
	local wrap=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	pad(wrap,14,14,16,16)
	vlist(wrap,8)
	local titleLbl=new("TextLabel",{Text=title or "",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=0},wrap)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=1},wrap)
	local contentLbl=new("TextLabel",{Text=content or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},wrap)
	self:_gap(s,pi,6)
	local obj={Frame=wrap,TitleLabel=titleLbl,ContentLabel=contentLbl}
	function obj:Set(t,c)
		if t then self.TitleLabel.Text=t end
		if c then self.ContentLabel.Text=c end
	end
	return obj
end

function Lib:AddRichLabel(pi,content)
	local s=self:GetPage(pi); if not s then return end
	local lbl=new("TextLabel",{
		Text=content or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,RichText=true,LayoutOrder=self:_o(pi),
	},s)
	self:_gap(s,pi,6)
	local obj={Label=lbl}
	function obj:Set(text) self.Label.Text=text end
	function obj:Show() self.Label.Visible=true end
	function obj:Hide() self.Label.Visible=false end
	return obj
end

function Lib:AddInlineImage(pi,assetId,size,color)
	local s=self:GetPage(pi); if not s then return end
	local sz=size or 20
	local img=new("ImageLabel",{
		Image="rbxassetid://"..tostring(assetId),
		ImageColor3=color or C.White,
		BackgroundTransparency=1,
		Size=UDim2.fromOffset(sz,sz),
		ScaleType=Enum.ScaleType.Fit,
		LayoutOrder=self:_o(pi),
	},s)
	self:_gap(s,pi,4)
	local obj={Image=img}
	function obj:SetColor(col) self.Image.ImageColor3=col end
	function obj:SetImage(id) self.Image.Image="rbxassetid://"..tostring(id) end
	return obj
end

function Lib:AddColorSwatch(pi,label,hexcolor)
	local s=self:GetPage(pi); if not s then return end
	local col=fromHex(hexcolor or "ffffff")
	local wrap=new("Frame",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
	hlist(wrap,8)
	local swatch=new("Frame",{Size=UDim2.fromOffset(18,18),BackgroundColor3=col,BorderSizePixel=0,LayoutOrder=0},wrap)
	corner(swatch,4)
	stroke(swatch,C.Border2,1)
	local code="#"..string.upper(hexcolor or "ffffff")
	new("TextLabel",{
		Text=(label and (label.." ") or "")..code,
		Font=Enum.Font.Code,TextSize=12,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-30,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1,
	},wrap)
	self:_gap(s,pi,4)
	return {Frame=wrap,Swatch=swatch}
end

function Lib:AddAlert(pi,title,message,style)
	local s=self:GetPage(pi); if not s then return end
	local styleMap={
		info    ={accent=C.Blue,   bg=C.BlueBg,   tc=C.Blue},
		success ={accent=C.Green,  bg=C.GreenBg,  tc=C.Green},
		warning ={accent=C.Yellow, bg=C.YellowBg, tc=C.Yellow},
		error   ={accent=C.Red,    bg=C.RedBg,    tc=C.Red},
		purple  ={accent=C.Purple, bg=C.PurpleBg, tc=C.Purple},
	}
	local st=styleMap[style or "info"] or styleMap.info
	local wrap=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=st.bg,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	pad(wrap,12,12,16,16)
	new("Frame",{Size=UDim2.fromOffset(3,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=st.accent,
		BorderSizePixel=0,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0)},wrap)
	local inner=new("Frame",{Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-12,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},wrap)
	vlist(inner,4)
	if title and title~="" then
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=st.tc,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
			TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=0},inner)
	end
	local msgLbl=new("TextLabel",{Text=message or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},inner)
	self:_gap(s,pi,6)
	local obj={Frame=wrap,MessageLabel=msgLbl}
	function obj:Set(msg) self.MessageLabel.Text=msg or "" end
	function obj:Show() self.Frame.Visible=true end
	function obj:Hide() self.Frame.Visible=false end
	return obj
end

function Lib:AddBadge(pi,text,style)
	local s=self:GetPage(pi); if not s then return end
	local styleMap={
		default ={bg=C.Card3,    tc=C.TextDim,dot=nil},
		success ={bg=C.GreenBg,  tc=C.Green,  dot=C.Green},
		error   ={bg=C.RedBg,    tc=C.Red,    dot=C.Red},
		warning ={bg=C.YellowBg, tc=C.Yellow, dot=C.Yellow},
		info    ={bg=C.BlueBg,   tc=C.Blue,   dot=C.Blue},
		white   ={bg=C.Card2,    tc=C.White,  dot=nil},
		purple  ={bg=C.PurpleBg, tc=C.Purple, dot=C.Purple},
	}
	local st=styleMap[style or "default"] or styleMap.default
	local wrap=new("Frame",{Size=UDim2.new(0,0,0,26),AutomaticSize=Enum.AutomaticSize.X,
		BackgroundColor3=st.bg,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,6)
	pad(wrap,0,0,st.dot and 8 or 10,10)
	hlist(wrap,6)
	if st.dot then
		local d=new("Frame",{Size=UDim2.fromOffset(6,6),BackgroundColor3=st.dot,BorderSizePixel=0,LayoutOrder=0},wrap)
		corner(d,3)
	end
	local lbl=new("TextLabel",{Text=text or "",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=st.tc,
		BackgroundTransparency=1,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,LayoutOrder=1},wrap)
	self:_gap(s,pi,6)
	local obj={Frame=wrap,Label=lbl}
	function obj:Set(t) self.Label.Text=t end
	return obj
end

function Lib:AddProgressBar(pi,label,value,maxVal)
	local s=self:GetPage(pi); if not s then return end
	value=value or 0; maxVal=maxVal or 100
	local pct=math.clamp(value/maxVal,0,1)

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	pad(wrap,12,12,16,16)

	local topRow=new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1},wrap)
	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-40,1,0),TextXAlignment=Enum.TextXAlignment.Left},topRow)
	local pctLbl=new("TextLabel",{Text=math.floor(pct*100).."%",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.White,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
		Size=UDim2.fromOffset(40,16),TextXAlignment=Enum.TextXAlignment.Right},topRow)

	local trackBg=new("Frame",{Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,8),
		BackgroundColor3=C.Card3,BorderSizePixel=0},wrap)
	corner(trackBg,4)
	local fill=new("Frame",{Size=UDim2.fromScale(pct,1),BackgroundColor3=C.White,BorderSizePixel=0},trackBg)
	corner(fill,4)

	self:_gap(s,pi,6)
	local obj={Frame=wrap,Fill=fill,PctLabel=pctLbl,_max=maxVal}
	function obj:SetValue(v)
		local p=math.clamp(v/self._max,0,1)
		tw(self.Fill,.35,{Size=UDim2.fromScale(p,1)},Enum.EasingStyle.Quint)
		self.PctLabel.Text=math.floor(p*100).."%"
	end
	function obj:Show() self.Frame.Visible=true end
	function obj:Hide() self.Frame.Visible=false end
	return obj
end

function Lib:AddTable(pi,headers,rows)
	if not self:_isAlive() then return end
	local s=self:GetPage(pi); if not s then return end
	headers = validateTable(headers, {})
	rows    = validateTable(rows, {})
	local cols=#headers
	local rowH=36

	local wrap=new("Frame",{
		Size=UDim2.new(1,0,0,(#rows+1)*rowH),
		BackgroundColor3=C.Card,BorderSizePixel=0,
		LayoutOrder=self:_o(pi),ClipsDescendants=true,
	},s)
	wrap:SetAttribute("ComponentId", self:_nextCompId("Table"))
	corner(wrap,10)
	stroke(wrap,C.Border,1)

	local function makeRow(data,isHeader,rowIndex)
		local bg=isHeader and C.Card2 or (rowIndex%2==0 and C.Card or C.Sidebar)
		local f=new("Frame",{
			Size=UDim2.new(1,0,0,rowH),
			Position=UDim2.fromOffset(0,rowIndex*rowH),
			BackgroundColor3=bg,BorderSizePixel=0,
		},wrap)
		if isHeader then
			new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},f)
		end
		for c,txt in ipairs(data) do
			new("TextLabel",{
				Text=tostring(txt),
				Font=isHeader and Enum.Font.GothamBold or Enum.Font.Gotham,
				TextSize=11,TextColor3=isHeader and C.White or C.Text,
				BackgroundTransparency=1,
				Position=UDim2.new((c-1)/cols,8,0,0),
				Size=UDim2.new(1/cols,-10,1,0),
				TextXAlignment=Enum.TextXAlignment.Left,
				TextTruncate=Enum.TextTruncate.AtEnd,
			},f)
		end
		if not isHeader then
			local hov=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=3,AutoButtonColor=false},f)
			hov.MouseEnter:Connect(function() tw(f,.1,{BackgroundColor3=C.Card3}) end)
			hov.MouseLeave:Connect(function() tw(f,.12,{BackgroundColor3=bg}) end)
		end
	end

	makeRow(headers,true,0)
	for i,row in ipairs(rows) do
		row = validateTable(row, {})
		makeRow(row,false,i)
	end

	self:_gap(s,pi,10)
	local obj={Frame=wrap}
	function obj:Show() self.Frame.Visible=true end
	function obj:Hide() self.Frame.Visible=false end
	return obj
end

function Lib:AddKeybind(pi,label,default,callback)
	local s=self:GetPage(pi); if not s then return end
	local currentKey=default or "None"
	local listening=false

	local row=new("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)
	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,
		BackgroundTransparency=1,Size=UDim2.new(1,-120,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

	local keyBtn=new("TextButton",{Text=currentKey,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.White,
		BackgroundColor3=C.Card3,BorderSizePixel=0,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(90,32),AutoButtonColor=false},row)
	corner(keyBtn,8)
	stroke(keyBtn,C.Border2,1)
	pcall(function() keyBtn.CursorIcon="rbxasset://SystemCursors/PointingHand" end)

	keyBtn.Activated:Connect(function()
		if listening then return end
		listening=true; keyBtn.Text="..."
		tw(keyBtn,.15,{BackgroundColor3=C.Card2})
	end)
	table.insert(self._conns,UserInputService.InputBegan:Connect(function(input,gp)
		if not listening then return end
		if input.UserInputType~=Enum.UserInputType.Keyboard then return end
		local kc=input.KeyCode
		if kc==Enum.KeyCode.Escape then
			listening=false; keyBtn.Text=currentKey
			tw(keyBtn,.15,{BackgroundColor3=C.Card3})
			return
		end
		local name=tostring(kc):gsub("Enum.KeyCode.","")
		currentKey=name; keyBtn.Text=name; listening=false
		tw(keyBtn,.15,{BackgroundColor3=C.Card3})
		if callback then self:_safeCall(callback, name) end
	end))
	row.MouseEnter:Connect(function() tw(row,.12,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.15,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=row,Button=keyBtn}
	function obj:GetKey() return currentKey end
	function obj:SetKey(k) currentKey=k; keyBtn.Text=k end
	return obj
end

function Lib:CreateStatusBadge(parent,state)
	local sp={
		on   ={text="ONLINE", bg=C.GreenBg, tc=C.Green,  dot=C.Green},
		off  ={text="OFFLINE",bg=C.RedBg,   tc=C.Red,    dot=C.Red},
		idle ={text="IDLE",   bg=C.YellowBg,tc=C.Yellow, dot=C.Yellow},
	}
	local st=sp[state or "idle"]
	local frame=new("Frame",{Size=UDim2.fromOffset(82,26),BackgroundColor3=st.bg,BorderSizePixel=0},parent)
	corner(frame,7)
	pad(frame,0,0,10,10)
	hlist(frame,7)
	local dot=new("Frame",{Size=UDim2.fromOffset(6,6),BackgroundColor3=st.dot,BorderSizePixel=0,LayoutOrder=0},frame)
	corner(dot,3)
	local lbl=new("TextLabel",{Text=st.text,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=st.tc,
		BackgroundTransparency=1,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,LayoutOrder=1},frame)
	local badge={Frame=frame,Label=lbl,Dot=dot,_sp=sp}
	function badge:SetState(ns)
		local p=self._sp[ns]; if not p then return end
		tw(self.Frame,.2,{BackgroundColor3=p.bg})
		tw(self.Dot,.2,{BackgroundColor3=p.dot})
		self.Label.Text=p.text; self.Label.TextColor3=p.tc
	end
	return badge
end

function Lib:ShowInlineNotification(msg,style,duration,title)
	local styleMap={
		info    ={dot=C.Blue,  bg=C.BlueBg},
		success ={dot=C.Green, bg=C.GreenBg},
		warning ={dot=C.Yellow,bg=C.YellowBg},
		error   ={dot=C.Red,   bg=C.RedBg},
		purple  ={dot=C.Purple,bg=C.PurpleBg},
	}
	local st=styleMap[style or "info"] or styleMap.info
	local h=title and 60 or 44

	local notif=new("Frame",{Size=UDim2.new(1,0,0,h),BackgroundColor3=C.Card2,
		BackgroundTransparency=1,BorderSizePixel=0,ZIndex=201,
		Position=UDim2.new(0,0,1,0)},self._notifHolder)
	corner(notif,10)
	stroke(notif,C.Border2,1)
	pad(notif,10,10,14,14)

	new("Frame",{Size=UDim2.fromOffset(3,h>44 and 40 or 24),BackgroundColor3=st.dot,
		BorderSizePixel=0,ZIndex=202,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0)},notif)

	if title then
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,
			BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),
			Size=UDim2.new(1,-12,0,20),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=202},notif)
	end
	new("TextLabel",{Text=msg or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Position=title and UDim2.fromOffset(12,22) or UDim2.fromOffset(12,0),
		Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=202},notif)

	tw(notif,.38,{BackgroundTransparency=0,Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)

	task.delay(duration or 3.5,function()
		if not notif or not notif.Parent then return end
		tw(notif,.22,{BackgroundTransparency=1,Position=UDim2.new(0,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.25,function()
			if notif and notif.Parent then notif:Destroy() end
		end)
	end)
end

function Lib:ShowElement(obj)
	if not obj then return end
	local f=obj.Frame or obj.Label
	if not f then return end
	f.Visible=true
	f.BackgroundTransparency=1
	pcall(function() f.TextTransparency=1 end)
	tw(f,.3,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
	pcall(function() tw(f,.3,{TextTransparency=0},Enum.EasingStyle.Quint) end)
end

function Lib:HideElement(obj)
	if not obj then return end
	local f=obj.Frame or obj.Label
	if not f then return end
	tw(f,.22,{BackgroundTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
	pcall(function() tw(f,.18,{TextTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In) end)
	task.delay(.24,function() if f and f.Parent then f.Visible=false end end)
end

function Lib:_runDemo()
	-- PAGE 1: DASHBOARD ─────────────────────────────────────────
	self:AddSectionHeader(1, "Dashboard", "Live component showcase")

	self:AddMetricRow(1, {
		{Label="Components", Value=22, Unit="available"},
		{Label="Version",    Value="1", Unit="slaoqUILib"},
		{Label="Pages",      Value=5,  Unit="in demo"},
	})

	self:AddDivider(1, "Status")
	local statusBadge = self:AddStatusBadge2(1, "Demo Status", "idle")
	local statuslbl   = self:AddLabel(1, "No action yet.", "muted")
	local hpBar = self:AddProgressBar(1, "Sample Progress A", 68, 100)
	local xpBar = self:AddProgressBar(1, "Sample Progress B", 33, 100)

	self:AddDivider(1, "Notification Center")
	local nc = self:AddNotificationCenter(1, {Height=160, MaxItems=25})
	nc:Push("Library loaded successfully", "success", "System")
	nc:Push("Demo mode. Use Lib.new({...}) for your script.", "info", "System")

	self:AddDivider(1, "Controls")
	self:AddButtonRow(1, {
		{Text="Online",  Style="success", Width=100, Callback=function()
			statusBadge:SetState("online")
			statuslbl:Set("Status set to Online")
			nc:Push("Status set to Online", "success", "Status")
			self:Notify("Now Online", "success", 2)
		end},
		{Text="Idle",    Style="ghost",   Width=100, Callback=function()
			statusBadge:SetState("idle")
			statuslbl:Set("Status set to Idle")
			nc:Push("Status set to Idle", "info", "Status")
			self:Notify("Now Idle", "info", 2)
		end},
		{Text="Offline", Style="danger",  Width=100, Callback=function()
			statusBadge:SetState("offline")
			statuslbl:Set("Status set to Offline")
			nc:Push("Status set to Offline", "error", "Status")
			self:Notify("Now Offline", "error", 2)
		end},
	})
	self:AddButtonRow(1, {
		{Text="Confirm Dialog", Style="outline", Width=140, Callback=function()
			self:Confirm("Confirm Action",
				"This is a test of the confirm modal system.",
				function() self:Notify("Confirmed!", "success", 2); nc:Push("User confirmed","success","Modal") end,
				function() self:Notify("Cancelled", "info", 2) end
			)
		end},
		{Text="Shake Window", Style="ghost", Width=140, Callback=function()
			self:Shake(8)
		end},
	})
	self:AddAlert(1, "Tip", "Press Ctrl+F to search any page. Use the gear icon for settings.", "info")

	-- PAGE 2: INPUTS ─────────────────────────────────────────────
	self:AddSectionHeader(2, "Inputs", "Text, numbers and selections")

	self:AddDivider(2, "Text")
	self:AddInput(2, "Text Input", "Type something and press Enter...", function(text, enter)
		if enter and text ~= "" then
			self:Notify("Input: \"" .. text .. "\"", "info", 3)
		end
	end)
	self:AddInput(2, "Multi-line Input", "Supports multiple lines...", function() end,
		{MultiLine=true})

	self:AddDivider(2, "Numbers")
	self:AddInputNumber(2, "Number Input (0–1000)", {Min=0, Max=1000, Step=5, Placeholder="Enter a number..."}, function(n, enter)
		if enter then self:Notify("Value: "..tostring(n), "info", 2) end
	end)
	self:AddStepper(2, "Stepper (1–20)", 1, 20, 5, 1, function(v)
		self:Notify("Stepper: "..tostring(v), "info", 1.5)
	end)

	self:AddDivider(2, "Selection")
	self:AddDropdown(2, "Single Dropdown", {"Option A","Option B","Option C","Option D","Option E"}, function(v)
		self:Notify("Selected: "..v, "success", 2)
	end)
	self:AddMultiSelect(2, "Multi-Select", {"Alpha","Beta","Gamma","Delta","Epsilon","Zeta"}, function(sel)
		local n=0; for _,v in pairs(sel) do if v then n=n+1 end end
		if n>0 then self:Notify(n.." item(s) selected","info",1.5) end
	end)

	self:AddDivider(2, "Radio & Color")
	self:AddRadioGroup(2, "Radio Group", {"Choice A","Choice B","Choice C"}, "Choice A", function(v)
		self:Notify("Radio: "..v, "success", 2)
	end)
	self:AddColorPicker(2, "Color Picker", Color3.fromRGB(68,136,255), function(col, hex)
		self:Notify("Color: #"..hex, "info", 2)
	end)

	self:AddDivider(2, "Toggles & Checkbox")
	self:AddToggle(2, "Simple Toggle", false, function(v)
		self:Notify(v and "Enabled" or "Disabled", v and "success" or "info", 1.5)
	end)
	self:AddToggle(2, "Toggle with Description", true, function(v)
		self:Notify(v and "Feature ON" or "Feature OFF", v and "success" or "info", 1.5)
	end, "This toggle has a secondary description line below the label")
	self:AddCheckbox(2, "Checkbox", false, function(v)
		self:Notify(v and "Checked" or "Unchecked", "info", 1.5)
	end)

	-- PAGE 3: COMPONENTS ─────────────────────────────────────────
	self:AddSectionHeader(3, "Components", "Visual elements and displays")

	self:AddDivider(3, "Labels")
	self:AddLabel(3, "Title style label", "title")
	self:AddLabel(3, "Subtitle style label", "subtitle")
	self:AddLabel(3, "Body style — default for most text.", "body")
	self:AddLabel(3, "Muted style — secondary or helper text.", "muted")
	self:AddLabel(3, "Caption style label", "caption")

	self:AddDivider(3, "Badges & Tags")
	self:AddBadge(3, "Default",  "default")
	self:AddBadge(3, "Success",  "success")
	self:AddBadge(3, "Error",    "error")
	self:AddBadge(3, "Warning",  "warning")
	self:AddBadge(3, "Info",     "info")
	self:AddBadge(3, "Purple",   "purple")
	self:AddTag(3, "tag: info",    "info")
	self:AddTag(3, "tag: success", "success")
	self:AddTag(3, "tag: warning", "warning")
	self:AddTag(3, "tag: error",   "error")

	self:AddDivider(3, "Alerts")
	self:AddAlert(3, "Information", "Here is some useful info for the user.", "info")
	self:AddAlert(3, "Success", "The operation completed successfully.", "success")
	self:AddAlert(3, "Warning", "Something requires your attention.", "warning")
	self:AddAlert(3, "Error", "Something went wrong. Please try again.", "error")

	self:AddDivider(3, "Progress Bars")
	local pb1 = self:AddProgressBar(3, "Download Progress", 72, 100)
	local pb2 = self:AddProgressBar(3, "Storage Used", 45, 100)
	self:AddButtonRow(3, {
		{Text="Randomize", Style="primary", Width=120, Callback=function()
			pb1:SetValue(math.random(10,100))
			pb2:SetValue(math.random(10,100))
		end},
		{Text="Fill",  Style="success", Width=90, Callback=function() pb1:SetValue(100); pb2:SetValue(100) end},
		{Text="Reset", Style="ghost",   Width=90, Callback=function() pb1:SetValue(0);   pb2:SetValue(0)   end},
	})

	self:AddDivider(3, "Spinner")
	local spinner = self:AddSpinner(3, "Loading...")
	self:AddButtonRow(3, {
		{Text="Start", Style="success", Width=90, Callback=function() spinner:Start() end},
		{Text="Stop",  Style="danger",  Width=90, Callback=function() spinner:Stop()  end},
	})

	self:AddDivider(3, "Paragraph")
	self:AddParagraph(3, "What is SlaoqUILib?",
		"A lightweight, modular UI library for Roblox scripts. Drop it in, call Lib.new({...}), " ..
		"then build pages using AddToggle, AddSlider, AddDropdown, AddLogConsole and more.")

	self:AddDivider(3, "Dynamic List")
	local dlist = self:AddList(3, "Item Log", {MaxItems=15, ItemHeight=32})
	local dcount = 0
	self:AddButtonRow(3, {
		{Text="Add Item", Style="primary", Width=110, Callback=function()
			dcount = dcount + 1
			local cols = {C.Blue, C.Green, C.Yellow, C.Red, C.Purple, C.Orange}
			dlist:Add("Item #"..dcount.." — "..os.date("%H:%M:%S"), cols[(dcount-1)%#cols+1])
		end},
		{Text="Clear", Style="ghost", Width=90, Callback=function()
			dlist:Clear(); dcount=0
		end},
	})

	-- PAGE 4: BUTTONS ─────────────────────────────────────────────
	self:AddSectionHeader(4, "Buttons", "All button styles and states")

	self:AddDivider(4, "All Styles")
	self:AddButtonRow(4, {
		{Text="Primary",  Style="primary", Width=110},
		{Text="Success",  Style="success", Width=110},
		{Text="Danger",   Style="danger",  Width=110},
	})
	self:AddButtonRow(4, {
		{Text="Ghost",   Style="ghost",   Width=110},
		{Text="Outline", Style="outline", Width=110},
		{Text="Warning", Style="warning", Width=110},
	})

	self:AddDivider(4, "Loading State")
	local loadBtn = self:AddButton(4, "Click to Load", "primary", nil)
	if loadBtn then
		loadBtn.Button.Activated:Connect(function()
			if loadBtn._loading then return end
			loadBtn:SetLoading(true)
			task.delay(2.5, function()
				loadBtn:SetLoading(false)
				self:Notify("Load complete!", "success", 2)
			end)
		end)
	end

	self:AddDivider(4, "Keybind")
	self:AddKeybind(4, "Custom Hotkey", "None", function(key)
		self:Notify("Hotkey set to: "..key, "info", 2)
	end)

	self:AddDivider(4, "Sliders")
	self:AddSlider(4, "Value A (0–100)", 0, 100, 50, function(v)
		self:Notify("Slider A: "..tostring(v), "info", 1)
	end)
	self:AddSlider(4, "Value B (−50–50)", -50, 50, 0, function() end)

	self:AddDivider(4, "Toast Notifications")
	self:AddButtonRow(4, {
		{Text="Info",    Style="ghost",   Width=90, Callback=function() self:Notify("Info toast",    "info",    2.5) end},
		{Text="Success", Style="success", Width=90, Callback=function() self:Notify("Success toast", "success", 2.5) end},
		{Text="Warning", Style="warning", Width=90, Callback=function() self:Notify("Warning toast", "warning", 2.5) end},
		{Text="Error",   Style="danger",  Width=90, Callback=function() self:Notify("Error toast",   "error",   2.5) end},
	})

	-- PAGE 5: LOGS ────────────────────────────────────────────────
	self:AddSectionHeader(5, "Logs", "Real-time output console")
	local console = self:AddLogConsole(5, 260)
	console:Log("SlaoqUILib v1 initialized", "SUCCESS")
	console:Log("Demo mode active", "INFO")
	console:Log("All components loaded", "DEBUG")
	console:Log("Ready for use", "INFO")

	self:AddButtonRow(5, {
		{Text="Info",    Style="ghost",   Width=90, Callback=function() console:Log("Info message",   "INFO")    end},
		{Text="Success", Style="success", Width=90, Callback=function() console:Log("Success",        "SUCCESS") end},
		{Text="Warning", Style="warning", Width=90, Callback=function() console:Log("Warning event",  "WARN")    end},
		{Text="Error",   Style="danger",  Width=90, Callback=function() console:Log("Error occurred", "ERROR")   end},
	})
	self:AddButtonRow(5, {
		{Text="Spam 10", Style="outline", Width=110, Callback=function()
			task.spawn(function()
				local levels={"INFO","SUCCESS","WARN","ERROR","DEBUG"}
				for i=1,10 do
					console:Log("Auto log entry #"..i, levels[math.random(1,#levels)])
					task.wait(0.05)
				end
			end)
		end},
		{Text="Clear", Style="danger", Width=90, Callback=function()
			console:Clear()
			console:Log("Console cleared", "INFO")
		end},
	})

	self:AddDivider(5, "API Quick Reference")
	self:AddParagraph(5, "Core Methods",
		"Notify · Confirm · Shake · Show / Hide · SetPageBadge · OnDestroy · Destroy")
	self:AddParagraph(5, "Components",
		"AddToggle · AddCheckbox · AddSlider · AddStepper · AddDropdown · AddRadioGroup · " ..
		"AddColorPicker · AddInput · AddInputNumber · AddMultiSelect · AddList · " ..
		"AddProgressBar · AddLogConsole · AddNotificationCenter · " ..
		"AddBadge · AddTag · AddAlert · AddCard · AddTable · AddKeybind · AddSpinner")
end
function Lib:AddNotificationCenter(pi, opts)
	if not self:_isAlive() then return end
	opts = opts or {}
	local maxItems = opts.MaxItems or 30
	local height = opts.Height or 200
	local s=self:GetPage(pi); if not s then return end

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,height+34),BackgroundColor3=fromHex("050505"),
		BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=self:_o(pi)},s)
	wrap:SetAttribute("ComponentId", self:_nextCompId("NotificationCenter"))
	corner(wrap,10)
	stroke(wrap,C.Border,1)

	local hdr=new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.Card,BorderSizePixel=0},wrap)
	corner(hdr,10)
	new("Frame",{Position=UDim2.new(0,0,1,-8),Size=UDim2.new(1,0,0,8),BackgroundColor3=C.Card,BorderSizePixel=0},hdr)
	pad(hdr,0,0,14,14); hlist(hdr,8)
	local dot=new("Frame",{Size=UDim2.fromOffset(7,7),BackgroundColor3=C.Green,BorderSizePixel=0,LayoutOrder=0},hdr)
	corner(dot,4)
	new("TextLabel",{Text="NOTIFICATIONS",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.TextDim,
		BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},hdr)
	local clearBtn=new("TextButton",{Text="Clear",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,
		BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(36,20),ZIndex=2,AutoButtonColor=false},hdr)
	clearBtn.MouseEnter:Connect(function() tw(clearBtn,.1,{TextColor3=C.TextDim}) end)
	clearBtn.MouseLeave:Connect(function() tw(clearBtn,.12,{TextColor3=C.TextOff}) end)

	local scroll=new("ScrollingFrame",{
		Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,1,-34),
		BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=5,ScrollBarImageColor3=C.Border3,ScrollBarImageTransparency=.2,
		CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=2,
	},wrap)
	pad(scroll,4,4,10,10)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3)},scroll)

	local items={}
	local count=0
	local styleColors={
		info   ={C.Blue,  fromHex("030914")},
		success={C.Green, fromHex("030e08")},
		warning={C.Yellow,fromHex("0e0b02")},
		error  ={C.Red,   fromHex("0e0404")},
		default={C.TextDim,C.Card},
	}

	self:_gap(s,pi,8)
	local obj={Frame=wrap}
	function obj:Push(text, style, label)
		if #items>=maxItems then
			if items[1] and items[1].Parent then items[1]:Destroy() end
			table.remove(items,1)
		end
		count=count+1
		local sc=styleColors[style] or styleColors.default
		local row=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
			BackgroundColor3=sc[2],BorderSizePixel=0,LayoutOrder=count},scroll)
		corner(row,8)
		pad(row,6,6,10,10)
		vlist(row,2)
		if label then
			new("TextLabel",{Text=string.upper(label),Font=Enum.Font.GothamBold,TextSize=9,TextColor3=sc[1],
				BackgroundTransparency=1,Size=UDim2.new(1,0,0,13),
				TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},row)
		end
		new("TextLabel",{Text=tostring(text),Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.Text,
			BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
			TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},row)
		table.insert(items,row)
		task.defer(function()
			if scroll and scroll.Parent then scroll.CanvasPosition=Vector2.new(0,math.huge) end
		end)
	end
	function obj:Clear()
		for _,r in ipairs(items) do if r and r.Parent then r:Destroy() end end
		items={}
	end
	function obj:SetActive(v)
		tw(dot,.2,{BackgroundColor3=v and C.Green or C.Red})
	end
	clearBtn.Activated:Connect(function() obj:Clear() end)
	return obj
end

function Lib:SaveState()
	pcall(function()
		local win = self.Window
		self._savedState = {
			pageIdx = self._pageIdx,
			offsetX = win and win.Position.X.Offset or 0,
			offsetY = win and win.Position.Y.Offset or 0,
		}
	end)
end

function Lib:_loadState()
	return self._savedState
end


local function processHexColors(text)
	return (text:gsub("(#%x%x%x%x%x%x)", function(h)
		local r=tonumber(h:sub(2,3),16)
		local g=tonumber(h:sub(4,5),16)
		local b=tonumber(h:sub(6,7),16)
		if not r then return h end
		return h..'<font color="rgb('..r..','..g..','..b..')">[  ]</font>'
	end))
end
Lib.ProcessHexColors = processHexColors

local _newCalled = false
local _origNew   = Lib.new
Lib.new = function(cfg)
	_newCalled = true
	return _origNew(cfg)
end

task.defer(function()
	if not _newCalled then
		pcall(_origNew, nil)
	end
end)

return Lib
