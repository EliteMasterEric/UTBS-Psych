-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/main.lua
-- * Main global script for the Undertale battle system.
-- * Called in all songs but only spawns the battle system when invoked.

luaDebugMode = true

local self = nil -- Assigned at the end.

--
-- GLOBAL VARIABLES
--
local settings = require('mods/utbs-lua-v1/scripts/settings')

local isInitialized = false

local isBoxBuilt = false

--
-- BOX STATE VARIABLES
--
local isBoxOpen = false
local isBoxOpening = false
local isBoxClosing = false
local isBoxLerping = false -- Called when changing box size without opening or closing it.
local boxRelativeOpenSpeed = 1.0

-- Current collision bounds of the battle box, relative to the center (0, 0).
local boxLeftBound = 0.0
local boxRightBound = 0.0
local boxTopBound = 0.0
local boxBottomBound = 0.0

-- Current size of the battle box
local boxW = 0.0
local boxH = 0.0
local boxX = settings.boxX
local boxY = settings.boxY

--
-- SOUL STATE VARIABLES
--

-- Soul mode affects gameplay. Possible modes include:
-- * Default
-- * Jump (Sans/Papyrus)
-- * Trap (Muffet)
-- * Shield (Undyne)
-- * Shooter (Mettaton)
-- * Switch (Mew Mew)
-- * Lasso (Starlo)
-- * Rhythm (El Baliador)
-- * Trashcan (Axis)

-- The value of soulMode is a table of functions to handle its behavior.
local soulMode = nil

-- Soul color only affects visuals, see soul mode.
local soulColor = settings.soulColors['red']

-- NOTE: Check both values to determine if the soul is vulnerable to damage.
local isSoulInvincible = false
local soulInvulnTimer = 0.0

local maySoulMove = true
local isSoulMoving = false
local isSoulTouchingTop = false
local isSoulTouchingBottom = false
local isSoulTouchingLeft = false
local isSoulTouchingRight = false

local targetBoxWidth = settings.defaultBoxWidth
local targetBoxHeight = settings.defaultBoxHeight

local soulXPos = 0.0
local soulYPos = 0.0

local timesHit = 0
local damageSoundTimer = 0

local soulFlashParams = nil
local soulFlashTimer = 0.0

--
-- ATTACK STATE VARIABLES
--
local nextAvailableBulletId = 0
local bulletData = {}

--
-- REGISTRIES
--
-- Registries are tables of scripts. This makes the battle system's behavior extensible through expanding the registry.

-- Main scripts defined by other mods, always running while UTBS is active.
local pluginRegistry = {}
-- Modes which the soul can be in which affect its behavior.
local soulModeRegistry = {}
-- Attacks which opponents can use which affect the soul.
local attackRegistry = {}

--
-- EVENT FUNCTIONS
--

function initializeBattleSystem()
    debugPrint("UTBS: Initializing battle system...")
    isInitialized = true

    -- Register built-in soul modes.
    registerSoulMode('default', require('mods/utbs-lua-v1/scripts/modes/default'))

    -- Set soul mode and color.
    setSoulMode('default')
end

function openBox(speed)
    if not isInitialized then
        debugPrint("UTBS: WARNING Cannot open battle box because the battle system has not been initialized.")
        return
    end

    if speed == nil then
        speed = 1.0
    end

    boxRelativeOpenSpeed = speed

    -- Build the box if it hasn't been built yet.
    if not isBoxBuilt then
        buildBox()
        buildAdditionalUI()
    end

    -- Open the box if it isn't already open.
    if not isBoxOpen then
        debugPrint("Opening box with speed " .. speed .. "...");
        isBoxOpening = true
        isBoxClosing = false

        -- Snap to the starting box size to prevent jank.
        boxW = 0
        boxH = 0
    end

    -- Clear any attacks that might be in progress.
    clearAttacks()

    if soulMode ~= nil and soulMode.onBoxStartOpen ~= nil then
        soulMode.onBoxStartOpen(self)
    end
end

function closeBox()
    if not isInitialized then
        debugPrint("UTBS: WARNING Cannot open battle box because the battle system has not been initialized.")
        return
    end

    if not isBoxBuilt then
        debugPrint("UTBS: WARNING Cannot close battle box because the battle box has not been built.")
        return
    end

    -- Close the box if it isn't already closed.
    if isBoxOpen then
        isBoxOpening = false
        isBoxClosing = true

        -- Snap to the target box size to prevent jank.
        boxW = targetBoxWidth
        boxH = targetBoxHeight
    end

    -- Clear any attacks that might be in progress.
    clearAttacks()

    if soulMode ~= nil and soulMode.onBoxStartClose ~= nil then
        soulMode.onBoxStartClose(self)
    end
end

function setTargetBoxSize(width, height)
    targetBoxWidth = width
    targetBoxHeight = height
    isBoxLerping = true
end

function useAttack(name, data)
    -- Spawns an attack with a given set of parameters.
    -- Stringify the params table.
    if name == nil then
        debugPrint("UTBS: WARNING Cannot use attack because no attack was provided.")
        return
    end

    local attack = attackRegistry[name]
    if attack == nil then
        debugPrint("UTBS: WARNING Cannot use attack '" .. name .. "' because it does not exist. Make sure to register it!")
        return
    end

    debugPrint("UTBS: Using attack '" .. name .. "' with data: {" .. data .. "}")

    attack.spawnAttack(self, data)
end

function spawnBullet(texture, posX, posY, timerSec, damage)
    local bulletId = nextAvailableBulletId;
    nextAvailableBulletId = nextAvailableBulletId + 1;

    local bulletName = 'utbsBullet' .. bulletId

    local bullet = {
        name = bulletName,
        texture = texture,
        x = posX,
        y = posY,
        alpha = 1.0,
        velocityX = 0.0,
        velocityY = 0.0,
        angle = 0.0,
        angularVelocity = 0.0,

        scaleX = 1.0,
        scaleY = 1.0,

        collisionPadX = 0.0,
        collisionPadY = 0.0,

        fadeInDuration = 0.0,
        fadeOutDuration = 0.0,

        -- How long the bullet lasts before being destroyed automatically.
        timer = timerSec,

        -- Whether the bullet provides invincibility frames when hit.
        -- Sans' bones set this to false.
        invulnOnHit = true,

        -- If invulnOnHit is true, deal % of the player's health as damage on hit.
        -- If invulnOnHit is false, deal % of the player's health every second while touching.
        -- REMEMBER: Player starting health is 100% and max health is 200%.
        damage = damage,
    }

    bulletData[bulletName] = bullet

    makeLuaSprite(bullet.name, bullet.texture, boxX + bullet.x, boxY + bullet.y);
    setObjectCamera(bullet.name, 'camHUD')
    addLuaSprite(bullet.name, false)

    debugPrint('UTBS: Spawned bullet (' .. bullet.name .. ') at ' .. (bullet.x + boxX) .. ', ' .. (bullet.y + boxY) .. ' with texture ' .. bullet.texture .. ' and timer ' .. bullet.timer .. 'sec.')

    return bullet
end

function clearAttacks()
    -- Remove all currently active attacks from the battle box.
    for bulletName, bullet in pairs(bulletData) do
        killBulletByName(bulletName)
    end
end

function setSoulMode(modeName, forceColor)
    -- Set the mode of the soul.
    -- Mode is tied to the relevant gameplay effects. By default, it also sets the color of the soul.
    -- If forceColor is false, the color will be left as-is and you can call setSoulColor() to change it manually.
    -- If forceColor is not provided, it defaults to true.

    if modeName == nil then
        debugPrint("UTBS: WARNING Cannot set soul mode because no mode was provided.")
        return
    end

    if forceColor == nil then
        forceColor = true
    end

    local mode = soulModeRegistry[modeName]

    if mode == nil then
        debugPrint("UTBS: WARNING Cannot set soul mode to '" .. modeName .. "' because it does not exist.")
        return
    end

    debugPrint("UTBS: Setting soul mode to '" .. mode.getName() .. "'")

    if soulMode ~= nil and soulMode.onSwitchFromMode ~= nil then
        soulMode.onSwitchFromMode(self)
    end

    soulMode = mode

    if soulMode.onSwitchToMode ~= nil then
        soulMode.onSwitchToMode(self)
    end

    if forceColor then
        -- TODO: Implement this.
        setSoulColor(soulMode.getColorName())
    end
end

function setSoulColor(colorName)
    -- Set the color of the soul.
    -- Note that this is not necessarily tied to the relevant gameplay effects.
    -- Use setSoulMode(mode) to change the mode and color conveniently.

    soulColor = settings.soulColors[colorName]
end

function flashSoulColor(params)
    -- Toggles the color between the current color and `targetColor` for `duration` seconds, `frequency` times per second.
    local targetColor = params['taretColor'] or settings.soulColors['white']
    local targetAlpha = params['targetAlpha'] or 1.0
    local duration = params['duration'] or 0.5
    local frequency = params['frequency'] or 10

    soulFlashParams = {
        targetColor = targetColor,
        targetAlpha = targetAlpha,
        duration = duration,
        frequency = frequency
    }
end

function registerPlugin(path)
    if path == nil then
        debugPrint("UTBS: WARNING Cannot register plugin because no file was provided.")
        return
    end

    local plugin = require(path)

    if plugin == nil then
        debugPrint("UTBS: WARNING Cannot register plugin because file '" .. path .. "' could not be loaded.")
        return
    end

    if plugin.getPluginInfo == nil then
        debugPrint("UTBS: WARNING Could not call plugin(" .. path .. ").getPluginInfo(), does the function exist?")
        return
    end

    local info = plugin.getPluginInfo()

    if info == nil or info['name'] == nil or info['version'] == nil then
        debugPrint("UTBS: WARNING Could not call plugin("..path..").getPluginInfo(), does the function return a value?")
        return
    end

    debugPrint("UTBS: Registering plugin '" .. info['name'] .. "' version " .. info['version'])

    local pluginName = info['name']

    -- Register
    pluginRegistry[pluginName] = plugin

    -- Post-registration
    if pluginRegistry[pluginName].onRegister ~= nil then
        -- debugPrint("UTBS: Calling plugin[" .. pluginName .. "].onRegister()...")
        pluginRegistry[pluginName].onRegister(self)
        -- debugPrint("UTBS: Done calling onRegister().")
    end
end

function registerSoulMode(name, script)
    if soulModeRegistry[name] ~= nil then
        debugPrint("UTBS: WARNING Cannot register soul mode '" .. name .. "' because it already exists.")
        return
    end
    soulModeRegistry[name] = script
    script.onRegister(self)
end

function registerAttack(name, script)
    if attackRegistry[name] ~= nil then
        debugPrint("UTBS: WARNING Cannot register attack '" .. name .. "' because it already exists.")
        return
    end
    attackRegistry[name] = script
    script.onRegister(self)
end

--
-- LIFECYCLE FUNCTIONS
--

function onCreate()
	-- Called when the Lua file is loaded.
    -- Some variables are not properly initialized yet.
end

function onCreatePost()
	-- Called after the Lua file is loaded and all variables are properly initialized.
    -- NOTE: This gets called multiple times for some reason -_-
end

function onUpdate(elapsed)
    -- Called before update() every frame, update logic here.
end

function onUpdatePost(elapsed)
    -- Called after update() every frame, update logic here.

    -- Skip all the expensive logic if the battle system hasn't been initialized for this song.
    if not isInitialized then
        return
    end

    if isBoxBuilt then
        handleUpdate_BoxOpenClose(elapsed)
        if isBoxOpen then
            handleUpdate_Soul(elapsed)
            handleUpdate_Attacks(elapsed)
        end
    end

    if damageSoundTimer <= 0.0 then
        damageSoundTimer = 0.0
    else
        damageSoundTimer = damageSoundTimer - elapsed
    end
end

function onUpdateScore(miss)
    -- Called when the score is updated.
    handleUpdate_Score(true)
end

function onDestroy()
	-- triggered when the lua file is ended (Song fade out finished)
end

--
-- INTERNAL FUNCTIONS
--
function buildBox()
    -- The black box the battle takes place in.
    makeLuaSprite('utbsBattleBox', 'utbs/battleBox', settings.boxX, settings.boxY)
    setProperty('utbsBattleBox.offset.x', 50)
    setProperty('utbsBattleBox.offset.y', 50)
    setProperty('utbsBattleBox.alpha', 0)
    setProperty('utbsBattleBox.antialiasing', false)
    setObjectCamera('utbsBattleBox', 'camHUD')

    -- The slightly larger white border around the battle box.
    makeLuaSprite('utbsBattleBoxBorder', 'utbs/battleBoxBorder', settings.boxX, settings.boxY)
    setProperty('utbsBattleBoxBorder.offset.x', 50)
    setProperty('utbsBattleBoxBorder.offset.y', 50)
    setProperty('utbsBattleBoxBorder.alpha', 0)
    setProperty('utbsBattleBoxBorder.antialiasing', false)
    setObjectCamera('utbsBattleBoxBorder', 'camHUD')

    addLuaSprite('utbsBattleBoxBorder', false)
    addLuaSprite('utbsBattleBox', false)

    makeLuaSprite('utbsSoul', 'utbs/soul', settings.boxX, settings.boxY)
    setProperty('utbsSoul.offset.x', 8)
    setProperty('utbsSoul.offset.y', 8)
    setProperty('utbsSoul.scale.x', 2)
    setProperty('utbsSoul.scale.y', 2)
    setProperty('utbsSoul.alpha', 0)
    setProperty('utbsSoul.antialiasing', false)
    setObjectCamera('utbsSoul', 'camHUD')

    addLuaSprite('utbsSoul', false)

    -- Indicate that the box has been built.
    isBoxBuilt = true
end

function buildAdditionalUI()

end

function handleUpdate_BoxOpenClose(elapsed)
    if not luaSpriteExists("utbsBattleBox") then
        return
    end

    boxX = getProperty('utbsBattleBox.x')
    boxY = getProperty('utbsBattleBox.y')
    local boxA = getProperty('utbsBattleBox.alpha')

    if isBoxOpening then
        local deltaX = (settings.boxX - boxX) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaY = (settings.boxY - boxY) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaWidth = (targetBoxWidth - boxW) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaHeight = (targetBoxHeight - boxH) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaAlpha = (1.0 - boxA) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed

        boxX = boxX + deltaX
        boxY = boxY + deltaY
        boxW = boxW + deltaWidth
        boxH = boxH + deltaHeight
        boxA = boxA + deltaAlpha
    elseif isBoxClosing then
        local deltaX = (settings.boxX - boxX) / elapsed * settings.boxCloseSpeed
        local deltaY = (settings.boxY - boxY) / elapsed * settings.boxCloseSpeed
        local deltaWidth = (0 - boxW) / elapsed * settings.boxCloseSpeed
        local deltaHeight = (0 - boxH) / elapsed * settings.boxCloseSpeed
        local deltaAlpha = (0 - boxA) / elapsed * settings.boxCloseSpeed

        boxX = boxX + deltaX
        boxY = boxY + deltaY
        boxW = boxW + deltaWidth
        boxH = boxH + deltaHeight
        boxA = boxA + deltaAlpha
    elseif isBoxLerping then
        local deltaX = (settings.boxX - boxX) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaY = (settings.boxY - boxY) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaWidth = (targetBoxWidth - boxW) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaHeight = (targetBoxHeight - boxH) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed
        local deltaAlpha = (1.0 - boxA) / elapsed * settings.boxOpenSpeed * boxRelativeOpenSpeed

        boxX = boxX + deltaX
        boxY = boxY + deltaY
        boxW = boxW + deltaWidth
        boxH = boxH + deltaHeight
        boxA = boxA + deltaAlpha
    else
        if isBoxOpen then
            boxA = 1.0
        else
            boxA = 0.0
        end
    end

    -- Round if we are very close to the target value.
    if (math.ceil(boxX) == settings.boxX or math.floor(boxX) == settings.boxX) then boxX = settings.boxX end
    if (math.ceil(boxY) == settings.boxY or math.floor(boxY) == settings.boxY) then boxY = settings.boxY end
    if (isBoxOpening and (math.ceil(boxW) == targetBoxWidth or math.floor(boxW) == targetBoxWidth)) then boxW = targetBoxWidth end
    if (isBoxOpening and (math.ceil(boxH) == targetBoxHeight or math.floor(boxH) == targetBoxHeight)) then boxH = targetBoxHeight end
    if (isBoxClosing and math.floor(boxW) == 0) then boxW = 0 end
    if (isBoxClosing and math.floor(boxH) == 0) then boxH = 0 end

    -- Apply the box size before we apply the position.
    setProperty('utbsBattleBox.scale.x', boxW / settings.boxImageSize)
	setProperty('utbsBattleBox.scale.y', boxH / settings.boxImageSize)
    setProperty('utbsBattleBox.x', boxX)
	setProperty('utbsBattleBox.y', boxY)
	setProperty('utbsBattleBox.alpha', boxA)

    -- Ensure the border is visible.
	setProperty('utbsBattleBoxBorder.scale.x', (boxW + settings.boxBorderWidth) / settings.boxImageSize)
	setProperty('utbsBattleBoxBorder.scale.y', (boxH + settings.boxBorderWidth) / settings.boxImageSize)
	setProperty('utbsBattleBoxBorder.x', boxX)
	setProperty('utbsBattleBoxBorder.y', boxY)
	setProperty('utbsBattleBoxBorder.alpha', boxA)

    -- Set internal bounding box to the displayed box.
    boxLeftBound = -boxW / 2 + settings.boxBorderWidth
    boxRightBound = boxW / 2 - settings.boxBorderWidth
    boxTopBound = -boxH / 2 + settings.boxBorderWidth
    boxBottomBound = boxH / 2 - settings.boxBorderWidth

    if (isBoxOpening and boxW >= targetBoxWidth) then
        isBoxOpen = true
        isBoxOpening = false
        isBoxClosing = false
        isBoxLerping = false

        if soulMode ~= nil and soulMode.onBoxOpen ~= nil then
            soulMode.onBoxOpen(self)
        end
    end
    if (isBoxClosing and boxW <= 0) then
        isBoxOpen = false
        isBoxOpening = false
        isBoxClosing = false
        isBoxLerping = false

        if soulMode ~= nil and soulMode.onBoxClose ~= nil then
            soulMode.onBoxClose(self)
        end
    end
    if (isBoxLerping and boxW == targetBoxWidth and boxH == targetBoxHeight) then
        isBoxOpen = true
        isBoxOpening = false
        isBoxClosing = false
        isBoxLerping = false
    end
end

function handleUpdate_Soul(elapsed)
    if soulMode == nil then
        debugPrint("UTBS: WARNING No soul mode has been set.")
        return
    end

    -- Soul state
    if isBoxOpen then
        isSoulInvincible = false
        maySoulMove = true
    else
        isSoulInvincible = true
        maySoulMove = false
    end

    if soulInvulnTimer <= 0.0 then
        soulInvulnTimer = 0.0
    else
        soulInvulnTimer = soulInvulnTimer - elapsed
    end

    -- Soul color
    if soulFlashParams ~= nil then
        -- Flash when calling the function that does that.
        soulFlashTimer = soulFlashTimer + elapsed

        if soulFlashTimer >= soulFlashParams['duration'] then
            soulFlashParams = nil
            soulFlashTimer = 0.0
        else
            local frequency = soulFlashParams['frequency']
            local targetColor = soulFlashParams['targetColor']
            local targetAlpha = soulFlashParams['targetAlpha']
            local baseAlpha = getProperty('utbsBattleBox.alpha')

            local useTargetColor = math.floor(frequency * soulFlashTimer) % 2 == 0

            local finalColor = useTargetColor and targetColor or soulColor
            local finalAlpha = useTargetColor and targetAlpha or baseAlpha

            setProperty('utbsSoul.color', finalColor)
            setProperty('utbsSoul.alpha', finalAlpha)
        end
    elseif soulInvulnTimer > 0.0 then
        -- Flash white while invulnerable due to taking damage.
        local frequency = 20
        local targetColor = settings.soulColors['white']

        local useTargetColor = math.floor(frequency * soulInvulnTimer) % 2 == 0

        local finalColor = useTargetColor and targetColor or soulColor

        setProperty('utbsSoul.color', finalColor)
    else
        -- Set the soul color to the current soul mode's color and alpha.
        setProperty('utbsSoul.color', soulColor)
        local targetAlpha = getProperty('utbsBattleBox.alpha')
        setProperty('utbsSoul.alpha', targetAlpha)
    end

    -- Soul controls
    left, down, up, right, action = accessControls()

    soulMode.onSoulInput(self, elapsed, left, down, up, right, action)

    -- Constrain soul position to bounds.
    if soulXPos <= boxLeftBound then
        soulXPos = boxLeftBound
        isSoulTouchingLeft = true
    else
        isSoulTouchingLeft = false
    end
    if soulXPos >= boxRightBound then
        soulXPos = boxRightBound
        isSoulTouchingRight = true
    else
        isSoulTouchingRight = false
    end
    if soulYPos <= boxTopBound then
        soulYPos = boxTopBound
        isSoulTouchingTop = true
    else
        isSoulTouchingTop = false
    end
    if soulYPos >= boxBottomBound then
        soulYPos = boxBottomBound
        isSoulTouchingBottom = true
    else
        isSoulTouchingBottom = false
    end

    -- Use the newly set soulXPos and soulYPos to update the soul's position.
    local absSoulXPos = soulXPos + boxX
    local absSoulYPos = soulYPos + boxY

    if botPlay and settings.soulDisabledInBotPlay then
        absSoulXPos = -5000
        absSoulYPos = -5000
    end

    setProperty("utbsSoul.x", absSoulXPos)
    setProperty("utbsSoul.y", absSoulYPos)
    setProperty("utbsSoul.angle", soulAngle)

    soulMode.onSoulUpdate(self, elapsed, absSoulXPos, absSoulYPos)
end

function handleUpdate_Attacks(elapsed)
    -- Iterate over each bullet in the bulletData table.
    for bulletName, bullet in pairs(bulletData) do
        -- Update the bullet timer.
        bullet.timer = bullet.timer - elapsed

        if bullet.timer <= 0 then
            killBulletByName(bulletName)
        else
            -- Update the other bullet data.
            bullet.x = bullet.x + bullet.velocityX * elapsed
            bullet.y = bullet.y + bullet.velocityY * elapsed
            bullet.angle = bullet.angle + bullet.angularVelocity * elapsed

            local fadeAlpha = 1.0

            if bullet.fadeInDuration > 0 then
                if bullet.fadeInTimer == nil then
                    bullet.fadeInTimer = bullet.fadeInDuration
                else
                    bullet.fadeInTimer = bullet.fadeInTimer - elapsed
                end

                if bullet.fadeInTimer <= 0 then
                    bullet.fadeInTimer = 0
                else
                    fadeAlpha = fadeAlpha * (1 - (bullet.fadeInTimer / bullet.fadeInDuration))
                end
            end

            if bullet.fadeOutDuration > 0 then
                -- Fade out timer should reach 0 at the same time as the bullet timer.
                if bullet.fadeOutTimer == nil then
                    bullet.fadeOutTimer = bullet.timer
                else
                    bullet.fadeOutTimer = bullet.fadeOutTimer - elapsed
                end

                if bullet.fadeOutTimer <= 0 then
                    bullet.fadeOutTimer = 0
                elseif bullet.fadeOutTimer >= bullet.fadeOutDuration then
                    -- If the bullet hasn't started fading out yet, timer/duration will be greater than 1.
                else
                    fadeAlpha = fadeAlpha * (bullet.fadeOutTimer / bullet.fadeOutDuration)
                end
            end

            -- Update the bullet's sprite based on the bullet data.
            setProperty(bullet.name .. '.x', boxX + bullet.x)
            setProperty(bullet.name .. '.y', boxY + bullet.y)
            setProperty(bullet.name .. '.angle', bullet.angle)
            setProperty(bullet.name .. '.alpha', bullet.alpha * fadeAlpha)
            setProperty(bullet.name .. '.scale.x', bullet.scaleX)
            setProperty(bullet.name .. '.scale.y', bullet.scaleY)

            -- Call the custom update callback. This can be used to implement custom bullet behavior, including spawning more bullets.
            if bullet.onUpdate ~= nil then
                bullet.onUpdate(self, bullet, elapsed)
            end

            if not (isSoulInvincible or soulInvulnTimer > 0.0) then
                -- Calculate soul collision.

                local bulletWidth = getProperty(bullet.name .. '.width')
                local bulletHeight = getProperty(bullet.name .. '.height')

                -- Calculate collision bounds.
                -- All bullets have a square collision box. Collision pad can make it larger or smaller as needed.
                local leftBound = bullet.x - (bulletWidth / 2) - bullet.collisionPadX
                local rightBound = bullet.x + (bulletWidth / 2) + bullet.collisionPadX
                local topBound = bullet.y - (bulletHeight / 2) - bullet.collisionPadY
                local bottomBound = bullet.y + (bulletHeight / 2) + bullet.collisionPadY

                -- Complicated math incoming!
                -- We need to check if the soul is touching the bullet, while accounting for the bullet being at an angle.
                -- We do this by translating the soul's center position to the bullet's coordinate space, then checking if it's within the provided bounds.

                -- First, we need to calculate the soul's position relative to the bullet's center.
                local soulXPosRelativeToBullet = soulXPos - bullet.x
                local soulYPosRelativeToBullet = soulYPos - bullet.y

                -- Next, we need to rotate the soul's position by the bullet's angle.
                -- This is done using a rotation matrix.
                local soulXPosRelativeToBulletRotated = soulXPosRelativeToBullet * math.cos(bullet.angle) - soulYPosRelativeToBullet * math.sin(bullet.angle)
                local soulYPosRelativeToBulletRotated = soulXPosRelativeToBullet * math.sin(bullet.angle) + soulYPosRelativeToBullet * math.cos(bullet.angle)

                -- Finally, we can check if the soul is within the bounds of the bullet.
                local isTouchingBullet = (soulXPosRelativeToBulletRotated) >= leftBound
                        and (soulXPosRelativeToBulletRotated) <= rightBound
                        and (soulYPosRelativeToBulletRotated) >= topBound
                        and (soulYPosRelativeToBulletRotated) <= bottomBound

                if isTouchingBullet then
                    if bullet.onHit ~= nil then
                        -- Call the callback to see if we should try to do damage.
                        local result = bullet.onHit(self, bullet)
                        if result then
                            damagePlayer(bullet.damage, bullet.invulnOnHit)
                        end
                    else
                        -- Don't call the callback, just try to do damage.
                        damagePlayer(bullet.damage, bullet.invulnOnHit)
                    end
                end
            end
        end
    end
end

local baseScoreText = ''
function handleUpdate_Score(wasTextReset)
    if wasTextReset then
        baseScoreText = getProperty('scoreTxt.text')
        -- Trim the last 2 characters.
        baseScoreText = string.sub(baseScoreText, 1, string.len(baseScoreText) - 2)
    end

    -- Add the damage
    text = baseScoreText .. " Times Hit: " .. timesHit .. "\n"

    setProperty("scoreTxt.text", text, false)
end

function getControl(keyboardControlOptions, gamepadControlOption, useGamepad)
    -- support two controls for the action input
    if #keyboardControlOptions == 2 then
        return getPropertyFromClass('flixel.FlxG', 'keys.pressed.' .. keyboardControlOptions[1]) or getPropertyFromClass('flixel.FlxG', 'keys.pressed.' .. keyboardControlOptions[2]) or
        (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.DPAD_' .. gamepadControlOption) or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.LEFT_STICK_DIGITAL_' .. gamepadControlOption)))
    end

    return getPropertyFromClass('flixel.FlxG', 'keys.pressed.' .. keyboardControlOptions[1]) or getPropertyFromClass('flixel.FlxG', 'keys.pressed.' .. keyboardControlOptions[2]) or getPropertyFromClass('flixel.FlxG', 'keys.pressed.' .. keyboardControlOptions[3]) or
    (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.DPAD_' .. gamepadControlOption) or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.LEFT_STICK_DIGITAL_' .. gamepadControlOption)))
end

function accessControls()
    local useGamepad = false
    if (getPropertyFromClass('flixel.FlxG', 'gamepads.numActiveGamepads') > 0) then
        useGamepad = true
    end

    local left = getControl({'LEFT', 'A', 'J'}, 'LEFT', useGamepad)
    local down = getControl({'DOWN', 'S', 'K'}, 'DOWN', useGamepad)
    local up = getControl({'UP', 'W', 'I'}, 'UP', useGamepad)
    local right = getControl({'RIGHT', 'D', 'L'}, 'RIGHT', useGamepad)
    local action = getControl({'SPACE', 'Z'}, 'A', useGamepad)

    return left, down, up, right, action
end

function damagePlayer(damage, applyInvuln)
    debugPrint('UTBS: Player hit for ' .. damage .. ' damage.')

    timesHit = timesHit + 1
    handleUpdate_Score(false)

    if soulMode ~= nil and soulMode.onPlayerHit ~= nil then
        damage = soulMode.onPlayerHit(self, damage)
    end


    -- Deal damage to the player.
    setProperty('health', getProperty('health') - (damage / 100.0));

    if (applyInvuln) then
        soulInvulnTimer = settings.soulInvulnDuration

        -- Play the sound every time.
        playSound('utbs/snd_hurt1', 1);
    else
        if (damageSoundTimer <= 0) then
            damageSoundTimer = settings.damageSoundDelay
            playSound('utbs/snd_hurt1', 1);
        end
    end
end

function killBulletByName(bulletName)
    -- Kill the bullet.
    local bullet = bulletData[bulletName]
    bulletData[bulletName] = nil

    -- Call the custom kill callback. This can be used to implement custom bullet behavior, including spawning more bullets.
    if bullet.onKill ~= nil then
        bullet.onKill(self, bullet)
    end

    removeLuaSprite(bulletName)
end

function setSoulPosition(targetX, targetY)
    local xDiff = targetX - soulXPos
    local yDiff = targetY - soulYPos

    if xDiff > settings.soulMoveThreshold or yDiff > settings.soulMoveThreshold then
        isSoulMoving = true
    else
        isSoulMoving = false
    end

    soulXPos = targetX;
    soulYPos = targetY;
end

function buildState()
    -- Return a table of functions we can use to manipulate the battle system from elsewhere.
    return {
        -- Initialization
        initializeBattleSystem = initializeBattleSystem,
        getInitialized = function() return isInitialized end,

        -- Plugins
        registerPlugin = registerPlugin,
        registerSoulMode = registerSoulMode,
        registerAttack = registerAttack,

        -- Behavior functions
        openBox = openBox,
        closeBox = closeBox,
        clearAttacks = clearAttacks,
        setSoulMode = setSoulMode,
        setSoulColor = setSoulColor,
        flashSoulColor = flashSoulColor,

        -- Getter and setter functions
        getSettings = function() return settings end,

        -- Soul functions
        getSoulMayMove = function() return maySoulMove end,
        setSoulMayMove = function(mayMove) maySoulMove = mayMove end,

        getSoulIsInvincible = function() return (isSoulInvincible or soulInvulnTimer > 0.0) end,
        setSoulIsInvincible = function(isInvincible) isSoulInvincible = isInvincible end,

        getSoulPosition = function() return soulXPos, soulYPos end,
        setSoulPosition = setSoulPosition,

        getSoulAngle = function() return soulAngle end,
        setSoulAngle = function(angle) soulAngle = angle end,

        getAbsSoulPosition = function() return (soulXPos + boxX), (soulYPos + boxY) end,
        getSoulIsMoving = function() return isSoulMoving end,
        getSoulTouchingTop = function() return isSoulTouchingTop end,
        getSoulTouchingBottom = function() return isSoulTouchingBottom end,
        getSoulTouchingLeft = function() return isSoulTouchingLeft end,
        getSoulTouchingRight = function() return isSoulTouchingRight end,

        -- Attack functions
        spawnBullet = spawnBullet
    }
end

self = buildState()

return self