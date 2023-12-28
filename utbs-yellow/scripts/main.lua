-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/main.lua
-- * Script handling the Undertale Yellow plugin.

local self = nil

function getPluginInfo()
    return {
        name = "Undertale Yellow",
        version = "1.0.0"
    }
end

function onRegister(state)
    debugPrint("UTBS: Loaded Undertale Yellow plugin.")

    state.registerSoulMode('lasso', require('mods/utbs-yellow/scripts/modes/lasso'))
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