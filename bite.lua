-- VoidHub | Bite By Night
-- credits: vonplayz_real

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

local repo = "https://raw.githubusercontent.com/VoidDeveloper67/VoidHub-Library/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Config = {
    StepDistance = 2.5,
    StepDelay = 0.15,
    UseVelocitySpoof = true,
    NoclipDuringMove = true,
    SolveDistance = 15,
    SpeedHackValue = 50,
    FlySpeed = 80,
    PingThreshold = 200,
}

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text or "",
            Duration = 3,
        })
    end)
end

local function getPing()
    local ping = 0
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ping
end

local OriginalLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local RemovedEffects = {}

local function setGFXLevel(level)
    pcall(function() local gs = UserSettings().GameSettings; if gs then gs.SavedQualityLevel = level end end)
    pcall(function() if settings and settings().Rendering then settings().Rendering.QualityLevel = level end end)
end

local function stripPostFX(enable)
    if enable then
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") or child:IsA("Sky") or child:IsA("Atmosphere") or
               child:IsA("BloomEffect") or child:IsA("BlurEffect") or child:IsA("ColorCorrectionEffect") or
               child:IsA("DepthOfFieldEffect") or child:IsA("SunRaysEffect") then
                child.Parent = nil
                table.insert(RemovedEffects, child)
            end
        end
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                for _, child in ipairs(cam:GetChildren()) do
                    if child:IsA("PostEffect") then child.Parent = nil; table.insert(RemovedEffects, child) end
                end
            end
        end)
    else
        for _, fx in ipairs(RemovedEffects) do pcall(function() fx.Parent = Lighting end) end
        RemovedEffects = {}
    end
end

local function disableEffects(enable)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or
           v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = not enable
        end
    end
end

local IsMoving = false
local MoveConnections = {}

local function stopMovement()
    IsMoving = false
    for _, conn in ipairs(MoveConnections) do pcall(function() conn:Disconnect() end) end
    MoveConnections = {}
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
    end
end

local function ultraSafeMoveTo(targetPos, onComplete)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    stopMovement()
    IsMoving = true
    local startPos = hrp.Position
    local distance = (targetPos - startPos).Magnitude
    local steps = math.max(math.ceil(distance / Config.StepDistance), 1)
    local currentStep = 0
    if Config.NoclipDuringMove then
        table.insert(MoveConnections, RunService.Stepped:Connect(function()
            if not IsMoving then return end
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end))
    end
    if Config.UseVelocitySpoof then
        table.insert(MoveConnections, RunService.Heartbeat:Connect(function()
            if not IsMoving then return end
            local dir = (targetPos - hrp.Position).Unit
            hrp.AssemblyLinearVelocity = dir * math.random(10, 20) + Vector3.new(math.random(-3,3), math.random(-2,2), math.random(-3,3))
        end))
    end
    local function doStep()
        if not IsMoving then stopMovement(); return end
        currentStep = currentStep + 1
        if currentStep > steps then
            pcall(function() hrp.CFrame = CFrame.new(targetPos); hrp.AssemblyLinearVelocity = Vector3.zero end)
            stopMovement()
            if onComplete then onComplete() end
            return
        end
        local alpha = currentStep / steps
        local newPos = startPos:Lerp(targetPos, alpha)
        local jitter = Vector3.new(math.random(-5,5)/20, math.random(-3,3)/20, math.random(-5,5)/20)
        pcall(function() hrp.CFrame = CFrame.new(newPos + jitter) end)
        task.delay(Config.StepDelay, doStep)
    end
    doStep()
end

local function findGenerators()
    local generators = {}
    pcall(function()
        local map = workspace.MAPS:FindFirstChild("GAME MAP")
        if map then
            local gensFolder = map:FindFirstChild("Generators")
            if gensFolder then
                for _, v in ipairs(gensFolder:GetChildren()) do if v:IsA("Model") then table.insert(generators, v) end end
            end
        end
    end)
    if #generators == 0 then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Generator" then table.insert(generators, v) end
        end
    end
    return generators
end

local function getGenPrimaryPart(model)
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("MeshPart") and p.Name:match("^Cube") then return p end
    end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function isGenDone(model)
    local prog = model:GetAttribute("Progress") or model:GetAttribute("Charge") or model:GetAttribute("Value")
    if prog and prog >= 100 then return true end
    if model:GetAttribute("Done") or model:GetAttribute("Complete") or model:GetAttribute("Completed") then return true end
    local hl = model:FindFirstChildOfClass("Highlight")
    if hl and not hl.Enabled then return true end
    return false
end

local function solveGenerator(model)
    pcall(function()
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Enabled then
                v.HoldDuration = 0
                v.MaxActivationDistance = 100
                fireproximityprompt(v)
            end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local gg = pg:FindFirstChild("Gen") or pg:FindFirstChild("Generator")
            if gg then
                local mf = gg:FindFirstChild("GeneratorMain") or gg:FindFirstChild("Main") or gg:FindFirstChild("Frame")
                if mf then
                    local ev = mf:FindFirstChild("Event") or mf:FindFirstChild("RemoteEvent")
                    if ev and ev:IsA("RemoteEvent") then ev:FireServer(true) end
                    for _, btn in ipairs(mf:GetDescendants()) do
                        if btn:IsA("TextButton") or btn:IsA("ImageButton") then pcall(function() btn.MouseButton1Click:Fire() end) end
                    end
                end
            end
        end
    end)
end

local pp = Instance.new("Part")
pp.Name = "VH_SafeZone"
pp.Size = Vector3.new(50, 2, 50)
pp.Position = Vector3.new(0, 1000, 0)
pp.Anchored = true
pp.CanCollide = true
pp.Material = Enum.Material.ForceField
pp.Transparency = 0.3
pp.Parent = workspace

local ESP = { highlights = {}, connections = {}, labels = {}, distanceLabels = {}, espFolder = nil, genStatus = {} }

local function getESPFolder()
    if not ESP.espFolder or not ESP.espFolder.Parent then
        ESP.espFolder = Instance.new("Folder")
        ESP.espFolder.Name = "VH_ESP"
        pcall(function() ESP.espFolder.Parent = CoreGui end)
    end
    return ESP.espFolder
end

local function espRemove(model)
    if ESP.highlights[model] then ESP.highlights[model]:Destroy(); ESP.highlights[model] = nil end
    if ESP.labels[model] then ESP.labels[model]:Destroy(); ESP.labels[model] = nil end
    if ESP.distanceLabels[model] then ESP.distanceLabels[model] = nil end
    ESP.genStatus[model] = nil
end

local function espDisconnect(name)
    if ESP.connections[name] then ESP.connections[name]:Disconnect(); ESP.connections[name] = nil end
end

local function createESPBillboard(model, playerName, textColor)
    local folder = getESPFolder()
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 160, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.MaxDistance = 1000
    billboard.Adornee = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    billboard.Parent = folder
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName or model.Name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = textColor
    nameLabel.TextStrokeTransparency = 0.6
    nameLabel.Parent = billboard
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 0, 0, 22)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.Font = Enum.Font.GothamSemibold
    distLabel.TextSize = 12
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeTransparency = 0.6
    distLabel.Parent = billboard
    ESP.labels[model] = billboard
    ESP.distanceLabels[model] = distLabel
end

local function startDistanceUpdater()
    if ESP.connections["distanceUpdater"] then return end
    ESP.connections["distanceUpdater"] = RunService.RenderStepped:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for model, distLabel in pairs(ESP.distanceLabels) do
                if model and model.Parent and distLabel and distLabel.Parent then
                    local t = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                    if t then distLabel.Text = string.format("%dm", math.floor((hrp.Position - t.Position).Magnitude)) end
                end
            end
        end)
    end)
end

local function stopDistanceUpdater()
    espDisconnect("distanceUpdater")
end

local function makeESP(model, fillColor, outlineColor, tag, playerName)
    if ESP.highlights[model] then return end
    local h = Instance.new("Highlight")
    h.FillColor = fillColor
    h.OutlineColor = outlineColor
    h.FillTransparency = 0.6
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = model
    h:SetAttribute("VH_Tag", tag)
    pcall(function() h.Parent = CoreGui end)
    ESP.highlights[model] = h
    createESPBillboard(model, playerName or model.Name, outlineColor)
end

local function updateGenESPColor(model)
    local highlight = ESP.highlights[model]
    if not highlight then return end
    local isDone = isGenDone(model)
    if isDone ~= ESP.genStatus[model] then
        ESP.genStatus[model] = isDone
        highlight.FillColor = isDone and Color3.fromRGB(50, 255, 100) or Color3.fromRGB(255, 200, 50)
        highlight.OutlineColor = isDone and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 230, 100)
        if ESP.labels[model] then
            local nl = ESP.labels[model]:FindFirstChildOfClass("TextLabel")
            if nl then nl.TextColor3 = highlight.OutlineColor end
        end
    end
end

local Window = Library:CreateWindow({
    Title = "VoidHub",
    Footer = "Bite By Night | vonplayz_real",
    Icon = 126161789124643,
    NotifySide = "Right",
    ShowCustomCursor = true,
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Survivor   = Window:AddTab("Survivor",  "user"),
    Killer     = Window:AddTab("Killer",    "sword"),
    Teleport   = Window:AddTab("Teleport",  "map-pin"),
    Movement   = Window:AddTab("Movement",  "move"),
    Visual     = Window:AddTab("Visual",    "eye"),
    Misc       = Window:AddTab("Misc",      "wrench"),
    Info       = Window:AddTab("Info",      "info"),
}

local SurvLeft   = Tabs.Survivor:AddLeftGroupbox("Tasks")
local SurvRight  = Tabs.Survivor:AddRightGroupbox("Survival")
local KillLeft   = Tabs.Killer:AddLeftGroupbox("Teleport Kill")
local TpLeft     = Tabs.Teleport:AddLeftGroupbox("Teleport")
local TpRight    = Tabs.Teleport:AddRightGroupbox("Move Settings")
local MoveLeft   = Tabs.Movement:AddLeftGroupbox("Movement")
local MoveRight  = Tabs.Movement:AddRightGroupbox("Camera")
local VisLeft    = Tabs.Visual:AddLeftGroupbox("ESP")
local MiscLeft   = Tabs.Misc:AddLeftGroupbox("Tools")
local MiscRight  = Tabs.Misc:AddRightGroupbox("Performance")
local InfoLeft   = Tabs.Info:AddLeftGroupbox("Stats")
local InfoRight  = Tabs.Info:AddRightGroupbox("Discord")

-- ================================================
-- SURVIVOR TAB — Tasks
-- ================================================

SurvLeft:AddToggle("InstaPrompt", {
    Text = "Insta Prompt",
    Tooltip = "Sets all proximity prompt hold times to 0",
    Default = true,
})

local instaPromptConn = nil
Toggles.InstaPrompt:OnChanged(function()
    if Toggles.InstaPrompt.Value then
        instaPromptConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.Enabled then
                        v.HoldDuration = 0
                        v.MaxActivationDistance = 60
                        local part = v.Parent
                        local rootPart = part:IsA("BasePart") and part or part:FindFirstChildWhichIsA("BasePart")
                        if rootPart and (hrp.Position - rootPart.Position).Magnitude <= 60 then
                            fireproximityprompt(v)
                        end
                    end
                end
            end)
        end)
        notify("Insta Prompt", "Enabled")
    else
        if instaPromptConn then instaPromptConn:Disconnect(); instaPromptConn = nil end
        notify("Insta Prompt", "Disabled")
    end
end)

SurvLeft:AddToggle("AutoSolveGens", {
    Text = "Auto Solve Generators",
    Tooltip = "Auto solves gens when you are close",
})

local solveGenConn = nil
local solvedGens = {}
Toggles.AutoSolveGens:OnChanged(function()
    if Toggles.AutoSolveGens.Value then
        solvedGens = {}
        solveGenConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                for _, gen in ipairs(findGenerators()) do
                    if solvedGens[gen] then continue end
                    if isGenDone(gen) then solvedGens[gen] = true; continue end
                    local primary = getGenPrimaryPart(gen)
                    if primary and (hrp.Position - primary.Position).Magnitude <= Config.SolveDistance then
                        solveGenerator(gen)
                    end
                end
            end)
        end)
        notify("Auto Solve Generators", "Enabled")
    else
        if solveGenConn then solveGenConn:Disconnect(); solveGenConn = nil end
        notify("Auto Solve Generators", "Disabled")
    end
end)

SurvLeft:AddSlider("SolveDistance", {
    Text = "Solve Distance",
    Tooltip = "Distance to auto-solve generators",
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 0,
    Callback = function(val) Config.SolveDistance = val end,
})

SurvLeft:AddToggle("AutoBarricade", {
    Text = "Auto Barricade",
    Tooltip = "Automatically centers the barricade dot",
})

local barricadeConn = nil
Toggles.AutoBarricade:OnChanged(function()
    if Toggles.AutoBarricade.Value then
        barricadeConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                local gui = LocalPlayer:FindFirstChild("PlayerGui")
                if not gui then return end
                local dot = gui:FindFirstChild("Dot")
                if dot and dot:IsA("ScreenGui") then
                    local container = dot:FindFirstChild("Container")
                    if container then
                        local frame = container:FindFirstChild("Frame")
                        if frame and dot.Enabled then
                            frame.AnchorPoint = Vector2.new(0.5, 0.5)
                            frame.Position = UDim2.new(0.5, 0, 0.5, 0)
                        end
                    end
                end
            end)
        end)
        notify("Auto Barricade", "Enabled")
    else
        if barricadeConn then barricadeConn:Disconnect(); barricadeConn = nil end
        notify("Auto Barricade", "Disabled")
    end
end)

SurvLeft:AddToggle("AutoGenerator", {
    Text = "Auto Generator",
    Tooltip = "Auto completes all generators one by one",
})

local autoGenEnabled = false
local genPuzzleConn = nil
local completedGens = {}
Toggles.AutoGenerator:OnChanged(function()
    autoGenEnabled = Toggles.AutoGenerator.Value
    if autoGenEnabled then
        completedGens = {}
        genPuzzleConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if not pg then return end
                local gg = pg:FindFirstChild("Gen") or pg:FindFirstChild("Generator")
                if gg then
                    local mf = gg:FindFirstChild("GeneratorMain") or gg:FindFirstChild("Main") or gg:FindFirstChild("Frame")
                    if mf then
                        local ev = mf:FindFirstChild("Event") or mf:FindFirstChild("RemoteEvent")
                        if ev and ev:IsA("RemoteEvent") then ev:FireServer(true) end
                        for _, btn in ipairs(mf:GetDescendants()) do
                            if btn:IsA("TextButton") or btn:IsA("ImageButton") then pcall(function() btn.MouseButton1Click:Fire() end) end
                        end
                    end
                end
            end)
        end)
        task.spawn(function()
            while autoGenEnabled do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if char and hrp then
                    for _, gen in ipairs(findGenerators()) do
                        if not autoGenEnabled then break end
                        if completedGens[gen] then continue end
                        if isGenDone(gen) then completedGens[gen] = true; continue end
                        local primary = getGenPrimaryPart(gen)
                        if primary then
                            local targetPos = (primary.CFrame + Vector3.new(0, -1, 2.5)).Position
                            ultraSafeMoveTo(targetPos)
                            task.wait(math.max((targetPos - hrp.Position).Magnitude / 15, 0.1) + 0.3)
                            for i = 1, 25 do
                                if not autoGenEnabled then break end
                                solveGenerator(gen)
                                task.wait(0.1)
                            end
                            task.wait(0.5)
                            if isGenDone(gen) then completedGens[gen] = true end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
        notify("Auto Generator", "Enabled")
    else
        if genPuzzleConn then genPuzzleConn:Disconnect(); genPuzzleConn = nil end
        notify("Auto Generator", "Disabled")
    end
end)

SurvLeft:AddButton({
    Text = "Solve Nearest Generator",
    Tooltip = "Instantly solves the closest generator",
    Func = function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local nearest, nearestDist = nil, math.huge
            for _, gen in ipairs(findGenerators()) do
                if isGenDone(gen) then continue end
                local primary = getGenPrimaryPart(gen)
                if primary then
                    local dist = (hrp.Position - primary.Position).Magnitude
                    if dist < nearestDist then nearestDist = dist; nearest = gen end
                end
            end
            if nearest then
                for i = 1, 30 do solveGenerator(nearest); task.wait(0.05) end
                notify("Generator", "Solved nearest generator!")
            else
                notify("Generator", "No incomplete generators found")
            end
        end)
    end,
})

-- ================================================
-- SURVIVOR TAB — Survival
-- ================================================

SurvRight:AddToggle("AntiDeath", {
    Text = "Anti Death",
    Tooltip = "Teleports to safe zone when low HP",
})

local antiDeath = { enabled = false, threshold = 30, conn = nil, lastPos = nil, teleported = false, debounce = false }
Toggles.AntiDeath:OnChanged(function()
    antiDeath.enabled = Toggles.AntiDeath.Value
    if antiDeath.enabled then
        antiDeath.conn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if hum.Health < antiDeath.threshold and hum.Health > 0 and not antiDeath.teleported and not antiDeath.debounce then
                antiDeath.debounce = true; antiDeath.teleported = true; antiDeath.lastPos = hrp.CFrame
                ultraSafeMoveTo((pp.CFrame + Vector3.new(0, 5, 0)).Position)
                task.delay(1, function() antiDeath.debounce = false end)
            elseif hum.Health >= antiDeath.threshold and antiDeath.teleported and antiDeath.lastPos and not antiDeath.debounce then
                antiDeath.debounce = true
                ultraSafeMoveTo(antiDeath.lastPos.Position, function() antiDeath.lastPos = nil; antiDeath.teleported = false end)
                task.delay(1, function() antiDeath.debounce = false end)
            end
        end)
        notify("Anti Death", "Enabled")
    else
        if antiDeath.conn then antiDeath.conn:Disconnect(); antiDeath.conn = nil end
        antiDeath.lastPos = nil; antiDeath.teleported = false; antiDeath.debounce = false
        notify("Anti Death", "Disabled")
    end
end)

SurvRight:AddSlider("HealthThreshold", {
    Text = "HP Threshold",
    Tooltip = "Health level that triggers Anti Death",
    Default = 30,
    Min = 10,
    Max = 80,
    Rounding = 0,
    Callback = function(val) antiDeath.threshold = val end,
})

SurvRight:AddToggle("SafetyArea", {
    Text = "Safety Area",
    Tooltip = "Teleports you to a high safe zone",
})

local lastPosition = nil
Toggles.SafetyArea:OnChanged(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if Toggles.SafetyArea.Value then
        lastPosition = hrp.CFrame
        ultraSafeMoveTo(Vector3.new(0, 1003, 0))
        notify("Safety Area", "Teleported to safe zone")
    else
        if lastPosition then ultraSafeMoveTo(lastPosition.Position); lastPosition = nil end
        notify("Safety Area", "Returned to position")
    end
end)

SurvRight:AddToggle("LowHPFloat", {
    Text = "Low HP Float",
    Tooltip = "Hovers upward when HP is critically low",
})

local lowHPFloatConn = nil
Toggles.LowHPFloat:OnChanged(function()
    if Toggles.LowHPFloat.Value then
        lowHPFloatConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if hum.Health <= 20 and hum.Health > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 18, hrp.AssemblyLinearVelocity.Z)
            end
        end)
        notify("Low HP Float", "Enabled")
    else
        if lowHPFloatConn then lowHPFloatConn:Disconnect(); lowHPFloatConn = nil end
        notify("Low HP Float", "Disabled")
    end
end)

SurvRight:AddToggle("AntiDebuff", {
    Text = "Anti Debuff",
    Tooltip = "Removes ragdoll, slow, stun, and blind effects",
})

local antiDebuffConn = nil
Toggles.AntiDebuff:OnChanged(function()
    if Toggles.AntiDebuff.Value then
        antiDebuffConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            for _, attr in ipairs({"Ragdoll", "Stunned", "Slowed", "Confused", "Blinded"}) do
                if hum:GetAttribute(attr) == true then hum:SetAttribute(attr, false) end
            end
            if hum.PlatformStand == true and not Toggles.Flight.Value then hum.PlatformStand = false end
            if hum.WalkSpeed == 0 then hum.WalkSpeed = 16 end
            if hum.UseJumpPower and hum.JumpPower == 0 then hum.JumpPower = 50 end
        end)
        notify("Anti Debuff", "Enabled")
    else
        if antiDebuffConn then antiDebuffConn:Disconnect(); antiDebuffConn = nil end
        notify("Anti Debuff", "Disabled")
    end
end)

SurvRight:AddToggle("ViewKiller", {
    Text = "View Killer",
    Tooltip = "Attaches your camera to the killer",
})

local killerAddedConn, killerRemovedConn = nil, nil
Toggles.ViewKiller:OnChanged(function()
    local camera = workspace.CurrentCamera
    if Toggles.ViewKiller.Value then
        pcall(function()
            local killerFolder = workspace.PLAYERS:FindFirstChild("KILLER")
            if not killerFolder then return end
            local function setKillerCam(killerChar)
                local hum = killerChar:FindFirstChildOfClass("Humanoid")
                if hum then camera.CameraSubject = hum end
            end
            local killer = killerFolder:GetChildren()[1]
            if killer then setKillerCam(killer) end
            killerAddedConn = killerFolder.ChildAdded:Connect(setKillerCam)
            killerRemovedConn = killerFolder.ChildRemoved:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then camera.CameraSubject = hum end
                end
            end)
        end)
        notify("View Killer", "Enabled")
    else
        if killerAddedConn then killerAddedConn:Disconnect(); killerAddedConn = nil end
        if killerRemovedConn then killerRemovedConn:Disconnect(); killerRemovedConn = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then camera.CameraSubject = hum end
        end
        notify("View Killer", "Disabled")
    end
end)

-- ================================================
-- KILLER TAB
-- ================================================

KillLeft:AddToggle("TeleportKill", {
    Text = "Teleport Kill",
    Tooltip = "Continuously moves you to the closest alive player",
})

local tpKillConn = nil
local killMode = "Closest"
local hitboxPart = nil
Toggles.TeleportKill:OnChanged(function()
    if Toggles.TeleportKill.Value then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if hitboxPart then hitboxPart:Destroy() end
                    hitboxPart = Instance.new("Part")
                    hitboxPart.Name = "VH_KillerHitbox"
                    hitboxPart.Size = Vector3.new(8, 8, 8)
                    hitboxPart.Transparency = 1
                    hitboxPart.CanCollide = false
                    hitboxPart.Massless = true
                    hitboxPart.CFrame = hrp.CFrame
                    hitboxPart.Parent = workspace
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = hrp; weld.Part1 = hitboxPart; weld.Parent = hitboxPart
                end
            end
        end)
        tpKillConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local targetChar
            if killMode == "Closest" then
                local closest, dist = nil, math.huge
                pcall(function()
                    for _, v in ipairs(workspace.PLAYERS.ALIVE:GetChildren()) do
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (root.Position - hrp.Position).Magnitude
                            if d < dist then dist = d; closest = v end
                        end
                    end
                end)
                targetChar = closest
            end
            if targetChar then
                local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                if hrp then ultraSafeMoveTo(hrp.Position) end
            end
        end)
        notify("Teleport Kill", "Enabled")
    else
        if tpKillConn then tpKillConn:Disconnect(); tpKillConn = nil end
        if hitboxPart then hitboxPart:Destroy(); hitboxPart = nil end
        notify("Teleport Kill", "Disabled")
    end
end)

-- ================================================
-- TELEPORT TAB
-- ================================================

local generatorIndex = 1
TpLeft:AddButton({
    Text = "Generator TP",
    Tooltip = "Moves to the next generator",
    Func = function()
        pcall(function()
            local generators = findGenerators()
            if #generators == 0 then notify("Generator TP", "No generators found"); return end
            local gen = generators[generatorIndex]
            local primary = getGenPrimaryPart(gen)
            if primary then
                ultraSafeMoveTo((primary.CFrame + Vector3.new(0, -0.5, 3.5)).Position)
                notify("Generator TP", "Moving to Generator " .. generatorIndex .. "/" .. #generators)
            end
            generatorIndex = generatorIndex % #generators + 1
        end)
    end,
})

local batteryRunning = false
local doneFuseBoxes = {}

local function findBatteries()
    local result = {}
    pcall(function()
        local folder = workspace.MAPS["GAME MAP"]:FindFirstChild("Batteries")
        if folder then
            for _, v in ipairs(folder:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("MeshPart") then table.insert(result, v) end
            end
        end
    end)
    if #result == 0 then
        for _, v in ipairs(workspace:GetDescendants()) do
            if (v:IsA("BasePart") or v:IsA("MeshPart")) and v.Name == "Battery" then table.insert(result, v) end
        end
    end
    return result
end

local function findFuseBoxes()
    local result = {}
    pcall(function()
        local folder = workspace.MAPS["GAME MAP"]:FindFirstChild("FuseBoxes")
        if folder then for _, v in ipairs(folder:GetChildren()) do if v:IsA("Model") then table.insert(result, v) end end end
    end)
    return result
end

local function activatePrompts(target)
    for _, v in ipairs(target:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function() v.HoldDuration = 0; v.MaxActivationDistance = 100; fireproximityprompt(v) end)
        end
    end
end

TpLeft:AddButton({
    Text = "Battery TP + Submit",
    Tooltip = "Grabs a battery and submits it to a FuseBox",
    Func = function()
        if batteryRunning then notify("Battery", "Already running"); return end
        task.spawn(function()
            batteryRunning = true
            local ok, err = pcall(function()
                local fuseBoxes = findFuseBoxes()
                if #fuseBoxes == 0 then notify("Battery TP", "No FuseBoxes found"); return end
                local targetFuse = nil
                for _, fb in ipairs(fuseBoxes) do
                    if not doneFuseBoxes[fb] then targetFuse = fb; break end
                end
                if not targetFuse then notify("Battery TP", "All FuseBoxes submitted!"); return end
                local batteries = findBatteries()
                if #batteries == 0 then notify("Battery TP", "No batteries found"); return end
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local bestBat, bestDist = nil, math.huge
                for _, bat in ipairs(batteries) do
                    if bat and bat.Parent then
                        local d = (hrp.Position - bat.Position).Magnitude
                        if d < bestDist then bestDist = d; bestBat = bat end
                    end
                end
                if not bestBat then notify("Battery TP", "No valid battery"); return end
                notify("Battery TP", "Moving to battery...")
                ultraSafeMoveTo((bestBat.CFrame + Vector3.new(0, 1, 2.5)).Position)
                task.wait(math.max(bestDist / 15, 0.1) + 0.3)
                activatePrompts(bestBat)
                task.wait(0.4)
                notify("Battery TP", "Moving to FuseBox...")
                local fp = targetFuse:FindFirstChild("HumanoidRootPart") or targetFuse:FindFirstChildWhichIsA("BasePart")
                if fp then
                    local fuseDist = (hrp.Position - fp.Position).Magnitude
                    ultraSafeMoveTo((fp.CFrame + Vector3.new(0, 0.5, 2.5)).Position)
                    task.wait(math.max(fuseDist / 15, 0.1) + 0.3)
                end
                activatePrompts(targetFuse)
                task.wait(0.4)
                doneFuseBoxes[targetFuse] = true
                notify("Battery TP", "FuseBox submitted!")
            end)
            if not ok then notify("Battery TP", "Error: " .. tostring(err)) end
            batteryRunning = false
        end)
    end,
})

TpLeft:AddButton({
    Text = "Reset FuseBox List",
    Tooltip = "Clears the submitted FuseBox memory",
    Func = function()
        doneFuseBoxes = {}
        notify("Battery TP", "FuseBox list reset")
    end,
})

TpLeft:AddButton({
    Text = "Teleport to Escape",
    Tooltip = "Moves to the map exit point",
    Func = function()
        pcall(function()
            local ep = workspace.MAPS["GAME MAP"].Escapes.EscapePoint
            if ep and ep:IsA("BasePart") then
                ultraSafeMoveTo((ep.CFrame + Vector3.new(0, 3, 0)).Position)
                notify("Escape TP", "Moving to escape...")
            end
        end)
    end,
})

TpRight:AddSlider("StepDistance", {
    Text = "Step Distance",
    Tooltip = "Max studs per movement step (lower = safer)",
    Default = 2.5,
    Min = 1,
    Max = 5,
    Rounding = 1,
    Callback = function(val) Config.StepDistance = val end,
})

TpRight:AddSlider("StepDelay", {
    Text = "Step Delay",
    Tooltip = "Seconds between each movement step",
    Default = 0.15,
    Min = 0.05,
    Max = 0.30,
    Rounding = 2,
    Callback = function(val) Config.StepDelay = val end,
})

-- ================================================
-- MOVEMENT TAB
-- ================================================

MoveLeft:AddToggle("SpeedHack", {
    Text = "Speed Hack",
    Tooltip = "Increases your walk speed",
})

local speedHackConn = nil
Toggles.SpeedHack:OnChanged(function()
    if Toggles.SpeedHack.Value then
        speedHackConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Config.SpeedHackValue end
        end)
        notify("Speed Hack", "Enabled")
    else
        if speedHackConn then speedHackConn:Disconnect(); speedHackConn = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        notify("Speed Hack", "Disabled")
    end
end)

MoveLeft:AddSlider("SpeedValue", {
    Text = "Speed Value",
    Tooltip = "Walk speed multiplier",
    Default = 50,
    Min = 20,
    Max = 100,
    Rounding = 0,
    Callback = function(val) Config.SpeedHackValue = val end,
})

MoveLeft:AddToggle("InfiniteSprint", {
    Text = "Infinite Sprint",
    Tooltip = "Sprint forever without stamina drain",
})

local sprintConn = nil
Toggles.InfiniteSprint:OnChanged(function()
    if Toggles.InfiniteSprint.Value then
        sprintConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            if isMobile then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then char:SetAttribute("WalkSpeed", hum.MoveDirection.Magnitude > 0 and 24 or 12) end
            else
                local spd = (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) and 25 or 12
                char:SetAttribute("WalkSpeed", spd)
            end
        end)
        notify("Infinite Sprint", "Enabled")
    else
        if sprintConn then sprintConn:Disconnect(); sprintConn = nil end
        local char = LocalPlayer.Character
        if char then char:SetAttribute("WalkSpeed", 12) end
        notify("Infinite Sprint", "Disabled")
    end
end)

MoveLeft:AddToggle("InfiniteStamina", {
    Text = "Infinite Stamina",
    Tooltip = "Never run out of stamina",
})

local staminaConn = nil
Toggles.InfiniteStamina:OnChanged(function()
    if Toggles.InfiniteStamina.Value then
        staminaConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                if char:GetAttribute("Stamina") then char:SetAttribute("Stamina", 100) end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum:GetAttribute("Stamina") then hum:SetAttribute("Stamina", 100) end
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("NumberValue") and (v.Name:lower():match("stamina") or v.Name:lower():match("energy")) then
                        v.Value = v.MaxValue or 100
                    end
                end
            end)
        end)
        notify("Infinite Stamina", "Enabled")
    else
        if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
        notify("Infinite Stamina", "Disabled")
    end
end)

MoveLeft:AddToggle("AllowJumping", {
    Text = "Allow Jumping",
    Tooltip = "Enables jumping for your character",
})

local jpLoop, jpCA = nil, nil
Toggles.AllowJumping:OnChanged(function()
    if Toggles.AllowJumping.Value then
        local function applyJump()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7 end
        end
        applyJump()
        local curHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if curHum then jpLoop = curHum:GetPropertyChangedSignal("JumpPower"):Connect(applyJump) end
        jpCA = LocalPlayer.CharacterAdded:Connect(function(newChar)
            local hum = newChar:WaitForChild("Humanoid")
            applyJump()
            if jpLoop then jpLoop:Disconnect() end
            jpLoop = hum:GetPropertyChangedSignal("JumpPower"):Connect(applyJump)
        end)
        notify("Allow Jumping", "Enabled")
    else
        if jpLoop then jpLoop:Disconnect(); jpLoop = nil end
        if jpCA then jpCA:Disconnect(); jpCA = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then if hum.UseJumpPower then hum.JumpPower = 0 else hum.JumpHeight = 0 end end
        end
        notify("Allow Jumping", "Disabled")
    end
end)

MoveLeft:AddToggle("Flight", {
    Text = "Flight",
    Tooltip = "Fly freely — WASD to move, Space/Shift for up/down",
})

local flyConn, flyBodyVelocity, flyBodyGyro = nil, nil, nil
Toggles.Flight:OnChanged(function()
    local char = LocalPlayer.Character
    if not char then notify("Flight", "No character found"); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then notify("Flight", "Missing HRP or Humanoid"); return end
    if Toggles.Flight.Value then
        hum.PlatformStand = true
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4; flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = hrp.CFrame; flyBodyGyro.Parent = hrp
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.zero; flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = hrp
        flyConn = RunService.RenderStepped:Connect(function()
            if not hrp or not hrp.Parent then return end
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then moveDir = moveDir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            flyBodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * Config.FlySpeed or Vector3.zero
            flyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
        end)
        notify("Flight", "Enabled")
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
        hum.PlatformStand = false
        notify("Flight", "Disabled")
    end
end)

MoveLeft:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Tooltip = "Flight movement speed",
    Default = 80,
    Min = 30,
    Max = 200,
    Rounding = 0,
    Callback = function(val) Config.FlySpeed = val end,
})

MoveLeft:AddToggle("Noclip", {
    Text = "Noclip",
    Tooltip = "Clip through walls and objects",
})

local noclipConn = nil
Toggles.Noclip:OnChanged(function()
    if Toggles.Noclip.Value then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end)
        notify("Noclip", "Enabled")
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = LocalPlayer.Character
        if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        notify("Noclip", "Disabled")
    end
end)

MoveLeft:AddToggle("AntiVoid", {
    Text = "Anti Void",
    Tooltip = "Prevents falling through the map",
})

local antiVoidConn = nil
Toggles.AntiVoid:OnChanged(function()
    if Toggles.AntiVoid.Value then
        antiVoidConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if hrp.Position.Y < -50 then
                    hrp.CFrame = CFrame.new(0, 100, 0)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    notify("Anti Void", "Teleported to safety!")
                end
            end)
        end)
        notify("Anti Void", "Enabled")
    else
        if antiVoidConn then antiVoidConn:Disconnect(); antiVoidConn = nil end
        notify("Anti Void", "Disabled")
    end
end)

MoveRight:AddToggle("FullBright", {
    Text = "Full Bright",
    Tooltip = "Makes the map fully visible",
})

Toggles.FullBright:OnChanged(function()
    if Toggles.FullBright.Value then
        Lighting.Brightness = 5; Lighting.ClockTime = 14; Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        notify("Full Bright", "Enabled")
    else
        Lighting.Brightness = OriginalLighting.Brightness; Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd; Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
        notify("Full Bright", "Disabled")
    end
end)

MoveRight:AddToggle("AutoLock", {
    Text = "Auto Lock",
    Tooltip = "Right-click to lock camera onto the closest player",
})

local lockedTarget, lockInputConn, lockRenderConn = nil, nil, nil
Toggles.AutoLock:OnChanged(function()
    if Toggles.AutoLock.Value then
        lockInputConn = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                if lockedTarget then
                    lockedTarget = nil
                else
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local closest, shortest = nil, math.huge
                    for _, other in ipairs(Players:GetPlayers()) do
                        if other ~= LocalPlayer and other.Character then
                            local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
                            if ohrp then
                                local d = (hrp.Position - ohrp.Position).Magnitude
                                if d < shortest then shortest = d; closest = ohrp end
                            end
                        end
                    end
                    lockedTarget = closest
                end
            end
        end)
        lockRenderConn = RunService.RenderStepped:Connect(function()
            if lockedTarget and lockedTarget.Parent then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, lockedTarget.Position)
            else
                lockedTarget = nil
            end
        end)
        notify("Auto Lock", "Enabled — Right-click to lock/unlock")
    else
        lockedTarget = nil
        if lockInputConn then lockInputConn:Disconnect(); lockInputConn = nil end
        if lockRenderConn then lockRenderConn:Disconnect(); lockRenderConn = nil end
        notify("Auto Lock", "Disabled")
    end
end)

-- ================================================
-- VISUAL TAB — ESP
-- ================================================

VisLeft:AddToggle("SurvivorESP", {
    Text = "Survivor ESP",
    Tooltip = "Shows survivors with name, distance, and highlight",
})

Toggles.SurvivorESP:OnChanged(function()
    espDisconnect("survivorAdd"); espDisconnect("survivorRemove")
    for model, h in pairs(ESP.highlights) do if h and h:GetAttribute("VH_Tag") == "survivor" then espRemove(model) end end
    if Toggles.SurvivorESP.Value then
        pcall(function()
            local function getPlayerName(model)
                for _, player in ipairs(Players:GetPlayers()) do if player.Character == model then return player.Name end end
                return model.Name
            end
            for _, v in ipairs(workspace.PLAYERS.ALIVE:GetChildren()) do
                if v:IsA("Model") then makeESP(v, Color3.fromRGB(0,200,255), Color3.fromRGB(100,230,255), "survivor", getPlayerName(v)) end
            end
            ESP.connections["survivorAdd"] = workspace.PLAYERS.ALIVE.ChildAdded:Connect(function(v)
                if v:IsA("Model") then task.wait(0.5); makeESP(v, Color3.fromRGB(0,200,255), Color3.fromRGB(100,230,255), "survivor", getPlayerName(v)) end
            end)
            ESP.connections["survivorRemove"] = workspace.PLAYERS.ALIVE.ChildRemoved:Connect(espRemove)
            startDistanceUpdater()
        end)
        notify("Survivor ESP", "Enabled")
    else
        stopDistanceUpdater()
        notify("Survivor ESP", "Disabled")
    end
end)

VisLeft:AddToggle("KillerESP", {
    Text = "Killer ESP",
    Tooltip = "Shows the killer with name, distance, and highlight",
})

Toggles.KillerESP:OnChanged(function()
    espDisconnect("killerAdd"); espDisconnect("killerRemove")
    for model, h in pairs(ESP.highlights) do if h and h:GetAttribute("VH_Tag") == "killer" then espRemove(model) end end
    if Toggles.KillerESP.Value then
        pcall(function()
            local function getKillerName(model)
                for _, player in ipairs(Players:GetPlayers()) do if player.Character == model then return player.Name .. " (Killer)" end end
                return "Killer"
            end
            for _, v in ipairs(workspace.PLAYERS.KILLER:GetChildren()) do
                if v:IsA("Model") then makeESP(v, Color3.fromRGB(255,50,50), Color3.fromRGB(255,100,100), "killer", getKillerName(v)) end
            end
            ESP.connections["killerAdd"] = workspace.PLAYERS.KILLER.ChildAdded:Connect(function(v)
                if v:IsA("Model") then task.wait(0.5); makeESP(v, Color3.fromRGB(255,50,50), Color3.fromRGB(255,100,100), "killer", getKillerName(v)) end
            end)
            ESP.connections["killerRemove"] = workspace.PLAYERS.KILLER.ChildRemoved:Connect(espRemove)
            startDistanceUpdater()
        end)
        notify("Killer ESP", "Enabled")
    else
        stopDistanceUpdater()
        notify("Killer ESP", "Disabled")
    end
end)

VisLeft:AddToggle("GeneratorESP", {
    Text = "Generator ESP",
    Tooltip = "Shows generators — yellow = undone, green = done",
})

Toggles.GeneratorESP:OnChanged(function()
    espDisconnect("genAdd"); espDisconnect("genRemove"); espDisconnect("genUpdater")
    for model, h in pairs(ESP.highlights) do if h and h:GetAttribute("VH_Tag") == "generator" then espRemove(model) end end
    if Toggles.GeneratorESP.Value then
        local function applyToGen(v)
            if v:IsA("Model") and v.Name == "Generator" then
                local isDone = isGenDone(v)
                ESP.genStatus[v] = isDone
                if isDone then makeESP(v, Color3.fromRGB(50,255,100), Color3.fromRGB(100,255,150), "generator", "Generator (Done)")
                else makeESP(v, Color3.fromRGB(255,200,50), Color3.fromRGB(255,230,100), "generator", "Generator") end
            end
        end
        pcall(function()
            for _, v in ipairs(workspace:GetDescendants()) do applyToGen(v) end
            ESP.connections["genAdd"] = workspace.DescendantAdded:Connect(applyToGen)
            ESP.connections["genRemove"] = workspace.DescendantRemoving:Connect(espRemove)
            ESP.connections["genUpdater"] = RunService.Heartbeat:Connect(function()
                for model, _ in pairs(ESP.highlights) do
                    if model and model.Parent and ESP.highlights[model]:GetAttribute("VH_Tag") == "generator" then
                        updateGenESPColor(model)
                    end
                end
            end)
            startDistanceUpdater()
        end)
        notify("Generator ESP", "Enabled")
    else
        stopDistanceUpdater()
        notify("Generator ESP", "Disabled")
    end
end)

-- ================================================
-- MISC TAB
-- ================================================

MiscLeft:AddToggle("AntiAFK", {
    Text = "Anti-AFK",
    Tooltip = "Prevents automatic disconnect from idling",
})

local afkConn = nil
Toggles.AntiAFK:OnChanged(function()
    if Toggles.AntiAFK.Value then
        afkConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
        notify("Anti-AFK", "Enabled")
    else
        if afkConn then afkConn:Disconnect(); afkConn = nil end
        notify("Anti-AFK", "Disabled")
    end
end)

MiscLeft:AddToggle("VelocitySpoof", {
    Text = "Velocity Spoof",
    Tooltip = "Apply fake velocity during teleport movement",
    Default = true,
    Callback = function(val) Config.UseVelocitySpoof = val end,
})

MiscLeft:AddToggle("NoclipDuringMove", {
    Text = "Noclip During Move",
    Tooltip = "Disable collision while teleport-moving",
    Default = true,
    Callback = function(val) Config.NoclipDuringMove = val end,
})

MiscRight:AddToggle("DisableShadows", {
    Text = "Disable Shadows",
    Tooltip = "Removes shadow casting from the map",
    Callback = function(val) Lighting.GlobalShadows = not val end,
})

MiscRight:AddToggle("RemovePostFX", {
    Text = "Remove Post FX",
    Tooltip = "Strips bloom, blur, and other post effects",
    Callback = function(val) stripPostFX(val) end,
})

MiscRight:AddToggle("MaxFog", {
    Text = "Max Fog Distance",
    Tooltip = "Removes fog from view",
    Callback = function(val)
        Lighting.FogEnd = val and 100000 or OriginalLighting.FogEnd
        Lighting.FogStart = val and 99999 or OriginalLighting.FogStart
    end,
})

MiscRight:AddToggle("AmbientBoost", {
    Text = "Ambient Boost",
    Tooltip = "Sets ambient to full white for better visibility",
    Callback = function(val)
        Lighting.Ambient = val and Color3.fromRGB(255,255,255) or OriginalLighting.Ambient
        Lighting.OutdoorAmbient = val and Color3.fromRGB(255,255,255) or OriginalLighting.OutdoorAmbient
    end,
})

MiscRight:AddToggle("LowGraphics", {
    Text = "Low Graphics Mode",
    Tooltip = "Sets graphics quality to Level 1",
    Callback = function(val) setGFXLevel(val and 1 or Enum.SavedQualitySetting.Automatic) end,
})

MiscRight:AddToggle("DisableEffects", {
    Text = "Disable Effects",
    Tooltip = "Removes particles, trails, beams",
    Callback = function(val) disableEffects(val) end,
})

MiscRight:AddButton({
    Text = "Apply All Optimizations",
    Tooltip = "Enables all performance improvements at once",
    Func = function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000; Lighting.FogStart = 99999
        Lighting.Ambient = Color3.fromRGB(160,160,160); Lighting.OutdoorAmbient = Color3.fromRGB(160,160,160)
        stripPostFX(true); disableEffects(true); setGFXLevel(1)
        notify("VoidHub", "All optimizations applied!")
    end,
})

MiscRight:AddButton({
    Text = "Restore All Settings",
    Tooltip = "Reverts all lighting and performance changes",
    Func = function()
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd; Lighting.FogStart = OriginalLighting.FogStart
        Lighting.Ambient = OriginalLighting.Ambient; Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        stripPostFX(false); setGFXLevel(Enum.SavedQualitySetting.Automatic)
        notify("VoidHub", "All settings restored")
    end,
})

-- ================================================
-- INFO TAB
-- ================================================

InfoLeft:AddLabel("FPSLabel", {
    Text = "FPS: calculating...",
    DoesWrap = false,
})

InfoLeft:AddLabel("PingLabel", {
    Text = "Ping: calculating...",
    DoesWrap = false,
})

local fpsCounter = 0
local lastFpsUpdate = tick()
RunService.Heartbeat:Connect(function()
    fpsCounter = fpsCounter + 1
    local now = tick()
    if now - lastFpsUpdate >= 1 then
        local fps = math.floor(fpsCounter / (now - lastFpsUpdate))
        fpsCounter = 0; lastFpsUpdate = now
        if Options.FPSLabel then Options.FPSLabel:SetText("FPS: " .. fps) end
    end
    if Options.PingLabel then
        local ping = math.floor(getPing())
        Options.PingLabel:SetText("Ping: " .. ping .. "ms")
    end
end)

InfoRight:AddLabel("discord_title", { Text = "VoidHub Community" })
InfoRight:AddLabel("discord_link", { Text = "discord.gg/WSZpRAFVq", DoesWrap = false })
InfoRight:AddLabel("discord_credit", { Text = "Made by vonplayz_real", DoesWrap = false })

InfoRight:AddButton({
    Text = "Copy Discord Link",
    Tooltip = "Copies the Discord invite to clipboard",
    Func = function()
        pcall(function() setclipboard("https://discord.gg/WSZpRAFVq") end)
        notify("VoidHub", "Discord invite copied!")
    end,
})

-- ================================================
-- UI SETTINGS (Theme + Save)
-- ================================================

local UITab = Window:AddTab("UI Settings", "settings")
local UILeft = UITab:AddLeftGroupbox("Menu", "wrench")

UILeft:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})
UILeft:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(value) Library.ShowCustomCursor = value end,
})
UILeft:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(value) Library:SetNotifySide(value) end,
})
UILeft:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind",
})
UILeft:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("VoidHub")
SaveManager:SetFolder("VoidHub/BiteByNight")
SaveManager:BuildConfigSection(UITab)
ThemeManager:ApplyToTab(UITab)
SaveManager:LoadAutoloadConfig()

notify("VoidHub", "Bite By Night loaded!")
print("VoidHub | Bite By Night | vonplayz_real")
