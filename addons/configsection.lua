-- // configsection.lua | VoidHub AddConfigSection Module

return function(Chloex, getConfigFolder, getCURRENT_VERSION, getConfigData, getElements, LoadConfigElements, SaveConfig, Nt, getAutoLoad)

    local HttpService = game:GetService("HttpService")

    local function notify(msg, delay, color)
        Nt(msg, delay, color)
    end

    function Chloex:AddConfigSection(Tab, SectionConfig)
        local ConfigFolder    = getConfigFolder()
        local CURRENT_VERSION = getCURRENT_VERSION()
        local ConfigData      = getConfigData()

        local sectionName, sectionIcon, customFolderName
        if type(SectionConfig) == "string" then
            sectionName      = SectionConfig
            sectionIcon      = ""
            customFolderName = nil
        elseif type(SectionConfig) == "table" then
            sectionName      = SectionConfig.Name       or "Configuration"
            sectionIcon      = SectionConfig.Icon       or ""
            customFolderName = SectionConfig.FolderName or nil  -- ✅ NEW: custom folder name
        else
            sectionName      = "Configuration"
            sectionIcon      = ""
            customFolderName = nil
        end

        -- ✅ NEW: jika FolderName disediakan, override ConfigFolder base-nya
        if customFolderName and customFolderName ~= "" then
            -- sanitize: hanya izinkan karakter aman untuk nama folder
            local sanitized = customFolderName:match("^%s*(.-)%s*$"):gsub("[^%w_%-]", "_")
            if sanitized ~= "" then
                ConfigFolder = sanitized
            end
        end

        local cfgFolder = ConfigFolder .. "/Config"

        if isfolder and makefolder then
            if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
            if not isfolder(cfgFolder)    then makefolder(cfgFolder)    end
        end

        local AUTOLOAD_FILE   = ConfigFolder .. "/autoload.txt"
        local currentAutoload = ""
        if isfile and isfile(AUTOLOAD_FILE) then
            pcall(function() currentAutoload = readfile(AUTOLOAD_FILE) end)
        end

        local function toPath(name)
            return cfgFolder .. "/" .. name .. ".json"
        end

        local function getList()
            local list = {}
            if not (listfiles and isfolder) then return list end
            local ok, files = pcall(listfiles, cfgFolder)
            if not ok then return list end
            for _, path in ipairs(files) do
                local n = path:match("([^/\\]+)%.json$")
                if n then table.insert(list, n) end
            end
            table.sort(list)
            return list
        end

        local function saveConfig(name)
            if not writefile then return false end
            ConfigData._version = CURRENT_VERSION
            local ok = pcall(writefile, toPath(name), HttpService:JSONEncode(ConfigData))
            return ok
        end

        local function loadConfig(name)
            local path = toPath(name)
            if not (isfile and isfile(path)) then return false end
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(path))
            end)
            if ok and type(data) == "table" then
                if data._version == CURRENT_VERSION then
                    for k in pairs(ConfigData) do
                        ConfigData[k] = nil
                    end
                    for k, v in pairs(data) do
                        ConfigData[k] = v
                    end
                    ConfigData._version = CURRENT_VERSION

                    local Elements = getElements()
                    for key, element in pairs(Elements) do
                        if data[key] ~= nil and element.Set then
                            element:Set(data[key], false)
                        elseif element.Set then
                            element:Set(element.Value, true)
                        end
                    end
                    return true
                else
                    notify("Version mismatch on '" .. name .. "'!", 3, Color3.fromRGB(255, 165, 0))
                end
            end
            return false
        end

        local function deleteConfig(name)
            local path = toPath(name)
            if isfile and isfile(path) then
                pcall(delfile, path)
                return true
            end
            return false
        end

        local function setAutoload(name)
            if writefile then
                pcall(writefile, AUTOLOAD_FILE, name)
                currentAutoload = name
            end
        end

        local function clearAutoload()
            if isfile and isfile(AUTOLOAD_FILE) then
                pcall(delfile, AUTOLOAD_FILE)
            end
            currentAutoload = ""
        end

        local Sections = Tab:AddSection({
            Title  = sectionName,
            Name   = sectionName,
            Icon   = sectionIcon,
            Open   = true,
        })

        local selectedConfig = nil
        local dropdownRef    = nil
        local autoloadLabel  = nil

        local nameInput = Sections:AddInput({
            Title       = "Config name",
            Placeholder = "Enter config name...",
            Default     = "",
            Flag        = "CHX_ConfigNameInput",
            Callback    = function() end,
        })

        Sections:AddButton({
            Title    = "Create config",
            Version  = "V2",
            Icon     = "lucide:file-plus",
            Callback = function()
                local raw  = nameInput and nameInput.Value or ""
                local name = raw:match("^%s*(.-)%s*$"):gsub("[^%w_%-]", "_")
                if name == "" then
                    notify("Config name cannot be empty!", 3, Color3.fromRGB(255, 80, 80))
                    return
                end
                if saveConfig(name) then
                    notify("Config '" .. name .. "' created!", 3, Color3.fromRGB(80, 220, 100))
                    if dropdownRef then
                        dropdownRef:SetValues(getList(), selectedConfig)
                    end
                else
                    notify("Failed to create config!", 3, Color3.fromRGB(255, 80, 80))
                end
            end,
        })

        dropdownRef = Sections:AddDropdown({
            Title    = "Config list",
            Options  = getList(),
            Default  = nil,
            Flag     = "CHX_ConfigListDropdown",
            Callback = function(val)
                selectedConfig = val
            end,
        })

        Sections:AddButton({
            Title    = "Load config",
            Version  = "V2",
            Icon     = "lucide:folder-open",
            Callback = function()
                if not selectedConfig then
                    notify("Select a config first!", 3, Color3.fromRGB(255, 165, 0))
                    return
                end
                if loadConfig(selectedConfig) then
                    notify("Loaded '" .. selectedConfig .. "'!", 3, Color3.fromRGB(80, 220, 100))
                else
                    notify("Failed to load config!", 3, Color3.fromRGB(255, 80, 80))
                end
            end,
        })

        Sections:AddButton({
            Title    = "Overwrite config",
            Version  = "V2",
            Icon     = "lucide:save",
            Callback = function()
                if not selectedConfig then
                    notify("Select a config first!", 3, Color3.fromRGB(255, 165, 0))
                    return
                end
                if saveConfig(selectedConfig) then
                    notify("Overwritten '" .. selectedConfig .. "'!", 3, Color3.fromRGB(80, 220, 100))
                else
                    notify("Failed to overwrite config!", 3, Color3.fromRGB(255, 80, 80))
                end
            end,
        })

        Sections:AddButton({
            Title    = "Delete config",
            Version  = "V2",
            Icon     = "lucide:trash-2",
            Callback = function()
                if not selectedConfig then
                    notify("Select a config first!", 3, Color3.fromRGB(255, 165, 0))
                    return
                end
                local name = selectedConfig
                if deleteConfig(name) then
                    if currentAutoload == name then
                        clearAutoload()
                        if autoloadLabel then
                            autoloadLabel:SetContent("none")
                        end
                    end
                    selectedConfig = nil
                    if dropdownRef then
                        dropdownRef:SetValues(getList(), nil)
                    end
                    notify("Deleted '" .. name .. "'!", 3, Color3.fromRGB(80, 220, 100))
                else
                    notify("Failed to delete config!", 3, Color3.fromRGB(255, 80, 80))
                end
            end,
        })

        Sections:AddButton({
            Title    = "Refresh list",
            Version  = "V2",
            Icon     = "lucide:refresh-cw",
            Callback = function()
                if dropdownRef then
                    dropdownRef:SetValues(getList(), selectedConfig)
                end
                notify("List refreshed!", 2, Color3.fromRGB(80, 180, 255))
            end,
        })

        Sections:AddButton({
            Title    = "Set as autoload",
            Version  = "V2",
            Icon     = "lucide:star",
            Callback = function()
                if not selectedConfig then
                    notify("Select a config first!", 3, Color3.fromRGB(255, 165, 0))
                    return
                end
                setAutoload(selectedConfig)
                if autoloadLabel then
                    autoloadLabel:SetContent(selectedConfig)
                end
                notify("Autoload set to '" .. selectedConfig .. "'!", 3, Color3.fromRGB(80, 220, 100))
            end,
        })

        Sections:AddButton({
            Title    = "Reset autoload",
            Version  = "V2",
            Icon     = "lucide:star-off",
            Callback = function()
                clearAutoload()
                if autoloadLabel then
                    autoloadLabel:SetContent("none")
                end
                notify("Autoload cleared!", 2, Color3.fromRGB(255, 165, 0))
            end,
        })

        autoloadLabel = Sections:AddParagraph({
            Title   = "Current autoload config",
            Content = currentAutoload ~= "" and currentAutoload or "none",
        })

        local _autoLoadEnabled = (getAutoLoad == nil) or (type(getAutoLoad) == "function" and getAutoLoad() == true)
        if currentAutoload ~= "" and _autoLoadEnabled then
            task.defer(function()
                task.wait(0.5)
                if loadConfig(currentAutoload) then
                    notify("Auto-loaded: " .. currentAutoload, 3, Color3.fromRGB(80, 220, 100))
                end
            end)
        end

        return Sections
    end

end
