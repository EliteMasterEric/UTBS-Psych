-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/init.lua
-- * Script which instructs UTBS to load the Undertale Yellow plugin.

function onCreatePost()
    debugPrint('utbs-yellow/init#onCreatePost()')
    -- Call registerPlugin pointing to THIS script.
    -- This tells the main mod script to load 
    callScript("mods/utbs-lua-v1/scripts/main", "registerPlugin", {"mods/utbs-yellow/scripts/main"})
end