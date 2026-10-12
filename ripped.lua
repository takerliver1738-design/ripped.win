-- ripped.win
-- key: fckedbymanta

local genv = (type(getgenv) == "function" and getgenv()) or _G
genv.ripped_unlocked = genv.ripped_unlocked or false
local KEY = "fckedbymanta"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- ============================ KEY GATE ============================
if not genv.ripped_unlocked then
    local pg = lp:WaitForChild("PlayerGui", 15)
    local sg = Instance.new("ScreenGui")
    sg.Name = "ripped_gate"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.Parent = pg

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(340, 200)
    card.Position = UDim2.new(0.5, -170, 0.5, -100)
    card.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    card.BorderSizePixel = 0
    card.Parent = sg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke", card)
    cs.Color = Color3.fromRGB(130, 95, 210)
    cs.Thickness = 1.5

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 32)
    t.Position = UDim2.new(0, 0, 0, 20)
    t.Text = "RIPPED.WIN"
    t.TextColor3 = Color3.fromRGB(160, 125, 230)
    t.TextSize = 22
    t.Font = Enum.Font.GothamBold
    t.Parent = card

    local s = Instance.new("TextLabel")
    s.BackgroundTransparency = 1
    s.Size = UDim2.new(1, 0, 0, 14)
    s.Position = UDim2.new(0, 0, 0, 52)
    s.Text = "enter key"
    s.TextColor3 = Color3.fromRGB(110, 115, 130)
    s.TextSize = 12
    s.Font = Enum.Font.Gotham
    s.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -40, 0, 38)
    box.Position = UDim2.new(0, 20, 0, 82)
    box.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    box.BorderSizePixel = 0
    box.PlaceholderText = "key"
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(235, 235, 245)
    box.PlaceholderColor3 = Color3.fromRGB(85, 90, 105)
    box.TextSize = 14
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 38)
    btn.Position = UDim2.new(0, 20, 0, 130)
    btn.BackgroundColor3 = Color3.fromRGB(115, 80, 195)
    btn.Text = "unlock"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local err = Instance.new("TextLabel")
    err.BackgroundTransparency = 1
    err.Size = UDim2.new(1, 0, 0, 14)
    err.Position = UDim2.new(0, 0, 0, 175)
    err.Text = ""
    err.TextColor3 = Color3.fromRGB(255, 80, 80)
    err.TextSize = 11
    err.Font = Enum.Font.Gotham
    err.Parent = card

    local function try()
        if box.Text == KEY then
            genv.ripped_unlocked = true
            sg:Destroy()
        else
            err.Text = "wrong key"
            box.Text = ""
        end
    end
    btn.MouseButton1Click:Connect(try)
    box.FocusLost:Connect(function(enter) if enter then try() end end)

    while not genv.ripped_unlocked do
        task.wait(0.1)
    end
end

-- ============================ LOAD OBSIDIAN ============================
local function http(url)
    local ok, res = pcall(game.HttpGet, game, url)
    if ok and type(res) == "string" and #res > 400 then return res end
end

local mirrors = {
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/",
    "https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/",
    "https://rawcdn.githack.com/deividcomsono/Obsidian/main/",
}

local libSrc, themeSrc, saveSrc
for _, base in ipairs(mirrors) do
    libSrc = http(base .. "Library.lua")
    if libSrc then
        themeSrc = http(base .. "addons/ThemeManager.lua")
        saveSrc  = http(base .. "addons/SaveManager.lua")
        break
    end
end

if not libSrc then
    local pg = lp:WaitForChild("PlayerGui", 10)
    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.Parent = pg
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 60)
    l.Position = UDim2.new(0, 0, 0.42, 0)
    l.BackgroundTransparency = 1
    l.Text = "ripped.win — ui failed to load. re-execute."
    l.TextColor3 = Color3.fromRGB(255, 90, 90)
    l.TextSize = 15
    l.Font = Enum.Font.GothamBold
    l.Parent = sg
    return
end

local Library = loadstring(libSrc)()
local ThemeManager = themeSrc and loadstring(themeSrc)() or nil
local SaveManager = saveSrc and loadstring(saveSrc)() or nil

-- Obsidian paints from a named scheme, not from a theme table: SetTheme is not
-- part of its API at all, so the old call failed inside its own pcall and the
-- colours here never reached the screen. Writing the scheme and re-applying it
-- through the registry is what the library does for a theme change of its own.
pcall(function()
    local Scheme = Library.Scheme

    Scheme.BackgroundColor = Color3.fromRGB(15, 17, 22)
    Scheme.MainColor = Color3.fromRGB(20, 22, 28)
    Scheme.AccentColor = Color3.fromRGB(150, 110, 220)
    Scheme.OutlineColor = Color3.fromRGB(38, 40, 50)
    Scheme.FontColor = Color3.fromRGB(235, 235, 245)

    Library:UpdateColorsUsingRegistry()
end)

local Window = Library:CreateWindow({
    Title = "ripped.win",
    Footer = "discord.gg/ripped",
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    main = Window:AddTab("Main", "home"),
    visual = Window:AddTab("Visual", "eye"),
    move = Window:AddTab("Movement", "move"),
    auto = Window:AddTab("Automation", "cpu"),
    sound = Window:AddTab("Game Sounds", "volume-2"),
    spoof = Window:AddTab("Spoof", "shield"),
    world = Window:AddTab("World", "globe"),
    cfg = Window:AddTab("Settings", "settings"),
}

-- ============================ CONFIG ============================
local C = {
    aim = false, aimMode = "None", aimKey = "E", aimKeyMode = "Hold",
    lockMethod = "Camera", scopedOnly = false,
    aimPart = "Head", fov = 150, smooth = 60,
    silent = false, silentChance = 100, silentFov = 242,
    showFov = false, fovColor = Color3.fromRGB(150, 110, 220),
    teamCheck = true, wallCheck = true, ffCheck = true, aliveCheck = true,
    predMode = "Advanced", predLead = 12, predVel = 100,
    autoFire = false, autoFireDelay = 8,
    maxDist = 1500, minDist = 0,
    priority = "Crosshair",
    hpFilter = 0, ignore = {},
    rage = false, rageAuto = false, rageHit = 100,
    trig = false, trigKey = "MouseButton2",
    trigFov = 30, trigDelay = 2, trigRand = 1,
    trigTeam = true, trigHead = false, trigAuto = true,
    noSpread = false, rapidFire = false, noScythe = false,
    fastReload = false, noRecoil = true, infAmmo = false,
    unSkins = false, unWraps = false, unCharms = false,
    unEmotes = false, unFinishers = false, unKillFX = false,
    esp = false, espHL = false,
    espBox = false, espNames = false, espHp = false, espHpText = false,
    espDist = false, espLook = false, espSkel = false,
    espTeammates = false, espDot = false, espTracers = false,
    espChams = false,
    espMax = 500, espText = 13, espFps = 30,
    colVis = Color3.fromRGB(60, 255, 60),
    colHid = Color3.fromRGB(255, 60, 60),
    colTeam = Color3.fromRGB(60, 130, 255),
    chamsFill = 0.5, chamsOutline = 0,
    noScopeOv = false, noScopeRet = false,
    noTracers = false, noMuzzle = false,
    noHitmark = false, noFlash = false,
    noBurn = false, noADS = false,
    noShootAnim = false, noSprintAnim = false,
    noSway = false, noBob = false,
    xhair = false, xhairSize = 8, xhairThick = 2, xhairGap = 3,
    xhairColor = Color3.fromRGB(0, 255, 170),
    hitmark = true, hitSound = "Skeet", hitVol = 50,
    dmgNums = true, killFeed = true, streakHUD = true,
    speed = false, speedVal = 16,
    jump = false, jumpVal = 50,
    fly = false, flySpeed = 50,
    noclip = false, infJump = false, bhop = false,
    fullbright = false, sprint = false, sprintVal = 32,
    autoplay = false, autoplayDist = 18,
    autoLoadout = true, autoVote = true, autoBan = true,
    autoQueue = false, autoAccept = true,
    primary = "AK-47", secondary = "Deagle", melee = "Karambit",
    util1 = "Frag Grenade", util2 = "Flashbang",
    mapList = { "Arena", "Onyx", "Crossroads" },
    banList = { "Grenade Launcher", "Minigun", "RPG" },
    spoofFps = false, spoofPing = false, fakeLag = false, hwid = false,
    noFog = true, gravity = false, gravityVal = 196.2,
    ambient = false, ambientCol = Color3.fromRGB(150, 150, 150),
    skybox = false, skyboxId = "",
    fovChanger = false, worldFov = 90,
    camOffset = false, camX = 0, camY = 0, camZ = 0,
    panicKey = "Delete", watermark = true,
    legit = false, legitFov = 60, legitSmooth = 18,
}

local sess = { start = tick(), kills = 0, deaths = 0, streak = 0, best = 0 }

-- ============================ RUNTIME ============================
local canMoveMouse = type(mousemoverel) == "function"
local canPressMouse = type(mouse1press) == "function" and type(mouse1release) == "function"
local vim = nil
pcall(function() vim = game:GetService("VirtualInputManager") end)
local drawingOk = type(Drawing) == "table" and type(Drawing.new) == "function"

-- no yield, async release
local function shoot()
    if canPressMouse then
        pcall(mouse1press)
        task.delay(0.012, function() pcall(mouse1release) end)
        return
    end
    if vim then
        pcall(function()
            vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)
        end)
        task.delay(0.012, function()
            pcall(function()
                vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)
            end)
        end)
    end
end

local fovCircle, tDot, wm
local xhair = {}
if drawingOk then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 64
    fovCircle.Radius = C.fov
    fovCircle.Color = C.fovColor
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Transparency = 0.7

    tDot = Drawing.new("Circle")
    tDot.Radius = 4
    tDot.NumSides = 16
    tDot.Filled = true
    tDot.Color = Color3.fromRGB(255, 90, 90)
    tDot.Visible = false

    for i = 1, 4 do
        xhair[i] = Drawing.new("Line")
        xhair[i].Thickness = C.xhairThick
        xhair[i].Color = C.xhairColor
        xhair[i].Visible = false
    end

    wm = Drawing.new("Text")
    wm.Size = 14
    wm.Outline = true
    wm.OutlineColor = Color3.new(0, 0, 0)
    wm.Color = Color3.fromRGB(160, 125, 230)
    wm.Font = 2
    wm.Visible = false
end

local function hrp(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function head(c) return c and c:FindFirstChild("Head") end
local function hum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(c)
    local h = hum(c)
    return h and h.Health > 0
end
local function ff(c) return c and c:FindFirstChildOfClass("ForceField") end
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function pick(char)
    if C.aimPart == "Head" then return head(char) or hrp(char) end
    if C.aimPart == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or hrp(char)
    end
    local cam = workspace.CurrentCamera
    if not cam then return head(char) end
    local h, r = head(char), hrp(char)
    if h and r then
        if (h.Position - cam.CFrame.Position).Magnitude < (r.Position - cam.CFrame.Position).Magnitude then
            return h
        end
        return r
    end
    return h or r
end

-- One raycast filter for the whole script. The line-of-sight check runs
-- hundreds of times a second between the aim, the ESP and the trigger, and
-- building a RaycastParams - plus a fresh filter list - on every one of them was
-- allocating two tables per call. The list is reused and only its one entry is
-- rewritten, which is also why the character is looked at here rather than
-- captured once: it changes on every respawn.
local losFilter = { lp.Character }
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
losParams.FilterDescendantsInstances = losFilter
losParams.IgnoreWater = true

local function los(part)
    local cam = workspace.CurrentCamera
    if not cam then return true end
    losFilter[1] = lp.Character
    -- workspace:Raycast, not the deprecated FindPartOnRay: same answer, a plain
    -- result table instead of a part plus an impact point, and it is the call
    -- the engine has been optimising since the old one was retired.
    local hit = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, losParams)
    if not hit or not hit.Instance then return true end
    local inst = hit.Instance
    return inst == part or inst:IsDescendantOf(part.Parent)
end

-- vis cache (200ms)
local visCache = {}
local function visCached(plr, part)
    if not part then return false end
    local c = visCache[plr]
    local now = tick()
    if c and now - c.t < 0.2 then return c.v end
    local v = los(part)
    visCache[plr] = { v = v, t = now }
    return v
end

local function teammate(plr)
    if not C.teamCheck then return false end
    local mine = lp.Team
    return mine and plr.Team == mine
end

local function ignored(plr)
    for _, id in ipairs(C.ignore) do
        if plr.UserId == id then return true end
    end
    return false
end

local function isTarget(plr, char)
    if plr == lp then return false end
    if ignored(plr) then return false end
    if not char then return false end
    if teammate(plr) then return false end
    if C.aliveCheck and not alive(char) then return false end
    if C.ffCheck and ff(char) then return false end
    if C.hpFilter > 0 then
        local h = hum(char)
        if not h then return false end
        local pct = (h.Health / math.max(h.MaxHealth, 1)) * 100
        if pct > C.hpFilter then return false end
    end
    return true
end

local function predict(part, lead)
    local char = part.Parent
    if not char then return part.Position end
    local r = hrp(char)
    if not r then return part.Position end
    if C.predMode == "Off" or lead <= 0 then return part.Position end
    return part.Position + r.AssemblyLinearVelocity * lead * (C.predVel / 100)
end

local function fovNow()
    local f = C.fov
    if C.legit and f > C.legitFov then f = C.legitFov end
    return f
end

-- Reused across scans, so a scan at 25 Hz does not allocate an entry and a
-- comparison closure every time.
local targetList = {}

local function byScore(a, b)
    return a.score < b.score
end

local function findTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local ml = UIS:GetMouseLocation()
    local f = fovNow()

    -- Score every candidate first, then ask which of them can be seen. The wall
    -- check is the expensive half - a physics ray per candidate, twenty-five
    -- times a second - and the screen maths that orders them is nearly free, so
    -- the old loop was paying for a ray at every player before it knew whether
    -- that player was anywhere near the priority order. Walking the sorted list
    -- and stopping at the first visible one returns the same target the old loop
    -- picked, for one ray instead of one per player.
    local count = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if isTarget(plr, char) then
            local part = pick(char)
            if part and part.Parent then
                local dist = (part.Position - cam.CFrame.Position).Magnitude
                if dist >= C.minDist and dist <= C.maxDist then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local sd = (Vector2.new(sp.X, sp.Y) - Vector2.new(cx, cy)).Magnitude
                        if sd <= f then
                            local score
                            if C.priority == "Mouse" then
                                score = (Vector2.new(sp.X, sp.Y) - Vector2.new(ml.X, ml.Y)).Magnitude
                            elseif C.priority == "Distance" then score = dist
                            elseif C.priority == "Health" then
                                local h = hum(char)
                                score = h and h.Health or 100
                            else
                                score = sd
                            end

                            count = count + 1

                            local entry = targetList[count]
                            if not entry then
                                entry = {}
                                targetList[count] = entry
                            end

                            entry.part, entry.score = part, score
                        end
                    end
                end
            end
        end
    end

    if count == 0 then return nil end

    -- the tail of the pool is left over from a scan that found more targets
    for i = #targetList, count + 1, -1 do
        targetList[i] = nil
    end

    table.sort(targetList, byScore)

    for i = 1, count do
        local entry = targetList[i]
        if not C.wallCheck or los(entry.part) then return entry.part end
    end

    return nil
end

-- shared target so aim + rage use one scan
local sharedT, sharedTTime = nil, 0
local function getSharedTarget(now)
    if now - sharedTTime < 0.04 and sharedT and sharedT.Parent then
        return sharedT
    end
    sharedTTime = now
    sharedT = findTarget()
    return sharedT
end

local aimState = { lastKey = false, toggled = false }
local function aimHeld()
    if C.aimKeyMode == "AlwaysOn" then return true end
    local kc = Enum.KeyCode[C.aimKey]
    local held = kc and UIS:IsKeyDown(kc)
    if not held then
        local uc = Enum.UserInputType[C.aimKey]
        if uc then held = UIS:IsMouseButtonPressed(uc) end
    end
    if C.aimKeyMode == "Toggle" then
        if held and not aimState.lastKey then
            aimState.toggled = not aimState.toggled
        end
        aimState.lastKey = held
        return aimState.toggled
    end
    if C.scopedOnly and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        return false
    end
    return held
end

local lastFire = 0
local function doAim(now)
    if not C.aim then return nil end
    if not aimHeld() then return nil end
    local target = getSharedTarget(now)
    if not target then return nil end
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local pos = predict(target, C.predLead / 100)
    if C.lockMethod == "Mouse" and canMoveMouse then
        local sp = cam:WorldToViewportPoint(pos)
        local vp = cam.ViewportSize
        local dx, dy = sp.X - vp.X / 2, sp.Y - vp.Y / 2
        local sm = C.smooth / 100
        if C.legit and sm < C.legitSmooth / 100 then sm = C.legitSmooth / 100 end
        dx, dy = dx * sm, dy * sm
        if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 then pcall(mousemoverel, dx, dy) end
    else
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos)
    end
    if C.autoFire and now - lastFire > C.autoFireDelay / 100 then
        lastFire = now
        shoot()
    end
    return target
end

local silentTarget = nil
local function doSilent()
    if not C.silent then silentTarget = nil; return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local best, bd = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and not teammate(plr) then
            local char = plr.Character
            if char then
                local part = head(char) or hrp(char)
                if part then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(cx, cy)).Magnitude
                        if d <= C.silentFov and d < bd then
                            bd = d
                            best = part
                        end
                    end
                end
            end
        end
    end
    if best and math.random() * 100 <= C.silentChance then
        silentTarget = best
    else
        silentTarget = nil
    end
end

local lastTrig = 0

-- The trigger's ray settings are built once and reused. While the trigger key is
-- held this runs on every frame, and it was building a RaycastParams and a fresh
-- filter list each time - two allocations per frame for an object that only ever
-- says the same two things.
local trigFilter = { lp.Character }
local trigParams = RaycastParams.new()
trigParams.FilterType = Enum.RaycastFilterType.Exclude
trigParams.FilterDescendantsInstances = trigFilter
trigParams.IgnoreWater = true

local function doTrigger(now)
    if not C.trig then return end
    local kc = Enum.KeyCode[C.trigKey]
    local uc = Enum.UserInputType[C.trigKey]
    local held = (kc and UIS:IsKeyDown(kc)) or (uc and UIS:IsMouseButtonPressed(uc))
    if not held then return end
    local wait = C.trigDelay / 100 + math.random() * (C.trigRand / 100)
    if now - lastTrig < wait then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    trigFilter[1] = lp.Character
    local res = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 5000, trigParams)
    if res and res.Instance then
        local char = res.Instance.Parent
        local plr = char and Players:GetPlayerFromCharacter(char)
        if plr and plr ~= lp then
            local myTeam = lp.Team
            if not (C.trigTeam and myTeam ~= nil and plr.Team == myTeam) then
                if not (C.trigHead and res.Instance.Name ~= "Head") then
                    lastTrig = now
                    if C.trigAuto then shoot() end
                end
            end
        end
    end
end

-- ============================ ESP ============================
local espPool = {}
local bonePairs = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
    {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function newESP()
    if not drawingOk then return nil end
    local e = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        hp = Drawing.new("Line"),
        hpBg = Drawing.new("Line"),
        hpText = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        dot = Drawing.new("Circle"),
        look = Drawing.new("Line"),
        bones = {},
    }
    for i = 1, #bonePairs do
        e.bones[i] = Drawing.new("Line")
    end
    return e
end

local function hideESP(e)
    if not e then return end
    for _, k in ipairs({"box", "name", "dist", "hp", "hpBg", "hpText", "tracer", "dot", "look"}) do
        if e[k] then e[k].Visible = false end
    end
    -- Eleven lines per player per frame were being told to hide again and again
    -- after they already were. The flag says whether this player's skeleton was
    -- drawn last frame, which is the only time there is anything to put out.
    if e.bonesLit then
        for _, b in ipairs(e.bones) do b.Visible = false end
        e.bonesLit = false
    end
end

local chams = {}
local function setChams(plr, char, color, on)
    local h = chams[plr]
    if not on then
        if h then h.Enabled = false end
        return
    end
    if not h then
        h = Instance.new("Highlight")
        h.Name = "ripped_h"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        chams[plr] = h
    end
    h.Adornee = char
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = C.chamsFill
    h.OutlineTransparency = C.chamsOutline
    h.Enabled = true
end

local function hpCol(hp, max)
    local r = hp / math.max(max, 1)
    if r > 0.6 then return Color3.fromRGB(60, 255, 60) end
    if r > 0.3 then return Color3.fromRGB(255, 200, 0) end
    return Color3.fromRGB(255, 60, 60)
end

local function drawESP()
    if not drawingOk then return end
    if not C.esp then
        for _, e in pairs(espPool) do hideESP(e) end
        for _, h in pairs(chams) do h.Enabled = false end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == lp then continue end
        local char = plr.Character
        local e = espPool[plr]
        local skip = false
        if not char or not alive(char) then skip = true end            -- A team check has to ask whether there IS a team first. Two nil teams
            -- are not "the same team": in a game that never assigns one - FFA, or
            -- the seconds before a round starts - `plr.Team == lp.Team` was true
            -- for everybody, so the ESP skipped the whole server and drew nothing
            -- while looking as if it were on.
            local myTeam = lp.Team
            if not skip and not C.espTeammates and myTeam ~= nil and plr.Team == myTeam then skip = true end
        local r = skip and nil or hrp(char)
        if not r then skip = true end
        if not skip then
            local d = (r.Position - cam.CFrame.Position).Magnitude
            if d > C.espMax then skip = true end
        end

        if skip then
            hideESP(e)
            if chams[plr] then chams[plr].Enabled = false end
        else
            if not e then
                e = newESP()
                espPool[plr] = e
            end
            if e then
                local hd = head(char)
                local col = visCached(plr, hd or r) and C.colVis or C.colHid
                if plr.Team == lp.Team then col = C.colTeam end
                local top = hd and (hd.Position + Vector3.new(0, 0.5, 0)) or (r.Position + Vector3.new(0, 2.5, 0))
                local bot = r.Position - Vector3.new(0, 3, 0)
                local tsp, tv = cam:WorldToViewportPoint(top)
                local bsp, bv = cam:WorldToViewportPoint(bot)

                if not tv and not bv then
                    hideESP(e)
                else
                    local h = math.abs(bsp.Y - tsp.Y)
                    local w = h * 0.55
                    local bx, by = tsp.X - w / 2, tsp.Y

                    if C.espBox then
                        e.box.Position = Vector2.new(bx, by)
                        e.box.Size = Vector2.new(w, h)
                        e.box.Color = col
                        e.box.Thickness = 1.5
                        e.box.Filled = false
                        e.box.Transparency = 1
                        e.box.Visible = true
                    else
                        e.box.Visible = false
                    end

                    if C.espNames then
                        e.name.Text = plr.Name
                        e.name.Position = Vector2.new(tsp.X - 50, by - 18)
                        e.name.Size = C.espText
                        e.name.Center = true
                        e.name.Outline = true
                        e.name.OutlineColor = Color3.new(0, 0, 0)
                        e.name.Color = col
                        e.name.Font = 2
                        e.name.Transparency = 1
                        e.name.Visible = true
                    else
                        e.name.Visible = false
                    end

                    if C.espDist then
                        -- A new string every frame for a number that changes once a
                        -- second: the label is only rewritten when the distance it
                        -- shows has actually moved a stud.
                        local studs = math.floor((r.Position - cam.CFrame.Position).Magnitude)
                        if studs ~= e.distValue then
                            e.distValue = studs
                            e.dist.Text = "[" .. studs .. "]"
                        end
                        e.dist.Position = Vector2.new(tsp.X - 50, by + h + 2)
                        e.dist.Size = C.espText - 1
                        e.dist.Center = true
                        e.dist.Outline = true
                        e.dist.OutlineColor = Color3.new(0, 0, 0)
                        e.dist.Color = col
                        e.dist.Font = 2
                        e.dist.Transparency = 1
                        e.dist.Visible = true
                    else
                        e.dist.Visible = false
                    end

                    if C.espHp then
                        local hh = hum(char)
                        if hh then
                            local ratio = clamp(hh.Health / math.max(hh.MaxHealth, 1), 0, 1)
                            local hx = bx - 6
                            local fh = h * ratio
                            e.hpBg.From = Vector2.new(hx, by)
                            e.hpBg.To = Vector2.new(hx, by + h)
                            e.hpBg.Color = Color3.new(0, 0, 0)
                            e.hpBg.Thickness = 4
                            e.hpBg.Transparency = 0.5
                            e.hpBg.Visible = true

                            e.hp.From = Vector2.new(hx, by + h - fh)
                            e.hp.To = Vector2.new(hx, by + h)
                            e.hp.Color = hpCol(hh.Health, hh.MaxHealth)
                            e.hp.Thickness = 3
                            e.hp.Transparency = 0.2
                            e.hp.Visible = true

                            if C.espHpText then
                                local hpNow, hpMax = math.floor(hh.Health), math.floor(hh.MaxHealth)
                                if hpNow ~= e.hpValue or hpMax ~= e.hpMax then
                                    e.hpValue, e.hpMax = hpNow, hpMax
                                    e.hpText.Text = hpNow .. "/" .. hpMax
                                end
                                e.hpText.Position = Vector2.new(hx - 40, by + h / 2 - 6)
                                e.hpText.Size = 11
                                e.hpText.Outline = true
                                e.hpText.OutlineColor = Color3.new(0, 0, 0)
                                e.hpText.Color = col
                                e.hpText.Font = 2
                                e.hpText.Transparency = 1
                                e.hpText.Visible = true
                            else
                                e.hpText.Visible = false
                            end
                        else
                            e.hp.Visible = false
                            e.hpBg.Visible = false
                            e.hpText.Visible = false
                        end
                    else
                        e.hp.Visible = false
                        e.hpBg.Visible = false
                        e.hpText.Visible = false
                    end

                    if C.espSkel then
                        for i, pair in ipairs(bonePairs) do
                            local a = char:FindFirstChild(pair[1])
                            local b = char:FindFirstChild(pair[2])
                            if a and b then
                                local ap, av = cam:WorldToViewportPoint(a.Position)
                                local bp, bvv = cam:WorldToViewportPoint(b.Position)
                                if av and bvv then
                                    e.bones[i].From = Vector2.new(ap.X, ap.Y)
                                    e.bones[i].To = Vector2.new(bp.X, bp.Y)
                                    e.bones[i].Color = col
                                    e.bones[i].Thickness = 1.5
                                    e.bones[i].Transparency = 0.4
                                    e.bones[i].Visible = true
                                    e.bonesLit = true
                                else
                                    e.bones[i].Visible = false
                                end
                            else
                                e.bones[i].Visible = false
                            end
                        end
                    elseif e.bonesLit then
                        for _, b in ipairs(e.bones) do b.Visible = false end
                        e.bonesLit = false
                    end

                    if C.espDot and hd then
                        local sp, on = cam:WorldToViewportPoint(hd.Position)
                        if on then
                            e.dot.Position = Vector2.new(sp.X, sp.Y)
                            e.dot.Radius = 4
                            e.dot.NumSides = 16
                            e.dot.Filled = true
                            e.dot.Color = col
                            e.dot.Transparency = 0.4
                            e.dot.Visible = true
                        else
                            e.dot.Visible = false
                        end
                    else
                        e.dot.Visible = false
                    end

                    if C.espLook then
                        local endPos = hd and (hd.Position + hd.CFrame.LookVector * 4) or r.Position + r.CFrame.LookVector * 4
                        local sp2, on2 = cam:WorldToViewportPoint(endPos)
                        if on2 and tv then
                            e.look.From = Vector2.new(tsp.X, tsp.Y)
                            e.look.To = Vector2.new(sp2.X, sp2.Y)
                            e.look.Color = col
                            e.look.Thickness = 2
                            e.look.Transparency = 0.5
                            e.look.Visible = true
                        else
                            e.look.Visible = false
                        end
                    else
                        e.look.Visible = false
                    end

                    if C.espTracers then
                        e.tracer.From = Vector2.new(vp.X / 2, vp.Y)
                        e.tracer.To = Vector2.new(tsp.X, by + h)
                        e.tracer.Color = col
                        e.tracer.Thickness = 1
                        e.tracer.Transparency = 0.5
                        e.tracer.Visible = true
                    else
                        e.tracer.Visible = false
                    end

                    setChams(plr, char, col, C.espChams or C.espHL)
                end
            end
        end
    end
end

local function drawXhair()
    if not drawingOk then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    for i = 1, 4 do
        if xhair[i].Visible ~= C.xhair then xhair[i].Visible = C.xhair end
        if C.xhair then
            xhair[i].Thickness = C.xhairThick
            xhair[i].Color = C.xhairColor
            local g, len = C.xhairGap, C.xhairSize
            if i == 1 then
                xhair[i].From = Vector2.new(cx, cy - g)
                xhair[i].To = Vector2.new(cx, cy - g - len)
            elseif i == 2 then
                xhair[i].From = Vector2.new(cx, cy + g)
                xhair[i].To = Vector2.new(cx, cy + g + len)
            elseif i == 3 then
                xhair[i].From = Vector2.new(cx - g, cy)
                xhair[i].To = Vector2.new(cx - g - len, cy)
            else
                xhair[i].From = Vector2.new(cx + g, cy)
                xhair[i].To = Vector2.new(cx + g + len, cy)
            end
        end
    end
end

-- ============================ MOVEMENT / WEAPON / WORLD ============================
local lastAppliedSpeed = -1
local function applyMovement()
    local char = lp.Character
    if not char then return end
    local h = hum(char)
    local r = hrp(char)
    if not h or not r then return end

    if C.speed then
        if h.WalkSpeed ~= C.speedVal then h.WalkSpeed = C.speedVal end
        lastAppliedSpeed = C.speedVal
    elseif lastAppliedSpeed ~= -1 then
        if h.WalkSpeed ~= 16 then h.WalkSpeed = 16 end
        lastAppliedSpeed = -1
    end

    if C.sprint then
        local target = math.max(h.WalkSpeed, C.sprintVal)
        if h.WalkSpeed ~= target then h.WalkSpeed = target end
    end

    if C.jump then
        if not h.UseJumpPower then h.UseJumpPower = true end
        if h.JumpPower ~= C.jumpVal then h.JumpPower = C.jumpVal end
    end

    if C.fly then r.Velocity = Vector3.new(0, C.flySpeed, 0) end

    if C.noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end

    if C.bhop and UIS:IsKeyDown(Enum.KeyCode.Space) then
        r.Velocity = Vector3.new(r.Velocity.X, math.max(r.Velocity.Y, 40), r.Velocity.Z)
    end

    if C.infJump then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end

local lastWeaponHash = ""
local function applyWeaponMods()
    local hash = tostring(C.noSpread) .. tostring(C.rapidFire) ..
                 tostring(C.fastReload) .. tostring(C.noRecoil) .. tostring(C.infAmmo)
    if hash == lastWeaponHash then return end
    lastWeaponHash = hash
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local mod = rep:FindFirstChild("Modules")
        local it = mod and mod:FindFirstChild("ItemLibrary")
        if not it then return end
        local lib = require(it)
        if not lib or not lib.Items then return end
        for _, item in pairs(lib.Items) do
            if type(item) == "table" and item.ShootRecoil ~= nil then
                if C.noSpread then
                    item.ShootSpread = 0
                    item.AimSpreadMultiplier = 0
                end
                if C.noRecoil then item.ShootRecoil = 0 end
                if C.rapidFire and item.ShootCooldown then item.ShootCooldown = item.ShootCooldown * 0.4 end
                if C.fastReload then item.ReloadLength = 0.05 end
                if C.infAmmo then item.MaxAmmo = 9999 end
            end
        end
    end)
end

local worldApplied = { noFog = false, fullbright = false, gravity = nil }
local function applyWorld()
    if C.noFog and not worldApplied.noFog then
        pcall(function() Lighting.FogEnd = 1e6 end)
        worldApplied.noFog = true
    end
    if C.fullbright and not worldApplied.fullbright then
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        end)
        worldApplied.fullbright = true
    end
    if C.gravity and worldApplied.gravity ~= C.gravityVal then
        pcall(function() workspace.Gravity = C.gravityVal end)
        worldApplied.gravity = C.gravityVal
    end
    if C.ambient then pcall(function() Lighting.Ambient = C.ambientCol end) end
    if C.skybox and C.skyboxId ~= "" then
        pcall(function()
            local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
            local id = "rbxassetid://" .. C.skyboxId
            sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt = id, id, id
            sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = id, id, id
        end)
    end
end

local function applyCam()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if C.fovChanger then cam.FieldOfView = C.worldFov end
    if C.camOffset then
        local char = lp.Character
        local h = char and hum(char)
        if h then h.CameraOffset = Vector3.new(C.camX, C.camY, C.camZ) end
    end
end

local function doAutoplay()
    if not C.autoplay then return end
    local char = lp.Character
    local r = char and hrp(char)
    if not r then return end
    local best, bd = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and not teammate(plr) then
            local ec = plr.Character
            if ec and alive(ec) then
                local er = hrp(ec)
                if er then
                    local d = (er.Position - r.Position).Magnitude
                    if d < bd then bd = d; best = er end
                end
            end
        end
    end
    if best and bd > C.autoplayDist then
        local dir = (best.Position - r.Position).Unit
        r.Velocity = Vector3.new(dir.X * 16, r.Velocity.Y, dir.Z * 16)
    end
end

-- ============================ KILL FX ============================
local streakTiers = {
    [2] = { "DOUBLE KILL", Color3.fromRGB(0, 200, 255) },
    [3] = { "TRIPLE KILL", Color3.fromRGB(80, 255, 120) },
    [4] = { "QUADRA KILL", Color3.fromRGB(180, 120, 255) },
    [5] = { "SPREE", Color3.fromRGB(255, 200, 0) },
    [10] = { "UNSTOPPABLE", Color3.fromRGB(255, 60, 60) },
    [15] = { "GODLIKE", Color3.fromRGB(255, 30, 120) },
    [20] = { "LEGENDARY", Color3.fromRGB(255, 255, 255) },
    [30] = { "RIPPED.WIN", Color3.fromRGB(160, 125, 230) },
}

local function flashHit()
    if not C.hitmark or not drawingOk then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local ls = {}
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Thickness = 2
        l.Color = Color3.fromRGB(255, 255, 255)
        if i == 1 then
            l.From, l.To = Vector2.new(cx - 8, cy - 8), Vector2.new(cx - 3, cy - 3)
        elseif i == 2 then
            l.From, l.To = Vector2.new(cx + 8, cy - 8), Vector2.new(cx + 3, cy - 3)
        elseif i == 3 then
            l.From, l.To = Vector2.new(cx - 8, cy + 8), Vector2.new(cx - 3, cy + 3)
        else
            l.From, l.To = Vector2.new(cx + 8, cy + 8), Vector2.new(cx + 3, cy + 3)
        end
        ls[i] = l
    end
    task.delay(0.14, function()
        for _, l in ipairs(ls) do
            pcall(function() l:Remove() end)
        end
    end)
end

local function playHit()
    if C.hitSound == "Off" then return end
    local id = "rbxassetid://5464248994"
    if C.hitSound == "Neverlose" then id = "rbxassetid://6326969814"
    elseif C.hitSound == "Gamesense" then id = "rbxassetid://6318318086" end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = C.hitVol / 100
    s.Parent = SoundService
    s:Play()
    task.delay(2, function()
        pcall(function() s:Destroy() end)
    end)
end

local function dmgNum(pos, amt)
    if not C.dmgNums or not drawingOk then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = cam:WorldToViewportPoint(pos)
    if not on then return end
    local t = Drawing.new("Text")
    t.Text = "-" .. tostring(math.floor(amt))
    t.Size = 22
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    t.Color = Color3.fromRGB(255, 100, 100)
    t.Font = 4
    t.Position = Vector2.new(sp.X, sp.Y)
    t.Visible = true
    task.spawn(function()
        for i = 1, 15 do
            task.wait(0.03)
            if t and t.Visible then
                t.Position = Vector2.new(t.Position.X, t.Position.Y - 3)
                t.Transparency = 1 - i / 15
            end
        end
        pcall(function() t:Remove() end)
    end)
end

local function popStreak(txt, col)
    if not C.streakHUD or not drawingOk then return end
    local t = Drawing.new("Text")
    t.Text = txt
    t.Size = 42
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    t.Color = col
    t.Font = 4
    local cam = workspace.CurrentCamera
    if not cam then return end
    t.Position = Vector2.new(cam.ViewportSize.X / 2, 200)
    t.Visible = true
    task.spawn(function()
        for i = 1, 20 do
            task.wait(0.05)
            if t and t.Visible then
                t.Transparency = 1 - (i / 20) * 0.9
                t.Position = Vector2.new(t.Position.X, t.Position.Y - 2)
            end
        end
        pcall(function() t:Remove() end)
    end)
end

-- kill feed
local feedGui, feedFrame, feedList = nil, nil, {}

local function initFeed()
    local pg = lp:WaitForChild("PlayerGui", 10)
    if not pg then return end
    feedGui = Instance.new("ScreenGui")
    feedGui.Name = "ripped_feed"
    feedGui.ResetOnSpawn = false
    feedGui.IgnoreGuiInset = true
    feedGui.DisplayOrder = 90
    feedGui.Parent = pg
    feedFrame = Instance.new("Frame")
    feedFrame.Size = UDim2.new(0, 340, 0, 400)
    feedFrame.Position = UDim2.new(1, -360, 0, 90)
    feedFrame.BackgroundTransparency = 1
    feedFrame.Parent = feedGui
end

local function pushFeed(name, hs)
    if not C.killFeed or not feedFrame then return end
    local e = Instance.new("Frame")
    e.Size = UDim2.new(1, 0, 0, 32)
    e.BackgroundColor3 = Color3.fromRGB(15, 18, 15)
    e.BackgroundTransparency = 0.15
    e.BorderSizePixel = 0
    e.Parent = feedFrame
    Instance.new("UICorner", e).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke", e)
    st.Color = hs and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(160, 125, 230)
    st.Thickness = 1.2
    st.Transparency = 0.2
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = (hs and "hshot · " or "kill · ") .. name
    l.TextColor3 = hs and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(240, 240, 250)
    l.Parent = e

    table.insert(feedList, 1, e)
    for i, x in ipairs(feedList) do
        x.Position = UDim2.new(0, 0, 0, (i - 1) * 36)
    end
    while #feedList > 8 do
        local old = table.remove(feedList)
        if old then old:Destroy() end
    end
    task.spawn(function()
        task.wait(6)
        if e and e.Parent then
            TweenService:Create(e, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
            task.wait(0.4)
            for i, x in ipairs(feedList) do
                if x == e then
                    table.remove(feedList, i)
                    break
                end
            end
            e:Destroy()
            for i, x in ipairs(feedList) do
                x.Position = UDim2.new(0, 0, 0, (i - 1) * 36)
            end
        end
    end)
end

initFeed()

-- ============================ KILL TRACKING ============================
local function hookEnemy(plr, char)
    local h = char and hum(char)
    if not h then return end
    h.Died:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local r = hrp(char)
        if not r then return end
        local sp, on = cam:WorldToViewportPoint(r.Position)
        if not on then return end
        local vp = cam.ViewportSize
        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude
        if d <= 200 and tick() - lastTrig < 0.6 then
            sess.kills = sess.kills + 1
            sess.streak = sess.streak + 1
            if sess.streak > sess.best then sess.best = sess.streak end
            flashHit()
            playHit()
            dmgNum(r.Position, h.MaxHealth)

            local hd = head(char)
            local isHS = false
            if hd then
                local hsp, hon = cam:WorldToViewportPoint(hd.Position)
                if hon and (Vector2.new(hsp.X, hsp.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude < 50 then
                    isHS = true
                end
            end
            pushFeed(plr.Name, isHS)
            local tier = streakTiers[sess.streak]
            if tier then popStreak(tier[1], tier[2]) end
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= lp then
        if p.Character then hookEnemy(p, p.Character) end
        p.CharacterAdded:Connect(function(c) hookEnemy(p, c) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p == lp then return end
    p.CharacterAdded:Connect(function(c) hookEnemy(p, c) end)
end)

local function hookDeath(char)
    local h = char and hum(char)
    if not h then return end
    h.Died:Connect(function()
        sess.deaths = sess.deaths + 1
        sess.streak = 0
    end)
end
if lp.Character then hookDeath(lp.Character) end
lp.CharacterAdded:Connect(hookDeath)

-- ============================ RENDER LOOP ============================
local lastMove, lastWeapon, lastWorld, lastCam, lastAuto = 0, 0, 0, 0, 0
local lastESP, lastSilent = 0, 0

local function renderStep()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local now = tick()

    if fovCircle then
        fovCircle.Radius = fovNow()
        fovCircle.Visible = C.showFov
        fovCircle.Color = C.fovColor
        fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
    end

    pcall(doTrigger, now)

    local silInterval = C.silent and (1 / 30) or (1 / 10)
    if now - lastSilent >= silInterval then
        lastSilent = now
        pcall(doSilent)
    end

    local target = doAim(now)
    if target then
        if fovCircle then fovCircle.Color = Color3.fromRGB(255, 90, 90) end
        if tDot and C.showFov then
            local sp = cam:WorldToViewportPoint(predict(target, C.predLead / 100))
            tDot.Position = Vector2.new(sp.X, sp.Y)
            tDot.Visible = true
        end
    else
        if fovCircle then fovCircle.Color = C.fovColor end
        if tDot then tDot.Visible = false end
    end

    if C.rage then
        local part = getSharedTarget(now)
        if part and math.random() * 100 <= C.rageHit then
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position)
            if C.rageAuto then shoot() end
        end
    end

    if now - lastMove > 0.1 then lastMove = now; pcall(applyMovement) end
    if now - lastWeapon > 3 then lastWeapon = now; pcall(applyWeaponMods) end
    if now - lastWorld > 3 then lastWorld = now; pcall(applyWorld) end
    if now - lastCam > 0.5 then lastCam = now; pcall(applyCam) end
    if now - lastAuto > 0.1 then lastAuto = now; pcall(doAutoplay) end

    local espInterval = 1 / math.max(C.espFps, 10)
    if now - lastESP >= espInterval then
        lastESP = now
        pcall(drawESP)
    end
    pcall(drawXhair)
end

local bound = pcall(function()
    RunService:BindToRenderStep("RippedRender", Enum.RenderPriority.Camera.Value + 1, function()
        pcall(renderStep)
    end)
end)
if not bound then
    RunService.RenderStepped:Connect(function() pcall(renderStep) end)
end

-- ============================ PANIC ============================
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode.Name == C.panicKey then
        C.aim = false; C.silent = false; C.trig = false
        C.esp = false; C.espChams = false; C.rage = false
        if fovCircle then fovCircle.Visible = false end
        if tDot then tDot.Visible = false end
        for _, e in pairs(espPool) do hideESP(e) end
        for _, h in pairs(chams) do h.Enabled = false end
        Library:Notify("panic off", 3)
    end
end)

lp.CharacterAdded:Connect(function()
    if fovCircle then fovCircle.Visible = C.showFov end
    if tDot then tDot.Visible = false end
    visCache = {}
end)

-- ============================ UI ============================

local aimGroup = Tabs.main:AddLeftGroupbox("Aimbot")
aimGroup:AddDropdown("aimMode", {
    Text = "Aimbot",
    Values = { "None", "Camera", "Mouse", "Silent" },
    Default = "None",
    Callback = function(v)
        C.aim = (v == "Camera" or v == "Mouse")
        C.silent = (v == "Silent")
        C.lockMethod = (v == "Mouse") and "Mouse" or "Camera"
    end,
})
-- AddKeybind is a Linoria call Obsidian dropped, and a key control here is a
-- key picker hung on a row: AddLabel gives the row its text, AddKeyPicker puts
-- the little key box beside it. This is the pair the library's own docs use, and
-- the assert inside AddKeyPicker is what settles it - a picker in "Press" mode
-- is only accepted on a Label, a Button or a SubButton, and nothing else carries
-- the method at all. The picker reports a rebind through ChangedCallback and
-- hands over the KeyCode itself, so the config keeps its Name - the same string
-- Enum.KeyCode[...] and Enum.UserInputType[...] are looked up with below.
local aimKey = aimGroup:AddLabel("Aim Key")
aimKey:AddKeyPicker("aimKey", {
    Text = "Aim Key", Default = "E", Mode = "Press",
    ChangedCallback = function(Key) if Key then C.aimKey = Key.Name end end,
})
aimGroup:AddDropdown("aimKeyMode", {
    Text = "Key Mode",
    Values = { "Hold", "Toggle", "AlwaysOn" },
    Default = "Hold",
    Callback = function(v) C.aimKeyMode = v end,
})
aimGroup:AddSlider("smooth", {
    Text = "Smoothness", Min = 1, Max = 100, Default = 60, Rounding = 1, Suffix = "/100",
    Callback = function(v) C.smooth = v end,
})
aimGroup:AddSlider("silentChance", {
    Text = "Silent Aim Hit Chance", Min = 1, Max = 100, Default = 100, Rounding = 1, Suffix = "/100",
    Callback = function(v) C.silentChance = v end,
})
aimGroup:AddSlider("fov", {
    Text = "FOV Size", Min = 1, Max = 500, Default = 150, Rounding = 1, Suffix = "/500",
    Callback = function(v) C.fov = v end,
})
aimGroup:AddDropdown("aimPart", {
    Text = "Hit Part",
    Values = { "Head", "Torso", "Nearest" },
    Default = "Head",
    Callback = function(v) C.aimPart = v end,
})
aimGroup:AddToggle("showFov", {
    Text = "Show FOV Circle", Default = false,
    Callback = function(v)
        C.showFov = v
        if fovCircle then fovCircle.Visible = v end
    end,
})
aimGroup:AddToggle("scopedOnly", {
    Text = "Only While Scoped", Default = false,
    Callback = function(v) C.scopedOnly = v end,
})
aimGroup:AddToggle("teamCheck", {
    Text = "Team Check", Default = true,
    Callback = function(v) C.teamCheck = v end,
})
aimGroup:AddToggle("wallCheck", {
    Text = "Wall Check", Default = true,
    Callback = function(v) C.wallCheck = v end,
})

local predGroup = Tabs.main:AddLeftGroupbox("Prediction")
predGroup:AddDropdown("predMode", {
    Text = "Mode",
    Values = { "Off", "Simple", "Advanced" },
    Default = "Advanced",
    Callback = function(v) C.predMode = v end,
})
predGroup:AddSlider("predLead", {
    Text = "Lead Time", Min = 0, Max = 60, Default = 12, Rounding = 1, Suffix = "%",
    Callback = function(v) C.predLead = v end,
})
predGroup:AddSlider("predVel", {
    Text = "Velocity Multiplier", Min = 10, Max = 300, Default = 100, Rounding = 1, Suffix = "%",
    Callback = function(v) C.predVel = v end,
})

local targetGroup = Tabs.main:AddLeftGroupbox("Target Selection")
targetGroup:AddDropdown("priority", {
    Text = "Priority",
    Values = { "Crosshair", "Mouse", "Distance", "Health" },
    Default = "Crosshair",
    Callback = function(v) C.priority = v end,
})
targetGroup:AddSlider("hpFilter", {
    Text = "Only Below HP%", Min = 0, Max = 100, Default = 0, Rounding = 1,
    Callback = function(v) C.hpFilter = v end,
})
targetGroup:AddInput("ignoreList", {
    Text = "Ignore IDs",
    Default = "",
    Placeholder = "12345,67890",
    Callback = function(v)
        local l = {}
        for id in string.gmatch(v, "(%d+)") do
            l[#l + 1] = tonumber(id)
        end
        C.ignore = l
    end,
})

local wmGroup = Tabs.main:AddRightGroupbox("Weapon Mods")
wmGroup:AddToggle("noSpread", { Text = "No Bullet Spread", Default = false, Callback = function(v) C.noSpread = v end })
wmGroup:AddToggle("rapidFire", { Text = "Rapid Fire", Default = false, Callback = function(v) C.rapidFire = v end })
wmGroup:AddToggle("noScythe", { Text = "No Scythe Cooldown", Default = false, Callback = function(v) C.noScythe = v end })
wmGroup:AddToggle("noRecoil", { Text = "No Recoil", Default = true, Callback = function(v) C.noRecoil = v end })
wmGroup:AddToggle("fastReload", { Text = "Fast Reload", Default = false, Callback = function(v) C.fastReload = v end })
wmGroup:AddToggle("infAmmo", { Text = "Infinite Ammo", Default = false, Callback = function(v) C.infAmmo = v end })

local extraGroup = Tabs.main:AddRightGroupbox("Extra")
extraGroup:AddToggle("skins", { Text = "Unlock Skins", Default = false, Callback = function(v) C.unSkins = v end })
extraGroup:AddToggle("wraps", { Text = "Unlock Wraps", Default = false, Callback = function(v) C.unWraps = v end })
extraGroup:AddToggle("charms", { Text = "Unlock Charms", Default = false, Callback = function(v) C.unCharms = v end })
extraGroup:AddToggle("emotes", { Text = "Unlock Emotes", Default = false, Callback = function(v) C.unEmotes = v end })
extraGroup:AddToggle("finishers", { Text = "Unlock Finishers", Default = false, Callback = function(v) C.unFinishers = v end })
extraGroup:AddToggle("kfx", { Text = "Unlock Kill Effects", Default = false, Callback = function(v) C.unKillFX = v end })

local rageGroup = Tabs.main:AddRightGroupbox("Ragebot")
rageGroup:AddToggle("rage", { Text = "Ragebot", Default = false, Callback = function(v) C.rage = v end })
rageGroup:AddToggle("rageAuto", { Text = "Auto Shoot", Default = false, Callback = function(v) C.rageAuto = v end })
rageGroup:AddSlider("rageHit", { Text = "Hit Chance", Min = 0, Max = 100, Default = 100, Rounding = 1, Suffix = "%", Callback = function(v) C.rageHit = v end })

local trigGroup = Tabs.main:AddRightGroupbox("Triggerbot")
trigGroup:AddToggle("trig", { Text = "Triggerbot", Default = false, Callback = function(v) C.trig = v end })
-- "MB2" is the name a key picker knows a mouse button by; it reports the pick
-- back as Enum.UserInputType.MouseButton2, whose Name is the string the trigger
-- below looks up with Enum.UserInputType[...].
local trigKey = trigGroup:AddLabel("Trigger Key")
trigKey:AddKeyPicker("trigKey", { Text = "Trigger Key", Default = "MB2", Mode = "Press", ChangedCallback = function(Key) if Key then C.trigKey = Key.Name end end })
trigGroup:AddSlider("trigFov", { Text = "Trigger FOV", Min = 5, Max = 300, Default = 30, Rounding = 1, Suffix = "px", Callback = function(v) C.trigFov = v end })
trigGroup:AddSlider("trigDelay", { Text = "Base Delay", Min = 1, Max = 100, Default = 2, Rounding = 1, Suffix = "cs", Callback = function(v) C.trigDelay = v end })
trigGroup:AddSlider("trigRand", { Text = "Delay Random", Min = 0, Max = 50, Default = 1, Rounding = 1, Suffix = "cs", Callback = function(v) C.trigRand = v end })
trigGroup:AddToggle("trigAuto", { Text = "Auto Click", Default = true, Callback = function(v) C.trigAuto = v end })
trigGroup:AddToggle("trigTeam", { Text = "Team Check", Default = true, Callback = function(v) C.trigTeam = v end })
trigGroup:AddToggle("trigHead", { Text = "Head Only", Default = false, Callback = function(v) C.trigHead = v end })

local espGroup = Tabs.visual:AddLeftGroupbox("ESP")
espGroup:AddToggle("esp", { Text = "Enable ESP", Default = false, Callback = function(v) C.esp = v end })
espGroup:AddToggle("espHL", { Text = "Highlight", Default = false, Callback = function(v) C.espHL = v end })
espGroup:AddToggle("espBox", { Text = "Box", Default = false, Callback = function(v) C.espBox = v end })
espGroup:AddToggle("espNames", { Text = "Names", Default = false, Callback = function(v) C.espNames = v end })
espGroup:AddToggle("espHp", { Text = "Health Bar", Default = false, Callback = function(v) C.espHp = v end })
espGroup:AddToggle("espHpText", { Text = "Health Text", Default = false, Callback = function(v) C.espHpText = v end })
espGroup:AddToggle("espDist", { Text = "Distance", Default = false, Callback = function(v) C.espDist = v end })
espGroup:AddToggle("espLook", { Text = "Look Direction", Default = false, Callback = function(v) C.espLook = v end })
espGroup:AddToggle("espSkel", { Text = "Skeleton", Default = false, Callback = function(v) C.espSkel = v end })
espGroup:AddToggle("espTeammates", { Text = "Show Teammates", Default = false, Callback = function(v) C.espTeammates = v end })
espGroup:AddToggle("espDot", { Text = "Head Dot", Default = false, Callback = function(v) C.espDot = v end })
espGroup:AddToggle("espTracers", { Text = "Tracers", Default = false, Callback = function(v) C.espTracers = v end })
espGroup:AddSlider("espMax", { Text = "Max Distance", Min = 100, Max = 1000, Default = 500, Rounding = 1, Suffix = "/1000", Callback = function(v) C.espMax = v end })
espGroup:AddSlider("espText", { Text = "Text Size", Min = 1, Max = 24, Default = 13, Rounding = 1, Suffix = "/24", Callback = function(v) C.espText = v end })
espGroup:AddSlider("espFps", { Text = "Refresh Rate", Min = 10, Max = 60, Default = 30, Rounding = 1, Suffix = " Hz", Callback = function(v) C.espFps = v end })

local colGroup = Tabs.visual:AddRightGroupbox("ESP Colors")
-- A colour picker is an addon in this revision too, not a groupbox control: the
-- same label-then-attach pair as the key pickers above, where the label carries
-- the row's text and the picker draws the swatch beside it.
local colVis = colGroup:AddLabel("Visible Color")
colVis:AddColorPicker("colVis", { Default = Color3.fromRGB(60, 255, 60), Callback = function(c) C.colVis = c end })
local colHid = colGroup:AddLabel("Hidden Color")
colHid:AddColorPicker("colHid", { Default = Color3.fromRGB(255, 60, 60), Callback = function(c) C.colHid = c end })
local colTeam = colGroup:AddLabel("Teammate Color")
colTeam:AddColorPicker("colTeam", { Default = Color3.fromRGB(60, 130, 255), Callback = function(c) C.colTeam = c end })

local chamsGroup = Tabs.visual:AddRightGroupbox("Chams")
chamsGroup:AddToggle("chams", { Text = "Enable Chams", Default = false, Callback = function(v) C.espChams = v end })
chamsGroup:AddSlider("chamsFill", { Text = "Fill Alpha", Min = 0, Max = 100, Default = 50, Rounding = 1, Suffix = "%", Callback = function(v) C.chamsFill = v / 100 end })
chamsGroup:AddSlider("chamsOutline", { Text = "Outline Alpha", Min = 0, Max = 100, Default = 0, Rounding = 1, Suffix = "%", Callback = function(v) C.chamsOutline = v / 100 end })

local removeGroup = Tabs.visual:AddRightGroupbox("Overlay Removals")
removeGroup:AddToggle("noScopeOv", { Text = "No Scope Overlay", Default = false, Callback = function(v) C.noScopeOv = v end })
removeGroup:AddToggle("noScopeRet", { Text = "No Scope Reticle", Default = false, Callback = function(v) C.noScopeRet = v end })
removeGroup:AddToggle("noTracers", { Text = "No Gun Tracers", Default = false, Callback = function(v) C.noTracers = v end })
removeGroup:AddToggle("noMuzzle", { Text = "No Muzzle Flash", Default = false, Callback = function(v) C.noMuzzle = v end })
removeGroup:AddToggle("noHitmark", { Text = "No Hitmarker", Default = false, Callback = function(v) C.noHitmark = v end })
removeGroup:AddToggle("noFlash", { Text = "No Flashbang", Default = false, Callback = function(v) C.noFlash = v end })
removeGroup:AddToggle("noBurn", { Text = "No Burn Effect", Default = false, Callback = function(v) C.noBurn = v end })
removeGroup:AddToggle("noADS", { Text = "No ADS Vignette", Default = false, Callback = function(v) C.noADS = v end })

local vmGroup = Tabs.visual:AddLeftGroupbox("Viewmodel")
vmGroup:AddToggle("noShootAnim", { Text = "No Shoot Animation", Default = false, Callback = function(v) C.noShootAnim = v end })
vmGroup:AddToggle("noSprintAnim", { Text = "No Sprint Animation", Default = false, Callback = function(v) C.noSprintAnim = v end })
vmGroup:AddToggle("noSway", { Text = "No Sway", Default = false, Callback = function(v) C.noSway = v end })
vmGroup:AddToggle("noBob", { Text = "No Bob", Default = false, Callback = function(v) C.noBob = v end })

local xGroup = Tabs.visual:AddLeftGroupbox("Crosshair")
xGroup:AddToggle("xhair", { Text = "Custom Crosshair", Default = false, Callback = function(v) C.xhair = v end })
xGroup:AddSlider("xhairSize", { Text = "Size", Min = 2, Max = 30, Default = 8, Rounding = 1, Callback = function(v) C.xhairSize = v end })
xGroup:AddSlider("xhairThick", { Text = "Thickness", Min = 1, Max = 6, Default = 2, Rounding = 1, Callback = function(v) C.xhairThick = v end })
xGroup:AddSlider("xhairGap", { Text = "Gap", Min = 0, Max = 20, Default = 3, Rounding = 1, Callback = function(v) C.xhairGap = v end })
local xhairColor = xGroup:AddLabel("Color")
xhairColor:AddColorPicker("xhairColor", { Default = Color3.fromRGB(0, 255, 170), Callback = function(c) C.xhairColor = c end })

local fxGroup = Tabs.visual:AddLeftGroupbox("Hit FX")
fxGroup:AddToggle("hitmark", { Text = "Hit Marker", Default = true, Callback = function(v) C.hitmark = v end })
fxGroup:AddDropdown("hitSound", { Text = "Hit Sound", Values = { "Skeet", "Neverlose", "Gamesense", "Bell", "Off" }, Default = "Skeet", Callback = function(v) C.hitSound = v end })
fxGroup:AddSlider("hitVol", { Text = "Hit Volume", Min = 0, Max = 100, Default = 50, Rounding = 1, Suffix = "%", Callback = function(v) C.hitVol = v end })
fxGroup:AddToggle("dmgNums", { Text = "Damage Numbers", Default = true, Callback = function(v) C.dmgNums = v end })
fxGroup:AddToggle("killFeed", { Text = "Kill Feed", Default = true, Callback = function(v) C.killFeed = v end })
fxGroup:AddToggle("streakHUD", { Text = "Streak HUD", Default = true, Callback = function(v) C.streakHUD = v end })

local mGroup = Tabs.move:AddLeftGroupbox("Movement")
mGroup:AddToggle("speed", { Text = "Speed Hack", Default = false, Callback = function(v) C.speed = v end })
mGroup:AddSlider("speedVal", { Text = "Speed", Min = 16, Max = 200, Default = 16, Rounding = 1, Callback = function(v) C.speedVal = v end })
mGroup:AddToggle("jump", { Text = "Jump Power", Default = false, Callback = function(v) C.jump = v end })
mGroup:AddSlider("jumpVal", { Text = "Jump", Min = 50, Max = 200, Default = 50, Rounding = 1, Callback = function(v) C.jumpVal = v end })
mGroup:AddToggle("fly", { Text = "Fly", Default = false, Callback = function(v) C.fly = v end })
mGroup:AddSlider("flySpeed", { Text = "Fly Speed", Min = 10, Max = 200, Default = 50, Rounding = 1, Callback = function(v) C.flySpeed = v end })

local mExtra = Tabs.move:AddRightGroupbox("Extras")
mExtra:AddToggle("noclip", { Text = "Noclip", Default = false, Callback = function(v) C.noclip = v end })
mExtra:AddToggle("infJump", { Text = "Infinite Jump", Default = false, Callback = function(v) C.infJump = v end })
mExtra:AddToggle("bhop", { Text = "Bunny Hop", Default = false, Callback = function(v) C.bhop = v end })
mExtra:AddToggle("fullbright", { Text = "Fullbright", Default = false, Callback = function(v) C.fullbright = v end })
mExtra:AddToggle("sprint", { Text = "Force Sprint", Default = false, Callback = function(v) C.sprint = v end })
mExtra:AddSlider("sprintVal", { Text = "Sprint Speed", Min = 16, Max = 100, Default = 32, Rounding = 1, Callback = function(v) C.sprintVal = v end })

local aGroup = Tabs.auto:AddLeftGroupbox("Autoplay")
aGroup:AddToggle("autoplay", { Text = "Enable Autoplay", Default = false, Callback = function(v) C.autoplay = v end })
aGroup:AddSlider("autoplayDist", { Text = "Auto Distance", Min = 5, Max = 50, Default = 18, Rounding = 1, Suffix = "st", Callback = function(v) C.autoplayDist = v end })
aGroup:AddToggle("autoLoadout", { Text = "Auto Loadout", Default = true, Callback = function(v) C.autoLoadout = v end })

local lGroup = Tabs.auto:AddRightGroupbox("Loadout")
lGroup:AddDropdown("primary", { Text = "Primary", Values = { "AK-47", "M4A1", "FAMAS", "AUG", "SCAR-H", "Sniper", "AWP", "Heavy Sniper", "SPAS-12" }, Default = "AK-47", Callback = function(v) C.primary = v end })
lGroup:AddDropdown("secondary", { Text = "Secondary", Values = { "Deagle", "Revolver", "Pistol", "SMG", "Uzi", "MP5", "Tec-9" }, Default = "Deagle", Callback = function(v) C.secondary = v end })
lGroup:AddDropdown("melee", { Text = "Melee", Values = { "Karambit", "Butterfly", "Bayonet", "M9", "Flip", "Tactical" }, Default = "Karambit", Callback = function(v) C.melee = v end })
lGroup:AddDropdown("util1", { Text = "Utility 1", Values = { "Frag Grenade", "Flashbang", "Smoke", "Molotov", "Incendiary", "None" }, Default = "Frag Grenade", Callback = function(v) C.util1 = v end })
lGroup:AddDropdown("util2", { Text = "Utility 2", Values = { "Frag Grenade", "Flashbang", "Smoke", "Molotov", "Incendiary", "None" }, Default = "Flashbang", Callback = function(v) C.util2 = v end })

local vGroup = Tabs.auto:AddLeftGroupbox("Map & Ban")
vGroup:AddToggle("autoVote", { Text = "Auto Vote Maps", Default = true, Callback = function(v) C.autoVote = v end })
vGroup:AddInput("mapList", { Text = "Map Priority", Default = "Arena, Onyx, Crossroads", Placeholder = "comma separated", Callback = function(v)
    local l = {}
    for m in string.gmatch(v, "([^,]+)") do
        l[#l + 1] = m:match("^%s*(.-)%s*$")
    end
    C.mapList = l
end })
vGroup:AddToggle("autoBan", { Text = "Auto Ban Weapons", Default = true, Callback = function(v) C.autoBan = v end })
vGroup:AddInput("banList", { Text = "Ban Priority", Default = "Grenade Launcher, Minigun, RPG", Placeholder = "comma separated", Callback = function(v)
    local l = {}
    for m in string.gmatch(v, "([^,]+)") do
        l[#l + 1] = m:match("^%s*(.-)%s*$")
    end
    C.banList = l
end })

local qGroup = Tabs.auto:AddRightGroupbox("Queue")
qGroup:AddToggle("autoQueue", { Text = "Auto Queue", Default = false, Callback = function(v) C.autoQueue = v end })
qGroup:AddDropdown("queueMode", { Text = "Mode", Values = { "Ranked", "Casual", "1v1", "2v2", "3v3", "4v4", "FFA" }, Default = "Ranked", Callback = function(v) C.queueMode = v end })
qGroup:AddToggle("autoAccept", { Text = "Auto Accept", Default = true, Callback = function(v) C.autoAccept = v end })

local sGroup = Tabs.sound:AddLeftGroupbox("Sounds")
sGroup:AddDropdown("hitSound2", { Text = "Hit Sound", Values = { "Skeet", "Neverlose", "Gamesense", "Bell", "Off" }, Default = "Skeet", Callback = function(v) C.hitSound = v end })
sGroup:AddSlider("soundVol", { Text = "Volume", Min = 0, Max = 100, Default = 50, Rounding = 1, Suffix = "%", Callback = function(v) C.hitVol = v end })

local spGroup = Tabs.spoof:AddLeftGroupbox("Spoof")
spGroup:AddToggle("spoofFps", { Text = "Spoof FPS", Default = false, Callback = function(v) C.spoofFps = v end })
spGroup:AddToggle("spoofPing", { Text = "Spoof Ping", Default = false, Callback = function(v) C.spoofPing = v end })
spGroup:AddToggle("fakeLag", { Text = "Fake Lag", Default = false, Callback = function(v) C.fakeLag = v end })
spGroup:AddToggle("hwid", { Text = "HWID Spoofer", Default = false, Callback = function(v) C.hwid = v end })

local wGroup = Tabs.world:AddLeftGroupbox("World")
wGroup:AddToggle("noFog", { Text = "No Fog", Default = true, Callback = function(v) C.noFog = v end })
wGroup:AddToggle("fullbright2", { Text = "Fullbright", Default = false, Callback = function(v) C.fullbright = v end })
wGroup:AddToggle("gravity", { Text = "Modify Gravity", Default = false, Callback = function(v) C.gravity = v end })
wGroup:AddSlider("gravityVal", { Text = "Gravity", Min = 0, Max = 500, Default = 196, Rounding = 1, Callback = function(v) C.gravityVal = v end })
wGroup:AddToggle("ambient", { Text = "Custom Ambient", Default = false, Callback = function(v) C.ambient = v end })
local ambientCol = wGroup:AddLabel("Ambient Color")
ambientCol:AddColorPicker("ambientCol", { Default = Color3.fromRGB(150, 150, 150), Callback = function(c) C.ambientCol = c end })

local skGroup = Tabs.world:AddRightGroupbox("Skybox")
skGroup:AddToggle("skybox", { Text = "Skybox Changer", Default = false, Callback = function(v) C.skybox = v end })
skGroup:AddInput("skyboxId", { Text = "Skybox ID", Default = "", Placeholder = "asset id", Callback = function(v) C.skyboxId = v end })

local cGroup = Tabs.world:AddRightGroupbox("Camera")
cGroup:AddToggle("fovChanger", { Text = "FOV Changer", Default = false, Callback = function(v) C.fovChanger = v end })
cGroup:AddSlider("worldFov", { Text = "World FOV", Min = 50, Max = 120, Default = 90, Rounding = 1, Callback = function(v) C.worldFov = v end })
cGroup:AddToggle("camOffset", { Text = "Camera Offset", Default = false, Callback = function(v) C.camOffset = v end })
cGroup:AddSlider("camX", { Text = "Offset X", Min = -10, Max = 10, Default = 0, Rounding = 1, Callback = function(v) C.camX = v end })
cGroup:AddSlider("camY", { Text = "Offset Y", Min = -10, Max = 10, Default = 0, Rounding = 1, Callback = function(v) C.camY = v end })
cGroup:AddSlider("camZ", { Text = "Offset Z", Min = -10, Max = 10, Default = 0, Rounding = 1, Callback = function(v) C.camZ = v end })

local cfgGroup = Tabs.cfg:AddLeftGroupbox("Script")
local panicKey = cfgGroup:AddLabel("Panic Key")
panicKey:AddKeyPicker("panicKey", { Text = "Panic Key", Default = "Delete", Mode = "Press", ChangedCallback = function(Key) if Key then C.panicKey = Key.Name end end })
cfgGroup:AddToggle("watermark", { Text = "Watermark", Default = true, Callback = function(v) C.watermark = v end })
cfgGroup:AddToggle("legit", { Text = "Legit Mode", Default = false, Callback = function(v) C.legit = v end })
cfgGroup:AddSlider("legitFov", { Text = "Legit FOV Cap", Min = 10, Max = 180, Default = 60, Rounding = 1, Callback = function(v) C.legitFov = v end })
cfgGroup:AddSlider("legitSmooth", { Text = "Legit Smooth Cap", Min = 5, Max = 100, Default = 18, Rounding = 1, Suffix = "%", Callback = function(v) C.legitSmooth = v end })
cfgGroup:AddButton({ Text = "Unload", Func = function()
    if fovCircle then fovCircle:Remove() end
    if tDot then tDot:Remove() end
    if wm then wm:Remove() end
    for _, l in ipairs(xhair) do l:Remove() end
    for _, e in pairs(espPool) do
        for _, k in ipairs({"box", "name", "dist", "hp", "hpBg", "hpText", "tracer", "dot", "look"}) do
            if e[k] then e[k]:Remove() end
        end
        for _, b in ipairs(e.bones) do b:Remove() end
    end
    for _, h in pairs(chams) do
        if h.Parent then h:Destroy() end
    end
    if feedGui then feedGui:Destroy() end
    Library:Unload()
end })
cfgGroup:AddButton({ Text = "Reset Key", Func = function() genv.ripped_unlocked = false end })

local statGroup = Tabs.cfg:AddRightGroupbox("Session")
statGroup:AddButton({ Text = "Show Stats", Func = function()
    Library:Notify(string.format("%d kills · %d deaths · best streak %d · %dm",
        sess.kills, sess.deaths, sess.best,
        math.floor((tick() - sess.start) / 60)), 8)
end })
statGroup:AddButton({ Text = "Reset Session", Func = function()
    sess.kills, sess.deaths, sess.streak, sess.best = 0, 0, 0, 0
    Library:Notify("reset", 3)
end })

if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("Ripped")
    ThemeManager:ApplyToTab(Tabs.cfg)
end
if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("Ripped")
    SaveManager:BuildConfigSection(Tabs.cfg)
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end

-- ============================ WATERMARK ============================
task.spawn(function()
    while true do
        if wm then
            if C.watermark then
                local ping = math.floor((lp:GetNetworkPing() or 0) * 1000)
                wm.Text = "ripped.win | " .. lp.Name .. " | " .. ping .. "ms"
                wm.Position = Vector2.new(15, 15)
                wm.Visible = true
            else
                wm.Visible = false
            end
        end
        task.wait(0.5)
    end
end)

Library:Notify("ripped.win loaded", 4)