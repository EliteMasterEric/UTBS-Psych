-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/init.lua
-- * Script which instructs UTBS to load the Sans plugin.

function onCreatePost()
    debugPrint('utbs-sans/init#onCreatePost()')
    -- Call registerPlugin pointing to THIS script.
    -- This tells the main mod script to load 
    callScript("mods/utbs-lua-v1/scripts/main", "registerPlugin", {"mods/utbs-sans/scripts/main"})
end