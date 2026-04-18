-- Velaris UI | KeySystem | Type = "luarmor"

return {
    Name = "Luarmor",
    Icon = "lucide:key",
    Args = { "ScriptId" },

    New = function(ScriptId)
        local function getLuarmorObj()
            if type(_G.luarmor) == "table" then return _G.luarmor end
            if type(_G.Luarmor) == "table" then return _G.Luarmor end
            local ok, env = pcall(getfenv)
            if ok and type(env) == "table" then
                if type(env.luarmor) == "table" then return env.luarmor end
                if type(env.Luarmor) == "table" then return env.Luarmor end
            end
            return nil
        end

        local function validateKey(key)
            if not key or key == "" then return false, "Key tidak boleh kosong." end
            local lm = getLuarmorObj()
            if not lm then return false, "Luarmor object tidak ditemukan di _G." end
            local fn = lm.CheckKey or lm.checkKey or lm.check or lm.Validate or lm.validate
            if type(fn) ~= "function" then return false, "Method CheckKey tidak ditemukan." end
            local ok, result = pcall(fn, lm, key)
            if not ok then return false, tostring(result) end
            return result == true, result == true and "Key valid!" or "Key tidak valid."
        end

        local function copyLink()
            return setclipboard("https://luarmor.net/")
        end

        return {
            Verify = validateKey,
            Copy   = copyLink,
        }
    end
}
