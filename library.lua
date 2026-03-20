local Lib = {}
Lib.__index = Lib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

local function fromHex(h)
	h = h:gsub("#","")
	return Color3.new(
		tonumber(h:sub(1,2),16)/255,
		tonumber(h:sub(3,4),16)/255,
		tonumber(h:sub(5,6),16)/255
	)
end

local function lerp(a,b,t) return a+(b-a)*t end

local function tw(obj, t, props, es, ed, delay_)
	if not obj or not obj.Parent then return end
	local info = TweenInfo.new(t or .2, es or Enum.EasingStyle.Quint, ed or Enum.EasingDirection.Out)
	local ok, tween = pcall(TweenService.Create, TweenService, obj, info, props)
	if ok and tween then
		if delay_ then task.delay(delay_, function() tween:Play() end) return tween end
		tween:Play()
		return tween
	end
end

local function new(class, props, parent)
	local ok, obj = pcall(Instance.new, class)
	if not ok then return end
	if props then
		for k,v in pairs(props) do
			if k ~= "Parent" then pcall(function() obj[k] = v end) end
		end
	end
	if parent then obj.Parent = parent end
	return obj
end

local function corner(obj, r)
	return new("UICorner", {CornerRadius=UDim.new(0,r or 8)}, obj)
end

local function stroke(obj, c, th, tr)
	return new("UIStroke", {Color=c or fromHex("1e1e1e"), Thickness=th or 1, Transparency=tr or 0}, obj)
end

local function pad(obj, t, b, l, r)
	return new("UIPadding", {
		PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0),
		PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0)
	}, obj)
end

local function listLayout(obj, dir, halign, spacing)
	return new("UIListLayout", {
		FillDirection = dir or Enum.FillDirection.Vertical,
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, spacing or 0)
	}, obj)
end

local C = {
	Bg        = fromHex("0d0d0d"),
	Bg2       = fromHex("111111"),
	Sidebar   = fromHex("0a0a0a"),
	Card      = fromHex("161616"),
	Card2     = fromHex("1a1a1a"),
	Card3     = fromHex("202020"),
	Border    = fromHex("222222"),
	Border2   = fromHex("2a2a2a"),
	Border3   = fromHex("363636"),
	Text      = fromHex("e8e8e8"),
	TextDim   = fromHex("888888"),
	TextOff   = fromHex("404040"),
	White     = fromHex("ffffff"),
	Green     = fromHex("00e87a"),
	GreenDim  = fromHex("0a2a1a"),
	Red       = fromHex("e84040"),
	RedDim    = fromHex("2a0a0a"),
	Yellow    = fromHex("f0c030"),
	YellowDim = fromHex("1e1800"),
	Orange    = fromHex("f07020"),
	Blue      = fromHex("4488ff"),
	BlueDim   = fromHex("0a1432"),
	Purple    = fromHex("9966ff"),
}

local DefaultConfig = {
	AppName          = "MY APP",
	AppSubtitle      = "Subtitle",
	AppVersion       = "1.0",
	LogoImage        = "",
	GuiParent        = "CoreGui",
	WindowWidth      = 880,
	WindowHeight     = 560,
	SidebarWidth     = 200,
	TweenSpeed       = 0.25,
	BarTweenSpeed    = 0.3,
	MobileBreakpoint = 650,
	Pages            = {
		{Icon="", Name="Dashboard"},
		{Icon="", Name="Settings"},
		{Icon="", Name="Logs"},
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
	if userCfg then
		for k,v in pairs(userCfg) do self.cfg[k]=v end
	end

	self._pages    = {}
	self._navBtns  = {}
	self._conns    = {}
	self._ord      = {}
	self._pageIdx  = 1

	local guiParent = self.cfg.GuiParent == "PlayerGui"
		and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

	self._sg = new("ScreenGui", {
		Name="SlaoqUI_"..self.cfg.AppName,
		ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
		DisplayOrder=999,
	}, guiParent)
	pcall(function() self._sg.IgnoreGuiInset = true end)

	self:_buildSplash()
	return self
end

function Lib:_buildSplash()
	local cfg = self.cfg

	local overlay = new("Frame", {
		Size=UDim2.fromScale(1,1),
		BackgroundColor3=C.Bg,
		BackgroundTransparency=0,
		BorderSizePixel=0,
		ZIndex=500,
	}, self._sg)

	local card = new("Frame", {
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.5,.52),
		Size=UDim2.fromOffset(380,220),
		BackgroundColor3=C.Card,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=501,
	}, overlay)
	corner(card,14)
	local cardStroke = stroke(card,C.Border2,1,1)

	local logoHolder = new("Frame", {
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,28),
		Size=UDim2.fromOffset(50,50),
		BackgroundColor3=C.Card3,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=502,
	}, card)
	corner(logoHolder,13)
	local logoStroke = stroke(logoHolder,C.Border3,1,1)

	if cfg.LogoImage ~= "" then
		new("ImageLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Image=cfg.LogoImage,
			ZIndex=503,
		}, logoHolder)
	else
		new("TextLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,
			TextSize=22,
			TextColor3=C.White,
			TextTransparency=1,
			ZIndex=503,
		}, logoHolder)
	end

	local nameLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,90),
		Size=UDim2.new(1,-32,0,22),
		BackgroundTransparency=1,
		Text=cfg.AppName,
		Font=Enum.Font.GothamBold,
		TextSize=16,
		TextColor3=C.White,
		TextTransparency=1,
		ZIndex=502,
	}, card)

	local subLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,114),
		Size=UDim2.new(1,-32,0,16),
		BackgroundTransparency=1,
		Text=cfg.AppSubtitle,
		Font=Enum.Font.Gotham,
		TextSize=11,
		TextColor3=C.TextDim,
		TextTransparency=1,
		ZIndex=502,
	}, card)

	local taskLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,148),
		Size=UDim2.new(1,-32,0,14),
		BackgroundTransparency=1,
		Text=cfg.SplashTasks[1] or "Loading...",
		Font=Enum.Font.Gotham,
		TextSize=10,
		TextColor3=C.TextOff,
		TextTransparency=1,
		ZIndex=502,
	}, card)

	local barBg = new("Frame",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,172),
		Size=UDim2.new(1,-40,0,3),
		BackgroundColor3=C.Card3,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=502,
	}, card)
	corner(barBg,2)

	local barFill = new("Frame",{
		Size=UDim2.new(0,0,1,0),
		BackgroundColor3=C.White,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=503,
	}, barBg)
	corner(barFill,2)

	local function runSplash(onDone)
		task.wait(.1)

		tw(card,.5,{BackgroundTransparency=0,Position=UDim2.fromScale(.5,.5)},Enum.EasingStyle.Quint)
		tw(cardStroke,.5,{Transparency=0})
		task.wait(.08)
		tw(logoHolder,.45,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
		tw(logoStroke,.45,{Transparency=0})
		for _,c in ipairs(logoHolder:GetChildren()) do
			if c:IsA("TextLabel") or c:IsA("ImageLabel") then
				tw(c,.4,{TextTransparency=0,ImageTransparency=0},Enum.EasingStyle.Quint,nil,.05)
			end
		end
		task.wait(.2)
		tw(nameLbl,.45,{TextTransparency=0})
		task.wait(.08)
		tw(subLbl,.4,{TextTransparency=0})
		task.wait(.15)
		tw(taskLbl,.4,{TextTransparency=0})
		tw(barBg,.4,{BackgroundTransparency=0})
		tw(barFill,.4,{BackgroundTransparency=0})
		task.wait(.2)

		local tasks = cfg.SplashTasks
		local n = #tasks
		for i, taskText in ipairs(tasks) do
			tw(taskLbl,.18,{TextTransparency=1})
			task.wait(.15)
			taskLbl.Text = taskText
			tw(taskLbl,.18,{TextTransparency=0})
			local targetScale = i/n
			tw(barFill,.5,{Size=UDim2.fromScale(targetScale,1)},Enum.EasingStyle.Quint)
			task.wait(.55)
		end

		task.wait(.2)
		tw(taskLbl,.3,{TextTransparency=1})
		tw(barBg,.3,{BackgroundTransparency=1})
		task.wait(.1)
		tw(subLbl,.3,{TextTransparency=1})
		tw(nameLbl,.3,{TextTransparency=1})
		task.wait(.1)
		tw(logoHolder,.3,{BackgroundTransparency=1})
		tw(logoStroke,.35,{Transparency=1})
		for _,c in ipairs(logoHolder:GetChildren()) do
			if c:IsA("TextLabel") or c:IsA("ImageLabel") then
				tw(c,.25,{TextTransparency=1,ImageTransparency=1})
			end
		end
		task.wait(.15)
		tw(card,.4,{BackgroundTransparency=1,Size=UDim2.fromOffset(380,200)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		tw(cardStroke,.35,{Transparency=1})
		task.wait(.25)
		tw(overlay,.5,{BackgroundTransparency=1},Enum.EasingStyle.Quint)
		task.wait(.52)
		overlay:Destroy()
		onDone()
	end

	task.spawn(runSplash, function() self:_buildWindow() end)
end

function Lib:_buildWindow()
	local cfg = self.cfg

	local win = new("Frame",{
		Name="Window",
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.5,.5),
		Size=UDim2.fromOffset(cfg.WindowWidth,cfg.WindowHeight),
		BackgroundColor3=C.Bg,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ClipsDescendants=false,
	}, self._sg)
	corner(win,12)
	stroke(win,C.Border,1)
	self.Window = win

	local shadow = new("ImageLabel",{
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.5,.5),
		Size=UDim2.new(1,60,1,60),
		BackgroundTransparency=1,
		Image="rbxassetid://6014261993",
		ImageColor3=Color3.fromRGB(0,0,0),
		ImageTransparency=.6,
		ZIndex=-1,
		ScaleType=Enum.ScaleType.Slice,
		SliceCenter=Rect.new(49,49,450,450),
	}, win)

	tw(win,.5,{BackgroundTransparency=0,Size=UDim2.fromOffset(cfg.WindowWidth,cfg.WindowHeight)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
	tw(shadow,.6,{ImageTransparency=.5})

	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local mob = vp.X < cfg.MobileBreakpoint or UserInputService.TouchEnabled
		local s = math.min(math.clamp(vp.X/1920,.38,1),math.clamp(vp.Y/1080,.38,1))
		local w = mob and math.floor(vp.X*.97) or math.floor(cfg.WindowWidth*s)
		local h = mob and math.floor(vp.Y*.93) or math.floor(cfg.WindowHeight*s)
		win.Size = UDim2.fromOffset(w,h)
		if self._sidebar then
			local sw = (mob or s<.55) and 48 or math.floor(cfg.SidebarWidth*s)
			self._sidebar.Size = UDim2.new(0,sw,1,0)
			self:_setCollapsed(sw < 90)
		end
	end

	table.insert(self._conns,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

	self:_buildTitleBar(win)
	self:_buildBody(win)
	self:_initPages()
	self:SetPage(1)
	task.defer(updateScale)
end

function Lib:_buildTitleBar(win)
	local cfg = self.cfg

	local tb = new("Frame",{
		Name="TitleBar",
		Size=UDim2.new(1,0,0,40),
		BackgroundColor3=C.Bg2,
		BorderSizePixel=0,
		ZIndex=10,
	}, win)
	corner(tb,12)
	new("Frame",{
		Position=UDim2.new(0,0,1,-1),
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
		ZIndex=10,
	}, tb)
	new("Frame",{
		Position=UDim2.new(0,0,1,-12),
		Size=UDim2.new(1,0,0,12),
		BackgroundColor3=C.Bg2,
		BorderSizePixel=0,
		ZIndex=10,
	}, tb)
	self.TitleBar = tb

	local leftArea = new("Frame",{
		Size=UDim2.new(1,-90,1,0),
		BackgroundTransparency=1,
		ZIndex=11,
	}, tb)
	pad(leftArea,0,0,14,0)
	listLayout(leftArea,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Left,10)

	local logoMini = new("Frame",{
		Size=UDim2.fromOffset(24,24),
		BackgroundColor3=C.Card3,
		BorderSizePixel=0,
		LayoutOrder=0,
	}, leftArea)
	corner(logoMini,6)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage},logoMini)
	else
		new("TextLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,
			TextSize=11,
			TextColor3=C.White,
		},logoMini)
	end

	new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1,LayoutOrder=1},leftArea)

	new("TextLabel",{
		Text=cfg.AppName,
		Font=Enum.Font.GothamBold,
		TextSize=12,
		TextColor3=C.White,
		BackgroundTransparency=1,
		Size=UDim2.new(0,0,1,0),
		AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Left,
		ZIndex=11,
		LayoutOrder=2,
	}, leftArea)

	local verBadge = new("Frame",{
		Size=UDim2.new(0,0,0,20),
		AutomaticSize=Enum.AutomaticSize.X,
		BackgroundColor3=C.Card3,
		BorderSizePixel=0,
		ZIndex=11,
		LayoutOrder=3,
	}, leftArea)
	corner(verBadge,5)
	pad(verBadge,0,0,7,7)
	new("TextLabel",{
		Text="v"..cfg.AppVersion,
		Font=Enum.Font.Gotham,
		TextSize=9,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Size=UDim2.new(0,0,1,0),
		AutomaticSize=Enum.AutomaticSize.X,
		ZIndex=12,
	}, verBadge)

	local btnArea = new("Frame",{
		AnchorPoint=Vector2.new(1,0),
		Position=UDim2.new(1,0,0,0),
		Size=UDim2.fromOffset(80,40),
		BackgroundTransparency=1,
		ZIndex=11,
	}, tb)
	listLayout(btnArea,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Right,0)

	local function mkBtn(sym, hc, cb, lo)
		local f = new("Frame",{
			Size=UDim2.fromOffset(38,40),
			BackgroundTransparency=1,
			ZIndex=11,
			LayoutOrder=lo,
		}, btnArea)
		local b = new("TextButton",{
			Text=sym,
			Font=Enum.Font.GothamBold,
			TextSize=13,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.fromScale(1,1),
			ZIndex=12,
			AutoButtonColor=false,
		}, f)
		b.MouseEnter:Connect(function()
			tw(b,.12,{TextColor3=hc,BackgroundTransparency=.94})
		end)
		b.MouseLeave:Connect(function()
			tw(b,.15,{TextColor3=C.TextDim,BackgroundTransparency=1})
		end)
		b.MouseButton1Down:Connect(function()
			tw(b,.06,{BackgroundTransparency=.88})
		end)
		b.MouseButton1Up:Connect(function()
			tw(b,.1,{BackgroundTransparency=.94})
		end)
		b.Activated:Connect(cb)
		return b
	end

	mkBtn("-", C.White,  function() self:ToggleVisibility() end, 1)
	local cb = mkBtn("x", C.Red, function() self:Destroy() end, 2)
	corner(cb.Parent,0)

	do
		local drag,ds,ws = false
		tb.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				drag=true; ds=i.Position; ws=self.Window.Position
			end
		end)
		tb.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
		end)
		table.insert(self._conns, UserInputService.InputChanged:Connect(function(i)
			if not drag then return end
			if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
			local d = i.Position-ds
			tw(self.Window,.06,{Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)},Enum.EasingStyle.Linear)
		end))
	end
end

function Lib:_buildBody(win)
	local cfg = self.cfg

	local body = new("Frame",{
		Position=UDim2.fromOffset(0,40),
		Size=UDim2.new(1,0,1,-40),
		BackgroundTransparency=1,
	}, win)
	self._body = body

	local sidebar = new("Frame",{
		Size=UDim2.new(0,cfg.SidebarWidth,1,0),
		BackgroundColor3=C.Sidebar,
		BorderSizePixel=0,
		ClipsDescendants=true,
		ZIndex=5,
	}, body)
	new("Frame",{
		Size=UDim2.new(0,1,1,0),
		Position=UDim2.new(1,-1,0,0),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
		ZIndex=6,
	}, sidebar)
	self._sidebar = sidebar

	local ss = new("ScrollingFrame",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		ScrollBarThickness=0,
		CanvasSize=UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.Y,
	}, sidebar)
	listLayout(ss,nil,Enum.HorizontalAlignment.Center,0)
	pad(ss,18,18,10,10)
	self._sideScroll = ss

	local logoArea = new("Frame",{
		Size=UDim2.new(1,0,0,90),
		BackgroundTransparency=1,
		LayoutOrder=0,
	}, ss)

	local logoWrap = new("Frame",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,0),
		Size=UDim2.fromOffset(48,48),
		BackgroundColor3=C.Card3,
		BorderSizePixel=0,
	}, logoArea)
	corner(logoWrap,13)
	stroke(logoWrap,C.Border2,1)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage},logoWrap)
	else
		new("TextLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,
			TextSize=21,
			TextColor3=C.White,
		}, logoWrap)
	end

	self._sideNameLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,54),
		Size=UDim2.new(1,0,0,16),
		BackgroundTransparency=1,
		Text=cfg.AppName,
		Font=Enum.Font.GothamBold,
		TextSize=11,
		TextColor3=C.White,
		TextTruncate=Enum.TextTruncate.AtEnd,
	}, logoArea)
	self._sideSubLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,72),
		Size=UDim2.new(1,0,0,13),
		BackgroundTransparency=1,
		Text=cfg.AppSubtitle,
		Font=Enum.Font.Gotham,
		TextSize=9,
		TextColor3=C.TextDim,
		TextTruncate=Enum.TextTruncate.AtEnd,
	}, logoArea)

	local divArea = new("Frame",{
		Size=UDim2.new(1,0,0,18),
		BackgroundTransparency=1,
		LayoutOrder=1,
	}, ss)
	new("Frame",{
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.5,.5),
		Size=UDim2.new(.8,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
	}, divArea)

	local barIndicator = new("Frame",{
		Size=UDim2.fromOffset(3,0),
		AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.fromOffset(0,60),
		BackgroundColor3=C.White,
		BorderSizePixel=0,
		ZIndex=9,
		Visible=false,
	}, sidebar)
	corner(barIndicator,2)
	self._bar = barIndicator

	for i,page in ipairs(cfg.Pages) do
		self:_makeNavBtn(page,i,ss)
	end

	new("Frame",{Size=UDim2.fromOffset(1,14),BackgroundTransparency=1,LayoutOrder=#cfg.Pages+10},ss)

	local content = new("Frame",{
		Position=UDim2.new(0,cfg.SidebarWidth,0,0),
		Size=UDim2.new(1,-cfg.SidebarWidth,1,0),
		BackgroundColor3=C.Bg2,
		BorderSizePixel=0,
		ClipsDescendants=true,
	}, body)
	self._content = content

	table.insert(self._conns, sidebar:GetPropertyChangedSignal("Size"):Connect(function()
		local sw = sidebar.Size.X.Offset
		content.Position = UDim2.new(0,sw,0,0)
		content.Size     = UDim2.new(1,-sw,1,0)
	end))

	self:_buildNotifSystem()
end

function Lib:_buildNotifSystem()
	local notifHolder = new("Frame",{
		AnchorPoint=Vector2.new(.5,1),
		Position=UDim2.new(.5,0,1,0),
		Size=UDim2.fromOffset(320,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
		ZIndex=200,
	}, self.Window)
	listLayout(notifHolder,nil,Enum.HorizontalAlignment.Center,8)
	pad(notifHolder,0,14,0,0)
	self._notifHolder = notifHolder
end

function Lib:_makeNavBtn(page,index,parent)
	local cfg = self.cfg

	local frame = new("Frame",{
		Size=UDim2.new(1,0,0,38),
		BackgroundTransparency=1,
		LayoutOrder=index+1,
	}, parent)

	local bg = new("Frame",{
		Size=UDim2.new(1,-8,1,-4),
		Position=UDim2.fromOffset(4,2),
		BackgroundColor3=C.Card2,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=5,
	}, frame)
	corner(bg,8)

	local dot = new("Frame",{
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.new(0,20,.5,0),
		Size=UDim2.fromOffset(6,6),
		BackgroundColor3=C.TextOff,
		BorderSizePixel=0,
		ZIndex=6,
	}, frame)
	corner(dot,3)

	local lbl = new("TextLabel",{
		Text=page.Name,
		Font=Enum.Font.GothamBold,
		TextSize=11,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Position=UDim2.fromOffset(34,0),
		Size=UDim2.new(1,-42,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
		ZIndex=6,
	}, frame)

	local click = new("TextButton",{
		Text="",
		BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),
		ZIndex=7,
		AutoButtonColor=false,
	}, frame)

	click.MouseEnter:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.18,{BackgroundTransparency=.92})
			tw(lbl,.18,{TextColor3=C.Text})
			tw(dot,.18,{BackgroundColor3=C.TextDim,Size=UDim2.fromOffset(7,7)})
		end
	end)
	click.MouseLeave:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.2,{BackgroundTransparency=1})
			tw(lbl,.2,{TextColor3=C.TextDim})
			tw(dot,.2,{BackgroundColor3=C.TextOff,Size=UDim2.fromOffset(6,6)})
		end
	end)
	click.MouseButton1Down:Connect(function()
		tw(bg,.08,{BackgroundTransparency=.88})
	end)
	click.Activated:Connect(function() self:SetPage(index) end)

	self._navBtns[index] = {Frame=frame, Bg=bg, Lbl=lbl, Dot=dot}
end

function Lib:_initPages()
	local C_ref = C
	for i=1,#self.cfg.Pages do
		local pageFrame = new("Frame",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Visible=false,
		}, self._content)

		local scroll = new("ScrollingFrame",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			ScrollBarThickness=3,
			ScrollBarImageColor3=C_ref.Border3,
			ScrollBarImageTransparency=.4,
			CanvasSize=UDim2.new(0,0,0,0),
			AutomaticCanvasSize=Enum.AutomaticSize.Y,
			ElasticBehavior=Enum.ElasticBehavior.Never,
		}, pageFrame)
		new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},scroll)
		pad(scroll,24,24,24,24)

		self._pages[i] = {Frame=pageFrame,Scroll=scroll}
		self._ord[i]   = 0
	end
end

function Lib:SetPage(index)
	local cfg = self.cfg
	if self._pages[self._pageIdx] then
		local old = self._pages[self._pageIdx].Frame
		tw(old,.18,{BackgroundTransparency=1})
		task.delay(.19,function() if old then old.Visible=false end end)
	end
	local oldBtn = self._navBtns[self._pageIdx]
	if oldBtn then
		tw(oldBtn.Lbl,cfg.TweenSpeed,{TextColor3=C.TextDim})
		tw(oldBtn.Bg,cfg.TweenSpeed,{BackgroundTransparency=1})
		tw(oldBtn.Dot,cfg.TweenSpeed,{BackgroundColor3=C.TextOff,Size=UDim2.fromOffset(6,6)})
	end

	self._pageIdx = index

	local newPage = self._pages[index]
	if newPage then
		newPage.Frame.Visible=true
		newPage.Frame.BackgroundTransparency=1
		tw(newPage.Frame,.2,{BackgroundTransparency=0})
	end
	local nb = self._navBtns[index]
	if nb then
		tw(nb.Lbl,cfg.TweenSpeed,{TextColor3=C.White})
		tw(nb.Bg,cfg.TweenSpeed,{BackgroundTransparency=.92})
		tw(nb.Dot,cfg.TweenSpeed,{BackgroundColor3=C.White,Size=UDim2.fromOffset(7,7)})
		self:_animBar(nb.Frame)
	end
end

function Lib:_animBar(target)
	local bar = self._bar
	if not bar or not target then return end
	local ok,relY = pcall(function()
		return target.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + target.AbsoluteSize.Y*.5
	end)
	if not ok then return end
	bar.Visible=true
	local cfg = self.cfg

	local t1 = tw(bar,cfg.BarTweenSpeed*.4,{Size=UDim2.fromOffset(3,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
	if t1 then
		t1.Completed:Connect(function()
			bar.Position = UDim2.new(0,0,0,relY)
			tw(bar,cfg.BarTweenSpeed*.7,{Size=UDim2.fromOffset(3,32)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		end)
	end
end

function Lib:_setCollapsed(c)
	if self._sideNameLbl then self._sideNameLbl.Visible=not c end
	if self._sideSubLbl  then self._sideSubLbl.Visible=not c  end
	for _,nb in ipairs(self._navBtns) do
		if nb and nb.Lbl then nb.Lbl.Visible=not c end
	end
end

function Lib:_o(pi)
	self._ord[pi]=(self._ord[pi] or 0)+1
	return self._ord[pi]
end

function Lib:GetPage(i)
	return self._pages[i] and self._pages[i].Scroll or nil
end

function Lib:_gap(s,pi,h)
	new("Frame",{Size=UDim2.new(1,0,0,h or 8),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
end

function Lib:_animIn(obj)
	if not obj then return end
	obj.BackgroundTransparency=1
	tw(obj,.35,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
end

function Lib:AddSectionHeader(pi, title, sub)
	local s = self:GetPage(pi); if not s then return end
	self:_gap(s,pi,8)
	local frame = new("Frame",{
		Size=UDim2.new(1,0,0,sub and 52 or 30),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	}, s)
	local t1 = new("TextLabel",{
		Text=title,
		Font=Enum.Font.GothamBold,
		TextSize=18,
		TextColor3=C.White,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,24),
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTransparency=1,
	}, frame)
	tw(t1,.45,{TextTransparency=0},Enum.EasingStyle.Quint)
	if sub then
		local t2 = new("TextLabel",{
			Text=sub,
			Font=Enum.Font.Gotham,
			TextSize=11,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(0,26),
			Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			TextTransparency=1,
		}, frame)
		tw(t2,.45,{TextTransparency=0},Enum.EasingStyle.Quint,nil,.06)
	end
	local divFrame = new("Frame",{
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	}, s)
	self:_gap(s,pi,16)
end

function Lib:AddMetricRow(pi, cards)
	local s = self:GetPage(pi); if not s then return end
	local cols  = math.min(#cards,3)
	local rows  = math.ceil(#cards/cols)
	local cellH = 76
	local gap   = 8

	local wrap = new("Frame",{
		Size=UDim2.new(1,0,0,rows*(cellH+gap)-gap),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	}, s)

	local objects = {}
	for i,card in ipairs(cards) do
		local row = math.floor((i-1)/cols)
		local col = (i-1)%cols
		local xOff = col==0 and 0 or gap
		local wOff = cols==1 and 0 or (col==0 or col==cols-1) and -gap/2 or -gap

		local f = new("Frame",{
			BackgroundColor3=C.Card,
			BackgroundTransparency=1,
			BorderSizePixel=0,
			ZIndex=2,
			Position=UDim2.new(col/cols,col>0 and gap or 0,0,row*(cellH+gap)),
			Size=UDim2.new(1/cols,wOff,0,cellH),
		}, wrap)
		corner(f,10)
		local fStroke = stroke(f,C.Border,1,1)

		tw(f,.4,{BackgroundTransparency=0},Enum.EasingStyle.Quint,nil,i*.04)
		tw(fStroke,.4,{Transparency=0},Enum.EasingStyle.Quint,nil,i*.04)

		pad(f,12,12,14,14)

		new("TextLabel",{
			Text=string.upper(card.Label or ""),
			Font=Enum.Font.GothamBold,
			TextSize=8,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,11),
			TextXAlignment=Enum.TextXAlignment.Left,
			ZIndex=3,
		}, f)

		local valLbl = new("TextLabel",{
			Text=tostring(card.Value or "---"),
			Font=Enum.Font.GothamBold,
			TextSize=22,
			TextColor3=C.White,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(0,15),
			Size=UDim2.new(1,0,0,28),
			TextXAlignment=Enum.TextXAlignment.Left,
			ZIndex=3,
		}, f)

		if card.Unit and card.Unit~="" then
			new("TextLabel",{
				Text=card.Unit,
				Font=Enum.Font.Gotham,
				TextSize=9,
				TextColor3=fromHex("555555"),
				BackgroundTransparency=1,
				Position=UDim2.fromOffset(0,45),
				Size=UDim2.new(1,0,0,12),
				TextXAlignment=Enum.TextXAlignment.Left,
				ZIndex=3,
			}, f)
		end

		local hov = new("TextButton",{
			Text="",BackgroundTransparency=1,
			Size=UDim2.fromScale(1,1),ZIndex=4,AutoButtonColor=false,
		}, f)
		hov.MouseEnter:Connect(function() tw(f,.15,{BackgroundColor3=C.Card2}) end)
		hov.MouseLeave:Connect(function() tw(f,.18,{BackgroundColor3=C.Card})  end)

		objects[i]={Frame=f,ValueLabel=valLbl}
	end
	self:_gap(s,pi,14)
	return objects
end

function Lib:SetMetricValue(obj,val)
	if obj and obj.ValueLabel then
		local old = obj.ValueLabel.Text
		if old ~= tostring(val) then
			tw(obj.ValueLabel,.1,{TextTransparency=.5})
			task.delay(.12,function()
				if obj.ValueLabel and obj.ValueLabel.Parent then
					obj.ValueLabel.Text=tostring(val)
					tw(obj.ValueLabel,.15,{TextTransparency=0})
				end
			end)
		end
	end
end

function Lib:AddButtonRow(pi, defs)
	local s = self:GetPage(pi); if not s then return end
	local row = new("Frame",{
		Size=UDim2.new(1,0,0,40),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	}, s)
	listLayout(row,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Left,8)

	local styles = {
		primary = {bg=C.White,      tc=C.Bg,    hov=fromHex("dcdcdc"), down=fromHex("bbbbbb")},
		danger  = {bg=C.Red,        tc=C.White, hov=fromHex("ff5555"), down=fromHex("cc3333")},
		warning = {bg=C.Yellow,     tc=C.Bg,    hov=C.Orange,          down=fromHex("c05010")},
		ghost   = {bg=C.Card2,      tc=C.Text,  hov=C.Card3,           down=C.Card},
		outline = {bg=C.Bg,         tc=C.Text,  hov=C.Card2,           down=C.Card},
		success = {bg=C.GreenDim,   tc=C.Green, hov=fromHex("0d3d21"), down=fromHex("061a10")},
	}

	local btns={}
	for i,def in ipairs(defs) do
		local st = styles[def.Style or "primary"]
		local isOutline = def.Style=="outline"
		local btn = new("TextButton",{
			Text=def.Text or "",
			Font=Enum.Font.GothamBold,
			TextSize=11,
			TextColor3=st.tc,
			BackgroundColor3=st.bg,
			BackgroundTransparency=isOutline and 0 or 0,
			BorderSizePixel=0,
			Size=UDim2.fromOffset(def.Width or 120,36),
			AutoButtonColor=false,
			LayoutOrder=i,
		}, row)
		corner(btn,8)
		if isOutline then stroke(btn,C.Border2,1) end

		btn.MouseEnter:Connect(function()
			tw(btn,.15,{BackgroundColor3=st.hov})
		end)
		btn.MouseLeave:Connect(function()
			tw(btn,.18,{BackgroundColor3=st.bg})
		end)
		btn.MouseButton1Down:Connect(function()
			tw(btn,.07,{BackgroundColor3=st.down})
			tw(btn,.07,{Size=UDim2.fromOffset((def.Width or 120)-4,33)})
		end)
		btn.MouseButton1Up:Connect(function()
			tw(btn,.15,{BackgroundColor3=st.hov,Size=UDim2.fromOffset(def.Width or 120,36)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		end)
		if def.Callback then btn.Activated:Connect(def.Callback) end
		btns[i]=btn
	end
	self:_gap(s,pi,12)
	return btns
end

function Lib:AddButton(pi,text,style,cb)
	local r=self:AddButtonRow(pi,{{Text=text,Style=style or "primary",Callback=cb}})
	return r and r[1]
end

function Lib:AddToggle(pi, label, default, callback)
	local s = self:GetPage(pi); if not s then return end

	local row = new("Frame",{
		Size=UDim2.new(1,0,0,44),
		BackgroundColor3=C.Card,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	}, s)
	corner(row,10)
	local rowStroke = stroke(row,C.Border,1,1)
	tw(row,.35,{BackgroundTransparency=0})
	tw(rowStroke,.35,{Transparency=0})
	pad(row,0,0,14,14)

	new("TextLabel",{
		Text=label or "",
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=C.Text,
		BackgroundTransparency=1,
		Size=UDim2.new(1,-62,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
	}, row)

	local state = default==true

	local track = new("Frame",{
		AnchorPoint=Vector2.new(1,.5),
		Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(40,22),
		BackgroundColor3=state and C.White or C.Card3,
		BorderSizePixel=0,
	}, row)
	corner(track,11)
	local trackStroke = stroke(track,C.Border2,1)

	local knob = new("Frame",{
		AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.new(0,state and 20 or 2,.5,0),
		Size=UDim2.fromOffset(18,18),
		BackgroundColor3=state and C.Bg or C.TextDim,
		BorderSizePixel=0,
	}, track)
	corner(knob,9)

	local function setState(v, skipCb)
		state=v
		tw(track,.25,{BackgroundColor3=v and C.White or C.Card3},Enum.EasingStyle.Quart)
		tw(trackStroke,.25,{Color=v and fromHex("aaaaaa") or C.Border2})
		tw(knob,.22,{
			Position=UDim2.new(0,v and 20 or 2,.5,0),
			Size=UDim2.fromOffset(18,18),
			BackgroundColor3=v and C.Bg or C.TextDim,
		},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		if not skipCb and callback then callback(v) end
	end

	local click = new("TextButton",{
		Text="",BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false,
	}, track)
	click.MouseButton1Down:Connect(function()
		tw(knob,.07,{Size=UDim2.fromOffset(20,16)})
	end)
	click.Activated:Connect(function() setState(not state) end)

	row.MouseEnter:Connect(function() tw(row,.18,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.2,{BackgroundColor3=C.Card})   end)

	self:_gap(s,pi,6)

	local t={Track=track,Knob=knob}
	function t:SetState(v) setState(v,true) end
	function t:GetState() return state end
	return t
end

function Lib:AddInput(pi, labelTxt, placeholder, callback)
	local s = self:GetPage(pi); if not s then return end

	if labelTxt then
		local lt = new("TextLabel",{
			Text=labelTxt,
			Font=Enum.Font.GothamBold,
			TextSize=10,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=self:_o(pi),
			TextTransparency=1,
		}, s)
		tw(lt,.3,{TextTransparency=0})
		self:_gap(s,pi,4)
	end

	local wrap = new("Frame",{
		Size=UDim2.new(1,0,0,40),
		BackgroundColor3=C.Card,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	}, s)
	corner(wrap,10)
	local wStroke = stroke(wrap,C.Border,1,1)
	pad(wrap,0,0,14,14)
	tw(wrap,.35,{BackgroundTransparency=0})
	tw(wStroke,.35,{Transparency=0})

	local box = new("TextBox",{
		Text="",
		PlaceholderText=placeholder or "",
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=C.Text,
		PlaceholderColor3=C.TextOff,
		BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),
		ClearTextOnFocus=false,
		TextXAlignment=Enum.TextXAlignment.Left,
	}, wrap)

	box.Focused:Connect(function()
		tw(wrap,.18,{BackgroundColor3=C.Card2})
		tw(wStroke,.18,{Color=C.Border3})
	end)
	box.FocusLost:Connect(function(enter)
		tw(wrap,.2,{BackgroundColor3=C.Card})
		tw(wStroke,.2,{Color=C.Border})
		if callback then callback(box.Text,enter) end
	end)

	self:_gap(s,pi,10)
	return box
end

function Lib:AddCard(pi, title, subtitle)
	local s = self:GetPage(pi); if not s then return end

	local card = new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	}, s)
	corner(card,10)
	local cStroke = stroke(card,C.Border,1,1)
	tw(card,.35,{BackgroundTransparency=0})
	tw(cStroke,.35,{Transparency=0})

	if title then
		local hdr = new("Frame",{
			Size=UDim2.new(1,0,0,subtitle and 50 or 38),
			BackgroundColor3=C.Card2,
			BorderSizePixel=0,
		}, card)
		corner(hdr,10)
		new("Frame",{
			Position=UDim2.new(0,0,1,-1),
			Size=UDim2.new(1,0,0,11),
			BackgroundColor3=C.Card2,
			BorderSizePixel=0,
		}, hdr)
		new("Frame",{
			Position=UDim2.new(0,0,1,0),
			Size=UDim2.new(1,0,0,1),
			BackgroundColor3=C.Border,
			BorderSizePixel=0,
		}, hdr)
		pad(hdr,0,0,16,16)
		new("TextLabel",{
			Text=title,
			Font=Enum.Font.GothamBold,
			TextSize=12,
			TextColor3=C.White,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(0,10),
			Size=UDim2.new(1,0,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,
		}, hdr)
		if subtitle then
			new("TextLabel",{
				Text=subtitle,
				Font=Enum.Font.Gotham,
				TextSize=10,
				TextColor3=C.TextDim,
				BackgroundTransparency=1,
				Position=UDim2.fromOffset(0,30),
				Size=UDim2.new(1,0,0,14),
				TextXAlignment=Enum.TextXAlignment.Left,
			}, hdr)
		end
	end

	local inner = new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
	}, card)
	pad(inner,14,14,16,16)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},inner)

	self:_gap(s,pi,10)
	return inner
end

function Lib:AddLogConsole(pi, height)
	local s = self:GetPage(pi); if not s then return end

	local frame = new("Frame",{
		Size=UDim2.new(1,0,0,height or 200),
		BackgroundColor3=fromHex("080808"),
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ClipsDescendants=true,
		LayoutOrder=self:_o(pi),
	}, s)
	corner(frame,10)
	local fStroke = stroke(frame,C.Border,1,1)
	tw(frame,.35,{BackgroundTransparency=0})
	tw(fStroke,.35,{Transparency=0})

	local hdr = new("Frame",{
		Size=UDim2.new(1,0,0,32),
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
	}, frame)
	corner(hdr,10)
	new("Frame",{
		Position=UDim2.new(0,0,1,0),
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
	}, hdr)
	new("Frame",{
		Position=UDim2.new(0,0,1,-10),
		Size=UDim2.new(1,0,0,10),
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
	}, hdr)
	pad(hdr,0,0,14,14)

	local dot = new("Frame",{
		AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.new(0,0,.5,0),
		Size=UDim2.fromOffset(6,6),
		BackgroundColor3=C.Green,
		BorderSizePixel=0,
		LayoutOrder=0,
	}, hdr)
	corner(dot,3)

	new("TextLabel",{
		Text="  CONSOLE",
		Font=Enum.Font.GothamBold,
		TextSize=9,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
	}, hdr)

	local textBox = new("TextBox",{
		Text="",
		Font=Enum.Font.Code,
		TextSize=10,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Position=UDim2.fromOffset(0,33),
		Size=UDim2.new(1,0,1,-33),
		MultiLine=true,
		TextEditable=false,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextYAlignment=Enum.TextYAlignment.Bottom,
		ClearTextOnFocus=false,
		TextWrapped=true,
		ZIndex=2,
	}, frame)
	pad(textBox,8,8,12,12)

	self:_gap(s,pi,10)

	local levelPfx = {
		INFO="[INFO] ",SUCCESS="[OK]   ",WARN="[WARN] ",
		ERROR="[ERR]  ",SNIPE="[SNIPE]",DEBUG="[DBG]  ",
	}
	local console={Frame=frame,TextBox=textBox,_lines={},_dot=dot}

	function console:Log(msg,level)
		local lv=string.upper(level or "INFO")
		local ts=os.date("%H:%M:%S")
		local pfx=levelPfx[lv] or "[INFO] "
		local line=("%s  %s  %s"):format(ts,pfx,tostring(msg))
		table.insert(self._lines,line)
		if #self._lines>400 then table.remove(self._lines,1) end
		self.TextBox.Text=table.concat(self._lines,"\n")
	end
	function console:Clear()
		self._lines={}; self.TextBox.Text=""
	end
	function console:SetActive(v)
		tw(self._dot,.2,{BackgroundColor3=v and C.Green or C.Red})
	end
	return console
end

function Lib:AddLabel(pi, text, style)
	local s = self:GetPage(pi); if not s then return end
	local styles = {
		title    = {size=17,color=C.White,  font=Enum.Font.GothamBold},
		subtitle = {size=13,color=C.Text,   font=Enum.Font.GothamBold},
		body     = {size=12,color=C.Text,   font=Enum.Font.Gotham},
		muted    = {size=11,color=C.TextDim,font=Enum.Font.Gotham},
		caption  = {size=9, color=C.TextOff,font=Enum.Font.Gotham},
	}
	local st=styles[style or "body"]
	local lbl = new("TextLabel",{
		Text=text or "",
		Font=st.font,
		TextSize=st.size,
		TextColor3=st.color,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,st.size+10),
		TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true,
		LayoutOrder=self:_o(pi),
		TextTransparency=1,
	}, s)
	tw(lbl,.3,{TextTransparency=0})
	self:_gap(s,pi,4)
	return lbl
end

function Lib:AddSeparator(pi, spacing)
	local s = self:GetPage(pi); if not s then return end
	local sp=spacing or 6
	self:_gap(s,pi,sp)
	new("Frame",{
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	}, s)
	self:_gap(s,pi,sp)
end

function Lib:AddDropdown(pi, labelTxt, options, callback)
	local s = self:GetPage(pi); if not s then return end

	if labelTxt then
		local lt = new("TextLabel",{
			Text=labelTxt,
			Font=Enum.Font.GothamBold,
			TextSize=10,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=self:_o(pi),
			TextTransparency=1,
		}, s)
		tw(lt,.3,{TextTransparency=0})
		self:_gap(s,pi,4)
	end

	local selected=options[1] or ""
	local open=false

	local wrapper=new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
		ClipsDescendants=false,
		LayoutOrder=self:_o(pi),
		ZIndex=50,
	}, s)

	local btn=new("TextButton",{
		Text="",
		BackgroundColor3=C.Card,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		Size=UDim2.new(1,0,0,40),
		AutoButtonColor=false,
		ZIndex=51,
	}, wrapper)
	corner(btn,10)
	local btnStroke = stroke(btn,C.Border,1,1)
	pad(btn,0,0,14,14)
	tw(btn,.35,{BackgroundTransparency=0})
	tw(btnStroke,.35,{Transparency=0})

	new("TextLabel",{
		Text=selected,
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=C.Text,
		BackgroundTransparency=1,
		Size=UDim2.new(1,-24,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
		ZIndex=52,
	}, btn)

	local arrow=new("TextLabel",{
		Text="v",
		Font=Enum.Font.GothamBold,
		TextSize=10,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		AnchorPoint=Vector2.new(1,.5),
		Position=UDim2.new(1,-14,.5,0),
		Size=UDim2.fromOffset(14,14),
		ZIndex=52,
	}, btn)

	local listH=#options*36
	local optList=new("Frame",{
		Position=UDim2.fromOffset(0,44),
		Size=UDim2.new(1,0,0,0),
		BackgroundColor3=C.Card2,
		BorderSizePixel=0,
		ClipsDescendants=true,
		ZIndex=60,
		Visible=false,
	}, wrapper)
	corner(optList,10)
	stroke(optList,C.Border2,1)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},optList)

	local selLabel = btn:FindFirstChildWhichIsA("TextLabel")

	for i,opt in ipairs(options) do
		local ob=new("TextButton",{
			Text=opt,
			Font=Enum.Font.Gotham,
			TextSize=12,
			TextColor3=C.Text,
			BackgroundColor3=C.Card2,
			BackgroundTransparency=1,
			BorderSizePixel=0,
			Size=UDim2.new(1,0,0,36),
			AutoButtonColor=false,
			LayoutOrder=i,
			ZIndex=61,
			TextXAlignment=Enum.TextXAlignment.Left,
		}, optList)
		pad(ob,0,0,14,14)
		ob.MouseEnter:Connect(function() tw(ob,.1,{BackgroundTransparency=.85}) end)
		ob.MouseLeave:Connect(function() tw(ob,.12,{BackgroundTransparency=1})  end)
		ob.Activated:Connect(function()
			selected=opt
			if selLabel then selLabel.Text=opt end
			open=false
			tw(optList,.2,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			tw(arrow,.2,{Rotation=0})
			task.delay(.21,function() optList.Visible=false end)
			if callback then callback(opt) end
		end)
	end

	btn.MouseEnter:Connect(function() tw(btn,.15,{BackgroundColor3=C.Card2}) end)
	btn.MouseLeave:Connect(function() tw(btn,.18,{BackgroundColor3=C.Card})  end)
	btn.Activated:Connect(function()
		open=not open
		optList.Visible=true
		if open then
			tw(optList,.25,{Size=UDim2.new(1,0,0,listH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
			tw(arrow,.2,{Rotation=180})
		else
			tw(optList,.2,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			tw(arrow,.2,{Rotation=0})
			task.delay(.21,function() optList.Visible=false end)
		end
	end)

	self:_gap(s,pi,10)
	return {Button=btn,List=optList,GetSelected=function() return selected end}
end

function Lib:CreateStatusBadge(parent,state)
	local sp={
		on   ={text="ONLINE",  bg=C.GreenDim,  tc=C.Green,  dot=C.Green},
		off  ={text="OFFLINE", bg=C.RedDim,    tc=C.Red,    dot=C.Red},
		idle ={text="IDLE",    bg=C.YellowDim, tc=C.Yellow, dot=C.Yellow},
	}
	local s=sp[state or "idle"]
	local frame=new("Frame",{
		Size=UDim2.fromOffset(76,24),
		BackgroundColor3=s.bg,
		BorderSizePixel=0,
	}, parent)
	corner(frame,7)
	pad(frame,0,0,10,10)

	local inner=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},frame)
	listLayout(inner,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Center,6)

	local dot=new("Frame",{
		Size=UDim2.fromOffset(5,5),
		BackgroundColor3=s.dot,
		BorderSizePixel=0,
		LayoutOrder=0,
	}, inner)
	corner(dot,3)

	local lbl=new("TextLabel",{
		Text=s.text,
		Font=Enum.Font.GothamBold,
		TextSize=9,
		TextColor3=s.tc,
		BackgroundTransparency=1,
		Size=UDim2.new(0,0,1,0),
		AutomaticSize=Enum.AutomaticSize.X,
		LayoutOrder=1,
	}, inner)

	local badge={Frame=frame,Label=lbl,Dot=dot,_sp=sp}
	function badge:SetState(ns)
		local p=self._sp[ns]; if not p then return end
		tw(self.Frame,.2,{BackgroundColor3=p.bg})
		tw(self.Dot,.2,{BackgroundColor3=p.dot})
		self.Label.Text=p.text; self.Label.TextColor3=p.tc
	end
	return badge
end

function Lib:ShowNotification(msg, style, duration, title)
	local styleMap={
		info    ={dot=C.Blue,   bg=C.BlueDim},
		success ={dot=C.Green,  bg=C.GreenDim},
		warning ={dot=C.Yellow, bg=C.YellowDim},
		error   ={dot=C.Red,    bg=C.RedDim},
	}
	local st=styleMap[style or "info"] or styleMap.info

	local notif=new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=201,
		ClipsDescendants=true,
	}, self._notifHolder)
	corner(notif,10)
	local nStroke=stroke(notif,C.Border2,1,1)
	pad(notif,12,12,14,14)

	local accent=new("Frame",{
		Size=UDim2.fromOffset(3,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=st.dot,
		BorderSizePixel=0,
		ZIndex=202,
	}, notif)
	corner(accent,2)

	if title then
		new("TextLabel",{
			Text=title,
			Font=Enum.Font.GothamBold,
			TextSize=12,
			TextColor3=C.White,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(12,0),
			Size=UDim2.new(1,-12,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,
			ZIndex=202,
		}, notif)
	end

	new("TextLabel",{
		Text=msg or "",
		Font=Enum.Font.Gotham,
		TextSize=11,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Position=UDim2.fromOffset(12,title and 20 or 0),
		Size=UDim2.new(1,-12,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true,
		ZIndex=202,
	}, notif)

	tw(notif,.3,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
	tw(nStroke,.3,{Transparency=0})

	task.delay(duration or 3.5,function()
		if not notif or not notif.Parent then return end
		tw(notif,.25,{BackgroundTransparency=1})
		tw(nStroke,.25,{Transparency=1})
		task.delay(.28,function()
			if notif and notif.Parent then
				tw(notif,.22,{Size=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
				task.delay(.24,function()
					if notif and notif.Parent then notif:Destroy() end
				end)
			end
		end)
	end)
end

function Lib:ToggleVisibility()
	local win=self.Window
	if not win then return end
	if win.Visible and win.BackgroundTransparency<.5 then
		tw(win,.22,{BackgroundTransparency=1,Size=UDim2.fromOffset(win.AbsoluteSize.X-10,win.AbsoluteSize.Y-10)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.24,function() if win and win.Parent then win.Visible=false end end)
	else
		win.Visible=true
		win.BackgroundTransparency=1
		tw(win,.3,{BackgroundTransparency=0,Size=UDim2.fromOffset(self.cfg.WindowWidth,self.cfg.WindowHeight)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
	end
end

function Lib:SetVisible(v)
	if self.Window then
		self.Window.Visible=v
		if v then self.Window.BackgroundTransparency=0 end
	end
end

function Lib:Destroy()
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	if self._sg and self._sg.Parent then
		tw(self.Window,.22,{BackgroundTransparency=1})
		task.delay(.25,function()
			pcall(function() self._sg:Destroy() end)
		end)
	end
end

return Lib
