-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/modes/default.lua
-- * Script handling the default soul mode.

function getName()
    return "Default";
end

function getColorName()
    return "red";
end

function onRegister(self)
    -- Called when the soul mode is registered.
    debugPrint("UTBS: Registered soul mode 'default'!");
end

function onSwitchToMode(self)
    -- Called when the soul mode is switched to this mode.
end

function onSwitchFromMode(self)
    -- Called when the soul mode is switched from this mode.
end

function onBoxStartOpen(self)
    -- Called when the box starts to open while this mode is active.
end

function onBoxStartClose(self)
    -- Called when the box starts to close while this mode is active.
end

function onBoxOpen(self)
    -- Called when the box is opened while this mode is active.
end

function onBoxClose(self)
    -- Called when the box is closed while this mode is active.
end

local left = false;
local down = false;
local up = false;
local right = false;

function onSoulInput(self, elapsed, jpLeft, jpDown, jpUp, jpRight, jpAction)
    -- Perform movement based on the user input.

    local settings = self.getSettings()

    local xDir = 0;
    local yDir = 0;

    if not self.getSoulMayMove() then
        left = false;
        down = false;
        up = false;
        right = false;
    else
        if settings.nullCancelation then
            -- Advanced logic to try to make strafing feel more natural.
            
            if (jpLeft and not left) then
                -- Just pressed left.
                left = true;
                right = false;
            end
            if (jpRight and not right) then
                -- Just pressed right.
                right = true;
                left = false;
            end
            if (jpDown and not down) then
                -- Just pressed down.
                down = true;
                up = false;
            end
            if (jpUp and not up) then
                -- Just pressed up.
                up = true;
                down = false;
            end
    
            if (not jpLeft and left) then
                -- Just released left.
                left = false;
                if (jpRight) then
                    right = true;
                end
            end
    
            if (not jpRight and right) then
                -- Just released right.
                right = false;
                if (jpLeft) then
                    left = true;
                end
            end
    
            if (not jpDown and down) then
                -- Just released down.
                down = false;
                if (jpUp) then
                    up = true;
                end
            end
    
            if (not jpUp and up) then
                -- Just released up.
                up = false;
                if (jpDown) then
                    down = true;
                end
            end
        else 
            left = jpLeft;
            down = jpDown;
            up = jpUp;
            right = jpRight;
        end
    end
    
    if (left) then
        xDir = xDir - 1;
    end

    if (right) then
        xDir = xDir + 1;
    end
    
    if (up) then
        yDir = yDir - 1;
    end

    if (down) then
        yDir = yDir + 1;
    end

    if not settings.fastDiagonal then
        -- Ensure total movement is not faster when moving diagonally.
        if (xDir ~= 0 and yDir ~= 0) then
            xDir = xDir * 0.70710678118;
            yDir = yDir * 0.70710678118;
        end
    end

    local xDiff = xDir * settings.soulSpeed * elapsed;
    local yDiff = yDir * settings.soulSpeed * elapsed;

    local soulX, soulY = self.getSoulPosition();
    self.setSoulPosition(soulX + xDiff, soulY + yDiff);
end

function onSoulUpdate(self, elapsed, absSoulXPos, absSoulYPos)
    -- Perform an update after movement is applied.
end

function onPlayerHit(self, damage)
    -- Called when the player is hit by a bullet.
    return damage
end

return {
    getName = getName,
    getColorName = getColorName,

    onRegister = onRegister,
    onSwitchFromMode = onSwitchFromMode,
    onSwitchToMode = onSwitchToMode,
    onBoxOpen = onBoxOpen,
    onBoxClose = onBoxClose,

    onSoulInput = onSoulInput,
    onSoulUpdate = onSoulUpdate,
    onPlayerHit = onPlayerHit,
}