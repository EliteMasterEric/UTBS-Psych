--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsSoulMode.lua
--- * Custom event which tells the Undertale battle system to change the soul's mode.

-- Event notes hooks
function onEvent(name, targetMode, forceColorStr)
    if name ~= "utbsSoulMode" then
        return
    end

    local forceColor = not (forceColorStr == "false")

    callScript("mods/utbs-lua-v1/scripts/main", "setSoulMode", {targetMode, forceColor})
end
