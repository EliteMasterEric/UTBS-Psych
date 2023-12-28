--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- custom_events/utbsSetTargetBoxSize.lua
--- * Custom event which tells the Undertale battle system to grow or shrink the battle box.

-- Event notes hooks
function onEvent(name, widthStr, heightStr)
    if name ~= "utbsSetTargetBoxSize" then
        return
    end

    local width = tonumber(widthStr) or 100
    local height = tonumber(heightStr) or 100

    debugPrint("UTBS: Setting target box size to " .. width .. "x" .. height .. ".")

    callScript("mods/utbs-lua-v1/scripts/main", "setTargetBoxSize", {width, height})
end
