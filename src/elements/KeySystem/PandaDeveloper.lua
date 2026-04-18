-- Velaris UI | KeySystem | Type = "pandadeveloper"

return {
    Name = "Panda",
    Icon = "lucide:shield",
    Args = { "ServiceId" },

    New = function(ServiceId)
        local function getPandaObj()
            if type(_G.PandaDeveloper) == "table" then return _G.PandaDeveloper end
            if type(_G.pandaDeveloper) == "table" then return _G.pandaDeveloper end
            if type(_G.PandaKey)       == "table" then return _G.PandaKey       end
            if type(_G.pandakey)       == "table" then return _G.pandakey       end
            if type(_G.Panda)          == "table" then return _G.Panda          end
            local ok, env = pcall(getfenv)
            if ok and type(env) == "table" then
                if type(env.PandaDeveloper) == "table" then return env.PandaDeveloper end
                if type(env.PandaKey)       == "table" then return env.PandaKey       end
            end
            return nil
        end

        local function validateKey(key)
            if not key or key == "" then return false, "Key tidak boleh kosong." end
            local pd = getPandaObj()
            if not pd then return false, "PandaDeveloper object tidak ditemukan di _G." end
            local fn = pd.CheckKey or pd.checkKey or pd.check or pd.Validate or pd.validate or pd.VerifyKey or pd.verifyKey
            if type(fn) ~= "function" then return false, "Method CheckKey tidak ditemukan." end
            local ok, result = pcall(fn, pd, key)
            if not ok then return false, tostring(result) end
            return result == true, result == true and "Key valid!" or "Key tidak valid."
        end

        local function copyLink()
            return setclipboard("https://pandadevelopment.net/getkey?service=" .. tostring(ServiceId))
        end

        return {
            Verify = validateKey,
            Copy   = copyLink,
        }
    end
}
