local VoidHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/vonplayz_real/VoidHub/refs/heads/main/dist/main.lua", true))()

local Window = VoidHub:Window({
    Title = "VoidHub", -- Main title displayed at the top of the window
    Footer = "By vonplayz_real", -- Footer text shown at the bottom
    Content = "Content",
    Color = "Default", -- UI theme color (Default or custom theme)
    Version = 1.0,
    ["Tab Width"] = 120, -- Width size of the tab section
    Image = "101833678008843", -- Window icon asset ID (replace with your own)
    Configname = "Vilaris_Ui", -- Configuration file name for saving settings
    Uitransparent = 0.15, -- UI transparency (0 = solid, 1 = fully transparent)
    ShowUser = true,
    Search = true, 
    Animation = true,   -- aktifkan animasi
    TypeDelay  = 0.07,   -- opsional, default 0.07
    TypePause  = 2.5,    -- opsional, default 2.5
    Config = {
        AutoSave = true, -- Automatically save settings
        AutoLoad = true -- Automatically load saved settings
    },
    KeySystem = {
        Title = "My Hub",
        Icon = "lucide:bird",
        Placeholder = "Enter your key here",
        Default = "mykey123",
        DiscordText = "Join the Discord",
        DiscordUrl  = "https://discord.gg/xxxxx",
        Links = {
            { Name = "Linkvertise", Icon = "lucide:link", Url = "https://linkvertise.com/xxxxx" },
            { Name = "LootLabs",   Icon = "lucide:gift", Url = "https://lootlabs.gg/xxxxx" },
            { Name = "Work.ink",   Icon = "lucide:pen",  Url = "https://work.ink/xxxxx" },
        },

        Steps = {
            "Choose your Authorization System!",
            "Complete ads ( 2 Checkpoint )",
            "Copy and paste key here!!",
        },

        Callback = function(key)
            local validKeys = {
                "mykey123",
                "vip-key-456",
            }
            for _, v in ipairs(validKeys) do
                if key == v then
                    return true
                end
            end
            return false
        end,
    },
})

Window:Tag({
    Title = "v0.0.2",
    Color = Color3.fromRGB(245, 167, 35), -- kuning
})

local Tabs = {

    Section = Window:AddTab({
        Name = "Section",
        Icon = "lucide:table-of-contents",
    }),

    Badge = Window:AddTab({
        Name = "Badge",
        Icon = "lucide:badge-check",
    }),

    Button = Window:AddTab({
        Name = "Button",
        Icon = "lucide:mouse",
    }),

    Toggle = Window:AddTab({
        Name = "Toggle",
        Icon = "lucide:toggle-right",
    }),

    Dropdown = Window:AddTab({
        Name = "Dropdwon",
        Icon = "lucide:menu",
    }),

    Input = Window:AddTab({
        Name = "Input",
        Icon = "lucide:chevrons-left-right-ellipsis",
    }),

    Panel = Window:AddTab({
        Name = "Panel",
        Icon = "lucide:panel-bottom",
    }),

    Keybind = Window:AddTab({
        Name = "Keybind",
        Icon = "lucide:key",
    }),

    Slider = Window:AddTab({
        Name = "Slider",
        Icon = "lucide:settings-2",
    }),

    Paragraph = Window:AddTab({
        Name = "Paragraph",
        Icon = "lucide:rows-2",
    }),

    Colorpicker = Window:AddTab({
        Name = "Colorpicker",
        Icon = "lucide:palette",
    }),

    Config = Window:AddTab({
        Name = "Config",
        Icon = "lucide:folder",
    }),
}

local Sec = {}

Sec.SectionTransparency = Tabs.Section:AddSection({
    Title = "Transparency Section",
    Transparency   = true,  
})

Sec.SectionTransparency:AddToggle({
    Title    = "Aimbot",
    Default  = false,
    Callback = function(value)
        if value then
        else
        end
    end
})

Sec.Section = Tabs.Section:AddSection({
    Title = "Normal Section",
})

Sec.Section:AddToggle({
    Title    = "Auto Farm Event",
    Default  = false,
    Callback = function(value)
        if value then
        else
        end
    end
})

Sec.SectionLeft = Tabs.Section:AddSection({
    Title = "Left Section",
    Tabbox   = "Left",
})

Sec.SectionLeft:AddToggle({
    Title    = "Auto Farm",
    Default  = false,
    Callback = function(value)
        if value then
        else
        end
    end
})

Sec.SectionRight = Tabs.Section:AddSection({
    Title = "Right Section",
    Tabbox   = "Right",
})

Sec.SectionRight:AddDropdown({
    Title    = "Example",
    Options  = { "Option A", "Option B", "Option C" },
    Multi    = false,
    Default  = "Option A",
    Callback = function(value) print("Selected:", value) end
})

Sec.SectionRight:AddButton({
    Title    = "Button Test",
    Version  = "V2",
    Icon     = "lucide:bird",
    Callback = function() end
})

Sec.SectionTabbox = Tabs.Section:AddSection({
    Title = "Tabbox Section",
})

local Test1  = Sec.SectionTabbox:AddTabbox({ Title = "Icon",     Icon = "lucide:cpu" })
local Test2  = Sec.SectionTabbox:AddTabbox({ Icon = "lucide:cpu", Desc = "No Title"})
local Test3  = Sec.SectionTabbox:AddTabbox({ Title = "Desc",     Icon = "lucide:cpu", Desc = "Test 3 Description" })
local Test4  = Sec.SectionTabbox:AddTabbox({ Title = "Title" })

Sec.Badge = Tabs.Badge:AddSection({
    Title = "Badge Section",
    Open = true
})

Sec.Badge:AddParagraph({ 
    Title = "Example Badge Bug",
    Content = "This is Bug paragraph.\nUse \\n for new lines.",
    Badge = "Bug",
})

Sec.Badge:AddParagraph({ 
    Title = "Example Badge New",
    Content = "This is New paragraph.\nUse \\n for new lines.",
    Badge = "New",
})

Sec.Badge:AddParagraph({ 
    Title = "Example Badge Warning",
    Content = "This is Warning paragraph.\nUse \\n for new lines.",
    Badge = "Warning",
})

Sec.Badge:AddParagraph({ 
    Title = "Example Badge Fixed",
    Content = "This is Fixed paragraph.\nUse \\n for new lines.",
    Badge = "Fixed",
})

Sec.Button = Tabs.Button:AddSection({
    Title = "Button Section",
    Open = true
})

-- Example Button (Single)
Sec.Button:AddButton({
    Title = "Example Single",
    Callback = function()
        print("This is an example button")
        Nt("Example clicked!", 2)
    end
})

-- Example Button (Dual Button)
Sec.Button:AddButton({
    Title = "Example ",
    Callback = function()
        print("Example ON")
        Nt("Example enabled!", 2)
    end,

    SubTitle = "Example Off",
    SubCallback = function()
        print("Example OFF")
        Nt("Example disabled!", 2)
    end
})

Sec.Button:AddButton({
    Title = "Example Button V2",
    Version = "V2",
    Callback = function()
        print("This is an example button")
        Nt("Example clicked!", 2)
    end
})

Sec.Button:AddButton({
    Title = "Example ",
    Version = "V2",
    Callback = function()
        print("Example ON")
        Nt("Example enabled!", 2)
    end,

    SubTitle = "Example Off",
    SubCallback = function()
        print("Example OFF")
        Nt("Example disabled!", 2)
    end
})

Sec.Button:AddButton({
    Title = "Example Button V2 (Icon)",
    Version = "V2",
    Icon = "rbxassetid://79715859717613",  -- pakai asset id
    Callback = function()
        print("This is an example button")
        Nt("Example clicked!", 2)
    end
})

Sec.Button:AddButton({
    Title = "Locked",
    Locked = true,
    LockMessage = "Locked",
    Callback = function()
        print("This is an example button")
        Nt("Example clicked!", 2)
    end
})

Sec.Button:AddButton({
    Title = "Button V2 Locked",
    Locked = true,
    Version = "V2",
    Icon = "rbxassetid://79715859717613",  -- pakai asset id
    Callback = function()
        print("This is an example button")
        Nt("Example clicked!", 2)
    end
})


Sec.Toggle = Tabs.Toggle:AddSection({
    Title = "Toggle Section",
    Open = true
})

-- Example Basic
Sec.Toggle:AddToggle({
    Title = "Example Basic",
    Default = false,
    Callback = function(value)
        print("Example toggle:", value)

        if value then
            Nt("Example enabled!", 2)
        else
            Nt("Example disabled!", 2)
        end
    end
})

-- Example With Title2
Sec.Toggle:AddToggle({
    Title = "Example Title2",
    Title2 = "Example Sub Title",
    Default = false,
    Callback = function(value)
        if value then
            print("Example ON")
            Nt("Example enabled!", 2)
        else
            print("Example OFF")
            Nt("Example disabled!", 2)
        end
    end
})

-- Example With Content
Sec.Toggle:AddToggle({
    Title = "Example Content",
    Content = "This is an example toggle description",
    Default = false,
    Callback = function(value)
        if value then
            Nt("Example enabled!", 2)
        else
            Nt("Example disabled!", 2)
        end
    end
})

Sec.Toggle:AddToggle({
    Title = "Toggle Locked",
    Locked = true,
    Default = false,
    Callback = function(value)
        print("Example toggle:", value)

        if value then
            Nt("Example enabled!", 2)
        else
            Nt("Example disabled!", 2)
        end
    end
})

Sec.Toggle:AddToggle({
    Title = "Example Icon",
    Type   = "Toggle",
    Icon = "lucide:bird",
    Default = false,
    Callback = function(value)
        if value then
        else
        end
    end
})

Sec.Toggle:AddToggle({
    Title    = "Type Checkbox Icon",
    Type     = "Checkbox",   -- tampilan checkbox
    Icon     = "lucide:bird",
    Default  = false,
    Callback = function(value)
        print("Checked:", value)
    end
})

Sec.Dropdown = Tabs.Dropdown:AddSection({
    Title = "Dropdown Section",
    Open = true
})

-- Example Single
Sec.Dropdown:AddDropdown({
    Title = "Example Single",
    Content = "Example dropdown description",
    Options = {
        "Option A",
        "Option B",
        "Option C",
        "Option D"
    },
    Multi = false,
    Default = "Option A",
    Callback = function(value)
        print("Example selected:", value)
    end
})

-- Example Multi
Sec.Dropdown:AddDropdown({
    Title = "Example Multi",
    Content = "Example multi dropdown description",
    Options = {
        "Option 1",
        "Option 2",
        "Option 3",
        "Option 4"
    },
    Multi = true,
    Default = {
        "Option 1",
        "Option 2"
    },
    Callback = function(selectedTable)
        print("Example selected options:")
        for _, v in ipairs(selectedTable) do
            print("- " .. v)
        end
    end
})

Sec.Input = Tabs.Input:AddSection({
    Title = "Input Section",
    Open = true
})

Sec.Input:AddInput({
    Title = "Username",
    Content = "Enter your username",
    Default = game.Players.LocalPlayer.Name,
    Callback = function(value)
        print("Username set to:", value)
        -- Save username setting
    end
})

Sec.Input:AddInput({
    Title = "Input Search",
    Content = "Type item name to search",
    Default = "", -- Default kosong
    Callback = function(value)
        if value ~= "" then
            print("Searching for:", value)
            -- Kode search
        end
    end
})

Sec.Input:AddInput({
    Title = "Type Textarea",
    Type = "Textarea",
    Content = "Enter your username",
    Default = "",
    Callback = function(value)
        print("Username set to:", value)
        -- Save username setting
    end
})

Sec.Input:AddInput({
    Title = "Input Icon",
    InputIcon = "lucide:bird",
    Content = "Enter your username",
    Default = "",
    Callback = function(value)
        print("Username set to:", value)
        -- Save username setting
    end
})

Sec.Panel = Tabs.Panel:AddSection({
    Title = "Panel Section",
    Open = true
})

-- Example Panel (Single Button)
Sec.Panel:AddPanel({
    Title = "Example (Single Button)",
    Content = "Example panel description",
    Placeholder = "Example_Name",
    Default = "ExampleDefault",
    ButtonText = "Example Action",
    ButtonCallback = function(value)
        print("Example value:", value)
        -- Example logic here
        Nt("Example action executed!", 2)
    end
})

-- Example Panel (Dual Button)
Sec.Panel:AddPanel({
    Title = "Example (Dual Button)",
    Content = "Example panel with two actions",
    Placeholder = "Example_Name",
    Default = "",
    ButtonText = "Example Save",
    ButtonCallback = function(value)
        if value ~= "" then
            print("Example save:", value)
            Nt("Example saved!", 2)
        else
            Nt("Example name required!", 2)
        end
    end,

    SubButtonText = "Example Load",
    SubButtonCallback = function(value)
        if value ~= "" then
            print("Example load:", value)
            Nt("Example loaded!", 2)
        else
            Nt("Example name required!", 2)
        end
    end
})

Sec.Keybind = Tabs.Keybind:AddSection({
    Title = "Keybind Section",
    Open = true
})

Sec.Keybind:AddKeybind({
    Title = "Toggle ESP",
    Content = "Tekan untuk toggle",  -- subtitle kecil di bawah title
    Value = "RightShift",            -- default key
    Callback = function(key)
    end
})

Sec.Slider = Tabs.Slider:AddSection({
    Title = "Slider Section",
    Open = true
})

-- Example Basic
Sec.Slider:AddSlider({
    Title = "Example Basic",
    Content = "Example slider description",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        print("Example slider value:", value)
    end
})

-- Example Alternative
Sec.Slider:AddSlider({
    Title = "Example Alternative",
    Content = "Another example slider",
    Min = 0,
    Max = 100,
    Default = 70,
    Increment = 5,
    Callback = function(value)
        print("Example value:", value)
    end
})

Sec.Slider:AddSlider({
    Title    = "Brightness",
    Min      = 0,
    Max      = 100,
    Default  = 70,
    Tooltip  = true,   -- ← aktifkan tooltip
    Locked  = true,
    Callback = function(value)
        print("Brightness:", value)
    end,
})

Sec.Slider:AddSlider({
    Title    = "Size",
    Min      = 1,
    Max      = 50,
    Default  = 20,
    IconFrom = "lucide:sun",  -- icon kecil di kiri
    IconTo   = "lucide:sun",  -- icon besar di kanan
    Tooltip  = true,
    Callback = function(value)
        print("Size:", value)
    end,
})

Sec.Slider:AddSlider({
    Title        = "Walkspeed",
    Min          = 1,
    Max          = 100,
    Default      = 16,
    ScrollParent = MyScrollingFrame,  -- ← referensi langsung
    Callback     = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})

Sec.Paragraph = Tabs.Paragraph:AddSection({
    Title = "Paragraph Section",
    Open = true
})

-- Example Paragraph (Simple)
Sec.Paragraph:AddParagraph({
    Title = "Example",
    Content = "This is an example paragraph.\nUse \\n for new lines."
})

-- Example Paragraph (With Icon)
Sec.Paragraph:AddParagraph({
    Title = "Example",
    Content = "Example information paragraph with an icon.",
    Icon = "example_icon"
})

-- Example Paragraph (With Button)
Sec.Paragraph:AddParagraph({
    Title = "Example",
    Content = "Example paragraph with action button.",
    Icon = "example_action_icon",
    ButtonText = "Example Action",
    ButtonCallback = function()
        print("Example button clicked")
    end
})

-- Example Paragraph (Support Section)
Sec.Paragraph:AddParagraph({
    Title = "Example",
    Content = "Example support paragraph with a button.",
    Icon = "example_help_icon",
    ButtonText = "Get Help",
    ButtonCallback = function()
        print("Support action triggered")
    end
})

-- Kartu biru (1 tombol)
Sec.Paragraph:AddParagraph({
    Title = "VoidHub Discord",
    Content = "VoidHub - Best UI Library",
    Icon = "rbxassetid://ICON_ID",  -- ganti ICON_ID dengan ID asset sebenarnya
    Color = Color3.fromRGB(70, 130, 220),
    ButtonText = "Copy Discord",
    ButtonCallback = function()
        setclipboard("discord.gg/ECxQFc97F5")
        print("Discord copied to clipboard!")
    end,
})

-- Kartu merah (2 tombol)
Sec.Paragraph:AddParagraph({
    Title = "VoidHub",
    Content = "Stable, Smooth - Powered by VoidHub Library",
    Icon = "rbxassetid://ICON_ID",  -- ganti ICON_ID dengan ID asset sebenarnya
    Color = Color3.fromRGB(220, 100, 90),
    ButtonText = "Discord VoidHub",
    ButtonCallback = function()
        setclipboard("discord.gg/ECxQFc97F5")
        print("Discord VoidHub copied!")
    end,
    SubButtonText = "Link VoidHub",
    SubButtonCallback = function()
        print("SubButton clicked! Add your logic here.")
    end,
})

Sec.Colorpicker = Tabs.Colorpicker:AddSection({
    Title = "Colorpicker Section",
    Open = true
})

Sec.Colorpicker:AddColorpicker({
    Title    = "Select Color",
    Content  = "",                              -- opsional
    Default  = Color3.fromRGB(255, 100, 100),  -- opsional
    Flag     = "custom_color",                  -- opsional
    Callback = function(color)
        print("Warna dipilih:", color)
    end
})
