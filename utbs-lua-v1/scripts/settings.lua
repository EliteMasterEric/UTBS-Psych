--- =======================
--- UNDERTALE BATTLE SYSTEM
--- =======================
---
--- scripts/settings.lua
--- * Global settings the Undertale battle system.
--- * Require this file to modify its values. Don't modify this file directly or you'll mess up other mods.

-- Return all settings so they can be accessed via require('mods/utbs-lua-v1/scripts/settings')
return {
    ---
    --- BATTLE BOX
    ---

    --- The width and height of utbs/battleBox.png. Don't touch this.
    boxImageSize = 100;

    -- Horizontal position of the battle box (center).
    boxX = 1280 - 325;
    -- Vertical position of the battle box (center).
    boxY = 720 / 2;
    -- Width of the battle box.
    boxWidth = 450;
    -- Height of the battle box.
    boxHeight = 300;

    -- The width of the border around the battle box.
    boxBorderWidth = 16;

    -- The speed at which the box opens.
    boxOpenSpeed = 250 / 60 / 1000;
    -- The speed at which the box closes.
    boxCloseSpeed = 250 / 60 / 1000;

    -- The soul colors.
    soulColors = {
        red = getColorFromHex("FF0000"),
        orange = getColorFromHex("FFB000"),
        yellow = getColorFromHex("F7FF00"),
        green = getColorFromHex("00FF1B"),
        aqua = getColorFromHex("00A2E8"),
        lightBlue = getColorFromHex("4300FF"),
        purple = getColorFromHex("FC00FF")
    },

    -- 
    -- SOUL CONTROLS
    --

    soulSpeed = 4.2 * 60,

    -- True: Pressing right while holding left will move right, and releasing right will move left again.
    -- False: Pressing right while holding left will stop the soul.
    nullCancelation = true,

    -- True: Soul moves at 1.41x speed when moving diagonally.
    -- False: Soul moves at 1x speed when moving diagonally.
    fastDiagonal = true
}