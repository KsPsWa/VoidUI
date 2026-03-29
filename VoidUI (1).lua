local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer

local T = {
	Bg           = Color3.fromRGB(9, 9, 15),
	BgLight      = Color3.fromRGB(15, 15, 24),
	BgTab        = Color3.fromRGB(12, 12, 19),
	BgElement    = Color3.fromRGB(19, 19, 30),
	BgHover      = Color3.fromRGB(26, 16, 52),
	BgInput      = Color3.fromRGB(7, 7, 12),
	Accent       = Color3.fromRGB(138, 58, 255),
	AccentDark   = Color3.fromRGB(88, 28, 178),
	AccentLight  = Color3.fromRGB(178, 118, 255),
	AccentFaded  = Color3.fromRGB(55, 20, 110),
	TextPrimary  = Color3.fromRGB(238, 238, 252),
	TextSub      = Color3.fromRGB(138, 138, 158),
	TextMuted    = Color3.fromRGB(78, 78, 94),
	TextAccent   = Color3.fromRGB(178, 118, 255),
	Border       = Color3.fromRGB(38, 18, 78),
	BorderLight  = Color3.fromRGB(58, 28, 108),
	Sep          = Color3.fromRGB(28, 14, 58),
	Success      = Color3.fromRGB(48, 214, 98),
	Warning      = Color3.fromRGB(252, 178, 48),
	Error        = Color3.fromRGB(252, 58, 58),
	Info         = Color3.fromRGB(138, 58, 255),
	ScrollBar    = Color3.fromRGB(58, 28, 118),
}

local EF = {Enum.EasingStyle.Quad, Enum.EasingDirection.Out}
local TI = {
	Fast   = TweenInfo.new(0.14, table.unpack(EF)),
	Mid    = TweenInfo.new(0.24, table.unpack(EF)),
	Slow   = TweenInfo.new(0.38, table.unpack(EF)),
	Spring = TweenInfo.new(0.34, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

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
	l.TextXAlignment = xa or Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = p; return l
end

local function lst(p, spacing)
	local u = Instance.new("UIListLayout")
	u.SortOrder = Enum.SortOrder.LayoutOrder; u.Padding = UDim.new(0, spacing or 0)
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
	r.BackgroundColor3 = Color3.new(1,1,1); r.BackgroundTransparency = 0.82
	r.BorderSizePixel = 0; r.Size = UDim2.new(0,0,0,0)
	r.Position = UDim2.new(0, mx, 0, my); r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.ZIndex = 20; r.Parent = p; corner(r, 999)
	local sz = math.max(p.AbsoluteSize.X, p.AbsoluteSize.Y) * 2.2
	tw(r, {Size=UDim2.new(0,sz,0,sz), BackgroundTransparency=1},
		TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	Debris:AddItem(r, 0.5)
end

local function mrel(obj)
	local mp = UserInputService:GetMouseLocation()
	return mp.X - obj.AbsolutePosition.X, mp.Y - obj.AbsolutePosition.Y
end

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

local VoidUI   = {}
VoidUI.__index = VoidUI
VoidUI.Version = "2.0.0"
VoidUI.Author  = "Arx2d"
VoidUI.Flags   = {}
VoidUI.Theme   = T

local _ng, _nh, _ns = nil, nil, {}

local function _initN()
	if _ng then return end
	_ng = Instance.new("ScreenGui")
	_ng.Name = "VoidUI_N"; _ng.ResetOnSpawn = false
	_ng.IgnoreGuiInset = true; _ng.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_ng.Parent = LP.PlayerGui
	_nh = frm(_ng, UDim2.new(0,300,1,0), UDim2.new(1,-316,0,0), T.Bg, 1)
	local u = lst(_nh, 6); u.VerticalAlignment = Enum.VerticalAlignment.Bottom
	pad(_nh, 0,0,12,0)
end

function VoidUI:Notify(opts)
	_initN()
	local title = opts.Title or "Void UI"; local content = opts.Content or ""
	local dur = opts.Duration or 4; local ntype = opts.Type or "info"
	local cols  = {info=T.Info, success=T.Success, warning=T.Warning, error=T.Error}
	local icons = {info="·", success="✓", warning="!", error="✕"}
	local ac = cols[ntype] or T.Info
	if #_ns >= 6 then local o = table.remove(_ns,1); if o and o.Parent then o:Destroy() end end
	local nf = frm(_nh, UDim2.new(1,0,0,72), nil, T.BgLight, 0)
	nf.ClipsDescendants = true; nf.LayoutOrder = tick()
	corner(nf, 8); stroke(nf, ac, 1, 0.55)
	local ab = frm(nf, UDim2.new(0,3,1,0), UDim2.new(0,0,0,0), ac, 0); corner(ab,3)
	local icf = frm(nf, UDim2.new(0,28,0,28), UDim2.new(0,14,0,10), T.AccentFaded, 0); corner(icf,6)
	local icl = lbl(icf, icons[ntype] or "·", 13, ac, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	icl.Size = UDim2.new(1,0,1,0)
	local tl = lbl(nf, title, 13, T.TextPrimary, Enum.Font.GothamBold)
	tl.Size = UDim2.new(1,-54,0,18); tl.Position = UDim2.new(0,48,0,10)
	local cl = lbl(nf, content, 11, T.TextSub, Enum.Font.Gotham)
	cl.Size = UDim2.new(1,-54,0,26); cl.Position = UDim2.new(0,48,0,30)
	cl.TextWrapped = true; cl.TextTruncate = Enum.TextTruncate.None
	local pbg = frm(nf, UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), T.Border, 0)
	local pb  = frm(pbg, UDim2.new(1,0,1,0), nil, ac, 0); grad(pb, {T.AccentLight, ac}, 0)
	nf.Position = UDim2.new(1,12, nf.Position.Y.Scale, nf.Position.Y.Offset)
	tw(nf, {Position=UDim2.new(0,0,nf.Position.Y.Scale,nf.Position.Y.Offset)}, TI.Spring)
	table.insert(_ns, nf)
	tw(pb, {Size=UDim2.new(0,0,1,0)}, TweenInfo.new(dur, Enum.EasingStyle.Linear))
	task.delay(dur, function()
		tw(nf, {Position=UDim2.new(1,12,nf.Position.Y.Scale,nf.Position.Y.Offset)}, TI.Mid)
		task.wait(0.28)
		local idx = table.find(_ns, nf)
		if idx then table.remove(_ns, idx) end
		if nf.Parent then nf:Destroy() end
	end)
end

local _wmg
function VoidUI:CreateWatermark(opts)
	if _wmg then _wmg:Destroy() end
	local text = opts.Text or "VOID UI"; local show = opts.Enabled ~= false
	_wmg = Instance.new("ScreenGui")
	_wmg.Name = "VoidUI_WM"; _wmg.ResetOnSpawn = false
	_wmg.IgnoreGuiInset = true; _wmg.Parent = LP.PlayerGui
	local wf = frm(_wmg, UDim2.new(0,240,0,30), UDim2.new(0,14,0,14), T.BgLight, 0)
	wf.Visible = show; corner(wf,7); stroke(wf, T.Border, 1, 0)
	local bar = frm(wf, UDim2.new(0,2,0,18), UDim2.new(0,7,0.5,-9), T.Accent, 0)
	corner(bar,2); grad(bar, {T.AccentLight, T.Accent}, 90)
	local wl = lbl(wf, text, 11, T.TextSub, Enum.Font.Code)
	wl.Size = UDim2.new(1,-18,1,0); wl.Position = UDim2.new(0,16,0,0)
	local fps, fc, ft = 60, 0, os.clock()
	RunService.Heartbeat:Connect(function()
		fc += 1; local n = os.clock()
		if n-ft >= 0.5 then fps = math.round(fc/(n-ft)); fc=0; ft=n end
		wl.Text = text.."  ·  "..fps.." fps"
		wl.TextColor3 = fps >= 55 and T.TextSub or fps >= 30 and T.Warning or T.Error
	end)
	local obj = {}
	function obj:SetText(t) text=t end
	function obj:Toggle(v) wf.Visible=v end
	function obj:Destroy() _wmg:Destroy() end
	return obj
end

local function _loadScreen(opts)
	local title = opts.LoadingTitle or "VOID UI"; local sub = opts.LoadingSubtitle or ""
	local steps = opts.LoadingSteps or {"Initializing...","Building UI...","Done!"}
	local logo  = opts.Logo or "VOID"
	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidUI_Load"; sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = LP.PlayerGui
	local bg = frm(sg, UDim2.new(1,0,1,0), nil, Color3.fromRGB(4,4,8), 1)
	local card = frm(sg, UDim2.new(0,400,0,240), UDim2.new(0.5,-200,0.5,-120), T.Bg, 1)
	corner(card,14); stroke(card, T.Border, 1, 0)
	local tl = frm(card, UDim2.new(1,0,0,3), nil, T.Accent, 0); corner(tl,14)
	grad(tl, {T.AccentLight, T.Accent, T.AccentDark}, 0)
	local d1 = frm(card, UDim2.new(0,6,0,6), UDim2.new(0,14,0,14), T.Accent, 0); corner(d1,99)
	local d2 = frm(card, UDim2.new(0,6,0,6), UDim2.new(0,26,0,14), T.AccentFaded, 0); corner(d2,99)
	local d3 = frm(card, UDim2.new(0,6,0,6), UDim2.new(0,38,0,14), T.AccentFaded, 0); corner(d3,99)
	local ll = lbl(card, logo, 36, T.TextPrimary, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	ll.Size = UDim2.new(1,0,0,56); ll.Position = UDim2.new(0,0,0,28)
	grad(ll, {T.AccentLight, T.Accent}, 90)
	local ttl = lbl(card, title, 14, T.TextPrimary, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	ttl.Size = UDim2.new(1,-32,0,20); ttl.Position = UDim2.new(0,16,0,90)
	local stl = lbl(card, sub, 11, T.TextSub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	stl.Size = UDim2.new(1,-32,0,16); stl.Position = UDim2.new(0,16,0,110)
	frm(card, UDim2.new(1,-32,0,1), UDim2.new(0,16,0,134), T.Sep, 0)
	local stp = lbl(card, steps[1], 11, T.TextAccent, Enum.Font.Code, Enum.TextXAlignment.Center)
	stp.Size = UDim2.new(1,-32,0,16); stp.Position = UDim2.new(0,16,0,144)
	local pbg = frm(card, UDim2.new(1,-32,0,5), UDim2.new(0,16,0,168), T.BgElement, 0); corner(pbg,5)
	local pb = frm(pbg, UDim2.new(0,0,1,0), nil, T.Accent, 0); corner(pb,5)
	grad(pb, {T.AccentLight, T.Accent}, 0)
	local vl = lbl(card, "void ui v"..VoidUI.Version.." · "..VoidUI.Author, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	vl.Size = UDim2.new(1,-32,0,14); vl.Position = UDim2.new(0,16,0,192)
	tw(bg,   {BackgroundTransparency=0.25}, TI.Mid)
	tw(card, {BackgroundTransparency=0},    TI.Spring)
	local n = #steps
	for i, step in ipairs(steps) do
		stp.Text = step
		tw(pb, {Size=UDim2.new(i/n,0,1,0)}, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		task.wait(0.32)
	end
	task.wait(0.22)
	tw(card, {BackgroundTransparency=1, Position=UDim2.new(0.5,-200,0.42,-120)}, TI.Mid)
	tw(bg,   {BackgroundTransparency=1}, TI.Mid)
	task.wait(0.3); sg:Destroy()
end

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
	local W        = (opts.Size and opts.Size.Width)  or 600
	local H        = (opts.Size and opts.Size.Height) or 420

	if opts.Accent then
		local a = opts.Accent
		T.Accent = a
		T.AccentDark  = Color3.new(a.R*0.6,a.G*0.6,a.B*0.6)
		T.AccentLight = Color3.new(math.min(a.R*1.3,1),math.min(a.G*1.3,1),math.min(a.B*1.3,1))
		T.AccentFaded = Color3.new(a.R*0.38,a.G*0.38,a.B*0.38)
		T.TextAccent  = T.AccentLight; T.Border = Color3.new(a.R*0.27,a.G*0.14,a.B*0.55); T.Info = a
	end

	task.spawn(_loadScreen, {LoadingTitle=lTitle, LoadingSubtitle=lSub, LoadingSteps=lSteps, Logo=lLogo})
	task.wait((#(lSteps or {"","",""}) * 0.32) + 0.72)

	local saved = cfgOn and cfgLoad(cfgFile) or {}

	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidUI_Main"; sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = LP.PlayerGui

	local mf = frm(sg, UDim2.new(0,W,0,H), UDim2.new(0.5,-W/2,0.5,-H/2), T.Bg, 0)
	corner(mf,11); stroke(mf, T.Border, 1, 0)

	local glw = Instance.new("ImageLabel")
	glw.Size = UDim2.new(1,80,1,80); glw.Position = UDim2.new(0,-40,0,-40)
	glw.BackgroundTransparency = 1; glw.Image = "rbxassetid://5028857084"
	glw.ImageColor3 = T.Accent; glw.ImageTransparency = 0.88
	glw.ScaleType = Enum.ScaleType.Slice; glw.SliceCenter = Rect.new(24,24,276,276)
	glw.ZIndex = 0; glw.Parent = mf

	local tb = frm(mf, UDim2.new(1,0,0,38), nil, T.BgLight, 0); corner(tb,11)
	frm(tb, UDim2.new(1,0,0,11), UDim2.new(0,0,1,-11), T.BgLight, 0)
	local tbLine = frm(tb, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), T.Accent, 0.5)
	grad(tbLine, {Color3.new(0,0,0), T.Accent, T.Accent, Color3.new(0,0,0)}, 0)

	local logoL = lbl(tb, "VOID", 15, T.Accent, Enum.Font.GothamBlack)
	logoL.Size = UDim2.new(0,48,1,0); logoL.Position = UDim2.new(0,14,0,0)
	local nameL = lbl(tb, winName, 13, T.TextSub, Enum.Font.GothamMedium)
	nameL.Size = UDim2.new(1,-190,1,0); nameL.Position = UDim2.new(0,60,0,0)

	local function ctrlBtn(txt, xo, hc)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,26,0,20); b.Position = UDim2.new(1,xo,0.5,-10)
		b.BackgroundColor3 = T.BgElement; b.Text = txt; b.Font = Enum.Font.GothamBold
		b.TextSize = 12; b.TextColor3 = T.TextMuted; b.BorderSizePixel = 0; b.Parent = tb
		corner(b,5); stroke(b, T.Border, 1, 0.3)
		b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hc,TextColor3=T.TextPrimary}) end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=T.BgElement,TextColor3=T.TextMuted}) end)
		return b
	end

	local closeBtn = ctrlBtn("✕", -14, T.Error)
	local minBtn   = ctrlBtn("─", -46, T.AccentDark)
	local pinBtn   = ctrlBtn("⊕", -78, T.AccentFaded)

	local sb = frm(mf, UDim2.new(0,148,1,-38), UDim2.new(0,0,0,38), T.BgTab, 0)
	pad(sb, 8,6,8,6); lst(sb, 3)
	frm(mf, UDim2.new(0,1,1,-38), UDim2.new(0,148,0,38), T.Sep, 0)

	local verL = lbl(sb, "v"..VoidUI.Version, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	verL.Size = UDim2.new(1,0,0,16); verL.Position = UDim2.new(0,0,1,-20)

	local ca = Instance.new("Frame")
	ca.Size = UDim2.new(1,-149,1,-38); ca.Position = UDim2.new(0,149,0,38)
	ca.BackgroundTransparency = 1; ca.ClipsDescendants = true; ca.Parent = mf

	local drag, dStart, dOrigin = false, nil, nil
	tb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag=true; dStart=i.Position; dOrigin=mf.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dStart
			mf.Position = UDim2.new(dOrigin.X.Scale, dOrigin.X.Offset+d.X, dOrigin.Y.Scale, dOrigin.Y.Offset+d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		sb.Visible = not minimized; ca.Visible = not minimized
		tw(mf, {Size=UDim2.new(0,W,0,minimized and 38 or H)}, TI.Mid)
	end)

	local pinned = false
	pinBtn.MouseButton1Click:Connect(function()
		pinned = not pinned
		pinBtn.TextColor3 = pinned and T.Accent or T.TextMuted
	end)

	closeBtn.MouseButton1Click:Connect(function()
		tw(mf, {BackgroundTransparency=1,Size=UDim2.new(0,W,0,0),Position=UDim2.new(0.5,-W/2,0.5,0)}, TI.Mid)
		task.wait(0.3); sg:Destroy()
	end)

	UserInputService.InputBegan:Connect(function(i, gpe)
		if gpe then return end
		if i.KeyCode == tKey then mf.Visible = not mf.Visible end
	end)

	local Win = {}
	Win._tabs = {}; Win._active = nil
	Win._cfgFile = cfgFile; Win._cfgOn = cfgOn; Win._saved = saved

	function Win:SaveConfig()
		if self._cfgOn then cfgSave(self._cfgFile, VoidUI.Flags) end
	end

	function Win:SetAccent(color)
		T.Accent = color; T.AccentDark = Color3.new(color.R*0.6,color.G*0.6,color.B*0.6)
		T.AccentLight = Color3.new(math.min(color.R*1.3,1),math.min(color.G*1.3,1),math.min(color.B*1.3,1))
		glw.ImageColor3 = color; logoL.TextColor3 = color
	end

	function Win:Destroy() sg:Destroy() end

	function Win:CreateTab(name, icon)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1,0,0,36); tabBtn.BackgroundColor3 = T.BgTab
		tabBtn.Text = ""; tabBtn.BorderSizePixel = 0
		tabBtn.LayoutOrder = #self._tabs+1; tabBtn.Parent = sb; corner(tabBtn,7)

		local stripe = frm(tabBtn, UDim2.new(0,3,0,20), UDim2.new(0,0,0.5,-10), T.Accent, 1); corner(stripe,3)

		local iconL = lbl(tabBtn, icon or "", 14, T.TextMuted, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
		iconL.Size = UDim2.new(0,22,1,0); iconL.Position = UDim2.new(0,10,0,0)

		local nL = lbl(tabBtn, name, 12, T.TextMuted, Enum.Font.GothamMedium)
		nL.Size = UDim2.new(1,-38,1,0); nL.Position = UDim2.new(0, icon and 34 or 12, 0, 0)

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1,0,1,0); scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = T.ScrollBar; scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Visible = false; scroll.Parent = ca
		lst(scroll, 5); pad(scroll, 10,12,10,12)

		tabBtn.MouseEnter:Connect(function()
			if self._active ~= scroll then tw(tabBtn,{BackgroundColor3=T.BgHover}); tw(nL,{TextColor3=T.TextSub}) end
		end)
		tabBtn.MouseLeave:Connect(function()
			if self._active ~= scroll then tw(tabBtn,{BackgroundColor3=T.BgTab}); tw(nL,{TextColor3=T.TextMuted}) end
		end)

		local function activate()
			for _, t in ipairs(self._tabs) do
				t.sc.Visible = false
				tw(t.btn,{BackgroundColor3=T.BgTab}); tw(t.nL,{TextColor3=T.TextMuted})
				tw(t.iL,{TextColor3=T.TextMuted}); tw(t.str,{BackgroundTransparency=1})
			end
			scroll.Visible = true; self._active = scroll
			tw(tabBtn,{BackgroundColor3=T.BgHover}); tw(nL,{TextColor3=T.TextAccent})
			tw(iconL,{TextColor3=T.Accent}); tw(stripe,{BackgroundTransparency=0})
		end

		tabBtn.MouseButton1Click:Connect(function()
			activate(); local x,y = mrel(tabBtn); ripple(tabBtn,x,y)
		end)

		table.insert(self._tabs, {sc=scroll, btn=tabBtn, nL=nL, iL=iconL, str=stripe})
		if #self._tabs == 1 then task.defer(activate) end

		local Tab = {}; Tab._lo = 0; Tab._win = self

		local function lo() Tab._lo += 1; return Tab._lo end

		local function elem(h, hasDesc)
			local c = frm(scroll, UDim2.new(1,0,0, hasDesc and h+20 or h), nil, T.BgElement, 0)
			c.LayoutOrder = lo(); c.ClipsDescendants = true
			corner(c,7); stroke(c, T.Border, 1, 0.45)
			c.MouseEnter:Connect(function() tw(c,{BackgroundColor3=T.BgHover}) end)
			c.MouseLeave:Connect(function() tw(c,{BackgroundColor3=T.BgElement}) end)
			return c
		end

		function Tab:CreateSection(text)
			local sf = frm(scroll, UDim2.new(1,0,0,22), nil, T.Bg, 1); sf.LayoutOrder = lo()
			frm(sf, UDim2.new(0.38,-6,0,1), UDim2.new(0,0,0.5,0), T.Sep, 0)
			frm(sf, UDim2.new(0.38,-6,0,1), UDim2.new(0.62,6,0.5,0), T.Sep, 0)
			local sl = lbl(sf, text:upper(), 9, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
			sl.Size = UDim2.new(0.24,0,1,0); sl.Position = UDim2.new(0.38,0,0,0); sl.LetterSpacing = 3
		end

		function Tab:CreateSeparator()
			local sf = frm(scroll, UDim2.new(1,0,0,1), nil, T.Sep, 0); sf.LayoutOrder = lo()
		end

		function Tab:CreateLabel(text, color, size)
			local lf = frm(scroll, UDim2.new(1,0,0,20), nil, T.Bg, 1); lf.LayoutOrder = lo()
			local ll = lbl(lf, text or "", size or 11, color or T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
			ll.Size = UDim2.new(1,0,1,0); ll.TextWrapped = true; return ll
		end

		function Tab:CreateToggle(opts)
			local tFlag = opts.Flag
			local tVal  = tFlag and (Win._saved[tFlag] ~= nil and Win._saved[tFlag] or opts.CurrentValue) or (opts.CurrentValue or false)
			local tDesc = opts.Description; local tCb = opts.Callback or function() end

			local c = elem(38, tDesc); local val = tVal
			local nl = lbl(c, opts.Name or "Toggle", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(1,-62,0,18); nl.Position = UDim2.new(0,12,0, tDesc and 6 or 10)

			if tDesc then
				local dl = lbl(c, tDesc, 10, T.TextMuted)
				dl.Size = UDim2.new(1,-62,0,14); dl.Position = UDim2.new(0,12,0,24)
			end

			local tbg = frm(c, UDim2.new(0,40,0,22), UDim2.new(1,-52,0.5,-11), val and T.Accent or T.AccentFaded, 0)
			corner(tbg,11); stroke(tbg, T.Border, 1, 0.3)
			local th = frm(tbg, UDim2.new(0,16,0,16), val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8), T.TextPrimary, 0)
			corner(th,8)
			local sh = frm(th, UDim2.new(0,6,0,6), UDim2.new(0,2,0,2), Color3.new(1,1,1), 0.52); corner(sh,3)

			local function set(v, silent)
				val = v
				tw(tbg,{BackgroundColor3=v and T.Accent or T.AccentFaded},TI.Fast)
				tw(th,{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)},TI.Fast)
				tw(nl,{TextColor3=v and T.TextPrimary or T.TextSub},TI.Fast)
				if not silent then tCb(v); if tFlag then VoidUI.Flags[tFlag]=v; Win:SaveConfig() end end
			end
			set(tVal, true)

			local cb = Instance.new("TextButton")
			cb.Size=UDim2.new(1,0,1,0); cb.BackgroundTransparency=1; cb.Text=""; cb.Parent=c
			cb.MouseButton1Click:Connect(function() set(not val); local x,y=mrel(c); ripple(c,x,y) end)

			local obj = {}
			function obj:Set(v) set(v,false) end; function obj:Get() return val end
			function obj:Toggle() set(not val,false) end; return obj
		end

		function Tab:CreateSlider(opts)
			local sFlag = opts.Flag; local sRange = opts.Range or {0,100}; local sInc = opts.Increment or 1
			local sDef  = sFlag and (Win._saved[sFlag] or opts.CurrentValue) or (opts.CurrentValue or sRange[1])
			local sSuf  = opts.Suffix or ""; local sCb = opts.Callback or function() end

			local c = elem(52); local val = math.clamp(sDef, sRange[1], sRange[2])
			local nl = lbl(c, opts.Name or "Slider", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(1,-70,0,16); nl.Position = UDim2.new(0,12,0,8)
			local vl = lbl(c, tostring(val)..sSuf, 12, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0,56,0,16); vl.Position = UDim2.new(1,-68,0,8)

			local track = frm(c, UDim2.new(1,-24,0,5), UDim2.new(0,12,0,36), T.Border, 0); corner(track,5)
			local fill  = frm(track, UDim2.new(0,0,1,0), nil, T.Accent, 0); corner(fill,5)
			grad(fill, {T.AccentLight, T.Accent}, 0)
			local thumb = frm(track, UDim2.new(0,16,0,16), UDim2.new(0,-8,0.5,-8), T.AccentLight, 0)
			corner(thumb,8); stroke(thumb, T.Accent, 2, 0); thumb.ZIndex = 4

			local function upd(v)
				v = math.clamp(math.round(v/sInc)*sInc, sRange[1], sRange[2]); val = v
				local p = (v-sRange[1])/(sRange[2]-sRange[1])
				tw(fill,{Size=UDim2.new(p,0,1,0)},TI.Fast); tw(thumb,{Position=UDim2.new(p,-8,0.5,-8)},TI.Fast)
				vl.Text = tostring(v)..sSuf; sCb(v)
				if sFlag then VoidUI.Flags[sFlag]=v; Win:SaveConfig() end
			end

			local p0 = (val-sRange[1])/(sRange[2]-sRange[1])
			fill.Size = UDim2.new(p0,0,1,0); thumb.Position = UDim2.new(p0,-8,0.5,-8)

			local drag = false
			local function pct(x) return math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1) end
			thumb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
			track.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(sRange[1]+(sRange[2]-sRange[1])*pct(i.Position.X)) end
			end)
			UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
			UserInputService.InputChanged:Connect(function(i)
				if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(sRange[1]+(sRange[2]-sRange[1])*pct(i.Position.X)) end
			end)

			local obj = {}; function obj:Set(v) upd(v) end; function obj:Get() return val end; return obj
		end

		function Tab:CreateButton(opts)
			local bCb = opts.Callback or function() end; local bDesc = opts.Description
			local c = elem(36, bDesc); c.ClipsDescendants = true
			local nl = lbl(c, opts.Name or "Button", 12, T.TextPrimary, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
			nl.Size = UDim2.new(1,-32,0,18); nl.Position = UDim2.new(0,12,0, bDesc and 6 or 9)
			if bDesc then
				local dl = lbl(c, bDesc, 10, T.TextMuted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
				dl.Size = UDim2.new(1,-32,0,14); dl.Position = UDim2.new(0,12,0,24)
			end
			local arr = lbl(c, opts.Icon or "›", 15, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			arr.Size = UDim2.new(0,18,1,0); arr.Position = UDim2.new(1,-24,0,0)
			local btn = Instance.new("TextButton")
			btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=c
			btn.MouseEnter:Connect(function() tw(nl,{TextColor3=T.TextAccent}); tw(arr,{TextColor3=T.Accent}) end)
			btn.MouseLeave:Connect(function() tw(nl,{TextColor3=T.TextPrimary}); tw(arr,{TextColor3=T.TextMuted}) end)
			btn.MouseButton1Down:Connect(function() tw(c,{BackgroundColor3=T.AccentFaded}) end)
			btn.MouseButton1Click:Connect(function()
				tw(c,{BackgroundColor3=T.BgHover}); local x,y=mrel(c); ripple(c,x,y); bCb()
			end)
		end

		function Tab:CreateDropdown(opts)
			local dFlag = opts.Flag; local dOpts = opts.Options or {}
			local dDef  = dFlag and (Win._saved[dFlag] or opts.CurrentOption) or opts.CurrentOption
			local dCb   = opts.Callback or function() end; local dMulti = opts.Multi or false
			local val   = dDef; local open = false; local sel = {}

			local c = elem(36); c.ClipsDescendants = false; c.ZIndex = 5
			local nl = lbl(c, opts.Name or "Dropdown", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(0.5,0,0,18); nl.Position = UDim2.new(0,12,0.5,-9)
			local vl = lbl(c, type(val)=="table" and (#val.." selected") or (val or "Select..."), 11, T.TextAccent, Enum.Font.Gotham, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0.4,-8,0,18); vl.Position = UDim2.new(0.5,0,0.5,-9)
			local al = lbl(c, "▾", 13, T.TextMuted, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			al.Size = UDim2.new(0,18,0,18); al.Position = UDim2.new(1,-26,0.5,-9)

			local dd = frm(c, UDim2.new(1,0,0,0), UDim2.new(0,0,1,5), T.BgLight, 0)
			dd.ClipsDescendants = true; dd.ZIndex = 10; dd.Visible = false
			corner(dd,7); stroke(dd, T.Border, 1, 0); lst(dd, 2); pad(dd,4,4,4,4)

			local function refreshVl()
				if dMulti then
					local s = {}; for o,v in pairs(sel) do if v then s[#s+1]=o end end
					vl.Text = #s>0 and (#s.." selected") or "None"
				else
					vl.Text = val or "Select..."
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
				ob.MouseEnter:Connect(function() tw(ob,{BackgroundColor3=T.BgHover}); tw(ol,{TextColor3=T.TextPrimary}) end)
				ob.MouseLeave:Connect(function()
					tw(ob,{BackgroundColor3=T.BgLight})
					tw(ol,{TextColor3=(dMulti and sel[opt] or opt==val) and T.TextAccent or T.TextSub})
				end)
				ob.MouseButton1Click:Connect(function()
					if dMulti then
						sel[opt] = not sel[opt]
						tw(chk,{BackgroundColor3=sel[opt] and T.Accent or T.AccentFaded})
						tw(ol,{TextColor3=sel[opt] and T.TextAccent or T.TextSub})
						local r={}; for o,v in pairs(sel) do if v then r[#r+1]=o end end
						val=r; refreshVl(); dCb(r)
					else
						val=opt; refreshVl()
						for _,ch in ipairs(dd:GetChildren()) do
							if ch:IsA("TextButton") then
								local cl=ch:FindFirstChildOfClass("TextLabel")
								if cl then tw(cl,{TextColor3=T.TextSub}) end
							end
						end
						tw(ol,{TextColor3=T.TextAccent})
						open=false; tw(dd,{Size=UDim2.new(1,0,0,0)},TI.Fast); tw(al,{Rotation=0},TI.Fast)
						task.wait(0.15); dd.Visible=false; dCb(opt)
						if dFlag then VoidUI.Flags[dFlag]=opt; Win:SaveConfig() end
					end
				end)
			end

			local mb = Instance.new("TextButton")
			mb.Size=UDim2.new(1,0,1,0); mb.BackgroundTransparency=1; mb.Text=""; mb.Parent=c
			mb.MouseButton1Click:Connect(function()
				open=not open; local th=open and math.min(#dOpts*34+8,200) or 0
				dd.Visible=true; tw(dd,{Size=UDim2.new(1,0,0,th)},TI.Fast); tw(al,{Rotation=open and 180 or 0},TI.Fast)
				if not open then task.delay(0.16,function() dd.Visible=false end) end
			end)

			local obj = {}
			function obj:Set(v) val=v; refreshVl(); dCb(v) end
			function obj:Get() return val end
			function obj:AddOption(o) table.insert(dOpts,o) end
			function obj:Clear() val=nil; refreshVl() end
			return obj
		end

		function Tab:CreateInput(opts)
			local iFlag = opts.Flag; local iCb = opts.Callback or function() end
			local iLive = opts.LiveUpdate or false; local iNum = opts.NumberOnly or false
			local c = elem(52)
			local nl = lbl(c, opts.Name or "Input", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(1,-24,0,16); nl.Position = UDim2.new(0,12,0,6)
			local ibg = frm(c, UDim2.new(1,-24,0,24), UDim2.new(0,12,0,26), T.BgInput, 0)
			corner(ibg,5); local ibs = stroke(ibg, T.Border, 1, 0.2)
			local ib = Instance.new("TextBox")
			ib.Size=UDim2.new(1,-10,1,0); ib.Position=UDim2.new(0,5,0,0)
			ib.BackgroundTransparency=1; ib.Text=""; ib.PlaceholderText=opts.Placeholder or "Type here..."
			ib.Font=Enum.Font.Gotham; ib.TextSize=11; ib.TextColor3=T.TextPrimary
			ib.PlaceholderColor3=T.TextMuted; ib.ClearTextOnFocus=false; ib.Parent=ibg
			ib.Focused:Connect(function() tw(ibg,{BackgroundColor3=T.BgLight}); ibs.Color=T.Accent; ibs.Transparency=0 end)
			ib.FocusLost:Connect(function(e)
				tw(ibg,{BackgroundColor3=T.BgInput}); ibs.Color=T.Border; ibs.Transparency=0.2
				if e then local v=iNum and tonumber(ib.Text) or ib.Text; iCb(v); if iFlag then VoidUI.Flags[iFlag]=v; Win:SaveConfig() end end
			end)
			if iLive then ib:GetPropertyChangedSignal("Text"):Connect(function() iCb(iNum and tonumber(ib.Text) or ib.Text) end) end
			local obj = {}; function obj:Set(v) ib.Text=tostring(v) end
			function obj:Get() return ib.Text end; function obj:Clear() ib.Text="" end; return obj
		end

		function Tab:CreateKeybind(opts)
			local kFlag = opts.Flag; local val = opts.CurrentKey or Enum.KeyCode.Unknown
			local kCb = opts.Callback or function() end; local kHold = opts.HoldToTrigger or false
			local binding = false; local held = false
			local c = elem(36)
			local nl = lbl(c, opts.Name or "Keybind", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(0.6,0,0,18); nl.Position = UDim2.new(0,12,0.5,-9)
			local kbg = frm(c, UDim2.new(0,76,0,24), UDim2.new(1,-88,0.5,-12), T.BgInput, 0)
			corner(kbg,5); stroke(kbg, T.Border, 1, 0.2)
			local kl = lbl(kbg, val.Name, 11, T.TextAccent, Enum.Font.Code, Enum.TextXAlignment.Center)
			kl.Size = UDim2.new(1,0,1,0)
			local btn = Instance.new("TextButton")
			btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=c
			btn.MouseButton1Click:Connect(function()
				binding=true; kl.Text="..."; kl.TextColor3=T.TextSub; tw(kbg,{BackgroundColor3=T.AccentFaded})
			end)
			UserInputService.InputBegan:Connect(function(i, gpe)
				if binding and i.UserInputType==Enum.UserInputType.Keyboard then
					binding=false; val=i.KeyCode; kl.Text=i.KeyCode.Name; kl.TextColor3=T.TextAccent
					tw(kbg,{BackgroundColor3=T.BgInput}); if kFlag then VoidUI.Flags[kFlag]=i.KeyCode.Name; Win:SaveConfig() end
					kCb(i.KeyCode); return
				end
				if not gpe and not binding and i.KeyCode==val then
					if kHold then held=true else kCb(val) end
				end
			end)
			UserInputService.InputEnded:Connect(function(i)
				if i.KeyCode==val and kHold and held then held=false; kCb(val) end
			end)
			local obj = {}; function obj:Get() return val end
			function obj:Set(k) val=k; kl.Text=k.Name end; return obj
		end

		function Tab:CreateColorPicker(opts)
			local cFlag = opts.Flag; local cDef = opts.Default or Color3.fromRGB(138,58,255)
			local cCb = opts.Callback or function() end
			local val = cDef; local open = false
			local hue, sat, bri = Color3.toHSV(cDef)

			local c = elem(36); c.ClipsDescendants = false
			local nl = lbl(c, opts.Name or "Color", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(1,-72,0,18); nl.Position = UDim2.new(0,12,0.5,-9)
			local prev = frm(c, UDim2.new(0,32,0,20), UDim2.new(1,-48,0.5,-10), val, 0)
			corner(prev,5); stroke(prev, T.Border, 1, 0)
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
					svB.BackgroundColor3=Color3.fromHSV(hue,1,1); svW.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1))})
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
						svB.BackgroundColor3=Color3.fromHSV(hue,1,1); svW.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1))})
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
				tw(pk,{Size=UDim2.new(1,0,0,open and 116 or 0)},TI.Fast); tw(al,{Rotation=open and 180 or 0},TI.Fast)
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
			function obj:Get() return val end; return obj
		end

		function Tab:CreateProgressBar(opts)
			local pMin = opts.Min or 0; local pMax = opts.Max or 100
			local pVal = opts.Value or 0; local pSuf = opts.Suffix or ""
			local pCol = opts.Color or T.Accent

			local c = elem(44)
			local nl = lbl(c, opts.Name or "Progress", 12, T.TextPrimary, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(1,-70,0,16); nl.Position = UDim2.new(0,12,0,6)
			local vl = lbl(c, tostring(pVal)..pSuf, 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0,56,0,16); vl.Position = UDim2.new(1,-68,0,6)
			local track = frm(c, UDim2.new(1,-24,0,6), UDim2.new(0,12,0,30), T.Border, 0); corner(track,6)
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

		function Tab:CreateTextDisplay(opts)
			local c = elem(36)
			local nl = lbl(c, opts.Name or "", 11, T.TextMuted, Enum.Font.GothamMedium)
			nl.Size = UDim2.new(0.45,0,0,16); nl.Position = UDim2.new(0,12,0.5,-8)
			local vl = lbl(c, opts.Text or "", opts.Size or 11, T.TextAccent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
			vl.Size = UDim2.new(0.5,0,0,16); vl.Position = UDim2.new(0.45,0,0.5,-8)
			local obj = {}
			function obj:Set(v) vl.Text=tostring(v) end
			function obj:SetColor(col) vl.TextColor3=col end
			function obj:Get() return vl.Text end
			return obj
		end

		return Tab
	end

	return Win
end

return VoidUI
