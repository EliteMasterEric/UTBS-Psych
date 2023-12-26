-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/main.lua
-- * Script handling the Undertale Yellow plugin.

local self = nil

function onCreatePost()
    -- callScript("mods/utbs-lua-v1/scripts/main", "registerPlugin", {"undertale-yellow", self})
end

function onRegister(state)
    debugPrint("UTBS: Loaded Undertale Yellow plugin.")

    --state.registerSoulMode('lasso', require('mods/undertale-yellow/scripts/modes/lasso'))
end

function buildState()
    return {
        onRegister = onRegister,
    }
end

self = buildState()

return self