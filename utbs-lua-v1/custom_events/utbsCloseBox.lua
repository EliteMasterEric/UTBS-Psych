--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsCloseBox.lua
--- * Custom event which tells the Undertale battle system to close the battle box.

-- Event notes hooks
function onEvent(name)
    if name ~= "utbsCloseBox" then
        return
    end

    callScript("mods/utbs-lua-v1/scripts/main", "closeBox")
end
