# SlaoqUILib

A lightweight, modular, dark-themed UI library for Roblox scripts. Drop it in, configure it with a single table, and build rich multi-page interfaces using a clean component API — no manual GUI work required.

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Window Controls](#window-controls)
- [Pages & Navigation](#pages--navigation)
- [Notifications & Dialogs](#notifications--dialogs)
- [Components](#components)
  - [AddSectionHeader](#addsectionheader)
  - [AddDivider](#adddivider)
  - [AddSeparator](#addseparator)
  - [AddLabel](#addlabel)
  - [AddRichLabel](#addrichlabel)
  - [AddParagraph](#addparagraph)
  - [AddAlert](#addalert)
  - [AddBadge](#addbadge)
  - [AddTag](#addtag)
  - [AddButton](#addbutton)
  - [AddButtonRow](#addbuttonrow)
  - [AddToggle](#addtoggle)
  - [AddCheckbox](#addcheckbox)
  - [AddSlider](#addslider)
  - [AddStepper](#addstepper)
  - [AddInput](#addinput)
  - [AddInputNumber](#addinputnumber)
  - [AddDropdown](#adddropdown)
  - [AddRadioGroup](#addradiogroup)
  - [AddMultiSelect](#addmultiselect)
  - [AddColorPicker](#addcolorpicker)
  - [AddKeybind](#addkeybind)
  - [AddProgressBar](#addprogressbar)
  - [AddMetricRow](#addmetricrow)
  - [AddTable](#addtable)
  - [AddList](#addlist)
  - [AddCard](#addcard)
  - [AddLogConsole](#addlogconsole)
  - [AddNotificationCenter](#addnotificationcenter)
  - [AddSpinner](#addspinner)
  - [AddColorSwatch](#addcolorswatch)
  - [AddInlineImage](#addinlineimage)
  - [AddStatusBadge2](#addstatusbadge2)
- [Utility Methods](#utility-methods)
- [Platform Helpers](#platform-helpers)
- [Lifecycle & Cleanup](#lifecycle--cleanup)
- [Color System](#color-system)
- [Demo Mode](#demo-mode)

---

## Installation

Load the library at the top of your script:

```lua
local Lib = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
```

Or, if you have the file locally:

```lua
local Lib = require(path.to.library)
```

---

## Quick Start

```lua
local Lib = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

local ui = Lib.new({
    AppName     = "My Script",
    AppSubtitle = "v1",
    AppVersion  = "1.0",
    Pages = {
        { Name = "Main" },
        { Name = "Settings" },
    },
})

-- Add a toggle to page 1 (Main)
ui:AddToggle(1, "Enable Feature", false, function(value)
    print("Toggle:", value)
end)

-- Add a button to page 2 (Settings)
ui:AddButton(2, "Reset", "danger", function()
    print("Reset clicked")
end)
```

Calling `Lib.new()` with **no arguments** launches a full interactive demo showcasing every component.

---

## Configuration Reference

Pass a configuration table to `Lib.new({})`. All fields are optional and fall back to sensible defaults.

| Field | Type | Default | Description |
|---|---|---|---|
| `AppName` | string | `"MY APP"` | Title shown in the sidebar and title bar |
| `AppSubtitle` | string | `"Subtitle"` | Subtitle shown below the logo in the sidebar |
| `AppVersion` | string | `"1.0"` | Version string shown in the title bar badge |
| `LogoImage` | string | Roblox asset ID | Image used as the app logo. Set to `""` to use the first letter of `AppName` instead |
| `GuiParent` | string | `"CoreGui"` | Where the ScreenGui is parented. Use `"PlayerGui"` as an alternative |
| `WindowWidth` | number | `920` | Base width of the window in pixels |
| `WindowHeight` | number | `580` | Base height of the window in pixels |
| `SidebarWidth` | number | `210` | Width of the left navigation sidebar |
| `TweenSpeed` | number | `0.22` | Duration (seconds) of navigation transition tweens |
| `BarTweenSpeed` | number | `0.22` | Duration (seconds) of the sidebar selection bar animation |
| `MiniModeBreakpoint` | number | `700` | Viewport width (px) below which the UI switches to mobile/mini mode |
| `ToggleKey` | string | `"K"` | Keyboard key that shows/hides the window (ignored on touch devices) |
| `ShowPill` | bool | `true` | Whether to show the floating "Show Interface" pill on mobile/when hidden |
| `SplashMode` | string | `"splash"` | Intro animation style: `"splash"` (full loading screen), `"silent"` (fade in), `"none"` (instant) |
| `Debug` | bool | `false` | If `true`, prints internal `INFO` log messages to the output |
| `AccentColor` | Color3 | `nil` | Overrides the accent color used for active nav items, toggles, and highlights |
| `Colors` | table | `nil` | Override any entry from the internal color palette (see [Color System](#color-system)) |
| `Pages` | table | See below | List of page definitions |
| `SplashTasks` | table | Default strings | List of task strings cycled through on the splash screen |

### Pages Configuration

Each entry in the `Pages` array is a table:

```lua
Pages = {
    { Name = "Dashboard" },
    { Name = "Settings", Icon = "1234567890" }, -- optional Roblox asset ID for an icon
    {
        -- A collapsible group of pages
        Group = "Advanced",
        DefaultOpen = true,
        Pages = {
            { Name = "Logs" },
            { Name = "Debug" },
        }
    },
}
```

| Field | Description |
|---|---|
| `Name` | Display name of the page in the sidebar |
| `Icon` | (optional) Roblox asset ID for a sidebar icon. Falls back to the first letter if the image fails to load |
| `Group` | Creates a collapsible group header instead of a regular page |
| `DefaultOpen` | (group only) Whether the group starts expanded. Defaults to `true` |

### Example with all options

```lua
local ui = Lib.new({
    AppName        = "AimHelper Pro",
    AppSubtitle    = "by You",
    AppVersion     = "2.1",
    LogoImage      = "rbxassetid://YOUR_LOGO_ID",
    GuiParent      = "CoreGui",
    WindowWidth    = 860,
    WindowHeight   = 540,
    SidebarWidth   = 200,
    TweenSpeed     = 0.18,
    ToggleKey      = "RightShift",
    ShowPill       = true,
    SplashMode     = "silent",
    AccentColor    = Color3.fromRGB(0, 232, 122),
    Debug          = false,
    Pages = {
        { Name = "Main"     },
        { Name = "Visuals"  },
        { Name = "Settings" },
        { Name = "Logs"     },
    },
    SplashTasks = {
        "Loading modules...",
        "Checking environment...",
        "Ready.",
    },
})
```

---

## Window Controls

These methods control the visibility and state of the window.

```lua
ui:Show()               -- Show the window (with animation)
ui:Hide()               -- Hide the window (with animation)
ui:SetVisible(bool)     -- Show or hide based on a boolean
ui:ToggleVisibility()   -- Toggle between shown and hidden
ui:Minimise()           -- Collapse the window to just the title bar (or mobile pill)
ui:Maximise()           -- Restore the window from minimised state
ui:IsVisible()          -- Returns true if the window is currently visible
ui:IsMinimised()        -- Returns true if the window is currently minimised
ui:Shake(intensity)     -- Briefly shake the window (intensity defaults to 6)
ui:SetPage(index)       -- Navigate to a page by its 1-based index
```

---

## Pages & Navigation

Pages are referenced by their **1-based index** corresponding to the order they appear in the `Pages` configuration table.

```lua
local scroll = ui:GetPage(1)  -- Returns the ScrollingFrame of page 1, or nil
ui:SetPage(2)                 -- Switch to page 2 with animation
ui:SetPageBadge(1, "3")       -- Show a red badge with "3" on page 1's nav button
ui:SetPageBadge(1, "")        -- Remove the badge
```

---

## Notifications & Dialogs

### Toast Notifications

```lua
ui:Notify(message, style, duration, title)
-- or the full alias:
ui:ShowNotification(message, style, duration, title)
```

| Parameter | Type | Description |
|---|---|---|
| `message` | string | The notification body text |
| `style` | string | `"info"`, `"success"`, `"warning"`, `"error"`, `"purple"` |
| `duration` | number | How long to display (seconds). Defaults to `3` |
| `title` | string | Optional title shown in the header. Defaults to the style name |

```lua
ui:Notify("Operation completed!", "success", 3, "Done")
ui:Notify("Something went wrong.", "error", 5)
ui:Notify("Check your settings.", "warning")
```

### Confirm Dialog

```lua
ui:Confirm(title, message, onConfirm, onCancel, opts)
```

| Parameter | Type | Description |
|---|---|---|
| `title` | string | Modal title |
| `message` | string | Body text |
| `onConfirm` | function | Called when the user clicks the confirm button |
| `onCancel` | function | Called when the user clicks cancel or the overlay |
| `opts` | table | Optional. `ConfirmText`, `CancelText`, `ConfirmColor`, `Destructive` (bool, default `true`) |

```lua
ui:Confirm(
    "Delete Save",
    "This will permanently erase your save data. Are you sure?",
    function()
        -- user confirmed
    end,
    function()
        -- user cancelled
    end,
    { ConfirmText = "Delete", CancelText = "Keep", Destructive = true }
)
```

### Inline Notification (anchored to bottom of window)

```lua
ui:ShowInlineNotification(message, style, duration, title)
```

Works the same as `Notify` but renders inside the window frame at the bottom rather than as a floating toast.

---

## Components

All component methods take a **page index** (`pi`) as their first argument. Components are appended in the order they are called.

---

### AddSectionHeader

A large title + optional subtitle + horizontal divider. Use at the top of a page section.

```lua
ui:AddSectionHeader(pi, title, subtitle)
```

```lua
ui:AddSectionHeader(1, "Dashboard", "Overview of your session")
```

---

### AddDivider

A labeled or plain horizontal divider to separate content groups.

```lua
ui:AddDivider(pi, text, spacing)
```

| Parameter | Description |
|---|---|
| `text` | Optional label in the center. If omitted, renders a plain line |
| `spacing` | Vertical space above and below (default `8`) |

```lua
ui:AddDivider(1, "Settings")
ui:AddDivider(1)              -- plain line
ui:AddDivider(1, "Data", 12)  -- extra spacing
```

---

### AddSeparator

A simple 1px horizontal line with spacing.

```lua
ui:AddSeparator(pi, spacing)  -- spacing defaults to 6
```

---

### AddLabel

A text label with predefined styles.

```lua
local obj = ui:AddLabel(pi, text, style)
```

| Style | Description |
|---|---|
| `"title"` | 19px, white, bold |
| `"subtitle"` | 14px, white, bold |
| `"body"` | 13px, light gray (default) |
| `"muted"` | 12px, dim gray |
| `"caption"` | 10px, very dim |

**Returned object methods:**

```lua
obj:Set("New text")
obj:SetColor(Color3.fromRGB(255, 100, 100))
```

---

### AddRichLabel

A label with RichText enabled, useful for inline color/bold/italic markup.

```lua
local obj = ui:AddRichLabel(pi, content)
```

```lua
local rl = ui:AddRichLabel(1, '<font color="rgb(0,232,122)">Online</font> — all systems go')
rl:Set("<b>Updated:</b> now")
rl:Show()
rl:Hide()
```

---

### AddParagraph

A card containing a bold title and wrapped body text.

```lua
local obj = ui:AddParagraph(pi, title, content)
```

```lua
local p = ui:AddParagraph(1, "About", "This script does X, Y, and Z.")
p:Set("New title", "New content")
```

---

### AddAlert

A colored alert banner with an optional title and accent bar.

```lua
local obj = ui:AddAlert(pi, title, message, style)
```

Style options: `"info"`, `"success"`, `"warning"`, `"error"`, `"purple"`.

```lua
local alert = ui:AddAlert(1, "Warning", "You are in spectator mode.", "warning")
alert:Set("New message text")
alert:Show()
alert:Hide()
```

---

### AddBadge

A small inline badge pill.

```lua
local obj = ui:AddBadge(pi, text, style)
```

Style options: `"default"`, `"success"`, `"error"`, `"warning"`, `"info"`, `"white"`, `"purple"`.

```lua
local b = ui:AddBadge(1, "Beta", "warning")
b:Set("Stable")  -- update text
```

---

### AddTag

A rounded pill tag.

```lua
local obj = ui:AddTag(pi, text, style)
```

Style options: `"info"`, `"success"`, `"warning"`, `"error"`, `"muted"`, `"default"`.

```lua
local tag = ui:AddTag(1, "Active", "success")
tag:Set("Inactive")
tag:SetStyle("error")
```

---

### AddButton

A single full-width-ish button with built-in loading state support.

```lua
local obj = ui:AddButton(pi, text, style, callback)
```

Style options: `"primary"`, `"danger"`, `"warning"`, `"ghost"`, `"outline"`, `"success"`, `"purple"`.

**Returned object methods:**

```lua
obj:Set("New Label")            -- change button text
obj:SetEnabled(false)           -- disable the button
obj:SetLoading(true)            -- show "..." and disable clicks
obj:SetLoading(false)           -- restore to normal
```

```lua
local btn = ui:AddButton(1, "Save", "primary", function()
    print("Saved!")
end)

-- Simulate async work:
btn.Button.Activated:Connect(function()
    btn:SetLoading(true)
    task.delay(2, function()
        btn:SetLoading(false)
        ui:Notify("Saved!", "success", 2)
    end)
end)
```

---

### AddButtonRow

A horizontal row of up to several buttons, each independently styled.

```lua
local buttons = ui:AddButtonRow(pi, definitions)
```

Each entry in `definitions` is a table:

| Field | Description |
|---|---|
| `Text` | Button label |
| `Style` | One of the style strings listed above |
| `Width` | Button width in pixels (default `130`) |
| `Callback` | Function called on click |

```lua
local btns = ui:AddButtonRow(1, {
    { Text = "Accept", Style = "success", Width = 120, Callback = function() end },
    { Text = "Decline", Style = "danger",  Width = 120, Callback = function() end },
})
-- btns[1] and btns[2] are the TextButton instances
```

---

### AddToggle

A toggle switch.

```lua
local obj = ui:AddToggle(pi, label, default, callback, description)
```

| Parameter | Description |
|---|---|
| `label` | Text shown on the left |
| `default` | Initial state (`true`/`false`) |
| `callback` | `function(value: bool)` fired on change |
| `description` | Optional secondary text below the label |

**Returned object methods:**

```lua
obj:Set(true)          -- set state without firing callback
obj:Get()              -- returns current state (bool)
obj:SetState(true)     -- alias for Set
obj:GetState()         -- alias for Get
```

```lua
local toggle = ui:AddToggle(1, "Auto-Farm", false, function(v)
    print("Auto-Farm:", v)
end, "Automatically collects resources")

-- Read state elsewhere:
print(toggle:Get())
```

---

### AddCheckbox

A checkbox, functionally similar to a toggle but styled differently.

```lua
local obj = ui:AddCheckbox(pi, label, default, callback)
```

**Returned object methods:** `obj:Set(bool)`, `obj:Get()`, `obj:SetState(bool)`, `obj:GetState()`.

```lua
local cb = ui:AddCheckbox(2, "Agree to Terms", false, function(v)
    print("Agreed:", v)
end)
```

---

### AddSlider

A horizontal drag slider.

```lua
local obj = ui:AddSlider(pi, label, min, max, default, callback)
```

The `callback` fires on mouse/touch release, not while dragging.

**Returned object method:**

```lua
obj:SetValue(50)  -- programmatically set the value
```

```lua
local slider = ui:AddSlider(1, "Walk Speed", 0, 100, 16, function(v)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
end)
```

---

### AddStepper

A numeric stepper with increment/decrement buttons.

```lua
local obj = ui:AddStepper(pi, label, min, max, default, step, callback)
```

**Returned object methods:**

```lua
obj:GetValue()      -- returns current value
obj:SetValue(10)    -- set value programmatically
```

```lua
local stepper = ui:AddStepper(1, "Jump Count", 1, 10, 3, 1, function(v)
    print("Jumps:", v)
end)
```

---

### AddInput

A text input box.

```lua
local obj = ui:AddInput(pi, label, placeholder, callback, opts)
```

The `callback` is called as `function(text, enterPressed)` when focus is lost.

| Option | Description |
|---|---|
| `RemoveTextAfterFocusLost` | Clears the box after the user defocuses |
| `ClearTextOnFocus` | Clears the box when the user clicks into it |
| `MultiLine` | Makes the box taller and allows newlines |
| `TextSize` | Font size (default `13`) |

**Returned object methods:**

```lua
obj:Set("default text")
obj:Get()             -- returns current text
obj:Focus()           -- programmatically focus the input
obj:Clear()           -- clear the text
```

```lua
local input = ui:AddInput(1, "Player Name", "Enter username...", function(text, enter)
    if enter then
        print("Searching for:", text)
    end
end)
```

---

### AddInputNumber

A text input that validates and clamps to a numeric range.

```lua
local obj = ui:AddInputNumber(pi, label, opts, callback)
```

| Option | Description |
|---|---|
| `Min` | Minimum allowed value (default `0`) |
| `Max` | Maximum allowed value (default `999999999`) |
| `Step` | Rounds to the nearest multiple of this value |
| `Placeholder` | Placeholder text |

**Returned object methods:**

```lua
obj:Set(25)          -- set value programmatically
obj:Get()            -- returns current numeric value
obj:SetValid(true, "OK")       -- mark as valid with optional message
obj:SetValid(false, "Too high") -- mark as invalid
```

```lua
local numInput = ui:AddInputNumber(1, "Damage Multiplier", {
    Min = 1, Max = 999, Step = 1, Placeholder = "1–999"
}, function(n, enter)
    if enter then print("Multiplier set to", n) end
end)
```

---

### AddDropdown

A single-select dropdown list.

```lua
local obj = ui:AddDropdown(pi, label, options, callback)
```

`options` is a table of strings. The `callback` receives the selected string.

**Returned object:**

```lua
obj.GetSelected()   -- returns the currently selected string
```

Supports keyboard navigation when open: `↑` / `↓` to highlight, `Enter` to select, `Escape` to close.

```lua
local dd = ui:AddDropdown(1, "Game Mode", {"FFA", "Teams", "Ranked"}, function(v)
    print("Mode:", v)
end)
print(dd.GetSelected())
```

---

### AddRadioGroup

A group of mutually exclusive radio buttons.

```lua
local obj = ui:AddRadioGroup(pi, label, options, default, callback)
```

**Returned object methods:**

```lua
obj:GetSelected()         -- returns selected string
obj:SetSelected("Option B")
```

```lua
local radio = ui:AddRadioGroup(2, "Team", {"Red", "Blue", "Spectator"}, "Blue", function(v)
    print("Team:", v)
end)
```

---

### AddMultiSelect

An expandable multi-select list.

```lua
local obj = ui:AddMultiSelect(pi, label, options, callback)
```

The `callback` receives the internal `selected` table where keys are option strings and values are booleans.

**Returned object methods:**

```lua
obj:GetSelected()                     -- returns table of selected option strings
obj:SetSelected({"Alpha", "Gamma"})   -- programmatically set selection
obj:IsSelected("Alpha")               -- returns bool
```

```lua
local ms = ui:AddMultiSelect(1, "Active Hacks", {"ESP", "Aimbot", "SpeedHack"}, function(sel)
    for opt, active in pairs(sel) do
        print(opt, active)
    end
end)
```

---

### AddColorPicker

A color picker with a saturation/value field, hue bar, and hex input.

```lua
local obj = ui:AddColorPicker(pi, label, default, callback)
```

`default` can be a `Color3` or a hex string (e.g. `"4488ff"`). The `callback` receives `(Color3, hexString)`.

**Returned object methods:**

```lua
obj:GetColor()              -- returns Color3, hexString
obj:SetColor(Color3)        -- update programmatically (also accepts hex string)
obj:SetColor("ff0000")
```

```lua
local cp = ui:AddColorPicker(1, "ESP Color", Color3.fromRGB(0, 200, 255), function(col, hex)
    print("New color:", hex)
end)
```

---

### AddKeybind

A clickable keybind recorder.

```lua
local obj = ui:AddKeybind(pi, label, default, callback)
```

Clicking the button puts it in listening mode. The next key pressed becomes the new bind. `Escape` cancels.

**Returned object methods:**

```lua
obj:GetKey()        -- returns current key name string
obj:SetKey("F")     -- set programmatically
```

```lua
local kb = ui:AddKeybind(1, "Toggle ESP", "X", function(key)
    print("ESPKey set to:", key)
end)
```

---

### AddProgressBar

A labeled progress bar.

```lua
local obj = ui:AddProgressBar(pi, label, value, maxValue)
```

**Returned object methods:**

```lua
obj:SetValue(75)    -- updates bar and percentage label
obj:Show()
obj:Hide()
```

```lua
local bar = ui:AddProgressBar(1, "XP Progress", 340, 1000)
-- later:
bar:SetValue(500)
```

---

### AddMetricRow

A row of up to 3 stat cards displayed side by side.

```lua
local objects = ui:AddMetricRow(pi, cards)
```

Each card definition:

| Field | Description |
|---|---|
| `Label` | Small uppercase label |
| `Value` | Large number/text shown prominently |
| `Unit` | Small text below the value |

**Returns** an array of objects, each with a `ValueLabel` and `Frame`.

```lua
local metrics = ui:AddMetricRow(1, {
    { Label = "Kills",  Value = 0,   Unit = "this session" },
    { Label = "Deaths", Value = 0,   Unit = "this session" },
    { Label = "KDR",    Value = "—", Unit = "ratio" },
})

-- Update values:
ui:SetMetricValue(metrics[1], 12)
ui:SetMetricValue(metrics[2], 3)
ui:SetMetricValue(metrics[3], "4.0")
```

---

### AddTable

A static data table with a header row.

```lua
local obj = ui:AddTable(pi, headers, rows)
```

```lua
local tbl = ui:AddTable(1,
    { "Name", "Level", "Status" },
    {
        { "Alpha", "50", "Online"  },
        { "Beta",  "32", "Offline" },
    }
)
tbl:Show()
tbl:Hide()
```

---

### AddList

A dynamic scrollable list that supports adding and removing items at runtime.

```lua
local obj = ui:AddList(pi, label, opts)
```

| Option | Description |
|---|---|
| `MaxItems` | Maximum entries before oldest is removed (default `50`) |
| `ItemHeight` | Height per row in pixels (default `36`) |
| `ShowIndex` | Prefix each item with its number |

**Returned object methods:**

```lua
obj:Add(text, color)     -- add an item, returns its index
obj:RemoveAt(index)      -- remove item at index
obj:Clear()              -- remove all items
obj:GetItems()           -- returns array of text strings
obj:Count()              -- returns number of items
```

```lua
local log = ui:AddList(1, "Kill Feed", { MaxItems = 20, ItemHeight = 30 })

-- Later:
log:Add("You killed Alpha", Color3.fromRGB(0, 232, 122))
log:Add("Beta killed you",  Color3.fromRGB(232, 64, 64))
```

---

### AddCard

A container card with an optional header. Returns an inner `Frame` you can parent other instances to, or use as a layout container.

```lua
local inner = ui:AddCard(pi, title, subtitle)
```

The returned `inner` frame has `UIListLayout` and `UIPadding` already applied — just parent elements to it.

```lua
local card = ui:AddCard(1, "Player Info", "Current session data")
-- parent custom labels/etc. to 'card'
local nameLabel = Instance.new("TextLabel")
nameLabel.Text = "Player: " .. game.Players.LocalPlayer.Name
nameLabel.Parent = card
```

---

### AddLogConsole

A terminal-style scrollable console with colored log levels.

```lua
local console = ui:AddLogConsole(pi, height)
```

`height` defaults to `220`.

**Returned object methods:**

```lua
console:Log(message, level)   -- level: "INFO", "SUCCESS", "WARN", "ERROR", "DEBUG", "SNIPE"
console:Clear()
console:SetActive(bool)       -- changes the dot indicator to green (true) or red (false)
```

```lua
local console = ui:AddLogConsole(5, 280)
console:Log("Script started", "SUCCESS")
console:Log("Scanning workspace...", "INFO")
console:Log("Unexpected nil value", "WARN")
console:Log("Target not found", "ERROR")
```

---

### AddNotificationCenter

An in-page feed of pushed notification entries.

```lua
local obj = ui:AddNotificationCenter(pi, opts)
```

| Option | Description |
|---|---|
| `MaxItems` | Maximum entries (default `30`) |
| `Height` | Height of the scroll area (default `200`) |

**Returned object methods:**

```lua
obj:Push(text, style, label)   -- push a new entry; style: "info","success","warning","error","default"
obj:Clear()
obj:SetActive(bool)            -- toggle green/red status dot
```

```lua
local nc = ui:AddNotificationCenter(1, { MaxItems = 50, Height = 180 })
nc:Push("Player joined", "success", "Event")
nc:Push("Connection lost", "error", "Network")
```

---

### AddSpinner

A small animated loading spinner row.

```lua
local obj = ui:AddSpinner(pi, label)
```

**Returned object methods:**

```lua
obj:Stop()
obj:Start()
```

```lua
local spinner = ui:AddSpinner(1, "Fetching data...")
task.delay(3, function()
    spinner:Stop()
end)
```

---

### AddColorSwatch

A visual color chip with a hex label, for display purposes.

```lua
local obj = ui:AddColorSwatch(pi, label, hexColor)
```

```lua
ui:AddColorSwatch(1, "Accent", "00e87a")
ui:AddColorSwatch(1, "Danger", "e84040")
```

---

### AddInlineImage

Renders a Roblox image inline on the page.

```lua
local obj = ui:AddInlineImage(pi, assetId, size, color)
```

```lua
local img = ui:AddInlineImage(1, 7059346373, 24, Color3.new(1,1,1))
img:SetColor(Color3.fromRGB(100, 200, 255))
img:SetImage(1234567890)
```

---

### AddStatusBadge2

A row with a label on the left and a colored dot + state text on the right.

```lua
local obj = ui:AddStatusBadge2(pi, label, state)
```

State options: `"online"`, `"offline"`, `"idle"`, `"loading"`.

```lua
local badge = ui:AddStatusBadge2(1, "Connection", "idle")
badge:SetState("online")
badge:SetState("offline")
```

---

## Utility Methods

### Show / Hide Elements

Animate any component in or out:

```lua
ui:ShowElement(obj)   -- fade in obj.Frame
ui:HideElement(obj)   -- fade out obj.Frame
```

### SetMetricValue

Update a metric card value with a brief flash animation:

```lua
ui:SetMetricValue(metricObj, newValue)
```

### AddSearchInput

Convenience alias for a search-styled text input:

```lua
local obj = ui:AddSearchInput(pi, placeholder, callback)
```

### CreateStatusBadge (standalone)

Creates a small badge frame you can place anywhere — not tied to a page:

```lua
local badge = ui:CreateStatusBadge(parentFrame, state)
-- state: "on", "off", "idle"
badge:SetState("on")
```

### ProcessHexColors

A utility that takes a string and appends a colored preview swatch after each hex color code found:

```lua
local result = Lib.ProcessHexColors("The color is #ff0000 and #00e87a")
```

---

## Platform Helpers

```lua
ui:IsMobile()                  -- returns true on touch devices or when mobile simulation is on
ui:IsPC()                      -- inverse of IsMobile()

ui:OnMobile(function()
    -- runs only on touch devices
end)

ui:OnPC(function()
    -- runs only on non-touch devices
end)

ui:AddPlatform({
    PC = function()
        -- called if on PC
    end,
    Mobile = function()
        -- called if on mobile
    end,
})

-- Only add a component on mobile:
ui:AddMobileOnly(pi, function(pageIndex)
    ui:AddLabel(pageIndex, "Touch controls active", "muted")
end)

-- Only add a component on PC:
ui:AddPCOnly(pi, function(pageIndex)
    ui:AddKeybind(pageIndex, "Sprint", "LeftShift", function() end)
end)

-- Render different label text per platform:
ui:AddPlatformLabel(pi, "Press K to toggle", "Tap the pill to toggle", "muted")

-- Render different alert text per platform:
ui:AddPlatformAlert(pi, "Controls", "Use keyboard shortcuts", "Tap the menu", "info")
```

---

## Lifecycle & Cleanup

```lua
-- Register a callback to run just before the library destroys itself:
ui:OnDestroy(function()
    print("UI removed")
end)

-- Completely remove the UI, disconnect all connections, and destroy all instances:
ui:Destroy()
```

The built-in Settings panel includes an **Unload Script** button that calls `Destroy()` after a confirmation dialog.

---

## Color System

The internal palette uses these named keys, all of which can be overridden via the `Colors` config field:

| Key | Default | Usage |
|---|---|---|
| `Bg` | `#060606` | Main window background |
| `Bg2` | `#080808` | Title bar / content area background |
| `Sidebar` | `#050505` | Sidebar background |
| `Card` | `#121212` | Card background |
| `Card2` | `#1a1a1a` | Hovered card / input background |
| `Card3` | `#222222` | Stepper controls, track fills |
| `Border` | `#2a2a2a` | Primary border color |
| `Border2` | `#222222` | Secondary border |
| `Border3` | `#2e2e2e` | Scrollbar color |
| `Text` | `#d8d8d8` | Primary text |
| `TextDim` | `#9a9a9a` | Secondary / dim text |
| `TextOff` | `#555555` | Inactive / placeholder text |
| `White` | `#ffffff` | Pure white accent |
| `Green` | `#00e87a` | Success color |
| `GreenBg` | `#030e08` | Success background tint |
| `Red` | `#e84040` | Error / danger color |
| `RedBg` | `#0e0404` | Error background tint |
| `Yellow` | `#f0c030` | Warning color |
| `YellowBg` | `#0e0b02` | Warning background tint |
| `Orange` | `#f07020` | Orange accent |
| `Blue` | `#4488ff` | Info color |
| `BlueBg` | `#030914` | Info background tint |
| `Purple` | `#aa44ff` | Purple accent |
| `PurpleBg` | `#0a0414` | Purple background tint |

Override example:

```lua
local ui = Lib.new({
    Colors = {
        Green   = Color3.fromRGB(0, 255, 150),
        GreenBg = Color3.fromRGB(0, 20, 10),
    },
    AccentColor = Color3.fromRGB(0, 255, 150),
    -- ...
})
```

---

## Demo Mode

Calling `Lib.new()` with no arguments (or the library being `require`d without calling `.new`) launches an automatic demo that populates five pages — Dashboard, Inputs, Components, Buttons, and Logs — with every built-in component, showcasing interactive behavior.

```lua
-- Launch demo:
local Lib = loadstring(game:HttpGet("YOUR_URL"))()
-- Lib.new() is called automatically if you never call it yourself,
-- or call it explicitly:
Lib.new()
```

---

## Built-in Settings Panel

Click the **gear icon** (⚙) in the title bar at any time to open the built-in settings panel. It provides:

- **Keybind configurator** — click and press any key to remap the toggle shortcut
- **Reduce Motion toggle** — shortens animation durations and removes easing overshoot for accessibility
- **Simulate Mobile toggle** — previews the mobile layout from a desktop session (developer tool)
- **Unload Script button** — calls `Destroy()` after a confirm dialog
- **About section** — shows library name, version, and app name

---

## Built-in Search

Press **Ctrl+F** (or click the search icon in the title bar) to open an inline search bar that highlights matching text across all labels and buttons on the current page. Use the `↑` / `↓` navigation arrows to jump between results.
