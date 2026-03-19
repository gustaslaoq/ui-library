local SlaoqUILib = {}
SlaoqUILib.__index = SlaoqUILib

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService      = game:GetService("GuiService")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

local DefaultConfig = {
    AppName       = "MY APP",
    AppSubtitle   = "Subtitle here",
    AppVersion    = "1.0",
    LogoImage     = "",
    WindowWidth   = 820,
    WindowHeight  = 540,
    SidebarWidth  = 180,

    Pages = {
        { Icon = "",  Name = "Dashboard"     },
        { Icon = "",  Name = "Settings"      },
        { Icon = "",  Name = "Logs"          },
        { Icon = "",  Name = "History"       },
    },

    Colors = {
        Bg          = Color3.fromHex("000000"),
        Surface     = Color3.fromHex("080808"),
        Card        = Color3.fromHex("101010"),
        Card2       = Color3.fromHex("0c0c0c"),
        Border      = Color3.fromHex("1c1c1c"),
        Border2     = Color3.fromHex("252525"),
        Text        = Color3.fromHex("d8d8d8"),
        Muted       = Color3.fromHex("999999"),
        Dim         = Color3.fromHex("666666"),
        White       = Color3.fromHex("ffffff"),
        Green       = Color3.fromHex("00ff88"),
        Green2      = Color3.fromHex("00cc66"),
        Red         = Color3.fromHex("c0392b"),
        Red2        = Color3.fromHex("e74c3c"),
        Yellow      = Color3.fromHex("ffcc00"),
        Orange      = Color3.fromHex("ff8800"),
        Purple      = Color3.fromHex("aa66ff"),
        Primary     = Color3.fromHex("ffffff"), -- main accent (buttons, active)
    },

    Font            = Enum.Font.GothamBold,
    FontRegular     = Enum.Font.Gotham,

    -- Tweens
    TweenSpeed      = 0.18, 
    BarTweenSpeed   = 0.22, 

    MobileBreakpoint = 600,
}

local function Lerp(a, b, t) return a + (b - a) * t end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        if child then child.Parent = obj end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, time, props, easingStyle, easingDirection)
    local info = TweenInfo.new(
        time or 0.18,
        easingStyle or Enum.EasingStyle.Quint,
        easingDirection or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function WithStroke(parent, color, thickness, transparency)
    local stroke = Create("UIStroke", {
        Color        = color or Color3.fromHex("1c1c1c"),
        Thickness    = thickness or 1,
        Transparency = transparency or 0,
        Parent       = parent,
    })
    return stroke
end

local function WithCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent       = parent,
    })
end

local function WithPadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 10),
        PaddingRight  = UDim.new(0, right  or 10),
        Parent        = parent,
    })
end

local function GetScale()
    local vp = workspace.CurrentCamera.ViewportSize
    return math.min(vp.X / 1920, vp.Y / 1080)
end

function SlaoqUILib.new(userConfig)
    local self = setmetatable({}, SlaoqUILib)

    self.Config = {}
    for k, v in pairs(DefaultConfig) do self.Config[k] = v end
    if userConfig then
        for k, v in pairs(userConfig) do
            if k == "Colors" then
                for ck, cv in pairs(v) do self.Config.Colors[ck] = cv end
            elseif k == "Pages" then
                self.Config.Pages = v
            else
                self.Config[k] = v
            end
        end
    end

    local C = self.Config.Colors
    local cfg = self.Config

    self._pages        = {}   
    self._pageIndex    = 1
    self._navButtons   = {}
    self._connections  = {}
    self._logLines     = {}
    self._logConsoles  = {}   
    self._notifQueue   = {}

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Create("ScreenGui", {
        Name              = cfg.AppName .. "_UI",
        ResetOnSpawn      = false,
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset    = true,
        Parent            = playerGui,
    })
    self.ScreenGui = screenGui

    local win = Create("Frame", {
        Name              = "Window",
        AnchorPoint       = Vector2.new(0.5, 0.5),
        Position          = UDim2.fromScale(0.5, 0.5),
        Size              = UDim2.fromOffset(cfg.WindowWidth, cfg.WindowHeight),
        BackgroundColor3  = C.Bg,
        BorderSizePixel   = 0,
        ClipsDescendants  = true,
        Parent            = screenGui,
    })
    WithCorner(win, 12)
    WithStroke(win, C.Border2, 1)
    self.Window = win

    -- Auto-scale window on viewport change
    local function updateScale()
        local vp = workspace.CurrentCamera.ViewportSize
        local isMobile = vp.X < cfg.MobileBreakpoint or
                         UserInputService.TouchEnabled
        local scaleX = math.clamp(vp.X / 1920, 0.45, 1.0)
        local scaleY = math.clamp(vp.Y / 1080, 0.45, 1.0)
        local s = math.min(scaleX, scaleY)

        local w = math.floor(cfg.WindowWidth  * s)
        local h = math.floor(cfg.WindowHeight * s)
        if isMobile then
            -- On mobile fill more of the screen
            w = math.floor(vp.X * 0.97)
            h = math.floor(vp.Y * 0.94)
        end
        win.Size = UDim2.fromOffset(w, h)

        -- Collapse sidebar on mobile
        if self._sidebar then
            local sw = isMobile and 46 or math.floor(cfg.SidebarWidth * s)
            self._sidebar.Size = UDim2.new(0, sw, 1, 0)
            self:_updateSidebarLabels(isMobile or sw < 80)
        end
    end

    table.insert(self._connections,
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

    local titleBar = Create("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Parent           = win,
    })
    Create("Frame", {  -- bottom border
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        Parent           = titleBar,
    })
    self.TitleBar = titleBar

    -- App name label
    local titleName = Create("TextLabel", {
        Text             = cfg.AppName,
        Font             = cfg.Font,
        TextSize         = 11,
        TextColor3       = C.White,
        BackgroundTransparency = 1,
        Position         = UDim2.fromOffset(12, 6),
        Size             = UDim2.new(0.6, 0, 0, 14),
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 11,
        Parent           = titleBar,
    })
    self.TitleNameLabel = titleName

    local titleVersion = Create("TextLabel", {
        Text             = "v" .. cfg.AppVersion,
        Font             = cfg.FontRegular,
        TextSize         = 9,
        TextColor3       = C.Dim,
        BackgroundTransparency = 1,
        Position         = UDim2.fromOffset(12, 21),
        Size             = UDim2.new(0.6, 0, 0, 12),
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 11,
        Parent           = titleBar,
    })
    self.TitleVersionLabel = titleVersion

    -- Close button
    local closeBtn = Create("TextButton", {
        Text             = "✕",
        Font             = cfg.FontRegular,
        TextSize         = 13,
        TextColor3       = C.Muted,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -4, 0.5, 0),
        Size             = UDim2.fromOffset(36, 36),
        ZIndex           = 11,
        Parent           = titleBar,
    })
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.12, { TextColor3 = C.Red2 })
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.12, { TextColor3 = C.Muted })
    end)
    closeBtn.Activated:Connect(function()
        self:Destroy()
    end)
    self.CloseButton = closeBtn

    -- Minimize button
    local minBtn = Create("TextButton", {
        Text             = "–",
        Font             = cfg.FontRegular,
        TextSize         = 16,
        TextColor3       = C.Muted,
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -40, 0.5, 0),
        Size             = UDim2.fromOffset(36, 36),
        ZIndex           = 11,
        Parent           = titleBar,
    })
    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, 0.12, { TextColor3 = C.White })
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, 0.12, { TextColor3 = C.Muted })
    end)
    minBtn.Activated:Connect(function()
        self:ToggleVisibility()
    end)
    self.MinButton = minBtn

    -- Title bar drag
    do
        local dragging = false
        local dragStart, startPos

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = input.Position
                startPos  = win.Position
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        table.insert(self._connections,
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement or
                    input.UserInputType == Enum.UserInputType.Touch)
                then
                    local delta = input.Position - dragStart
                    win.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        )
    end

    local body = Create("Frame", {
        Name             = "Body",
        Position         = UDim2.fromOffset(0, 36),
        Size             = UDim2.new(1, 0, 1, -36),
        BackgroundTransparency = 1,
        Parent           = win,
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
    -- right border
    Create("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = sidebar,
    })
    self._sidebar = sidebar

    -- Sidebar scroll container
    local sidebarScroll = Create("ScrollingFrame", {
        Name                   = "SidebarScroll",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 0,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Parent                 = sidebar,
    })
    local sidebarLayout = Create("UIListLayout", {
        SortOrder         = Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, 0),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent            = sidebarScroll,
    })
    WithPadding(sidebarScroll, 12, 12, 6, 6)

    -- Logo area
    local logoFrame = Create("Frame", {
        Name             = "LogoFrame",
        Size             = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        LayoutOrder      = 0,
        Parent           = sidebarScroll,
    })

    local logoImg = Create("ImageLabel", {
        Name             = "Logo",
        AnchorPoint      = Vector2.new(0.5, 0),
        Position         = UDim2.new(0.5, 0, 0, 4),
        Size             = UDim2.fromOffset(44, 44),
        BackgroundTransparency = 1,
        Image            = cfg.LogoImage ~= "" and cfg.LogoImage or "",
        Parent           = logoFrame,
    })
    -- fallback circle if no logo
    if cfg.LogoImage == "" then
        logoImg.BackgroundColor3 = Color3.fromHex("000000")
        logoImg.BackgroundTransparency = 0
        WithCorner(logoImg, 22)
        WithStroke(logoImg, C.Border2, 1.5)
        Create("TextLabel", {
            Text      = string.sub(cfg.AppName, 1, 1),
            Font      = cfg.Font,
            TextSize  = 20,
            TextColor3 = C.White,
            BackgroundTransparency = 1,
            Size      = UDim2.fromScale(1, 1),
            Parent    = logoImg,
        })
    end
    self.LogoImage = logoImg

    local appNameLbl = Create("TextLabel", {
        Name             = "AppNameSidebar",
        Text             = cfg.AppName,
        Font             = cfg.Font,
        TextSize         = 10,
        TextColor3       = C.White,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, 52),
        Size             = UDim2.new(1, 0, 0, 14),
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 6,
        Parent           = logoFrame,
    })
    local appSubLbl = Create("TextLabel", {
        Name             = "AppSubSidebar",
        Text             = cfg.AppSubtitle,
        Font             = cfg.FontRegular,
        TextSize          = 9,
        TextColor3        = C.Muted,
        BackgroundTransparency = 1,
        Position          = UDim2.new(0, 0, 0, 67),
        Size              = UDim2.new(1, 0, 0, 12),
        TextXAlignment    = Enum.TextXAlignment.Center,
        ZIndex            = 6,
        Parent            = logoFrame,
    })
    self._sidebarNameLabel = appNameLbl
    self._sidebarSubLabel  = appSubLbl

    -- Divider
    Create("Frame", {
        Name             = "Divider",
        Size             = UDim2.new(0.85, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        LayoutOrder      = 1,
        Parent           = sidebarScroll,
    })
    Create("Frame", { Size = UDim2.fromOffset(1, 8), BackgroundTransparency=1, LayoutOrder=2, Parent=sidebarScroll })

    -- Active bar indicator
    local barIndicator = Create("Frame", {
        Name             = "BarIndicator",
        Size             = UDim2.fromOffset(3, 28),
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.fromOffset(2, 0),
        BackgroundColor3 = C.White,
        BorderSizePixel  = 0,
        ZIndex           = 8,
        Visible          = false,
        Parent           = sidebar,
    })
    WithCorner(barIndicator, 3)
    self._barIndicator = barIndicator

    -- Nav buttons
    for i, page in ipairs(cfg.Pages) do
        local btn = self:_createNavButton(page, i, sidebarScroll)
        table.insert(self._navButtons, btn)
    end

    Create("Frame", { Size = UDim2.fromOffset(1, 8), BackgroundTransparency=1,
        LayoutOrder = #cfg.Pages + 10, Parent=sidebarScroll })

    local contentArea = Create("Frame", {
        Name             = "ContentArea",
        Position         = UDim2.new(0, cfg.SidebarWidth, 0, 0),
        Size             = UDim2.new(1, -cfg.SidebarWidth, 1, 0),
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = body,
    })
    self._contentArea = contentArea

    -- Update content area position when sidebar resizes
    table.insert(self._connections,
        sidebar:GetPropertyChangedSignal("Size"):Connect(function()
            contentArea.Position = UDim2.new(0, sidebar.Size.X.Offset, 0, 0)
            contentArea.Size     = UDim2.new(1, -sidebar.Size.X.Offset, 1, 0)
        end)
    )

    local notifFrame = Create("Frame", {
        Name             = "NotifToast",
        AnchorPoint      = Vector2.new(0.5, 1),
        Position         = UDim2.new(0.5, 0, 1, 60),
        Size             = UDim2.fromOffset(320, 44),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        ZIndex           = 100,
        Visible          = true,
        Parent           = win,
    })
    WithCorner(notifFrame, 8)
    WithStroke(notifFrame, C.Border2, 1)
    local notifText = Create("TextLabel", {
        Text             = "",
        Font             = cfg.FontRegular,
        TextSize         = 11,
        TextColor3       = C.Text,
        BackgroundTransparency = 1,
        Size             = UDim2.fromScale(1, 1),
        TextXAlignment   = Enum.TextXAlignment.Center,
        TextWrapped      = true,
        ZIndex           = 101,
        Parent           = notifFrame,
    })
    WithPadding(notifFrame, 6, 6, 12, 12)
    self._notifFrame = notifFrame
    self._notifText  = notifText
    self._notifActive = false

    -- Initialize pages
    self:_initPages()

    -- Select first page
    self:SetPage(1)

    -- Apply initial scale
    updateScale()

    return self
end

function SlaoqUILib:_createNavButton(page, index, parent)
    local C   = self.Config.Colors
    local cfg = self.Config

    local btnFrame = Create("Frame", {
        Name             = "NavBtn_" .. index,
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        LayoutOrder      = index + 2,
        Parent           = parent,
    })

    -- Hover background
    local hoverBg = Create("Frame", {
        Name             = "HoverBg",
        Size             = UDim2.new(1, -8, 1, -4),
        Position         = UDim2.fromOffset(4, 2),
        BackgroundColor3 = C.White,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = btnFrame,
    })
    WithCorner(hoverBg, 6)

    local hasIcon = page.Icon and page.Icon ~= ""

    -- Icon (if provided)
    if hasIcon then
        Create("ImageLabel", {
            Name             = "NavIcon",
            Size             = UDim2.fromOffset(16, 16),
            Position         = UDim2.fromOffset(10, 9),
            BackgroundTransparency = 1,
            Image            = page.Icon,
            ZIndex           = 6,
            Parent           = btnFrame,
        })
    else
        -- dot fallback
        Create("Frame", {
            Name             = "NavDot",
            Size             = UDim2.fromOffset(5, 5),
            Position         = UDim2.fromOffset(12, 15),
            BackgroundColor3 = C.Dim,
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = btnFrame,
        })
    end

    local labelX = hasIcon and 32 or 24
    local textLabel = Create("TextLabel", {
        Name             = "NavLabel",
        Text             = page.Name,
        Font             = cfg.Font,
        TextSize         = 11,
        TextColor3       = C.Muted,
        BackgroundTransparency = 1,
        Position         = UDim2.fromOffset(labelX, 0),
        Size             = UDim2.new(1, -labelX - 8, 1, 0),
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 6,
        Parent           = btnFrame,
    })

    -- Button click detector
    local clickBtn = Create("TextButton", {
        Text             = "",
        BackgroundTransparency = 1,
        Size             = UDim2.fromScale(1, 1),
        ZIndex           = 7,
        Parent           = btnFrame,
    })

    -- Hover effects
    clickBtn.MouseEnter:Connect(function()
        if self._pageIndex ~= index then
            Tween(hoverBg, 0.12, { BackgroundTransparency = 0.95 })
            Tween(textLabel, 0.12, { TextColor3 = C.Text })
        end
    end)
    clickBtn.MouseLeave:Connect(function()
        if self._pageIndex ~= index then
            Tween(hoverBg, 0.12, { BackgroundTransparency = 1 })
            Tween(textLabel, 0.12, { TextColor3 = C.Muted })
        end
    end)
    clickBtn.Activated:Connect(function()
        self:SetPage(index)
    end)

    return {
        Frame      = btnFrame,
        HoverBg    = hoverBg,
        TextLabel  = textLabel,
        ClickBtn   = clickBtn,
    }
end

function SlaoqUILib:_initPages()
    for i, _ in ipairs(self.Config.Pages) do
        local pageFrame = Create("Frame", {
            Name             = "Page_" .. i,
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible          = false,
            Parent           = self._contentArea,
        })
        local scroll = Create("ScrollingFrame", {
            Name                = "PageScroll",
            Size                = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness  = 3,
            ScrollBarImageColor3 = self.Config.Colors.Border2,
            CanvasSize          = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent              = pageFrame,
        })
        local layout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 0),
            Parent    = scroll,
        })
        WithPadding(scroll, 20, 20, 22, 22)

        table.insert(self._pages, {
            Frame  = pageFrame,
            Scroll = scroll,
            Layout = layout,
        })
    end
end

function SlaoqUILib:GetPage(index)
    return self._pages[index] and self._pages[index].Scroll or nil
end

function SlaoqUILib:SetPage(index)
    local cfg = self.Config
    local C   = cfg.Colors

    if self._pages[self._pageIndex] then
        self._pages[self._pageIndex].Frame.Visible = false
    end
    local oldBtn = self._navButtons[self._pageIndex]
    if oldBtn then
        Tween(oldBtn.TextLabel, cfg.TweenSpeed, { TextColor3 = C.Muted })
        Tween(oldBtn.HoverBg,   cfg.TweenSpeed, { BackgroundTransparency = 1 })
    end

    self._pageIndex = index

    if self._pages[index] then
        self._pages[index].Frame.Visible = true
    end

    local newBtn = self._navButtons[index]
    if newBtn then
        Tween(newBtn.TextLabel, cfg.TweenSpeed, { TextColor3 = C.White })
        Tween(newBtn.HoverBg,   cfg.TweenSpeed, { BackgroundTransparency = 0.93 })
        self:_animateBarTo(newBtn.Frame)
    end
end

function SlaoqUILib:_animateBarTo(targetFrame)
    local bar = self._barIndicator
    if not bar then return end

    local targetAbsPos = targetFrame.AbsolutePosition
    local sidebarAbsPos = self._sidebar.AbsolutePosition
    local relY = targetAbsPos.Y - sidebarAbsPos.Y + targetFrame.AbsoluteSize.Y * 0.5

    bar.Visible = true

    local cfg = self.Config
    Tween(bar, cfg.BarTweenSpeed * 0.5, { Size = UDim2.fromOffset(3, 0) },
        Enum.EasingStyle.Quint, Enum.EasingDirection.In):Completed:Connect(function()
        bar.Position = UDim2.new(0, 2, 0, relY)
        Tween(bar, cfg.BarTweenSpeed * 0.6, { Size = UDim2.fromOffset(3, 28) },
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

function SlaoqUILib:_updateSidebarLabels(collapsed)
    local C = self.Config.Colors
    if self._sidebarNameLabel then
        self._sidebarNameLabel.Visible = not collapsed
    end
    if self._sidebarSubLabel then
        self._sidebarSubLabel.Visible  = not collapsed
    end
    for _, nb in ipairs(self._navButtons) do
        nb.TextLabel.Visible = not collapsed
    end
end

function SlaoqUILib:AddSectionHeader(pageIndex, title, subtitle)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C = self.Config.Colors

    local frame = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, subtitle and 44 or 28),
        BackgroundTransparency = 1,
        LayoutOrder      = self:_nextOrder(pageIndex),
        Parent           = scroll,
    })
    Create("TextLabel", {
        Text             = title,
        Font             = self.Config.Font,
        TextSize         = 18,
        TextColor3       = C.White,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 22),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = frame,
    })
    if subtitle then
        Create("TextLabel", {
            Text             = subtitle,
            Font             = self.Config.FontRegular,
            TextSize         = 11,
            TextColor3       = C.Muted,
            BackgroundTransparency = 1,
            Position         = UDim2.fromOffset(0, 22),
            Size             = UDim2.new(1, 0, 0, 16),
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = frame,
        })
    end
    -- Divider
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        LayoutOrder      = self:_nextOrder(pageIndex),
        Parent           = scroll,
    })
    Create("Frame", { Size=UDim2.fromOffset(1,10), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })
end

function SlaoqUILib:AddMetricRow(pageIndex, cards)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local row = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundTransparency = 1,
        LayoutOrder      = self:_nextOrder(pageIndex),
        Parent           = scroll,
    })
    local gridLayout = Create("UIGridLayout", {
        CellSize         = UDim2.new(1 / #cards, -6, 1, 0),
        CellPaddingHorizontal = UDim.new(0, 6),
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Parent           = row,
    })

    local cardObjects = {}

    for i, card in ipairs(cards) do
        local cardFrame = Create("Frame", {
            Name             = "MetricCard_" .. i,
            BackgroundColor3 = C.Card,
            BorderSizePixel  = 0,
            ZIndex           = 2,
            LayoutOrder      = i,
            Parent           = row,
        })
        WithCorner(cardFrame, 10)
        WithStroke(cardFrame, C.Border, 1)
        WithPadding(cardFrame, 10, 10, 14, 14)

        local labelLbl = Create("TextLabel", {
            Text             = card.Label,
            Font             = cfg.Font,
            TextSize         = 9,
            TextColor3       = C.Muted,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 13),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 3,
            Parent           = cardFrame,
        })
        local valueLbl = Create("TextLabel", {
            Text             = card.Value or "—",
            Font             = cfg.Font,
            TextSize         = 22,
            TextColor3       = C.White,
            BackgroundTransparency = 1,
            Position         = UDim2.fromOffset(0, 15),
            Size             = UDim2.new(1, 0, 0, 28),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 3,
            Parent           = cardFrame,
        })
        if card.Unit and card.Unit ~= "" then
            Create("TextLabel", {
                Text     = card.Unit,
                Font     = cfg.FontRegular,
                TextSize = 10,
                TextColor3 = C.Dim,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 44),
                Size     = UDim2.new(1, 0, 0, 12),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex   = 3,
                Parent   = cardFrame,
            })
        end

        local ib = Create("TextButton", {
            Text="", BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=4, Parent=cardFrame })
        ib.MouseEnter:Connect(function()
            Tween(cardFrame, 0.12, { BackgroundColor3 = C.Card2 })
        end)
        ib.MouseLeave:Connect(function()
            Tween(cardFrame, 0.12, { BackgroundColor3 = C.Card })
        end)

        table.insert(cardObjects, { Frame = cardFrame, ValueLabel = valueLbl, Label = labelLbl })
    end

    Create("Frame", { Size=UDim2.fromOffset(1,10), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    return cardObjects  -- caller can store references to update values
end

-- Update a metric card value
function SlaoqUILib:SetMetricValue(cardObj, value)
    if cardObj and cardObj.ValueLabel then
        cardObj.ValueLabel.Text = tostring(value)
    end
end

function SlaoqUILib:CreateStatusBadge(parent, state)
    local C   = self.Config.Colors
    local cfg = self.Config

    local stateProps = {
        on   = { text = "ON",   bg = Color3.fromRGB(0,204,102),  bgA = 0.90, textColor = C.Green2,  border = Color3.fromRGB(0,204,102)  },
        off  = { text = "OFF",  bg = Color3.fromRGB(255,68,68),  bgA = 0.90, textColor = C.Red2,    border = Color3.fromRGB(255,68,68)  },
        idle = { text = "IDLE", bg = Color3.fromRGB(255,204,0),  bgA = 0.93, textColor = C.Yellow,  border = Color3.fromRGB(255,204,0)  },
    }

    local s = stateProps[state or "idle"]

    local frame = Create("Frame", {
        Name             = "StatusBadge",
        Size             = UDim2.fromOffset(52, 20),
        BackgroundColor3 = s.bg,
        BackgroundTransparency = s.bgA,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    WithCorner(frame, 9)
    WithStroke(frame, s.border, 1, 0.75)

    local lbl = Create("TextLabel", {
        Text     = s.text,
        Font     = cfg.Font,
        TextSize = 9,
        TextColor3 = s.textColor,
        BackgroundTransparency = 1,
        Size     = UDim2.fromScale(1, 1),
        ZIndex   = 2,
        Parent   = frame,
    })

    local badge = { Frame = frame, Label = lbl, _stateProps = stateProps }

    function badge:SetState(newState)
        local sp = self._stateProps[newState]
        if not sp then return end
        Tween(self.Frame, 0.15, {
            BackgroundColor3       = sp.bg,
            BackgroundTransparency = sp.bgA,
        })
        self.Label.Text      = sp.text
        self.Label.TextColor3 = sp.textColor
    end

    return badge
end

function SlaoqUILib:AddButton(pageIndex, text, style, callback)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local styles = {
        primary = { bg=C.White,    textColor=C.Bg,    hoverBg=Color3.fromRGB(220,220,220) },
        danger  = { bg=C.Red,      textColor=C.White, hoverBg=C.Red2                       },
        warning = { bg=C.Yellow,   textColor=C.Bg,    hoverBg=C.Orange                     },
        ghost   = { bg=C.Card,     textColor=C.Text,  hoverBg=C.Card2                      },
    }
    local s = styles[style or "primary"]

    local btn = Create("TextButton", {
        Name             = "Btn_" .. text,
        Text             = text,
        Font             = cfg.Font,
        TextSize         = 12,
        TextColor3       = s.textColor,
        BackgroundColor3 = s.bg,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 140, 0, 38),
        LayoutOrder      = self:_nextOrder(pageIndex),
        AutoButtonColor  = false,
        Parent           = scroll,
    })
    WithCorner(btn, 8)

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.12, { BackgroundColor3 = s.hoverBg })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.12, { BackgroundColor3 = s.bg })
    end)
    btn.Activated:Connect(function()
        if callback then callback() end
    end)

    Create("Frame", { Size=UDim2.fromOffset(1,8), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    return btn
end

function SlaoqUILib:AddButtonRow(pageIndex, buttonDefs)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(pageIndex),
        Parent = scroll,
    })
    local listLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 8),
        Parent        = row,
    })

    local styles = {
        primary = { bg=C.White, textColor=C.Bg, hoverBg=Color3.fromRGB(220,220,220) },
        danger  = { bg=C.Red,   textColor=C.White, hoverBg=C.Red2 },
        warning = { bg=C.Yellow,textColor=C.Bg, hoverBg=C.Orange },
        ghost   = { bg=C.Card,  textColor=C.Text, hoverBg=C.Card2 },
    }

    local btns = {}
    for i, def in ipairs(buttonDefs) do
        local s = styles[def.Style or "primary"]
        local btn = Create("TextButton", {
            Text             = def.Text,
            Font             = cfg.Font,
            TextSize         = 12,
            TextColor3       = s.textColor,
            BackgroundColor3 = s.bg,
            BorderSizePixel  = 0,
            Size             = UDim2.fromOffset(def.Width or 140, 38),
            AutoButtonColor  = false,
            LayoutOrder      = i,
            Parent           = row,
        })
        WithCorner(btn, 8)
        btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = s.hoverBg }) end)
        btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = s.bg }) end)
        if def.Callback then
            btn.Activated:Connect(def.Callback)
        end
        table.insert(btns, btn)
    end

    Create("Frame", { Size=UDim2.fromOffset(1,10), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    return btns
end

function SlaoqUILib:AddToggle(pageIndex, label, default, callback)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local row = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder      = self:_nextOrder(pageIndex),
        Parent           = scroll,
    })
    Create("TextLabel", {
        Text     = label,
        Font     = cfg.FontRegular,
        TextSize = 12,
        TextColor3 = C.Text,
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, -56, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent   = row,
    })

    local state = default == true

    -- Track
    local track = Create("Frame", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, 0, 0.5, 0),
        Size             = UDim2.fromOffset(36, 20),
        BackgroundColor3 = state and C.White or C.Card,
        BorderSizePixel  = 0,
        Parent           = row,
    })
    WithCorner(track, 10)
    WithStroke(track, C.Border2, 1)

    -- Knob
    local knob = Create("Frame", {
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = state and UDim2.fromOffset(18, 10) or UDim2.fromOffset(2, 10),
        Size             = UDim2.fromOffset(16, 16),
        BackgroundColor3 = state and C.Bg or C.Muted,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    WithCorner(knob, 8)

    local clickBtn = Create("TextButton", {
        Text="", BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=5, Parent=track
    })
    clickBtn.Activated:Connect(function()
        state = not state
        Tween(track, 0.15, { BackgroundColor3 = state and C.White or C.Card })
        Tween(knob,  0.15, {
            Position         = state and UDim2.fromOffset(18, 10) or UDim2.fromOffset(2, 10),
            BackgroundColor3 = state and C.Bg or C.Muted,
        })
        if callback then callback(state) end
    end)

    Create("Frame", { Size=UDim2.fromOffset(1,6), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    local toggle = { Track = track, Knob = knob, State = state }
    function toggle:SetState(v)
        state = v
        self.State = v
        Tween(self.Track, 0.15, { BackgroundColor3 = v and C.White or C.Card })
        Tween(self.Knob,  0.15, {
            Position         = v and UDim2.fromOffset(18, 10) or UDim2.fromOffset(2, 10),
            BackgroundColor3 = v and C.Bg or C.Muted,
        })
    end
    return toggle
end

function SlaoqUILib:AddInput(pageIndex, labelText, placeholder, callback)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    if labelText then
        Create("TextLabel", {
            Text     = labelText,
            Font     = cfg.FontRegular,
            TextSize = 11,
            TextColor3 = C.Muted,
            BackgroundTransparency = 1,
            Size     = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = self:_nextOrder(pageIndex),
            Parent   = scroll,
        })
    end

    local inputBox = Create("TextBox", {
        Text             = "",
        PlaceholderText  = placeholder or "",
        Font             = cfg.FontRegular,
        TextSize         = 12,
        TextColor3       = C.Text,
        PlaceholderColor3 = C.Dim,
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 36),
        LayoutOrder      = self:_nextOrder(pageIndex),
        ClearTextOnFocus = false,
        Parent           = scroll,
    })
    WithCorner(inputBox, 6)
    WithStroke(inputBox, C.Border2, 1)
    WithPadding(inputBox, 0, 0, 12, 12)

    inputBox.Focused:Connect(function()
        Tween(inputBox, 0.12, { BackgroundColor3 = C.Card2 })
    end)
    inputBox.FocusLost:Connect(function(enterPressed)
        Tween(inputBox, 0.12, { BackgroundColor3 = C.Card })
        if callback then callback(inputBox.Text, enterPressed) end
    end)

    Create("Frame", { Size=UDim2.fromOffset(1,8), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    return inputBox
end

function SlaoqUILib:AddCard(pageIndex, title)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local card = Create("Frame", {
        Name             = "Card",
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = self:_nextOrder(pageIndex),
        Parent           = scroll,
    })
    WithCorner(card, 10)
    WithStroke(card, C.Border, 1)

    local inner = Create("Frame", {
        Name             = "CardInner",
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent           = card,
    })
    WithPadding(inner, 14, 14, 16, 16)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
        Parent    = inner,
    })

    if title then
        Create("TextLabel", {
            Text     = string.upper(title),
            Font     = cfg.Font,
            TextSize = 9,
            TextColor3 = C.Muted,
            BackgroundTransparency = 1,
            Size     = UDim2.new(1, 0, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = -1,
            Parent   = inner,
        })
    end

    Create("Frame", { Size=UDim2.fromOffset(1,10), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    return inner 
end

function SlaoqUILib:AddLogConsole(pageIndex, height)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local consoleFrame = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, height or 180),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = self:_nextOrder(pageIndex),
        ClipsDescendants = true,
        Parent           = scroll,
    })
    WithCorner(consoleFrame, 8)
    WithStroke(consoleFrame, C.Border2, 1)

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
        Parent           = consoleFrame,
    })
    WithPadding(textBox, 8, 8, 10, 10)

    Create("Frame", { Size=UDim2.fromOffset(1,10), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    local console = { Frame = consoleFrame, TextBox = textBox, _lines = {} }

    local levelColors = {
        INFO    = "<font color=\"#999999\">",
        SUCCESS = "<font color=\"#00ff88\">",
        WARN    = "<font color=\"#ffcc00\">",
        ERROR   = "<font color=\"#e74c3c\">",
        DEBUG   = "<font color=\"#aa66ff\">",
        SNIPE   = "<font color=\"#ffffff\">",
    }

    function console:Log(message, level)
        level = level or "INFO"
        local colorOpen  = levelColors[level] or levelColors.INFO
        local colorClose = "</font>"
        local timestamp  = os.date("%H:%M:%S")
        local line = string.format(
            "<font color=\"#444444\">[%s]</font> %s%s%s",
            timestamp, colorOpen, message, colorClose
        )
        table.insert(self._lines, line)
        if #self._lines > 200 then
            table.remove(self._lines, 1)
        end
        self.TextBox.Text = table.concat(self._lines, "\n")
    end

    function console:Clear()
        self._lines = {}
        self.TextBox.Text = ""
    end

    table.insert(self._logConsoles, console)
    return console
end

function SlaoqUILib:ShowNotification(message, style, duration)
    local C   = self.Config.Colors
    local cfg = self.Config

    local styleColors = {
        info    = C.Text,
        success = C.Green2,
        warning = C.Yellow,
        error   = C.Red2,
    }
    local textColor = styleColors[style or "info"] or C.Text

    self._notifText.Text       = message
    self._notifText.TextColor3 = textColor

    Tween(self._notifFrame, 0.25, {
        Position = UDim2.new(0.5, 0, 1, -14)
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(duration or 3.5, function()
        Tween(self._notifFrame, 0.22, {
            Position = UDim2.new(0.5, 0, 1, 60)
        })
    end)
end

function SlaoqUILib:AddLabel(pageIndex, text, style)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    local styles = {
        title    = { size=16, color=C.White,   font=cfg.Font        },
        subtitle = { size=13, color=C.Text,    font=cfg.Font        },
        body     = { size=12, color=C.Text,    font=cfg.FontRegular },
        muted    = { size=11, color=C.Muted,   font=cfg.FontRegular },
        caption  = { size=9,  color=C.Dim,     font=cfg.FontRegular },
    }
    local s = styles[style or "body"]

    local lbl = Create("TextLabel", {
        Text     = text,
        Font     = s.font,
        TextSize = s.size,
        TextColor3 = s.color,
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, s.size + 6),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = self:_nextOrder(pageIndex),
        Parent   = scroll,
    })
    return lbl
end

function SlaoqUILib:AddSeparator(pageIndex, spacing)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C = self.Config.Colors

    Create("Frame", { Size=UDim2.fromOffset(1, spacing or 6), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })
    Create("Frame", {
        Size     = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        LayoutOrder = self:_nextOrder(pageIndex),
        Parent   = scroll,
    })
    Create("Frame", { Size=UDim2.fromOffset(1, spacing or 6), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })
end

function SlaoqUILib:AddDropdown(pageIndex, labelText, options, callback)
    local scroll = self:GetPage(pageIndex)
    if not scroll then return end
    local C   = self.Config.Colors
    local cfg = self.Config

    if labelText then
        Create("TextLabel", {
            Text     = labelText,
            Font     = cfg.FontRegular,
            TextSize = 11,
            TextColor3 = C.Muted,
            BackgroundTransparency = 1,
            Size     = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = self:_nextOrder(pageIndex),
            Parent   = scroll,
        })
    end

    local selected = options[1] or ""
    local open     = false

    local container = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(pageIndex),
        Parent = scroll,
    })

    local dropBtn = Create("TextButton", {
        Text     = selected .. "  ▾",
        Font     = cfg.FontRegular,
        TextSize = 12,
        TextColor3 = C.Text,
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        Size     = UDim2.new(1, 0, 0, 36),
        AutoButtonColor = false,
        Parent   = container,
    })
    WithCorner(dropBtn, 6)
    WithStroke(dropBtn, C.Border2, 1)
    WithPadding(dropBtn, 0, 0, 12, 12)

    local optionList = Create("Frame", {
        Name     = "DropdownList",
        Position = UDim2.fromOffset(0, 38),
        Size     = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Card2,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex   = 20,
        Visible  = false,
        Parent   = container,
    })
    WithCorner(optionList, 6)
    WithStroke(optionList, C.Border2, 1)

    local listLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
        Parent    = optionList,
    })

    for i, opt in ipairs(options) do
        local optBtn = Create("TextButton", {
            Text     = opt,
            Font     = cfg.FontRegular,
            TextSize = 12,
            TextColor3 = C.Text,
            BackgroundColor3 = C.Card2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size     = UDim2.new(1, 0, 0, 32),
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent   = optionList,
        })
        WithPadding(optBtn, 0, 0, 12, 12)
        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, 0.1, { BackgroundTransparency = 0.85 })
        end)
        optBtn.MouseLeave:Connect(function()
            Tween(optBtn, 0.1, { BackgroundTransparency = 1 })
        end)
        optBtn.Activated:Connect(function()
            selected = opt
            dropBtn.Text = opt .. "  ▾"
            open = false
            Tween(optionList, 0.15, { Size = UDim2.new(1, 0, 0, 0) })
            task.delay(0.15, function() optionList.Visible = false end)
            if callback then callback(opt) end
        end)
    end

    local listHeight = #options * 32

    dropBtn.Activated:Connect(function()
        open = not open
        optionList.Visible = true
        if open then
            Tween(optionList, 0.18, { Size = UDim2.new(1, 0, 0, listHeight) },
                Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Tween(optionList, 0.15, { Size = UDim2.new(1, 0, 0, 0) })
            task.delay(0.15, function() optionList.Visible = false end)
        end
    end)

    Create("Frame", { Size=UDim2.fromOffset(1,8), BackgroundTransparency=1,
        LayoutOrder=self:_nextOrder(pageIndex), Parent=scroll })

    return { Button = dropBtn, List = optionList,
             GetSelected = function() return selected end }
end

local _orderCounters = {}
function SlaoqUILib:_nextOrder(pageIndex)
    _orderCounters[pageIndex] = (_orderCounters[pageIndex] or 100) + 1
    return _orderCounters[pageIndex]
end

function SlaoqUILib:ToggleVisibility()
    local win = self.Window
    local targetA = win.BackgroundTransparency > 0.5 and 0 or 1
    Tween(win, 0.2, { BackgroundTransparency = targetA })
    for _, desc in ipairs(win:GetDescendants()) do
        if desc:IsA("Frame") or desc:IsA("TextLabel") or desc:IsA("TextButton") then
        end
    end
    win.Visible = true
    if targetA == 1 then
        task.delay(0.2, function() win.Visible = false end)
    end
end

function SlaoqUILib:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function SlaoqUILib:GetPageFrame(index)
    if self._pages[index] then
        return self._pages[index].Scroll
    end
end

function SlaoqUILib:GetRawPage(index)
    if self._pages[index] then
        return self._pages[index].Frame
    end
end
return SlaoqUILib
