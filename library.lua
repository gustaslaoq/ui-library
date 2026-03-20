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

local function tw(obj, t, props, es, ed)
	if not obj or not obj.Parent then return end
	local ok, tween = pcall(TweenService.Create, TweenService, obj,
		TweenInfo.new(t or .18, es or Enum.EasingStyle.Quint, ed or Enum.EasingDirection.Out), props)
	if ok then tween:Play() return tween end
end

local function new(class, props, parent)
	local ok, obj = pcall(Instance.new, class)
	if not ok then return end
	if props then
		for k,v in pairs(props) do
			if k ~= "Parent" then
				pcall(function() obj[k] = v end)
			end
		end
	end
	obj.Parent = parent
	return obj
end

local function corner(obj, r)   new("UICorner",  {CornerRadius=UDim.new(0,r or 8)},   obj) end
local function stroke(obj,c,th) new("UIStroke",  {Color=c,Thickness=th or 1},          obj) end
local function pad(obj,t,b,l,r) new("UIPadding", {PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0)}, obj) end
local function listLayout(obj,dir,halign,spacing)
	new("UIListLayout",{FillDirection=dir or Enum.FillDirection.Vertical,HorizontalAlignment=halign or Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,spacing or 0)},obj)
end

local C = {
	Bg      = fromHex("060606"),
	Bg2     = fromHex("0a0a0a"),
	Sidebar = fromHex("070707"),
	Card    = fromHex("111111"),
	Card2   = fromHex("161616"),
	Card3   = fromHex("1c1c1c"),
	Border  = fromHex("1e1e1e"),
	Border2 = fromHex("282828"),
	Border3 = fromHex("333333"),
	Text    = fromHex("e0e0e0"),
	TextDim = fromHex("888888"),
	TextOff = fromHex("444444"),
	White   = fromHex("ffffff"),
	Accent  = fromHex("ffffff"),
	Green   = fromHex("00e87a"),
	Red     = fromHex("e84040"),
	Yellow  = fromHex("f0c030"),
	Orange  = fromHex("f07020"),
	Purple  = fromHex("9966ff"),
	Blue    = fromHex("4488ff"),
}

local DefaultConfig = {
	AppName          = "MY APP",
	AppSubtitle      = "Subtitle",
	AppVersion       = "1.0",
	LogoImage        = "",
	GuiParent        = "CoreGui",
	WindowWidth      = 860,
	WindowHeight     = 560,
	SidebarWidth     = 190,
	TweenSpeed       = 0.2,
	BarTweenSpeed    = 0.25,
	MobileBreakpoint = 650,
	Pages            = {
		{Icon="", Name="Dashboard"},
		{Icon="", Name="Settings"},
		{Icon="", Name="Logs"},
	},
	SplashTasks = {
		"Initializing...",
		"Loading configuration...",
		"Starting engine...",
		"Ready.",
	},
}

function Lib.new(userCfg)
	local self = setmetatable({}, Lib)

	self.cfg = {}
	for k,v in pairs(DefaultConfig) do self.cfg[k]=v end
	if userCfg then
		for k,v in pairs(userCfg) do
			if k ~= "Pages" and k ~= "SplashTasks" then
				self.cfg[k] = v
			else
				self.cfg[k] = v
			end
		end
	end

	self._pages     = {}
	self._navBtns   = {}
	self._conns     = {}
	self._ord       = {}
	self._pageIdx   = 1

	local guiParent = self.cfg.GuiParent == "PlayerGui"
		and LocalPlayer:WaitForChild("PlayerGui")
		or  CoreGui

	self._sg = new("ScreenGui", {
		Name         = self.cfg.AppName.."_UI",
		ResetOnSpawn = false,
		ZIndexBehavior= Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	}, guiParent)
	pcall(function() self._sg.IgnoreGuiInset = true end)

	self:_buildSplash()

	return self
end

function Lib:_buildSplash()
	local cfg = self.cfg

	local overlay = new("Frame", {
		Size             = UDim2.fromScale(1,1),
		BackgroundColor3 = C.Bg,
		BorderSizePixel  = 0,
		ZIndex           = 200,
	}, self._sg)

	local card = new("Frame", {
		AnchorPoint      = Vector2.new(.5,.5),
		Position         = UDim2.fromScale(.5,.5),
		Size             = UDim2.fromOffset(420, 260),
		BackgroundColor3 = C.Card,
		BorderSizePixel  = 0,
		ZIndex           = 201,
	}, overlay)
	corner(card, 16)
	stroke(card, C.Border2, 1)

	local logoLbl = new("TextLabel", {
		AnchorPoint            = Vector2.new(.5,0),
		Position               = UDim2.new(.5,0,0,32),
		Size                   = UDim2.fromOffset(52,52),
		BackgroundColor3       = C.Card2,
		BorderSizePixel        = 0,
		Text                   = cfg.LogoImage == "" and string.upper(string.sub(cfg.AppName,1,1)) or "",
		Font                   = Enum.Font.GothamBold,
		TextSize               = 22,
		TextColor3             = C.White,
		ZIndex                 = 202,
	}, card)
	corner(logoLbl, 14)
	stroke(logoLbl, C.Border3, 1)
	if cfg.LogoImage ~= "" then
		logoLbl.Text = ""
		new("ImageLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Image=cfg.LogoImage,
			ZIndex=203,
		}, logoLbl)
	end

	local appName = new("TextLabel", {
		AnchorPoint            = Vector2.new(.5,0),
		Position               = UDim2.new(.5,0,0,96),
		Size                   = UDim2.new(1,-40,0,22),
		BackgroundTransparency = 1,
		Text                   = cfg.AppName,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 17,
		TextColor3             = C.White,
		ZIndex                 = 202,
	}, card)

	local appSub = new("TextLabel", {
		AnchorPoint            = Vector2.new(.5,0),
		Position               = UDim2.new(.5,0,0,120),
		Size                   = UDim2.new(1,-40,0,16),
		BackgroundTransparency = 1,
		Text                   = cfg.AppSubtitle,
		Font                   = Enum.Font.Gotham,
		TextSize               = 11,
		TextColor3             = C.TextDim,
		ZIndex                 = 202,
	}, card)

	local taskLbl = new("TextLabel", {
		AnchorPoint            = Vector2.new(.5,0),
		Position               = UDim2.new(.5,0,0,156),
		Size                   = UDim2.new(1,-40,0,14),
		BackgroundTransparency = 1,
		Text                   = cfg.SplashTasks[1] or "Loading...",
		Font                   = Enum.Font.Gotham,
		TextSize               = 10,
		TextColor3             = C.TextOff,
		ZIndex                 = 202,
	}, card)

	local barBg = new("Frame", {
		AnchorPoint      = Vector2.new(.5,0),
		Position         = UDim2.new(.5,0,0,178),
		Size             = UDim2.new(1,-40,0,4),
		BackgroundColor3 = C.Card3,
		BorderSizePixel  = 0,
		ZIndex           = 202,
	}, card)
	corner(barBg, 2)

	local barFill = new("Frame", {
		Size             = UDim2.fromOffset(0,4),
		BackgroundColor3 = C.White,
		BorderSizePixel  = 0,
		ZIndex           = 203,
	}, barBg)
	corner(barFill, 2)

	local tasks = cfg.SplashTasks
	local n     = #tasks

	local function runSplash(done)
		local step = (barBg.AbsoluteSize.X) / n
		for i, taskText in ipairs(tasks) do
			taskLbl.Text = taskText
			local targetW = step * i
			tw(barFill, 0.35, {Size=UDim2.fromOffset(targetW, 4)})
			task.wait(0.45)
		end
		task.wait(0.2)
		tw(overlay, 0.4, {BackgroundTransparency=1})
		task.wait(0.45)
		overlay:Destroy()
		done()
	end

	task.spawn(runSplash, function()
		self:_buildWindow()
	end)
end

function Lib:_buildWindow()
	local cfg = self.cfg

	local win = new("Frame", {
		Name             = "Window",
		AnchorPoint      = Vector2.new(.5,.5),
		Position         = UDim2.fromScale(.5,.5),
		Size             = UDim2.fromOffset(cfg.WindowWidth, cfg.WindowHeight),
		BackgroundColor3 = C.Bg,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
	}, self._sg)
	corner(win, 10)
	stroke(win, C.Border, 1)
	self.Window = win

	win.BackgroundTransparency = 1
	tw(win, .35, {BackgroundTransparency=0})

	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local mob = vp.X < cfg.MobileBreakpoint or UserInputService.TouchEnabled
		local s   = math.min(math.clamp(vp.X/1920,.4,1), math.clamp(vp.Y/1080,.4,1))
		local w   = mob and math.floor(vp.X*.97) or math.floor(cfg.WindowWidth*s)
		local h   = mob and math.floor(vp.Y*.93) or math.floor(cfg.WindowHeight*s)
		win.Size  = UDim2.fromOffset(w,h)
		if self._sidebar then
			local sw = (mob or s<.6) and 48 or math.floor(cfg.SidebarWidth*s)
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
	updateScale()
end

function Lib:_buildTitleBar(win)
	local cfg = self.cfg

	local tb = new("Frame", {
		Name             = "TitleBar",
		Size             = UDim2.new(1,0,0,38),
		BackgroundColor3 = C.Bg2,
		BorderSizePixel  = 0,
		ZIndex           = 10,
	}, win)
	new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=10},tb)
	self.TitleBar = tb

	local left = new("Frame",{Size=UDim2.new(.6,0,1,0),BackgroundTransparency=1,ZIndex=11},tb)
	pad(left,0,0,14,0)
	listLayout(left, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, 8)

	new("TextLabel",{
		Text=cfg.AppName,Font=Enum.Font.GothamBold,TextSize=11,
		TextColor3=C.White,BackgroundTransparency=1,
		Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,
	},left)

	local ver = new("Frame",{Size=UDim2.new(0,0,0,18),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=C.Card3,BorderSizePixel=0,ZIndex=11,LayoutOrder=1},left)
	corner(ver,4)
	pad(ver,0,0,6,6)
	new("TextLabel",{
		Text="v"..cfg.AppVersion,Font=Enum.Font.Gotham,TextSize=9,
		TextColor3=C.TextDim,BackgroundTransparency=1,
		Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
		ZIndex=12,
	},ver)

	local right = new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.new(.4,0,1,0),BackgroundTransparency=1,ZIndex=11},tb)
	listLayout(right, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, 0)

	local function winBtn(txt, hoverC, cb)
		local b = new("TextButton",{
			Text=txt,Font=Enum.Font.GothamBold,TextSize=12,
			TextColor3=C.TextDim,BackgroundTransparency=1,
			Size=UDim2.fromOffset(38,38),AutoButtonColor=false,ZIndex=12,
		},right)
		b.MouseEnter:Connect(function() tw(b,.1,{TextColor3=hoverC or C.White,BackgroundTransparency=.9}) end)
		b.MouseLeave:Connect(function() tw(b,.1,{TextColor3=C.TextDim,BackgroundTransparency=1}) end)
		b.Activated:Connect(cb)
		return b
	end

	winBtn("-", C.White, function() self:ToggleVisibility() end)
	local closeB = winBtn("x", C.Red, function() self:Destroy() end)
	corner(closeB, 0)

	do
		local drag, ds, ws = false
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
			self.Window.Position = UDim2.new(ws.X.Scale, ws.X.Offset+d.X, ws.Y.Scale, ws.Y.Offset+d.Y)
		end))
	end
end

function Lib:_buildBody(win)
	local cfg = self.cfg

	local body = new("Frame",{
		Position=UDim2.fromOffset(0,38),
		Size=UDim2.new(1,0,1,-38),
		BackgroundTransparency=1,
	},win)
	self._body = body

	local sidebar = new("Frame",{
		Size=UDim2.new(0,cfg.SidebarWidth,1,0),
		BackgroundColor3=C.Sidebar,
		BorderSizePixel=0,
		ClipsDescendants=true,
		ZIndex=5,
	},body)
	new("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=6},sidebar)
	self._sidebar = sidebar

	local ss = new("ScrollingFrame",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		ScrollBarThickness=0,
		CanvasSize=UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.Y,
	},sidebar)
	listLayout(ss, nil, Enum.HorizontalAlignment.Center, 0)
	pad(ss,16,16,8,8)
	self._sideScroll = ss

	local logoArea = new("Frame",{
		Size=UDim2.new(1,0,0,88),
		BackgroundTransparency=1,
		LayoutOrder=0,
	},ss)

	local logoFrame = new("Frame",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,0),
		Size=UDim2.fromOffset(46,46),
		BackgroundColor3=C.Card3,
		BorderSizePixel=0,
	},logoArea)
	corner(logoFrame,12)
	stroke(logoFrame,C.Border2,1)

	if self.cfg.LogoImage ~= "" then
		new("ImageLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Image=self.cfg.LogoImage,
		},logoFrame)
	else
		new("TextLabel",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Text=string.upper(string.sub(cfg.AppName,1,1)),
			Font=Enum.Font.GothamBold,
			TextSize=20,
			TextColor3=C.White,
		},logoFrame)
	end

	self._sideNameLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,52),
		Size=UDim2.new(1,0,0,16),
		BackgroundTransparency=1,
		Text=cfg.AppName,
		Font=Enum.Font.GothamBold,
		TextSize=11,
		TextColor3=C.White,
		TextTruncate=Enum.TextTruncate.AtEnd,
	},logoArea)
	self._sideSubLbl = new("TextLabel",{
		AnchorPoint=Vector2.new(.5,0),
		Position=UDim2.new(.5,0,0,70),
		Size=UDim2.new(1,0,0,13),
		BackgroundTransparency=1,
		Text=cfg.AppSubtitle,
		Font=Enum.Font.Gotham,
		TextSize=9,
		TextColor3=C.TextDim,
		TextTruncate=Enum.TextTruncate.AtEnd,
	},logoArea)

	local divFrame = new("Frame",{
		Size=UDim2.new(1,0,0,20),
		BackgroundTransparency=1,
		LayoutOrder=1,
	},ss)
	new("Frame",{
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.fromScale(.5,.5),
		Size=UDim2.new(.75,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
	},divFrame)

	local barIndicator = new("Frame",{
		Size=UDim2.fromOffset(3,0),
		AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.fromOffset(0,0),
		BackgroundColor3=C.White,
		BorderSizePixel=0,
		ZIndex=9,
		Visible=false,
	},sidebar)
	corner(barIndicator,2)
	self._bar = barIndicator

	for i,page in ipairs(cfg.Pages) do
		self:_makeNavBtn(page,i,ss)
	end

	new("Frame",{Size=UDim2.fromOffset(1,12),BackgroundTransparency=1,LayoutOrder=#cfg.Pages+10},ss)

	local content = new("Frame",{
		Position=UDim2.new(0,cfg.SidebarWidth,0,0),
		Size=UDim2.new(1,-cfg.SidebarWidth,1,0),
		BackgroundColor3=C.Bg2,
		BorderSizePixel=0,
		ClipsDescendants=true,
	},body)
	self._content = content

	table.insert(self._conns, sidebar:GetPropertyChangedSignal("Size"):Connect(function()
		local sw = sidebar.Size.X.Offset
		content.Position = UDim2.new(0,sw,0,0)
		content.Size     = UDim2.new(1,-sw,1,0)
	end))

	local notifF = new("Frame",{
		AnchorPoint=Vector2.new(.5,1),
		Position=UDim2.new(.5,0,1,70),
		Size=UDim2.fromOffset(300,40),
		BackgroundColor3=C.Card2,
		BorderSizePixel=0,
		ZIndex=150,
	},win)
	corner(notifF,8)
	stroke(notifF,C.Border2,1)
	pad(notifF,0,0,14,14)
	local notifT = new("TextLabel",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		Text="",
		Font=Enum.Font.Gotham,
		TextSize=11,
		TextColor3=C.Text,
		TextXAlignment=Enum.TextXAlignment.Left,
		ZIndex=151,
	},notifF)
	local notifDot = new("Frame",{
		AnchorPoint=Vector2.new(1,.5),
		Position=UDim2.new(1,-14,.5,0),
		Size=UDim2.fromOffset(6,6),
		BackgroundColor3=C.Green,
		BorderSizePixel=0,
		ZIndex=152,
	},notifF)
	corner(notifDot,3)
	self._notifFrame = notifF
	self._notifText  = notifT
	self._notifDot   = notifDot
end

function Lib:_makeNavBtn(page, index, parent)
	local cfg = self.cfg

	local frame = new("Frame",{
		Size=UDim2.new(1,0,0,36),
		BackgroundTransparency=1,
		LayoutOrder=index+1,
	},parent)

	local bg = new("Frame",{
		Size=UDim2.new(1,-8,1,-4),
		Position=UDim2.fromOffset(4,2),
		BackgroundColor3=C.Card2,
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ZIndex=5,
	},frame)
	corner(bg,7)

	local dot = new("Frame",{
		AnchorPoint=Vector2.new(.5,.5),
		Position=UDim2.new(0,22,.5,0),
		Size=UDim2.fromOffset(5,5),
		BackgroundColor3=C.TextOff,
		BorderSizePixel=0,
		ZIndex=6,
	},frame)
	corner(dot,3)
	self._navBtns[index] = self._navBtns[index] or {}
	self._navBtns[index]._dot = dot

	local lbl = new("TextLabel",{
		Text=page.Name,
		Font=Enum.Font.GothamBold,
		TextSize=11,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Position=UDim2.fromOffset(36,0),
		Size=UDim2.new(1,-44,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
		ZIndex=6,
	},frame)

	local click = new("TextButton",{
		Text="",
		BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),
		ZIndex=7,
		AutoButtonColor=false,
	},frame)

	click.MouseEnter:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.12,{BackgroundTransparency=.93})
			tw(lbl,.12,{TextColor3=C.Text})
		end
	end)
	click.MouseLeave:Connect(function()
		if self._pageIdx ~= index then
			tw(bg,.12,{BackgroundTransparency=1})
			tw(lbl,.12,{TextColor3=C.TextDim})
		end
	end)
	click.Activated:Connect(function() self:SetPage(index) end)

	self._navBtns[index] = {Frame=frame, Bg=bg, Lbl=lbl, Dot=dot}
end

function Lib:_initPages()
	for i=1,#self.cfg.Pages do
		local pageFrame = new("Frame",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			Visible=false,
		},self._content)

		local scroll = new("ScrollingFrame",{
			Size=UDim2.fromScale(1,1),
			BackgroundTransparency=1,
			ScrollBarThickness=3,
			ScrollBarImageColor3=C.Border3,
			ScrollBarImageTransparency=.5,
			CanvasSize=UDim2.new(0,0,0,0),
			AutomaticCanvasSize=Enum.AutomaticSize.Y,
			ElasticBehavior=Enum.ElasticBehavior.Never,
		},pageFrame)

		new("UIListLayout",{
			SortOrder=Enum.SortOrder.LayoutOrder,
			Padding=UDim.new(0,0),
		},scroll)
		pad(scroll,22,22,22,22)

		self._pages[i]  = {Frame=pageFrame, Scroll=scroll}
		self._ord[i]    = 0
	end
end

function Lib:SetPage(index)
	local cfg = self.cfg
	if self._pages[self._pageIdx] then
		self._pages[self._pageIdx].Frame.Visible = false
	end
	local old = self._navBtns[self._pageIdx]
	if old then
		tw(old.Lbl, cfg.TweenSpeed, {TextColor3=C.TextDim})
		tw(old.Bg,  cfg.TweenSpeed, {BackgroundTransparency=1})
		tw(old.Dot, cfg.TweenSpeed, {BackgroundColor3=C.TextOff})
	end

	self._pageIdx = index

	if self._pages[index] then
		self._pages[index].Frame.Visible = true
	end
	local nb = self._navBtns[index]
	if nb then
		tw(nb.Lbl, cfg.TweenSpeed, {TextColor3=C.White})
		tw(nb.Bg,  cfg.TweenSpeed, {BackgroundTransparency=.92})
		tw(nb.Dot, cfg.TweenSpeed, {BackgroundColor3=C.White})
		self:_animBar(nb.Frame)
	end
end

function Lib:_animBar(target)
	local bar = self._bar
	if not bar or not target then return end
	local ok,y = pcall(function()
		return target.AbsolutePosition.Y - self._sidebar.AbsolutePosition.Y + target.AbsoluteSize.Y*.5
	end)
	if not ok then return end
	bar.Visible = true
	local t1 = tw(bar, self.cfg.BarTweenSpeed*.4, {Size=UDim2.fromOffset(3,0)},
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	if t1 then
		t1.Completed:Connect(function()
			bar.Position = UDim2.new(0,0,0,y)
			tw(bar, self.cfg.BarTweenSpeed*.65, {Size=UDim2.fromOffset(3,30)},
				Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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

function Lib:_o(pi)
	self._ord[pi] = (self._ord[pi] or 0) + 1
	return self._ord[pi]
end

function Lib:GetPage(i)
	return self._pages[i] and self._pages[i].Scroll or nil
end

function Lib:_gap(scroll, pi, h)
	new("Frame",{
		Size=UDim2.new(1,0,0,h or 8),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	},scroll)
end

function Lib:AddSectionHeader(pi, title, sub)
	local scroll = self:GetPage(pi); if not scroll then return end

	self:_gap(scroll,pi,4)

	local frame = new("Frame",{
		Size=UDim2.new(1,0,0,sub and 52 or 32),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	},scroll)

	new("TextLabel",{
		Text=title,
		Font=Enum.Font.GothamBold,
		TextSize=17,
		TextColor3=C.White,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,24),
		TextXAlignment=Enum.TextXAlignment.Left,
	},frame)
	if sub then
		new("TextLabel",{
			Text=sub,
			Font=Enum.Font.Gotham,
			TextSize=11,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(0,26),
			Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
		},frame)
	end

	local divFrame = new("Frame",{
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	},scroll)

	self:_gap(scroll,pi,14)
end

function Lib:AddMetricRow(pi, cards)
	local scroll = self:GetPage(pi); if not scroll then return end

	local cols  = math.min(#cards, 3)
	local rows  = math.ceil(#cards/cols)
	local cellH = 72
	local gap   = 8

	local wrap = new("Frame",{
		Size=UDim2.new(1,0,0, rows*(cellH+gap)-gap),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	},scroll)

	local objects = {}
	for i,card in ipairs(cards) do
		local row = math.floor((i-1)/cols)
		local col = (i-1) % cols
		local cellW = (1/cols)
		local x = col*(cellW) + (col>0 and gap/wrap.AbsoluteSize.X or 0)

		local f = new("Frame",{
			BackgroundColor3=C.Card,
			BorderSizePixel=0,
			ZIndex=2,
			Position=UDim2.new(col/cols, col>0 and gap or 0, 0, row*(cellH+gap)),
			Size=UDim2.new(1/cols, col==0 and -gap/2 or (col==cols-1 and -gap/2 or -gap), 0, cellH),
		},wrap)
		corner(f,10)
		stroke(f,C.Border,1)
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
			LetterSpacing=2,
		},f)

		local valLbl = new("TextLabel",{
			Text=tostring(card.Value or "---"),
			Font=Enum.Font.GothamBold,
			TextSize=22,
			TextColor3=C.White,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(0,14),
			Size=UDim2.new(1,0,0,28),
			TextXAlignment=Enum.TextXAlignment.Left,
			ZIndex=3,
		},f)

		if card.Unit and card.Unit ~= "" then
			new("TextLabel",{
				Text=card.Unit,
				Font=Enum.Font.Gotham,
				TextSize=9,
				TextColor3=C.TextDim,
				BackgroundTransparency=1,
				Position=UDim2.fromOffset(0,44),
				Size=UDim2.new(1,0,0,12),
				TextXAlignment=Enum.TextXAlignment.Left,
				ZIndex=3,
			},f)
		end

		local hover = new("TextButton",{
			Text="",BackgroundTransparency=1,
			Size=UDim2.fromScale(1,1),ZIndex=4,AutoButtonColor=false,
		},f)
		hover.MouseEnter:Connect(function() tw(f,.12,{BackgroundColor3=C.Card2}) end)
		hover.MouseLeave:Connect(function() tw(f,.12,{BackgroundColor3=C.Card})  end)

		objects[i] = {Frame=f, ValueLabel=valLbl}
	end

	self:_gap(scroll,pi,14)
	return objects
end

function Lib:SetMetricValue(obj, val)
	if obj and obj.ValueLabel then obj.ValueLabel.Text = tostring(val) end
end

function Lib:AddButtonRow(pi, defs)
	local scroll = self:GetPage(pi); if not scroll then return end

	local row = new("Frame",{
		Size=UDim2.new(1,0,0,40),
		BackgroundTransparency=1,
		LayoutOrder=self:_o(pi),
	},scroll)
	listLayout(row, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, 8)

	local styles = {
		primary = {bg=C.White,    tc=C.Bg,    hov=fromHex("dddddd")},
		danger  = {bg=C.Red,      tc=C.White, hov=fromHex("ff5555")},
		warning = {bg=C.Yellow,   tc=C.Bg,    hov=C.Orange},
		ghost   = {bg=C.Card2,    tc=C.Text,  hov=C.Card3},
		outline = {bg="transparent", tc=C.Text, hov=C.Card2},
	}

	local btns = {}
	for i,def in ipairs(defs) do
		local s = styles[def.Style or "primary"]
		local isOutline = def.Style == "outline"
		local btn = new("TextButton",{
			Text=def.Text or "",
			Font=Enum.Font.GothamBold,
			TextSize=11,
			TextColor3=s.tc,
			BackgroundColor3=isOutline and C.Card or s.bg,
			BackgroundTransparency=isOutline and 0 or 0,
			BorderSizePixel=0,
			Size=UDim2.fromOffset(def.Width or 120, 36),
			AutoButtonColor=false,
			LayoutOrder=i,
		},row)
		corner(btn,8)
		if isOutline then stroke(btn,C.Border2,1) end
		btn.MouseEnter:Connect(function() tw(btn,.12,{BackgroundColor3=s.hov}) end)
		btn.MouseLeave:Connect(function() tw(btn,.12,{BackgroundColor3=isOutline and C.Card or s.bg}) end)
		btn.MouseButton1Down:Connect(function() tw(btn,.06,{BackgroundTransparency=.15}) end)
		btn.MouseButton1Up:Connect(function()   tw(btn,.06,{BackgroundTransparency=0})   end)
		if def.Callback then btn.Activated:Connect(def.Callback) end
		btns[i] = btn
	end

	self:_gap(scroll,pi,12)
	return btns
end

function Lib:AddButton(pi, text, style, cb)
	local r = self:AddButtonRow(pi,{{Text=text,Style=style or "primary",Callback=cb}})
	return r and r[1]
end

function Lib:AddToggle(pi, label, default, callback)
	local scroll = self:GetPage(pi); if not scroll then return end

	local row = new("Frame",{
		Size=UDim2.new(1,0,0,40),
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	},scroll)
	corner(row,8)
	stroke(row,C.Border,1)
	pad(row,0,0,14,14)

	new("TextLabel",{
		Text=label or "",
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=C.Text,
		BackgroundTransparency=1,
		Size=UDim2.new(1,-58,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
	},row)

	local state = default == true

	local track = new("Frame",{
		AnchorPoint=Vector2.new(1,.5),
		Position=UDim2.new(1,0,.5,0),
		Size=UDim2.fromOffset(38,20),
		BackgroundColor3=state and C.White or C.Card3,
		BorderSizePixel=0,
	},row)
	corner(track,10)
	stroke(track,C.Border2,1)

	local knob = new("Frame",{
		AnchorPoint=Vector2.new(0,.5),
		Position=UDim2.new(0,state and 20 or 2,.5,0),
		Size=UDim2.fromOffset(16,16),
		BackgroundColor3=state and C.Bg or C.TextDim,
		BorderSizePixel=0,
	},track)
	corner(knob,8)

	local click = new("TextButton",{
		Text="",BackgroundTransparency=1,
		Size=UDim2.fromScale(1,1),ZIndex=5,AutoButtonColor=false,
	},track)
	click.Activated:Connect(function()
		state = not state
		tw(track,.18,{BackgroundColor3=state and C.White or C.Card3})
		tw(knob,.18,{
			Position=UDim2.new(0,state and 20 or 2,.5,0),
			BackgroundColor3=state and C.Bg or C.TextDim,
		})
		if callback then callback(state) end
	end)

	self:_gap(scroll,pi,6)

	local t = {Track=track,Knob=knob}
	function t:SetState(v)
		state=v
		tw(self.Track,.18,{BackgroundColor3=v and C.White or C.Card3})
		tw(self.Knob,.18,{Position=UDim2.new(0,v and 20 or 2,.5,0),BackgroundColor3=v and C.Bg or C.TextDim})
	end
	function t:GetState() return state end
	return t
end

function Lib:AddInput(pi, labelTxt, placeholder, callback)
	local scroll = self:GetPage(pi); if not scroll then return end

	if labelTxt then
		new("TextLabel",{
			Text=labelTxt,
			Font=Enum.Font.GothamBold,
			TextSize=10,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=self:_o(pi),
		},scroll)
		self:_gap(scroll,pi,4)
	end

	local box = new("TextBox",{
		Text="",
		PlaceholderText=placeholder or "",
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=C.Text,
		PlaceholderColor3=C.TextOff,
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
		Size=UDim2.new(1,0,0,38),
		ClearTextOnFocus=false,
		LayoutOrder=self:_o(pi),
	},scroll)
	corner(box,8)
	stroke(box,C.Border,1)
	pad(box,0,0,14,14)

	box.Focused:Connect(function()
		tw(box,.12,{BackgroundColor3=C.Card2})
		for _,s in ipairs(box:GetChildren()) do
			if s:IsA("UIStroke") then tw(s,.12,{Color=C.Border3}) end
		end
	end)
	box.FocusLost:Connect(function(enter)
		tw(box,.12,{BackgroundColor3=C.Card})
		for _,s in ipairs(box:GetChildren()) do
			if s:IsA("UIStroke") then tw(s,.12,{Color=C.Border}) end
		end
		if callback then callback(box.Text,enter) end
	end)

	self:_gap(scroll,pi,10)
	return box
end

function Lib:AddCard(pi, title, subtitle)
	local scroll = self:GetPage(pi); if not scroll then return end

	local card = new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	},scroll)
	corner(card,10)
	stroke(card,C.Border,1)

	if title then
		local header = new("Frame",{
			Size=UDim2.new(1,0,0,subtitle and 48 or 38),
			BackgroundColor3=C.Card2,
			BorderSizePixel=0,
		},card)
		corner(header,10)
		new("Frame",{
			Position=UDim2.new(0,0,1,-1),
			Size=UDim2.new(1,0,0,1),
			BackgroundColor3=C.Border,
			BorderSizePixel=0,
		},header)
		pad(header,0,0,16,16)
		new("TextLabel",{
			Text=title,
			Font=Enum.Font.GothamBold,
			TextSize=12,
			TextColor3=C.White,
			BackgroundTransparency=1,
			Position=UDim2.fromOffset(0,10),
			Size=UDim2.new(1,0,0,18),
			TextXAlignment=Enum.TextXAlignment.Left,
		},header)
		if subtitle then
			new("TextLabel",{
				Text=subtitle,
				Font=Enum.Font.Gotham,
				TextSize=10,
				TextColor3=C.TextDim,
				BackgroundTransparency=1,
				Position=UDim2.fromOffset(0,29),
				Size=UDim2.new(1,0,0,13),
				TextXAlignment=Enum.TextXAlignment.Left,
			},header)
		end
	end

	local inner = new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
	},card)
	pad(inner,14,14,16,16)
	new("UIListLayout",{
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,8),
	},inner)

	self:_gap(scroll,pi,10)
	return inner
end

function Lib:AddLogConsole(pi, height)
	local scroll = self:GetPage(pi); if not scroll then return end

	local frame = new("Frame",{
		Size=UDim2.new(1,0,0,height or 200),
		BackgroundColor3=C.Bg,
		BorderSizePixel=0,
		ClipsDescendants=true,
		LayoutOrder=self:_o(pi),
	},scroll)
	corner(frame,10)
	stroke(frame,C.Border,1)

	local header = new("Frame",{
		Size=UDim2.new(1,0,0,30),
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
	},frame)
	corner(header,10)
	new("Frame",{
		Position=UDim2.new(0,0,1,0),
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
	},header)
	pad(header,0,0,12,12)
	new("TextLabel",{
		Text="CONSOLE",
		Font=Enum.Font.GothamBold,
		TextSize=9,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,1,0),
		TextXAlignment=Enum.TextXAlignment.Left,
		LetterSpacing=2,
	},header)

	local textBox = new("TextBox",{
		Text="",
		Font=Enum.Font.Code,
		TextSize=10,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		Position=UDim2.fromOffset(0,31),
		Size=UDim2.new(1,0,1,-31),
		MultiLine=true,
		TextEditable=false,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextYAlignment=Enum.TextYAlignment.Bottom,
		ClearTextOnFocus=false,
		TextWrapped=true,
		ZIndex=2,
	},frame)
	pad(textBox,8,8,12,12)

	self:_gap(scroll,pi,10)

	local console = {Frame=frame, TextBox=textBox, _lines={}}
	local colors = {INFO="[%s]",SUCCESS="[%s]",WARN="[%s]",ERROR="[%s]",SNIPE="[%s]",DEBUG="[%s]"}
	function console:Log(msg, level)
		local lv = string.upper(level or "INFO")
		local ts = os.date("%H:%M:%S")
		local line = ("[%s] [%s] %s"):format(ts, lv, tostring(msg))
		table.insert(self._lines, line)
		if #self._lines > 400 then table.remove(self._lines,1) end
		self.TextBox.Text = table.concat(self._lines,"\n")
	end
	function console:Clear()
		self._lines={}; self.TextBox.Text=""
	end
	return console
end

function Lib:AddLabel(pi, text, style)
	local scroll = self:GetPage(pi); if not scroll then return end
	local styles = {
		title    = {size=16,color=C.White, font=Enum.Font.GothamBold},
		subtitle = {size=13,color=C.Text,  font=Enum.Font.GothamBold},
		body     = {size=12,color=C.Text,  font=Enum.Font.Gotham},
		muted    = {size=11,color=C.TextDim,font=Enum.Font.Gotham},
		caption  = {size=9, color=C.TextOff,font=Enum.Font.Gotham},
	}
	local s = styles[style or "body"]
	local lbl = new("TextLabel",{
		Text=text or "",
		Font=s.font,
		TextSize=s.size,
		TextColor3=s.color,
		BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,s.size+8),
		TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true,
		LayoutOrder=self:_o(pi),
	},scroll)
	self:_gap(scroll,pi,4)
	return lbl
end

function Lib:AddSeparator(pi, spacing)
	local scroll = self:GetPage(pi); if not scroll then return end
	self:_gap(scroll,pi,spacing or 6)
	new("Frame",{
		Size=UDim2.new(1,0,0,1),
		BackgroundColor3=C.Border,
		BorderSizePixel=0,
		LayoutOrder=self:_o(pi),
	},scroll)
	self:_gap(scroll,pi,spacing or 6)
end

function Lib:AddDropdown(pi, labelTxt, options, callback)
	local scroll = self:GetPage(pi); if not scroll then return end

	if labelTxt then
		new("TextLabel",{
			Text=labelTxt,
			Font=Enum.Font.GothamBold,
			TextSize=10,
			TextColor3=C.TextDim,
			BackgroundTransparency=1,
			Size=UDim2.new(1,0,0,16),
			TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=self:_o(pi),
		},scroll)
		self:_gap(scroll,pi,4)
	end

	local selected = options[1] or ""
	local open     = false

	local wrapper = new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
		ClipsDescendants=false,
		LayoutOrder=self:_o(pi),
		ZIndex=50,
	},scroll)

	local dropBtn = new("TextButton",{
		Text=selected,
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=C.Text,
		BackgroundColor3=C.Card,
		BorderSizePixel=0,
		Size=UDim2.new(1,0,0,38),
		AutoButtonColor=false,
		ZIndex=51,
		TextXAlignment=Enum.TextXAlignment.Left,
	},wrapper)
	corner(dropBtn,8)
	stroke(dropBtn,C.Border,1)
	pad(dropBtn,0,0,14,40)

	new("TextLabel",{
		Text="v",
		Font=Enum.Font.GothamBold,
		TextSize=11,
		TextColor3=C.TextDim,
		BackgroundTransparency=1,
		AnchorPoint=Vector2.new(1,.5),
		Position=UDim2.new(1,-14,.5,0),
		Size=UDim2.fromOffset(14,14),
		ZIndex=52,
	},dropBtn)

	local listH = #options*34
	local optList = new("Frame",{
		Position=UDim2.fromOffset(0,42),
		Size=UDim2.new(1,0,0,0),
		BackgroundColor3=C.Card2,
		BorderSizePixel=0,
		ClipsDescendants=true,
		ZIndex=60,
		Visible=false,
	},wrapper)
	corner(optList,8)
	stroke(optList,C.Border2,1)
	new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},optList)

	for i,opt in ipairs(options) do
		local ob = new("TextButton",{
			Text=opt,
			Font=Enum.Font.Gotham,
			TextSize=12,
			TextColor3=C.Text,
			BackgroundColor3=C.Card2,
			BackgroundTransparency=1,
			BorderSizePixel=0,
			Size=UDim2.new(1,0,0,34),
			AutoButtonColor=false,
			LayoutOrder=i,
			ZIndex=61,
			TextXAlignment=Enum.TextXAlignment.Left,
		},optList)
		pad(ob,0,0,14,14)
		ob.MouseEnter:Connect(function() tw(ob,.08,{BackgroundTransparency=.85}) end)
		ob.MouseLeave:Connect(function() tw(ob,.08,{BackgroundTransparency=1})   end)
		ob.Activated:Connect(function()
			selected=opt; dropBtn.Text=opt; open=false
			tw(optList,.15,{Size=UDim2.new(1,0,0,0)})
			task.delay(.16,function() optList.Visible=false end)
			if callback then callback(opt) end
		end)
	end

	dropBtn.Activated:Connect(function()
		open=not open; optList.Visible=true
		if open then
			tw(optList,.2,{Size=UDim2.new(1,0,0,listH)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		else
			tw(optList,.15,{Size=UDim2.new(1,0,0,0)})
			task.delay(.16,function() optList.Visible=false end)
		end
	end)

	self:_gap(scroll,pi,10)
	return {Button=dropBtn,List=optList,GetSelected=function() return selected end}
end

function Lib:CreateStatusBadge(parent, state)
	local sp = {
		on   = {text="ONLINE",  bg=fromHex("0a2a1a"), tc=C.Green,  dot=C.Green},
		off  = {text="OFFLINE", bg=fromHex("2a0a0a"), tc=C.Red,    dot=C.Red},
		idle = {text="IDLE",    bg=fromHex("1e1e10"), tc=C.Yellow, dot=C.Yellow},
	}
	local s = sp[state or "idle"]
	local frame = new("Frame",{
		Size=UDim2.fromOffset(70,22),
		BackgroundColor3=s.bg,
		BorderSizePixel=0,
	},parent)
	corner(frame,6)
	pad(frame,0,0,8,8)
	local inner = new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},frame)
	listLayout(inner,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Center,5)
	local dot = new("Frame",{
		Size=UDim2.fromOffset(5,5),
		BackgroundColor3=s.dot,
		BorderSizePixel=0,
		LayoutOrder=0,
	},inner)
	corner(dot,3)
	new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1,LayoutOrder=-1},inner)
	local lbl = new("TextLabel",{
		Text=s.text,
		Font=Enum.Font.GothamBold,
		TextSize=9,
		TextColor3=s.tc,
		BackgroundTransparency=1,
		Size=UDim2.new(0,0,1,0),
		AutomaticSize=Enum.AutomaticSize.X,
		LayoutOrder=1,
	},inner)
	local badge={Frame=frame,Label=lbl,Dot=dot,_sp=sp}
	function badge:SetState(ns)
		local p=self._sp[ns]; if not p then return end
		tw(self.Frame,.15,{BackgroundColor3=p.bg})
		tw(self.Dot,.15,{BackgroundColor3=p.dot})
		self.Label.Text=p.text; self.Label.TextColor3=p.tc
	end
	return badge
end

function Lib:ShowNotification(msg, style, duration)
	local colors={info=C.Blue,success=C.Green,warning=C.Yellow,error=C.Red}
	local dotC = colors[style or "info"] or C.Blue
	self._notifText.Text = msg or ""
	self._notifDot.BackgroundColor3 = dotC
	tw(self._notifFrame,.28,{Position=UDim2.new(.5,0,1,-16)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
	task.delay(duration or 3.5,function()
		tw(self._notifFrame,.22,{Position=UDim2.new(.5,0,1,70)})
	end)
end

function Lib:ToggleVisibility()
	local win=self.Window
	if not win then return end
	if win.Visible and win.BackgroundTransparency<.5 then
		tw(win,.18,{BackgroundTransparency=1})
		task.delay(.2,function() if win and win.Parent then win.Visible=false end end)
	else
		win.Visible=true; win.BackgroundTransparency=1
		tw(win,.18,{BackgroundTransparency=0})
	end
end

function Lib:SetVisible(v)
	if self.Window then self.Window.Visible=v end
	if v and self.Window then self.Window.BackgroundTransparency=0 end
end

function Lib:Destroy()
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	if self._sg and self._sg.Parent then pcall(function() self._sg:Destroy() end) end
end

return Lib
