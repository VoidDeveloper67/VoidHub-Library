-- // Vilaris Ui | Keybind.lua 

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GuiConfig  = { Color = Color3.fromRGB(0, 208, 255) }
local ConfigData = {}
local SaveConfig = function() end

local KeybindModule = {}

function KeybindModule:Initialize(config, saveFunc, configData)
    if config     then GuiConfig  = config     end
    if saveFunc   then SaveConfig = saveFunc   end
    if configData then ConfigData = configData end
end

function KeybindModule:CreateKeybind(SectionAdd, KeybindConfig, CountItem, Elements)
    KeybindConfig          = KeybindConfig or {}
    KeybindConfig.Title    = KeybindConfig.Title    or "Keybind"
    KeybindConfig.Content  = KeybindConfig.Content  or ""
    KeybindConfig.Value    = KeybindConfig.Value    or "None"
    KeybindConfig.Mode     = KeybindConfig.Mode     or "Toggle"
    KeybindConfig.Modes    = KeybindConfig.Modes    or {"Always","Toggle","Hold"}
    KeybindConfig.Callback = KeybindConfig.Callback or function() end
    KeybindConfig.Changed  = KeybindConfig.Changed  or function() end
    KeybindConfig.Locked   = KeybindConfig.Locked   or false

    -- Load saved config
    local ck    = (KeybindConfig.Flag and KeybindConfig.Flag ~= "") and KeybindConfig.Flag or ("Keybind_" .. KeybindConfig.Title)
    local saved = ConfigData[ck]
    if type(saved) == "table" then
        if type(saved.Key) == "string" and saved.Key ~= "" then KeybindConfig.Value = saved.Key end
        if type(saved.Mode) == "string" and table.find(KeybindConfig.Modes, saved.Mode) then KeybindConfig.Mode = saved.Mode end
    elseif type(saved) == "string" and saved ~= "" then
        KeybindConfig.Value = saved
    end

    -- ── Obsidian special keys ──────────────────────────────────────
    local SpecialKeys = {
        MB1 = Enum.UserInputType.MouseButton1,
        MB2 = Enum.UserInputType.MouseButton2,
        MB3 = Enum.UserInputType.MouseButton3,
    }
    local SpecialKeysInput = {
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
    }

    -- ── Obsidian modifiers ─────────────────────────────────────────
    local Modifiers = {
        LAlt   = Enum.KeyCode.LeftAlt,   RAlt  = Enum.KeyCode.RightAlt,
        LCtrl  = Enum.KeyCode.LeftControl, RCtrl = Enum.KeyCode.RightControl,
        LShift = Enum.KeyCode.LeftShift,  RShift = Enum.KeyCode.RightShift,
        Tab    = Enum.KeyCode.Tab,         CapsLock = Enum.KeyCode.CapsLock,
    }
    local ModifiersInput = {
        [Enum.KeyCode.LeftAlt]      = "LAlt",  [Enum.KeyCode.RightAlt]     = "RAlt",
        [Enum.KeyCode.LeftControl]  = "LCtrl", [Enum.KeyCode.RightControl] = "RCtrl",
        [Enum.KeyCode.LeftShift]    = "LShift",[Enum.KeyCode.RightShift]   = "RShift",
        [Enum.KeyCode.Tab]          = "Tab",   [Enum.KeyCode.CapsLock]     = "CapsLock",
    }

    local IsModifierInput = function(Input)
        return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
    end

    local GetActiveModifiers = function()
        local active = {}
        for name, kc in pairs(Modifiers) do
            if not table.find(active, name) and UserInputService:IsKeyDown(kc) then
                table.insert(active, name)
            end
        end
        return active
    end

    local AreModifiersHeld = function(required)
        if type(required) ~= "table" or #required == 0 then return true end
        local active = GetActiveModifiers()
        for _, name in ipairs(required) do
            if not table.find(active, name) then return false end
        end
        return true
    end

    local VerifyModifiers = function(mods)
        if type(mods) ~= "table" then return {} end
        local valid = {}
        for _, name in ipairs(mods) do
            if Modifiers[name] then table.insert(valid, name) end
        end
        return valid
    end

    local ConvertToInputModifiers = function(mods)
        local out = {}
        for _, name in ipairs(mods) do table.insert(out, Modifiers[name]) end
        return out
    end

    -- ── State ──────────────────────────────────────────────────────
    local curKey      = KeybindConfig.Value
    local curMode     = KeybindConfig.Mode
    local curMods     = VerifyModifiers(KeybindConfig.DefaultModifiers or {})
    local displayVal  = curKey
    local toggled     = false
    local Picking     = false
    local Signals     = {}

    local function saveState()
        ConfigData[ck] = { Key = curKey, Mode = curMode }
        SaveConfig()
    end

    local function safeCall(fn, ...)
        if type(fn) == "function" then
            local ok, err = pcall(fn, ...)
            if not ok then warn("[keybind]", err) end
        end
    end

    -- ── Row frame (Vilaris style) ──────────────────────────────────
    local KeybindFrame = Instance.new("Frame")
    KeybindFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    KeybindFrame.BackgroundTransparency = 0.935
    KeybindFrame.BorderSizePixel        = 0
    KeybindFrame.LayoutOrder            = CountItem
    KeybindFrame.Size                   = UDim2.new(1, 0, 0, 46)
    KeybindFrame.Name                   = "KeybindFrame"
    KeybindFrame.ClipsDescendants       = false
    KeybindFrame.Parent                 = SectionAdd
    Instance.new("UICorner", KeybindFrame).CornerRadius = UDim.new(0, 4)

    local KBTitle = Instance.new("TextLabel")
    KBTitle.Font               = Enum.Font.GothamBold
    KBTitle.Text               = KeybindConfig.Title
    KBTitle.TextColor3         = Color3.fromRGB(231, 231, 231)
    KBTitle.TextSize           = 13
    KBTitle.TextXAlignment     = Enum.TextXAlignment.Left
    KBTitle.TextYAlignment     = Enum.TextYAlignment.Top
    KBTitle.BackgroundTransparency = 1
    KBTitle.Position           = UDim2.new(0, 10, 0, 10)
    KBTitle.Size               = UDim2.new(1, -100, 0, 13)
    KBTitle.Parent             = KeybindFrame

    local KBContent = Instance.new("TextLabel")
    KBContent.Font               = Enum.Font.GothamBold
    KBContent.Text               = KeybindConfig.Content
    KBContent.TextColor3         = Color3.fromRGB(255, 255, 255)
    KBContent.TextSize           = 12
    KBContent.TextTransparency   = 0.6
    KBContent.TextXAlignment     = Enum.TextXAlignment.Left
    KBContent.TextYAlignment     = Enum.TextYAlignment.Bottom
    KBContent.BackgroundTransparency = 1
    KBContent.TextWrapped        = true
    KBContent.Position           = UDim2.new(0, 10, 0, 23)
    KBContent.Size               = UDim2.new(1, -100, 0, 12 + (12 * (KBContent.TextBounds.X // math.max(1, KBContent.AbsoluteSize.X))))
    KBContent.TextWrapped        = true
    KeybindFrame.Size            = UDim2.new(1, 0, 0, KBContent.AbsoluteSize.Y + 33)
    KBContent.Parent             = KeybindFrame

    KBContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        KBContent.TextWrapped = false
        KBContent.Size = UDim2.new(1, -100, 0, 12 + (12 * (KBContent.TextBounds.X // math.max(1, KBContent.AbsoluteSize.X))))
        KeybindFrame.Size = UDim2.new(1, 0, 0, KBContent.AbsoluteSize.Y + 33)
        KBContent.TextWrapped = true
    end)

    -- ── Picker button (Obsidian style: auto-width TextButton) ──────
    local Picker = Instance.new("TextButton")
    Picker.BackgroundColor3       = Color3.fromRGB(35, 35, 35)
    Picker.BorderColor3           = Color3.fromRGB(50, 50, 50)
    Picker.BorderSizePixel        = 1
    Picker.AnchorPoint            = Vector2.new(1, 0.5)
    Picker.Position               = UDim2.new(1, -8, 0.5, 0)
    Picker.Size                   = UDim2.fromOffset(18, 18)
    Picker.Text                   = curKey
    Picker.Font                   = Enum.Font.GothamBold
    Picker.TextSize               = 13
    Picker.TextColor3             = Color3.fromRGB(200, 200, 200)
    Picker.AutoButtonColor        = false
    Picker.Parent                 = KeybindFrame

    -- Mode label kecil di bawah picker


    -- Mode context menu (Obsidian style: appears at ScreenGui level)
    -- We parent it to KeybindFrame with ClipsDescendants=false so it overflows
    local ModeMenu = Instance.new("Frame")
    ModeMenu.Name               = "ModeMenu"
    ModeMenu.AnchorPoint        = Vector2.new(1, 0)
    ModeMenu.BackgroundColor3   = Color3.fromRGB(25, 25, 25)
    ModeMenu.BorderColor3       = Color3.fromRGB(50, 50, 50)
    ModeMenu.BorderSizePixel    = 1
    ModeMenu.Size               = UDim2.fromOffset(62, 0)
    ModeMenu.Position           = UDim2.new(1, -8, 0, 22)
    ModeMenu.ZIndex             = 50
    ModeMenu.Visible            = false
    ModeMenu.ClipsDescendants   = false
    ModeMenu.Parent             = KeybindFrame

    local MML = Instance.new("UIListLayout", ModeMenu)
    MML.SortOrder = Enum.SortOrder.LayoutOrder

    -- ── Helper: Obsidian-style Display ────────────────────────────
    local function Display(overrideText)
        local text = overrideText or displayVal
        -- Obsidian calculates text bounds to auto-size the picker
        local textService = game:GetService("TextService")
        local params = Instance.new("GetTextBoundsParams")
        params.Text = text
        params.RichText = false
        params.Font = Font.fromEnum(Enum.Font.GothamBold)
        params.Size = 13
        params.Width = 200

        local bounds = Vector2.new(30, 14)
        pcall(function()
            bounds = textService:GetTextBoundsAsync(params)
        end)

        Picker.Text = text
        Picker.Size = UDim2.fromOffset(math.max(18, bounds.X + 9), math.max(18, bounds.Y + 4))
    end

    -- ── Mode buttons ───────────────────────────────────────────────
    local ModeButtons = {}
    for i, modeName in ipairs(KeybindConfig.Modes) do
        local ModeBtn = Instance.new("TextButton")
        ModeBtn.BackgroundColor3       = Color3.fromRGB(25, 25, 25)
        ModeBtn.BackgroundTransparency = 1
        ModeBtn.Size                   = UDim2.new(1, 0, 0, 21)
        ModeBtn.Text                   = modeName
        ModeBtn.Font                   = Enum.Font.GothamBold
        ModeBtn.TextSize               = 13
        ModeBtn.TextColor3             = Color3.fromRGB(200, 200, 200)
        ModeBtn.TextTransparency       = 0.5
        ModeBtn.AutoButtonColor        = false
        ModeBtn.ZIndex                 = 51
        ModeBtn.LayoutOrder            = i
        ModeBtn.Parent                 = ModeMenu

        local MB = {}

        function MB:Select()
            for _, other in pairs(ModeButtons) do
                other:Deselect()
            end
            curMode = modeName
            ModeBtn.BackgroundTransparency = 0
            ModeBtn.TextTransparency       = 0

            ModeMenu.Visible               = false
        end

        function MB:Deselect()
            ModeBtn.BackgroundTransparency = 1
            ModeBtn.TextTransparency       = 0.5
        end

        ModeBtn.MouseButton1Click:Connect(function()
            MB:Select()
            saveState()
            safeCall(KeybindConfig.Changed, curKey, curMode)
        end)

        if curMode == modeName then MB:Select() end
        ModeButtons[modeName] = MB
    end

    -- Resize ModeMenu height
    MML:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ModeMenu.Size = UDim2.fromOffset(62, MML.AbsoluteContentSize.Y)
    end)

    -- ── Trigger connections (rebuilt on key/mode change) ──────────
    local trigC, trigEndC

    local function RebuildTrigger()
        if trigC    then trigC:Disconnect();    trigC    = nil end
        if trigEndC then trigEndC:Disconnect(); trigEndC = nil end

        if curMode == "Always" or curKey == "None" or curKey == "Unknown" then return end

        local function matchesInput(input)
            if SpecialKeysInput[input.UserInputType] == curKey then return true end
            return input.UserInputType == Enum.UserInputType.Keyboard
                and input.KeyCode.Name == curKey
        end

        trigC = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or Picking or UserInputService:GetFocusedTextBox() then return end
            if curMode == "Always" or curKey == "None" or curKey == "Unknown" then return end
            if not AreModifiersHeld(curMods) then return end
            if not matchesInput(input) then return end

            if curMode == "Toggle" then
                toggled = not toggled
                safeCall(KeybindConfig.Callback, toggled)
            end
        end)

        if curMode == "Hold" then
            trigEndC = UserInputService.InputEnded:Connect(function(input)
                if Picking or UserInputService:GetFocusedTextBox() then return end
                if not matchesInput(input) then return end
                toggled = false
                safeCall(KeybindConfig.Callback, toggled)
            end)
        end
    end

    -- Also fire Hold on InputBegan
    table.insert(Signals, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or Picking or UserInputService:GetFocusedTextBox() then return end
        if curMode ~= "Hold" or curKey == "None" or curKey == "Unknown" then return end

        local function matchesInput(inp)
            if SpecialKeysInput[inp.UserInputType] == curKey then return true end
            return inp.UserInputType == Enum.UserInputType.Keyboard
                and inp.KeyCode.Name == curKey
        end

        if not AreModifiersHeld(curMods) then return end
        if not matchesInput(input) then return end
        toggled = true
        safeCall(KeybindConfig.Callback, toggled)
    end))

    table.insert(Signals, UserInputService.InputEnded:Connect(function()
        if Picking or UserInputService:GetFocusedTextBox() then return end
        if curMode ~= "Hold" then return end
        -- Update display only
    end))

    -- ── Left-click: Obsidian picking loop ─────────────────────────
    Picker.MouseButton1Click:Connect(function()
        if Picking then return end
        Picking = true

        Picker.Text = "..."
        Picker.Size = UDim2.fromOffset(29, 18)

        local Input
        local ActiveModifiers = {}

        local GetInput = function()
            Input = UserInputService.InputBegan:Wait()
            return UserInputService:GetFocusedTextBox() ~= nil
        end

        repeat
            task.wait()

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29, 18)

            if GetInput() then
                Picking = false
                Display()
                return
            end

            if Input.KeyCode == Enum.KeyCode.Escape then
                break
            end

            if IsModifierInput(Input) then
                local StopLoop = false

                repeat
                    task.wait()
                    if UserInputService:IsKeyDown(Input.KeyCode) then
                        task.wait(0.075)
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                table.insert(ActiveModifiers, ModifiersInput[Input.KeyCode])
                                Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                            end
                            if GetInput() then
                                StopLoop = true
                                break
                            end
                            if Input.KeyCode == Enum.KeyCode.Escape then break end
                            if not IsModifierInput(Input) then break end
                        else
                            if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                break
                            end
                        end
                    end
                until false

                if StopLoop then
                    Picking = false
                    Display()
                    return
                end
            end

            break
        until false

        local Key = "Unknown"
        if SpecialKeysInput[Input.UserInputType] ~= nil then
            Key = SpecialKeysInput[Input.UserInputType]
        elseif Input.UserInputType == Enum.UserInputType.Keyboard then
            Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
        end

        ActiveModifiers = (Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown") and {} or ActiveModifiers

        curKey   = Key
        curMods  = VerifyModifiers(ActiveModifiers)

        displayVal = #curMods > 0
            and (table.concat(curMods, " + ") .. " + " .. curKey)
            or curKey

        toggled = false
        Display()

        saveState()

        local newMods = ConvertToInputModifiers(curMods)
        safeCall(KeybindConfig.Changed, curKey, curMode, newMods)
        RebuildTrigger()

        -- Wait for release (Obsidian does this to prevent immediate re-trigger)
        local function isInputDown()
            if SpecialKeysInput[Input.UserInputType] then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode)
                    and not UserInputService:GetFocusedTextBox()
            end
            return false
        end

        repeat task.wait() until not isInputDown() or UserInputService:GetFocusedTextBox()
        Picking = false
    end)

    -- ── Right-click: open mode menu ────────────────────────────────
    Picker.MouseButton2Click:Connect(function()
        ModeMenu.Visible = not ModeMenu.Visible
    end)

    -- Close mode menu on click outside
    table.insert(Signals, UserInputService.InputBegan:Connect(function(input)
        if not ModeMenu.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        task.defer(function()
            if ModeMenu.Visible then ModeMenu.Visible = false end
        end)
    end))

    -- ── Lock overlay ───────────────────────────────────────────────
    if KeybindConfig.Locked then
        local ov = Instance.new("TextButton")
        ov.Text = ""; ov.AutoButtonColor = false
        ov.Size = UDim2.new(1,0,1,0)
        ov.BackgroundColor3 = Color3.fromRGB(8,8,14)
        ov.BackgroundTransparency = 0.4
        ov.BorderSizePixel = 0; ov.ZIndex = 10
        ov.Parent = KeybindFrame
        Instance.new("UICorner", ov).CornerRadius = UDim.new(0, 4)
    end

    -- Init
    Display()
    RebuildTrigger()

    -- ── API ────────────────────────────────────────────────────────
    local KeybindFunc = {}

    function KeybindFunc:Set(value, silent)
        curKey     = (not value or value == "") and "None" or tostring(value)
        displayVal = curKey
        Display()
        RebuildTrigger()
        saveState()
        if not silent then safeCall(KeybindConfig.Changed, curKey, curMode) end
    end

    function KeybindFunc:Get()     return curKey  end
    function KeybindFunc:GetMode() return curMode end

    function KeybindFunc:SetMode(mode)
        if not table.find(KeybindConfig.Modes, mode) then return end
        if ModeButtons[mode] then ModeButtons[mode]:Select() end
        curMode = mode
        saveState()
        RebuildTrigger()
    end

    function KeybindFunc:GetState()
        if curMode == "Always" then return true end
        if curMode == "Hold" then
            if curKey == "None" or curKey == "Unknown" then return false end
            if not AreModifiersHeld(curMods) then return false end
            if SpecialKeys[curKey] then
                return UserInputService:IsMouseButtonPressed(SpecialKeys[curKey])
                    and not UserInputService:GetFocusedTextBox()
            end
            local ok, kc = pcall(function() return Enum.KeyCode[curKey] end)
            return ok and UserInputService:IsKeyDown(kc) and not UserInputService:GetFocusedTextBox() or false
        end
        return toggled
    end

    function KeybindFunc:Clear(silent)      KeybindFunc:Set("None", silent)          end
    function KeybindFunc:SetTitle(t)        KBTitle.Text = tostring(t or "Keybind")  end
    function KeybindFunc:SetContent(t)      KBContent.Text = tostring(t or "")       end

    function KeybindFunc:Destroy()
        if trigC    then trigC:Disconnect()    end
        if trigEndC then trigEndC:Disconnect() end
        for _, c in ipairs(Signals) do
            if c and c.Connected then c:Disconnect() end
        end
        KeybindFrame:Destroy()
    end

    if KeybindConfig.Flag and KeybindConfig.Flag ~= "" and Elements then
        Elements[KeybindConfig.Flag] = KeybindFunc
    end

    return KeybindFunc
end

return KeybindModule
