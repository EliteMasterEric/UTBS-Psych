-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/main.lua
-- * Script handling the Sans plugin.

local self = nil

function getPluginInfo()
    return {
        name = "Sans",
        version = "1.0.0"
    }
end

function onRegister(state)
    debugPrint("UTBS: Loaded Sans Attack plugin.")

    state.registerSoulMode('gravity', require('mods/utbs-sans/scripts/modes/gravity'))
end

function buildState()
    return {
        -- Plugin info
        getPluginInfo = getPluginInfo,

        -- Lifecycle functions
        onRegister = onRegister,
    }
end

self = buildState()

return self