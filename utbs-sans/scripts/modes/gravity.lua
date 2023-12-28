-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/modes/gravity.lua
-- * Script handling the Gravity soul mode.
-- * Makes the soul blue and applies gravity to it.

function getName()
    return "Gravity";
end

function getColorName()
    return "blue";
end

function onRegister(self)
    debugPrint("UTBS: Registered soul mode 'gravity'!");
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

function onBoxOpen(self)
    -- Called when the box is opened while this mode is active.
end

function onBoxStartClose(self)
    -- Called when the box starts to close while this mode is active.
end

function onBoxClose(self)
    -- Called when the box is closed while this mode is active.
end

local left = false;
local down = false;
local up = false;
local right = false;

local grounded = false;
local gravityPower = 0.26 * 60;
-- Current angle of gravity (clockwise). 0 = down, 90 = left, 180 = up, 270 = right. Other values are not valid.
local gravityAngle = 0;

local jumpPower = 10 * 60;

-- Vertical speed relative to the direction of gravity (negative = away from gravity, positive = towards gravity).
local verticalSpeed = 0;

function onSoulInput(self, elapsed, jpLeft, jpDown, jpUp, jpRight, jpAction)
    -- Perform movement based on the user input.

    local settings = self.getSettings()

    local xDir = 0;
    local yDir = 0;

    -- Was pressed last update.
    local wasLeft = left;
    local wasDown = down;
    local wasUp = up;
    local wasRight = right;

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

    -- Just released.
    local jrLeft = (not jpLeft) and wasLeft;
    local jrDown = (not jpDown) and wasDown;
    local jrUp = (not jpUp) and wasUp;
    local jrRight = (not jpRight) and wasRight;
    
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

    local soulX, soulY = self.getSoulPosition();

    if not grounded then
        verticalSpeed = verticalSpeed - gravityPower * elapsed;
    end

    -- True if the user is pressing the direction away from gravity (the "jump" button)
    local isPressingAway = ((yDir < 0 and gravityAngle == 0) or (yDir > 0 and gravityAngle == 180) or (xDir < 0 and gravityAngle == 90) or (xDir > 0 and gravityAngle == 270));

    -- If gravity is vertical, ignore y movement.
    if (gravityAngle == 0 or gravityAngle == 180) then
        yDir = 0;
    end
    -- If gravity is horizontal, ignore x movement.
    if (gravityAngle == 90 or gravityAngle == 270) then
        xDir = 0;
    end

    -- If we are grounded and the user is pressing away from gravity, then jump.
    if (grounded and isPressingAway) then
        verticalSpeed = jumpPower * elapsed;
    end

    -- If we released the jump button, stop jumping.
    if (verticalSpeed > 0) and ((gravityAngle == 0 and jrUp) or (gravityAngle == 180 and jrDown) or (gravityAngle == 90 and jrRight) or (gravityAngle == 270 and jrLeft)) then
        verticalSpeed = verticalSpeed / 4;
    end
    
    local jumpX = verticalSpeed * math.sin(math.rad(gravityAngle));
    local jumpY = verticalSpeed * -math.cos(math.rad(gravityAngle));

    local xDiff = xDir * settings.soulSpeed * elapsed + jumpX;
    local yDiff = yDir * settings.soulSpeed * elapsed + jumpY;

    self.setSoulPosition(soulX + xDiff, soulY + yDiff);
end

function onSoulUpdate(self, elapsed, absSoulXPos, absSoulYPos)
    -- Perform an update after movement is applied.

    -- Orient the soul based on the direction of gravity.
    self.setSoulAngle(gravityAngle);

    -- Update the grounded state.
    if gravityAngle == 0 then
        grounded = self.getSoulTouchingBottom();
    elseif gravityAngle == 180 then
        grounded = self.getSoulTouchingTop();
    elseif gravityAngle == 90 then
        grounded = self.getSoulTouchingLeft();
    elseif gravityAngle == 270 then
        grounded = self.getSoulTouchingRight();
    end
end

return {
    getName = getName,
    getColorName = getColorName,

    onRegister = onRegister,
    onSwitchFromMode = onSwitchFromMode,
    onSwitchToMode = onSwitchToMode,
    onBoxStartOpen = onBoxStartOpen,
    onBoxOpen = onBoxOpen,
    onBoxStartClose = onBoxStartClose,
    onBoxClose = onBoxClose,

    onSoulInput = onSoulInput,
    onSoulUpdate = onSoulUpdate
}