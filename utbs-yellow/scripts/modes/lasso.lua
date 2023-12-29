-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/modes/lasso.lua
-- * Script handling the Lasso soul mode.
-- * Display a lasso around the soul, and restrict its movement.

local lassoRadius = 100;

local lassoSpriteXPad = 0;
local lassoSpriteYPad = 6;

local lassoSoundDelay = 1.5;
local lassoSoundTimer = 0;
local lassoSoundDistanceThreshold = 1.5;

local centerPointX = 0;
local centerPointY = 0;

function getName()
    return "Lasso";
end

function getColorName()
    return "yellow";
end

function onRegister(self)
    debugPrint("UTBS: Registered soul mode 'lasso'!");
end

function onSwitchToMode(self)
    -- Called when the soul mode is switched to this mode.
    self.flashSoulColor({
        duration = 0.5,
        frequency = 10,
    })

    showLassoSprite()

    playLassoSound()
end

function onSwitchFromMode(self)
    -- Called when the soul mode is switched from this mode.
    hideLassoSprite()
end

function onBoxStartOpen(self)
    -- Called when the box starts to open while this mode is active.
end

function onBoxOpen(self)
    -- Called when the box is opened while this mode is active.
    showLassoSprite()
end

function onBoxStartClose(self)
    -- Called when the box starts to close while this mode is active.
    hideLassoSprite()
end

function onBoxClose(self)
    -- Called when the box is closed while this mode is active.
end

function showLassoSprite()
    if not luaSpriteExists("utbsYellowLasso") then
        makeLuaSprite('utbsYellowLasso', 'utbs/modes/spr_battle_enemy_starlo_soul_0', 100, 100)
        setProperty('utbsYellowLasso.offset.x', 8)
        setProperty('utbsYellowLasso.offset.y', 8)
        setProperty('utbsYellowLasso.scale.x', 2)
        setProperty('utbsYellowLasso.scale.y', 2)
        setProperty('utbsYellowLasso.alpha', 1)
        setProperty('utbsYellowLasso.antialiasing', false)
        setObjectCamera('utbsYellowLasso', 'camHUD')
        
        addLuaSprite('utbsYellowLasso', false)
    else
        setProperty('utbsYellowLasso.alpha', 1)
    end
end

function playLassoSound()
    playSound('utbs/modes/snd_starlo_rope_strain')
    lassoSoundTimer = lassoSoundDelay
end

function hideLassoSprite()
    if luaSpriteExists("utbsYellowLasso") then
        setProperty('utbsYellowLasso.alpha', 0)
    else
        debugPrint("UTBS: WARNING Could not hide sprite, does not exist!")
    end
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

    
    local soulX, soulY = self.getSoulPosition();
    local distanceToCenter = getDistanceToCenter(soulX, soulY);
    
    local isXAwayFromCenter = (soulX * xDir) > 0; -- soulX and xDir have the same sign.
    local isYAwayFromCenter = (soulY * yDir) > 0; -- soulY and yDir have the same sign.

    local proportionalSpeed = (lassoRadius - distanceToCenter) / lassoRadius;
    local xProportionalSpeed = isXAwayFromCenter and proportionalSpeed or 1;
    local yProportionalSpeed = isYAwayFromCenter and proportionalSpeed or 1;

    -- debugPrint("UTBS: Lasso input : " .. distanceToCenter .. " : " .. proportionalSpeed);

    local xDiff = xDir * settings.soulSpeed * elapsed * xProportionalSpeed;
    local yDiff = yDir * settings.soulSpeed * elapsed * yProportionalSpeed;
    local diffDistance = math.sqrt(xDiff * xDiff + yDiff * yDiff);

    -- Handle lasso strain sound while moving.
    if lassoSoundTimer > 0 then
        lassoSoundTimer = lassoSoundTimer - elapsed
    else
        if diffDistance > lassoSoundDistanceThreshold then
            playLassoSound()
        end
    end

    self.setSoulPosition(soulX + xDiff, soulY + yDiff);
end

function getDistanceToCenter(posX, posY)
    local xDiff = posX - centerPointX;
    local yDiff = posY - centerPointY;

    return math.sqrt(xDiff * xDiff + yDiff * yDiff);
end

function onSoulUpdate(self, elapsed, absSoulXPos, absSoulYPos)
    -- Perform an update after movement is applied.
    if luaSpriteExists("utbsYellowLasso") then
        setProperty('utbsYellowLasso.x', absSoulXPos + lassoSpriteXPad)
        setProperty('utbsYellowLasso.y', absSoulYPos + lassoSpriteYPad)
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