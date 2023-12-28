--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsUseAttack.lua
--- * Custom event which tells the Undertale battle system to use an attack.

-- Event notes hooks
function onEvent(name)
    if name ~= "utbsCloseBox" then
        return
    end

    callScript("mods/utbs-lua-v1/scripts/main", "useAttack")
end
