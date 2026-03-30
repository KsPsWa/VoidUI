-- ══════════════════════════════════════════════════════════════
--  VoidUI v5.0  ·  Refactored Core
--  Changes:
--    · LoadModule(url) для динамической подгрузки модулей
--    · Scale-only позиции главного окна + UISizeConstraint
--    · SafeZone (notch/inset) через GuiService
--    · AutomaticSize.Y на всех контейнерах
--    · Dynamic CanvasSize через AbsoluteContentSize
--    · task.wait() вместо wait() везде
--    · Анимации не играют на скрытых элементах
--    · GC через Maid при закрытии вкладок
-- ══════════════════════════════════════════════════════════════

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")
local Players          = game:GetService("Players")
local Debris           = game:GetService("Debris")
local Stats            = game:GetService("Stats")

local LP = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
--  MAID  (минимальный GC-хелпер)
-- ══════════════════════════════════════════════════════════════
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Add(item)
    table.insert(self._tasks, item)
    return item
end

function Maid:Clean()
    for _, t in ipairs(self._tasks) do
        if typeof(t) == "RBXScriptConnection" then
            t:Disconnect()
        elseif typeof(t) == "Instance" then
            t:Destroy()
        elseif type(t) == "function" then
            pcall(t)
        end
    end
    self._tasks = {}
end

-- ══════════════════════════════════════════════════════════════
--  ТЕМЫ
-- ══════════════════════════════════════════════════════════════
local THEMES = {
    Void = {
        Bg          = Color3.fromRGB(8,   8,  14),
        BgLight     = Color3.fromRGB(14,  14, 22),
        BgTab       = Color3.fromRGB(11,  11, 18),
        BgElement   = Color3.fromRGB(18,  18, 28),
        BgHover     = Color3.fromRGB(28,  16, 56),
        BgInput     = Color3.fromRGB(6,   6,  11),
        Accent      = Color3.fromRGB(138, 58, 255),
        AccentDark  = Color3.fromRGB(88,  28, 178),
        AccentLight = Color3.fromRGB(178, 118,255),
        AccentFaded = Color3.fromRGB(55,  20, 110),
        TextPrimary = Color3.fromRGB(238, 238,252),
        TextSub     = Color3.fromRGB(138, 138,158),
        TextMuted   = Color3.fromRGB(72,  72, 90),
        TextAccent  = Color3.fromRGB(178, 118,255),
        Border      = Color3.fromRGB(36,  16, 76),
        BorderLight = Color3.fromRGB(56,  26, 106),
        Sep         = Color3.fromRGB(26,  12, 54),
        Success     = Color3.fromRGB(48,  214,98),
        Warning     = Color3.fromRGB(252, 178,48),
        Error       = Color3.fromRGB(252, 58, 58),
        Info        = Color3.fromRGB(138, 58, 255),
        ScrollBar   = Color3.fromRGB(55,  25, 115),
    },
    Midnight = {
        Bg          = Color3.fromRGB(6,   8,  16),
        BgLight     = Color3.fromRGB(10,  14, 28),
        BgTab       = Color3.fromRGB(8,   10, 22),
        BgElement   = Color3.fromRGB(14,  18, 36),
        BgHover     = Color3.fromRGB(20,  30, 70),
        BgInput     = Color3.fromRGB(5,   7,  14),
        Accent      = Color3.fromRGB(60,  120,255),
        AccentDark  = Color3.fromRGB(30,  70, 180),
        AccentLight = Color3.fromRGB(100, 160,255),
        AccentFaded = Color3.fromRGB(20,  45, 110),
        TextPrimary = Color3.fromRGB(220, 230,255),
        TextSub     = Color3.fromRGB(120, 140,180),
        TextMuted   = Color3.fromRGB(60,  75, 110),
        TextAccent  = Color3.fromRGB(100, 160,255),
        Border      = Color3.fromRGB(20,  40, 100),
        BorderLight = Color3.fromRGB(35,  60, 140),
        Sep         = Color3.fromRGB(15,  25, 60),
        Success     = Color3.fromRGB(48,  214,98),
        Warning     = Color3.fromRGB(252, 178,48),
        Error       = Color3.fromRGB(252, 58, 58),
        Info        = Color3.fromRGB(60,  120,255),
        ScrollBar   = Color3.fromRGB(30,  65, 160),
    },
    Crimson = {
        Bg          = Color3.fromRGB(12,  6,  8),
        BgLight     = Color3.fromRGB(20,  10, 14),
        BgTab       = Color3.fromRGB(16,  8,  11),
        BgElement   = Color3.fromRGB(24,  12, 16),
        BgHover     = Color3.fromRGB(55,  16, 22),
        BgInput     = Color3.fromRGB(8,   4,  6),
        Accent      = Color3.fromRGB(220, 40, 60),
        AccentDark  = Color3.fromRGB(140, 20, 35),
        AccentLight = Color3.fromRGB(255, 90, 110),
        AccentFaded = Color3.fromRGB(90,  16, 25),
        TextPrimary = Color3.fromRGB(252, 230,235),
        TextSub     = Color3.fromRGB(180, 130,140),
        TextMuted   = Color3.fromRGB(100, 65, 72),
        TextAccent  = Color3.fromRGB(255, 90, 110),
        Border      = Color3.fromRGB(80,  18, 26),
        BorderLight = Color3.fromRGB(120, 30, 42),
        Sep         = Color3.fromRGB(50,  12, 18),
        Success     = Color3.fromRGB(48,  214,98),
        Warning     = Color3.fromRGB(252, 178,48),
        Error       = Color3.fromRGB(252, 58, 58),
        Info        = Color3.fromRGB(220, 40, 60),
        ScrollBar   = Color3.fromRGB(110, 22, 35),
    },
    Forest = {
        Bg          = Color3.fromRGB(6,   12, 8),
        BgLight     = Color3.fromRGB(10,  20, 13),
        BgTab       = Color3.fromRGB(8,   16, 10),
        BgElement   = Color3.fromRGB(12,  24, 15),
        BgHover     = Color3.fromRGB(18,  50, 24),
        BgInput     = Color3.fromRGB(5,   9,  6),
        Accent      = Color3.fromRGB(48,  200,80),
        AccentDark  = Color3.fromRGB(24,  130,48),
        AccentLight = Color3.fromRGB(100, 230,130),
        AccentFaded = Color3.fromRGB(16,  75, 28),
        TextPrimary = Color3.fromRGB(220, 252,228),
        TextSub     = Color3.fromRGB(120, 170,130),
        TextMuted   = Color3.fromRGB(60,  95, 68),
        TextAccent  = Color3.fromRGB(100, 230,130),
        Border      = Color3.fromRGB(18,  70, 28),
        BorderLight = Color3.fromRGB(28,  100,42),
        Sep         = Color3.fromRGB(12,  44, 18),
        Success     = Color3.fromRGB(48,  214,98),
        Warning     = Color3.fromRGB(252, 178,48),
        Error       = Color3.fromRGB(252, 58, 58),
        Info        = Color3.fromRGB(48,  200,80),
        ScrollBar   = Color3.fromRGB(22,  90, 38),
    },
    Ash = {
        Bg          = Color3.fromRGB(12,  12, 14),
        BgLight     = Color3.fromRGB(20,  20, 24),
        BgTab       = Color3.fromRGB(16,  16, 19),
        BgElement   = Color3.fromRGB(24,  24, 28),
        BgHover     = Color3.fromRGB(40,  40, 50),
        BgInput     = Color3.fromRGB(8,   8,  10),
        Accent      = Color3.fromRGB(180, 180,200),
        AccentDark  = Color3.fromRGB(100, 100,120),
        AccentLight = Color3.fromRGB(220, 220,240),
        AccentFaded = Color3.fromRGB(60,  60, 75),
        TextPrimary = Color3.fromRGB(240, 240,248),
        TextSub     = Color3.fromRGB(150, 150,165),
        TextMuted   = Color3.fromRGB(80,  80, 95),
        TextAccent  = Color3.fromRGB(220, 220,240),
        Border      = Color3.fromRGB(50,  50, 65),
        BorderLight = Color3.fromRGB(70,  70, 88),
        Sep         = Color3.fromRGB(30,  30, 40),
        Success     = Color3.fromRGB(48,  214,98),
        Warning     = Color3.fromRGB(252, 178,48),
        Error       = Color3.fromRGB(252, 58, 58),
        Info        = Color3.fromRGB(180, 180,200),
        ScrollBar   = Color3.fromRGB(65,  65, 85),
    },
    Gold = {
        Bg          = Color3.fromRGB(10,  8,  4),
        BgLight     = Color3.fromRGB(18,  14, 6),
        BgTab       = Color3.fromRGB(14,  11, 5),
        BgElement   = Color3.fromRGB(22,  17, 7),
        BgHover     = Color3.fromRGB(50,  36, 8),
        BgInput     = Color3.fromRGB(7,   5,  2),
        Accent      = Color3.fromRGB(230, 170,30),
        AccentDark  = Color3.fromRGB(150, 105,15),
        AccentLight = Color3.fromRGB(255, 210,80),
        AccentFaded = Color3.fromRGB(85,  60, 10),
        TextPrimary = Color3.fromRGB(255, 245,210),
        TextSub     = Color3.fromRGB(180, 155,90),
        TextMuted   = Color3.fromRGB(100, 82, 40),
        TextAccent  = Color3.fromRGB(255, 210,80),
        Border      = Color3.fromRGB(80,  58, 12),
        BorderLight = Color3.fromRGB(120, 88, 20),
        Sep         = Color3.fromRGB(50,  36, 8),
        Success     = Color3.fromRGB(48,  214,98),
        Warning     = Color3.fromRGB(252, 178,48),
        Error       = Color3.fromRGB(252, 58, 58),
        Info        = Color3.fromRGB(230, 170,30),
        ScrollBar   = Color3.fromRGB(100, 72, 15),
    },
}

local T = {}
for k, v in pairs(THEMES.Void) do T[k] = v end

local function applyTheme(name)
    local src = THEMES[name]
    if not src then return end
    for k, v in pairs(src) do T[k] = v end
end

local function applyAccent(col)
    T.Accent      = col
    T.AccentDark  = Color3.new(col.R * 0.62,  col.G * 0.62,  col.B * 0.62)
    T.AccentLight = Color3.new(math.min(col.R * 1.35, 1), math.min(col.G * 1.35, 1), math.min(col.B * 1.35, 1))
    T.AccentFaded = Color3.new(col.R * 0.38,  col.G * 0.38,  col.B * 0.38)
    T.TextAccent  = T.AccentLight
    T.Border      = Color3.new(col.R * 0.27,  col.G * 0.15,  col.B * 0.55)
    T.ScrollBar   = Color3.new(col.R * 0.44,  col.G * 0.22,  col.B * 0.70)
    T.Info        = col
end

-- ══════════════════════════════════════════════════════════════
--  SAFE ZONE  (notch/inset для iPhone/Android)
-- ══════════════════════════════════════════════════════════════
-- GuiService:GetGuiInset() возвращает (topInset, bottomInset)
local function getSafeInset()
    local ok, top, bottom = pcall(function()
        return GuiService:GetGuiInset()
    end)
    if ok then
        return top, bottom
    end
    return Vector2.zero, Vector2.zero
end

-- ══════════════════════════════════════════════════════════════
--  EASING
-- ══════════════════════════════════════════════════════════════
local EF = { Enum.EasingStyle.Quad, Enum.EasingDirection.Out }
local TI = {
    Fast   = TweenInfo.new(0.12, table.unpack(EF)),
    Mid    = TweenInfo.new(0.20, table.unpack(EF)),
    Slow   = TweenInfo.new(0.34, table.unpack(EF)),
    Spring = TweenInfo.new(0.30, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.38, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Linear = TweenInfo.new(1,    Enum.EasingStyle.Linear),
}

-- ══════════════════════════════════════════════════════════════
--  УТИЛИТЫ
-- ══════════════════════════════════════════════════════════════

-- Анимируем только видимые объекты
local function tw(o, p, i)
    if not o or not o.Parent then return end
    if o:IsA("GuiObject") and not o.Visible then return end
    TweenService:Create(o, i or TI.Mid, p):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local function pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 6)
    u.PaddingRight  = UDim.new(0, r or 6)
    u.PaddingBottom = UDim.new(0, b or 6)
    u.PaddingLeft   = UDim.new(0, l or 6)
    u.Parent = p
    return u
end

local function stroke(p, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color        = color or T.Border
    s.Thickness    = thick or 1
    s.Transparency = trans or 0
    s.Parent = p
    return s
end

local function lbl(p, text, size, color, font, xa)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text          = text or ""
    l.TextSize      = size or 13
    l.TextColor3    = color or T.TextPrimary
    l.Font          = font or Enum.Font.GothamMedium
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextTruncate  = Enum.TextTruncate.AtEnd
    l.Parent = p
    return l
end

local function lst(p, spacing, dir)
    local u = Instance.new("UIListLayout")
    u.SortOrder     = Enum.SortOrder.LayoutOrder
    u.FillDirection = dir or Enum.FillDirection.Vertical
    u.Padding       = UDim.new(0, spacing or 0)
    u.Parent = p
    return u
end

local function grad(p, colors, rot)
    local g   = Instance.new("UIGradient")
    local kps = {}
    for i, v in ipairs(colors) do
        kps[i] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), v)
    end
    g.Color    = ColorSequence.new(kps)
    g.Rotation = rot or 0
    g.Parent   = p
    return g
end

local function frm(p, size, pos, bg, trans)
    local f = Instance.new("Frame")
    f.Size                   = size or UDim2.new(1, 0, 1, 0)
    f.Position               = pos  or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3       = bg or T.Bg
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel        = 0
    f.Parent = p
    return f
end

local function ripple(p, mx, my)
    local r = Instance.new("Frame")
    r.BackgroundColor3       = Color3.new(1, 1, 1)
    r.BackgroundTransparency = 0.80
    r.BorderSizePixel        = 0
    r.Size                   = UDim2.new(0, 0, 0, 0)
    r.Position               = UDim2.new(0, mx, 0, my)
    r.AnchorPoint            = Vector2.new(0.5, 0.5)
    r.ZIndex = 20
    r.Parent = p
    corner(r, 999)
    local sz = math.max(p.AbsoluteSize.X, p.AbsoluteSize.Y) * 2.4
    tw(r, { Size = UDim2.new(0, sz, 0, sz), BackgroundTransparency = 1 },
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    Debris:AddItem(r, 0.5)
end

local function mrel(obj)
    local mp = UserInputService:GetMouseLocation()
    return mp.X - obj.AbsolutePosition.X, mp.Y - obj.AbsolutePosition.Y
end

-- Привязать CanvasSize ScrollingFrame к AbsoluteContentSize его UIListLayout
local function bindCanvas(scroll, layout)
    local function update()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

-- ══════════════════════════════════════════════════════════════
--  КОНФИГ
-- ══════════════════════════════════════════════════════════════
local CONFIG_DIR = "VoidUI"
local function cfgSave(name, data)
    pcall(function()
        if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
        writefile(CONFIG_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
end
local function cfgLoad(name)
    local ok, r = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_DIR .. "/" .. name .. ".json"))
    end)
    return ok and r or {}
end

-- ══════════════════════════════════════════════════════════════
--  ГЛОБАЛЬНЫЕ ХОТКЕИ
-- ══════════════════════════════════════════════════════════════
local _hotkeys = {}

local function registerHotkey(key, label, cb)
    table.insert(_hotkeys, { key = key, label = label, cb = cb, enabled = true })
    return #_hotkeys
end

local function removeHotkey(id)
    _hotkeys[id] = nil
end

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for _, h in pairs(_hotkeys) do
        if h and h.enabled and i.KeyCode == h.key then
            pcall(h.cb)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TOOLTIP
-- ══════════════════════════════════════════════════════════════
local _tooltipGui, _tooltipFrame, _tooltipLbl

local function _initTooltip()
    if _tooltipGui then return end
    _tooltipGui = Instance.new("ScreenGui")
    _tooltipGui.Name          = "VoidUI_Tooltip"
    _tooltipGui.ResetOnSpawn  = false
    _tooltipGui.IgnoreGuiInset = true
    _tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _tooltipGui.Parent = LP.PlayerGui

    _tooltipFrame = frm(_tooltipGui, UDim2.new(0, 10, 0, 24), UDim2.new(0, 0, 0, 0), T.BgLight, 0)
    _tooltipFrame.Visible = false
    _tooltipFrame.ZIndex  = 50
    corner(_tooltipFrame, 5)
    stroke(_tooltipFrame, T.Border, 1, 0)
    pad(_tooltipFrame, 4, 8, 4, 8)

    _tooltipLbl = lbl(_tooltipFrame, "", 10, T.TextSub, Enum.Font.Gotham)
    _tooltipLbl.Size             = UDim2.new(1, 0, 1, 0)
    _tooltipLbl.ZIndex           = 51
    _tooltipLbl.TextXAlignment   = Enum.TextXAlignment.Center
end

local function attachTooltip(obj, text)
    _initTooltip()
    obj.MouseEnter:Connect(function()
        _tooltipLbl.Text = text
        local w = #text * 6.5 + 20
        _tooltipFrame.Size    = UDim2.new(0, w, 0, 24)
        _tooltipFrame.Visible = true
        _tooltipFrame.BackgroundTransparency = 1
        tw(_tooltipFrame, { BackgroundTransparency = 0 }, TI.Fast)
    end)
    obj.MouseLeave:Connect(function()
        _tooltipFrame.Visible = false
    end)
    RunService.RenderStepped:Connect(function()
        if _tooltipFrame.Visible then
            local mp = UserInputService:GetMouseLocation()
            _tooltipFrame.Position = UDim2.new(0, mp.X + 14, 0, mp.Y + 8)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  КОНТЕКСТНОЕ МЕНЮ
-- ══════════════════════════════════════════════════════════════
local _ctxGui
local function _destroyCtx()
    if _ctxGui then _ctxGui:Destroy(); _ctxGui = nil end
end

local function showContextMenu(items, x, y)
    _destroyCtx()
    _ctxGui = Instance.new("ScreenGui")
    _ctxGui.Name           = "VoidUI_Ctx"
    _ctxGui.ResetOnSpawn   = false
    _ctxGui.IgnoreGuiInset = true
    _ctxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _ctxGui.Parent = LP.PlayerGui

    local menuH = #items * 30 + 8
    local mf2   = frm(_ctxGui, UDim2.new(0, 160, 0, menuH), UDim2.new(0, x, 0, y), T.BgLight, 0)
    mf2.ZIndex = 40
    corner(mf2, 8); stroke(mf2, T.Border, 1, 0)
    pad(mf2, 4, 4, 4, 4); lst(mf2, 2)

    mf2.Size = UDim2.new(0, 160, 0, 0)
    tw(mf2, { Size = UDim2.new(0, 160, 0, menuH) }, TI.Spring)

    for _, item in ipairs(items) do
        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3       = T.BgElement
        btn.BackgroundTransparency = 0
        btn.Text             = ""
        btn.BorderSizePixel  = 0
        btn.ZIndex           = 41
        btn.Parent           = mf2
        corner(btn, 5)

        local il = lbl(btn, item.icon and (item.icon .. " ") or "", 11, T.Accent, Enum.Font.GothamMedium)
        il.Size = UDim2.new(0, 22, 1, 0); il.Position = UDim2.new(0, 6, 0, 0)
        il.TextXAlignment = Enum.TextXAlignment.Center; il.ZIndex = 42

        local tl2 = lbl(btn, item.label or "", 11, T.TextSub, Enum.Font.Gotham)
        tl2.Size = UDim2.new(1, -32, 1, 0); tl2.Position = UDim2.new(0, 28, 0, 0)
        tl2.ZIndex = 42

        btn.MouseEnter:Connect(function()
            tw(btn, { BackgroundColor3 = T.BgHover }, TI.Fast)
            tw(tl2, { TextColor3 = T.TextPrimary }, TI.Fast)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, { BackgroundColor3 = T.BgElement }, TI.Fast)
            tw(tl2, { TextColor3 = T.TextSub }, TI.Fast)
        end)
        btn.MouseButton1Click:Connect(function()
            _destroyCtx()
            if item.cb then item.cb() end
        end)
    end

    local closeConn
    closeConn = UserInputService.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            task.defer(function()
                _destroyCtx()
                closeConn:Disconnect()
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  VOIDUI OBJECT
-- ══════════════════════════════════════════════════════════════
local VoidUI = {}
VoidUI.__index = VoidUI
VoidUI.Version = "5.0.0"
VoidUI.Author  = "Arx2d"
VoidUI.Flags   = {}
VoidUI.Theme   = T
VoidUI.Themes  = THEMES

-- ══════════════════════════════════════════════════════════════
--  МОДУЛЬНАЯ СИСТЕМА
-- ══════════════════════════════════════════════════════════════
VoidUI._modules = {}

-- Динамическая подгрузка внешнего модуля по URL.
-- Модуль должен принимать VoidUI как аргумент и возвращать таблицу.
-- Пример: loadstring(game:HttpGet("..."))()
function VoidUI:LoadModule(url)
    assert(type(url) == "string", "LoadModule: url должен быть строкой")
    if self._modules[url] then return self._modules[url] end
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))(self)
    end)
    if not ok then
        warn("[VoidUI] LoadModule failed:", url, result)
        return nil
    end
    self._modules[url] = result
    return result
end

-- ══════════════════════════════════════════════════════════════
--  NOTIFY
-- ══════════════════════════════════════════════════════════════
local _ng, _nh, _ns = nil, nil, {}

local function _initN()
    if _ng then return end
    _ng = Instance.new("ScreenGui")
    _ng.Name           = "VoidUI_N"
    _ng.ResetOnSpawn   = false
    _ng.IgnoreGuiInset = true
    _ng.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _ng.Parent = LP.PlayerGui

    _nh = frm(_ng, UDim2.new(0, 310, 1, 0), UDim2.new(1, -326, 0, 0), T.Bg, 1)
    local u = lst(_nh, 7)
    u.VerticalAlignment = Enum.VerticalAlignment.Bottom
    pad(_nh, 0, 0, 14, 0)
end

function VoidUI:Notify(opts)
    _initN()
    local title   = opts.Title    or "Void UI"
    local content = opts.Content  or ""
    local dur     = opts.Duration or 4
    local ntype   = opts.Type     or "info"
    local cols    = { info = T.Info, success = T.Success, warning = T.Warning, error = T.Error }
    local icons   = { info = "ℹ",   success = "✓",        warning = "⚠",       error = "✕" }
    local ac      = cols[ntype] or T.Info

    if #_ns >= 5 then
        local o = table.remove(_ns, 1)
        if o and o.Parent then
            tw(o, { Position = UDim2.new(1, 12, 0, o.Position.Y.Offset) }, TI.Fast)
            task.delay(0.2, function() if o.Parent then o:Destroy() end end)
        end
    end

    local nf = frm(_nh, UDim2.new(1, 0, 0, 76), nil, T.BgLight, 0)
    nf.ClipsDescendants = true
    nf.LayoutOrder      = tick()
    corner(nf, 10); stroke(nf, ac, 1, 0.45)

    local ab = frm(nf, UDim2.new(0, 3, 0.7, 0), UDim2.new(0, 0, 0.15, 0), ac, 0); corner(ab, 3)
    grad(ab, { T.AccentLight, ac }, 90)

    local icf = frm(nf, UDim2.new(0, 30, 0, 30), UDim2.new(0, 14, 0, 10), T.AccentFaded, 0); corner(icf, 8)
    local icl = lbl(icf, icons[ntype] or "·", 14, ac, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    icl.Size = UDim2.new(1, 0, 1, 0)

    local tl = lbl(nf, title, 13, T.TextPrimary, Enum.Font.GothamBold)
    tl.Size = UDim2.new(1, -58, 0, 18); tl.Position = UDim2.new(0, 52, 0, 10)

    local cl = lbl(nf, content, 11, T.TextSub, Enum.Font.Gotham)
    cl.Size        = UDim2.new(1, -58, 0, 30); cl.Position = UDim2.new(0, 52, 0, 30)
    cl.TextWrapped = true; cl.TextTruncate = Enum.TextTruncate.None

    local pbg = frm(nf, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), T.Border, 0)
    local pb  = frm(pbg, UDim2.new(1, 0, 1, 0), nil, ac, 0)
    grad(pb, { T.AccentLight, ac }, 0)

    nf.Position = UDim2.new(1, 14, 0, 0)
    tw(nf, { Position = UDim2.new(0, 0, 0, 0) }, TI.Spring)
    table.insert(_ns, nf)
    tw(pb, { Size = UDim2.new(0, 0, 1, 0) }, TweenInfo.new(dur, Enum.EasingStyle.Linear))

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size                   = UDim2.new(0, 18, 0, 18)
    closeBtn.Position               = UDim2.new(1, -24, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text      = "✕"; closeBtn.TextSize = 10
    closeBtn.TextColor3 = T.TextMuted
    closeBtn.Font      = Enum.Font.GothamBold
    closeBtn.Parent    = nf

    local function dismiss()
        tw(nf, { Position = UDim2.new(1, 14, 0, 0), BackgroundTransparency = 1 }, TI.Mid)
        task.wait(0.25)
        local idx = table.find(_ns, nf)
        if idx then table.remove(_ns, idx) end
        if nf.Parent then nf:Destroy() end
    end
    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(dur, dismiss)
end

-- ══════════════════════════════════════════════════════════════
--  STATS OVERLAY
-- ══════════════════════════════════════════════════════════════
local _statGui
function VoidUI:CreateStatsOverlay(opts)
    opts = opts or {}
    if _statGui then _statGui:Destroy() end

    _statGui = Instance.new("ScreenGui")
    _statGui.Name           = "VoidUI_Stats"
    _statGui.ResetOnSpawn   = false
    _statGui.IgnoreGuiInset = true
    _statGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _statGui.Parent = LP.PlayerGui

    local W, H   = 200, 56
    local topInset = getSafeInset()
    local vp     = workspace.CurrentCamera.ViewportSize

    -- Позиция с учётом safe zone
    local sf = frm(_statGui,
        UDim2.new(0, W, 0, H),
        UDim2.new(0, vp.X - W - 14, 0, vp.Y - H - 14),
        T.BgLight, 0)
    corner(sf, 10); stroke(sf, T.Border, 1, 0.2)

    local topBar = frm(sf, UDim2.new(1, 0, 0, 2), nil, T.Accent, 0); corner(topBar, 10)
    grad(topBar, { T.AccentLight, T.Accent, T.AccentDark }, 0)

    local fpsBlock = frm(sf, UDim2.new(0.5, -1, 1, -4), UDim2.new(0, 4, 0, 4), T.Bg, 0); corner(fpsBlock, 7)
    local fpsIcon  = lbl(fpsBlock, "FPS", 8, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    fpsIcon.Size = UDim2.new(1, 0, 0, 14); fpsIcon.Position = UDim2.new(0, 0, 0, 4)
    local fpsVal = lbl(fpsBlock, "...", 18, T.TextAccent, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    fpsVal.Size = UDim2.new(1, 0, 0, 24); fpsVal.Position = UDim2.new(0, 0, 0, 16)

    frm(sf, UDim2.new(0, 1, 0, 36), UDim2.new(0.5, -0.5, 0, 10), T.Sep, 0)

    local pingBlock = frm(sf, UDim2.new(0.5, -5, 1, -4), UDim2.new(0.5, 1, 0, 4), T.Bg, 0); corner(pingBlock, 7)
    local pingIcon  = lbl(pingBlock, "PING", 8, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    pingIcon.Size = UDim2.new(1, 0, 0, 14); pingIcon.Position = UDim2.new(0, 0, 0, 4)
    local pingVal = lbl(pingBlock, "...", 18, T.Success, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    pingVal.Size = UDim2.new(1, 0, 0, 24); pingVal.Position = UDim2.new(0, 0, 0, 16)

    -- Перетаскивание с clamping
    local drag2, dStart, dOrigin = false, nil, nil
    sf.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag2 = true; dStart = i.Position; dOrigin = sf.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag2 and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d   = i.Position - dStart
            local cvp = workspace.CurrentCamera.ViewportSize
            sf.Position = UDim2.new(0,
                math.clamp(dOrigin.X.Offset + d.X, 0, cvp.X - W), 0,
                math.clamp(dOrigin.Y.Offset + d.Y, 0, cvp.Y - H))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag2 = false end
    end)

    local fc, ft, pingTimer = 0, os.clock(), 0
    local function getPing()
        local ok, p = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        return ok and math.round(p) or 0
    end

    RunService.Heartbeat:Connect(function(dt)
        fc += 1
        local now = os.clock()
        if now - ft >= 0.5 then
            local fps = math.round(fc / (now - ft)); fc = 0; ft = now
            fpsVal.Text       = tostring(fps)
            fpsVal.TextColor3 = fps >= 55 and T.Success or fps >= 30 and T.Warning or T.Error
        end
        pingTimer += dt
        if pingTimer >= 1 then
            pingTimer = 0
            local p = getPing()
            pingVal.Text       = tostring(p) .. "ms"
            pingVal.TextColor3 = p < 80 and T.Success or p < 150 and T.Warning or T.Error
        end
    end)

    local obj = {}
    function obj:Toggle(v) sf.Visible = v end
    function obj:Destroy() _statGui:Destroy() end
    return obj
end

-- ══════════════════════════════════════════════════════════════
--  WATERMARK
-- ══════════════════════════════════════════════════════════════
local _wmg
function VoidUI:CreateWatermark(opts)
    if _wmg then _wmg:Destroy() end
    local text = opts.Text or "VOID UI"
    local show = opts.Enabled ~= false
    _wmg = Instance.new("ScreenGui")
    _wmg.Name = "VoidUI_WM"; _wmg.ResetOnSpawn = false
    _wmg.IgnoreGuiInset = true; _wmg.Parent = LP.PlayerGui

    local topInset = getSafeInset()
    local safeTop  = math.max(topInset.Y, 14)

    local wf = frm(_wmg, UDim2.new(0, 220, 0, 32), UDim2.new(0, 14, 0, safeTop), T.BgLight, 0)
    wf.Visible = show; corner(wf, 8); stroke(wf, T.Border, 1, 0)
    local bar  = frm(wf, UDim2.new(0, 2, 0, 20), UDim2.new(0, 8, 0.5, -10), T.Accent, 0)
    corner(bar, 2); grad(bar, { T.AccentLight, T.Accent }, 90)
    local wl = lbl(wf, text, 11, T.TextSub, Enum.Font.GothamMedium)
    wl.Size = UDim2.new(1, -20, 1, 0); wl.Position = UDim2.new(0, 18, 0, 0)

    local fc2, ft2, fps2 = 0, os.clock(), 60
    RunService.Heartbeat:Connect(function()
        fc2 += 1
        local n = os.clock()
        if n - ft2 >= 0.5 then fps2 = math.round(fc2 / (n - ft2)); fc2 = 0; ft2 = n end
        wl.Text       = text .. "  ·  " .. fps2 .. " fps"
        wl.TextColor3 = fps2 >= 55 and T.TextSub or fps2 >= 30 and T.Warning or T.Error
    end)

    local obj = {}
    function obj:SetText(t) text = t end
    function obj:Toggle(v) wf.Visible = v end
    function obj:Destroy() _wmg:Destroy() end
    return obj
end

-- ══════════════════════════════════════════════════════════════
--  LOADING SCREEN
-- ══════════════════════════════════════════════════════════════
local function _loadScreen(opts)
    local title = opts.LoadingTitle    or "VOID UI"
    local sub   = opts.LoadingSubtitle or ""
    local steps = opts.LoadingSteps    or { "Initializing...", "Building UI...", "Ready!" }
    local logo  = opts.Logo            or "VOID"

    local sg = Instance.new("ScreenGui")
    sg.Name = "VoidUI_Load"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP.PlayerGui

    local bg   = frm(sg, UDim2.new(1, 0, 1, 0), nil, Color3.fromRGB(4, 4, 8), 1)
    local card = frm(sg, UDim2.new(0, 420, 0, 250), UDim2.new(0.5, -210, 0.5, -125), T.Bg, 1)
    corner(card, 14); stroke(card, T.Border, 1, 0)

    local tl2 = frm(card, UDim2.new(1, 0, 0, 3), nil, T.Accent, 0); corner(tl2, 14)
    grad(tl2, { T.AccentLight, T.Accent, T.AccentDark }, 0)

    local ll = lbl(card, logo, 38, T.TextPrimary, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    ll.Size = UDim2.new(1, 0, 0, 58); ll.Position = UDim2.new(0, 0, 0, 26)
    grad(ll, { T.AccentLight, T.Accent }, 90)

    local ttl = lbl(card, title, 15, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    ttl.Size = UDim2.new(1, -32, 0, 22); ttl.Position = UDim2.new(0, 16, 0, 92)

    local stl = lbl(card, sub, 11, T.TextSub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    stl.Size = UDim2.new(1, -32, 0, 16); stl.Position = UDim2.new(0, 16, 0, 114)

    frm(card, UDim2.new(1, -32, 0, 1), UDim2.new(0, 16, 0, 138), T.Sep, 0)

    local stp = lbl(card, steps[1], 11, T.TextAccent, Enum.Font.Code, Enum.TextXAlignment.Center)
    stp.Size = UDim2.new(1, -32, 0, 16); stp.Position = UDim2.new(0, 16, 0, 148)

    local pbg = frm(card, UDim2.new(1, -32, 0, 6), UDim2.new(0, 16, 0, 172), T.BgElement, 0); corner(pbg, 6)
    local pb  = frm(pbg, UDim2.new(0, 0, 1, 0), nil, T.Accent, 0); corner(pb, 6)
    grad(pb, { T.AccentLight, T.Accent }, 0)

    local vl2 = lbl(card, "void ui v" .. VoidUI.Version, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    vl2.Size = UDim2.new(1, -32, 0, 14); vl2.Position = UDim2.new(0, 16, 0, 198)

    tw(bg, { BackgroundTransparency = 0.22 }, TI.Mid)
    tw(card, { BackgroundTransparency = 0 }, TI.Spring)

    local n = #steps
    for i, step in ipairs(steps) do
        stp.Text = step
        tw(pb, { Size = UDim2.new(i / n, 0, 1, 0) },
            TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        task.wait(0.28)
    end
    task.wait(0.18)
    tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, -210, 0.42, -125) }, TI.Mid)
    tw(bg,   { BackgroundTransparency = 1 }, TI.Mid)
    task.wait(0.26); sg:Destroy()
end

-- ══════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ══════════════════════════════════════════════════════════════
function VoidUI:CreateWindow(opts)
    local winName   = opts.Name            or "VOID UI"
    local lTitle    = opts.LoadingTitle    or winName
    local lSub      = opts.LoadingSubtitle or ""
    local lSteps    = opts.LoadingSteps
    local lLogo     = opts.Logo            or "VOID"
    local cfgOpts   = opts.ConfigurationSaving or {}
    local cfgFile   = cfgOpts.FileName  or "config"
    local cfgOn     = cfgOpts.Enabled  ~= false
    local tKey      = opts.ToggleKey    or Enum.KeyCode.RightShift
    local themeName = opts.Theme        or "Void"

    -- Размеры окна — Scale + UISizeConstraint
    local maxW = (opts.Size and opts.Size.Width)  or 660
    local maxH = (opts.Size and opts.Size.Height) or 460
    local minW = 280
    local minH = 200

    applyTheme(themeName)
    if opts.Accent then applyAccent(opts.Accent) end

    task.spawn(_loadScreen, {
        LoadingTitle    = lTitle,
        LoadingSubtitle = lSub,
        LoadingSteps    = lSteps,
        Logo            = lLogo,
    })
    task.wait((#(lSteps or { "", "", "" }) * 0.28) + 0.60)

    local saved = cfgOn and cfgLoad(cfgFile) or {}

    local sg = Instance.new("ScreenGui")
    sg.Name           = "VoidUI_Main"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP.PlayerGui

    -- ── Главный фрейм (Scale-only позиция, центр экрана) ──────
    -- Размер через Scale, ограничен UISizeConstraint
    local mf = Instance.new("Frame")
    mf.AnchorPoint            = Vector2.new(0.5, 0.5)
    mf.Position               = UDim2.new(0.5, 0, 0.5, 0)
    mf.Size                   = UDim2.new(0.88, 0, 0.82, 0)   -- scale relative
    mf.BackgroundColor3       = T.Bg
    mf.BackgroundTransparency = 0
    mf.BorderSizePixel        = 0
    mf.Parent = sg
    corner(mf, 12); stroke(mf, T.Border, 1, 0)

    -- UISizeConstraint: зажимаем окно между minW/minH и maxW/maxH
    local sc = Instance.new("UISizeConstraint")
    sc.MinSize = Vector2.new(minW, minH)
    sc.MaxSize = Vector2.new(maxW, maxH)
    sc.Parent  = mf

    -- Свечение
    local glw = Instance.new("ImageLabel")
    glw.Size               = UDim2.new(1, 90, 1, 90)
    glw.Position           = UDim2.new(0, -45, 0, -45)
    glw.BackgroundTransparency = 1
    glw.Image              = "rbxassetid://5028857084"
    glw.ImageColor3        = T.Accent
    glw.ImageTransparency  = 0.88
    glw.ScaleType          = Enum.ScaleType.Slice
    glw.SliceCenter        = Rect.new(24, 24, 276, 276)
    glw.ZIndex = 0; glw.Parent = mf

    -- Тайтл-бар
    local tb = frm(mf, UDim2.new(1, 0, 0, 42), nil, T.BgLight, 0); corner(tb, 12)
    frm(tb, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 1, -14), T.BgLight, 0)
    local tbLine = frm(tb, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), T.Accent, 0.42)
    grad(tbLine, { Color3.new(0, 0, 0), T.Accent, T.AccentLight, T.Accent, Color3.new(0, 0, 0) }, 0)

    local logoL = lbl(tb, "VOID", 16, T.Accent, Enum.Font.GothamBlack)
    logoL.Size = UDim2.new(0, 50, 1, 0); logoL.Position = UDim2.new(0, 14, 0, 0)
    local nameL = lbl(tb, winName, 13, T.TextSub, Enum.Font.GothamMedium)
    nameL.Size = UDim2.new(1, -220, 1, 0); nameL.Position = UDim2.new(0, 66, 0, 0)

    local verTL = lbl(tb, "v" .. VoidUI.Version, 10, T.TextMuted, Enum.Font.Code, Enum.TextXAlignment.Right)
    verTL.Size = UDim2.new(0, 60, 1, 0); verTL.Position = UDim2.new(1, -155, 0, 0)

    local function ctrlBtn(txt, xo, hc)
        local b = Instance.new("TextButton")
        b.Size              = UDim2.new(0, 28, 0, 22)
        b.Position          = UDim2.new(1, xo, 0.5, -11)
        b.BackgroundColor3  = T.BgElement
        b.Text              = txt
        b.Font              = Enum.Font.GothamBold
        b.TextSize          = 12
        b.TextColor3        = T.TextMuted
        b.BorderSizePixel   = 0
        b.Parent = tb
        corner(b, 6); stroke(b, T.Border, 1, 0.25)
        b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = hc, TextColor3 = T.TextPrimary }, TI.Fast) end)
        b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = T.BgElement, TextColor3 = T.TextMuted }, TI.Fast) end)
        return b
    end

    local closeBtn = ctrlBtn("✕", -14, T.Error)
    local minBtn   = ctrlBtn("─", -48, T.AccentDark)
    local pinBtn   = ctrlBtn("📌", -82, T.AccentFaded)

    -- Боковая панель
    local sb = frm(mf, UDim2.new(0, 154, 1, -42), UDim2.new(0, 0, 0, 42), T.BgTab, 0)
    pad(sb, 8, 6, 28, 6); lst(sb, 4)
    frm(mf, UDim2.new(0, 1, 1, -42), UDim2.new(0, 154, 0, 42), T.Sep, 0)

    -- Поиск
    local searchBg = frm(sb, UDim2.new(1, 0, 0, 28), nil, T.BgInput, 0); corner(searchBg, 7)
    stroke(searchBg, T.Border, 1, 0.3)
    local searchBox = Instance.new("TextBox")
    searchBox.Size                   = UDim2.new(1, -22, 1, 0)
    searchBox.Position               = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text                   = ""
    searchBox.PlaceholderText        = "🔍 Поиск..."
    searchBox.Font                   = Enum.Font.Gotham
    searchBox.TextSize               = 10
    searchBox.TextColor3             = T.TextPrimary
    searchBox.PlaceholderColor3      = T.TextMuted
    searchBox.ClearTextOnFocus       = false
    searchBox.Parent = searchBg

    local searchCount = lbl(searchBg, "", 9, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Right)
    searchCount.Size = UDim2.new(0, 18, 1, 0); searchCount.Position = UDim2.new(1, -20, 0, 0)

    local verL = lbl(sb, "v" .. VoidUI.Version, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    verL.Size = UDim2.new(1, 0, 0, 16); verL.Position = UDim2.new(0, 0, 1, -22); verL.ZIndex = 2

    -- Контент-область
    local ca = Instance.new("Frame")
    ca.Size                   = UDim2.new(1, -155, 1, -42)
    ca.Position               = UDim2.new(0, 155, 0, 42)
    ca.BackgroundTransparency = 1
    ca.ClipsDescendants       = true
    ca.Parent = mf

    -- ── Перетаскивание (пиксельный clamp, Scale-позиция → нужно конвертировать) ──
    local drag2, dStartPos, dStartAbs = false, nil, nil
    local minimized = false

    tb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag2    = true
            dStartPos = i.Position
            dStartAbs = mf.AbsolutePosition
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag2 and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d   = i.Position - dStartPos
            local cvp = workspace.CurrentCamera.ViewportSize
            local absW = mf.AbsoluteSize.X
            local absH = mf.AbsoluteSize.Y
            local newX = math.clamp(dStartAbs.X + d.X, 0, cvp.X - absW)
            local newY = math.clamp(dStartAbs.Y + d.Y, 0, cvp.Y - absH)
            -- Переводим в Scale+Offset = чистый Offset от (0,0)
            mf.AnchorPoint = Vector2.new(0, 0)
            mf.Position    = UDim2.new(0, newX, 0, newY)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag2 = false end
    end)

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        sb.Visible = not minimized; ca.Visible = not minimized
        -- При минимизации убираем Size constraint Y
        if minimized then
            sc.MinSize = Vector2.new(minW, 42)
            sc.MaxSize = Vector2.new(maxW, 42)
        else
            sc.MinSize = Vector2.new(minW, minH)
            sc.MaxSize = Vector2.new(maxW, maxH)
        end
        minBtn.Text = minimized and "□" or "─"
    end)

    local pinned = false
    pinBtn.MouseButton1Click:Connect(function()
        pinned = not pinned
        tw(pinBtn, { BackgroundColor3 = pinned and T.AccentFaded or T.BgElement }, TI.Fast)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        tw(mf, { BackgroundTransparency = 1, Size = UDim2.new(0, mf.AbsoluteSize.X, 0, 8) }, TI.Mid)
        task.wait(0.26); sg:Destroy()
    end)

    registerHotkey(tKey, "Toggle UI", function()
        mf.Visible = not mf.Visible
        if mf.Visible then tw(mf, { BackgroundTransparency = 0 }, TI.Fast) end
    end)

    -- ── Win object ────────────────────────────────────────────
    local Win = {}
    Win._tabs     = {}
    Win._active   = nil
    Win._cfgFile  = cfgFile
    Win._cfgOn    = cfgOn
    Win._saved    = saved
    Win._allElems = {}
    Win._hotkeys  = {}
    Win._sg       = sg
    Win._mf       = mf

    function Win:SaveConfig()
        if self._cfgOn then cfgSave(self._cfgFile, VoidUI.Flags) end
    end

    function Win:SetTheme(name)
        applyTheme(name)
        glw.ImageColor3   = T.Accent
        logoL.TextColor3  = T.Accent
    end

    function Win:SetAccent(color)
        applyAccent(color)
        glw.ImageColor3   = T.Accent
        logoL.TextColor3  = T.Accent
    end

    function Win:Notify(o) VoidUI:Notify(o) end
    function Win:Destroy() sg:Destroy() end

    function Win:RegisterHotkey(key, label, cb)
        local id = registerHotkey(key, label, cb)
        table.insert(self._hotkeys, id)
        return id
    end

    -- Поиск по элементам
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q     = searchBox.Text:lower()
        local count = 0
        for _, info in ipairs(Win._allElems) do
            if q == "" then
                info.frame.Visible = true
            else
                local found = info.name:lower():find(q, 1, true) ~= nil
                info.frame.Visible = found
                if found then count += 1 end
            end
        end
        searchCount.Text = q ~= "" and tostring(count) or ""
    end)

    -- ════════════════════════════════════════════════════════
    --  CREATE TAB
    -- ════════════════════════════════════════════════════════
    function Win:CreateTab(name, icon, badge)
        local tabMaid = Maid.new()   -- GC для этой вкладки

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size             = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundColor3 = T.BgTab
        tabBtn.Text             = ""
        tabBtn.BorderSizePixel  = 0
        tabBtn.LayoutOrder      = #self._tabs + 2
        tabBtn.Parent = sb
        corner(tabBtn, 7)

        local stripe = frm(tabBtn, UDim2.new(0, 3, 0, 22), UDim2.new(0, 0, 0.5, -11), T.Accent, 1); corner(stripe, 3)
        local iconL  = lbl(tabBtn, icon or "", 15, T.TextMuted, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
        iconL.Size = UDim2.new(0, 24, 1, 0); iconL.Position = UDim2.new(0, 8, 0, 0)
        local nL = lbl(tabBtn, name, 12, T.TextMuted, Enum.Font.GothamMedium)
        nL.Size = UDim2.new(1, -46, 1, 0); nL.Position = UDim2.new(0, icon and 34 or 12, 0, 0)

        local badgeL
        if badge then
            local bF = frm(tabBtn, UDim2.new(0, 18, 0, 14), UDim2.new(1, -22, 0.5, -7), T.Accent, 0); corner(bF, 7)
            badgeL = lbl(bF, tostring(badge), 9, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
            badgeL.Size = UDim2.new(1, 0, 1, 0)
        end

        -- ScrollingFrame для контента вкладки
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size                   = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel        = 0
        scroll.ScrollBarThickness     = 4
        scroll.ScrollBarImageColor3   = T.ScrollBar
        scroll.ScrollBarImageTransparency = 0.3
        -- AutomaticCanvasSize вместо ручного управления
        scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
        scroll.Visible  = false
        scroll.Parent   = ca

        local scrollLayout = lst(scroll, 5)
        pad(scroll, 10, 14, 10, 12)

        -- bindCanvas привязывает CanvasSize к реальному контенту
        bindCanvas(scroll, scrollLayout)

        tabMaid:Add(scroll.MouseEnter:Connect(function()
            tw(scroll, { ScrollBarImageTransparency = 0 }, TI.Fast)
        end))
        tabMaid:Add(scroll.MouseLeave:Connect(function()
            tw(scroll, { ScrollBarImageTransparency = 0.3 }, TI.Fast)
        end))

        tabMaid:Add(tabBtn.MouseEnter:Connect(function()
            if self._active ~= scroll then
                tw(tabBtn, { BackgroundColor3 = T.BgHover }, TI.Fast)
                tw(nL, { TextColor3 = T.TextSub }, TI.Fast)
            end
        end))
        tabMaid:Add(tabBtn.MouseLeave:Connect(function()
            if self._active ~= scroll then
                tw(tabBtn, { BackgroundColor3 = T.BgTab }, TI.Fast)
                tw(nL, { TextColor3 = T.TextMuted }, TI.Fast)
            end
        end))

        local function activate()
            for _, t in ipairs(self._tabs) do
                t.sc.Visible = false
                tw(t.btn, { BackgroundColor3 = T.BgTab }, TI.Fast)
                tw(t.nL,  { TextColor3 = T.TextMuted }, TI.Fast)
                tw(t.iL,  { TextColor3 = T.TextMuted }, TI.Fast)
                tw(t.str, { BackgroundTransparency = 1 }, TI.Fast)
            end
            scroll.Visible = true; self._active = scroll
            tw(tabBtn, { BackgroundColor3 = T.BgHover }, TI.Fast)
            tw(nL,     { TextColor3 = T.TextAccent }, TI.Fast)
            tw(iconL,  { TextColor3 = T.Accent }, TI.Fast)
            tw(stripe, { BackgroundTransparency = 0 }, TI.Fast)
        end

        tabMaid:Add(tabBtn.MouseButton1Click:Connect(function()
            activate()
            local x, y = mrel(tabBtn); ripple(tabBtn, x, y)
        end))

        table.insert(self._tabs, { sc = scroll, btn = tabBtn, nL = nL, iL = iconL, str = stripe })
        if #self._tabs == 1 then task.defer(activate) end

        -- ── Tab object ────────────────────────────────────────
        local Tab = {}; Tab._lo = 0; Tab._win = self; Tab._maid = tabMaid

        local function lo() Tab._lo += 1; return Tab._lo end

        -- elem: контейнер элемента с AutomaticSize.Y
        local function elem(minH2, hasDesc, noHover, noFade)
            local baseH = hasDesc and (minH2 + 20) or minH2
            local c = frm(scroll, UDim2.new(1, 0, 0, baseH), nil, T.BgElement, noFade and 0 or 1)
            c.LayoutOrder    = lo()
            c.ClipsDescendants = true
            -- AutomaticSize по Y: контейнер растягивается под контент
            c.AutomaticSize  = Enum.AutomaticSize.Y
            corner(c, 7); stroke(c, T.Border, 1, 0.4)
            if not noFade then
                task.defer(function()
                    tw(c, { BackgroundTransparency = 0 }, TI.Mid)
                end)
            end
            if not noHover then
                tabMaid:Add(c.MouseEnter:Connect(function() tw(c, { BackgroundColor3 = T.BgHover }, TI.Fast) end))
                tabMaid:Add(c.MouseLeave:Connect(function() tw(c, { BackgroundColor3 = T.BgElement }, TI.Fast) end))
            end
            return c
        end

        local function reg(c, n)
            table.insert(Win._allElems, { frame = c, name = n or "" })
        end

        -- ── Section ──────────────────────────────────────────
        function Tab:CreateSection(text)
            local sf = frm(scroll, UDim2.new(1, 0, 0, 22), nil, T.Bg, 1); sf.LayoutOrder = lo()
            frm(sf, UDim2.new(0.36, -6, 0, 1), UDim2.new(0, 0, 0.5, 0), T.Sep, 0)
            frm(sf, UDim2.new(0.36, -6, 0, 1), UDim2.new(0.64, 6, 0.5, 0), T.Sep, 0)
            local sl = lbl(sf, text:upper(), 9, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
            sl.Size = UDim2.new(0.28, 0, 1, 0); sl.Position = UDim2.new(0.36, 0, 0, 0)
        end

        -- ── Separator ────────────────────────────────────────
        function Tab:CreateSeparator()
            local sf = frm(scroll, UDim2.new(1, 0, 0, 1), nil, T.Sep, 0); sf.LayoutOrder = lo()
        end

        -- ── Divider ──────────────────────────────────────────
        function Tab:CreateDivider(text)
            if text then
                local df = frm(scroll, UDim2.new(1, 0, 0, 18), nil, T.Bg, 1); df.LayoutOrder = lo()
                frm(df, UDim2.new(0.38, -6, 0, 1), UDim2.new(0, 0, 0.5, 0), T.Sep, 0)
                frm(df, UDim2.new(0.38, -6, 0, 1), UDim2.new(0.62, 6, 0.5, 0), T.Sep, 0)
                local dl = lbl(df, text, 9, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
                dl.Size = UDim2.new(0.24, 0, 1, 0); dl.Position = UDim2.new(0.38, 0, 0, 0)
            else
                local df = frm(scroll, UDim2.new(1, 0, 0, 1), nil, T.Sep, 0); df.LayoutOrder = lo()
            end
        end

        -- ── Label ────────────────────────────────────────────
        function Tab:CreateLabel(text, color, size)
            local lf = frm(scroll, UDim2.new(1, 0, 0, 22), nil, T.Bg, 1); lf.LayoutOrder = lo()
            local ll2 = lbl(lf, text or "", size or 11, color or T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
            ll2.Size = UDim2.new(1, 0, 1, 0); ll2.TextWrapped = true
            return ll2
        end

        -- ── Alert ────────────────────────────────────────────
        function Tab:CreateAlert(opts2)
            local aType = opts2.Type or "info"
            local cols2 = { info = T.Info, success = T.Success, warning = T.Warning, error = T.Error }
            local icons2 = { info = "ℹ", success = "✓", warning = "⚠", error = "✕" }
            local ac2   = cols2[aType] or T.Info
            local c = frm(scroll, UDim2.new(1, 0, 0, 48), nil, T.BgElement, 1)
            c.LayoutOrder = lo(); corner(c, 7); stroke(c, ac2, 1, 0.3)
            task.defer(function() tw(c, { BackgroundTransparency = 0 }, TI.Mid) end)
            local sideBar = frm(c, UDim2.new(0, 3, 1, 0), nil, ac2, 0); corner(sideBar, 3)
            local icf2 = frm(c, UDim2.new(0, 24, 0, 24), UDim2.new(0, 12, 0.5, -12), T.AccentFaded, 0); corner(icf2, 6)
            local icl2 = lbl(icf2, icons2[aType] or "·", 12, ac2, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
            icl2.Size = UDim2.new(1, 0, 1, 0)
            local tl3 = lbl(c, opts2.Title   or "", 12, T.TextPrimary, Enum.Font.GothamBold)
            tl3.Size = UDim2.new(1, -52, 0, 16); tl3.Position = UDim2.new(0, 44, 0, 8)
            local cl3 = lbl(c, opts2.Content or "", 10, T.TextSub, Enum.Font.Gotham)
            cl3.Size = UDim2.new(1, -52, 0, 18); cl3.Position = UDim2.new(0, 44, 0, 26)
            cl3.TextWrapped = true; cl3.TextTruncate = Enum.TextTruncate.None
        end

        -- ── Toggle ───────────────────────────────────────────
        function Tab:CreateToggle(opts2)
            local tFlag = opts2.Flag
            local tVal  = (tFlag and Win._saved[tFlag] ~= nil) and Win._saved[tFlag] or (opts2.CurrentValue or false)
            local tDesc = opts2.Description
            local tCb   = opts2.Callback or function() end

            local c   = elem(38, tDesc); local val = tVal; reg(c, opts2.Name)
            if opts2.Tooltip then attachTooltip(c, opts2.Tooltip) end

            local ctxBtn = Instance.new("TextButton")
            ctxBtn.Size = UDim2.new(1, 0, 1, 0); ctxBtn.BackgroundTransparency = 1
            ctxBtn.Text = ""; ctxBtn.Parent = c

            local nl2 = lbl(c, opts2.Name or "Toggle", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(1, -62, 0, 18); nl2.Position = UDim2.new(0, 12, 0, tDesc and 6 or 10)

            if tDesc then
                local dl = lbl(c, tDesc, 10, T.TextMuted)
                dl.Size = UDim2.new(1, -62, 0, 14); dl.Position = UDim2.new(0, 12, 0, 24)
            end

            local tbg = frm(c, UDim2.new(0, 42, 0, 23), UDim2.new(1, -54, 0.5, -11.5), val and T.Accent or T.AccentFaded, 0)
            corner(tbg, 12); stroke(tbg, T.Border, 1, 0.25)
            local th = frm(tbg, UDim2.new(0, 17, 0, 17), val and UDim2.new(1, -20, 0.5, -8.5) or UDim2.new(0, 3, 0.5, -8.5), T.TextPrimary, 0)
            corner(th, 9)
            local sh = frm(th, UDim2.new(0, 6, 0, 6), UDim2.new(0, 2, 0, 2), Color3.new(1, 1, 1), 0.5); corner(sh, 3)

            local function set(v, silent)
                val = v
                tw(tbg, { BackgroundColor3 = v and T.Accent or T.AccentFaded }, TI.Fast)
                tw(th,  { Position = v and UDim2.new(1, -20, 0.5, -8.5) or UDim2.new(0, 3, 0.5, -8.5) }, TI.Fast)
                tw(nl2, { TextColor3 = v and T.TextPrimary or T.TextSub }, TI.Fast)
                if not silent then
                    tCb(v)
                    if tFlag then VoidUI.Flags[tFlag] = v; Win:SaveConfig() end
                end
            end
            set(tVal, true)

            tabMaid:Add(ctxBtn.MouseButton1Click:Connect(function()
                set(not val); local x, y = mrel(c); ripple(c, x, y)
            end))
            tabMaid:Add(ctxBtn.MouseButton2Click:Connect(function()
                local mp = UserInputService:GetMouseLocation()
                showContextMenu({
                    { icon = "✓", label = "Включить",  cb = function() set(true) end },
                    { icon = "✕", label = "Выключить", cb = function() set(false) end },
                    { icon = "↺", label = "Сбросить",  cb = function() set(opts2.CurrentValue or false) end },
                }, mp.X, mp.Y)
            end))

            local obj = {}
            function obj:Set(v) set(v, false) end
            function obj:Get() return val end
            function obj:Toggle() set(not val, false) end
            return obj
        end

        -- ── Slider ───────────────────────────────────────────
        function Tab:CreateSlider(opts2)
            local sFlag = opts2.Flag
            local sRange = opts2.Range or { 0, 100 }
            local sInc   = opts2.Increment or 1
            local sDef   = (sFlag and Win._saved[sFlag]) or opts2.CurrentValue or sRange[1]
            local sSuf   = opts2.Suffix or ""
            local sCb    = opts2.Callback or function() end

            local c   = elem(54); local val = math.clamp(sDef, sRange[1], sRange[2]); reg(c, opts2.Name)
            if opts2.Tooltip then attachTooltip(c, opts2.Tooltip) end

            local nl2 = lbl(c, opts2.Name or "Slider", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(1, -72, 0, 16); nl2.Position = UDim2.new(0, 12, 0, 8)
            local vl = lbl(c, tostring(val) .. sSuf, 13, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            vl.Size = UDim2.new(0, 58, 0, 16); vl.Position = UDim2.new(1, -70, 0, 8)

            local track = frm(c, UDim2.new(1, -24, 0, 6), UDim2.new(0, 12, 0, 36), T.Border, 0); corner(track, 6)
            local fill  = frm(track, UDim2.new(0, 0, 1, 0), nil, T.Accent, 0); corner(fill, 6)
            grad(fill, { T.AccentLight, T.Accent }, 0)
            local thumb = frm(track, UDim2.new(0, 18, 0, 18), UDim2.new(0, -9, 0.5, -9), T.AccentLight, 0)
            corner(thumb, 9); stroke(thumb, T.Accent, 2, 0); thumb.ZIndex = 4

            local tooltip2 = frm(thumb, UDim2.new(0, 44, 0, 20), UDim2.new(0.5, -22, 0, -28), T.BgLight, 0)
            corner(tooltip2, 5); stroke(tooltip2, T.Border, 1, 0); tooltip2.Visible = false
            local ttl2 = lbl(tooltip2, "", 10, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
            ttl2.Size = UDim2.new(1, 0, 1, 0)

            local function upd(v)
                v = math.clamp(math.round(v / sInc) * sInc, sRange[1], sRange[2]); val = v
                local p = (v - sRange[1]) / (sRange[2] - sRange[1])
                tw(fill,  { Size = UDim2.new(p, 0, 1, 0) }, TI.Fast)
                tw(thumb, { Position = UDim2.new(p, -9, 0.5, -9) }, TI.Fast)
                vl.Text = tostring(v) .. sSuf; ttl2.Text = tostring(v) .. sSuf
                sCb(v)
                if sFlag then VoidUI.Flags[sFlag] = v; Win:SaveConfig() end
            end

            local p0 = (val - sRange[1]) / (sRange[2] - sRange[1])
            fill.Size = UDim2.new(p0, 0, 1, 0); thumb.Position = UDim2.new(p0, -9, 0.5, -9)

            local dragS = false
            local function pct(x) return math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1) end

            tabMaid:Add(thumb.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragS = true; tooltip2.Visible = true end
            end))
            tabMaid:Add(track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragS = true; tooltip2.Visible = true
                    upd(sRange[1] + (sRange[2] - sRange[1]) * pct(i.Position.X))
                end
            end))
            tabMaid:Add(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragS = false; tooltip2.Visible = false end
            end))
            tabMaid:Add(UserInputService.InputChanged:Connect(function(i)
                if dragS and i.UserInputType == Enum.UserInputType.MouseMovement then
                    upd(sRange[1] + (sRange[2] - sRange[1]) * pct(i.Position.X))
                end
            end))

            local obj = {}
            function obj:Set(v) upd(v) end
            function obj:Get() return val end
            return obj
        end

        -- ── Button ───────────────────────────────────────────
        function Tab:CreateButton(opts2)
            local bCb   = opts2.Callback or function() end
            local bDesc = opts2.Description
            local c = elem(36, bDesc); c.ClipsDescendants = true; reg(c, opts2.Name)
            if opts2.Tooltip then attachTooltip(c, opts2.Tooltip) end

            local nl2 = lbl(c, opts2.Name or "Button", 12, T.TextPrimary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
            nl2.Size = UDim2.new(1, -32, 0, 18); nl2.Position = UDim2.new(0, 12, 0, bDesc and 6 or 9)

            if bDesc then
                local dl = lbl(c, bDesc, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
                dl.Size = UDim2.new(1, -32, 0, 14); dl.Position = UDim2.new(0, 12, 0, 24)
            end

            local arr = lbl(c, opts2.Icon or "›", 16, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            arr.Size = UDim2.new(0, 18, 1, 0); arr.Position = UDim2.new(1, -24, 0, 0)
            local lstripe = frm(c, UDim2.new(0, 2, 0, 18), UDim2.new(0, 0, 0.5, -9), T.Accent, 1); corner(lstripe, 2)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = c

            tabMaid:Add(btn.MouseEnter:Connect(function()
                tw(nl2,    { TextColor3 = T.TextAccent }, TI.Fast)
                tw(arr,    { TextColor3 = T.Accent }, TI.Fast)
                tw(lstripe, { BackgroundTransparency = 0 }, TI.Fast)
            end))
            tabMaid:Add(btn.MouseLeave:Connect(function()
                tw(nl2,    { TextColor3 = T.TextPrimary }, TI.Fast)
                tw(arr,    { TextColor3 = T.TextMuted }, TI.Fast)
                tw(lstripe, { BackgroundTransparency = 1 }, TI.Fast)
            end))
            tabMaid:Add(btn.MouseButton1Down:Connect(function()
                tw(c, { BackgroundColor3 = T.AccentFaded }, TI.Fast)
            end))
            tabMaid:Add(btn.MouseButton1Click:Connect(function()
                tw(c, { BackgroundColor3 = T.BgHover }, TI.Fast)
                local x, y = mrel(c); ripple(c, x, y); bCb()
            end))
        end

        -- ── Dropdown ─────────────────────────────────────────
        function Tab:CreateDropdown(opts2)
            local dFlag  = opts2.Flag
            local dOpts  = opts2.Options or {}
            local dDef   = (dFlag and Win._saved[dFlag]) or opts2.CurrentOption
            local dCb    = opts2.Callback or function() end
            local dMulti = opts2.Multi or false
            local val    = dDef; local open = false; local sel = {}

            local c = elem(36); c.ClipsDescendants = false; c.ZIndex = 5; reg(c, opts2.Name)

            local nl2 = lbl(c, opts2.Name or "Dropdown", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(0.5, 0, 0, 18); nl2.Position = UDim2.new(0, 12, 0.5, -9)
            local vl = lbl(c, type(val) == "table" and (#val .. " selected") or (val or "Выбрать..."), 11, T.TextAccent, Enum.Font.Gotham, Enum.TextXAlignment.Right)
            vl.Size = UDim2.new(0.4, -8, 0, 18); vl.Position = UDim2.new(0.5, 0, 0.5, -9)
            local al = lbl(c, "▾", 13, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            al.Size = UDim2.new(0, 18, 0, 18); al.Position = UDim2.new(1, -26, 0.5, -9)

            local dd = frm(c, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 5), T.BgLight, 0)
            dd.ClipsDescendants = true; dd.ZIndex = 10; dd.Visible = false
            corner(dd, 7); stroke(dd, T.Border, 1, 0); lst(dd, 2); pad(dd, 4, 4, 4, 4)

            local function refreshVl()
                if dMulti then
                    local s = {}; for o, v2 in pairs(sel) do if v2 then s[#s + 1] = o end end
                    vl.Text = #s > 0 and (#s .. " selected") or "Ничего"
                else
                    vl.Text = val or "Выбрать..."
                end
            end

            for _, opt in ipairs(dOpts) do
                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1, 0, 0, 30); ob.BackgroundColor3 = T.BgLight
                ob.Text = ""; ob.BorderSizePixel = 0; ob.Parent = dd; corner(ob, 5)
                local ol = lbl(ob, opt, 11, opt == val and T.TextAccent or T.TextSub)
                ol.Size = UDim2.new(1, -16, 1, 0); ol.Position = UDim2.new(0, 8, 0, 0)
                ob.MouseEnter:Connect(function() tw(ob, { BackgroundColor3 = T.BgHover }, TI.Fast); tw(ol, { TextColor3 = T.TextPrimary }, TI.Fast) end)
                ob.MouseLeave:Connect(function() tw(ob, { BackgroundColor3 = T.BgLight }, TI.Fast); tw(ol, { TextColor3 = opt == val and T.TextAccent or T.TextSub }, TI.Fast) end)
                ob.MouseButton1Click:Connect(function()
                    if dMulti then
                        sel[opt] = not sel[opt]
                        tw(ol, { TextColor3 = sel[opt] and T.TextAccent or T.TextSub }, TI.Fast)
                        local r = {}; for o2, v2 in pairs(sel) do if v2 then r[#r + 1] = o2 end end
                        val = r; refreshVl(); dCb(r)
                    else
                        val = opt; refreshVl()
                        for _, ch in ipairs(dd:GetChildren()) do
                            if ch:IsA("TextButton") then
                                local cll = ch:FindFirstChildOfClass("TextLabel")
                                if cll then tw(cll, { TextColor3 = T.TextSub }, TI.Fast) end
                            end
                        end
                        tw(ol, { TextColor3 = T.TextAccent }, TI.Fast)
                        open = false
                        tw(dd, { Size = UDim2.new(1, 0, 0, 0) }, TI.Fast)
                        tw(al, { Rotation = 0 }, TI.Fast)
                        task.wait(0.13); dd.Visible = false; dCb(opt)
                        if dFlag then VoidUI.Flags[dFlag] = opt; Win:SaveConfig() end
                    end
                end)
            end

            local mb = Instance.new("TextButton")
            mb.Size = UDim2.new(1, 0, 1, 0); mb.BackgroundTransparency = 1; mb.Text = ""; mb.Parent = c
            tabMaid:Add(mb.MouseButton1Click:Connect(function()
                open = not open
                local th2 = open and math.min(#dOpts * 34 + 8, 180) or 0
                dd.Visible = true
                tw(dd, { Size = UDim2.new(1, 0, 0, th2) }, TI.Fast)
                tw(al, { Rotation = open and 180 or 0 }, TI.Fast)
                if not open then task.delay(0.15, function() dd.Visible = false end) end
            end))

            local obj = {}
            function obj:Set(v) val = v; refreshVl(); dCb(v) end
            function obj:Get() return val end
            function obj:AddOption(o) table.insert(dOpts, o) end
            function obj:Clear() val = nil; refreshVl() end
            return obj
        end

        -- ── Input ────────────────────────────────────────────
        function Tab:CreateInput(opts2)
            local iFlag = opts2.Flag
            local iCb   = opts2.Callback or function() end
            local iLive = opts2.LiveUpdate or false
            local iNum  = opts2.NumberOnly or false
            local c = elem(52); reg(c, opts2.Name)

            local nl2 = lbl(c, opts2.Name or "Input", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(1, -24, 0, 16); nl2.Position = UDim2.new(0, 12, 0, 6)

            local ibg = frm(c, UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 26), T.BgInput, 0)
            corner(ibg, 5); local ibs = stroke(ibg, T.Border, 1, 0.2)

            local ib = Instance.new("TextBox")
            ib.Size                   = UDim2.new(1, -12, 1, 0)
            ib.Position               = UDim2.new(0, 6, 0, 0)
            ib.BackgroundTransparency = 1
            ib.Text                   = ""
            ib.PlaceholderText        = opts2.Placeholder or "Введите значение..."
            ib.Font                   = Enum.Font.Gotham
            ib.TextSize               = 11
            ib.TextColor3             = T.TextPrimary
            ib.PlaceholderColor3      = T.TextMuted
            ib.ClearTextOnFocus       = false
            ib.Parent = ibg

            tabMaid:Add(ib.Focused:Connect(function()
                tw(ibg, { BackgroundColor3 = T.BgLight }, TI.Fast)
                ibs.Color = T.Accent; ibs.Transparency = 0
            end))
            tabMaid:Add(ib.FocusLost:Connect(function(e)
                tw(ibg, { BackgroundColor3 = T.BgInput }, TI.Fast)
                ibs.Color = T.Border; ibs.Transparency = 0.2
                if e then
                    local v2 = iNum and tonumber(ib.Text) or ib.Text
                    iCb(v2)
                    if iFlag then VoidUI.Flags[iFlag] = v2; Win:SaveConfig() end
                end
            end))
            if iLive then
                tabMaid:Add(ib:GetPropertyChangedSignal("Text"):Connect(function()
                    iCb(iNum and tonumber(ib.Text) or ib.Text)
                end))
            end

            local obj = {}
            function obj:Set(v2) ib.Text = tostring(v2) end
            function obj:Get() return ib.Text end
            function obj:Clear() ib.Text = "" end
            return obj
        end

        -- ── Keybind ──────────────────────────────────────────
        function Tab:CreateKeybind(opts2)
            local kFlag = opts2.Flag
            local kCb   = opts2.Callback or function() end
            local kHold = opts2.Hold or false
            local val   = opts2.CurrentKey or Enum.KeyCode.Unknown
            local binding = false; local held = false
            local c = elem(36); reg(c, opts2.Name)

            local nl2 = lbl(c, opts2.Name or "Keybind", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(1, -100, 0, 16); nl2.Position = UDim2.new(0, 12, 0.5, -8)

            local kbg = frm(c, UDim2.new(0, 80, 0, 22), UDim2.new(1, -92, 0.5, -11), T.BgInput, 0)
            corner(kbg, 6); stroke(kbg, T.Border, 1, 0.2)
            local kl = lbl(kbg, val.Name, 11, T.TextAccent, Enum.Font.Code, Enum.TextXAlignment.Center)
            kl.Size = UDim2.new(1, 0, 1, 0)

            local btn2 = Instance.new("TextButton")
            btn2.Size = UDim2.new(1, 0, 1, 0); btn2.BackgroundTransparency = 1; btn2.Text = ""; btn2.Parent = c
            tabMaid:Add(btn2.MouseButton1Click:Connect(function()
                binding = true; kl.Text = "..."; kl.TextColor3 = T.TextSub
                tw(kbg, { BackgroundColor3 = T.AccentFaded }, TI.Fast)
            end))
            tabMaid:Add(UserInputService.InputBegan:Connect(function(i, gpe)
                if binding and i.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false; val = i.KeyCode; kl.Text = i.KeyCode.Name; kl.TextColor3 = T.TextAccent
                    tw(kbg, { BackgroundColor3 = T.BgInput }, TI.Fast)
                    if kFlag then VoidUI.Flags[kFlag] = i.KeyCode.Name; Win:SaveConfig() end
                    kCb(i.KeyCode); return
                end
                if not gpe and not binding and i.KeyCode == val then
                    if kHold then held = true else kCb(val) end
                end
            end))
            tabMaid:Add(UserInputService.InputEnded:Connect(function(i)
                if i.KeyCode == val and kHold and held then held = false; kCb(val) end
            end))

            local obj = {}
            function obj:Get() return val end
            function obj:Set(k) val = k; kl.Text = k.Name end
            return obj
        end

        -- ── ColorPicker ──────────────────────────────────────
        function Tab:CreateColorPicker(opts2)
            local cFlag = opts2.Flag
            local cDef  = opts2.Default or Color3.fromRGB(138, 58, 255)
            local cCb   = opts2.Callback or function() end
            local val   = cDef; local open = false
            local hue, sat, bri = Color3.toHSV(cDef)

            local c = elem(36); c.ClipsDescendants = false; reg(c, opts2.Name)
            local nl2 = lbl(c, opts2.Name or "Цвет", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(1, -72, 0, 18); nl2.Position = UDim2.new(0, 12, 0.5, -9)
            local prev = frm(c, UDim2.new(0, 34, 0, 22), UDim2.new(1, -50, 0.5, -11), val, 0)
            corner(prev, 6); stroke(prev, T.Border, 1, 0)
            local al = lbl(c, "▾", 13, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            al.Size = UDim2.new(0, 16, 0, 18); al.Position = UDim2.new(1, -22, 0.5, -9)

            local pk = frm(c, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 5), T.BgLight, 0)
            pk.ClipsDescendants = true; pk.ZIndex = 8; pk.Visible = false
            corner(pk, 7); stroke(pk, T.Border, 1, 0); pad(pk, 8, 8, 8, 8)

            local function applyCol()
                val = Color3.fromHSV(hue, sat, bri)
                prev.BackgroundColor3 = val; cCb(val)
                if cFlag then VoidUI.Flags[cFlag] = { val.R, val.G, val.B }; Win:SaveConfig() end
            end

            local hBar = frm(pk, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 0), T.Bg, 0); corner(hBar, 4)
            grad(hBar, {
                Color3.fromHSV(0, 1, 1), Color3.fromHSV(0.17, 1, 1), Color3.fromHSV(0.33, 1, 1),
                Color3.fromHSV(0.5, 1, 1), Color3.fromHSV(0.67, 1, 1), Color3.fromHSV(0.83, 1, 1), Color3.fromHSV(1, 1, 1)
            }, 0)
            local hTh = frm(hBar, UDim2.new(0, 4, 1, 4), UDim2.new(hue, -2, 0, -2), T.TextPrimary, 0); corner(hTh, 2)
            stroke(hTh, T.Bg, 1, 0)

            local svB = frm(pk, UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 22), Color3.fromHSV(hue, 1, 1), 0); corner(svB, 4)
            local svW = Instance.new("UIGradient")
            svW.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)) })
            svW.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }); svW.Parent = svB
            local svHf = frm(svB, UDim2.new(1, 0, 1, 0), nil, Color3.new(0, 0, 0), 0)
            local svHg = Instance.new("UIGradient"); svHg.Rotation = 90
            svHg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)), ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)) })
            svHg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }); svHg.Parent = svHf
            local svTh = frm(svB, UDim2.new(0, 12, 0, 12), UDim2.new(sat, -6, 1 - bri, -6), T.TextPrimary, 0)
            corner(svTh, 6); stroke(svTh, T.Bg, 1.5, 0); svTh.ZIndex = 3

            local dH, dSV = false, false
            tabMaid:Add(hBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dH  = true
                    hue = math.clamp((i.Position.X - hBar.AbsolutePosition.X) / hBar.AbsoluteSize.X, 0, 1)
                    tw(hTh, { Position = UDim2.new(hue, -2, 0, -2) }, TI.Fast)
                    svB.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    svW.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)) })
                    applyCol()
                end
            end))
            tabMaid:Add(svB.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dSV = true
                    sat = math.clamp((i.Position.X - svB.AbsolutePosition.X) / svB.AbsoluteSize.X, 0, 1)
                    bri = 1 - math.clamp((i.Position.Y - svB.AbsolutePosition.Y) / svB.AbsoluteSize.Y, 0, 1)
                    tw(svTh, { Position = UDim2.new(sat, -6, 1 - bri, -6) }, TI.Fast); applyCol()
                end
            end))
            tabMaid:Add(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dH = false; dSV = false end
            end))
            tabMaid:Add(UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    if dH then
                        hue = math.clamp((i.Position.X - hBar.AbsolutePosition.X) / hBar.AbsoluteSize.X, 0, 1)
                        tw(hTh, { Position = UDim2.new(hue, -2, 0, -2) }, TI.Fast)
                        svB.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                        svW.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)) })
                        applyCol()
                    elseif dSV then
                        sat = math.clamp((i.Position.X - svB.AbsolutePosition.X) / svB.AbsoluteSize.X, 0, 1)
                        bri = 1 - math.clamp((i.Position.Y - svB.AbsolutePosition.Y) / svB.AbsoluteSize.Y, 0, 1)
                        tw(svTh, { Position = UDim2.new(sat, -6, 1 - bri, -6) }, TI.Fast); applyCol()
                    end
                end
            end))

            local mb = Instance.new("TextButton")
            mb.Size = UDim2.new(1, 0, 1, 0); mb.BackgroundTransparency = 1; mb.Text = ""; mb.Parent = c
            tabMaid:Add(mb.MouseButton1Click:Connect(function()
                open = not open; pk.Visible = true
                tw(pk, { Size = UDim2.new(1, 0, 0, open and 118 or 0) }, TI.Fast)
                tw(al, { Rotation = open and 180 or 0 }, TI.Fast)
                if not open then task.delay(0.15, function() pk.Visible = false end) end
            end))

            local obj = {}
            function obj:Set(color)
                val = color; prev.BackgroundColor3 = color
                hue, sat, bri = Color3.toHSV(color)
                svB.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                tw(hTh,  { Position = UDim2.new(hue, -2, 0, -2) }, TI.Fast)
                tw(svTh, { Position = UDim2.new(sat, -6, 1 - bri, -6) }, TI.Fast)
            end
            function obj:Get() return val end
            return obj
        end

        -- ── ProgressBar ──────────────────────────────────────
        function Tab:CreateProgressBar(opts2)
            local pMin = opts2.Min or 0; local pMax = opts2.Max or 100
            local pVal = opts2.Value or 0; local pSuf = opts2.Suffix or ""
            local pCol = opts2.Color or T.Accent
            local c = elem(44); reg(c, opts2.Name)
            local nl2 = lbl(c, opts2.Name or "Progress", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(1, -70, 0, 16); nl2.Position = UDim2.new(0, 12, 0, 6)
            local vl = lbl(c, tostring(pVal) .. pSuf, 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            vl.Size = UDim2.new(0, 56, 0, 16); vl.Position = UDim2.new(1, -68, 0, 6)
            local track = frm(c, UDim2.new(1, -24, 0, 7), UDim2.new(0, 12, 0, 30), T.Border, 0); corner(track, 6)
            local fill  = frm(track, UDim2.new(0, 0, 1, 0), nil, pCol, 0); corner(fill, 6)
            fill.Size = UDim2.new(math.clamp((pVal - pMin) / (pMax - pMin), 0, 1), 0, 1, 0)

            local obj = {}
            function obj:Set(v)
                v = math.clamp(v, pMin, pMax)
                tw(fill, { Size = UDim2.new((v - pMin) / (pMax - pMin), 0, 1, 0) }, TI.Mid)
                vl.Text = tostring(math.round(v)) .. pSuf
            end
            function obj:SetMax(m) pMax = m end
            function obj:SetColor(col) pCol = col; fill.BackgroundColor3 = col end
            return obj
        end

        -- ── TextDisplay ──────────────────────────────────────
        function Tab:CreateTextDisplay(opts2)
            local c = elem(36); reg(c, opts2.Name or "")
            local nl2 = lbl(c, opts2.Name or "", 11, T.TextMuted, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(0.48, 0, 0, 16); nl2.Position = UDim2.new(0, 12, 0.5, -8)
            local vl = lbl(c, opts2.Text or "", opts2.Size or 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            vl.Size = UDim2.new(0.48, 0, 0, 16); vl.Position = UDim2.new(0.48, 0, 0.5, -8)
            local obj = {}
            function obj:Set(v) vl.Text = tostring(v) end
            function obj:SetColor(col) vl.TextColor3 = col end
            function obj:Get() return vl.Text end
            return obj
        end

        -- ── MultiToggle ──────────────────────────────────────
        function Tab:CreateMultiToggle(opts2)
            local options  = opts2.Options or {}
            local defaults = opts2.Defaults or {}
            local mCb      = opts2.Callback or function() end
            local state    = {}
            for _, o in ipairs(options) do state[o] = defaults[o] or false end

            local totalH = 32 + #options * 30
            local c = frm(scroll, UDim2.new(1, 0, 0, totalH), nil, T.BgElement, 1)
            c.LayoutOrder = lo(); c.AutomaticSize = Enum.AutomaticSize.Y
            corner(c, 7); stroke(c, T.Border, 1, 0.4); reg(c, opts2.Name)
            task.defer(function() tw(c, { BackgroundTransparency = 0 }, TI.Mid) end)

            local nl2 = lbl(c, opts2.Name or "MultiToggle", 12, T.TextPrimary, Enum.Font.GothamBold)
            nl2.Size = UDim2.new(1, -24, 0, 18); nl2.Position = UDim2.new(0, 12, 0, 8)

            for i, opt in ipairs(options) do
                local row = frm(c, UDim2.new(1, -24, 0, 26), UDim2.new(0, 12, 0, 28 + (i - 1) * 30), T.Bg, 0); corner(row, 5)
                local rl  = lbl(row, opt, 11, T.TextSub, Enum.Font.Gotham)
                rl.Size = UDim2.new(1, -40, 1, 0); rl.Position = UDim2.new(0, 10, 0, 0)
                local tbg2 = frm(row, UDim2.new(0, 34, 0, 18), UDim2.new(1, -40, 0.5, -9), state[opt] and T.Accent or T.AccentFaded, 0)
                corner(tbg2, 9)
                local th2 = frm(tbg2, UDim2.new(0, 14, 0, 14), state[opt] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), T.TextPrimary, 0)
                corner(th2, 7)
                local rb = Instance.new("TextButton"); rb.Size = UDim2.new(1, 0, 1, 0); rb.BackgroundTransparency = 1; rb.Text = ""; rb.Parent = row
                tabMaid:Add(rb.MouseButton1Click:Connect(function()
                    state[opt] = not state[opt]
                    tw(tbg2, { BackgroundColor3 = state[opt] and T.Accent or T.AccentFaded }, TI.Fast)
                    tw(th2,  { Position = state[opt] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }, TI.Fast)
                    tw(rl,   { TextColor3 = state[opt] and T.TextPrimary or T.TextSub }, TI.Fast)
                    mCb(state)
                end))
            end

            local obj = {}
            function obj:Get() return state end
            function obj:Set(o, v) state[o] = v end
            return obj
        end

        -- ── Radio ────────────────────────────────────────────
        function Tab:CreateRadio(opts2)
            local options  = opts2.Options or {}
            local def      = opts2.Default or options[1]
            local rCb      = opts2.Callback or function() end
            local selected = def

            local totalH = 32 + #options * 28
            local c = frm(scroll, UDim2.new(1, 0, 0, totalH), nil, T.BgElement, 1)
            c.LayoutOrder = lo(); c.AutomaticSize = Enum.AutomaticSize.Y
            corner(c, 7); stroke(c, T.Border, 1, 0.4); reg(c, opts2.Name)
            task.defer(function() tw(c, { BackgroundTransparency = 0 }, TI.Mid) end)

            local nl2 = lbl(c, opts2.Name or "Radio", 12, T.TextPrimary, Enum.Font.GothamBold)
            nl2.Size = UDim2.new(1, -24, 0, 18); nl2.Position = UDim2.new(0, 12, 0, 7)

            local dots = {}
            local function selectOpt(opt)
                selected = opt
                for o, parts in pairs(dots) do
                    local active = o == opt
                    tw(parts.outer, { BackgroundColor3 = active and T.Accent or T.AccentFaded }, TI.Fast)
                    tw(parts.inner, { BackgroundTransparency = active and 0 or 1 }, TI.Fast)
                    tw(parts.lbl,   { TextColor3 = active and T.TextPrimary or T.TextSub }, TI.Fast)
                end
                rCb(opt)
            end

            for i, opt in ipairs(options) do
                local row   = frm(c, UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 28 + (i - 1) * 28), T.Bg, 0); corner(row, 5)
                local outer = frm(row, UDim2.new(0, 16, 0, 16), UDim2.new(0, 8, 0.5, -8), opt == def and T.Accent or T.AccentFaded, 0); corner(outer, 99)
                stroke(outer, T.Border, 1, 0.2)
                local inner = frm(outer, UDim2.new(0, 8, 0, 8), UDim2.new(0.5, -4, 0.5, -4), T.TextPrimary, opt == def and 0 or 1); corner(inner, 99)
                local rl    = lbl(row, opt, 11, opt == def and T.TextPrimary or T.TextSub, Enum.Font.Gotham)
                rl.Size = UDim2.new(1, -36, 1, 0); rl.Position = UDim2.new(0, 32, 0, 0)
                dots[opt] = { outer = outer, inner = inner, lbl = rl }
                local rb = Instance.new("TextButton"); rb.Size = UDim2.new(1, 0, 1, 0); rb.BackgroundTransparency = 1; rb.Text = ""; rb.Parent = row
                tabMaid:Add(rb.MouseButton1Click:Connect(function() selectOpt(opt) end))
            end

            local obj = {}
            function obj:Get() return selected end
            function obj:Set(v) selectOpt(v) end
            return obj
        end

        -- ── Stepper ──────────────────────────────────────────
        function Tab:CreateStepper(opts2)
            local sMin  = opts2.Min     or 0
            local sMax  = opts2.Max     or 10
            local sStep = opts2.Step    or 1
            local sSuf2 = opts2.Suffix  or ""
            local sDef2 = opts2.Default or sMin
            local sCb2  = opts2.Callback or function() end
            local val   = math.clamp(sDef2, sMin, sMax)
            local c     = elem(36); reg(c, opts2.Name)

            local nl2 = lbl(c, opts2.Name or "Stepper", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(0.45, 0, 0, 16); nl2.Position = UDim2.new(0, 12, 0.5, -8)
            local ctrlF = frm(c, UDim2.new(0, 90, 0, 26), UDim2.new(1, -102, 0.5, -13), T.Bg, 0)
            corner(ctrlF, 7); stroke(ctrlF, T.Border, 1, 0.3)

            local minusB = Instance.new("TextButton")
            minusB.Size = UDim2.new(0, 26, 1, 0); minusB.BackgroundTransparency = 1
            minusB.Text = "−"; minusB.Font = Enum.Font.GothamBold; minusB.TextSize = 14
            minusB.TextColor3 = T.TextSub; minusB.BorderSizePixel = 0; minusB.Parent = ctrlF

            local valL = lbl(ctrlF, tostring(val) .. sSuf2, 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
            valL.Size = UDim2.new(1, -52, 1, 0); valL.Position = UDim2.new(0, 26, 0, 0)

            local plusB = Instance.new("TextButton")
            plusB.Size = UDim2.new(0, 26, 1, 0); plusB.Position = UDim2.new(1, -26, 0, 0)
            plusB.BackgroundTransparency = 1; plusB.Text = "+"; plusB.Font = Enum.Font.GothamBold
            plusB.TextSize = 14; plusB.TextColor3 = T.TextSub; plusB.BorderSizePixel = 0; plusB.Parent = ctrlF

            local function update(v)
                val = math.clamp(v, sMin, sMax); valL.Text = tostring(val) .. sSuf2
                tw(valL, { TextColor3 = T.TextAccent }, TI.Fast); sCb2(val)
            end
            tabMaid:Add(minusB.MouseButton1Click:Connect(function() update(val - sStep) end))
            tabMaid:Add(plusB.MouseButton1Click:Connect(function() update(val + sStep) end))

            local obj = {}
            function obj:Get() return val end
            function obj:Set(v) update(v) end
            return obj
        end

        -- ── Badge ────────────────────────────────────────────
        function Tab:CreateBadge(opts2)
            local bCol = opts2.Color or T.Accent
            local c    = elem(32); reg(c, opts2.Name or "")
            local nl2  = lbl(c, opts2.Name or "Badge", 12, T.TextPrimary, Enum.Font.GothamMedium)
            nl2.Size = UDim2.new(0.6, 0, 0, 16); nl2.Position = UDim2.new(0, 12, 0.5, -8)
            local badgeF   = frm(c, UDim2.new(0, 0, 0, 20), UDim2.new(1, -14, 0.5, -10), bCol, 0); corner(badgeF, 10)
            local badgeLbl = lbl(badgeF, opts2.Text or "ACTIVE", 9, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
            badgeLbl.Size = UDim2.new(1, 0, 1, 0)
            task.defer(function()
                local tw2 = #(opts2.Text or "ACTIVE") * 7 + 14
                badgeF.Size = UDim2.new(0, tw2, 0, 20); badgeF.Position = UDim2.new(1, -(tw2 + 8), 0.5, -10)
            end)
            local obj = {}
            function obj:Set(text, color)
                badgeLbl.Text = text or ""
                if color then badgeF.BackgroundColor3 = color end
                local tw2 = #(text or "") * 7 + 14
                badgeF.Size = UDim2.new(0, tw2, 0, 20); badgeF.Position = UDim2.new(1, -(tw2 + 8), 0.5, -10)
            end
            return obj
        end

        -- ── SetBadge (на табе) ───────────────────────────────
        function Tab:SetBadge(text)
            if badgeL then badgeL.Text = tostring(text) end
        end

        -- ── Destroy (GC вкладки) ────────────────────────────
        function Tab:Destroy()
            tabMaid:Clean()
            if scroll and scroll.Parent then scroll:Destroy() end
            if tabBtn and tabBtn.Parent then tabBtn:Destroy() end
        end

        return Tab
    end

    -- ════════════════════════════════════════════════════════
    --  ВСТРОЕННАЯ ВКЛАДКА НАСТРОЕК
    -- ════════════════════════════════════════════════════════
    function Win:CreateSettingsTab()
        local sTab = self:CreateTab("Настройки", "⚙")

        sTab:CreateSection("Тема")

        local themeNames = {}
        for name in pairs(THEMES) do table.insert(themeNames, name) end
        table.sort(themeNames)

        sTab:CreateRadio({
            Name     = "Preset тема",
            Options  = themeNames,
            Default  = "Void",
            Callback = function(v)
                self:SetTheme(v)
                VoidUI:Notify({ Title = "Тема", Content = "Применена: " .. v, Type = "success", Duration = 2 })
            end,
        })

        sTab:CreateSection("Акцент")

        sTab:CreateColorPicker({
            Name     = "Цвет акцента",
            Default  = T.Accent,
            Callback = function(col) self:SetAccent(col) end,
        })

        sTab:CreateSeparator()
        sTab:CreateSection("Интерфейс")

        sTab:CreateSlider({
            Name         = "Прозрачность окна",
            Range        = { 0, 80 },
            Increment    = 5,
            Suffix       = "%",
            CurrentValue = 0,
            Callback     = function(v)
                tw(mf, { BackgroundTransparency = v / 100 }, TI.Fast)
            end,
        })

        sTab:CreateSeparator()
        sTab:CreateSection("Хоткеи")

        sTab:CreateKeybind({
            Name       = "Показать/скрыть UI",
            CurrentKey = tKey,
            Callback   = function(k) tKey = k end,
        })

        sTab:CreateSeparator()
        sTab:CreateSection("Информация")

        sTab:CreateTextDisplay({ Name = "Версия", Text = "v" .. VoidUI.Version })
        sTab:CreateTextDisplay({ Name = "Автор",  Text = VoidUI.Author })

        sTab:CreateButton({
            Name     = "Тест уведомления",
            Callback = function()
                VoidUI:Notify({ Title = "VoidUI v" .. VoidUI.Version, Content = "Уведомления работают!", Type = "success", Duration = 3 })
            end,
        })

        sTab:CreateButton({
            Name     = "Сохранить конфиг",
            Callback = function()
                self:SaveConfig()
                VoidUI:Notify({ Title = "Конфиг", Content = "Сохранено", Type = "success", Duration = 2 })
            end,
        })

        return sTab
    end

    return Win
end

return VoidUI
