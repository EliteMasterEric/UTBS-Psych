--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsOpenBox.lua
--- * Custom event which tells the Undertale battle system to open the battle box.

-- Event notes hooks
function onEvent(name, speedStr)
    if name ~= "utbsOpenBox" then
        return
    end

    local speedValue = tonumber(speedStr) or 1.0

    callScript("mods/utbs-lua-v1/scripts/main", "openBox", {speedValue})
end
