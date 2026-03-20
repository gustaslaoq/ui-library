local Lib = {}
Lib.__index = Lib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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

local function tw(obj, t, props, es, ed)
	if not obj or not obj.Parent then return end
	local ok, tween = pcall(TweenService.Create, TweenService, obj,
		TweenInfo.new(t or .2, es or Enum.EasingStyle.Quint, ed or Enum.EasingDirection.Out), props)
	if ok and tween then tween:Play() return tween end
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
	return new("UIStroke",{Color=c or fromHex("1a1a1a"),Thickness=th or 1,Transparency=tr or 0},obj)
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

local C = {
	Bg       = fromHex("060606"),
	Bg2      = fromHex("080808"),
	Sidebar  = fromHex("050505"),
	Card     = fromHex("0e0e0e"),
	Card2    = fromHex("131313"),
	Card3    = fromHex("191919"),
	Border   = fromHex("1a1a1a"),
	Border2  = fromHex("222222"),
	Border3  = fromHex("2e2e2e"),
	Text     = fromHex("d8d8d8"),
	TextDim  = fromHex("666666"),
	TextOff  = fromHex("2e2e2e"),
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
}

local DefaultConfig = {
	AppName          = "MY APP",
	AppSubtitle      = "Subtitle",
	AppVersion       = "1.0",
	LogoImage        = "",
	GuiParent        = "CoreGui",
	WindowWidth      = 920,
	WindowHeight     = 580,
	SidebarWidth     = 210,
	TweenSpeed       = 0.22,
	BarTweenSpeed    = 0.28,
	MiniModeBreakpoint = 700,
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

	self._pages      = {}
	self._navBtns    = {}
	self._conns      = {}
	self._ord        = {}
	self._pageIdx    = 1
	self._minimised  = false
	self._miniWasUsed= false
	self._mobilePill = nil
	self._preMinSize = nil
	self._minBtn     = nil

	local guiParent = self.cfg.GuiParent == "PlayerGui"
		and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

	self._sg = new("ScreenGui",{
		Name="SlaoqUI",
		ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
		DisplayOrder=999,
	}, guiParent)
	pcall(function() self._sg.IgnoreGuiInset = true end)

	self:_buildWindow()
	self:_runSplash()
	return self
end

function Lib:_useMiniMode()
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1920,1080)
	return UserInputService.TouchEnabled or vp.X < self.cfg.MiniModeBreakpoint
end

function Lib:_runSplash()
	local cfg = self.cfg
	self.Window.Visible = false

	local card = new("Frame",{
		AnchorPoint      = Vector2.new(.5,.5),
		Position         = UDim2.fromScale(.5,.5),
		Size             = UDim2.fromOffset(360,220),
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		ZIndex           = 600,
		ClipsDescendants = false,
	}, self._sg)
	corner(card, 18)
	stroke(card, C.Border2, 1)

	local logoBox = new("Frame",{
		AnchorPoint      = Vector2.new(.5,0),
		Position         = UDim2.new(.5,0,0,30),
		Size             = UDim2.fromOffset(54,54),
		BackgroundColor3 = C.Card3,
		BorderSizePixel  = 0,
		ZIndex           = 601,
	}, card)
	corner(logoBox, 14)
	stroke(logoBox, C.Border3, 1)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage,ZIndex=602},logoBox)
	else
		new("TextLabel",{
			Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,TextSize=24,TextColor3=C.White,ZIndex=602,
		},logoBox)
	end

	new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,98),
		Size=UDim2.new(1,-32,0,22), BackgroundTransparency=1,
		Text=cfg.AppName, Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=C.White, ZIndex=601,
	}, card)

	new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,122),
		Size=UDim2.new(1,-32,0,15), BackgroundTransparency=1,
		Text=cfg.AppSubtitle, Font=Enum.Font.Gotham, TextSize=11,
		TextColor3=C.TextDim, ZIndex=601,
	}, card)

	local taskLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0), Position=UDim2.new(.5,0,0,152),
		Size=UDim2.new(1,-32,0,14), BackgroundTransparency=1,
		Text=cfg.SplashTasks[1] or "Loading...",
		Font=Enum.Font.Gotham, TextSize=10,
		TextColor3=C.TextOff, ZIndex=601,
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
	local n     = #tasks

	task.spawn(function()
		task.wait(.2)
		for i,t in ipairs(tasks) do
			tw(taskLbl,.15,{TextTransparency=1})
			task.wait(.12)
			taskLbl.Text = t
			tw(taskLbl,.2,{TextTransparency=0})
			tw(barFill,.45,{Size=UDim2.fromScale(i/n,1)},Enum.EasingStyle.Quint)
			task.wait(.55)
		end
		task.wait(.2)
		tw(card,.35,{BackgroundTransparency=1,Size=UDim2.fromOffset(340,200)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.wait(.38)
		pcall(function() card:Destroy() end)
		self.Window.Visible = true
		self.Window.BackgroundTransparency = 1
		tw(self.Window,.35,{BackgroundTransparency=0},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
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
		ClipsDescendants=true,
	}, self._sg)
	corner(win,12)
	stroke(win,C.Border,1)
	self.Window = win

	local function doScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp  = cam.ViewportSize
		local mini = self:_useMiniMode()
		local s   = math.min(math.clamp(vp.X/1920,.35,1),math.clamp(vp.Y/1080,.35,1))
		local w   = mini and math.floor(vp.X*.97) or math.floor(cfg.WindowWidth*s)
		local h   = mini and math.floor(vp.Y*.93) or math.floor(cfg.WindowHeight*s)
		if not self._minimised then
			win.Size = UDim2.fromOffset(w,h)
		end
		if self._sidebar then
			local sw = mini and 48 or math.floor(cfg.SidebarWidth*s)
			self._sidebar.Size = UDim2.new(0,sw,1,0)
			self:_setCollapsed(sw < 90)
		end
	end
	self._doScale = doScale

	table.insert(self._conns,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if not self._minimised then doScale() end
		end))

	self:_buildTitleBar(win)
	self:_buildBody(win)
	self:_initPages()
	self:SetPage(1)
	task.defer(doScale)
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
	new("Frame",{Position=UDim2.new(0,0,1,-13),Size=UDim2.new(1,0,0,13),BackgroundColor3=C.Bg2,BorderSizePixel=0,ZIndex=10},tb)
	new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=10},tb)
	self.TitleBar = tb

	local left = new("Frame",{Size=UDim2.new(1,-90,1,0),BackgroundTransparency=1,ZIndex=11},tb)
	pad(left,0,0,14,0)
	hlist(left,10)

	local logoMini = new("Frame",{Size=UDim2.fromOffset(26,26),BackgroundColor3=C.Card3,BorderSizePixel=0,LayoutOrder=0},left)
	corner(logoMini,7)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage,ZIndex=12},logoMini)
	else
		new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=string.upper(string.sub(cfg.AppName,1,1)),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,ZIndex=12},logoMini)
	end

	new("TextLabel",{Text=cfg.AppName,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,BackgroundTransparency=1,Size=UDim2.fromOffset(0,26),AutomaticSize=Enum.AutomaticSize.X,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,LayoutOrder=1},left)

	local ver = new("Frame",{Size=UDim2.fromOffset(0,22),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=C.Card3,BorderSizePixel=0,ZIndex=11,LayoutOrder=2},left)
	corner(ver,5)
	pad(ver,0,0,8,8)
	new("TextLabel",{Text="v"..cfg.AppVersion,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.fromOffset(0,22),AutomaticSize=Enum.AutomaticSize.X,ZIndex=12},ver)

	local right = new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(88,44),BackgroundTransparency=1,ZIndex=11},tb)
	hlist(right,0)

	local function mkBtn(sym,hc,cb,lo)
		local b = new("TextButton",{Text=sym,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.fromOffset(44,44),ZIndex=12,AutoButtonColor=false,LayoutOrder=lo},right)
		b.MouseEnter:Connect(function() tw(b,.12,{TextColor3=hc,BackgroundTransparency=.93}) end)
		b.MouseLeave:Connect(function() tw(b,.15,{TextColor3=C.TextDim,BackgroundTransparency=1}) end)
		b.Activated:Connect(cb)
		return b
	end
	self._minBtn = mkBtn("-",C.White,function() self:Minimise() end,1)
	mkBtn("x",C.Red,function() self:Destroy() end,2)

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
			self.Window.Position = UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
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

	local ss = new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},sidebar)
	vlist(ss,0,Enum.HorizontalAlignment.Center)
	pad(ss,18,18,8,8)

	local logoArea = new("Frame",{Size=UDim2.new(1,0,0,104),BackgroundTransparency=1,LayoutOrder=0},ss)
	local logoWrap = new("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),Size=UDim2.fromOffset(52,52),BackgroundColor3=C.Card3,BorderSizePixel=0},logoArea)
	corner(logoWrap,14)
	stroke(logoWrap,C.Border2,1)
	if cfg.LogoImage ~= "" then
		new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=cfg.LogoImage},logoWrap)
	else
		new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=string.upper(string.sub(cfg.AppName,1,1)),Font=Enum.Font.GothamBold,TextSize=23,TextColor3=C.White},logoWrap)
	end

	self._sideNameLbl = new("TextLabel",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,60),Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=cfg.AppName,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,TextTruncate=Enum.TextTruncate.AtEnd},logoArea)
	self._sideSubLbl  = new("TextLabel",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,80),Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=cfg.AppSubtitle,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextDim,TextTruncate=Enum.TextTruncate.AtEnd},logoArea)

	local divArea = new("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=1},ss)
	new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.8,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},divArea)

	local bar = new("Frame",{Size=UDim2.fromOffset(3,0),AnchorPoint=Vector2.new(0,.5),Position=UDim2.fromOffset(0,100),BackgroundColor3=C.White,BorderSizePixel=0,ZIndex=9,Visible=false},sidebar)
	corner(bar,2)
	self._bar = bar

	for i,page in ipairs(cfg.Pages) do
		self:_makeNavBtn(page,i,ss)
	end
	new("Frame",{Size=UDim2.fromOffset(1,14),BackgroundTransparency=1,LayoutOrder=#cfg.Pages+10},ss)

	local content = new("Frame",{Position=UDim2.new(0,cfg.SidebarWidth,0,0),Size=UDim2.new(1,-cfg.SidebarWidth,1,0),BackgroundColor3=C.Bg2,BorderSizePixel=0,ClipsDescendants=true},body)
	self._content = content

	table.insert(self._conns, sidebar:GetPropertyChangedSignal("Size"):Connect(function()
		local sw = sidebar.Size.X.Offset
		content.Position = UDim2.new(0,sw,0,0)
		content.Size     = UDim2.new(1,-sw,1,0)
	end))

	local nh = new("Frame",{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-10),Size=UDim2.new(.65,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=200},win)
	vlist(nh,6)
	self._notifHolder = nh
end

function Lib:_makeNavBtn(page,index,parent)
	local cfg = self.cfg

	local frame = new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=index+1},parent)

	local bg = new("Frame",{Size=UDim2.new(1,-8,1,-4),Position=UDim2.fromOffset(4,2),BackgroundColor3=C.Card2,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5},frame)
	corner(bg,8)

	local dot = new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,22,.5,0),Size=UDim2.fromOffset(6,6),BackgroundColor3=C.TextOff,BorderSizePixel=0,ZIndex=6},frame)
	corner(dot,3)

	local lbl = new("TextLabel",{Text=page.Name,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TextDim,BackgroundTransparency=1,Position=UDim2.fromOffset(36,0),Size=UDim2.new(1,-44,1,0),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=6},frame)

	local click = new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=7,AutoButtonColor=false},frame)
	click.AutoButtonColor = false
	pcall(function() click.CursorIcon = "rbxasset://SystemCursors/PointingHand" end)

	click.MouseEnter:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.15,{BackgroundTransparency=.88})
			tw(lbl,.15,{TextColor3=C.Text})
			tw(dot,.15,{BackgroundColor3=C.TextDim,Size=UDim2.fromOffset(7,7)})
		end
	end)
	click.MouseLeave:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.18,{BackgroundTransparency=1})
			tw(lbl,.18,{TextColor3=C.TextDim})
			tw(dot,.18,{BackgroundColor3=C.TextOff,Size=UDim2.fromOffset(6,6)})
		end
	end)
	click.Activated:Connect(function() self:SetPage(index) end)
	self._navBtns[index] = {Frame=frame,Bg=bg,Lbl=lbl,Dot=dot}
end

function Lib:_initPages()
	for i=1,#self.cfg.Pages do
		local frame = new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.Bg2,BackgroundTransparency=1,Visible=false},self._content)
		local scroll = new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Border3,ScrollBarImageTransparency=.5,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ElasticBehavior=Enum.ElasticBehavior.Never},frame)
		new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},scroll)
		pad(scroll,24,24,24,24)
		self._pages[i]  = {Frame=frame,Scroll=scroll}
		self._ord[i]    = 0
	end
end

function Lib:SetPage(index)
	local cfg = self.cfg
	if self._pages[self._pageIdx] then
		local oldFrame = self._pages[self._pageIdx].Frame
		tw(oldFrame,.15,{BackgroundTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.16,function() if oldFrame and oldFrame.Parent then oldFrame.Visible=false; oldFrame.BackgroundTransparency=1 end end)
	end
	local old = self._navBtns[self._pageIdx]
	if old then
		tw(old.Lbl,cfg.TweenSpeed,{TextColor3=C.TextDim})
		tw(old.Bg,cfg.TweenSpeed,{BackgroundTransparency=1})
		tw(old.Dot,cfg.TweenSpeed,{BackgroundColor3=C.TextOff,Size=UDim2.fromOffset(6,6)})
	end
	self._pageIdx = index
	local newPage = self._pages[index]
	if newPage then
		newPage.Frame.BackgroundTransparency = 1
		newPage.Frame.Visible = true
		tw(newPage.Frame,.2,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
	end
	local nb = self._navBtns[index]
	if nb then
		tw(nb.Lbl,cfg.TweenSpeed,{TextColor3=C.White})
		tw(nb.Bg,cfg.TweenSpeed,{BackgroundTransparency=.88})
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
	if self._sideNameLbl then self._sideNameLbl.Visible = not c end
	if self._sideSubLbl  then self._sideSubLbl.Visible  = not c end
	for _,nb in ipairs(self._navBtns) do
		if nb and nb.Lbl then nb.Lbl.Visible = not c end
	end
end

function Lib:_ensurePill()
	if self._mobilePill then return end
	local pill = new("TextButton",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,-60),
		Size=UDim2.fromOffset(170,42),
		BackgroundColor3=C.Card2,
		BorderSizePixel=0,
		Text="Show Interface",
		Font=Enum.Font.GothamBold,
		TextSize=13,
		TextColor3=C.White,
		AutoButtonColor=false,
		ZIndex=800,
		Visible=false,
	}, self._sg)
	corner(pill,999)
	stroke(pill,C.Border2,1)
	pill.MouseEnter:Connect(function() tw(pill,.15,{BackgroundColor3=C.Card3}) end)
	pill.MouseLeave:Connect(function() tw(pill,.18,{BackgroundColor3=C.Card2}) end)
	pill.Activated:Connect(function() self:Maximise() end)
	self._mobilePill = pill
end

function Lib:Minimise()
	if self._minimised then return end
	self._minimised = true

	local win  = self.Window
	local mini = self:_useMiniMode()
	self._miniWasUsed = mini

	if mini then
		self:_ensurePill()
		local pill = self._mobilePill
		tw(win,.2,{BackgroundTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.22,function()
			if win and win.Parent then win.Visible=false end
		end)
		pill.Visible=true
		pill.Position=UDim2.new(.5,0,0,-60)
		pill.BackgroundTransparency=1
		tw(pill,.38,{Position=UDim2.new(.5,0,0,20),BackgroundTransparency=0},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
	else
		self._preMinSize = {W=win.AbsoluteSize.X, H=win.AbsoluteSize.Y}
		self._body.Visible = false
		local miniW = math.max(380, math.floor(win.AbsoluteSize.X*.68))
		tw(win,.4,{Size=UDim2.fromOffset(miniW,44)},Enum.EasingStyle.Quint)
		if self._minBtn then self._minBtn.Text = "+" end
	end
end

function Lib:Maximise()
	if not self._minimised then return end
	self._minimised = false

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
		tw(win,.32,{BackgroundTransparency=0},Enum.EasingStyle.Quint)
	else
		local prev    = self._preMinSize
		local cfg     = self.cfg
		local targetW = prev and prev.W or cfg.WindowWidth
		local targetH = prev and prev.H or cfg.WindowHeight
		tw(win,.45,{Size=UDim2.fromOffset(targetW,targetH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		task.delay(.18,function()
			if self._body then self._body.Visible = true end
		end)
		if self._minBtn then self._minBtn.Text = "-" end
	end
end

function Lib:ToggleVisibility()
	if self._minimised then self:Maximise() else self:Minimise() end
end

function Lib:SetVisible(v)
	if v then
		if self._minimised then self:Maximise() else
			if self.Window then self.Window.Visible=true; self.Window.BackgroundTransparency=0 end
		end
	else
		if not self._minimised then self:Minimise() end
	end
end

function Lib:_o(pi)
	self._ord[pi] = (self._ord[pi] or 0)+1
	return self._ord[pi]
end

function Lib:GetPage(i)
	return self._pages[i] and self._pages[i].Scroll or nil
end

function Lib:_gap(s,pi,h)
	new("Frame",{Size=UDim2.new(1,0,0,h or 8),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
end

function Lib:AddSectionHeader(pi,title,sub)
	local s=self:GetPage(pi); if not s then return end
	self:_gap(s,pi,4)
	if title then
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=20,TextColor3=C.White,BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
	end
	if sub then
		new("TextLabel",{Text=sub,Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
	end
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	self:_gap(s,pi,16)
end

function Lib:AddMetricRow(pi,cards)
	local s=self:GetPage(pi); if not s then return end
	local n=# cards; local cols=math.min(n,3); local rows=math.ceil(n/cols)
	local H=82; local G=10

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,rows*(H+G)-G),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)

	local objects={}
	for i,card in ipairs(cards) do
		local row=math.floor((i-1)/cols); local col=(i-1)%cols
		local wOff = n==1 and 0 or (col==0 or col==cols-1) and -G/2 or -G

		local f=new("Frame",{BackgroundColor3=C.Card,BorderSizePixel=0,ZIndex=2,Position=UDim2.new(col/cols,col>0 and G or 0,0,row*(H+G)),Size=UDim2.new(1/cols,wOff,0,H)},wrap)
		corner(f,10)
		stroke(f,C.Border,1)
		pad(f,14,14,16,14)

		new("TextLabel",{Text=string.upper(card.Label or ""),Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,13),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},f)

		local valLbl=new("TextLabel",{Text=tostring(card.Value or "---"),Font=Enum.Font.GothamBold,TextSize=24,TextColor3=C.White,BackgroundTransparency=1,Position=UDim2.fromOffset(0,16),Size=UDim2.new(1,0,0,32),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},f)

		if card.Unit and card.Unit~="" then
			new("TextLabel",{Text=card.Unit,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TextOff,BackgroundTransparency=1,Position=UDim2.fromOffset(0,50),Size=UDim2.new(1,0,0,14),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},f)
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
	local s=self:GetPage(pi); if not s then return end

	local row=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
	hlist(row,10)

	local styles={
		primary = {bg=C.White,    tc=C.Bg,    hov=fromHex("e0e0e0"),dn=fromHex("c0c0c0")},
		danger  = {bg=C.Red,      tc=C.White, hov=fromHex("ff5555"),dn=fromHex("bb2222")},
		warning = {bg=C.Yellow,   tc=C.Bg,    hov=C.Orange,          dn=fromHex("b04010")},
		ghost   = {bg=C.Card2,    tc=C.Text,  hov=C.Card3,           dn=C.Card},
		outline = {bg=C.Card,     tc=C.Text,  hov=C.Card2,           dn=C.Sidebar},
		success = {bg=C.GreenBg,  tc=C.Green, hov=fromHex("061a0d"),dn=fromHex("030a06")},
	}

	local btns={}
	for i,def in ipairs(defs) do
		local st=styles[def.Style or "primary"]
		local w=def.Width or 130

		local btn=new("TextButton",{Text=def.Text or "",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=st.tc,BackgroundColor3=st.bg,BorderSizePixel=0,Size=UDim2.fromOffset(w,40),AutoButtonColor=false,LayoutOrder=i},row)
		corner(btn,9)
		if def.Style=="outline" then stroke(btn,C.Border2,1) end

		btn.MouseEnter:Connect(function() tw(btn,.14,{BackgroundColor3=st.hov}) end)
		btn.MouseLeave:Connect(function() tw(btn,.16,{BackgroundColor3=st.bg}) end)
		btn.MouseButton1Down:Connect(function() tw(btn,.07,{BackgroundColor3=st.dn,Size=UDim2.fromOffset(w-4,38)}) end)
		btn.MouseButton1Up:Connect(function() tw(btn,.2,{BackgroundColor3=st.hov,Size=UDim2.fromOffset(w,40)},Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
		pcall(function() btn.CursorIcon = "rbxasset://SystemCursors/PointingHand" end)
		if def.Callback then
			btn.Activated:Connect(function()
				local ok,err = pcall(def.Callback)
				if not ok then
					local orig = st.bg
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
	return r and r[1]
end

function Lib:AddToggle(pi,label,default,callback)
	local s=self:GetPage(pi); if not s then return end

	local row=new("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(row,10)
	stroke(row,C.Border,1)
	pad(row,0,0,16,16)

	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-64,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

	local state=default==true

	local track=new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(44,24),BackgroundColor3=state and C.White or C.Card3,BorderSizePixel=0},row)
	corner(track,12)
	local tStroke=stroke(track,state and fromHex("aaaaaa") or C.Border2,1)

	local knob=new("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,state and 22 or 2,.5,0),Size=UDim2.fromOffset(20,20),BackgroundColor3=state and C.Bg or C.TextDim,BorderSizePixel=0},track)
	corner(knob,10)

	local function apply(v,silent)
		state=v
		tw(track,.22,{BackgroundColor3=v and C.White or C.Card3},Enum.EasingStyle.Quart)
		tw(tStroke,.22,{Color=v and fromHex("aaaaaa") or C.Border2})
		tw(knob,.22,{Position=UDim2.new(0,v and 22 or 2,.5,0),BackgroundColor3=v and C.Bg or C.TextDim},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		if not silent and callback then callback(v) end
	end

	local click=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false},track)
	pcall(function() click.CursorIcon = "rbxasset://SystemCursors/PointingHand" end)
	click.MouseButton1Down:Connect(function() tw(knob,.07,{Size=UDim2.fromOffset(22,18)}) end)
	click.MouseButton1Up:Connect(function() tw(knob,.15,{Size=UDim2.fromOffset(20,20)},Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
	click.Activated:Connect(function() apply(not state) end)

	row.MouseEnter:Connect(function() tw(row,.15,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.18,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local t={Track=track,Knob=knob}
	function t:SetState(v) apply(v,true) end
	function t:GetState() return state end
	return t
end

function Lib:AddInput(pi,labelTxt,placeholder,callback)
	local s=self:GetPage(pi); if not s then return end

	if labelTxt then
		new("TextLabel",{Text=labelTxt,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
		self:_gap(s,pi,4)
	end

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	local ws=stroke(wrap,C.Border,1)
	pad(wrap,0,0,16,16)

	local box=new("TextBox",{Text="",PlaceholderText=placeholder or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,PlaceholderColor3=C.TextOff,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},wrap)

	box.Focused:Connect(function() tw(wrap,.16,{BackgroundColor3=C.Card2}); tw(ws,.16,{Color=C.Border3}) end)
	box.FocusLost:Connect(function(enter) tw(wrap,.18,{BackgroundColor3=C.Card}); tw(ws,.18,{Color=C.Border}); if callback then callback(box.Text,enter) end end)
	wrap.MouseEnter:Connect(function() if not box:IsFocused() then tw(wrap,.15,{BackgroundColor3=C.Card2}) end end)
	wrap.MouseLeave:Connect(function() if not box:IsFocused() then tw(wrap,.18,{BackgroundColor3=C.Card}) end end)

	self:_gap(s,pi,10)
	return box
end

function Lib:AddCard(pi,title,subtitle)
	local s=self:GetPage(pi); if not s then return end

	local card=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(card,10)
	stroke(card,C.Border,1)

	if title then
		local hdr=new("Frame",{Size=UDim2.new(1,0,0,subtitle and 54 or 42),BackgroundColor3=C.Card2,BorderSizePixel=0},card)
		corner(hdr,10)
		new("Frame",{Position=UDim2.new(0,0,1,-11),Size=UDim2.new(1,0,0,11),BackgroundColor3=C.Card2,BorderSizePixel=0},hdr)
		new("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},hdr)
		pad(hdr,0,0,16,16)
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,BackgroundTransparency=1,Position=UDim2.fromOffset(0,11),Size=UDim2.new(1,0,0,20),TextXAlignment=Enum.TextXAlignment.Left},hdr)
		if subtitle then
			new("TextLabel",{Text=subtitle,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TextDim,BackgroundTransparency=1,Position=UDim2.fromOffset(0,33),Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Left},hdr)
		end
	end

	local inner=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},card)
	pad(inner,14,14,16,16)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},inner)

	self:_gap(s,pi,10)
	return inner
end

function Lib:AddLogConsole(pi,height)
	local s=self:GetPage(pi); if not s then return end

	local frame=new("Frame",{Size=UDim2.new(1,0,0,height or 220),BackgroundColor3=fromHex("050505"),BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=self:_o(pi)},s)
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
	new("TextLabel",{Text="CONSOLE",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},hdr)

	local textBox=new("TextBox",{Text="",Font=Enum.Font.Code,TextSize=11,TextColor3=C.TextDim,BackgroundTransparency=1,Position=UDim2.fromOffset(0,35),Size=UDim2.new(1,0,1,-35),MultiLine=true,TextEditable=false,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Bottom,ClearTextOnFocus=false,TextWrapped=true,ZIndex=2},frame)
	pad(textBox,8,8,12,12)

	self:_gap(s,pi,10)

	local console={Frame=frame,TextBox=textBox,_dot=dot,_lines={}}
	local pfx={INFO="[INFO]  ",SUCCESS="[OK]    ",WARN="[WARN]  ",ERROR="[ERR]   ",SNIPE="[SNIPE] ",DEBUG="[DBG]   "}
	function console:Log(msg,level)
		local lv=string.upper(level or "INFO")
		local ts=os.date("%H:%M:%S")
		table.insert(self._lines,("%s  %s  %s"):format(ts,pfx[lv] or "[INFO]  ",tostring(msg)))
		if #self._lines>400 then table.remove(self._lines,1) end
		self.TextBox.Text=table.concat(self._lines,"\n")
	end
	function console:Clear() self._lines={}; self.TextBox.Text="" end
	function console:SetActive(v) tw(self._dot,.2,{BackgroundColor3=v and C.Green or C.Red}) end
	return console
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
	local lbl=new("TextLabel",{Text=text or "",Font=st.font,TextSize=st.size,TextColor3=st.color,BackgroundTransparency=1,Size=UDim2.new(1,0,0,st.size+12),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=self:_o(pi)},s)
	self:_gap(s,pi,4)
	return lbl
end

function Lib:AddSeparator(pi,spacing)
	local s=self:GetPage(pi); if not s then return end
	local sp=spacing or 6
	self:_gap(s,pi,sp)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	self:_gap(s,pi,sp)
end

function Lib:AddDropdown(pi,labelTxt,options,callback)
	local s=self:GetPage(pi); if not s then return end

	if labelTxt then
		new("TextLabel",{Text=labelTxt,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=self:_o(pi)},s)
		self:_gap(s,pi,4)
	end

	local selected=options[1] or ""
	local open=false

	local wrapper=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ClipsDescendants=false,LayoutOrder=self:_o(pi),ZIndex=50},s)

	local btn=new("TextButton",{Text="",BackgroundColor3=C.Card,BorderSizePixel=0,Size=UDim2.new(1,0,0,44),AutoButtonColor=false,ZIndex=51},wrapper)
	corner(btn,10)
	local bStroke=stroke(btn,C.Border,1)
	pad(btn,0,0,16,16)
	hlist(btn,0)

	local selLbl=new("TextLabel",{Text=selected,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-22,1,0),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52,LayoutOrder=0},btn)
	local arrow=new("TextLabel",{Text="v",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.fromOffset(22,22),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=52,LayoutOrder=1},btn)

	local listH=#options*40
	local optList=new("Frame",{Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Card2,BorderSizePixel=0,ClipsDescendants=true,ZIndex=60,Visible=false},wrapper)
	corner(optList,10)
	stroke(optList,C.Border2,1)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},optList)

	for i,opt in ipairs(options) do
		local ob=new("TextButton",{Text=opt,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundColor3=C.Card2,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,40),AutoButtonColor=false,LayoutOrder=i,ZIndex=61,TextXAlignment=Enum.TextXAlignment.Left},optList)
		pad(ob,0,0,16,16)
		ob.MouseEnter:Connect(function() tw(ob,.1,{BackgroundTransparency=.84}) end)
		ob.MouseLeave:Connect(function() tw(ob,.12,{BackgroundTransparency=1}) end)
		ob.Activated:Connect(function()
			selected=opt; selLbl.Text=opt; open=false
			tw(optList,.18,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			tw(arrow,.18,{Rotation=0})
			task.delay(.2,function() if optList then optList.Visible=false end end)
			if callback then callback(opt) end
		end)
	end

	btn.MouseEnter:Connect(function() tw(btn,.14,{BackgroundColor3=C.Card2}) end)
	btn.MouseLeave:Connect(function() tw(btn,.16,{BackgroundColor3=C.Card}) end)
	pcall(function() btn.CursorIcon = "rbxasset://SystemCursors/PointingHand" end)
	btn.Activated:Connect(function()
		open=not open; optList.Visible=true
		if open then
			tw(optList,.25,{Size=UDim2.new(1,0,0,listH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
			tw(arrow,.2,{Rotation=180})
		else
			tw(optList,.18,{Size=UDim2.new(1,0,0,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
			tw(arrow,.2,{Rotation=0})
			task.delay(.2,function() if optList then optList.Visible=false end end)
		end
	end)

	self:_gap(s,pi,10)
	return {Button=btn,List=optList,GetSelected=function() return selected end}
end

function Lib:CreateStatusBadge(parent,state)
	local sp={
		on   ={text="ONLINE", bg=C.GreenBg, tc=C.Green, dot=C.Green},
		off  ={text="OFFLINE",bg=C.RedBg,   tc=C.Red,   dot=C.Red},
		idle ={text="IDLE",   bg=C.YellowBg,tc=C.Yellow,dot=C.Yellow},
	}
	local st=sp[state or "idle"]
	local frame=new("Frame",{Size=UDim2.fromOffset(82,26),BackgroundColor3=st.bg,BorderSizePixel=0},parent)
	corner(frame,7)
	pad(frame,0,0,10,10)
	hlist(frame,7)
	local dot=new("Frame",{Size=UDim2.fromOffset(6,6),BackgroundColor3=st.dot,BorderSizePixel=0,LayoutOrder=0},frame)
	corner(dot,3)
	local lbl=new("TextLabel",{Text=st.text,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=st.tc,BackgroundTransparency=1,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,LayoutOrder=1},frame)
	local badge={Frame=frame,Label=lbl,Dot=dot,_sp=sp}
	function badge:SetState(ns)
		local p=self._sp[ns]; if not p then return end
		tw(self.Frame,.2,{BackgroundColor3=p.bg})
		tw(self.Dot,.2,{BackgroundColor3=p.dot})
		self.Label.Text=p.text; self.Label.TextColor3=p.tc
	end
	return badge
end

function Lib:ShowNotification(msg,style,duration,title)
	local styleMap={
		info    ={dot=C.Blue,  bg=C.BlueBg},
		success ={dot=C.Green, bg=C.GreenBg},
		warning ={dot=C.Yellow,bg=C.YellowBg},
		error   ={dot=C.Red,   bg=C.RedBg},
	}
	local st=styleMap[style or "info"] or styleMap.info
	local h=title and 60 or 44

	local notif=new("Frame",{Size=UDim2.new(1,0,0,h),BackgroundColor3=C.Card2,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=201,Position=UDim2.new(0,0,1,0)},self._notifHolder)
	corner(notif,10)
	stroke(notif,C.Border2,1)
	pad(notif,10,10,14,14)

	new("Frame",{Size=UDim2.fromOffset(3,h>44 and 40 or 24),BackgroundColor3=st.dot,BorderSizePixel=0,ZIndex=202,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0)},notif)

	if title then
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-12,0,20),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=202},notif)
	end
	new("TextLabel",{Text=msg or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,BackgroundTransparency=1,Position=title and UDim2.fromOffset(12,22) or UDim2.fromOffset(12,0),Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=202},notif)

	tw(notif,.35,{BackgroundTransparency=0,Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)

	task.delay(duration or 3.5,function()
		if not notif or not notif.Parent then return end
		tw(notif,.22,{BackgroundTransparency=1,Position=UDim2.new(0,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
		task.delay(.25,function()
			if notif and notif.Parent then notif:Destroy() end
		end)
	end)
end

function Lib:AddSlider(pi,label,min,max,default,callback)
	local s=self:GetPage(pi); if not s then return end
	min=min or 0; max=max or 100; default=math.clamp(default or min,min,max)

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	pad(wrap,12,12,16,16)

	local topRow=new("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1},wrap)
	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-50,1,0),TextXAlignment=Enum.TextXAlignment.Left},topRow)
	local valLbl=new("TextLabel",{Text=tostring(default),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.White,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(50,18),TextXAlignment=Enum.TextXAlignment.Right},topRow)

	local trackBg=new("Frame",{Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,0,0,6),BackgroundColor3=C.Card3,BorderSizePixel=0},wrap)
	corner(trackBg,3)
	local fill=new("Frame",{Size=UDim2.fromScale((default-min)/(max-min),1),BackgroundColor3=C.White,BorderSizePixel=0},trackBg)
	corner(fill,3)
	local knobSl=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new((default-min)/(max-min),0,.5,0),Size=UDim2.fromOffset(14,14),BackgroundColor3=C.White,BorderSizePixel=0,ZIndex=3},trackBg)
	corner(knobSl,7)

	local dragging=false
	local interact=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,14),Position=UDim2.fromOffset(0,-7),ZIndex=4,AutoButtonColor=false},trackBg)
	pcall(function() interact.CursorIcon="rbxasset://SystemCursors/PointingHand" end)

	local function updateVal(absX)
		local rel=math.clamp((absX-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
		local v=math.floor(min+rel*(max-min)+.5)
		local pct=(v-min)/(max-min)
		tw(fill,.06,{Size=UDim2.fromScale(pct,1)})
		tw(knobSl,.06,{Position=UDim2.new(pct,0,.5,0)})
		valLbl.Text=tostring(v)
		if callback then callback(v) end
	end

	interact.MouseButton1Down:Connect(function(x) dragging=true; updateVal(x) end)
	table.insert(self._conns,UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
	end))
	table.insert(self._conns,UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			updateVal(i.Position.X)
		end
	end))

	wrap.MouseEnter:Connect(function() tw(wrap,.15,{BackgroundColor3=C.Card2}) end)
	wrap.MouseLeave:Connect(function() tw(wrap,.18,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=wrap,Fill=fill,Knob=knobSl,ValueLabel=valLbl,_min=min,_max=max}
	function obj:SetValue(v)
		v=math.clamp(v,self._min,self._max)
		local pct=(v-self._min)/(self._max-self._min)
		tw(self.Fill,.15,{Size=UDim2.fromScale(pct,1)})
		tw(self.Knob,.15,{Position=UDim2.new(pct,0,.5,0)})
		self.ValueLabel.Text=tostring(v)
	end
	return obj
end

function Lib:AddParagraph(pi,title,content)
	local s=self:GetPage(pi); if not s then return end

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	pad(wrap,14,14,16,16)
	vlist(wrap,8)

	local titleLbl=new("TextLabel",{Text=title or "",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.White,BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=0},wrap)
	new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=1},wrap)
	local contentLbl=new("TextLabel",{Text=content or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},wrap)

	self:_gap(s,pi,6)
	local obj={Frame=wrap,TitleLabel=titleLbl,ContentLabel=contentLbl}
	function obj:Set(t,c)
		if t then self.TitleLabel.Text=t end
		if c then self.ContentLabel.Text=c end
	end
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

	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-120,1,0),TextXAlignment=Enum.TextXAlignment.Left},row)

	local keyBtn=new("TextButton",{Text=currentKey,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.White,BackgroundColor3=C.Card3,BorderSizePixel=0,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(90,32),AutoButtonColor=false},row)
	corner(keyBtn,8)
	stroke(keyBtn,C.Border2,1)
	pcall(function() keyBtn.CursorIcon="rbxasset://SystemCursors/PointingHand" end)

	keyBtn.Activated:Connect(function()
		if listening then return end
		listening=true
		keyBtn.Text="..."
		tw(keyBtn,.15,{BackgroundColor3=C.Card2})
	end)

	table.insert(self._conns,UserInputService.InputBegan:Connect(function(input,gp)
		if not listening then return end
		if input.UserInputType~=Enum.UserInputType.Keyboard then return end
		local kc=input.KeyCode
		if kc==Enum.KeyCode.Escape then
			listening=false
			keyBtn.Text=currentKey
			tw(keyBtn,.15,{BackgroundColor3=C.Card3})
			return
		end
		local name=tostring(kc):gsub("Enum.KeyCode.","")
		currentKey=name
		keyBtn.Text=name
		listening=false
		tw(keyBtn,.15,{BackgroundColor3=C.Card3})
		if callback then callback(name) end
	end))

	row.MouseEnter:Connect(function() tw(row,.15,{BackgroundColor3=C.Card2}) end)
	row.MouseLeave:Connect(function() tw(row,.18,{BackgroundColor3=C.Card}) end)

	self:_gap(s,pi,6)
	local obj={Frame=row,Button=keyBtn}
	function obj:GetKey() return currentKey end
	function obj:SetKey(k) currentKey=k; keyBtn.Text=k end
	return obj
end

function Lib:AddBadge(pi, text, style)
	local s=self:GetPage(pi); if not s then return end
	local styleMap={
		default ={bg=C.Card3,   tc=C.TextDim, dot=nil},
		success ={bg=C.GreenBg, tc=C.Green,   dot=C.Green},
		error   ={bg=C.RedBg,   tc=C.Red,     dot=C.Red},
		warning ={bg=C.YellowBg,tc=C.Yellow,  dot=C.Yellow},
		info    ={bg=C.BlueBg,  tc=C.Blue,    dot=C.Blue},
		white   ={bg=C.Card2,   tc=C.White,   dot=nil},
	}
	local st=styleMap[style or "default"] or styleMap.default
	local wrap=new("Frame",{Size=UDim2.new(0,0,0,26),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=st.bg,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,6)
	pad(wrap,0,0,st.dot and 8 or 10, 10)
	hlist(wrap,6)
	if st.dot then
		local d=new("Frame",{Size=UDim2.fromOffset(6,6),BackgroundColor3=st.dot,BorderSizePixel=0,LayoutOrder=0},wrap)
		corner(d,3)
	end
	local lbl=new("TextLabel",{Text=text or "",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=st.tc,BackgroundTransparency=1,Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,LayoutOrder=1},wrap)
	self:_gap(s,pi,6)
	local obj={Frame=wrap,Label=lbl}
	function obj:Set(t) self.Label.Text=t end
	return obj
end

function Lib:AddAlert(pi, title, message, style)
	local s=self:GetPage(pi); if not s then return end
	local styleMap={
		info    ={accent=C.Blue,   bg=C.BlueBg,   tc=C.Blue},
		success ={accent=C.Green,  bg=C.GreenBg,  tc=C.Green},
		warning ={accent=C.Yellow, bg=C.YellowBg, tc=C.Yellow},
		error   ={accent=C.Red,    bg=C.RedBg,    tc=C.Red},
	}
	local st=styleMap[style or "info"] or styleMap.info

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=st.bg,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	pad(wrap,12,12,16,16)

	local accent=new("Frame",{Size=UDim2.fromOffset(3,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=st.accent,BorderSizePixel=0,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0)},wrap)
	corner(accent,2)

	local inner=new("Frame",{Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},wrap)
	vlist(inner,4)

	if title and title~="" then
		new("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=st.tc,BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=0},inner)
	end
	local msgLbl=new("TextLabel",{Text=message or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TextDim,BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},inner)

	self:_gap(s,pi,6)
	local obj={Frame=wrap,MessageLabel=msgLbl}
	function obj:Set(msg) self.MessageLabel.Text=msg or "" end
	function obj:Show() self.Frame.Visible=true end
	function obj:Hide() self.Frame.Visible=false end
	return obj
end

function Lib:AddProgressBar(pi, label, value, maxVal)
	local s=self:GetPage(pi); if not s then return end
	value=value or 0; maxVal=maxVal or 100
	local pct=math.clamp(value/maxVal,0,1)

	local wrap=new("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)
	pad(wrap,12,12,16,16)

	local topRow=new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1},wrap)
	new("TextLabel",{Text=label or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-40,1,0),TextXAlignment=Enum.TextXAlignment.Left},topRow)
	local pctLbl=new("TextLabel",{Text=math.floor(pct*100).."%",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.White,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(40,16),TextXAlignment=Enum.TextXAlignment.Right},topRow)

	local trackBg=new("Frame",{Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,8),BackgroundColor3=C.Card3,BorderSizePixel=0},wrap)
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

function Lib:AddRichLabel(pi, content)
	local s=self:GetPage(pi); if not s then return end
	local lbl=new("TextLabel",{
		Text=content or "",
		Font=Enum.Font.Gotham,
		TextSize=13,
		TextColor3=C.Text,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true,
		RichText=true,
		LayoutOrder=self:_o(pi),
	},s)
	self:_gap(s,pi,6)
	local obj={Label=lbl}
	function obj:Set(text) self.Label.Text=text end
	function obj:Show() self.Label.Visible=true end
	function obj:Hide() self.Label.Visible=false end
	return obj
end

function Lib:AddDivider(pi, text, spacing)
	local s=self:GetPage(pi); if not s then return end
	local sp=spacing or 8
	self:_gap(s,pi,sp)

	if text and text~="" then
		local row=new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,LayoutOrder=self:_o(pi)},s)
		new("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.new(.36,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},row)
		new("TextLabel",{Text=string.upper(text),Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TextOff,BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.24,0,1,0),TextXAlignment=Enum.TextXAlignment.Center},row)
		new("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.new(.36,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},row)
	else
		new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0,LayoutOrder=self:_o(pi)},s)
	end
	self:_gap(s,pi,sp)
end

function Lib:AddTable(pi, headers, rows)
	local s=self:GetPage(pi); if not s then return end
	local cols=#headers
	local rowH=36

	local wrap=new("Frame",{
		Size=UDim2.new(1,0,0,(#rows+1)*rowH),
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
		ClipsDescendants=true,
	},s)
	corner(wrap,10)
	stroke(wrap,C.Border,1)

	local function makeRow(data, isHeader, rowIndex)
		local bg=isHeader and C.Card2 or (rowIndex%2==0 and C.Card or C.Sidebar)
		local f=new("Frame",{
			Size=UDim2.new(1,0,0,rowH),
			Position=UDim2.fromOffset(0,(rowIndex)*rowH),
			BackgroundColor3=bg,
			BorderSizePixel=0,
		},wrap)
		if isHeader then
			new("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Border,BorderSizePixel=0},f)
		end
		for c,txt in ipairs(data) do
			new("TextLabel",{
				Text=tostring(txt),
				Font=isHeader and Enum.Font.GothamBold or Enum.Font.Gotham,
				TextSize=11,
				TextColor3=isHeader and C.White or C.Text,
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
		makeRow(row,false,i)
	end

	self:_gap(s,pi,10)
	local obj={Frame=wrap,_headers=headers,_rows=rows}
	function obj:Show() self.Frame.Visible=true end
	function obj:Hide() self.Frame.Visible=false end
	return obj
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

function Lib:Destroy()
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	if self._sg and self._sg.Parent then
		if self.Window then tw(self.Window,.2,{BackgroundTransparency=1}) end
		task.delay(.24,function() pcall(function() self._sg:Destroy() end) end)
	end
end

return Lib
