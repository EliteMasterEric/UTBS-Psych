--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsOpenBox.lua
--- * Custom event which tells the Undertale battle system to open the battle box.

-- Event notes hooks
function onEvent(name)
    if name ~= "utbsOpenBox" then
        return
    end

    callScript("mods/utbs-lua-v1/scripts/main", "openBox")
end
