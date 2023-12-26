--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsStartBattle.lua
--- * Custom event which tells the Undertale battle system to initialize any necessary components.
--- * Call this event immediately as the song starts (even if the battle only starts later).

-- Event notes hooks
function onEvent(name)
    if name ~= "utbsStartBattle" then
        return
    end

    callScript("mods/utbs-lua-v1/scripts/main", "initializeBattleSystem")
end
