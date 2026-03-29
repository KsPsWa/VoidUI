-- ══════════════════════════════════════════════════════════════
--  VoidUI v3.0  ·  Enhanced Edition
--  New: FPS/Ping overlay (draggable, bottom-right, clamped)
--  New: CreateMultiToggle, CreateBadge, CreateTable,
--       CreateAccordion, CreateRadio, CreateAlert,
--       CreateStepper, CreateChip, CreateDivider
--  Improved: window drag clamped to screen, better anims,
--            tab badges, search bar in tab panel,
--            notification queue with priority
-- ══════════════════════════════════════════════════════════════

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local Debris           = game:GetService("Debris")
local Stats            = game:GetService("Stats")

local LP = Players.LocalPlayer

-- ── Тема ─────────────────────────────────────────────────────
local T = {
	Bg           = Color3.fromRGB(8, 8, 14),
	BgLight      = Color3.fromRGB(14, 14, 22),
	BgTab        = Color3.fromRGB(11, 11, 18),
	BgElement    = Color3.fromRGB(18, 18, 28),
	BgHover      = Color3.fromRGB(28, 16, 56),
	BgInput      = Color3.fromRGB(6, 6, 11),
	Accent       = Color3.fromRGB(138, 58, 255),
	AccentDark   = Color3.fromRGB(88, 28, 178),
	AccentLight  = Color3.fromRGB(178, 118, 255),
	AccentFaded  = Color3.fromRGB(55, 20, 110),
	TextPrimary  = Color3.fromRGB(238, 238, 252),
	TextSub      = Color3.fromRGB(138, 138, 158),
	TextMuted    = Color3.fromRGB(72, 72, 90),
	TextAccent   = Color3.fromRGB(178, 118, 255),
	Border       = Color3.fromRGB(36, 16, 76),
	BorderLight  = Color3.fromRGB(56, 26, 106),
	Sep          = Color3.fromRGB(26, 12, 54),
	Success      = Color3.fromRGB(48, 214, 98),
	Warning      = Color3.fromRGB(252, 178, 48),
	Error        = Color3.fromRGB(252, 58, 58),
	Info         = Color3.fromRGB(138, 58, 255),
	ScrollBar    = Color3.fromRGB(55, 25, 115),
	GlassAlpha  = 0.06,
}

-- ── Easing ───────────────────────────────────────────────────
local EF = {Enum.EasingStyle.Quad, Enum.EasingDirection.Out}
local TI = {
	Fast   = TweenInfo.new(0.13, table.unpack(EF)),
	Mid    = TweenInfo.new(0.22, table.unpack(EF)),
	Slow   = TweenInfo.new(0.36, table.unpack(EF)),
	Spring = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
	Bounce = TweenInfo.new(0.4,  Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

-- ── Утилиты ──────────────────────────────────────────────────
local function tw(o, p, i) TweenService:Create(o, i or TI.Mid, p):Play() end

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end

local function pad(p, t, r, b, l)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, t or 6); u.PaddingRight = UDim.new(0, r or 6)
	u.PaddingBottom = UDim.new(0, b or 6); u.PaddingLeft = UDim.new(0, l or 6)
	u.Parent = p; return u
end

local function stroke(p, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or T.Border; s.Thickness = thick or 1; s.Transparency = trans or 0
	s.Parent = p; return s
end

local function lbl(p, text, size, color, font, xa)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1; l.Text = text or ""; l.TextSize = size or 13
	l.TextColor3 = color or T.TextPrimary; l.Font = font or Enum.Font.GothamMedium
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = p; return l
end

local function lst(p, spacing, dir)
	local u = Instance.new("UIListLayout")
	u.SortOrder = Enum.SortOrder.LayoutOrder
	u.FillDirection = dir or Enum.FillDirection.Vertical
	u.Padding = UDim.new(0, spacing or 0)
	u.Parent = p; return u
end

local function grad(p, colors, rot)
	local g = Instance.new("UIGradient"); local kps = {}
	for i, v in ipairs(colors) do kps[i] = ColorSequenceKeypoint.new((i-1)/(#colors-1), v) end
	g.Color = ColorSequence.new(kps); g.Rotation = rot or 0; g.Parent = p; return g
end

local function frm(p, size, pos, bg, trans)
	local f = Instance.new("Frame")
	f.Size = size or UDim2.new(1,0,1,0); f.Position = pos or UDim2.new(0,0,0,0)
	f.BackgroundColor3 = bg or T.Bg; f.BackgroundTransparency = trans or 0
	f.BorderSizePixel = 0; f.Parent = p; return f
end

local function ripple(p, mx, my)
	local r = Instance.new("Frame")
	r.BackgroundColor3 = Color3.new(1,1,1); r.BackgroundTransparency = 0.78
	r.BorderSizePixel = 0; r.Size = UDim2.new(0,0,0,0)
	r.Position = UDim2.new(0, mx, 0, my); r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.ZIndex = 20; r.Parent = p; corner(r, 999)
	local sz = math.max(p.AbsoluteSize.X, p.AbsoluteSize.Y) * 2.4
	tw(r, {Size=UDim2.new(0,sz,0,sz), BackgroundTransparency=1},
		TweenInfo.new(0.44, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	Debris:AddItem(r, 0.5)
end

local function mrel(obj)
	local mp = UserInputService:GetMouseLocation()
	return mp.X - obj.AbsolutePosition.X, mp.Y - obj.AbsolutePosition.Y
end

-- Зажим позиции в пределах экрана
local function clampPos(mf, W, H)
	local vp = workspace.CurrentCamera.ViewportSize
	local ox = math.clamp(mf.Position.X.Offset, 0, vp.X - W)
	local oy = math.clamp(mf.Position.Y.Offset, 0, vp.Y - H)
	mf.Position = UDim2.new(0, ox, 0, oy)
end

-- ── Конфиг ───────────────────────────────────────────────────
local CONFIG_DIR = "VoidUI"
local function cfgSave(name, data)
	pcall(function()
		if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
		writefile(CONFIG_DIR.."/"..name..".json", HttpService:JSONEncode(data))
	end)
end
local function cfgLoad(name)
	local ok, r = pcall(function()
		return HttpService:JSONDecode(readfile(CONFIG_DIR.."/"..name..".json"))
	end)
	return ok and r or {}
end

-- ── VoidUI object ─────────────────────────────────────────────
local VoidUI   = {}
VoidUI.__index = VoidUI
VoidUI.Version = "3.0.0"
VoidUI.Author  = "Enhanced"
VoidUI.Flags   = {}
VoidUI.Theme   = T

-- ══════════════════════════════════════════════════════════════
--  NOTIFY
-- ══════════════════════════════════════════════════════════════
local _ng, _nh, _ns = nil, nil, {}

local function _initN()
	if _ng then return end
	_ng = Instance.new("ScreenGui")
	_ng.Name = "VoidUI_N"; _ng.ResetOnSpawn = false
	_ng.IgnoreGuiInset = true; _ng.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_ng.Parent = LP.PlayerGui
	_nh = frm(_ng, UDim2.new(0,310,1,0), UDim2.new(1,-326,0,0), T.Bg, 1)
	local u = lst(_nh, 7); u.VerticalAlignment = Enum.VerticalAlignment.Bottom
	pad(_nh, 0,0,14,0)
end

function VoidUI:Notify(opts)
	_initN()
	local title   = opts.Title or "Void UI"
	local content = opts.Content or ""
	local dur     = opts.Duration or 4
	local ntype   = opts.Type or "info"
	local priority = opts.Priority or 0  -- выше = важнее, пушит старые
	local cols  = {info=T.Info, success=T.Success, warning=T.Warning, error=T.Error}
	local icons = {info="ℹ", success="✓", warning="⚠", error="✕"}
	local ac = cols[ntype] or T.Info

	-- Если очередь полная — удаляем самое старое с низким приоритетом
	if #_ns >= 5 then
		local o = table.remove(_ns, 1)
		if o and o.Parent then
			tw(o, {Position=UDim2.new(1,12,o.Position.Y.Scale,o.Position.Y.Offset)}, TI.Fast)
			task.delay(0.2, function() if o.Parent then o:Destroy() end end)
		end
	end

	local nf = frm(_nh, UDim2.new(1,0,0,76), nil, T.BgLight, 0)
	nf.ClipsDescendants = true; nf.LayoutOrder = tick()
	corner(nf, 10); stroke(nf, ac, 1, 0.45)

	-- Боковая полоска акцента
	local ab = frm(nf, UDim2.new(0,3,0.7,0), UDim2.new(0,0,0.15,0), ac, 0); corner(ab,3)
	grad(ab, {T.AccentLight, ac}, 90)

	-- Иконка
	local icf = frm(nf, UDim2.new(0,30,0,30), UDim2.new(0,14,0,10), T.AccentFaded, 0); corner(icf,8)
	local icl = lbl(icf, icons[ntype] or "·", 14, ac, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	icl.Size = UDim2.new(1,0,1,0)

	-- Заголовок
	local tl = lbl(nf, title, 13, T.TextPrimary, Enum.Font.GothamBold)
	tl.Size = UDim2.new(1,-58,0,18); tl.Position = UDim2.new(0,52,0,10)

	-- Контент
	local cl = lbl(nf, content, 11, T.TextSub, Enum.Font.Gotham)
	cl.Size = UDim2.new(1,-58,0,30); cl.Position = UDim2.new(0,52,0,30)
	cl.TextWrapped = true; cl.TextTruncate = Enum.TextTruncate.None

	-- Прогресс-бар снизу
	local pbg = frm(nf, UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), T.Border, 0)
	local pb  = frm(pbg, UDim2.new(1,0,1,0), nil, ac, 0)
	grad(pb, {T.AccentLight, ac}, 0)

	-- Анимация появления
	nf.Position = UDim2.new(1,14, 0, 0)
	tw(nf, {Position=UDim2.new(0,0,0,0)}, TI.Spring)
	table.insert(_ns, nf)

	tw(pb, {Size=UDim2.new(0,0,1,0)}, TweenInfo.new(dur, Enum.EasingStyle.Linear))

	-- Клик — закрыть досрочно
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size=UDim2.new(0,18,0,18); closeBtn.Position=UDim2.new(1,-24,0,8)
	closeBtn.BackgroundTransparency=1; closeBtn.Text="✕"; closeBtn.TextSize=10
	closeBtn.TextColor3=T.TextMuted; closeBtn.Font=Enum.Font.GothamBold; closeBtn.Parent=nf

	local function dismiss()
		tw(nf, {Position=UDim2.new(1,14,0,0), BackgroundTransparency=1}, TI.Mid)
		task.wait(0.26)
		local idx = table.find(_ns, nf)
		if idx then table.remove(_ns, idx) end
		if nf.Parent then nf:Destroy() end
	end
	closeBtn.MouseButton1Click:Connect(dismiss)
	task.delay(dur, dismiss)
end

-- ══════════════════════════════════════════════════════════════
--  FPS / PING OVERLAY  (снизу справа, перетаскиваемый)
-- ══════════════════════════════════════════════════════════════
local _statGui
function VoidUI:CreateStatsOverlay(opts)
	opts = opts or {}
	if _statGui then _statGui:Destroy() end

	_statGui = Instance.new("ScreenGui")
	_statGui.Name = "VoidUI_Stats"; _statGui.ResetOnSpawn = false
	_statGui.IgnoreGuiInset = true; _statGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_statGui.Parent = LP.PlayerGui

	local W, H = 200, 56
	local vp = workspace.CurrentCamera.ViewportSize
	-- Начальная позиция: нижний правый угол с отступом
	local startX = vp.X - W - 14
	local startY = vp.Y - H - 14

	local sf = frm(_statGui, UDim2.new(0,W,0,H), UDim2.new(0,startX,0,startY), T.BgLight, 0)
	corner(sf, 10); stroke(sf, T.Border, 1, 0.2)

	-- Верхняя полоска градиент
	local topBar = frm(sf, UDim2.new(1,0,0,2), nil, T.Accent, 0); corner(topBar, 10)
	grad(topBar, {T.AccentLight, T.Accent, T.AccentDark}, 0)

	-- FPS блок
	local fpsBlock = frm(sf, UDim2.new(0.5,-1,1,-4), UDim2.new(0,4,0,4), T.Bg, 0); corner(fpsBlock,7)
	local fpsIcon = lbl(fpsBlock, "FPS", 8, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	fpsIcon.Size = UDim2.new(1,0,0,14); fpsIcon.Position = UDim2.new(0,0,0,4)
	local fpsVal = lbl(fpsBlock, "...", 18, T.TextAccent, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	fpsVal.Size = UDim2.new(1,0,0,24); fpsVal.Position = UDim2.new(0,0,0,16)

	-- Разделитель
	frm(sf, UDim2.new(0,1,0,36), UDim2.new(0.5,-0.5,0,10), T.Sep, 0)

	-- Ping блок
	local pingBlock = frm(sf, UDim2.new(0.5,-5,1,-4), UDim2.new(0.5,1,0,4), T.Bg, 0); corner(pingBlock,7)
	local pingIcon = lbl(pingBlock, "PING", 8, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	pingIcon.Size = UDim2.new(1,0,0,14); pingIcon.Position = UDim2.new(0,0,0,4)
	local pingVal = lbl(pingBlock, "...", 18, T.Success, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	pingVal.Size = UDim2.new(1,0,0,24); pingVal.Position = UDim2.new(0,0,0,16)

	-- Перетаскивание (с зажимом)
	local drag, dStart, dOrigin = false, nil, nil
	sf.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag=true; dStart=i.Position; dOrigin=sf.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dStart
			local nx = dOrigin.X.Offset + d.X
			local ny = dOrigin.Y.Offset + d.Y
			local cvp = workspace.CurrentCamera.ViewportSize
			nx = math.clamp(nx, 0, cvp.X - W)
			ny = math.clamp(ny, 0, cvp.Y - H)
			sf.Position = UDim2.new(0, nx, 0, ny)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
	end)

	-- Точный FPS через Heartbeat
	local fc, ft = 0, os.clock()
	local curFps = 60

	-- Точный ping через Stats
	local function getPing()
		local ok, p = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		return ok and math.round(p) or 0
	end

	local pingTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		fc += 1
		local now = os.clock()
		if now - ft >= 0.5 then
			curFps = math.round(fc / (now - ft))
			fc = 0; ft = now
			fpsVal.Text = tostring(curFps)
			fpsVal.TextColor3 = curFps >= 55 and T.Success or curFps >= 30 and T.Warning or T.Error
		end

		pingTimer += dt
		if pingTimer >= 1 then
			pingTimer = 0
			local p = getPing()
			pingVal.Text = tostring(p) .. "ms"
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
	local text = opts.Text or "VOID UI"; local show = opts.Enabled ~= false
	_wmg = Instance.new("ScreenGui")
	_wmg.Name = "VoidUI_WM"; _wmg.ResetOnSpawn = false
	_wmg.IgnoreGuiInset = true; _wmg.Parent = LP.PlayerGui

	local wf = frm(_wmg, UDim2.new(0,220,0,32), UDim2.new(0,14,0,14), T.BgLight, 0)
	wf.Visible = show; corner(wf,8); stroke(wf, T.Border, 1, 0)

	-- Акцентная боковая полоска
	local bar = frm(wf, UDim2.new(0,2,0,20), UDim2.new(0,8,0.5,-10), T.Accent, 0)
	corner(bar,2); grad(bar, {T.AccentLight, T.Accent}, 90)

	local wl = lbl(wf, text, 11, T.TextSub, Enum.Font.GothamMedium)
	wl.Size = UDim2.new(1,-20,1,0); wl.Position = UDim2.new(0,18,0,0)

	local fc2, ft2, fps2 = 0, os.clock(), 60
	RunService.Heartbeat:Connect(function()
		fc2 += 1; local n = os.clock()
		if n-ft2 >= 0.5 then fps2 = math.round(fc2/(n-ft2)); fc2=0; ft2=n end
		wl.Text = text .. "  ·  " .. fps2 .. " fps"
		wl.TextColor3 = fps2 >= 55 and T.TextSub or fps2 >= 30 and T.Warning or T.Error
	end)

	local obj = {}
	function obj:SetText(t) text=t end
	function obj:Toggle(v) wf.Visible=v end
	function obj:Destroy() _wmg:Destroy() end
	return obj
end

-- ══════════════════════════════════════════════════════════════
--  LOADING SCREEN
-- ══════════════════════════════════════════════════════════════
local function _loadScreen(opts)
	local title = opts.LoadingTitle or "VOID UI"; local sub = opts.LoadingSubtitle or ""
	local steps = opts.LoadingSteps or {"Initializing...","Building UI...","Ready!"}
	local logo  = opts.Logo or "VOID"
	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidUI_Load"; sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = LP.PlayerGui

	local bg = frm(sg, UDim2.new(1,0,1,0), nil, Color3.fromRGB(4,4,8), 1)
	local card = frm(sg, UDim2.new(0,420,0,250), UDim2.new(0.5,-210,0.5,-125), T.Bg, 1)
	corner(card,14); stroke(card, T.Border, 1, 0)

	-- Верхняя линия
	local tl2 = frm(card, UDim2.new(1,0,0,3), nil, T.Accent, 0); corner(tl2,14)
	grad(tl2, {T.AccentLight, T.Accent, T.AccentDark}, 0)

	-- Точки декора
	for i=1,3 do
		local d = frm(card, UDim2.new(0,6,0,6), UDim2.new(0,8+(i-1)*14,0,14),
			i==1 and T.Accent or T.AccentFaded, 0); corner(d,99)
	end

	local ll = lbl(card, logo, 38, T.TextPrimary, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	ll.Size = UDim2.new(1,0,0,58); ll.Position = UDim2.new(0,0,0,26)
	grad(ll, {T.AccentLight, T.Accent}, 90)

	local ttl = lbl(card, title, 15, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	ttl.Size = UDim2.new(1,-32,0,22); ttl.Position = UDim2.new(0,16,0,92)

	local stl = lbl(card, sub, 11, T.TextSub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	stl.Size = UDim2.new(1,-32,0,16); stl.Position = UDim2.new(0,16,0,114)

	frm(card, UDim2.new(1,-32,0,1), UDim2.new(0,16,0,138), T.Sep, 0)

	local stp = lbl(card, steps[1], 11, T.TextAccent, Enum.Font.Code, Enum.TextXAlignment.Center)
	stp.Size = UDim2.new(1,-32,0,16); stp.Position = UDim2.new(0,16,0,148)

	local pbg = frm(card, UDim2.new(1,-32,0,6), UDim2.new(0,16,0,172), T.BgElement, 0); corner(pbg,6)
	local pb  = frm(pbg, UDim2.new(0,0,1,0), nil, T.Accent, 0); corner(pb,6)
	grad(pb, {T.AccentLight, T.Accent}, 0)

	local vl2 = lbl(card, "void ui v"..VoidUI.Version, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	vl2.Size = UDim2.new(1,-32,0,14); vl2.Position = UDim2.new(0,16,0,198)

	tw(bg,   {BackgroundTransparency=0.22}, TI.Mid)
	tw(card, {BackgroundTransparency=0},    TI.Spring)

	local n = #steps
	for i, step in ipairs(steps) do
		stp.Text = step
		tw(pb, {Size=UDim2.new(i/n,0,1,0)}, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		task.wait(0.3)
	end
	task.wait(0.2)
	tw(card, {BackgroundTransparency=1, Position=UDim2.new(0.5,-210,0.42,-125)}, TI.Mid)
	tw(bg,   {BackgroundTransparency=1}, TI.Mid)
	task.wait(0.28); sg:Destroy()
end

-- ══════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ══════════════════════════════════════════════════════════════
function VoidUI:CreateWindow(opts)
	local winName  = opts.Name            or "VOID UI"
	local lTitle   = opts.LoadingTitle    or winName
	local lSub     = opts.LoadingSubtitle or ""
	local lSteps   = opts.LoadingSteps
	local lLogo    = opts.Logo            or "VOID"
	local cfgOpts  = opts.ConfigurationSaving or {}
	local cfgFile  = cfgOpts.FileName    or "config"
	local cfgOn    = cfgOpts.Enabled ~= false
	local tKey     = opts.ToggleKey       or Enum.KeyCode.RightShift
	local W        = (opts.Size and opts.Size.Width)  or 640
	local H        = (opts.Size and opts.Size.Height) or 440

	if opts.Accent then
		local a = opts.Accent
		T.Accent      = a
		T.AccentDark  = Color3.new(a.R*0.6,  a.G*0.6,  a.B*0.6)
		T.AccentLight = Color3.new(math.min(a.R*1.3,1), math.min(a.G*1.3,1), math.min(a.B*1.3,1))
		T.AccentFaded = Color3.new(a.R*0.38, a.G*0.38, a.B*0.38)
		T.TextAccent  = T.AccentLight
		T.Border      = Color3.new(a.R*0.27, a.G*0.14, a.B*0.55)
		T.Info = a
	end

	task.spawn(_loadScreen, {LoadingTitle=lTitle, LoadingSubtitle=lSub, LoadingSteps=lSteps, Logo=lLogo})
	task.wait((#(lSteps or {"","",""}) * 0.3) + 0.65)

	local saved = cfgOn and cfgLoad(cfgFile) or {}

	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidUI_Main"; sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = LP.PlayerGui

	-- Основная рамка — позиция по центру экрана через offset
	local vp0 = workspace.CurrentCamera.ViewportSize
	local mf = frm(sg, UDim2.new(0,W,0,H),
		UDim2.new(0, math.round(vp0.X/2 - W/2), 0, math.round(vp0.Y/2 - H/2)), T.Bg, 0)
	corner(mf,12); stroke(mf, T.Border, 1, 0)

	-- Стеклянное свечение
	local glw = Instance.new("ImageLabel")
	glw.Size = UDim2.new(1,90,1,90); glw.Position = UDim2.new(0,-45,0,-45)
	glw.BackgroundTransparency = 1; glw.Image = "rbxassetid://5028857084"
	glw.ImageColor3 = T.Accent; glw.ImageTransparency = 0.9
	glw.ScaleType = Enum.ScaleType.Slice; glw.SliceCenter = Rect.new(24,24,276,276)
	glw.ZIndex = 0; glw.Parent = mf

	-- Тайтл-бар
	local tb = frm(mf, UDim2.new(1,0,0,40), nil, T.BgLight, 0); corner(tb,12)
	frm(tb, UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), T.BgLight, 0)
	local tbLine = frm(tb, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), T.Accent, 0.42)
	grad(tbLine, {Color3.new(0,0,0), T.Accent, T.AccentLight, T.Accent, Color3.new(0,0,0)}, 0)

	-- Логотип
	local logoL = lbl(tb, "VOID", 16, T.Accent, Enum.Font.GothamBlack)
	logoL.Size = UDim2.new(0,50,1,0); logoL.Position = UDim2.new(0,14,0,0)
	local nameL = lbl(tb, winName, 13, T.TextSub, Enum.Font.GothamMedium)
	nameL.Size = UDim2.new(1,-200,1,0); nameL.Position = UDim2.new(0,66,0,0)

	-- Версия в тайтл-баре
	local verTL = lbl(tb, "v"..VoidUI.Version, 10, T.TextMuted, Enum.Font.Code, Enum.TextXAlignment.Right)
	verTL.Size = UDim2.new(0,60,1,0); verTL.Position = UDim2.new(1,-148,0,0)

	local function ctrlBtn(txt, xo, hc)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,28,0,22); b.Position = UDim2.new(1,xo,0.5,-11)
		b.BackgroundColor3 = T.BgElement; b.Text = txt; b.Font = Enum.Font.GothamBold
		b.TextSize = 12; b.TextColor3 = T.TextMuted; b.BorderSizePixel = 0; b.Parent = tb
		corner(b,6); stroke(b, T.Border, 1, 0.25)
		b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hc,TextColor3=T.TextPrimary},TI.Fast) end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=T.BgElement,TextColor3=T.TextMuted},TI.Fast) end)
		return b
	end

	local closeBtn = ctrlBtn("✕", -14, T.Error)
	local minBtn   = ctrlBtn("─", -48, T.AccentDark)
	local pinBtn   = ctrlBtn("📌", -82, T.AccentFaded)

	-- Боковая панель вкладок
	local sb = frm(mf, UDim2.new(0,152,1,-40), UDim2.new(0,0,0,40), T.BgTab, 0)
	pad(sb, 8,6,28,6); lst(sb, 4)
	frm(mf, UDim2.new(0,1,1,-40), UDim2.new(0,152,0,40), T.Sep, 0)

	-- Поиск вкладок
	local searchBg = frm(sb, UDim2.new(1,0,0,28), nil, T.BgInput, 0); corner(searchBg,7)
	stroke(searchBg, T.Border, 1, 0.3)
	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1,-20,1,0); searchBox.Position = UDim2.new(0,10,0,0)
	searchBox.BackgroundTransparency = 1; searchBox.Text = ""
	searchBox.PlaceholderText = "🔍 Поиск..."; searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 10; searchBox.TextColor3 = T.TextPrimary
	searchBox.PlaceholderColor3 = T.TextMuted; searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchBg

	-- Версия внизу боковой панели
	local verL = lbl(sb, "v"..VoidUI.Version, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	verL.Size = UDim2.new(1,0,0,16); verL.Position = UDim2.new(0,0,1,-22); verL.ZIndex = 2

	-- Контент-область
	local ca = Instance.new("Frame")
	ca.Size = UDim2.new(1,-153,1,-40); ca.Position = UDim2.new(0,153,0,40)
	ca.BackgroundTransparency = 1; ca.ClipsDescendants = true; ca.Parent = mf

	-- Перетаскивание окна (с зажимом в экране)
	local drag2, dStart2, dOrigin2 = false, nil, nil
	tb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag2=true; dStart2=i.Position; dOrigin2=mf.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag2 and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dStart2
			local nx = dOrigin2.X.Offset + d.X
			local ny = dOrigin2.Y.Offset + d.Y
			local cvp = workspace.CurrentCamera.ViewportSize
			nx = math.clamp(nx, 0, cvp.X - W)
			ny = math.clamp(ny, 0, cvp.Y - (minimized and 40 or H))
			mf.Position = UDim2.new(0, nx, 0, ny)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag2=false end
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		sb.Visible = not minimized; ca.Visible = not minimized
		tw(mf, {Size=UDim2.new(0,W,0,minimized and 40 or H)}, TI.Mid)
		minBtn.Text = minimized and "□" or "─"
	end)

	local pinned = false
	pinBtn.MouseButton1Click:Connect(function()
		pinned = not pinned
		tw(pinBtn, {BackgroundColor3 = pinned and T.AccentFaded or T.BgElement}, TI.Fast)
	end)

	closeBtn.MouseButton1Click:Connect(function()
		tw(mf, {BackgroundTransparency=1, Size=UDim2.new(0,W,0,8),
			Position=UDim2.new(0,mf.Position.X.Offset, 0,mf.Position.Y.Offset + H/2)}, TI.Mid)
		task.wait(0.28); sg:Destroy()
	end)

	UserInputService.InputBegan:Connect(function(i, gpe)
		if gpe then return end
		if i.KeyCode == tKey then
			mf.Visible = not mf.Visible
			if mf.Visible then tw(mf,{BackgroundTransparency=0},TI.Fast) end
		end
	end)

	-- ── Win object ────────────────────────────────────────────
	local Win = {}
	Win._tabs = {}; Win._active = nil
	Win._cfgFile = cfgFile; Win._cfgOn = cfgOn; Win._saved = saved
	Win._allElems = {}  -- для поиска

	function Win:SaveConfig()
		if self._cfgOn then cfgSave(self._cfgFile, VoidUI.Flags) end
	end

	function Win:SetAccent(color)
		T.Accent = color
		T.AccentDark  = Color3.new(color.R*0.6,color.G*0.6,color.B*0.6)
		T.AccentLight = Color3.new(math.min(color.R*1.3,1),math.min(color.G*1.3,1),math.min(color.B*1.3,1))
		glw.ImageColor3 = color; logoL.TextColor3 = color
	end

	function Win:Notify(o) VoidUI:Notify(o) end
	function Win:Destroy() sg:Destroy() end

	-- Поиск по вкладкам (фильтрует элементы по имени)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchBox.Text:lower()
		for _, info in ipairs(Win._allElems) do
			if q == "" then
				info.frame.Visible = true
			else
				info.frame.Visible = info.name:lower():find(q) ~= nil
			end
		end
	end)

	-- ════════════════════════════════════════════════════════
	--  CREATE TAB
	-- ════════════════════════════════════════════════════════
	function Win:CreateTab(name, icon, badge)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1,0,0,36); tabBtn.BackgroundColor3 = T.BgTab
		tabBtn.Text = ""; tabBtn.BorderSizePixel = 0
		tabBtn.LayoutOrder = #self._tabs+2; tabBtn.Parent = sb; corner(tabBtn,7)

		local stripe = frm(tabBtn, UDim2.new(0,3,0,22), UDim2.new(0,0,0.5,-11), T.Accent, 1); corner(stripe,3)

		local iconL = lbl(tabBtn, icon or "", 15, T.TextMuted, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
		iconL.Size = UDim2.new(0,24,1,0); iconL.Position = UDim2.new(0,8,0,0)

		local nL = lbl(tabBtn, name, 12, T.TextMuted, Enum.Font.GothamMedium)
		nL.Size = UDim2.new(1,-42,1,0); nL.Position = UDim2.new(0, icon and 34 or 12, 0, 0)

		-- Бейдж на вкладку
		local badgeL
		if badge then
			local bF = frm(tabBtn, UDim2.new(0,18,0,14), UDim2.new(1,-22,0.5,-7), T.Accent, 0); corner(bF,7)
			badgeL = lbl(bF, tostring(badge), 9, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			badgeL.Size = UDim2.new(1,0,1,0)
		end

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1,0,1,0); scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = T.ScrollBar; scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Visible = false; scroll.Parent = ca
		lst(scroll, 5); pad(scroll, 10,12,10,12)

		tabBtn.MouseEnter:Connect(function()
			if self._active ~= scroll then
				tw(tabBtn,{BackgroundColor3=T.BgHover},TI.Fast)
				tw(nL,{TextColor3=T.TextSub},TI.Fast)
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if self._active ~= scroll then
				tw(tabBtn,{BackgroundColor3=T.BgTab},TI.Fast)
				tw(nL,{TextColor3=T.TextMuted},TI.Fast)
			end
		end)

		local function activate()
			for _, t in ipairs(self._tabs) do
				t.sc.Visible = false
				tw(t.btn,{BackgroundColor3=T.BgTab},TI.Fast)
				tw(t.nL,{TextColor3=T.TextMuted},TI.Fast)
				tw(t.iL,{TextColor3=T.TextMuted},TI.Fast)
				tw(t.str,{BackgroundTransparency=1},TI.Fast)
			end
			scroll.Visible = true; self._active = scroll
			tw(tabBtn,{BackgroundColor3=T.BgHover},TI.Fast)
			tw(nL,{TextColor3=T.TextAccent},TI.Fast)
			tw(iconL,{TextColor3=T.Accent},TI.Fast)
			tw(stripe,{BackgroundTransparency=0},TI.Fast)
		end

		tabBtn.MouseButton1Click:Connect(function()
			activate(); local x,y = mrel(tabBtn); ripple(tabBtn,x,y)
		end)

		table.insert(self._tabs, {sc=scroll, btn=tabBtn, nL=nL, iL=iconL, str=stripe})
		if #self._tabs == 1 then task.defer(activate) end

		-- ── Tab object ──────────────────────────────────────
		local Tab = {}; Tab._lo = 0; Tab._win = self

		local function lo() Tab._lo += 1; return Tab._lo end

		local function elem(h, hasDesc, noHover)
			local c = frm(scroll, UDim2.new(1,0,0, hasDesc and h+20 or h), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); c.ClipsDescendants = true
			corner(c,7); stroke(c, T.Border, 1, 0.4)
			if not noHover then
				c.MouseEnter:Connect(function() tw(c,{BackgroundColor3=T.BgHover},TI.Fast) end)
				c.MouseLeave:Connect(function() tw(c,{BackgroundColor3=T.BgElement},TI.Fast) end)
			end
			return c
		end

		-- Регистрация элемента для поиска
		local function reg(c, n)
			table.insert(Win._allElems, {frame=c, name=n or ""})
		end

		-- ── Section ─────────────────────────────────────────
		function Tab:CreateSection(text)
			local sf = frm(scroll, UDim2.new(1,0,0,22), nil, T.Bg, 1); sf.LayoutOrder = lo()
			frm(sf, UDim2.new(0.36,-6,0,1), UDim2.new(0,0,0.5,0), T.Sep, 0)
			frm(sf, UDim2.new(0.36,-6,0,1), UDim2.new(0.64,6,0.5,0), T.Sep, 0)
			local sl = lbl(sf, text:upper(), 9, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			sl.Size = UDim2.new(0.28,0,1,0); sl.Position = UDim2.new(0.36,0,0,0); sl.LetterSpacing = 4
		end

		-- ── Separator ────────────────────────────────────────
		function Tab:CreateSeparator()
			local sf = frm(scroll, UDim2.new(1,0,0,1), nil, T.Sep, 0); sf.LayoutOrder = lo()
		end

		-- ── Divider с текстом ────────────────────────────────
		function Tab:CreateDivider(text)
			local df = frm(scroll, UDim2.new(1,0,0,1), nil, T.Sep, 0); df.LayoutOrder = lo()
			if text then
				local parent = frm(scroll, UDim2.new(1,0,0,18), nil, T.Bg, 1); parent.LayoutOrder = Tab._lo
				df.Parent = parent
				local dl = lbl(parent, text, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
				dl.Size = UDim2.new(1,0,1,0)
			end
		end

		-- ── Label ────────────────────────────────────────────
		function Tab:CreateLabel(text, color, size)
			local lf = frm(scroll, UDim2.new(1,0,0,22), nil, T.Bg, 1); lf.LayoutOrder = lo()
			local ll2 = lbl(lf, text or "", size or 11, color or T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
			ll2.Size = UDim2.new(1,0,1,0); ll2.TextWrapped = true; return ll2
		end

		-- ── Alert (информационный блок) ──────────────────────
		function Tab:CreateAlert(opts2)
			local aType = opts2.Type or "info"
			local cols2 = {info=T.Info, success=T.Success, warning=T.Warning, error=T.Error}
			local icons2 = {info="ℹ", success="✓", warning="⚠", error="✕"}
			local ac2 = cols2[aType] or T.Info

			local c = frm(scroll, UDim2.new(1,0,0,48), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); corner(c,7)
			stroke(c, ac2, 1, 0.3)
			-- Боковая полоска
			local ab2 = frm(c, UDim2.new(0,3,1,0), nil, ac2, 0); corner(ab2,3)
			-- Иконка
			local icf2 = frm(c, UDim2.new(0,24,0,24), UDim2.new(0,12,0.5,-12), T.AccentFaded, 0); corner(icf2,6)
			local icl2 = lbl(icf2, icons2[aType] or "·", 12, ac2, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			icl2.Size = UDim2.new(1,0,1,0)
			-- Текст
			local tl3 = lbl(c, opts2.Title or "", 12, T.TextPrimary, Enum.Font.GothamBold)
			tl3.Size = UDim2.new(1,-52,0,16); tl3.Position = UDim2.new(0,44,0,8)
			local cl3 = lbl(c, opts2.Content or "", 10, T.TextSub, Enum.Font.Gotham)
			cl3.Size = UDim2.new(1,-52,0,18); cl3.Position = UDim2.new(0,44,0,26)
			cl3.TextWrapped = true; cl3.TextTruncate = Enum.TextTruncate.None
		end

		-- ── Toggle ───────────────────────────────────────────
		function Tab:CreateToggle(opts2)
			local tFlag = opts2.Flag
			local tVal  = tFlag and (Win._saved[tFlag] ~= nil and Win._saved[tFlag] or opts2.CurrentValue) or (opts2.CurrentValue or false)
			local tDesc = opts2.Description; local tCb = opts2.Callback or function() end

			local c = elem(38, tDesc); local val = tVal; reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Toggle", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(1,-62,0,18); nl2.Position = UDim2.new(0,12,0, tDesc and 6 or 10)

			if tDesc then
				local dl = lbl(c, tDesc, 10, T.TextMuted)
				dl.Size = UDim2.new(1,-62,0,14); dl.Position = UDim2.new(0,12,0,24)
			end

			local tbg = frm(c, UDim2.new(0,42,0,23), UDim2.new(1,-54,0.5,-11.5), val and T.Accent or T.AccentFaded, 0)
			corner(tbg,12); stroke(tbg, T.Border, 1, 0.25)
			local th = frm(tbg, UDim2.new(0,17,0,17), val and UDim2.new(1,-20,0.5,-8.5) or UDim2.new(0,3,0.5,-8.5), T.TextPrimary, 0)
			corner(th,9)
			local sh = frm(th, UDim2.new(0,6,0,6), UDim2.new(0,2,0,2), Color3.new(1,1,1), 0.5); corner(sh,3)

			local function set(v, silent)
				val = v
				tw(tbg,{BackgroundColor3=v and T.Accent or T.AccentFaded},TI.Fast)
				tw(th,{Position=v and UDim2.new(1,-20,0.5,-8.5) or UDim2.new(0,3,0.5,-8.5)},TI.Fast)
				tw(nl2,{TextColor3=v and T.TextPrimary or T.TextSub},TI.Fast)
				if not silent then tCb(v); if tFlag then VoidUI.Flags[tFlag]=v; Win:SaveConfig() end end
			end
			set(tVal, true)

			local cb = Instance.new("TextButton")
			cb.Size=UDim2.new(1,0,1,0); cb.BackgroundTransparency=1; cb.Text=""; cb.Parent=c
			cb.MouseButton1Click:Connect(function() set(not val); local x,y=mrel(c); ripple(c,x,y) end)

			local obj = {}
			function obj:Set(v) set(v,false) end
			function obj:Get() return val end
			function obj:Toggle() set(not val,false) end
			return obj
		end

		-- ── MultiToggle (несколько опций с чекбоксами) ───────
		function Tab:CreateMultiToggle(opts2)
			local options = opts2.Options or {}
			local defaults = opts2.Defaults or {}
			local mCb = opts2.Callback or function() end
			local state = {}

			for _, o in ipairs(options) do
				state[o] = defaults[o] or false
			end

			local totalH = 32 + #options * 30
			local c = frm(scroll, UDim2.new(1,0,0,totalH), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); corner(c,7); stroke(c, T.Border, 1, 0.4); reg(c, opts2.Name)

			local nl2 = lbl(c, opts2.Name or "MultiToggle", 12, T.TextPrimary, Enum.Font.GothamBold)
			nl2.Size = UDim2.new(1,-24,0,18); nl2.Position = UDim2.new(0,12,0,8)

			local function buildOption(opt, idx)
				local row = frm(c, UDim2.new(1,-24,0,26), UDim2.new(0,12,0,28+(idx-1)*30), T.Bg, 0)
				corner(row,5)
				local rl = lbl(row, opt, 11, T.TextSub, Enum.Font.Gotham)
				rl.Size = UDim2.new(1,-40,1,0); rl.Position = UDim2.new(0,10,0,0)

				local tbg2 = frm(row, UDim2.new(0,34,0,18), UDim2.new(1,-40,0.5,-9), state[opt] and T.Accent or T.AccentFaded, 0)
				corner(tbg2,9); stroke(tbg2, T.Border, 1, 0.3)
				local th2 = frm(tbg2, UDim2.new(0,14,0,14),
					state[opt] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7), T.TextPrimary, 0)
				corner(th2,7)

				local rb = Instance.new("TextButton")
				rb.Size=UDim2.new(1,0,1,0); rb.BackgroundTransparency=1; rb.Text=""; rb.Parent=row
				rb.MouseButton1Click:Connect(function()
					state[opt] = not state[opt]
					tw(tbg2,{BackgroundColor3=state[opt] and T.Accent or T.AccentFaded},TI.Fast)
					tw(th2,{Position=state[opt] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)},TI.Fast)
					tw(rl,{TextColor3=state[opt] and T.TextPrimary or T.TextSub},TI.Fast)
					mCb(state)
				end)
			end

			for i, opt in ipairs(options) do
				buildOption(opt, i)
			end

			local obj = {}
			function obj:Get() return state end
			function obj:Set(o, v) state[o]=v end
			return obj
		end

		-- ── Radio (одиночный выбор) ───────────────────────────
		function Tab:CreateRadio(opts2)
			local options = opts2.Options or {}
			local def = opts2.Default or options[1]
			local rCb = opts2.Callback or function() end
			local selected = def

			local totalH = 32 + #options * 28
			local c = frm(scroll, UDim2.new(1,0,0,totalH), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); corner(c,7); stroke(c, T.Border, 1, 0.4); reg(c, opts2.Name)

			local nl2 = lbl(c, opts2.Name or "Radio", 12, T.TextPrimary, Enum.Font.GothamBold)
			nl2.Size = UDim2.new(1,-24,0,18); nl2.Position = UDim2.new(0,12,0,7)

			local dots = {}

			local function selectOpt(opt)
				selected = opt
				for o, parts in pairs(dots) do
					local active = o == opt
					tw(parts.outer,{BackgroundColor3=active and T.Accent or T.AccentFaded},TI.Fast)
					tw(parts.inner,{BackgroundTransparency=active and 0 or 1},TI.Fast)
					tw(parts.lbl,{TextColor3=active and T.TextPrimary or T.TextSub},TI.Fast)
				end
				rCb(opt)
			end

			for i, opt in ipairs(options) do
				local row = frm(c, UDim2.new(1,-24,0,24), UDim2.new(0,12,0,28+(i-1)*28), T.Bg, 0)
				corner(row,5)
				-- Radio dot
				local outer = frm(row, UDim2.new(0,16,0,16), UDim2.new(0,8,0.5,-8),
					opt==def and T.Accent or T.AccentFaded, 0); corner(outer,99)
				stroke(outer, T.Border, 1, 0.2)
				local inner = frm(outer, UDim2.new(0,8,0,8), UDim2.new(0.5,-4,0.5,-4),
					T.TextPrimary, opt==def and 0 or 1); corner(inner,99)
				local rl = lbl(row, opt, 11, opt==def and T.TextPrimary or T.TextSub, Enum.Font.Gotham)
				rl.Size = UDim2.new(1,-36,1,0); rl.Position = UDim2.new(0,32,0,0)
				dots[opt] = {outer=outer, inner=inner, lbl=rl}

				local rb = Instance.new("TextButton")
				rb.Size=UDim2.new(1,0,1,0); rb.BackgroundTransparency=1; rb.Text=""; rb.Parent=row
				rb.MouseButton1Click:Connect(function() selectOpt(opt) end)
			end

			local obj = {}
			function obj:Get() return selected end
			function obj:Set(v) selectOpt(v) end
			return obj
		end

		-- ── Slider ───────────────────────────────────────────
		function Tab:CreateSlider(opts2)
			local sFlag = opts2.Flag; local sRange = opts2.Range or {0,100}; local sInc = opts2.Increment or 1
			local sDef  = sFlag and (Win._saved[sFlag] or opts2.CurrentValue) or (opts2.CurrentValue or sRange[1])
			local sSuf  = opts2.Suffix or ""; local sCb = opts2.Callback or function() end

			local c = elem(54); local val = math.clamp(sDef, sRange[1], sRange[2]); reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Slider", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(1,-72,0,16); nl2.Position = UDim2.new(0,12,0,8)
			local vl = lbl(c, tostring(val)..sSuf, 13, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0,58,0,16); vl.Position = UDim2.new(1,-70,0,8)

			local track = frm(c, UDim2.new(1,-24,0,6), UDim2.new(0,12,0,36), T.Border, 0); corner(track,6)
			local fill  = frm(track, UDim2.new(0,0,1,0), nil, T.Accent, 0); corner(fill,6)
			grad(fill, {T.AccentLight, T.Accent}, 0)
			local thumb = frm(track, UDim2.new(0,18,0,18), UDim2.new(0,-9,0.5,-9), T.AccentLight, 0)
			corner(thumb,9); stroke(thumb, T.Accent, 2, 0); thumb.ZIndex = 4

			-- Значение над ползунком при перетаскивании
			local tooltip = frm(thumb, UDim2.new(0,44,0,20), UDim2.new(0.5,-22,0,-26), T.BgLight, 0)
			corner(tooltip,5); stroke(tooltip, T.Border, 1, 0); tooltip.Visible = false
			local ttl2 = lbl(tooltip, "", 10, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			ttl2.Size = UDim2.new(1,0,1,0)

			local function upd(v)
				v = math.clamp(math.round(v/sInc)*sInc, sRange[1], sRange[2]); val = v
				local p = (v-sRange[1])/(sRange[2]-sRange[1])
				tw(fill,{Size=UDim2.new(p,0,1,0)},TI.Fast)
				tw(thumb,{Position=UDim2.new(p,-9,0.5,-9)},TI.Fast)
				vl.Text = tostring(v)..sSuf; ttl2.Text = tostring(v)..sSuf; sCb(v)
				if sFlag then VoidUI.Flags[sFlag]=v; Win:SaveConfig() end
			end

			local p0 = (val-sRange[1])/(sRange[2]-sRange[1])
			fill.Size = UDim2.new(p0,0,1,0); thumb.Position = UDim2.new(p0,-9,0.5,-9)

			local dragS = false
			local function pct(x) return math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1) end
			thumb.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					dragS=true; tooltip.Visible=true
				end
			end)
			track.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					dragS=true; tooltip.Visible=true
					upd(sRange[1]+(sRange[2]-sRange[1])*pct(i.Position.X))
				end
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					dragS=false; tooltip.Visible=false
				end
			end)
			UserInputService.InputChanged:Connect(function(i)
				if dragS and i.UserInputType==Enum.UserInputType.MouseMovement then
					upd(sRange[1]+(sRange[2]-sRange[1])*pct(i.Position.X))
				end
			end)

			local obj = {}
			function obj:Set(v) upd(v) end
			function obj:Get() return val end
			return obj
		end

		-- ── Stepper (± кнопки) ──────────────────────────────
		function Tab:CreateStepper(opts2)
			local sMin = opts2.Min or 0; local sMax = opts2.Max or 10
			local sStep = opts2.Step or 1; local sSuf2 = opts2.Suffix or ""
			local sDef2 = opts2.Default or sMin; local sCb2 = opts2.Callback or function() end
			local val = math.clamp(sDef2, sMin, sMax)

			local c = elem(36); reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Stepper", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(0.45,0,0,16); nl2.Position = UDim2.new(0,12,0.5,-8)

			-- Контролы
			local ctrlF = frm(c, UDim2.new(0,90,0,26), UDim2.new(1,-102,0.5,-13), T.Bg, 0)
			corner(ctrlF,7); stroke(ctrlF, T.Border, 1, 0.3)

			local minusB = Instance.new("TextButton")
			minusB.Size=UDim2.new(0,26,1,0); minusB.BackgroundTransparency=1
			minusB.Text="−"; minusB.Font=Enum.Font.GothamBold; minusB.TextSize=14
			minusB.TextColor3=T.TextSub; minusB.BorderSizePixel=0; minusB.Parent=ctrlF

			local valL = lbl(ctrlF, tostring(val)..sSuf2, 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			valL.Size = UDim2.new(1,-52,1,0); valL.Position = UDim2.new(0,26,0,0)

			local plusB = Instance.new("TextButton")
			plusB.Size=UDim2.new(0,26,1,0); plusB.Position=UDim2.new(1,-26,0,0)
			plusB.BackgroundTransparency=1; plusB.Text="+"
			plusB.Font=Enum.Font.GothamBold; plusB.TextSize=14
			plusB.TextColor3=T.TextSub; plusB.BorderSizePixel=0; plusB.Parent=ctrlF

			local function update(v)
				val = math.clamp(v, sMin, sMax)
				valL.Text = tostring(val)..sSuf2
				tw(valL,{TextColor3=T.TextAccent},TI.Fast); sCb2(val)
			end

			minusB.MouseButton1Click:Connect(function() update(val - sStep) end)
			plusB.MouseButton1Click:Connect(function() update(val + sStep) end)

			local obj = {}
			function obj:Get() return val end
			function obj:Set(v) update(v) end
			return obj
		end

		-- ── Button ───────────────────────────────────────────
		function Tab:CreateButton(opts2)
			local bCb = opts2.Callback or function() end; local bDesc = opts2.Description
			local c = elem(36, bDesc); c.ClipsDescendants = true; reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Button", 12, T.TextPrimary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
			nl2.Size = UDim2.new(1,-32,0,18); nl2.Position = UDim2.new(0,12,0, bDesc and 6 or 9)
			if bDesc then
				local dl = lbl(c, bDesc, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
				dl.Size = UDim2.new(1,-32,0,14); dl.Position = UDim2.new(0,12,0,24)
			end
			-- Акцентная стрелка
			local arr = lbl(c, opts2.Icon or "›", 16, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			arr.Size = UDim2.new(0,18,1,0); arr.Position = UDim2.new(1,-24,0,0)
			-- Левая полоска при ховере
			local lstripe = frm(c, UDim2.new(0,2,0,18), UDim2.new(0,0,0.5,-9), T.Accent, 1); corner(lstripe,2)

			local btn = Instance.new("TextButton")
			btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=c
			btn.MouseEnter:Connect(function()
				tw(nl2,{TextColor3=T.TextAccent},TI.Fast); tw(arr,{TextColor3=T.Accent},TI.Fast)
				tw(lstripe,{BackgroundTransparency=0},TI.Fast)
			end)
			btn.MouseLeave:Connect(function()
				tw(nl2,{TextColor3=T.TextPrimary},TI.Fast); tw(arr,{TextColor3=T.TextMuted},TI.Fast)
				tw(lstripe,{BackgroundTransparency=1},TI.Fast)
			end)
			btn.MouseButton1Down:Connect(function() tw(c,{BackgroundColor3=T.AccentFaded},TI.Fast) end)
			btn.MouseButton1Click:Connect(function()
				tw(c,{BackgroundColor3=T.BgHover},TI.Fast)
				local x,y=mrel(c); ripple(c,x,y); bCb()
			end)
		end

		-- ── Chip row (горизонтальные кнопки-теги) ───────────
		function Tab:CreateChips(opts2)
			local chips = opts2.Options or {}
			local def2 = opts2.Default
			local multi = opts2.Multi or false
			local cCb = opts2.Callback or function() end
			local selected2 = multi and {} or def2

			local c = frm(scroll, UDim2.new(1,0,0,56), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); corner(c,7); stroke(c, T.Border, 1, 0.4); reg(c, opts2.Name)

			local nl2 = lbl(c, opts2.Name or "", 11, T.TextMuted, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(1,0,0,16); nl2.Position = UDim2.new(0,12,0,6)

			local chipRow = Instance.new("Frame")
			chipRow.Size = UDim2.new(1,-24,0,26); chipRow.Position = UDim2.new(0,12,0,26)
			chipRow.BackgroundTransparency = 1; chipRow.Parent = c
			local cl3 = lst(chipRow, 6, Enum.FillDirection.Horizontal)
			cl3.HorizontalAlignment = Enum.HorizontalAlignment.Left

			local chipBtns = {}

			for _, chip in ipairs(chips) do
				local cf = Instance.new("TextButton")
				cf.Size = UDim2.new(0, #chip * 7 + 20, 0, 22)
				cf.BackgroundColor3 = chip==def2 and T.AccentFaded or T.BgInput
				cf.Text = chip; cf.Font = Enum.Font.GothamMedium; cf.TextSize = 10
				cf.TextColor3 = chip==def2 and T.TextAccent or T.TextMuted
				cf.BorderSizePixel = 0; cf.Parent = chipRow
				corner(cf, 11); stroke(cf, T.Border, 1, 0.2)
				chipBtns[chip] = cf

				cf.MouseButton1Click:Connect(function()
					if multi then
						selected2[chip] = not selected2[chip]
						tw(cf,{BackgroundColor3=selected2[chip] and T.AccentFaded or T.BgInput},TI.Fast)
						tw(cf,{TextColor3=selected2[chip] and T.TextAccent or T.TextMuted},TI.Fast)
						cCb(selected2)
					else
						selected2 = chip
						for o2, bf in pairs(chipBtns) do
							tw(bf,{BackgroundColor3=o2==chip and T.AccentFaded or T.BgInput},TI.Fast)
							bf.TextColor3 = o2==chip and T.TextAccent or T.TextMuted
						end
						cCb(chip)
					end
				end)
			end

			local obj = {}
			function obj:Get() return selected2 end
			return obj
		end

		-- ── Dropdown ─────────────────────────────────────────
		function Tab:CreateDropdown(opts2)
			local dFlag = opts2.Flag; local dOpts = opts2.Options or {}
			local dDef  = dFlag and (Win._saved[dFlag] or opts2.CurrentOption) or opts2.CurrentOption
			local dCb   = opts2.Callback or function() end; local dMulti = opts2.Multi or false
			local val   = dDef; local open = false; local sel = {}

			local c = elem(36); c.ClipsDescendants = false; c.ZIndex = 5; reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Dropdown", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(0.5,0,0,18); nl2.Position = UDim2.new(0,12,0.5,-9)
			local vl = lbl(c, type(val)=="table" and (#val.." selected") or (val or "Выбрать..."), 11, T.TextAccent, Enum.Font.Gotham, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0.4,-8,0,18); vl.Position = UDim2.new(0.5,0,0.5,-9)
			local al = lbl(c, "▾", 13, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			al.Size = UDim2.new(0,18,0,18); al.Position = UDim2.new(1,-26,0.5,-9)

			local dd = frm(c, UDim2.new(1,0,0,0), UDim2.new(0,0,1,5), T.BgLight, 0)
			dd.ClipsDescendants = true; dd.ZIndex = 10; dd.Visible = false
			corner(dd,7); stroke(dd, T.Border, 1, 0); lst(dd, 2); pad(dd,4,4,4,4)

			local function refreshVl()
				if dMulti then
					local s = {}; for o,v2 in pairs(sel) do if v2 then s[#s+1]=o end end
					vl.Text = #s>0 and (#s.." selected") or "Ничего"
				else
					vl.Text = val or "Выбрать..."
				end
			end

			for _, opt in ipairs(dOpts) do
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1,0,0,30); ob.BackgroundColor3 = T.BgLight
				ob.Text = ""; ob.BorderSizePixel = 0; ob.Parent = dd; corner(ob,5)
				local ol = lbl(ob, opt, 11, opt==val and T.TextAccent or T.TextSub)
				ol.Size = UDim2.new(1,-16,1,0); ol.Position = UDim2.new(0,8,0,0)
				local chk
				if dMulti then
					chk = frm(ob, UDim2.new(0,14,0,14), UDim2.new(1,-22,0.5,-7), T.AccentFaded, 0)
					corner(chk,4); stroke(chk, T.Border, 1, 0)
				end
				ob.MouseEnter:Connect(function() tw(ob,{BackgroundColor3=T.BgHover},TI.Fast); tw(ol,{TextColor3=T.TextPrimary},TI.Fast) end)
				ob.MouseLeave:Connect(function()
					tw(ob,{BackgroundColor3=T.BgLight},TI.Fast)
					tw(ol,{TextColor3=(dMulti and sel[opt] or opt==val) and T.TextAccent or T.TextSub},TI.Fast)
				end)
				ob.MouseButton1Click:Connect(function()
					if dMulti then
						sel[opt] = not sel[opt]
						tw(chk,{BackgroundColor3=sel[opt] and T.Accent or T.AccentFaded},TI.Fast)
						tw(ol,{TextColor3=sel[opt] and T.TextAccent or T.TextSub},TI.Fast)
						local r={}; for o2,v2 in pairs(sel) do if v2 then r[#r+1]=o2 end end
						val=r; refreshVl(); dCb(r)
					else
						val=opt; refreshVl()
						for _,ch in ipairs(dd:GetChildren()) do
							if ch:IsA("TextButton") then
								local cll=ch:FindFirstChildOfClass("TextLabel")
								if cll then tw(cll,{TextColor3=T.TextSub},TI.Fast) end
							end
						end
						tw(ol,{TextColor3=T.TextAccent},TI.Fast)
						open=false; tw(dd,{Size=UDim2.new(1,0,0,0)},TI.Fast); tw(al,{Rotation=0},TI.Fast)
						task.wait(0.14); dd.Visible=false; dCb(opt)
						if dFlag then VoidUI.Flags[dFlag]=opt; Win:SaveConfig() end
					end
				end)
			end

			local mb = Instance.new("TextButton")
			mb.Size=UDim2.new(1,0,1,0); mb.BackgroundTransparency=1; mb.Text=""; mb.Parent=c
			mb.MouseButton1Click:Connect(function()
				open=not open; local th2=open and math.min(#dOpts*34+8,180) or 0
				dd.Visible=true; tw(dd,{Size=UDim2.new(1,0,0,th2)},TI.Fast); tw(al,{Rotation=open and 180 or 0},TI.Fast)
				if not open then task.delay(0.16,function() dd.Visible=false end) end
			end)

			local obj = {}
			function obj:Set(v) val=v; refreshVl(); dCb(v) end
			function obj:Get() return val end
			function obj:AddOption(o) table.insert(dOpts,o) end
			function obj:Clear() val=nil; refreshVl() end
			return obj
		end

		-- ── Input ────────────────────────────────────────────
		function Tab:CreateInput(opts2)
			local iFlag = opts2.Flag; local iCb = opts2.Callback or function() end
			local iLive = opts2.LiveUpdate or false; local iNum = opts2.NumberOnly or false
			local c = elem(52); reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Input", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(1,-24,0,16); nl2.Position = UDim2.new(0,12,0,6)
			local ibg = frm(c, UDim2.new(1,-24,0,24), UDim2.new(0,12,0,26), T.BgInput, 0)
			corner(ibg,5); local ibs = stroke(ibg, T.Border, 1, 0.2)
			local ib = Instance.new("TextBox")
			ib.Size=UDim2.new(1,-12,1,0); ib.Position=UDim2.new(0,6,0,0)
			ib.BackgroundTransparency=1; ib.Text=""
			ib.PlaceholderText=opts2.Placeholder or "Введите значение..."
			ib.Font=Enum.Font.Gotham; ib.TextSize=11; ib.TextColor3=T.TextPrimary
			ib.PlaceholderColor3=T.TextMuted; ib.ClearTextOnFocus=false; ib.Parent=ibg
			ib.Focused:Connect(function() tw(ibg,{BackgroundColor3=T.BgLight},TI.Fast); ibs.Color=T.Accent; ibs.Transparency=0 end)
			ib.FocusLost:Connect(function(e)
				tw(ibg,{BackgroundColor3=T.BgInput},TI.Fast); ibs.Color=T.Border; ibs.Transparency=0.2
				if e then local v2=iNum and tonumber(ib.Text) or ib.Text; iCb(v2); if iFlag then VoidUI.Flags[iFlag]=v2; Win:SaveConfig() end end
			end)
			if iLive then ib:GetPropertyChangedSignal("Text"):Connect(function() iCb(iNum and tonumber(ib.Text) or ib.Text) end) end
			local obj = {}
			function obj:Set(v2) ib.Text=tostring(v2) end
			function obj:Get() return ib.Text end
			function obj:Clear() ib.Text="" end
			return obj
		end

		-- ── Keybind ──────────────────────────────────────────
		function Tab:CreateKeybind(opts2)
			local kFlag = opts2.Flag; local val = opts2.CurrentKey or Enum.KeyCode.Unknown
			local kCb = opts2.Callback or function() end; local kHold = opts2.HoldToTrigger or false
			local binding = false; local held = false
			local c = elem(36); reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Keybind", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(0.6,0,0,18); nl2.Position = UDim2.new(0,12,0.5,-9)
			local kbg = frm(c, UDim2.new(0,82,0,26), UDim2.new(1,-94,0.5,-13), T.BgInput, 0)
			corner(kbg,6); stroke(kbg, T.Border, 1, 0.2)
			local kl = lbl(kbg, val.Name, 11, T.TextAccent, Enum.Font.Code, Enum.TextXAlignment.Center)
			kl.Size = UDim2.new(1,0,1,0)
			local btn2 = Instance.new("TextButton")
			btn2.Size=UDim2.new(1,0,1,0); btn2.BackgroundTransparency=1; btn2.Text=""; btn2.Parent=c
			btn2.MouseButton1Click:Connect(function()
				binding=true; kl.Text="..."; kl.TextColor3=T.TextSub
				tw(kbg,{BackgroundColor3=T.AccentFaded},TI.Fast)
			end)
			UserInputService.InputBegan:Connect(function(i, gpe)
				if binding and i.UserInputType==Enum.UserInputType.Keyboard then
					binding=false; val=i.KeyCode; kl.Text=i.KeyCode.Name; kl.TextColor3=T.TextAccent
					tw(kbg,{BackgroundColor3=T.BgInput},TI.Fast)
					if kFlag then VoidUI.Flags[kFlag]=i.KeyCode.Name; Win:SaveConfig() end
					kCb(i.KeyCode); return
				end
				if not gpe and not binding and i.KeyCode==val then
					if kHold then held=true else kCb(val) end
				end
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.KeyCode==val and kHold and held then held=false; kCb(val) end
			end)
			local obj = {}
			function obj:Get() return val end
			function obj:Set(k) val=k; kl.Text=k.Name end
			return obj
		end

		-- ── ColorPicker ──────────────────────────────────────
		function Tab:CreateColorPicker(opts2)
			local cFlag = opts2.Flag; local cDef = opts2.Default or Color3.fromRGB(138,58,255)
			local cCb = opts2.Callback or function() end
			local val = cDef; local open = false
			local hue, sat, bri = Color3.toHSV(cDef)

			local c = elem(36); c.ClipsDescendants = false; reg(c, opts2.Name)
			local nl2 = lbl(c, opts2.Name or "Цвет", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(1,-72,0,18); nl2.Position = UDim2.new(0,12,0.5,-9)
			local prev = frm(c, UDim2.new(0,34,0,22), UDim2.new(1,-50,0.5,-11), val, 0)
			corner(prev,6); stroke(prev, T.Border, 1, 0)
			local al = lbl(c, "▾", 13, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			al.Size = UDim2.new(0,16,0,18); al.Position = UDim2.new(1,-22,0.5,-9)

			local pk = frm(c, UDim2.new(1,0,0,0), UDim2.new(0,0,1,5), T.BgLight, 0)
			pk.ClipsDescendants=true; pk.ZIndex=8; pk.Visible=false; corner(pk,7); stroke(pk,T.Border,1,0)
			pad(pk,8,8,8,8)

			local function applyCol()
				val = Color3.fromHSV(hue, sat, bri)
				prev.BackgroundColor3 = val; cCb(val)
				if cFlag then VoidUI.Flags[cFlag]={val.R,val.G,val.B}; Win:SaveConfig() end
			end

			local hBar = frm(pk, UDim2.new(1,0,0,14), UDim2.new(0,0,0,0), T.Bg, 0); corner(hBar,4)
			grad(hBar, {Color3.fromHSV(0,1,1),Color3.fromHSV(0.17,1,1),Color3.fromHSV(0.33,1,1),
				Color3.fromHSV(0.5,1,1),Color3.fromHSV(0.67,1,1),Color3.fromHSV(0.83,1,1),Color3.fromHSV(1,1,1)},0)
			local hTh = frm(hBar, UDim2.new(0,4,1,4), UDim2.new(hue,-2,0,-2), T.TextPrimary, 0); corner(hTh,2)
			stroke(hTh, T.Bg, 1, 0)

			local svB = frm(pk, UDim2.new(1,0,0,80), UDim2.new(0,0,0,22), Color3.fromHSV(hue,1,1), 0); corner(svB,4)
			local svW = Instance.new("UIGradient"); svW.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1))})
			svW.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}); svW.Parent=svB
			local svHf = frm(svB, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0), 0)
			local svHg = Instance.new("UIGradient"); svHg.Rotation=90
			svHg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),ColorSequenceKeypoint.new(1,Color3.new(0,0,0))})
			svHg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); svHg.Parent=svHf
			local svTh = frm(svB, UDim2.new(0,12,0,12), UDim2.new(sat,-6,1-bri,-6), T.TextPrimary, 0)
			corner(svTh,6); stroke(svTh, T.Bg, 1.5, 0); svTh.ZIndex=3

			local dH, dSV = false, false
			hBar.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					dH=true; hue=math.clamp((i.Position.X-hBar.AbsolutePosition.X)/hBar.AbsoluteSize.X,0,1)
					tw(hTh,{Position=UDim2.new(hue,-2,0,-2)},TI.Fast)
					svB.BackgroundColor3=Color3.fromHSV(hue,1,1)
					svW.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1))})
					applyCol()
				end
			end)
			svB.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then
					dSV=true; sat=math.clamp((i.Position.X-svB.AbsolutePosition.X)/svB.AbsoluteSize.X,0,1)
					bri=1-math.clamp((i.Position.Y-svB.AbsolutePosition.Y)/svB.AbsoluteSize.Y,0,1)
					tw(svTh,{Position=UDim2.new(sat,-6,1-bri,-6)},TI.Fast); applyCol()
				end
			end)
			UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dH=false; dSV=false end end)
			UserInputService.InputChanged:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseMovement then
					if dH then hue=math.clamp((i.Position.X-hBar.AbsolutePosition.X)/hBar.AbsoluteSize.X,0,1)
						tw(hTh,{Position=UDim2.new(hue,-2,0,-2)},TI.Fast)
						svB.BackgroundColor3=Color3.fromHSV(hue,1,1)
						svW.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1))})
						applyCol()
					elseif dSV then
						sat=math.clamp((i.Position.X-svB.AbsolutePosition.X)/svB.AbsoluteSize.X,0,1)
						bri=1-math.clamp((i.Position.Y-svB.AbsolutePosition.Y)/svB.AbsoluteSize.Y,0,1)
						tw(svTh,{Position=UDim2.new(sat,-6,1-bri,-6)},TI.Fast); applyCol()
					end
				end
			end)

			local mb = Instance.new("TextButton")
			mb.Size=UDim2.new(1,0,1,0); mb.BackgroundTransparency=1; mb.Text=""; mb.Parent=c
			mb.MouseButton1Click:Connect(function()
				open=not open; pk.Visible=true
				tw(pk,{Size=UDim2.new(1,0,0,open and 118 or 0)},TI.Fast)
				tw(al,{Rotation=open and 180 or 0},TI.Fast)
				if not open then task.delay(0.16,function() pk.Visible=false end) end
			end)

			local obj = {}
			function obj:Set(color)
				val=color; prev.BackgroundColor3=color
				hue,sat,bri=Color3.toHSV(color)
				svB.BackgroundColor3=Color3.fromHSV(hue,1,1)
				tw(hTh,{Position=UDim2.new(hue,-2,0,-2)},TI.Fast)
				tw(svTh,{Position=UDim2.new(sat,-6,1-bri,-6)},TI.Fast)
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
			nl2.Size = UDim2.new(1,-70,0,16); nl2.Position = UDim2.new(0,12,0,6)
			local vl = lbl(c, tostring(pVal)..pSuf, 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0,56,0,16); vl.Position = UDim2.new(1,-68,0,6)
			local track = frm(c, UDim2.new(1,-24,0,7), UDim2.new(0,12,0,30), T.Border, 0); corner(track,6)
			local fill  = frm(track, UDim2.new(0,0,1,0), nil, pCol, 0); corner(fill,6)
			grad(fill, {Color3.new(math.min(pCol.R*1.3,1),math.min(pCol.G*1.3,1),math.min(pCol.B*1.3,1)),pCol},0)
			fill.Size = UDim2.new(math.clamp((pVal-pMin)/(pMax-pMin),0,1),0,1,0)

			local obj = {}
			function obj:Set(v)
				v=math.clamp(v,pMin,pMax)
				tw(fill,{Size=UDim2.new((v-pMin)/(pMax-pMin),0,1,0)},TI.Mid)
				vl.Text=tostring(math.round(v))..pSuf
			end
			function obj:SetMax(m) pMax=m end
			function obj:SetColor(col) pCol=col; fill.BackgroundColor3=col end
			return obj
		end

		-- ── TextDisplay (ключ-значение строка) ───────────────
		function Tab:CreateTextDisplay(opts2)
			local c = elem(36); reg(c, opts2.Name or "")
			local nl2 = lbl(c, opts2.Name or "", 11, T.TextMuted, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(0.48,0,0,16); nl2.Position = UDim2.new(0,12,0.5,-8)
			local vl = lbl(c, opts2.Text or "", opts2.Size or 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0.48,0,0,16); vl.Position = UDim2.new(0.48,0,0.5,-8)
			local obj = {}
			function obj:Set(v) vl.Text=tostring(v) end
			function obj:SetColor(col) vl.TextColor3=col end
			function obj:Get() return vl.Text end
			return obj
		end

		-- ── Table (таблица данных) ────────────────────────────
		function Tab:CreateTable(opts2)
			local headers = opts2.Headers or {}
			local rows    = opts2.Rows or {}
			local rowH    = 28
			local totalH  = 32 + #rows * rowH + 2

			local c = frm(scroll, UDim2.new(1,0,0,totalH), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); corner(c,7); stroke(c, T.Border, 1, 0.4); reg(c, opts2.Name or "Table")

			-- Заголовок таблицы
			local head = frm(c, UDim2.new(1,0,0,28), nil, T.AccentFaded, 0)
			corner(head,7); -- нижние углы убираем
			local headList = lst(head, 0, Enum.FillDirection.Horizontal)

			local colW = 1 / math.max(#headers, 1)
			for _, h in ipairs(headers) do
				local hl = lbl(head, h, 10, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
				hl.Size = UDim2.new(colW, 0, 1, 0)
			end

			-- Строки
			for ri, row in ipairs(rows) do
				local rf = frm(c, UDim2.new(1,0,0,rowH), UDim2.new(0,0,0,28+(ri-1)*rowH),
					ri%2==0 and T.BgLight or T.BgElement, 0)
				lst(rf, 0, Enum.FillDirection.Horizontal)
				for ci, cell in ipairs(row) do
					local cl4 = lbl(rf, tostring(cell), 10, T.TextSub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
					cl4.Size = UDim2.new(colW, 0, 1, 0)
				end
			end

			local obj = {}
			function obj:AddRow(row)
				local ri = #c:GetChildren() - 1
				local rf = frm(c, UDim2.new(1,0,0,rowH), UDim2.new(0,0,0,28+ri*rowH),
					ri%2==0 and T.BgLight or T.BgElement, 0)
				lst(rf, 0, Enum.FillDirection.Horizontal)
				for _, cell in ipairs(row) do
					local cl4 = lbl(rf, tostring(cell), 10, T.TextSub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
					cl4.Size = UDim2.new(colW, 0, 1, 0)
				end
				c.Size = UDim2.new(1,0,0,c.Size.Y.Offset + rowH)
			end
			return obj
		end

		-- ── Accordion (сворачиваемый блок) ───────────────────
		function Tab:CreateAccordion(opts2)
			local aTitle = opts2.Title or "Accordion"
			local aOpen  = opts2.DefaultOpen or false

			local wrapper = frm(scroll, UDim2.new(1,0,0,36), nil, T.BgElement, 0)
			wrapper.LayoutOrder = lo(); wrapper.ClipsDescendants = true
			corner(wrapper,7); stroke(wrapper, T.Border, 1, 0.4); reg(wrapper, aTitle)

			-- Хедер
			local header = frm(wrapper, UDim2.new(1,0,0,36), nil, T.BgElement, 0)
			local hl2 = lbl(header, aTitle, 12, T.TextPrimary, Enum.Font.GothamBold)
			hl2.Size = UDim2.new(1,-36,1,0); hl2.Position = UDim2.new(0,12,0,0)
			local arrowL = lbl(header, "›", 16, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			arrowL.Size = UDim2.new(0,24,1,0); arrowL.Position = UDim2.new(1,-30,0,0)
			if aOpen then arrowL.Rotation = 90 end

			-- Контент-область аккордеона
			local inner = frm(wrapper, UDim2.new(1,-24,0,0), UDim2.new(0,12,0,40), T.Bg, 0)
			inner.ClipsDescendants = true; corner(inner,5)
			local innerList = lst(inner, 4); pad(inner, 4,0,4,0)
			inner.AutomaticCanvasSize = Enum.AutomaticSize.None

			local expanded = aOpen
			local innerH = 0

			local function recalcH()
				local total = 0
				for _, ch in ipairs(inner:GetChildren()) do
					if ch:IsA("Frame") or ch:IsA("TextButton") then
						total += ch.AbsoluteSize.Y + 4
					end
				end
				return total
			end

			local function toggleAccordion()
				expanded = not expanded
				tw(arrowL,{Rotation=expanded and 90 or 0},TI.Fast)
				if expanded then
					innerH = recalcH() + 12
					tw(wrapper,{Size=UDim2.new(1,0,0,40+innerH)},TI.Mid)
					tw(inner,{Size=UDim2.new(1,-24,0,innerH)},TI.Mid)
				else
					tw(wrapper,{Size=UDim2.new(1,0,0,36)},TI.Mid)
					tw(inner,{Size=UDim2.new(1,-24,0,0)},TI.Mid)
				end
			end

			local hBtn = Instance.new("TextButton")
			hBtn.Size=UDim2.new(1,0,0,36); hBtn.BackgroundTransparency=1; hBtn.Text=""; hBtn.Parent=header
			hBtn.MouseButton1Click:Connect(toggleAccordion)
			header.MouseEnter:Connect(function() tw(header,{BackgroundColor3=T.BgHover},TI.Fast) end)
			header.MouseLeave:Connect(function() tw(header,{BackgroundColor3=T.BgElement},TI.Fast) end)

			-- Если изначально открыт — открываем после рендера
			if aOpen then
				task.defer(function()
					innerH = recalcH() + 12
					wrapper.Size = UDim2.new(1,0,0,40+math.max(innerH,0))
					inner.Size = UDim2.new(1,-24,0,math.max(innerH,0))
				end)
			end

			-- Возвращаем мини-Tab для inner
			local InnerTab = {}
			InnerTab._lo = 0

			local function ilo() InnerTab._lo += 1; return InnerTab._lo end
			local function ielem(h2)
				local cf = frm(inner, UDim2.new(1,0,0,h2), nil, T.BgElement, 0)
				cf.LayoutOrder = ilo(); corner(cf,5); stroke(cf,T.Border,1,0.5)
				return cf
			end

			function InnerTab:CreateToggle(o2)
				local tCb2 = o2.Callback or function() end; local val2 = o2.CurrentValue or false
				local cf = ielem(30)
				local nl3 = lbl(cf, o2.Name or "Toggle", 11, T.TextPrimary, Enum.Font.GothamMedium)
				nl3.Size = UDim2.new(1,-50,0,14); nl3.Position = UDim2.new(0,8,0.5,-7)
				local tbg3 = frm(cf, UDim2.new(0,34,0,18), UDim2.new(1,-42,0.5,-9), val2 and T.Accent or T.AccentFaded, 0)
				corner(tbg3,9)
				local th3 = frm(tbg3, UDim2.new(0,14,0,14), val2 and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7), T.TextPrimary, 0)
				corner(th3,7)
				local rb2 = Instance.new("TextButton"); rb2.Size=UDim2.new(1,0,1,0); rb2.BackgroundTransparency=1; rb2.Text=""; rb2.Parent=cf
				rb2.MouseButton1Click:Connect(function()
					val2=not val2
					tw(tbg3,{BackgroundColor3=val2 and T.Accent or T.AccentFaded},TI.Fast)
					tw(th3,{Position=val2 and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)},TI.Fast)
					tCb2(val2)
					-- Обновить высоту аккордеона
					task.defer(function()
						innerH = recalcH() + 12
						wrapper.Size = UDim2.new(1,0,0,40+innerH)
						inner.Size = UDim2.new(1,-24,0,innerH)
					end)
				end)
			end

			function InnerTab:CreateButton(o2)
				local bCb2 = o2.Callback or function() end
				local cf = ielem(28)
				local nl3 = lbl(cf, o2.Name or "Button", 11, T.TextPrimary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
				nl3.Size = UDim2.new(1,0,1,0)
				local rb2 = Instance.new("TextButton"); rb2.Size=UDim2.new(1,0,1,0); rb2.BackgroundTransparency=1; rb2.Text=""; rb2.Parent=cf
				rb2.MouseButton1Click:Connect(function() bCb2(); local x,y=mrel(cf); ripple(cf,x,y) end)
			end

			return InnerTab
		end

		-- ── Badge (статус-бейдж) ──────────────────────────────
		function Tab:CreateBadge(opts2)
			local bCol = opts2.Color or T.Accent
			local c = elem(32); reg(c, opts2.Name or "")

			local nl2 = lbl(c, opts2.Name or "Badge", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl2.Size = UDim2.new(0.6,0,0,16); nl2.Position = UDim2.new(0,12,0.5,-8)

			local badgeF = frm(c, UDim2.new(0,0,0,20), UDim2.new(1,-14,0.5,-10), bCol, 0)
			corner(badgeF,10)
			local badgeLbl = lbl(badgeF, opts2.Text or "ACTIVE", 9, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			badgeLbl.Size = UDim2.new(1,0,1,0)

			-- Авто-размер бейджа по тексту
			task.defer(function()
				local tw2 = #(opts2.Text or "ACTIVE") * 7 + 14
				badgeF.Size = UDim2.new(0, tw2, 0, 20)
				badgeF.Position = UDim2.new(1, -(tw2+8), 0.5, -10)
			end)

			local obj = {}
			function obj:Set(text, color)
				badgeLbl.Text = text or ""
				if color then badgeF.BackgroundColor3 = color end
				local tw2 = #(text or "") * 7 + 14
				badgeF.Size = UDim2.new(0, tw2, 0, 20)
				badgeF.Position = UDim2.new(1, -(tw2+8), 0.5, -10)
			end
			return obj
		end

		-- ── Tab badge setter ──────────────────────────────────
		function Tab:SetBadge(text)
			if badgeL then badgeL.Text = tostring(text) end
		end

		return Tab
	end

	return Win
end

return VoidUI
