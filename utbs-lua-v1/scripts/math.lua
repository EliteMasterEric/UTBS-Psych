--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- scripts/math.lua
--- * Math utilities used by the Undertale battle system.
--- * Require this file to call its functions.

return {
    getRadiansBetweenPoints = function(x1, y1, x2, y2)
        -- Get the angle between two points, relative to 0,0, in radians
        -- Zero degrees is to the right, and angles increase counter-clockwise
        return math.atan2(y2 - y1, x2 - x1)
    end,
    getDegreesBetweenPoints = function(x1, y1, x2, y2)
        -- Get the angle between two points, relative to 0,0, in degrees
        -- Zero degrees is to the right, and angles increase counter-clockwise
        return math.deg(math.atan2(y2 - y1, x2 - x1))
    end,
}