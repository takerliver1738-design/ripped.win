local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function waitForLoadingScreen()
	local coreGui = game:GetService("CoreGui")
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	local localPlayer = Players.LocalPlayer
	while not localPlayer do
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		localPlayer = Players.LocalPlayer
	end
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local function isActiveLoadingGui(object)
		local normalizedName = object.Name:lower():gsub("[%s_%-]", "")
		if normalizedName ~= "loadingscreen" and not normalizedName:find("loadingscreen", 1, true) then
			return false
		end
		local current = object
		while current and current ~= playerGui and current ~= coreGui do
			if current:IsA("LayerCollector") and not current.Enabled then
				return false
			end
			if current:IsA("GuiObject") and not current.Visible then
				return false
			end
			current = current.Parent
		end
		return object:IsDescendantOf(playerGui) or object:IsDescendantOf(coreGui)
	end
	local clearSince
	repeat
		local loading = false
		for _, root in ipairs({ playerGui, coreGui }) do
			for _, object in ipairs(root:GetDescendants()) do
				if isActiveLoadingGui(object) then
					loading = true
					break
				end
			end
			if loading then
				break
			end
		end
		clearSince = loading and nil or (clearSince or os.clock())
		task.wait(0.1)
	until clearSince and os.clock() - clearSince >= 0.5
end
pcall(waitForLoadingScreen)

local LOGO_ASSET = "72968764333468"
local GUI_NAME = "RippedWinUI"
local TOGGLE_KEY = Enum.KeyCode.RightShift
local REDUCED_MOTION = false

local C = {
	black = Color3.fromHex("#050608"),
	panel = Color3.fromHex("#0A0C10"),
	panel2 = Color3.fromHex("#10141B"),
	blue = Color3.fromHex("#3478FF"),
	blueHi = Color3.fromHex("#5795FF"),
	sweep = Color3.fromHex("#B7D0FF"),
	text = Color3.fromHex("#E8EDF7"),
	text2 = Color3.fromHex("#788398"),
	line = Color3.fromHex("#1C2431"),
	scroll = Color3.fromHex("#2A3547"),
}

local HEADER_H, FOOTER_H = 48, 28
local CARD_TOP, CARD_HEAD, WELL_M, MIN_WELL = 2, 30, 6, 210
local GAP, PAD = 7, 7
local MARGIN = 8
local MIN_W, MIN_H = 420, 340
local connections = {}
local loopTweens = {}
local destroyed = false
local gui
local Ragebot
local Esp
local Aim
local Silent
local silentGuard = false
local HitSounds

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function destroy()
	if destroyed then
		return
	end
	destroyed = true
	if Esp then
		pcall(function()
			Esp.stop()
		end)
	end
	if Aim then
		pcall(function()
			Aim.stop()
		end)
	end
	if Silent then
		if Silent.token then
			Silent.token.alive = false
		end
		if Silent.fovCircle then
			pcall(function()
				Silent.fovCircle:Remove()
			end)
			Silent.fovCircle = nil
		end
		pcall(function()
			for _, c in ipairs(Silent.conns) do
				c:Disconnect()
			end
		end)
	end
	if HitSounds then
		pcall(function()
			for _, c in ipairs(HitSounds.conns) do
				c:Disconnect()
			end
		end)
	end
	if Ragebot then
		pcall(function()
			Ragebot.stop()
		end)
	end
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, t in ipairs(loopTweens) do
		t:Cancel()
	end
	table.clear(loopTweens)
	if gui then
		pcall(function()
			gui:Destroy()
		end)
	end
end

local function new(class, props, children)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			o[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function tween(obj, duration, props, style, dir)
	if REDUCED_MOTION or duration <= 0 then
		for k, v in pairs(props) do
			obj[k] = v
		end
		return nil
	end
	local t = TweenService:Create(
		obj,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function hLine(parent, pos, size)
	return new("Frame", {
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		Position = pos,
		Size = size,
		Parent = parent,
	})
end

local function bez(x0, y0, cx, cy, x1, y1, n)
	local pts = {}
	for i = 0, n do
		local t = i / n
		local a, b, c = (1 - t) * (1 - t), 2 * (1 - t) * t, t * t
		table.insert(pts, a * x0 + b * cx + c * x1)
		table.insert(pts, a * y0 + b * cy + c * y1)
	end
	return pts
end

local function makeIcon(parent, prims, px, thick)
	local k = px / 24
	local root = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(px, px),
		Parent = parent,
	})
	local parts = {}
	local color = C.text2

	local function seg(x1, y1, x2, y2)
		local dx, dy = (x2 - x1) * k, (y2 - y1) * k
		local len = math.sqrt(dx * dx + dy * dy)
		local f = new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((x1 + x2) / 2 * k, (y1 + y2) / 2 * k),
			Size = UDim2.fromOffset(len + thick * 0.5, thick),
			Rotation = math.deg(math.atan2(dy, dx)),
			Parent = root,
		})
		corner(f, thick / 2)
		table.insert(parts, { f, "BackgroundColor3" })
	end

	local function outline(cx, cy, w, h, radius)
		local f = new("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx * k, cy * k),
			Size = UDim2.fromOffset(w * k, h * k),
			Parent = root,
		})
		corner(f, radius)
		local s = stroke(f, color, thick, 0)
		table.insert(parts, { s, "Color" })
	end

	for _, p in ipairs(prims) do
		if p.t == "ring" then
			outline(p.x, p.y, p.r * 2, p.r * 2, p.r * k)
		elseif p.t == "rect" then
			outline(p.x + p.w / 2, p.y + p.h / 2, p.w, p.h, 1.5 * k)
		elseif p.t == "line" then
			for i = 1, #p.pts - 3, 2 do
				seg(p.pts[i], p.pts[i + 1], p.pts[i + 2], p.pts[i + 3])
			end
		end
	end

	return {
		root = root,
		setColor = function(c, duration)
			for _, part in ipairs(parts) do
				tween(part[1], duration or 0.18, { [part[2]] = c })
			end
		end,
	}
end

local function lens()
	local top = bez(2, 12, 12, 0, 22, 12, 8)
	local bottom = bez(22, 12, 12, 24, 2, 12, 8)
	return { t = "line", pts = top }, { t = "line", pts = bottom }
end
local eyeTop, eyeBottom = lens()

local SECTIONS = {
	{
		id = "legit",
		label = "Legit",
		prims = {
			{ t = "ring", x = 12, y = 12, r = 7 },
			{ t = "line", pts = { 12, 2, 12, 7 } },
			{ t = "line", pts = { 12, 17, 12, 22 } },
			{ t = "line", pts = { 2, 12, 7, 12 } },
			{ t = "line", pts = { 17, 12, 22, 12 } },
		},
	},
	{
		id = "rage",
		label = "Rage",
		prims = { { t = "line", pts = { 13, 2, 4, 14, 11, 14, 10, 22, 19, 10, 12, 10, 13, 2 } } },
	},
	{
		id = "esp",
		label = "ESP",
		prims = { eyeTop, eyeBottom, { t = "ring", x = 12, y = 12, r = 3 } },
	},
	{
		id = "visuals",
		label = "Visuals",
		prims = {
			{ t = "line", pts = { 12, 2, 22, 7, 12, 12, 2, 7, 12, 2 } },
			{ t = "line", pts = { 2, 12, 12, 17, 22, 12 } },
			{ t = "line", pts = { 2, 17, 12, 22, 22, 17 } },
		},
	},
	{
		id = "character",
		label = "Character",
		prims = {
			{ t = "ring", x = 12, y = 8, r = 4 },
			{ t = "line", pts = { 4, 21, 4.6, 17, 7, 14, 12, 13, 17, 14, 19.4, 17, 20, 21 } },
		},
	},
	{
		id = "misc",
		label = "Misc",
		prims = {
			{ t = "rect", x = 3, y = 3, w = 7, h = 7 },
			{ t = "rect", x = 14, y = 3, w = 7, h = 7 },
			{ t = "rect", x = 3, y = 14, w = 7, h = 7 },
			{ t = "rect", x = 14, y = 14, w = 7, h = 7 },
		},
	},
	{
		id = "settings",
		label = "Settings",
		prims = {
			{ t = "line", pts = { 4, 6, 13, 6 } },
			{ t = "line", pts = { 17, 6, 20, 6 } },
			{ t = "ring", x = 15, y = 6, r = 2 },
			{ t = "line", pts = { 4, 12, 7, 12 } },
			{ t = "line", pts = { 11, 12, 20, 12 } },
			{ t = "ring", x = 9, y = 12, r = 2 },
			{ t = "line", pts = { 4, 18, 15, 18 } },
			{ t = "line", pts = { 19, 18, 20, 18 } },
			{ t = "ring", x = 17, y = 18, r = 2 },
		},
	},
}

local player = Players.LocalPlayer
if not player then
	error("RIPPED.WIN: LocalPlayer is not available. Run this from an in-game client.")
end
local playerGui = player:WaitForChild("PlayerGui")

local guiParent = playerGui
local ok, coreGui = pcall(function()
	return game:GetService("CoreGui")
end)
if ok and coreGui then
	guiParent = coreGui
end
if type(gethui) == "function" then
	local huiOk, hui = pcall(gethui)
	if huiOk and hui then
		guiParent = hui
	end
end

local existing = guiParent:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end
local oldPlayerGui = playerGui:FindFirstChild(GUI_NAME)
if oldPlayerGui then
	oldPlayerGui:Destroy()
end

local cloneref_ = (type(cloneref) == "function") and cloneref or function(s)
	return s
end
local repS = cloneref_(game:GetService("ReplicatedStorage"))
local runS = cloneref_(game:GetService("RunService"))
local ws = cloneref_(game:GetService("Workspace"))
local HttpService = game:GetService("HttpService")

local CONFIG_FOLDER = "ripped_win"
local CONFIG_INDEX = CONFIG_FOLDER .. "/configs.json"
local AUTOSAVE_FILE = CONFIG_FOLDER .. "/autosave.json"
local ACTIVE_FILE = CONFIG_FOLDER .. "/active.txt"

local CONFIG_DEFAULTS = {
	Enabled = true,
	Desync = true,
	DesyncJitter = false,	-- cycle multiple desync offsets each frame for wider anti-aim coverage
	AutoEquip = true,
	RequireEquipped = true,
	FireRate = 0.0005,
	Spread = 0,
	Lead = 0,			-- raw seconds; overridden when AutoLead is true
	AutoLead = false,		-- compute lead from half local ping automatically
	Range = 500,
	WeaponSlot = "Melee",
	HitPart = "Head",
	VisibleCheck = false,	-- skip targets not in line-of-sight (ragebot)
	UseFOV = false,		-- gate ragebot firing to AimCfg.FOV screen radius
}

local ESP_DEFAULTS = {
	Enabled = false,
	TeamCheck = true,
	VisibleCheck = true,
	MaxDistance = 1000,
	BoxStyle = "Corner",
	BoxFill = false,
	Skeleton = false,
	HeadDot = false,
	Name = true,
	HealthBar = true,
	HealthNumber = false,
	DistanceText = true,
	WeaponText = true,
	Tracer = "Off",
	Chams = false,
	ChamsThroughWalls = true,
	EnemyColor = Color3.fromHex("#5795FF"),
	HiddenColor = Color3.fromHex("#8892A6"),
	TeamColor = Color3.fromHex("#2ECC71"),
}

local AIM_DEFAULTS = {
	Enabled = false,
	Activation = "Always",
	Method = "Mouse",
	Key = Enum.KeyCode.LeftAlt,
	KeyType = "Keyboard",
	Smoothing = 0,
	HitPart = "Head",
	PredictionMs = 0,
	Selection = "Crosshair",
	FOV = 150,
	FovCircle = true,
	AutoSwitch = true,
	RequireEquipped = true,
	MaxDistance = 1000,
	TeamCheck = true,
	VisibleCheck = true,
	SnapLine = true,
	TargetBox = true,
	TargetHp = true,
	SnapColor = Color3.fromHex("#B7D0FF"),
}

local SILENT_DEFAULTS = {
	Enabled = false,
	Method = "Click",
	HitPart = "Head",
	UseFOV = true,
	FovRadius = 150,		-- independent silent aim FOV; 0 = use AimCfg.FOV
	TeamCheck = true,
	VisibleCheck = true,
	MaxDistance = 1000,
	PredictionMs = 0,		-- velocity lead in ms applied to silent aim target position
}

local HIT_DEFAULTS = {
	HitEnabled = true,
	HitSound = "Neverlose",
	HitVolume = 60,
}

local META_DEFAULTS = {
	AutoLoad = true,
	AutoSave = true,
	AutoSaveInterval = 30,
	LastConfig = "default",
}

local function deepClone(t)
	if type(t) ~= "table" then
		return t
	end
	local n = {}
	for k, v in pairs(t) do
		n[k] = deepClone(v)
	end
	return n
end

local function ensureFolder()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		if not isfolder(CONFIG_FOLDER) then
			makefolder(CONFIG_FOLDER)
		end
	end
end

local function colorToTable(c)
	if typeof(c) == "Color3" then
		return { r = c.R, g = c.G, b = c.B }
	end
	return c
end

local function tableToColor(t)
	if type(t) == "table" and t.r and t.g and t.b then
		return Color3.new(t.r, t.g, t.b)
	end
	return t
end

local function keyToString(k)
	if typeof(k) == "EnumItem" then
		return k.Name
	end
	return tostring(k)
end

local function stringToKey(s, keyType)
	if keyType == "Mouse" then
		local ok, v = pcall(function()
			return Enum.UserInputType[s]
		end)
		if ok and v then
			return v
		end
		return Enum.UserInputType.MouseButton2
	end
	local ok, v = pcall(function()
		return Enum.KeyCode[s]
	end)
	if ok and v then
		return v
	end
	return Enum.KeyCode.LeftAlt
end

local function serializeSection(src, defaults)
	local out = {}
	for k, def in pairs(defaults) do
		local v = src[k]
		if v == nil then
			v = def
		end
		if typeof(v) == "Color3" then
			out[k] = colorToTable(v)
		elseif typeof(v) == "EnumItem" then
			out[k] = v.Name
		else
			out[k] = v
		end
	end
	return out
end

local function applySection(dst, src, defaults)
	if type(src) ~= "table" then
		return
	end
	for k, def in pairs(defaults) do
		local v = src[k]
		if v ~= nil then
			if typeof(def) == "Color3" then
				dst[k] = tableToColor(v)
			elseif typeof(def) == "EnumItem" then
				dst[k] = stringToKey(v, src.KeyType or "Keyboard")
			else
				dst[k] = v
			end
		elseif dst[k] == nil then
			dst[k] = deepClone(def)
		end
	end
end

local ConfigManager = {
	list = {},
	active = "default",
	meta = deepClone(META_DEFAULTS),
	dirty = false,
	_lastSave = 0,
	_widgets = {},
}

local Config, ESPConfig, AimCfg, SilentConfig, HitSoundCfg

local function getgenvSafe()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return nil
end

local function initLiveTables()
	local genv = getgenvSafe()
	if genv then
		Config = genv.Config
		if type(Config) ~= "table" then
			Config = deepClone(CONFIG_DEFAULTS)
			genv.Config = Config
		else
			for k, v in pairs(CONFIG_DEFAULTS) do
				if Config[k] == nil then
					Config[k] = v
				end
			end
		end
		ESPConfig = genv.RippedESP
		if type(ESPConfig) ~= "table" then
			ESPConfig = deepClone(ESP_DEFAULTS)
			genv.RippedESP = ESPConfig
		else
			for k, v in pairs(ESP_DEFAULTS) do
				if ESPConfig[k] == nil then
					ESPConfig[k] = v
				end
			end
		end
		AimCfg = genv.RippedAim
		if type(AimCfg) ~= "table" then
			AimCfg = deepClone(AIM_DEFAULTS)
			genv.RippedAim = AimCfg
		else
			for k, v in pairs(AIM_DEFAULTS) do
				if AimCfg[k] == nil then
					AimCfg[k] = v
				end
			end
		end
		SilentConfig = genv.RippedSilent
		if type(SilentConfig) ~= "table" then
			SilentConfig = deepClone(SILENT_DEFAULTS)
			genv.RippedSilent = SilentConfig
		else
			for k, v in pairs(SILENT_DEFAULTS) do
				if SilentConfig[k] == nil then
					SilentConfig[k] = v
				end
			end
		end
		HitSoundCfg = genv.RippedHits
		if type(HitSoundCfg) ~= "table" then
			HitSoundCfg = deepClone(HIT_DEFAULTS)
			genv.RippedHits = HitSoundCfg
		else
			for k, v in pairs(HIT_DEFAULTS) do
				if HitSoundCfg[k] == nil then
					HitSoundCfg[k] = v
				end
			end
		end
	else
		Config = deepClone(CONFIG_DEFAULTS)
		ESPConfig = deepClone(ESP_DEFAULTS)
		AimCfg = deepClone(AIM_DEFAULTS)
		SilentConfig = deepClone(SILENT_DEFAULTS)
		HitSoundCfg = deepClone(HIT_DEFAULTS)
	end
end

initLiveTables()

function ConfigManager.snapshot()
	return {
		version = 2,
		name = ConfigManager.active,
		meta = deepClone(ConfigManager.meta),
		rage = serializeSection(Config, CONFIG_DEFAULTS),
		esp = serializeSection(ESPConfig, ESP_DEFAULTS),
		aim = serializeSection(AimCfg, AIM_DEFAULTS),
		silent = serializeSection(SilentConfig, SILENT_DEFAULTS),
		hits = serializeSection(HitSoundCfg, HIT_DEFAULTS),
		skins = {
			enabled = Skins and Skins.enabled or false,
		},
	}
end

function ConfigManager.apply(data, opts)
	opts = opts or {}
	if type(data) ~= "table" then
		return false
	end
	if data.meta then
		for k, v in pairs(META_DEFAULTS) do
			if data.meta[k] ~= nil then
				ConfigManager.meta[k] = data.meta[k]
			end
		end
	end
	if data.rage then
		applySection(Config, data.rage, CONFIG_DEFAULTS)
	end
	if data.esp then
		applySection(ESPConfig, data.esp, ESP_DEFAULTS)
	end
	if data.aim then
		applySection(AimCfg, data.aim, AIM_DEFAULTS)
		if type(data.aim.Key) == "string" then
			AimCfg.Key = stringToKey(data.aim.Key, data.aim.KeyType or AimCfg.KeyType)
		end
	end
	if data.silent then
		applySection(SilentConfig, data.silent, SILENT_DEFAULTS)
	end
	if data.hits then
		applySection(HitSoundCfg, data.hits, HIT_DEFAULTS)
	end
	if data.name then
		ConfigManager.active = data.name
	end
	if not opts.skipApplyRuntime then
		ConfigManager.applyRuntime()
	end
	ConfigManager.dirty = false
	ConfigManager.refreshWidgets()
	return true
end

function ConfigManager.applyRuntime()
	if Esp then
		Esp.setEnabled(ESPConfig.Enabled == true)
	end
	if Aim then
		Aim.setEnabled(AimCfg.Enabled == true)
	end
	if Silent and SilentConfig.Enabled then
		Silent.install()
	end
	if Skins and data and data.skins then
		Skins.setEnabled(data.skins.enabled == true)
	elseif Skins and ConfigManager._lastSkinsEnabled ~= nil then
	end
end

function ConfigManager.markDirty()
	ConfigManager.dirty = true
end

function ConfigManager.writeFile(path, content)
	if type(writefile) ~= "function" then
		return false
	end
	ensureFolder()
	local ok = pcall(function()
		writefile(path, content)
	end)
	return ok
end

function ConfigManager.readFile(path)
	if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(path) then
		return nil
	end
	local ok, data = pcall(readfile, path)
	if ok then
		return data
	end
	return nil
end

function ConfigManager.save(name)
	name = name or ConfigManager.active or "default"
	name = tostring(name):gsub("[^%w%-%_ ]", ""):sub(1, 48)
	if name == "" then
		name = "default"
	end
	ConfigManager.active = name
	ConfigManager.meta.LastConfig = name
	local snap = ConfigManager.snapshot()
	snap.name = name
	local json = HttpService:JSONEncode(snap)
	local path = CONFIG_FOLDER .. "/" .. name .. ".json"
	local ok = ConfigManager.writeFile(path, json)
	if ok then
		ConfigManager.list[name] = true
		ConfigManager.writeIndex()
		ConfigManager.writeFile(ACTIVE_FILE, name)
		ConfigManager.dirty = false
		ConfigManager._lastSave = tick()
	end
	return ok
end

function ConfigManager.load(name)
	name = name or ConfigManager.active or "default"
	local path = CONFIG_FOLDER .. "/" .. name .. ".json"
	local raw = ConfigManager.readFile(path)
	if not raw then
		return false
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(data) ~= "table" then
		return false
	end
	ConfigManager.active = name
	ConfigManager.meta.LastConfig = name
	ConfigManager.writeFile(ACTIVE_FILE, name)
	return ConfigManager.apply(data)
end

function ConfigManager.delete(name)
	name = tostring(name or "")
	if name == "" or name == "default" then
		return false
	end
	local path = CONFIG_FOLDER .. "/" .. name .. ".json"
	if type(delfile) == "function" and type(isfile) == "function" and isfile(path) then
		pcall(delfile, path)
	end
	ConfigManager.list[name] = nil
	ConfigManager.writeIndex()
	if ConfigManager.active == name then
		ConfigManager.active = "default"
		ConfigManager.writeFile(ACTIVE_FILE, "default")
	end
	return true
end

function ConfigManager.writeIndex()
	local names = {}
	for n in pairs(ConfigManager.list) do
		table.insert(names, n)
	end
	table.sort(names)
	ConfigManager.writeFile(CONFIG_INDEX, HttpService:JSONEncode({
		configs = names,
		meta = ConfigManager.meta,
	}))
end

function ConfigManager.readIndex()
	local raw = ConfigManager.readFile(CONFIG_INDEX)
	if raw then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if ok and type(data) == "table" then
			if type(data.configs) == "table" then
				ConfigManager.list = {}
				for _, n in ipairs(data.configs) do
					ConfigManager.list[tostring(n)] = true
				end
			end
			if type(data.meta) == "table" then
				for k, v in pairs(META_DEFAULTS) do
					if data.meta[k] ~= nil then
						ConfigManager.meta[k] = data.meta[k]
					end
				end
			end
		end
	end
	local active = ConfigManager.readFile(ACTIVE_FILE)
	if active and active ~= "" then
		ConfigManager.active = active:match("^%s*(.-)%s*$") or "default"
	end
end

function ConfigManager.autosave()
	if not ConfigManager.meta.AutoSave then
		return
	end
	local snap = ConfigManager.snapshot()
	snap.name = ConfigManager.active
	ConfigManager.writeFile(AUTOSAVE_FILE, HttpService:JSONEncode(snap))
	ConfigManager._lastSave = tick()
	ConfigManager.dirty = false
end

function ConfigManager.autoload()
	ConfigManager.readIndex()
	if ConfigManager.meta.AutoLoad then
		local name = ConfigManager.meta.LastConfig or ConfigManager.active or "default"
		if ConfigManager.load(name) then
			return true, name
		end
		local auto = ConfigManager.readFile(AUTOSAVE_FILE)
		if auto then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(auto)
			end)
			if ok and type(data) == "table" then
				ConfigManager.apply(data)
				return true, "autosave"
			end
		end
	end
	return false
end

function ConfigManager.reset()
	applySection(Config, CONFIG_DEFAULTS, CONFIG_DEFAULTS)
	applySection(ESPConfig, ESP_DEFAULTS, ESP_DEFAULTS)
	applySection(AimCfg, AIM_DEFAULTS, AIM_DEFAULTS)
	applySection(SilentConfig, SILENT_DEFAULTS, SILENT_DEFAULTS)
	applySection(HitSoundCfg, HIT_DEFAULTS, HIT_DEFAULTS)
	ConfigManager.applyRuntime()
	ConfigManager.refreshWidgets()
	ConfigManager.dirty = true
end

function ConfigManager.registerWidget(key, widget)
	ConfigManager._widgets[key] = widget
end

function ConfigManager.refreshWidgets()
	for key, w in pairs(ConfigManager._widgets) do
		if w and w.set then
			local section, field = key:match("^(%w+)%.(.+)$")
			local src
			if section == "rage" then
				src = Config
			elseif section == "esp" then
				src = ESPConfig
			elseif section == "aim" then
				src = AimCfg
			elseif section == "silent" then
				src = SilentConfig
			elseif section == "hits" then
				src = HitSoundCfg
			elseif section == "meta" then
				src = ConfigManager.meta
			end
			if src and src[field] ~= nil then
				pcall(function()
					w.set(src[field])
				end)
			end
		end
	end
end

function ConfigManager.startAutosaveLoop()
	task.spawn(function()
		while not destroyed do
			task.wait(1)
			if ConfigManager.meta.AutoSave and ConfigManager.dirty then
				local interval = tonumber(ConfigManager.meta.AutoSaveInterval) or 30
				if tick() - ConfigManager._lastSave >= interval then
					ConfigManager.autosave()
					if ConfigManager.active and ConfigManager.active ~= "" then
						ConfigManager.save(ConfigManager.active)
					end
				end
			end
		end
	end)
end

local SLOTS = { Primary = 1, Secondary = 2, Melee = 3 }
local HITPART_CANDIDATES = {
	Head = { "Head" },
	Torso = { "UpperTorso", "Torso", "HumanoidRootPart" },
	Root = { "HumanoidRootPart" },
}

local rageUtil, rageEnum, FighterController, SpectateController
local rageLoaded = false
do
	local ok = pcall(function()
		rageUtil = require(repS.Modules.Utility)
		rageEnum = require(repS.Modules.EnumLibrary)
		local ps = player:FindFirstChildOfClass("PlayerScripts")
		local controllers = ps and ps:FindFirstChild("Controllers")
		FighterController = controllers and require(controllers.FighterController)
		local sctrl = controllers and controllers:FindFirstChild("SpectateController")
		SpectateController = sctrl and require(sctrl)
	end)
	rageLoaded = ok and rageUtil ~= nil and rageEnum ~= nil and FighterController ~= nil
end

Ragebot = {
	loaded = rageLoaded,
	running = false,
	conns = {},
	_target = "none",
}

local lastFire = 0
local deflecting = {}
local RESTORE_BIND = "__rippedwin_desync_restore"

local function rageConn(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Ragebot.conns, c)
	return c
end

local function updateDeflection()
	if not FighterController or not FighterController.Objects then
		return
	end
	for _, fighterObj in FighterController.Objects do
		local plr = fighterObj.Player
		if not plr then
			continue
		end
		if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
			deflecting[plr] = false
			continue
		end
		local equipped = fighterObj.EquippedItem
		local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
		local isDeflecting = false
		if isKatana then
			isDeflecting = (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
		end
		deflecting[plr] = isDeflecting
	end
end

local function isEnemy(plr)
	if plr == player then
		return false
	end
	local duel = SpectateController and SpectateController.CurrentDuelSubject
	local localDueler = duel and duel:GetDueler(player)
	local localTeam = localDueler and localDueler:Get("TeamID") or nil
	if localTeam and duel and duel.Duelers then
		for _, dueler in duel.Duelers do
			if dueler.Player == plr then
				local team = dueler:Get("TeamID")
				return team ~= localTeam
			end
		end
	end
	local pTeam = plr:GetAttribute("TeamID")
	local lTeam = player:GetAttribute("TeamID")
	if pTeam and lTeam then
		return pTeam ~= lTeam
	end
	return true
end

local function getHitPart(char)
	for _, name in ipairs(HITPART_CANDIDATES[Config.HitPart] or HITPART_CANDIDATES.Head) do
		local part = char:FindFirstChild(name)
		if part then
			return part
		end
	end
	return char:FindFirstChild("Head")
end

-- jitter table: cycle through offset positions to widen desync angle coverage
local JITTER_OFFSETS = {
	Vector3.new(0, 1, 2), Vector3.new(2, 1, -1), Vector3.new(-2, 1, 1),
	Vector3.new(1, 1, -2), Vector3.new(-1, 1, 2),
}
local jitterIdx = 0

local rageRayParams = RaycastParams.new()
rageRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function rageVisCheck(fromPos, targetChar, targetHead, targetRoot)
	rageRayParams.FilterDescendantsInstances = rayFilter(targetChar)
	local targetPos = targetHead and targetHead.Position or targetRoot.Position
	local result = workspace:Raycast(fromPos, targetPos - fromPos, rageRayParams)
	return result == nil
end

local function getClosestTarget()
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	local myRoot = char:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return nil, nil, nil
	end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize
	local fovPx = AimCfg.FOV
	local myPos = myRoot.Position
	local closestPlayer, closestRoot, closestHead
	local closestScore = math.huge
	for _, plr in Players:GetPlayers() do
		if not isEnemy(plr) or deflecting[plr] then
			continue
		end
		local pChar = plr.Character
		if not pChar then
			continue
		end
		local pRoot = pChar:FindFirstChild("HumanoidRootPart")
		local pHead = pChar:FindFirstChild("Head")
		local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
		if not (pRoot and pHead and pHum and pHum.Health > 0) then
			continue
		end
		local dist3D = (myPos - pRoot.Position).Magnitude
		if dist3D > Config.Range then
			continue
		end
		-- optional visibility gate
		if Config.VisibleCheck and not rageVisCheck(myPos, pChar, pHead, pRoot) then
			continue
		end
		-- optional FOV gate (screen-space)
		local screenDist = 0
		if Config.UseFOV and cam and vp then
			local sp = cam:WorldToViewportPoint(pRoot.Position)
			if sp.Z <= 0 then
				continue
			end
			screenDist = math.sqrt((sp.X - vp.X/2)^2 + (sp.Y - vp.Y/2)^2)
			if screenDist > fovPx then
				continue
			end
		end
		-- score: 3D distance primary, screen distance secondary (tiebreaker when FOV off)
		local score = dist3D + screenDist * 0.01
		if score < closestScore then
			closestScore = score
			closestPlayer, closestRoot, closestHead = plr, pRoot, pHead
		end
	end
	return closestPlayer, closestRoot, closestHead
end

local function hasKnifeViewModel(targetPlayer)
	if not targetPlayer then
		return false
	end
	local viewModels = ws:FindFirstChild("ViewModels")
	if not viewModels then
		return false
	end
	local targetName = targetPlayer.Name
	for _, model in viewModels:GetChildren() do
		if model:IsA("Model")
			and string.find(model.Name, targetName, 1, true)
			and string.find(model.Name, "Knife", 1, true) then
			return true
		end
	end
	return false
end

local function onHeartbeat()
	updateDeflection()
	local targetPlayer, targetRoot, targetHead = getClosestTarget()
	Ragebot._target = targetPlayer and targetPlayer.Name or "none"

	local itemReady = true
	if Config.RequireEquipped then
		local lf = FighterController and FighterController.LocalFighter
		itemReady = lf ~= nil and lf.EquippedItem ~= nil
	end

	local desyncCF = nil
	if itemReady and Config.Desync and targetRoot and targetHead then
		local desyncPos
		if Config.DesyncJitter then
			-- cycle through jitter offsets to prevent server-side trajectory prediction
			jitterIdx = (jitterIdx % #JITTER_OFFSETS) + 1
			desyncPos = (targetRoot.CFrame * CFrame.new(JITTER_OFFSETS[jitterIdx])).Position
		elseif hasKnifeViewModel(targetPlayer) then
			desyncPos = (targetRoot.CFrame * CFrame.new(0, 6, 0)).Position
		else
			desyncPos = (targetRoot.CFrame * CFrame.new(0, 1, 2)).Position
		end
		desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
	end

	if desyncCF and player.Character then
		local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
		if myRoot then
			local oldCF = myRoot.CFrame
			local oldVel = myRoot.Velocity
			local oldRotVel = myRoot.RotVelocity
			myRoot.CFrame = desyncCF
			runS:BindToRenderStep(RESTORE_BIND, 101, function()
				if myRoot then
					myRoot.CFrame = oldCF
					myRoot.Velocity = oldVel
					myRoot.RotVelocity = oldRotVel
				end
				runS:UnbindFromRenderStep(RESTORE_BIND)
			end)
		end
	end

	if not Config.Enabled then
		return
	end
	if not itemReady then
		return
	end
	if not targetPlayer or not targetHead or not targetRoot then
		return
	end
	if deflecting[targetPlayer] then
		return
	end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	if not FighterController or not FighterController.LocalFighter then
		return
	end
	local item = FighterController.LocalFighter.EquippedItem
	if not item then
		return
	end
	if tick() - lastFire < Config.FireRate then
		return
	end
	lastFire = tick()
	-- origin for the aim ray must be the local shooter's own position, not the desync offset.
	-- desyncCF only moves our HRP for one frame to confuse the server about our stance.
	-- using desyncCF.Position as origin made shots physically impossible from the server's perspective.
	local myChar = player.Character
	local myRoot2 = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local originPos = myRoot2 and myRoot2.Position or targetRoot.Position
	local aimPart = getHitPart(targetPlayer.Character) or targetHead
	local targetPos = aimPart.Position
	local aimCF = CFrame.lookAt(originPos, targetPos)
	local targetCF = aimPart.CFrame
	local spread = Config.Spread or 0
	local randomOffset = Vector3.new(
		(math.random() - 0.5) * spread,
		(math.random() - 0.5) * spread,
		(math.random() - 0.5) * spread
	)
	-- AutoLead: estimate server receive latency as half the network round-trip
	local lead = Config.Lead or 0
	if Config.AutoLead then
		local ok, stats = pcall(function() return game:GetService("Stats") end)
		if ok and stats then
			local pingMs = stats.Network.ServerStatsItem["Data Ping"].Value
			lead = math.clamp(pingMs / 2 / 1000, 0, 0.25)	-- cap at 250ms lead
		end
	end
	local aimedPos = targetPos + targetRoot.Velocity * lead + randomOffset
	-- S_ETX: object-space hit offset encoded as a CFrame.
	-- Server resolves final hit world pos as: aimPart.CFrame * decode(S_ETX)
	-- To hit part center: identity (zero translation, zero rotation).
	-- To hit an offset (e.g. top of head): CFrame.new(0, 0.4, 0).
	-- The old ToObjectSpace encoding was computing world→local of aimedPos which
	-- gave a non-zero rotation component the server rejected as inconsistent.
	local hitOffset = CFrame.new(0, 0, 0) -- center of part; adjust for subpart targeting
	local cameradata = {}
	cameradata[utf8.char(1)] = {
		[utf8.char(0)] = rageUtil:EncodeCFrame(aimCF),
		[utf8.char(1)] = rageUtil:EncodeCFrame(targetCF),
		[utf8.char(2)] = aimPart,
		[utf8.char(3)] = rageUtil:EncodeCFrame(hitOffset),
	}
	silentGuard = true
	pcall(function()
		repS.Remotes.Replication.Fighter.UseItem:FireServer(
			item:Get("ObjectID"),
			rageEnum:ToEnum("StartShooting"),
			cameradata,
			nil
		)
	end)
	silentGuard = false
	if HitSounds then
		HitSounds.noteShot(targetPlayer, aimPart.Name == "Head")
	end
end

function Ragebot.equip()
	if not rageLoaded then
		return
	end
	local lf = FighterController and FighterController.LocalFighter
	if lf then
		pcall(function()
			lf:EquipItem(SLOTS[Config.WeaponSlot] or 3)
		end)
	end
end

function Ragebot.getEquippedName()
	if not rageLoaded then
		return nil
	end
	local lf = FighterController and FighterController.LocalFighter
	local item = lf and lf.EquippedItem
	if not item then
		return nil
	end
	local ok, name = pcall(function()
		local vm = item.ViewModel
		return vm and vm.Name or nil
	end)
	if ok and name then
		return tostring(name)
	end
	return "equipped"
end

function Ragebot.start()
	if not Ragebot.loaded or Ragebot.running then
		return
	end
	Ragebot.running = true
	rageConn(Players.PlayerRemoving, function(plr)
		deflecting[plr] = nil
	end)
	rageConn(runS.Heartbeat, onHeartbeat)
	task.spawn(function()
		local lf = FighterController.LocalFighter
		while Ragebot.running and not lf do
			task.wait(0.1)
			lf = FighterController.LocalFighter
		end
		if Ragebot.running then
			Ragebot.equip()
		end
	end)
	task.spawn(function()
		while Ragebot.running do
			task.wait(1)
			if Ragebot.running and Config.AutoEquip then
				Ragebot.equip()
			end
		end
	end)
end

function Ragebot.stop()
	Ragebot.running = false
	for _, c in ipairs(Ragebot.conns) do
		c:Disconnect()
	end
	table.clear(Ragebot.conns)
	pcall(function()
		runS:UnbindFromRenderStep(RESTORE_BIND)
	end)
end

local function rayFilter(char, cam)
	local filter = { char }
	local lchar = player.Character
	if lchar then
		table.insert(filter, lchar)
	end
	cam = cam or workspace.CurrentCamera
	if cam then
		table.insert(filter, cam)
	end
	local vm = ws:FindFirstChild("ViewModels")
	if vm then
		table.insert(filter, vm)
	end
	return filter
end

local hasDrawing = (type(Drawing) == "table" or type(Drawing) == "userdata")
	and type(Drawing.new) == "function"

local R15_BONES = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}
local R6_BONES = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

Esp = {
	running = false,
	conns = {},
	lifecycle = nil,
}
local espPool = {}
local espChams = {}
local espWeapons = {}
local espVis = {}
local espRayParams = RaycastParams.new()
espRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function espDestroyCham(plr)
	local cham = espChams[plr]
	if cham then
		if cham.hl then
			pcall(function()
				cham.hl:Destroy()
			end)
		end
		espChams[plr] = nil
	end
end

local function espHidePool(pool)
	for _, o in ipairs(pool.objs) do
		o.Visible = false
	end
end

local function espReleasePool(plr)
	local pool = espPool[plr]
	if pool then
		for _, o in ipairs(pool.objs) do
			pcall(function()
				o:Remove()
			end)
		end
		espPool[plr] = nil
	end
	espDestroyCham(plr)
	espVis[plr] = nil
end

local function espReleaseAll()
	local seen = {}
	for plr in pairs(espPool) do
		seen[plr] = true
	end
	for plr in pairs(espChams) do
		seen[plr] = true
	end
	for plr in pairs(seen) do
		espReleasePool(plr)
	end
	table.clear(espWeapons)
	table.clear(espVis)
end

local function newDrawing(class, props)
	local ok, obj = pcall(Drawing.new, class)
	if not ok or not obj then
		return nil
	end
	for k, v in pairs(props or {}) do
		pcall(function()
			obj[k] = v
		end)
	end
	return obj
end

local function espCreatePool(plr)
	local pool = { objs = {}, char = nil, bones = {}, bonesDirty = true }
	local function add(class, props)
		local o = newDrawing(class, props)
		if o then
			table.insert(pool.objs, o)
		end
		return o
	end
	pool.fill = add("Square", { Filled = true, Thickness = 1, Transparency = 0.65, Visible = false, ZIndex = 1 })
	pool.box = add("Square", { Filled = false, Thickness = 1, Transparency = 1, Visible = false, ZIndex = 2 })
	pool.corners = {}
	for _ = 1, 8 do
		table.insert(pool.corners, add("Line", { Thickness = 1.5, Transparency = 1, Visible = false, ZIndex = 2 }))
	end
	pool.tracer = add("Line", { Thickness = 1, Transparency = 1, Visible = false, ZIndex = 1 })
	pool.name = add("Text", { Size = 13, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Transparency = 1, Visible = false, ZIndex = 3, Font = 2 })
	pool.dist = add("Text", { Size = 12, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Transparency = 1, Visible = false, ZIndex = 3, Font = 2 })
	pool.weapon = add("Text", { Size = 12, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Transparency = 1, Visible = false, ZIndex = 3, Font = 2 })
	pool.hnum = add("Text", { Size = 11, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Transparency = 1, Visible = false, ZIndex = 3, Font = 2 })
	pool.hpBack = add("Square", { Filled = true, Thickness = 1, Transparency = 0.55, Color = Color3.new(0, 0, 0), Visible = false, ZIndex = 2 })
	pool.hpFill = add("Square", { Filled = true, Thickness = 1, Transparency = 1, Visible = false, ZIndex = 2 })
	pool.head = add("Circle", { Filled = true, Thickness = 1, NumSides = 16, Transparency = 0.8, Visible = false, ZIndex = 2 })
	pool.skLines = {}
	for _ = 1, #R15_BONES do
		table.insert(pool.skLines, add("Line", { Thickness = 1.2, Transparency = 0.85, Visible = false, ZIndex = 2 }))
	end
	espPool[plr] = pool
	return pool
end

local function espResolveBones(pool, char)
	local bones = {}
	local rig = char:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
	local dirty = false
	for _, pair in ipairs(rig) do
		local p0 = char:FindFirstChild(pair[1])
		local p1 = char:FindFirstChild(pair[2])
		if p0 and p1 then
			table.insert(bones, { p0, p1 })
		else
			dirty = true
		end
	end
	pool.bones = bones
	pool.bonesDirty = dirty
end

local espWeaponsAt = 0
local function espRefreshWeapons()
	local now = tick()
	if now - espWeaponsAt < 0.25 then
		return
	end
	espWeaponsAt = now
	table.clear(espWeapons)
	if not rageLoaded or not FighterController or not FighterController.Objects then
		return
	end
	for _, fighterObj in FighterController.Objects do
		local plr = fighterObj.Player
		if plr then
			local ok, name = pcall(function()
				local item = fighterObj.EquippedItem
				return item and item.ViewModel and item.ViewModel.Name or nil
			end)
			if ok and name then
				espWeapons[plr] = tostring(name)
			end
		end
	end
end

local function getWeaponName(plr, char)
	local cached = espWeapons[plr]
	if cached then
		return cached
	end
	local tool = char and char:FindFirstChildOfClass("Tool")
	return tool and tool.Name or nil
end

local function espUpdateChams(plr, char, color, throughWalls)
	local cham = espChams[plr]
	if not cham or cham.char ~= char or not cham.hl or cham.hl.Parent ~= char then
		espDestroyCham(plr)
		local ok, hl = pcall(function()
			local h = Instance.new("Highlight")
			h.Name = "_ripped_esp_cham"
			h.Adornee = char
			h.FillTransparency = 0.65
			h.OutlineTransparency = 0.1
			h.Enabled = true
			h.Parent = char
			return h
		end)
		if not ok or not hl then
			return
		end
		cham = { hl = hl, char = char, mode = nil }
		espChams[plr] = cham
	end
	local mode = throughWalls and "top" or "occ"
	if cham.mode ~= mode then
		cham.mode = mode
		cham.hl.DepthMode = throughWalls
			and Enum.HighlightDepthMode.AlwaysOnTop
			or Enum.HighlightDepthMode.OccludedOnly
	end
	cham.hl.FillColor = color
	cham.hl.OutlineColor = color
end

local function espFrame()
	local cam = workspace.CurrentCamera
	if not cam then
		for _, pool in pairs(espPool) do
			espHidePool(pool)
		end
		return
	end
	espRefreshWeapons()
	local vpSize = cam.ViewportSize
	local camPos = cam.CFrame.Position
	local activePlayers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		activePlayers[plr] = true
		local pool = espPool[plr]
		if not pool and hasDrawing then
			pool = espCreatePool(plr)
		end

		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local dead = char == nil or char.Parent == nil
			or hum == nil or root == nil or hum.Health <= 0
		if dead then
			if pool then
				espHidePool(pool)
			end
			espDestroyCham(plr)
			continue
		end

		local okE, enemy = pcall(isEnemy, plr)
		if not okE then
			enemy = true
		end
		if ESPConfig.TeamCheck and not enemy then
			if pool then
				espHidePool(pool)
			end
			espDestroyCham(plr)
			continue
		end

		local dist = (camPos - root.Position).Magnitude
		if ESPConfig.MaxDistance > 0 and dist > ESPConfig.MaxDistance then
			if pool then
				espHidePool(pool)
			end
			espDestroyCham(plr)
			continue
		end

		local vis
		if ESPConfig.VisibleCheck then
			local cache = espVis[plr]
			if not cache or tick() - cache.at > 0.1 then
				espRayParams.FilterDescendantsInstances = rayFilter(char, cam)
				local targetPos = head and head.Position or root.Position
				local result = workspace:Raycast(camPos, targetPos - camPos, espRayParams)
				espVis[plr] = { state = result == nil, at = tick() }
				cache = espVis[plr]
			end
			vis = cache.state
		else
			vis = true
		end

		local color = enemy
			and (vis and ESPConfig.EnemyColor or ESPConfig.HiddenColor)
			or ESPConfig.TeamColor

		if ESPConfig.Chams then
			espUpdateChams(plr, char, color, ESPConfig.ChamsThroughWalls)
		else
			espDestroyCham(plr)
		end

		if not pool then
			continue
		end

		local okBB, cf, size = pcall(function()
			return char:GetBoundingBox()
		end)
		if not okBB or size.Magnitude <= 0 then
			espHidePool(pool)
			continue
		end

		local anyOnScreen = false
		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		local half = size / 2
		for cx = -1, 1, 2 do
			for cy = -1, 1, 2 do
				for cz = -1, 1, 2 do
					local wp = cf * Vector3.new(half.X * cx, half.Y * cy, half.Z * cz)
					local sp = cam:WorldToViewportPoint(wp)
					if sp.Z > 0 then
						anyOnScreen = true
						if sp.X < minX then
							minX = sp.X
						end
						if sp.Y < minY then
							minY = sp.Y
						end
						if sp.X > maxX then
							maxX = sp.X
						end
						if sp.Y > maxY then
							maxY = sp.Y
						end
					end
				end
			end
		end
		local boxW, boxH = maxX - minX, maxY - minY
		local boxOK = anyOnScreen and boxW > 2 and boxH > 2
			and boxW == boxW and boxH == boxH
		local boxCX = (minX + maxX) / 2
		local boxBottom = maxY

		if pool.fill then
			local show = boxOK and ESPConfig.BoxFill
			pool.fill.Visible = show
			if show then
				pool.fill.Position = Vector2.new(minX, minY)
				pool.fill.Size = Vector2.new(boxW, boxH)
				pool.fill.Color = color
			end
		end

		if pool.box then
			local show = boxOK and ESPConfig.BoxStyle == "Full"
			pool.box.Visible = show
			if show then
				pool.box.Position = Vector2.new(minX, minY)
				pool.box.Size = Vector2.new(boxW, boxH)
				pool.box.Color = color
			end
		end

		local cornerDefs = nil
		if boxOK and ESPConfig.BoxStyle == "Corner" then
			local cl = math.clamp(math.min(boxW, boxH) * 0.28, 4, 30)
			cornerDefs = {
				{ minX, minY, minX + cl, minY }, { minX, minY, minX, minY + cl },
				{ maxX, minY, maxX - cl, minY }, { maxX, minY, maxX, minY + cl },
				{ minX, maxY, minX + cl, maxY }, { minX, maxY, minX, maxY - cl },
				{ maxX, maxY, maxX - cl, maxY }, { maxX, maxY, maxX, maxY - cl },
			}
		end
		for i, line in ipairs(pool.corners) do
			local d = cornerDefs and cornerDefs[i]
			if d then
				line.From = Vector2.new(d[1], d[2])
				line.To = Vector2.new(d[3], d[4])
				line.Color = color
				line.Visible = true
			else
				line.Visible = false
			end
		end

		local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		if pool.hpBack then
			local show = boxOK and ESPConfig.HealthBar
			pool.hpBack.Visible = show
			if show then
				pool.hpBack.Position = Vector2.new(minX - 6, minY)
				pool.hpBack.Size = Vector2.new(2, boxH)
			end
		end
		if pool.hpFill then
			local show = boxOK and ESPConfig.HealthBar
			pool.hpFill.Visible = show
			if show then
				local fh = math.max(boxH * frac, 1)
				pool.hpFill.Position = Vector2.new(minX - 6, boxBottom - fh)
				pool.hpFill.Size = Vector2.new(2, fh)
				pool.hpFill.Color = Color3.fromRGB(
					math.floor(255 * (1 - frac)),
					math.floor(220 * frac + 35),
					60
				)
			end
		end

		if pool.name then
			local show = boxOK and ESPConfig.Name
			pool.name.Visible = show
			if show then
				pool.name.Text = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
				pool.name.Position = Vector2.new(boxCX, minY - 16)
				pool.name.Color = color
			end
		end

		if pool.dist then
			local show = boxOK and ESPConfig.DistanceText
			pool.dist.Visible = show
			if show then
				pool.dist.Text = math.floor(dist + 0.5) .. "m"
				pool.dist.Position = Vector2.new(boxCX, boxBottom + 2)
				pool.dist.Color = color
			end
		end

		if pool.weapon then
			local wname = ESPConfig.WeaponText and getWeaponName(plr, char) or nil
			local show = boxOK and wname ~= nil
			pool.weapon.Visible = show
			if show then
				pool.weapon.Text = tostring(wname)
				pool.weapon.Position = Vector2.new(boxCX, boxBottom + (ESPConfig.DistanceText and 16 or 2))
				pool.weapon.Color = color
			end
		end

		if pool.hnum then
			local show = boxOK and ESPConfig.HealthNumber
			pool.hnum.Visible = show
			if show then
				pool.hnum.Text = tostring(math.ceil(hum.Health))
				pool.hnum.Position = Vector2.new(minX - 8, boxBottom + 2)
				pool.hnum.Color = color
			end
		end

		if pool.head then
			local show = boxOK and ESPConfig.HeadDot and head ~= nil
			pool.head.Visible = show
			if show then
				local hp = cam:WorldToViewportPoint(head.Position)
				if hp.Z > 0 then
					pool.head.Position = Vector2.new(hp.X, hp.Y)
					pool.head.Radius = math.clamp(500 / dist, 2, 7)
					pool.head.Color = color
				else
					pool.head.Visible = false
				end
			end
		end

		if pool.tracer then
			local show = boxOK and ESPConfig.Tracer ~= "Off"
			pool.tracer.Visible = show
			if show then
				local oy = 0
				if ESPConfig.Tracer == "Bottom" then
					oy = vpSize.Y
				elseif ESPConfig.Tracer == "Center" then
					oy = vpSize.Y / 2
				end
				pool.tracer.From = Vector2.new(vpSize.X / 2, oy)
				pool.tracer.To = Vector2.new(boxCX, boxBottom)
				pool.tracer.Color = color
			end
		end

		if ESPConfig.Skeleton then
			if char ~= pool.char or pool.bonesDirty then
				espResolveBones(pool, char)
				pool.char = char
			end
			for i, line in ipairs(pool.skLines) do
				local bone = boxOK and pool.bones[i]
				if bone then
					local a = cam:WorldToViewportPoint(bone[1].Position)
					local b = cam:WorldToViewportPoint(bone[2].Position)
					if a.Z > 0 and b.Z > 0 then
						line.From = Vector2.new(a.X, a.Y)
						line.To = Vector2.new(b.X, b.Y)
						line.Color = color
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			end
		else
			for _, line in ipairs(pool.skLines) do
				line.Visible = false
			end
		end
	end

	for plr in pairs(espPool) do
		if not activePlayers[plr] then
			espReleasePool(plr)
		end
	end
	for plr in pairs(espChams) do
		if not activePlayers[plr] then
			espDestroyCham(plr)
		end
	end
	for plr in pairs(espVis) do
		if not activePlayers[plr] then
			espVis[plr] = nil
		end
	end
end

function Esp.setEnabled(on)
	on = on == true
	if on == Esp.running then
		return
	end
	Esp.running = on
	if on then
		table.insert(Esp.conns, runS.RenderStepped:Connect(espFrame))
	else
		for _, c in ipairs(Esp.conns) do
			c:Disconnect()
		end
		table.clear(Esp.conns)
		espReleaseAll()
	end
end

function Esp.stop()
	Esp.running = false
	for _, c in ipairs(Esp.conns) do
		c:Disconnect()
	end
	table.clear(Esp.conns)
	if Esp.lifecycle then
		Esp.lifecycle:Disconnect()
		Esp.lifecycle = nil
	end
	espReleaseAll()
end

Esp.lifecycle = Players.PlayerRemoving:Connect(function(plr)
	espReleasePool(plr)
	espWeapons[plr] = nil
end)

Aim = {
	running = false,
	toggled = false,
	sticky = nil,
	conns = {},
	viz = nil,
}

local AIM_BIND = "__rippedwin_aim"
local aimVis = {}
local aimRayParams = RaycastParams.new()
aimRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function checkVisibleAim(plr, char, head, root, fromPos)
	local cached = aimVis[plr]
	local now = tick()
	if not cached or now - cached.at > 0.1 then
		aimRayParams.FilterDescendantsInstances = rayFilter(char)
		local targetPos = head and head.Position or root.Position
		cached = {
			state = workspace:Raycast(fromPos, targetPos - fromPos, aimRayParams) == nil,
			at = now,
		}
		aimVis[plr] = cached
	end
	return cached.state
end

local function resolvePartFor(char, cam, mode)
	if mode == "Nearest" then
		local best, bestD = nil, math.huge
		local vp = cam.ViewportSize
		for _, name in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart" }) do
			local p = char:FindFirstChild(name)
			if p then
				local sp = cam:WorldToViewportPoint(p.Position)
				if sp.Z > 0 then
					local d = math.sqrt((sp.X - vp.X / 2) ^ 2 + (sp.Y - vp.Y / 2) ^ 2)
					if d < bestD then
						best, bestD = p, d
					end
				end
			end
		end
		return best
	end
	local names = mode == "Torso"
		and { "UpperTorso", "Torso", "HumanoidRootPart" }
		or { "Head" }
	for _, name in ipairs(names) do
		local p = char:FindFirstChild(name)
		if p then
			return p
		end
	end
	return char:FindFirstChild("Head")
end

function Aim.pick()
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local camPos = cam.CFrame.Position
	local best = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == player then
			continue
		end
		if AimCfg.TeamCheck then
			local okE, enemy = pcall(isEnemy, plr)
			if not okE or not enemy then
				continue
			end
		end
		local char = plr.Character
		if not char or char.Parent == nil then
			continue
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then
			continue
		end
		local dist = (camPos - root.Position).Magnitude
		if dist > AimCfg.MaxDistance or dist < 1 then
			continue
		end
		if AimCfg.VisibleCheck
			and not checkVisibleAim(plr, char, char:FindFirstChild("Head"), root, camPos) then
			continue
		end
		local part = resolvePartFor(char, cam, AimCfg.HitPart)
		if not part then
			continue
		end
		local sp = cam:WorldToViewportPoint(part.Position)
		if sp.Z <= 0 then
			continue
		end
		local vp = cam.ViewportSize
		local crossDist = math.sqrt((sp.X - vp.X / 2) ^ 2 + (sp.Y - vp.Y / 2) ^ 2)
		if crossDist > AimCfg.FOV then
			continue
		end
		local score
		if AimCfg.Selection == "Health" then
			score = hum.Health
		elseif AimCfg.Selection == "Distance" then
			score = dist
		else
			score = crossDist
		end
		if not best or score < best.score then
			best = { player = plr, char = char, hum = hum, root = root, part = part, score = score }
		end
	end
	return best
end

function Aim.activeNow()
	if AimCfg.Activation == "Always" then
		return true
	end
	if AimCfg.Activation == "Toggle" then
		return Aim.toggled
	end
	if AimCfg.KeyType == "Mouse" then
		return UserInputService:IsMouseButtonPressed(AimCfg.Key)
	end
	return UserInputService:IsKeyDown(AimCfg.Key)
end

local function hideAimViz()
	local viz = Aim.viz
	if not viz then
		return
	end
	for _, o in ipairs(viz.all) do
		o.Visible = false
	end
end

local function drawDashes(from, to, lines, color)
	local dx, dy = to.X - from.X, to.Y - from.Y
	local len = math.sqrt(dx * dx + dy * dy)
	local i = 1
	if len >= 6 then
		local ux, uy = dx / len, dy / len
		local pos = 0
		local dash, gap = 10, 8
		while pos < len and i <= #lines do
			local segEnd = math.min(pos + dash, len)
			local line = lines[i]
			line.From = Vector2.new(from.X + ux * pos, from.Y + uy * pos)
			line.To = Vector2.new(from.X + ux * segEnd, from.Y + uy * segEnd)
			line.Color = color
			line.Visible = true
			i += 1
			pos += dash + gap
		end
	end
	for j = i, #lines do
		lines[j].Visible = false
	end
end

local function drawAimViz(cam, target)
	local viz = Aim.viz
	if not viz then
		return
	end
	if not target then
		hideAimViz()
		return
	end
	local okBB, cf, size = pcall(target.char.GetBoundingBox, target.char)
	if not okBB or size.Magnitude <= 0 then
		hideAimViz()
		return
	end
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local half = size / 2
	for cx = -1, 1, 2 do
		for cy = -1, 1, 2 do
			for cz = -1, 1, 2 do
				local sp = cam:WorldToViewportPoint(cf * Vector3.new(half.X * cx, half.Y * cy, half.Z * cz))
				if sp.Z > 0 then
					minX = math.min(minX, sp.X)
					minY = math.min(minY, sp.Y)
					maxX = math.max(maxX, sp.X)
					maxY = math.max(maxY, sp.Y)
				end
			end
		end
	end
	local boxW, boxH = maxX - minX, maxY - minY
	if boxW < 2 or boxH < 2 or boxW ~= boxW or boxH ~= boxH then
		hideAimViz()
		return
	end
	local color = AimCfg.SnapColor
	local boxCX = (minX + maxX) / 2
	local boxCY = (minY + maxY) / 2

	if AimCfg.SnapLine then
		local vp = cam.ViewportSize
		drawDashes(Vector2.new(vp.X / 2, vp.Y / 2), Vector2.new(boxCX, boxCY), viz.dashes, color)
	else
		for _, l in ipairs(viz.dashes) do
			l.Visible = false
		end
	end

	local cornerDefs = nil
	if AimCfg.TargetBox then
		local cl = math.clamp(math.min(boxW, boxH) * 0.28, 4, 30)
		cornerDefs = {
			{ minX, minY, minX + cl, minY }, { minX, minY, minX, minY + cl },
			{ maxX, minY, maxX - cl, minY }, { maxX, minY, maxX, minY + cl },
			{ minX, maxY, minX + cl, maxY }, { minX, maxY, minX, maxY - cl },
			{ maxX, maxY, maxX - cl, maxY }, { maxX, maxY, maxX, maxY - cl },
		}
	end
	for i, line in ipairs(viz.corners) do
		local d = cornerDefs and cornerDefs[i]
		if d then
			line.From = Vector2.new(d[1], d[2])
			line.To = Vector2.new(d[3], d[4])
			line.Color = color
			line.Visible = true
		else
			line.Visible = false
		end
	end

	if AimCfg.TargetHp then
		local frac = math.clamp(target.hum.Health / math.max(target.hum.MaxHealth, 1), 0, 1)
		local barH = boxH + 2
		viz.hpBack.Visible = true
		viz.hpBack.Position = Vector2.new(minX - 7, minY - 1)
		viz.hpBack.Size = Vector2.new(3, barH)
		viz.hpFill.Visible = true
		local fh = math.max(barH * frac, 1)
		viz.hpFill.Position = Vector2.new(minX - 7, maxY + 1 - fh)
		viz.hpFill.Size = Vector2.new(3, fh)
		viz.hpFill.Color = Color3.fromRGB(70, 225, 110)
	else
		viz.hpBack.Visible = false
		viz.hpFill.Visible = false
	end
end

local function aimStep()
	local cam = workspace.CurrentCamera
	if not cam then
		hideAimViz()
		if Aim.viz and Aim.viz.circle then
			Aim.viz.circle.Visible = false
		end
		return
	end
	local target = nil
	if Aim.running and Aim.activeNow() then
		local lchar = player.Character
		local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")
		local lhum = lchar and lchar:FindFirstChildOfClass("Humanoid")
		local equippedOK = not AimCfg.RequireEquipped
			or (Ragebot.loaded and Ragebot.getEquippedName() ~= nil)
		if lchar and lroot and lhum and lhum.Health > 0 and equippedOK then
			if not AimCfg.AutoSwitch and Aim.sticky then
				local s = Aim.sticky
				if s.char.Parent and s.hum and s.hum.Health > 0 and s.part and s.part.Parent then
					target = s
				else
					Aim.sticky = nil
				end
			end
			if not target then
				target = Aim.pick()
				Aim.sticky = target
			end
		end
	end
	if target then
		local aimPos = target.part.Position + target.root.Velocity * (AimCfg.PredictionMs / 1000)
		local alpha = AimCfg.Smoothing <= 0.01 and 1 or (1 - math.clamp(AimCfg.Smoothing, 0, 0.95))
		if AimCfg.Method == "Mouse" and type(mousemoverel) == "function" then
			local sp = cam:WorldToViewportPoint(aimPos)
			if sp.Z > 0 then
				local vp = cam.ViewportSize
				local dx, dy = sp.X - vp.X / 2, sp.Y - vp.Y / 2
				pcall(function()
					mousemoverel(dx * alpha, dy * alpha)
				end)
			end
		else
			local camPos = cam.CFrame.Position
			local want = CFrame.lookAt(camPos, aimPos)
			local newCF = alpha >= 1 and want or cam.CFrame:Lerp(want, alpha)
			pcall(function()
				cam.CFrame = newCF
			end)
		end
	end
	drawAimViz(cam, target)

	local fovCircle = Aim.viz and Aim.viz.circle
	if fovCircle then
		if AimCfg.FovCircle then
			local vp = cam.ViewportSize
			fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
			fovCircle.Radius = AimCfg.FOV
			fovCircle.Color = AimCfg.SnapColor
			fovCircle.Visible = true
		else
			fovCircle.Visible = false
		end
	end
end

function Aim.setEnabled(on)
	on = on == true
	if on == Aim.running then
		return
	end
	if on then
		if hasDrawing then
			local viz = { dashes = {}, corners = {}, all = {} }
			for _ = 1, 40 do
				local l = newDrawing("Line", { Thickness = 1.4, Transparency = 0.35, Visible = false, ZIndex = 4 })
				if l then
					table.insert(viz.dashes, l)
					table.insert(viz.all, l)
				end
			end
			for _ = 1, 8 do
				local l = newDrawing("Line", { Thickness = 1.2, Transparency = 0, Visible = false, ZIndex = 4 })
				if l then
					table.insert(viz.corners, l)
					table.insert(viz.all, l)
				end
			end
			viz.hpBack = newDrawing("Square", { Filled = true, Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.45, Visible = false, ZIndex = 4 })
			viz.hpFill = newDrawing("Square", { Filled = true, Thickness = 1, Color = Color3.fromRGB(70, 225, 110), Transparency = 0, Visible = false, ZIndex = 4 })
			if viz.hpBack then
				table.insert(viz.all, viz.hpBack)
			end
			if viz.hpFill then
				table.insert(viz.all, viz.hpFill)
			end
			viz.circle = newDrawing("Circle", { Thickness = 1, Transparency = 0.45, Filled = false, NumSides = 64, Visible = false, ZIndex = 3, Color = AimCfg.SnapColor })
			Aim.viz = viz
		end
		table.insert(Aim.conns, Players.PlayerRemoving:Connect(function(plr)
			aimVis[plr] = nil
		end))
		table.insert(Aim.conns, UserInputService.InputBegan:Connect(function(input, processed)
			if processed or AimCfg.Activation ~= "Toggle" then
				return
			end
			local match
			if AimCfg.KeyType == "Mouse" then
				match = input.UserInputType == AimCfg.Key
			else
				match = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == AimCfg.Key
			end
			if match then
				Aim.toggled = not Aim.toggled
			end
		end))
		runS:BindToRenderStep(AIM_BIND, Enum.RenderPriority.Camera.Value + 1, aimStep)
		Aim.running = true
	else
		Aim.stop()
	end
end

function Aim.stop()
	Aim.running = false
	Aim.sticky = nil
	Aim.toggled = false
	pcall(function()
		runS:UnbindFromRenderStep(AIM_BIND)
	end)
	for _, c in ipairs(Aim.conns) do
		c:Disconnect()
	end
	table.clear(Aim.conns)
	if Aim.viz then
		for _, o in ipairs(Aim.viz.all) do
			pcall(function()
				o:Remove()
			end)
		end
		if Aim.viz.circle then
			pcall(function()
				Aim.viz.circle:Remove()
			end)
		end
		Aim.viz = nil
	end
	table.clear(aimVis)
end

local S_NUL, S_SOH, S_STX, S_ETX = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)

Silent = {
	supported = rageLoaded,
	hooked = false,
	clickReady = false,
	clicks = 0,
	lastClick = 0,
	redirects = 0,
	lastName = "—",
	lastAt = 0,
	conns = {},
	fovCircle = nil,
	token = { alive = true },
}

if type(getgenv) == "function" then
	local oldToken = getgenv().__RIPPEDWIN_SILENT_TOKEN
	if type(oldToken) == "table" then
		oldToken.alive = false
	end
	getgenv().__RIPPEDWIN_SILENT_TOKEN = Silent.token
end

local useItemRemote = nil

function Silent.pick(cam)
	local camPos = cam.CFrame.Position
	local best = nil
	-- use SilentConfig.FovRadius if set; fall back to AimCfg.FOV when 0
	local silentFov = (SilentConfig.FovRadius and SilentConfig.FovRadius > 0)
		and SilentConfig.FovRadius or AimCfg.FOV
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == player then
			continue
		end
		if SilentConfig.TeamCheck then
			local okE, enemy = pcall(isEnemy, plr)
			if not okE or not enemy then
				continue
			end
		end
		local char = plr.Character
		if not char or char.Parent == nil then
			continue
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then
			continue
		end
		local dist = (camPos - root.Position).Magnitude
		if dist > SilentConfig.MaxDistance or dist < 1 then
			continue
		end
		if SilentConfig.VisibleCheck
			and not checkVisibleAim(plr, char, char:FindFirstChild("Head"), root, camPos) then
			continue
		end
		local part = resolvePartFor(char, cam, SilentConfig.HitPart)
		if not part then
			continue
		end
		-- apply velocity lead for prediction before screen-space scoring
		local leadSecs = (SilentConfig.PredictionMs or 0) / 1000
		if leadSecs > 0 then
			local vel = root.Velocity
			-- predicted world position for FOV and scoring; actual hit position used at fire time
			local predictedWorld = part.Position + vel * leadSecs
			local sp2 = cam:WorldToViewportPoint(predictedWorld)
			if sp2.Z <= 0 then
				continue
			end
			local vp = cam.ViewportSize
			local score = math.sqrt((sp2.X - vp.X/2)^2 + (sp2.Y - vp.Y/2)^2)
			if SilentConfig.UseFOV and score > silentFov then
				continue
			end
			if not best or score < best.score then
				best = { player = plr, part = part, root = root, score = score, predicted = predictedWorld }
			end
		else
			local sp = cam:WorldToViewportPoint(part.Position)
			if sp.Z <= 0 then
				continue
			end
			local vp = cam.ViewportSize
			local score = math.sqrt((sp.X - vp.X/2)^2 + (sp.Y - vp.Y/2)^2)
			if SilentConfig.UseFOV and score > silentFov then
				continue
			end
			if not best or score < best.score then
				best = { player = plr, part = part, root = root, score = score, predicted = nil }
			end
		end
	end
	return best
end

function Silent.install()
	if Silent.clickReady or not Silent.supported then
		return Silent.hooked
	end
	local okR = pcall(function()
		local plainRS = game:GetService("ReplicatedStorage")
		local remotes = plainRS:WaitForChild("Remotes", 5)
		local replication = remotes and remotes:WaitForChild("Replication", 5)
		local fighter = replication and replication:WaitForChild("Fighter", 5)
		useItemRemote = fighter and fighter:WaitForChild("UseItem", 5)
	end)
	if not useItemRemote then
		Silent.supported = false
		return false
	end
	Silent.clickReady = true
	if hasDrawing then
		Silent.fovCircle = newDrawing("Circle", {
			Thickness = 1,
			Transparency = 0.5,
			Filled = false,
			NumSides = 64,
			Visible = false,
			ZIndex = 3,
			Color = Color3.fromHex("#5795FF"),
		})
		table.insert(Silent.conns, runS.RenderStepped:Connect(function()
			local ring = Silent.fovCircle
			if not ring then
				return
			end
			if SilentConfig.Enabled and SilentConfig.UseFOV then
				local cam = workspace.CurrentCamera
				if cam then
					local vp = cam.ViewportSize
					ring.Position = Vector2.new(vp.X / 2, vp.Y / 2)
					-- use independent FovRadius when set, otherwise inherit AimCfg.FOV
					ring.Radius = (SilentConfig.FovRadius and SilentConfig.FovRadius > 0)
						and SilentConfig.FovRadius or AimCfg.FOV
					ring.Visible = true
					return
				end
			end
			ring.Visible = false
		end))
	end
	table.insert(Silent.conns, UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not SilentConfig.Enabled then
			return
		end
		if SilentConfig.Method == "Hook" and Silent.hooked then
			return
		end
		if tick() - Silent.lastClick < 0.06 then
			return
		end
		if not FighterController or not FighterController.LocalFighter then
			return
		end
		local item = FighterController.LocalFighter.EquippedItem
		if not item then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local target = Silent.pick(cam)
		if not target then
			return
		end
		Silent.lastClick = tick()
		-- fire inline (no task.spawn) so our redirected shot arrives BEFORE the game's
		-- own shot fires. task.spawn would defer past the game's InputBegan handler,
		-- causing the server to see two StartShooting in one frame and drop the second.
		pcall(function()
			local camPos = cam.CFrame.Position
			local aimPos = target.predicted or target.part.Position
			local aimCF = CFrame.lookAt(camPos, aimPos)
			local packet = {}
			packet[S_SOH] = {
				[S_NUL] = rageUtil:EncodeCFrame(aimCF),
				[S_SOH] = rageUtil:EncodeCFrame(target.part.CFrame),
				[S_STX] = target.part,
				[S_ETX] = rageUtil:EncodeCFrame(CFrame.new(0, 0, 0)),
			}
			Silent.clicks += 1
			Silent.lastName = target.player.Name
			Silent.lastAt = tick()
			if HitSounds then
				HitSounds.noteShot(target.player, target.part.Name == "Head")
			end
			useItemRemote:FireServer(
				item:Get("ObjectID"),
				rageEnum:ToEnum("StartShooting"),
				packet,
				nil
			)
		end)
	end))
	local cc = (type(newcclosure) == "function") and newcclosure or function(f)
		return f
	end
	local token = Silent.token
	local okH = (type(hookmetamethod) == "function" and type(getnamecallmethod) == "function")
		and pcall(function()
		Silent.oldNamecall = hookmetamethod(game, "__namecall", cc(function(self, ...)
			if not token.alive then
				return Silent.oldNamecall(self, ...)
			end
			local method = getnamecallmethod()
			local isUseItem = method == "FireServer"
				and typeof(self) == "Instance"
				and (self == useItemRemote
					or (self.Name == "UseItem" and self.Parent and self.Parent.Name == "Fighter"))
			if not isUseItem then
				return Silent.oldNamecall(self, ...)
			end
			if silentGuard or not SilentConfig.Enabled or SilentConfig.Method == "Click" then
				return Silent.oldNamecall(self, ...)
			end
			local args = { ... }
			local data = args[3]
			if type(data) ~= "table" or rageUtil == nil then
				return Silent.oldNamecall(self, ...)
			end
			local pkt = data[S_SOH]
			if type(pkt) ~= "table" or typeof(pkt[S_STX]) ~= "Instance" then
				return Silent.oldNamecall(self, ...)
			end
			pcall(function()
				local cam = workspace.CurrentCamera
				if not cam then
					return
				end
				local target = Silent.pick(cam)
				if not target then
					return
				end
				local origin = cam.CFrame.Position
				local aimPos = target.predicted or target.part.Position
				local aimCF = CFrame.lookAt(origin, aimPos)
				pkt[S_NUL] = rageUtil:EncodeCFrame(aimCF)
				pkt[S_SOH] = rageUtil:EncodeCFrame(target.part.CFrame)
				pkt[S_STX] = target.part
				pkt[S_ETX] = rageUtil:EncodeCFrame(CFrame.new(0, 0, 0))
				Silent.redirects += 1
				Silent.lastName = target.player.Name
				Silent.lastAt = tick()
				if HitSounds then
					HitSounds.noteShot(target.player, target.part.Name == "Head")
				end
			end)
			return Silent.oldNamecall(self, ...)
		end))
	end)
	Silent.hooked = okH
	-- if namecall hook failed (executor doesn't support it), retry once after 2 seconds
	-- in case the game's remote tree wasn't fully loaded on first attempt
	if not okH and not Silent._retried then
		Silent._retried = true
		task.delay(2, function()
			if not Silent.hooked and SilentConfig.Enabled then
				Silent.clickReady = false -- allow reinstall path to re-run
				Silent.install()
			end
		end)
	end
	return Silent.hooked
end

local Skins = {
	enabled = false,
	wanted = false,
	installed = false,
	status = "off",
}

local skinFolder = "ripped_skins"
local skinSaveFile = skinFolder .. "/config.json"
local skinsCC = (type(newcclosure) == "function") and newcclosure or function(f)
	return f
end
local skinsEquip = {}
local skinsFavs = {}
local skinsConstructing = nil
local skinsViewing = nil
local skinsLastWeapon = nil
local skinsHooksReady = false
local skinsNamecallHooked = false
local skinsLibs = nil
local skinsScheduleReplicate
local rcEnumsCache = nil
local skinsInstalling = false
local skinsReplicatePending = false
local skinsReplicateQueued = 0

local SKIP_COSMETIC = { RANDOM_COSMETIC = true, NONE = true, [""] = true }

local function getRCEnums()
	if rcEnumsCache then
		return rcEnumsCache
	end
	local ok, rc = pcall(require, repS.Modules.ReplicatedClass)
	if ok and rc then
		rcEnumsCache = {
			Data = rc:ToEnum("Data"),
			Skin = rc:ToEnum("Skin"),
			Wrap = rc:ToEnum("Wrap"),
			Charm = rc:ToEnum("Charm"),
		}
	end
	return rcEnumsCache
end

local function skinsCloneCosmetic(cosmeticName, cosmeticType, options)
	options = options or {}
	if not cosmeticName or SKIP_COSMETIC[cosmeticName] then
		return nil
	end
	local libs = skinsLibs
	if not libs or not libs.Cosmetic or not libs.Cosmetic.Cosmetics then
		return nil
	end
	local CosmeticLibrary = libs.Cosmetic
	local EnumLibrary = libs.Enum

	local resolvedName = (CosmeticLibrary.RENAMED_COSMETICS
		and CosmeticLibrary.RENAMED_COSMETICS[cosmeticName])
		or cosmeticName
	local base = CosmeticLibrary.Cosmetics[resolvedName]
	if not base then
		local lower = resolvedName:lower()
		for k, v in pairs(CosmeticLibrary.Cosmetics) do
			if tostring(k):lower() == lower then
				base = v
				resolvedName = k
				break
			end
		end
	end
	if not base and EnumLibrary then
		pcall(function()
			local enumId = EnumLibrary:ToEnum(resolvedName)
			if enumId then
				local candidate = CosmeticLibrary.Cosmetics[enumId]
				if candidate then
					base = candidate
				end
			end
		end)
	end
	if not base then
		return nil
	end

	local data = {}
	for k, v in pairs(base) do
		data[k] = v
	end
	data.Name = resolvedName
	data.Type = data.Type or cosmeticType
	data.Seed = math.random(1, 1000000)
	if EnumLibrary then
		pcall(function()
			local enumId = EnumLibrary:ToEnum(resolvedName)
			if enumId then
				data.Enum = enumId
				data.ObjectID = enumId
			end
		end)
	end
	if options.inverted then
		data.Inverted = true
	end
	if options.favoritesOnly then
		data.OnlyUseFavorites = true
	end
	return data
end

local function skinsSave()
	if type(writefile) ~= "function" then
		return
	end
	task.spawn(function()
		pcall(function()
			local config = { equipped = {}, favorites = skinsFavs }
			for weapon, cosmetics in pairs(skinsEquip) do
				config.equipped[weapon] = {}
				for cosmeticType, cd in pairs(cosmetics) do
					if cd and cd.Name then
						config.equipped[weapon][cosmeticType] = {
							name = cd.Name,
							seed = cd.Seed,
							inverted = cd.IsInverted,
						}
					end
				end
			end
			if type(isfolder) == "function" and not isfolder(skinFolder) and type(makefolder) == "function" then
				makefolder(skinFolder)
			end
			writefile(skinSaveFile, HttpService:JSONEncode(config))
		end)
	end)
end

local function skinsLoad()
	if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(skinSaveFile) then
		return
	end
	pcall(function()
		local config = HttpService:JSONDecode(readfile(skinSaveFile))
		if config.equipped then
			for weapon, cosmetics in pairs(config.equipped) do
				skinsEquip[weapon] = {}
				for cosmeticType, cd in pairs(cosmetics) do
					if cd and cd.name then
						local cloned = skinsCloneCosmetic(cd.name, cosmeticType, { inverted = cd.inverted })
						if cloned then
							cloned.Seed = cd.seed
							skinsEquip[weapon][cosmeticType] = cloned
						end
					end
				end
			end
		end
		skinsFavs = config.favorites or {}
	end)
end

skinsScheduleReplicate = function()
	if not skinsLibs or not skinsLibs.Data then
		return
	end
	skinsReplicateQueued += 1
	if skinsReplicatePending then
		return
	end
	skinsReplicatePending = true
	task.spawn(function()
		while skinsReplicateQueued > 0 do
			skinsReplicateQueued = 0
			local waited = 0
			while not skinsHooksReady and waited < 10 do
				task.wait(0.1)
				waited += 0.1
			end
			pcall(function()
				if skinsLibs.Data.CurrentData then
					skinsLibs.Data.CurrentData:Replicate("WeaponInventory")
				end
			end)
			task.wait(0.05)
		end
		skinsReplicatePending = false
		task.defer(skinsSave)
	end)
end

function Skins.setEnabled(on)
	Skins.wanted = on == true
	if Skins.wanted then
		if Skins.installed then
			Skins.enabled = true
			Skins.status = "active"
		elseif not skinsInstalling then
			skinsInstalling = true
			Skins.status = "loading"
			task.defer(function()
				skinsInstall()
				skinsInstalling = false
				if not Skins.installed then
					Skins.status = "unavailable"
					return
				end
				if Skins.wanted then
					Skins.enabled = true
				else
					Skins.status = "off"
				end
			end)
		end
	else
		Skins.enabled = false
		Skins.status = "off"
	end
end

function skinsInstall()
	if Skins.installed then
		return
	end
	Skins.status = "loading"
	if not player.Character then
		pcall(function()
			player.CharacterAdded:Wait()
		end)
		task.wait(0.5)
	end
	local libs = {}
	local unlockedCache = nil
	local ok = pcall(function()
		local ps = player:FindFirstChildOfClass("PlayerScripts")
		local controllers = ps and ps:FindFirstChild("Controllers")
		local modules = repS:FindFirstChild("Modules")
		local dataCtrl = controllers and controllers:FindFirstChild("PlayerDataController")
		libs.Cosmetic = modules and require(modules.CosmeticLibrary)
		libs.Item = modules and require(modules.ItemLibrary)
		libs.Data = dataCtrl and require(dataCtrl)
		local dataUtility = modules and modules:FindFirstChild("PlayerDataUtility")
		libs.DataUtility = dataUtility and require(dataUtility)
		local enumLib = modules and modules:FindFirstChild("EnumLibrary")
		libs.Enum = enumLib and require(enumLib)
		if libs.Enum and libs.Enum.WaitForEnumBuilder then
			task.spawn(function()
				pcall(function()
					libs.Enum:WaitForEnumBuilder()
				end)
			end)
		end
	end)
	if not ok or not libs.Cosmetic or not libs.Item or not libs.Data then
		Skins.supported = false
		Skins.status = "modules missing"
		return
	end
	skinsLibs = libs

	local localNameLower = player.Name:lower()
	local finishersFolder = repS.Modules:FindFirstChild("Finishers")

	local origOwnsAllWeapons = libs.Data.OwnsAllWeapons
	libs.Data.OwnsAllWeapons = function(...)
		if Skins.enabled then
			return true
		end
		return origOwnsAllWeapons(...)
	end
	local origGetUnlocked = libs.Data.GetUnlockedWeapons
	libs.Data.GetUnlockedWeapons = function(...)
		if Skins.enabled then
			if not unlockedCache then
				unlockedCache = {}
				if libs.Item.Items then
					for name in pairs(libs.Item.Items) do
						if not string.find(name, "MISSING_", 1, true) then
							unlockedCache[name] = true
						end
					end
				end
			end
			return unlockedCache
		end
		return origGetUnlocked(...)
	end
	for _, funcName in ipairs({ "OwnsCosmeticNormally", "OwnsCosmeticUniversally", "OwnsCosmeticForSomething", "OwnsCosmeticForWeapon" }) do
		if libs.Cosmetic[funcName] then
			local orig = libs.Cosmetic[funcName]
			libs.Cosmetic[funcName] = function(...)
				if Skins.enabled then
					return true
				end
				return orig(...)
			end
		end
	end
	if libs.Cosmetic.OwnsCosmetic then
		local origOwnsCosmetic = libs.Cosmetic.OwnsCosmetic
		libs.Cosmetic.OwnsCosmetic = function(self, inventory, name, weapon)
			if Skins.enabled and name and not string.find(name, "MISSING_", 1, true) then
				return true
			end
			return origOwnsCosmetic(self, inventory, name, weapon)
		end
	end

	local cosmeticInventoryProxy = setmetatable({}, {
		__index = function()
			return true
		end,
		__newindex = function()
		end,
	})

	local origGet = libs.Data.Get
	libs.Data.Get = function(self, key)
		if not Skins.enabled then
			return origGet(self, key)
		end
		if key == "CosmeticInventory" then
			return cosmeticInventoryProxy
		end
		local data = origGet(self, key)
		if key == "FavoritedCosmetics" then
			local result = {}
			if data then
				for k, v in pairs(data) do
					result[k] = v
				end
			end
			for weaponName, favs in pairs(skinsFavs) do
				result[weaponName] = result[weaponName] or {}
				for cosmeticType, favSet in pairs(favs) do
					result[weaponName][cosmeticType] = favSet
				end
			end
			return result
		end
		return data
	end

	local origGetWeaponData = libs.Data.GetWeaponData
	libs.Data.GetWeaponData = function(self, weaponName)
		local data = origGetWeaponData(self, weaponName)
		if not Skins.enabled then
			return data
		end
		local patched = { Unlocked = true, Level = 100, XP = 99999 }
		if data then
			for k, v in pairs(data) do
				patched[k] = v
			end
		end
		if skinsEquip[weaponName] then
			for cosmeticType, cd in pairs(skinsEquip[weaponName]) do
				patched[cosmeticType] = cd
			end
		end
		return patched
	end

	local origImage = libs.Item.GetViewModelImageFromWeaponData
	libs.Item.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
		if Skins.enabled and weaponData and weaponData.Name then
			local eq = skinsEquip[weaponData.Name]
			if eq and eq.Skin
				and ((weaponData.Skin and weaponData.Skin == eq.Skin) or skinsViewing == player) then
				local skinInfo = self.ViewModels and self.ViewModels[eq.Skin.Name]
				if skinInfo then
					return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image
				end
			end
		end
		return origImage(self, weaponData, highRes)
	end

	local okVM = pcall(function()
		local ps = player:FindFirstChildOfClass("PlayerScripts")
		local modules = ps and ps:WaitForChild("Modules", 10)
		local rcc = modules and modules:WaitForChild("ClientReplicatedClasses", 10)
		local ClientItem = rcc and require(rcc.ClientFighter.ClientItem)
		local ClientEntity = rcc and require(rcc.ClientEntity)
		local vmMod = rcc and rcc.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
		local ViewProfile = modules and modules:WaitForChild("Pages") and modules.Pages:FindFirstChild("ViewProfile")

		if ViewProfile and ViewProfile.Fetch then
			local origFetch = ViewProfile.Fetch
			ViewProfile.Fetch = function(self, targetPlayer)
				skinsViewing = targetPlayer
				return origFetch(self, targetPlayer)
			end
		end

		if ClientItem and ClientItem._CreateViewModel then
			local origCreateVM = ClientItem._CreateViewModel
			ClientItem._CreateViewModel = function(self, viewmodelRef)
				local weaponName = self.Name
				local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
				skinsConstructing = (Skins.enabled and weaponPlayer == player) and weaponName or nil
				if Skins.enabled and weaponPlayer == player and weaponName
					and skinsEquip[weaponName] and skinsEquip[weaponName].Skin and viewmodelRef then
					pcall(function()
						local dataKey = self:ToEnum("Data")
						local skinKey = self:ToEnum("Skin")
						local nameKey = self:ToEnum("Name")
						if viewmodelRef[dataKey] then
							viewmodelRef[dataKey][skinKey] = skinsEquip[weaponName].Skin
							viewmodelRef[dataKey][nameKey] = skinsEquip[weaponName].Skin.Name
						elseif viewmodelRef.Data then
							viewmodelRef.Data.Skin = skinsEquip[weaponName].Skin
							viewmodelRef.Data.Name = skinsEquip[weaponName].Skin.Name
						end
					end)
				end
				local result = origCreateVM(self, viewmodelRef)
				skinsConstructing = nil
				return result
			end
		end

		if vmMod then
			local ClientViewModel = require(vmMod)
			if ClientViewModel.GetWrap then
				local origGetWrap = ClientViewModel.GetWrap
				ClientViewModel.GetWrap = function(self)
					if Skins.enabled and self.ClientItem then
						local weaponName = self.ClientItem.Name
						local weaponPlayer = self.ClientItem.ClientFighter
							and self.ClientItem.ClientFighter.Player
						if weaponName and weaponPlayer == player
							and skinsEquip[weaponName] and skinsEquip[weaponName].Wrap then
							return skinsEquip[weaponName].Wrap
						end
					end
					return origGetWrap(self)
				end
			end
			local origNew = ClientViewModel.new
			ClientViewModel.new = function(replicatedData, clientItem)
				local weaponPlayer = clientItem and clientItem.ClientFighter and clientItem.ClientFighter.Player
				local weaponName = skinsConstructing or (clientItem and clientItem.Name)
				if Skins.enabled and weaponPlayer == player and weaponName and skinsEquip[weaponName] then
					pcall(function()
						local enums = getRCEnums()
						if not enums then
							return
						end
						replicatedData[enums.Data] = replicatedData[enums.Data] or {}
						local cosmetics = skinsEquip[weaponName]
						if cosmetics.Skin then
							replicatedData[enums.Data][enums.Skin] = cosmetics.Skin
						end
						if cosmetics.Wrap then
							replicatedData[enums.Data][enums.Wrap] = cosmetics.Wrap
						end
						if cosmetics.Charm then
							replicatedData[enums.Data][enums.Charm] = cosmetics.Charm
						end
					end)
				end
				local result = origNew(replicatedData, clientItem)
				if Skins.enabled and result and weaponPlayer == player and weaponName
					and skinsEquip[weaponName] and skinsEquip[weaponName].Wrap and result._UpdateWrap then
					task.spawn(function()
						pcall(function()
							result:_UpdateWrap()
						end)
						task.wait(0.1)
						if not result._destroyed then
							pcall(function()
								result:_UpdateWrap()
							end)
						end
					end)
				end
				return result
			end
		end

		if ClientEntity and ClientEntity._PlayFinisher and finishersFolder then
			local origFinisher = ClientEntity._PlayFinisher
			ClientEntity._PlayFinisher = function(self, finisherName, isFinal, eliminator, serial)
				if Skins.enabled then
					local isOurKill = false
					if eliminator == player then
						isOurKill = true
					elseif type(eliminator) == "string" then
						isOurKill = eliminator == player.Name or eliminator:lower() == localNameLower
					elseif typeof(eliminator) == "userdata" and libs.Enum then
						pcall(function()
							local decoded = libs.Enum:FromEnum(eliminator)
							if decoded then
								local ds = tostring(decoded)
								isOurKill = ds == player.Name or ds:lower() == localNameLower
							end
						end)
					end
					if isOurKill then
						local weaponToUse = skinsLastWeapon
						if not (weaponToUse and skinsEquip[weaponToUse] and skinsEquip[weaponToUse].Finisher) then
							for wName, cosmetics in pairs(skinsEquip) do
								if cosmetics.Finisher then
									weaponToUse = wName
									break
								end
							end
						end
						if weaponToUse and skinsEquip[weaponToUse] and skinsEquip[weaponToUse].Finisher then
							local override = skinsEquip[weaponToUse].Finisher.Name
							if finishersFolder:FindFirstChild(override) then
								finisherName = override
							end
						end
					end
				end
				return origFinisher(self, finisherName, isFinal, eliminator, serial)
			end
		end
	end)

	pcall(function()
		local plainRS = game:GetService("ReplicatedStorage")
		local remotes = plainRS:WaitForChild("Remotes", 15)
		local dataRemotes = remotes and remotes:WaitForChild("Data", 10)
		local equipRemote = dataRemotes and dataRemotes:WaitForChild("EquipCosmetic", 10)
		local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
		local replication = remotes and remotes:WaitForChild("Replication", 10)
		local fighter = replication and replication:WaitForChild("Fighter", 10)
		local useItemRemote = fighter and fighter:FindFirstChild("UseItem")
		if not (equipRemote and hookmetamethod and getnamecallmethod) then
			return
		end
		local old
		local okHook = pcall(function()
			old = hookmetamethod(game, "__namecall", skinsCC(function(self, ...)
				if getnamecallmethod() ~= "FireServer" then
					return old(self, ...)
				end
				if self == equipRemote then
					if Skins.enabled then
						local weaponName, cosmeticType, cosmeticName, options = ...
						options = options or {}
						if not SKIP_COSMETIC[cosmeticName] then
							skinsEquip[weaponName] = skinsEquip[weaponName] or {}
							local handled = true
							if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
								skinsEquip[weaponName][cosmeticType] = nil
								if not next(skinsEquip[weaponName]) then
									skinsEquip[weaponName] = nil
								end
							else
								local cloned = skinsCloneCosmetic(cosmeticName, cosmeticType, {
									inverted = options.IsInverted,
									favoritesOnly = options.OnlyUseFavorites,
								})
								if cloned then
									skinsEquip[weaponName][cosmeticType] = cloned
								else
									handled = false
								end
							end
							if handled then
								skinsScheduleReplicate()
								return
							end
						end
					end
					return old(self, ...)
				end
				if favoriteRemote and self == favoriteRemote and Skins.enabled then
					local a1, a2, a3 = ...
					skinsFavs[a1] = skinsFavs[a1] or {}
					skinsFavs[a1][a2] = a3 or nil
					skinsSave()
					return
				end
				if useItemRemote and self == useItemRemote and Skins.enabled and FighterController then
					local itemObjectID = ...
					task.spawn(function()
						pcall(function()
							local fighter = FighterController:GetFighter(player)
							if fighter and fighter.Items then
								for _, item in pairs(fighter.Items) do
									if item:Get("ObjectID") == itemObjectID then
										skinsLastWeapon = item.Name
										break
									end
								end
							end
						end)
					end)
				end
				return old(self, ...)
			end))
		end)
		skinsNamecallHooked = okHook
		skinsHooksReady = okHook
	end)

	if type(getgc) == "function" and type(hookfunction) == "function"
		and type(checkcaller) == "function" and type(debug) == "table" and debug.info then
		task.spawn(function()
			pcall(function()
				local funcs = getgc()
				local n = #funcs
				local i = 0
				while i < n do
					local j = math.min(i + 500, n)
					for k = i + 1, j do
						local v = funcs[k]
						if typeof(v) == "function" then
							local src = debug.info(v, "s")
							if src and string.find(src, "AnalyticsPipelineController") then
								local orig = hookfunction(v, skinsCC(function(...)
									if not Skins.enabled or checkcaller() then
										return orig(...)
									end
									return nil
								end))
							end
						end
					end
					i = j
					task.wait(0.05)
				end
			end)
		end)
	end

	skinsLoad()
	Skins.installed = true
	skinsHooksReady = true
	pcall(function()
		if skinsLibs and skinsLibs.Data and skinsLibs.Data.CurrentData then
			skinsLibs.Data.CurrentData:Replicate("WeaponInventory")
		end
	end)
	Skins.status = skinsNamecallHooked and "active" or "partial (no namecall hook)"
end

local SoundService = game:GetService("SoundService")
local HIT_SOUNDS = {
	["Rust Headshot"] = "rbxassetid://138750331387064",
	["Neverlose"] = "rbxassetid://110168723447153",
	["Bubble"] = "rbxassetid://6534947588",
	["Laser"] = "rbxassetid://7837461331",
	["Steve"] = "rbxassetid://4965083997",
	["Call of Duty"] = "rbxassetid://5952120301",
	["Bat"] = "rbxassetid://3333907347",
	["TF2 Critical"] = "rbxassetid://296102734",
	["Saber"] = "rbxassetid://8415678813",
	["Bameware"] = "rbxassetid://3124331820",
	["Money"] = "rbxassetid://13956013041",
	["Notif"] = "rbxassetid://6696469190",
	["Shutter"] = "rbxassetid://10066921516",
	["RIFK7"] = "rbxassetid://9102080552",
}
local HIT_SOUND_NAMES = {
	"Rust Headshot", "Neverlose", "Bubble", "Laser", "Steve",
	"Call of Duty", "Bat", "TF2 Critical", "Saber", "Bameware",
	"Money", "Notif", "Shutter", "RIFK7",
}

HitSounds = {
	running = false,
	conns = {},
}

local hitShots = {}
local hitLastHealth = {}
local hitLastPlayed = 0

function HitSounds.noteShot(plr, head)
	if plr then
		hitShots[plr] = { at = tick(), head = head and true or false }
	end
end

function HitSounds.play(name, volume)
	if not HitSoundCfg.HitEnabled then
		return
	end
	local now = tick()
	if now - hitLastPlayed < 0.05 then
		return
	end
	hitLastPlayed = now
	local id = HIT_SOUNDS[name or HitSoundCfg.HitSound] or HIT_SOUNDS.Neverlose
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = id
			s.Volume = math.clamp((volume or HitSoundCfg.HitVolume) / 100, 0, 2)
			s.Parent = SoundService
			s:Play()
			task.delay(5, function()
				if s.Parent and not s.IsPlaying then
					s:Destroy()
				end
			end)
		end)
	end)
end

function HitSounds.start()
	if HitSounds.running then
		return
	end
	HitSounds.running = true
	table.insert(HitSounds.conns, runS.Heartbeat:Connect(function()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize
		local camPos = cam and cam.CFrame.Position
		local now = tick()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and char.Parent then
					local last = hitLastHealth[plr]
					local hp = hum.Health
					if last and hp < last - 0.01 then
						local attributed = false
						local shot = hitShots[plr]
						if shot and now - shot.at < 2.5 then
							attributed = true
						end
						if not attributed and Aim and Aim.sticky and Aim.sticky.player == plr then
							attributed = true
						end
						if not attributed and camPos and vp then
							local root = char:FindFirstChild("HumanoidRootPart")
							if root then
								local sp = cam:WorldToViewportPoint(root.Position)
								if sp.Z > 0 then
									local cd = math.sqrt((sp.X - vp.X / 2) ^ 2 + (sp.Y - vp.Y / 2) ^ 2)
									if cd <= 140 then
										attributed = true
									end
								end
							end
						end
						if attributed then
							HitSounds.play()
						end
					end
					hitLastHealth[plr] = hp
				else
					hitLastHealth[plr] = nil
				end
			end
		end
	end))
	table.insert(HitSounds.conns, Players.PlayerRemoving:Connect(function(plr)
		hitShots[plr] = nil
		hitLastHealth[plr] = nil
	end))
end

ConfigManager.autoload()
ConfigManager.startAutosaveLoop()

gui = new("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = guiParent,
})
connect(gui.Destroying, destroy)

local winW, winH = 760, 500
local window = new("Frame", {
	Name = "Window",
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
	Size = UDim2.fromOffset(winW, winH),
	Parent = gui,
})
corner(window, 10)
stroke(window, C.line, 1, 0)
local header = new("Frame", {
	Name = "Header",
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	Active = true,
	Size = UDim2.new(1, 0, 0, HEADER_H),
	Parent = window,
})
hLine(header, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1))

local brandCell = new("Frame", {
	Name = "Brand",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 152, 1, -1),
	Parent = header,
})
hLine(brandCell, UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0))

local brandRow = new("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.new(0, 0, 0, 0),
	Parent = brandCell,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}),
})

local logoTile = new("Frame", {
	Name = "LogoTile",
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(32, 28),
	LayoutOrder = 1,
	Parent = brandRow,
})
corner(logoTile, 6)
local logoGlow = stroke(logoTile, C.blue, 1.5, 0.35)

local logoImage = new("ImageLabel", {
	Name = "Logo",
	BackgroundTransparency = 1,
	Image = LOGO_ASSET,
	ImageTransparency = REDUCED_MOTION and 0 or 1,
	ScaleType = Enum.ScaleType.Fit,
	Size = UDim2.fromScale(1, 1),
	Parent = logoTile,
})

local logoFallback = new("TextLabel", {
	Name = "LogoFallback",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBlack,
	Text = "R",
	TextSize = 18,
	TextColor3 = C.text,
	Visible = false,
	Parent = logoTile,
})
connect(logoImage:GetPropertyChangedSignal("IsLoaded"), function()
	logoFallback.Visible = not logoImage.IsLoaded
end)
task.defer(function()
	if logoImage.Parent then
		logoFallback.Visible = not logoImage.IsLoaded
	end
end)

local textHolder = new("Frame", {
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.new(0, 0, 0, 28),
	LayoutOrder = 2,
	Parent = brandRow,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function brandLabel(text, order)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextSize = 17,
		TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		Parent = textHolder,
	})
end

local ripLabel = brandLabel("ripped", 1)
local winLabel = brandLabel(".win", 2)
winLabel.TextColor3 = Color3.new(1, 1, 1)
local sweepGradient = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.blue),
		ColorSequenceKeypoint.new(0.42, C.blue),
		ColorSequenceKeypoint.new(0.5, C.sweep),
		ColorSequenceKeypoint.new(0.58, C.blue),
		ColorSequenceKeypoint.new(1, C.blue),
	}),
	Parent = winLabel,
})

local underline = new("Frame", {
	BackgroundColor3 = C.blue,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 1, 2),
	Size = REDUCED_MOTION and UDim2.new(1, 0, 0, 2) or UDim2.new(0, 0, 0, 2),
	Parent = ripLabel,
})
corner(underline, 1)

local body = new("Frame", {
	Name = "Body",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, HEADER_H),
	Size = UDim2.new(1, 0, 1, -(HEADER_H + FOOTER_H)),
	Parent = window,
})

local sidebar = new("Frame", {
	Name = "Sidebar",
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 152, 1, 0),
	Parent = body,
})
hLine(sidebar, UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0))

local navList = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -1, 1, 0),
	Parent = sidebar,
}, {
	new("UIPadding", {
		PaddingTop = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}),
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}),
})

local marker = new("Frame", {
	Name = "Marker",
	BackgroundColor3 = C.blueHi,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(3, 24),
	Visible = false,
	Parent = sidebar,
})
corner(marker, 2)

local main = new("Frame", {
	Name = "Main",
	BackgroundColor3 = C.black,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Position = UDim2.fromOffset(152, 0),
	Size = UDim2.new(1, -152, 1, 0),
	Parent = body,
})

local scroller = new("ScrollingFrame", {
	Name = "Scroller",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = C.scroll,
	Parent = main,
}, {
	new("UIPadding", {
		PaddingTop = UDim.new(0, PAD),
		PaddingBottom = UDim.new(0, PAD),
		PaddingLeft = UDim.new(0, PAD),
		PaddingRight = UDim.new(0, PAD),
	}),
})

local fade = new("Frame", {
	Name = "SectionFade",
	BackgroundColor3 = C.black,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 10,
	Parent = main,
})

local footer = new("Frame", {
	Name = "Footer",
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 1, -FOOTER_H),
	Size = UDim2.new(1, 0, 0, FOOTER_H),
	Parent = window,
})
hLine(footer, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 1))

local cards = {}

local function buildCard(parent, order, title)
	local card = new("Frame", {
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(0.5, -GAP / 2, 0, 340),
		LayoutOrder = order,
		Parent = parent,
	})
	corner(card, 5)
	stroke(card, C.line, 1, 0)

	new("Frame", {
		BackgroundColor3 = C.blue,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, CARD_TOP),
		Parent = card,
	})

	local head = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, CARD_TOP),
		Size = UDim2.new(1, 0, 0, CARD_HEAD),
		Parent = card,
	})
	hLine(head, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1))
	local chevron = makeIcon(head, { { t = "line", pts = { 6, 9, 12, 15, 18, 9 } } }, 16, 1.8)
	chevron.root.AnchorPoint = Vector2.new(0.5, 0.5)
	chevron.root.Position = UDim2.new(1, -20, 0.5, 0)

	if title and title ~= "" then
		new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = title,
			TextSize = 12,
			TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = head,
		})
	end

	local well = new("Frame", {
		BackgroundColor3 = C.black,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(WELL_M, CARD_TOP + CARD_HEAD + WELL_M),
		Size = UDim2.new(1, -WELL_M * 2, 0, MIN_WELL),
		Parent = card,
	})
	corner(well, 3)
	stroke(well, C.line, 1, 0)

	local entry = { frame = card, well = well, closed = false, fullH = 340 }
	table.insert(cards, entry)

	connect(head.MouseEnter, function()
		chevron.setColor(C.text)
	end)
	connect(head.MouseLeave, function()
		chevron.setColor(C.text2)
	end)
	connect(head.Activated, function()
		entry.closed = not entry.closed
		tween(chevron.root, 0.22, { Rotation = entry.closed and -90 or 0 })
		tween(card, 0.22, {
			Size = UDim2.new(0.5, -GAP / 2, 0, entry.closed and (CARD_TOP + CARD_HEAD) or entry.fullH),
		})
	end)

	return entry
end

local function setCardHeights()
	local avail = scroller.AbsoluteSize.Y - PAD * 2
	local minCard = CARD_TOP + CARD_HEAD + WELL_M * 2 + MIN_WELL
	local h = math.max(minCard, math.floor((avail - GAP) / 2))
	for _, c in ipairs(cards) do
		c.fullH = h
		c.well.Size = UDim2.new(1, -WELL_M * 2, 0, h - CARD_TOP - CARD_HEAD - WELL_M * 2)
		if not c.closed then
			c.frame.Size = UDim2.new(0.5, -GAP / 2, 0, h)
		end
	end
end

local function pointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function prepWell(well)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = well,
	})
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = well,
	})
end

local function addToggle(well, order, text, default, callback, bindKey)
	local row = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = order,
		Parent = well,
	})
	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -44, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 12,
		TextColor3 = default and C.text or C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local pill = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = default and C.blue or C.panel2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(34, 18),
		Parent = row,
	})
	corner(pill, 9)
	local knob = new("Frame", {
		BackgroundColor3 = default and C.black or C.text2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(default and 0.7 or 0.3, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		Parent = pill,
	})
	corner(knob, 6)
	local on = default
	local function paint()
		tween(pill, 0.15, { BackgroundColor3 = on and C.blue or C.panel2 })
		tween(knob, 0.15, {
			Position = UDim2.new(on and 0.7 or 0.3, 0, 0.5, 0),
			BackgroundColor3 = on and C.black or C.text2,
		})
		tween(label, 0.15, { TextColor3 = on and C.text or C.text2 })
	end
	connect(pill.Activated, function()
		on = not on
		paint()
		callback(on)
		ConfigManager.markDirty()
	end)
	local widget = {
		get = function()
			return on
		end,
		set = function(v)
			if v ~= on then
				on = v
				paint()
			end
		end,
	}
	if bindKey then
		ConfigManager.registerWidget(bindKey, widget)
	end
	return widget
end

local function addSlider(well, order, text, minV, maxV, default, decimals, callback, bindKey)
	local row = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = order,
		Parent = well,
	})
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.6, 0, 0, 14),
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 12,
		TextColor3 = C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local val = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.4, 0, 0, 14),
		Font = Enum.Font.GothamMedium,
		Text = string.format("%." .. decimals .. "f", default),
		TextSize = 12,
		TextColor3 = C.blueHi,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	local track = new("Frame", {
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 24),
		Size = UDim2.new(1, 0, 0, 4),
		Parent = row,
	})
	corner(track, 2)
	local fill = new("Frame", {
		BackgroundColor3 = C.blue,
		BorderSizePixel = 0,
		Size = UDim2.fromScale((default - minV) / (maxV - minV), 1),
		Parent = track,
	})
	corner(fill, 2)
	local knob = new("Frame", {
		BackgroundColor3 = C.blueHi,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((default - minV) / (maxV - minV), 0, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		ZIndex = 2,
		Parent = track,
	})
	corner(knob, 5)

	local value = default
	local dragging = false
	local function paint(v)
		local rel = (v - minV) / (maxV - minV)
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		val.Text = string.format("%." .. decimals .. "f", v)
	end
	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		value = minV + (maxV - minV) * rel
		local step = 10 ^ -decimals
		value = math.floor(value / step + 0.5) * step
		paint(value)
		callback(value)
		ConfigManager.markDirty()
	end
	connect(track.InputBegan, function(input)
		if pointer(input) then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if pointer(input) then
			dragging = false
		end
	end)
	local widget = {
		get = function()
			return value
		end,
		set = function(v)
			value = math.clamp(v, minV, maxV)
			paint(value)
		end,
	}
	if bindKey then
		ConfigManager.registerWidget(bindKey, widget)
	end
	return widget
end

local function addSegmented(well, order, text, options, default, callback, bindKey)
	local current = default
	local row = new("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = order,
		Parent = well,
	}, {
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 12,
		TextColor3 = C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = row,
	})
	local chips = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 2,
		Parent = row,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	})
	local buttons = {}
	for i, opt in ipairs(options) do
		local selected = opt.value == current
		local chip = new("TextButton", {
			Text = opt.label,
			AutoButtonColor = false,
			BackgroundColor3 = C.blue,
			BackgroundTransparency = selected and 0.85 or 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = selected and C.blueHi or C.text2,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = i,
			Parent = chips,
		}, {
			new("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
		})
		corner(chip, 4)
		local chipStroke = stroke(chip, C.blue, 1, selected and 0.6 or 1)
		table.insert(buttons, { btn = chip, st = chipStroke, value = opt.value })
		connect(chip.Activated, function()
			current = opt.value
			for _, b in ipairs(buttons) do
				local sel = b.value == current
				tween(b.btn, 0.15, {
					BackgroundTransparency = sel and 0.85 or 1,
					TextColor3 = sel and C.blueHi or C.text2,
				})
				tween(b.st, 0.15, { Transparency = sel and 0.6 or 1 })
			end
			callback(current)
			ConfigManager.markDirty()
		end)
	end
	local widget = {
		get = function()
			return current
		end,
		set = function(v)
			current = v
			for _, b in ipairs(buttons) do
				local sel = b.value == current
				b.btn.BackgroundTransparency = sel and 0.85 or 1
				b.btn.TextColor3 = sel and C.blueHi or C.text2
				b.st.Transparency = sel and 0.6 or 1
			end
		end,
	}
	if bindKey then
		ConfigManager.registerWidget(bindKey, widget)
	end
	return widget
end

local function addKeybind(well, order, text, defaultKey, changed, bindKey)
	local row = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
		Parent = well,
	})
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -96, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 12,
		TextColor3 = C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local btn = new("TextButton", {
		Text = defaultKey and defaultKey.Name or "—",
		AutoButtonColor = false,
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(84, 20),
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = C.text,
		Parent = row,
	})
	corner(btn, 4)
	local btnStroke = stroke(btn, C.blue, 1, 1)
	local listening = false
	local function stopListen()
		listening = false
		btn.Text = defaultKey and defaultKey.Name or "—"
		btnStroke.Transparency = 1
		tween(btn, 0.15, { BackgroundColor3 = C.panel2, TextColor3 = C.text })
	end
	connect(btn.Activated, function()
		if listening then
			stopListen()
			return
		end
		listening = true
		btn.Text = "press a key"
		btnStroke.Transparency = 0.2
		tween(btn, 0.15, { BackgroundColor3 = C.blue, TextColor3 = C.text })
	end)
	connect(UserInputService.InputBegan, function(input, processed)
		if not listening or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Unknown or kc == Enum.KeyCode.Escape then
				return
			end
			defaultKey = kc
			stopListen()
			changed(kc, false)
			ConfigManager.markDirty()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3
			or input.UserInputType == Enum.UserInputType.MouseButton4 then
			defaultKey = input.UserInputType
			stopListen()
			changed(input.UserInputType, true)
			ConfigManager.markDirty()
		end
	end)
end

local function addDropdown(well, order, text, options, default, callback, bindKey)
	local current = default
	local row = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
		Parent = well,
	})
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -124, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 12,
		TextColor3 = C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local btn = new("TextButton", {
		Text = tostring(current),
		AutoButtonColor = false,
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.fromOffset(110, 20),
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = C.text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	corner(btn, 4)
	stroke(btn, C.line, 1, 0)
	local list = new("Frame", {
		BackgroundTransparency = 1,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = order + 1,
		Parent = well,
	})
	local scroll = new("ScrollingFrame", {
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 96),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.scroll,
		Parent = list,
	})
	corner(scroll, 4)
	stroke(scroll, C.line, 1, 0)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = scroll,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = scroll,
	})
	local optButtons = {}
	local function paint()
		for _, ob in ipairs(optButtons) do
			ob.TextColor3 = ob.Text == tostring(current) and C.blueHi or C.text2
		end
	end
	for i, opt in ipairs(options) do
		local ob = new("TextButton", {
			Text = tostring(opt),
			AutoButtonColor = false,
			BackgroundColor3 = C.panel2,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = C.text2,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = i,
			Parent = scroll,
		})
		corner(ob, 3)
		table.insert(optButtons, ob)
		connect(ob.Activated, function()
			current = opt
			btn.Text = tostring(opt)
			paint()
			list.Visible = false
			callback(opt)
			ConfigManager.markDirty()
		end)
	end
	paint()
	connect(btn.Activated, function()
		list.Visible = not list.Visible
	end)
	local widget = {
		get = function()
			return current
		end,
		set = function(v)
			current = v
			btn.Text = tostring(v)
			paint()
		end,
	}
	if bindKey then
		ConfigManager.registerWidget(bindKey, widget)
	end
	return widget
end

local function addButton(well, order, text, cb)
	local btn = new("TextButton", {
		Text = text,
		AutoButtonColor = false,
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.text,
		Parent = well,
	})
	corner(btn, 4)
	local bs = stroke(btn, C.blue, 1, 1)
	connect(btn.MouseEnter, function()
		tween(bs, 0.15, { Transparency = 0.4 })
	end)
	connect(btn.MouseLeave, function()
		tween(bs, 0.15, { Transparency = 1 })
	end)
	connect(btn.Activated, cb)
	return btn
end

local function addNote(well, order, text)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		Text = text,
		TextSize = 11,
		TextColor3 = C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = order,
		Parent = well,
	})
end

local CARD_SPECS = {
	rage = {
		{ title = "Combat", build = function(entry)
			prepWell(entry.well)
			addToggle(entry.well, 1, "Enabled", Config.Enabled, function(v)
				Config.Enabled = v
			end, "rage.Enabled")
			addSlider(entry.well, 2, "Fire rate", 0, 0.01, Config.FireRate, 4, function(v)
				Config.FireRate = v
			end, "rage.FireRate")
			addSlider(entry.well, 3, "Range", 50, 1000, Config.Range, 0, function(v)
				Config.Range = math.floor(v)
			end, "rage.Range")
			addToggle(entry.well, 4, "Visible check", Config.VisibleCheck, function(v)
				Config.VisibleCheck = v
			end, "rage.VisibleCheck")
			addToggle(entry.well, 5, "FOV gate", Config.UseFOV, function(v)
				Config.UseFOV = v
			end, "rage.UseFOV")
			addToggle(entry.well, 6, "Auto lead (ping)", Config.AutoLead, function(v)
				Config.AutoLead = v
			end, "rage.AutoLead")
			if not Ragebot.loaded then
				addNote(entry.well, 7, "game modules not found — controls inert in this game")
			end
		end },
		{ title = "Desync", build = function(entry)
			prepWell(entry.well)
			addToggle(entry.well, 1, "Desync", Config.Desync, function(v)
				Config.Desync = v
			end, "rage.Desync")
			addToggle(entry.well, 2, "Desync jitter", Config.DesyncJitter, function(v)
				Config.DesyncJitter = v
			end, "rage.DesyncJitter")
			addNote(entry.well, 3, "Offsets the root one frame before firing, restores it on the next render step. Jitter cycles 5 offset positions to widen anti-aim angle coverage.")
		end },
		{ title = "Equipment", build = function(entry)
			prepWell(entry.well)
			addToggle(entry.well, 1, "Auto equip", Config.AutoEquip, function(v)
				Config.AutoEquip = v
			end, "rage.AutoEquip")
			addToggle(entry.well, 2, "Require equipped", Config.RequireEquipped, function(v)
				Config.RequireEquipped = v
			end, "rage.RequireEquipped")
			addSegmented(entry.well, 3, "Weapon slot", {
				{ label = "Primary", value = "Primary" },
				{ label = "Secondary", value = "Secondary" },
				{ label = "Melee", value = "Melee" },
			}, Config.WeaponSlot, function(v)
				Config.WeaponSlot = v
				Ragebot.equip()
			end, "rage.WeaponSlot")
			local eqStatus = new("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = "equipped: —",
				TextSize = 11,
				TextColor3 = C.text2,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 4,
				Parent = entry.well,
			})
			task.spawn(function()
				local painted = "\1"
				while not destroyed do
					local n = Ragebot.loaded and (Ragebot.getEquippedName() or "none") or "n/a"
					if n ~= painted then
						painted = n
						pcall(function()
							eqStatus.Text = "equipped: " .. n
							eqStatus.TextColor3 = n ~= "none" and n ~= "n/a" and C.blueHi or C.text2
						end)
					end
					task.wait(0.15)
				end
			end)
		end },
		{ title = "Targeting", build = function(entry)
			prepWell(entry.well)
			addSegmented(entry.well, 1, "Hit part", {
				{ label = "Head", value = "Head" },
				{ label = "Torso", value = "Torso" },
				{ label = "Root", value = "Root" },
			}, Config.HitPart, function(v)
				Config.HitPart = v
			end, "rage.HitPart")
			addSlider(entry.well, 3, "Spread", 0, 0.5, Config.Spread or 0, 2, function(v)
				Config.Spread = v
			end, "rage.Spread")
			addSlider(entry.well, 4, "Lead (ms)", 0, 300, (Config.Lead or 0) * 1000, 0, function(v)
				Config.Lead = v / 1000
			end, "rage.Lead")
			local status = new("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = "target: none",
				TextSize = 11,
				TextColor3 = C.text2,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
				Parent = entry.well,
			})
			task.spawn(function()
				local painted = nil
				while not destroyed do
					local t = Ragebot._target
					if t ~= painted then
						painted = t
						pcall(function()
							status.Text = "target: " .. tostring(t)
							status.TextColor3 = t ~= "none" and C.blueHi or C.text2
						end)
					end
					task.wait(0.15)
				end
			end)
		end },
	},
}

CARD_SPECS.esp = {
	{ title = "Players", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 1, "ESP enabled", ESPConfig.Enabled, function(v)
			ESPConfig.Enabled = v
			Esp.setEnabled(v)
		end, "esp.Enabled")
		addToggle(entry.well, 2, "Team check", ESPConfig.TeamCheck, function(v)
			ESPConfig.TeamCheck = v
		end, "esp.TeamCheck")
		addToggle(entry.well, 3, "Visible check", ESPConfig.VisibleCheck, function(v)
			ESPConfig.VisibleCheck = v
		end, "esp.VisibleCheck")
		addSlider(entry.well, 4, "Max distance", 25, 2000, ESPConfig.MaxDistance, 0, function(v)
			ESPConfig.MaxDistance = math.floor(v)
		end, "esp.MaxDistance")
	end },
	{ title = "Boxes", build = function(entry)
		prepWell(entry.well)
		addSegmented(entry.well, 1, "Box style", {
			{ label = "Off", value = "Off" },
			{ label = "Corner", value = "Corner" },
			{ label = "Full", value = "Full" },
		}, ESPConfig.BoxStyle, function(v)
			ESPConfig.BoxStyle = v
		end, "esp.BoxStyle")
		addToggle(entry.well, 2, "Box fill", ESPConfig.BoxFill, function(v)
			ESPConfig.BoxFill = v
		end, "esp.BoxFill")
		addToggle(entry.well, 3, "Skeleton", ESPConfig.Skeleton, function(v)
			ESPConfig.Skeleton = v
		end, "esp.Skeleton")
		addToggle(entry.well, 4, "Head dot", ESPConfig.HeadDot, function(v)
			ESPConfig.HeadDot = v
		end, "esp.HeadDot")
		if not hasDrawing then
			addNote(entry.well, 5, "Drawing API not found in this executor — box/skeleton/text can't render. Chams still work.")
		end
	end },
	{ title = "Info", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 1, "Names", ESPConfig.Name, function(v)
			ESPConfig.Name = v
		end, "esp.Name")
		addToggle(entry.well, 2, "Health bar", ESPConfig.HealthBar, function(v)
			ESPConfig.HealthBar = v
		end, "esp.HealthBar")
		addToggle(entry.well, 3, "Health number", ESPConfig.HealthNumber, function(v)
			ESPConfig.HealthNumber = v
		end, "esp.HealthNumber")
		addToggle(entry.well, 4, "Distance", ESPConfig.DistanceText, function(v)
			ESPConfig.DistanceText = v
		end, "esp.DistanceText")
		addToggle(entry.well, 5, "Weapon", ESPConfig.WeaponText, function(v)
			ESPConfig.WeaponText = v
		end, "esp.WeaponText")
	end },
	{ title = "Tracers", build = function(entry)
		prepWell(entry.well)
		addSegmented(entry.well, 1, "Tracer origin", {
			{ label = "Off", value = "Off" },
			{ label = "Bottom", value = "Bottom" },
			{ label = "Center", value = "Center" },
			{ label = "Top", value = "Top" },
		}, ESPConfig.Tracer, function(v)
			ESPConfig.Tracer = v
		end, "esp.Tracer")
		addToggle(entry.well, 2, "Chams", ESPConfig.Chams, function(v)
			ESPConfig.Chams = v
		end, "esp.Chams")
		addToggle(entry.well, 3, "Chams through walls", ESPConfig.ChamsThroughWalls, function(v)
			ESPConfig.ChamsThroughWalls = v
		end, "esp.ChamsThroughWalls")
	end },
}

CARD_SPECS.legit = {
	{ title = "Aimbot", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 1, "Aimbot enabled", AimCfg.Enabled, function(v)
			AimCfg.Enabled = v
			Aim.setEnabled(v)
		end, "aim.Enabled")
		addSegmented(entry.well, 2, "Activation", {
			{ label = "Always", value = "Always" },
			{ label = "Hold", value = "Hold" },
			{ label = "Toggle", value = "Toggle" },
		}, AimCfg.Activation, function(v)
			AimCfg.Activation = v
			Aim.toggled = false
		end, "aim.Activation")
		addSegmented(entry.well, 3, "Method", {
			{ label = "Mouse", value = "Mouse" },
			{ label = "Camera", value = "Camera" },
		}, AimCfg.Method, function(v)
			AimCfg.Method = v
		end, "aim.Method")
		addKeybind(entry.well, 4, "Aim key", AimCfg.Key, function(key, isMouse)
			AimCfg.Key = key
			AimCfg.KeyType = isMouse and "Mouse" or "Keyboard"
		end, "aim.Key")
	end },
	{ title = "Targeting", build = function(entry)
		prepWell(entry.well)
		addSegmented(entry.well, 1, "Hit part", {
			{ label = "Head", value = "Head" },
			{ label = "Torso", value = "Torso" },
			{ label = "Nearest", value = "Nearest" },
		}, AimCfg.HitPart, function(v)
			AimCfg.HitPart = v
			Aim.sticky = nil
		end, "aim.HitPart")
		addSegmented(entry.well, 2, "Pick by", {
			{ label = "Crosshair", value = "Crosshair" },
			{ label = "Distance", value = "Distance" },
			{ label = "Health", value = "Health" },
		}, AimCfg.Selection, function(v)
			AimCfg.Selection = v
		end, "aim.Selection")
		addToggle(entry.well, 3, "Auto switch", AimCfg.AutoSwitch, function(v)
			AimCfg.AutoSwitch = v
			Aim.sticky = nil
		end, "aim.AutoSwitch")
	end },
	{ title = "Snap line", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 1, "Snap line", AimCfg.SnapLine, function(v)
			AimCfg.SnapLine = v
		end, "aim.SnapLine")
		addToggle(entry.well, 2, "Target box", AimCfg.TargetBox, function(v)
			AimCfg.TargetBox = v
		end, "aim.TargetBox")
		addToggle(entry.well, 3, "Target health", AimCfg.TargetHp, function(v)
			AimCfg.TargetHp = v
		end, "aim.TargetHp")
		addToggle(entry.well, 4, "FOV circle", AimCfg.FovCircle, function(v)
			AimCfg.FovCircle = v
		end, "aim.FovCircle")
		if not hasDrawing then
			addNote(entry.well, 5, "Drawing API missing here — visuals off, aiming still works.")
		end
	end },
	{ title = "Motion", build = function(entry)
		prepWell(entry.well)
		addSlider(entry.well, 1, "FOV", 20, 500, AimCfg.FOV, 0, function(v)
			AimCfg.FOV = math.floor(v)
		end, "aim.FOV")
		addSlider(entry.well, 2, "Smoothing", 0, 0.95, AimCfg.Smoothing, 2, function(v)
			AimCfg.Smoothing = v
		end, "aim.Smoothing")
		addSlider(entry.well, 3, "Prediction (ms)", 0, 200, AimCfg.PredictionMs, 0, function(v)
			AimCfg.PredictionMs = math.floor(v)
		end, "aim.PredictionMs")
	end },
	{ title = "Checks", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 1, "Team check", AimCfg.TeamCheck, function(v)
			AimCfg.TeamCheck = v
		end, "aim.TeamCheck")
		addToggle(entry.well, 2, "Visible check", AimCfg.VisibleCheck, function(v)
			AimCfg.VisibleCheck = v
		end, "aim.VisibleCheck")
		addToggle(entry.well, 3, "Require equipped", AimCfg.RequireEquipped, function(v)
			AimCfg.RequireEquipped = v
		end, "aim.RequireEquipped")
		addSlider(entry.well, 4, "Max distance", 25, 2000, AimCfg.MaxDistance, 0, function(v)
			AimCfg.MaxDistance = math.floor(v)
		end, "aim.MaxDistance")
	end },
	{ title = "Silent aim", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 1, "Silent aim", SilentConfig.Enabled, function(v)
			SilentConfig.Enabled = v
			if v then
				Silent.install()
			end
		end, "silent.Enabled")
		addSegmented(entry.well, 2, "Method", {
			{ label = "Hook", value = "Hook" },
			{ label = "Click", value = "Click" },
		}, SilentConfig.Method, function(v)
			SilentConfig.Method = v
		end, "silent.Method")
		addSegmented(entry.well, 3, "Hit part", {
			{ label = "Head", value = "Head" },
			{ label = "Torso", value = "Torso" },
			{ label = "Nearest", value = "Nearest" },
		}, SilentConfig.HitPart, function(v)
			SilentConfig.HitPart = v
		end, "silent.HitPart")
		addToggle(entry.well, 4, "FOV gate", SilentConfig.UseFOV, function(v)
			SilentConfig.UseFOV = v
		end, "silent.UseFOV")
			addSlider(entry.well, 5, "FOV radius (0=use Aim)", 0, 500, SilentConfig.FovRadius or 0, 0, function(v)
				SilentConfig.FovRadius = math.floor(v)
			end, "silent.FovRadius")
			addSlider(entry.well, 6, "Prediction (ms)", 0, 200, SilentConfig.PredictionMs or 0, 0, function(v)
				SilentConfig.PredictionMs = math.floor(v)
			end, "silent.PredictionMs")
		local stat = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.GothamMedium,
			Text = "idle",
			TextSize = 11,
			TextColor3 = C.text2,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 5,
			Parent = entry.well,
		})
		task.spawn(function()
			local painted = "\1"
			while not destroyed do
				local line
				if not Silent.supported then
					line = "unavailable — no game modules"
				elseif SilentConfig.Enabled then
					local mode = SilentConfig.Method == "Click" and "click packets"
						or (Silent.hooked and "hook" or "click (hook failed)")
					local ago = Silent.lastAt > 0
						and string.format(" · %.1fs ago", math.max(tick() - Silent.lastAt, 0))
						or ""
					line = string.format("%s · hits: %d · last: %s%s",
						mode, Silent.redirects + Silent.clicks, Silent.lastName, ago)
				else
					line = "idle"
				end
				if line ~= painted then
					painted = line
					pcall(function()
						stat.Text = line
						stat.TextColor3 = SilentConfig.Enabled and C.blueHi or C.text2
					end)
				end
				task.wait(0.2)
			end
		end)
	end },
}

CARD_SPECS.visuals = {
	{ title = "Skin changer", build = function(entry)
		prepWell(entry.well)
		local skinToggle
		skinToggle = addToggle(entry.well, 1, "Unlock all + skins", false, function(v)
			Skins.setEnabled(v)
		end)
		local stat = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.GothamMedium,
			Text = "status: off",
			TextSize = 11,
			TextColor3 = C.text2,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
			Parent = entry.well,
		})
		task.spawn(function()
			local painted = "\1"
			while not destroyed do
				local line = "status: " .. Skins.status
				if line ~= painted then
					painted = line
					pcall(function()
						stat.Text = line
						stat.TextColor3 = Skins.enabled and C.blueHi or C.text2
					end)
					if Skins.status == "unavailable" then
						skinToggle.set(false)
					end
				end
				task.wait(0.25)
			end
		end)
		addNote(entry.well, 3, "Pick cosmetics in the game's own locker — every skin, wrap, charm and finisher is owned while enabled. Equips save to ripped_skins/config.json.")
	end },
}

CARD_SPECS.misc = {
	{ title = "Hit sounds", build = function(entry)
		prepWell(entry.well)
		addToggle(entry.well, 10, "Hit sounds", HitSoundCfg.HitEnabled, function(v)
			HitSoundCfg.HitEnabled = v
		end, "hits.HitEnabled")
		addDropdown(entry.well, 20, "Hit sound", HIT_SOUND_NAMES, HitSoundCfg.HitSound, function(v)
			HitSoundCfg.HitSound = v
		end, "hits.HitSound")
		addSlider(entry.well, 30, "Volume", 0, 100, HitSoundCfg.HitVolume, 0, function(v)
			HitSoundCfg.HitVolume = math.floor(v)
		end, "hits.HitVolume")
		addButton(entry.well, 40, "Test sound", function()
			HitSounds.play()
		end)
		addNote(entry.well, 50, "Plays on damage you deal: ragebot shots, silent redirects, aimbot-locked targets, or hits on anyone near your crosshair.")
	end },
}

CARD_SPECS.settings = {
	{ title = "Config", build = function(entry)
		prepWell(entry.well)
		local nameBox = new("TextBox", {
			BackgroundColor3 = C.panel2,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 22),
			Font = Enum.Font.GothamMedium,
			Text = ConfigManager.active or "default",
			PlaceholderText = "config name",
			TextSize = 12,
			TextColor3 = C.text,
			PlaceholderColor3 = C.text2,
			ClearTextOnFocus = false,
			LayoutOrder = 1,
			Parent = entry.well,
		})
		corner(nameBox, 4)
		stroke(nameBox, C.line, 1, 0)

		local statusLbl = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.GothamMedium,
			Text = "active: " .. (ConfigManager.active or "default"),
			TextSize = 11,
			TextColor3 = C.blueHi,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
			Parent = entry.well,
		})

		local function refreshStatus(msg)
			statusLbl.Text = msg or ("active: " .. (ConfigManager.active or "default"))
		end

		addButton(entry.well, 3, "Save", function()
			local name = nameBox.Text:match("^%s*(.-)%s*$") or ""
			if name == "" then
				name = ConfigManager.active or "default"
			end
			if ConfigManager.save(name) then
				nameBox.Text = name
				refreshStatus("saved: " .. name)
			else
				refreshStatus("save failed (no writefile?)")
			end
		end)
		addButton(entry.well, 4, "Load", function()
			local name = nameBox.Text:match("^%s*(.-)%s*$") or ""
			if name == "" then
				name = ConfigManager.active or "default"
			end
			if ConfigManager.load(name) then
				nameBox.Text = name
				refreshStatus("loaded: " .. name)
			else
				refreshStatus("load failed: " .. name)
			end
		end)
		addButton(entry.well, 5, "Delete", function()
			local name = nameBox.Text:match("^%s*(.-)%s*$") or ""
			if ConfigManager.delete(name) then
				nameBox.Text = ConfigManager.active
				refreshStatus("deleted: " .. name)
			else
				refreshStatus("can't delete default / missing")
			end
		end)
		addButton(entry.well, 6, "Reset to defaults", function()
			ConfigManager.reset()
			refreshStatus("reset to defaults")
		end)
		addToggle(entry.well, 7, "Auto load last config", ConfigManager.meta.AutoLoad, function(v)
			ConfigManager.meta.AutoLoad = v
			ConfigManager.writeIndex()
		end, "meta.AutoLoad")
		addToggle(entry.well, 8, "Auto save", ConfigManager.meta.AutoSave, function(v)
			ConfigManager.meta.AutoSave = v
			ConfigManager.writeIndex()
		end, "meta.AutoSave")
		addSlider(entry.well, 9, "Autosave interval (s)", 5, 120, ConfigManager.meta.AutoSaveInterval or 30, 0, function(v)
			ConfigManager.meta.AutoSaveInterval = math.floor(v)
			ConfigManager.writeIndex()
		end, "meta.AutoSaveInterval")
		addNote(entry.well, 10, "Configs live in workspace/ripped_win/*.json. Active name stored in active.txt. Autosave writes autosave.json on change.")
	end },
	{ title = "UI", build = function(entry)
		prepWell(entry.well)
		addNote(entry.well, 1, "RightShift toggles the menu. Drag header to move, bottom-right grip to resize.")
	end },
}

local panes = {}
for _, s in ipairs(SECTIONS) do
	local pane = new("Frame", {
		Name = s.id,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		Parent = scroller,
	}, {
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, GAP),
		}),
	})
	local spec = CARD_SPECS[s.id]
	local rowCount = spec and math.ceil(#spec / 2) or 2
	local idx = 0
	for r = 1, rowCount do
		local row = new("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = r,
			Parent = pane,
		}, {
			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, GAP),
			}),
		})
		for c = 1, 2 do
			idx += 1
			local item = spec and spec[idx]
			local entry = buildCard(row, c, item and item.title)
			if item and item.build then
				item.build(entry)
			end
		end
	end
	panes[s.id] = pane
end

connect(scroller:GetPropertyChangedSignal("AbsoluteSize"), setCardHeights)
local navs, navById = {}, {}
local current = nil
local markerReady = false

local function placeMarker(animate)
	local n = navById[current]
	if not n or n.btn.AbsoluteSize.Y <= 0 then
		return
	end
	local y = n.btn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + (n.btn.AbsoluteSize.Y - 24) / 2
	local target = UDim2.fromOffset(0, math.floor(y + 0.5))
	if animate and markerReady then
		tween(marker, 0.26, { Position = target })
	else
		marker.Position = target
		marker.Visible = true
		markerReady = true
	end
end

local function paintNav(n)
	local dur = 0.18
	local labelColor, iconColor, bgT, bgColor, strokeT
	if n.selected then
		labelColor, iconColor, bgColor, bgT, strokeT = C.blueHi, C.blueHi, C.blue, 0.9, 0.72
	elseif n.hovered then
		labelColor, iconColor, bgColor, bgT, strokeT = C.text, C.text, C.panel2, 0, 1
	else
		labelColor, iconColor, bgColor, bgT, strokeT = C.text2, C.text2, C.panel2, 1, 1
	end
	tween(n.btn, dur, { BackgroundColor3 = bgColor, BackgroundTransparency = bgT })
	tween(n.stroke, dur, { Transparency = strokeT })
	tween(n.label, dur, { TextColor3 = labelColor })
	n.icon.setColor(iconColor, dur)
end

local function selectSection(id)
	if current == id then
		return
	end
	current = id
	for _, n in ipairs(navs) do
		n.selected = (n.id == id)
		paintNav(n)
	end
	for sid, pane in pairs(panes) do
		pane.Visible = (sid == id)
	end
	scroller.CanvasPosition = Vector2.new(0, 0)
	local pane = panes[id]
	if not REDUCED_MOTION then
		pane.Position = UDim2.fromOffset(0, 6)
		tween(pane, 0.22, { Position = UDim2.fromOffset(0, 0) })
		fade.BackgroundTransparency = 0.5
		tween(fade, 0.22, { BackgroundTransparency = 1 })
	end
	placeMarker(true)
end

for i, s in ipairs(SECTIONS) do
	local btn = new("TextButton", {
		Name = s.id,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.panel2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = i,
		Parent = navList,
	})
	corner(btn, 4)
	local btnStroke = stroke(btn, C.blue, 1, 1)

	local icon = makeIcon(btn, s.prims, 20, 1.6)
	icon.root.AnchorPoint = Vector2.new(0, 0.5)
	icon.root.Position = UDim2.new(0, 18, 0.5, 0)

	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 52, 0, 0),
		Size = UDim2.new(1, -84, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = s.label,
		TextSize = 12,
		TextColor3 = C.text2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn,
	})

	local n = {
		id = s.id,
		btn = btn,
		stroke = btnStroke,
		icon = icon,
		label = label,
		selected = false,
		hovered = false,
	}
	table.insert(navs, n)
	navById[s.id] = n

	connect(btn.MouseEnter, function()
		n.hovered = true
		paintNav(n)
	end)
	connect(btn.MouseLeave, function()
		n.hovered = false
		paintNav(n)
	end)
	connect(btn.Activated, function()
		selectSection(s.id)
	end)
	connect(btn:GetPropertyChangedSignal("AbsolutePosition"), function()
		if current == s.id then
			placeMarker(false)
		end
	end)
end

local function applyResponsive()
	local w = winW
	local sw, brandSize, tw, th, cw, ch, navSize, showDots, gap
	if w >= 820 then
		sw, brandSize, tw, th, cw, ch, navSize, showDots, gap = 152, 17, 32, 28, 24, 20, 13, true, 8
	elseif w >= 600 then
		sw, brandSize, tw, th, cw, ch, navSize, showDots, gap = 142, 15, 29, 25, 22, 18, 12, true, 7
	else
		sw, brandSize, tw, th, cw, ch, navSize, showDots, gap = 124, 13, 25, 22, 19, 16, 11, false, 5
	end
	sidebar.Size = UDim2.new(0, sw, 1, 0)
	brandCell.Size = UDim2.new(0, sw, 1, -1)
	main.Position = UDim2.fromOffset(sw, 0)
	main.Size = UDim2.new(1, -sw, 1, 0)
	ripLabel.TextSize = brandSize
	winLabel.TextSize = brandSize
	brandRow:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, gap)
	logoTile.Size = UDim2.fromOffset(tw, th)
	for _, n in ipairs(navs) do
		n.label.TextSize = navSize
	end
end

local function viewport()
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.X > 0 and cam.ViewportSize.Y > 0 then
		return cam.ViewportSize
	end
	local ok, size = pcall(function()
		return gui.AbsoluteSize
	end)
	if ok and size and size.X > 0 and size.Y > 0 then
		return size
	end
	return Vector2.new(1280, 720)
end

local function setSize(w, h)
	winW, winH = w, h
	window.Size = UDim2.fromOffset(w, h)
	applyResponsive()
end

local function fit(recenter)
	local vp = viewport()
	local maxW, maxH = math.max(0, vp.X - MARGIN * 2), math.max(0, vp.Y - MARGIN * 2)
	local w = math.min(math.max(winW, math.min(MIN_W, maxW)), maxW)
	local h = math.min(math.max(winH, math.min(MIN_H, maxH)), maxH)
	setSize(w, h)
	local x, y
	if recenter then
		x, y = math.floor((vp.X - w) / 2), math.floor((vp.Y - h) / 2)
	else
		x = math.clamp(window.Position.X.Offset, MARGIN, math.max(MARGIN, vp.X - w - MARGIN))
		y = math.clamp(window.Position.Y.Offset, MARGIN, math.max(MARGIN, vp.Y - h - MARGIN))
	end
	window.Position = UDim2.fromOffset(x, y)
end

local grip = new("TextButton", {
	Name = "ResizeGrip",
	Text = "",
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -2, 1, -2),
	Size = UDim2.fromOffset(18, 18),
	ZIndex = 20,
	Parent = window,
})
for _, g in ipairs({ { len = 12, off = 10 }, { len = 6, off = 5 } }) do
	new("Frame", {
		BackgroundColor3 = C.scroll,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -g.off, 1, -g.off),
		Size = UDim2.fromOffset(g.len, 1.5),
		Rotation = -45,
		ZIndex = 21,
		Parent = grip,
	})
end

local dragState, resizeState = nil, nil
local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

connect(header.InputBegan, function(input)
	if isPointer(input) then
		dragState = {
			start = Vector2.new(input.Position.X, input.Position.Y),
			x = window.Position.X.Offset,
			y = window.Position.Y.Offset,
		}
	end
end)
connect(grip.InputBegan, function(input)
	if isPointer(input) then
		resizeState = {
			start = Vector2.new(input.Position.X, input.Position.Y),
			w = winW,
			h = winH,
		}
	end
end)
connect(UserInputService.InputChanged, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local pos = Vector2.new(input.Position.X, input.Position.Y)
	local vp = viewport()
	if dragState then
		local d = pos - dragState.start
		local x = math.clamp(dragState.x + d.X, -winW + 120, vp.X - 120)
		local y = math.clamp(dragState.y + d.Y, 0, vp.Y - HEADER_H)
		window.Position = UDim2.fromOffset(x, y)
	elseif resizeState then
		local d = pos - resizeState.start
		local px, py = window.Position.X.Offset, window.Position.Y.Offset
		local maxW = math.max(MIN_W, vp.X - px - MARGIN)
		local maxH = math.max(MIN_H, vp.Y - py - MARGIN)
		setSize(math.clamp(resizeState.w + d.X, MIN_W, maxW), math.clamp(resizeState.h + d.Y, MIN_H, maxH))
	end
end)
connect(UserInputService.InputEnded, function(input)
	if isPointer(input) then
		dragState, resizeState = nil, nil
	end
end)
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
	fit(true)
end)

local function setVisible(v)
	window.Visible = v
	for _, t in ipairs(loopTweens) do
		if v then
			t:Play()
		else
			t:Pause()
		end
	end
end
connect(UserInputService.InputBegan, function(input, processed)
	if not processed and input.KeyCode == TOGGLE_KEY then
		setVisible(not window.Visible)
	end
end)

if not REDUCED_MOTION then
	local glow = TweenService:Create(
		logoGlow,
		TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.85 }
	)
	glow:Play()
	table.insert(loopTweens, glow)

	sweepGradient.Offset = Vector2.new(-1, 0)
	local sweep = TweenService:Create(
		sweepGradient,
		TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 6),
		{ Offset = Vector2.new(1, 0) }
	)
	sweep:Play()
	table.insert(loopTweens, sweep)

	if logoImage.IsLoaded then
		tween(logoImage, 0.7, { ImageTransparency = 0 })
	end
	tween(underline, 0.7, { Size = UDim2.new(1, 0, 0, 2) }, Enum.EasingStyle.Quint)
end

fit(true)
selectSection(SECTIONS[1].id)
Ragebot.start()
if ESPConfig.Enabled then
	Esp.setEnabled(true)
end
if AimCfg.Enabled then
	Aim.setEnabled(true)
end
if SilentConfig.Enabled and Silent.supported then
	Silent.install()
end
HitSounds.start()
task.defer(function()
	if destroyed then
		return
	end
	setCardHeights()
	placeMarker(false)
	ConfigManager.refreshWidgets()
end)

if not REDUCED_MOTION then
	local cover = new("Frame", {
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = window,
	})
	local final = window.Position
	window.Position = UDim2.fromOffset(final.X.Offset, final.Y.Offset + 8)
	tween(window, 0.38, { Position = final })
	local t = tween(cover, 0.38, { BackgroundTransparency = 1 })
	if t then
		connect(t.Completed, function()
			cover:Destroy()
		end)
	end
end