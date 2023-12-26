-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/main.lua
-- * Main global script for the Undertale battle system.
-- * Called in all songs but only spawns the battle system when invoked.

-- TODO: Remove.
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

-- Current collision bounds of the battle box, relative to the center (0, 0).
local boxLeftBound = 0.0
local boxRightBound = 0.0
local boxTopBound = 0.0
local boxBottomBound = 0.0

-- Current size of the battle box
local boxW = 0.0
local boxH = 0.0

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

local isSoulInvincible = false
local maySoulMove = true
local isSoulMoving = true

local soulXPos = 0.0
local soulYPos = 0.0

local timesHit = 0

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

function openBox()
    if not isInitialized then
        debugPrint("UTBS: Cannot open battle box because the battle system has not been initialized.")
        return
    end

    -- Build the box if it hasn't been built yet.
    if not isBoxBuilt then
        buildBox()
        buildAdditionalUI()
    end

    -- Open the box if it isn't already open.
    if not isBoxOpen then
        debugPrint("Opening box...")
        isBoxOpening = true
        isBoxClosing = false

        boxW = 0
        boxH = 0
    end

    -- Clear any attacks that might be in progress.
    clearAttacks()
end

function closeBox()
    if not isInitialized then
        debugPrint("UTBS: Cannot open battle box because the battle system has not been initialized.")
        return
    end

    if not isBoxBuilt then
        debugPrint("UTBS: Cannot close battle box because the battle box has not been built.")
        return
    end

    -- Close the box if it isn't already closed.
    if isBoxOpen then
        isBoxOpening = false
        isBoxClosing = true

        boxW = settings.boxWidth
        boxH = settings.boxHeight
    end

    -- Clear any attacks that might be in progress.
    clearAttacks()
end

function clearAttacks()
    -- Remove all currently active attacks from the battle box.
    -- TODO: Implement this.
end

function setSoulMode(modeName, forceColor)
    -- Set the mode of the soul.
    -- Mode is tied to the relevant gameplay effects. By default, it also sets the color of the soul.
    -- If forceColor is false, the color will be left as-is and you can call setSoulColor() to change it manually.
    -- If forceColor is not provided, it defaults to true.

    if modeName == nil then
        debugPrint("UTBS: Cannot set soul mode because no mode was provided.")
        return
    end

    if forceColor == nil then
        forceColor = true
    end

    local mode = soulModeRegistry[modeName]

    if mode == nil then
        debugPrint("UTBS: Cannot set soul mode to '" .. modeName .. "' because it does not exist.")
        return
    end

    debugPrint("UTBS: Setting soul mode to '" .. mode.getName() .. "'")

    soulMode = mode

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

function registerPlugin(name, plugin)
    if name == nil then
        debugPrint("UTBS: Cannot register plugin because no name was provided.")
        return
    end
    if plugin == nil then
        debugPrint("UTBS: Cannot register plugin '" .. name .. "' because no handler was provided.")
        return
    end
    if pluginRegistry[name] ~= nil then
        debugPrint("UTBS: Cannot register plugin '" .. name .. "' because it already exists.")
        return
    end
    pluginRegistry[name] = plugin
    -- if pluginRegistry[name].onRegister == nil then
    --     debugPrint("UTBS: Could not call plugin["..name.."].onRegister, does the function exist?")
    --     return
    -- else
    --     -- pluginRegistry[name].onRegister(self)
    -- end
end

function registerSoulMode(name, script)
    if soulModeRegistry[name] ~= nil then
        debugPrint("UTBS: Cannot register soul mode '" .. name .. "' because it already exists.")
        return
    end
    soulModeRegistry[name] = script
    script.onRegister(self)
end

function registerAttack(name, script)
    if attackRegistry[name] ~= nil then
        debugPrint("UTBS: Cannot register attack '" .. name .. "' because it already exists.")
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
        handleUpdate_Soul(elapsed)

    end
end

function onUpdateScore(miss)
    -- Called when the score is updated.
    handleUpdate_Score()
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

    -- local boxW
    -- local boxH
    local boxX = getProperty('utbsBattleBox.x')
    local boxY = getProperty('utbsBattleBox.y')
    local boxA = getProperty('utbsBattleBox.alpha')

    if isBoxOpening then
        local deltaX = (settings.boxX - boxX) / elapsed * settings.boxOpenSpeed
        local deltaY = (settings.boxY - boxY) / elapsed * settings.boxOpenSpeed
        local deltaWidth = (settings.boxWidth - boxW) / elapsed * settings.boxOpenSpeed
        local deltaHeight = (settings.boxHeight - boxH) / elapsed * settings.boxOpenSpeed
        local deltaAlpha = (1.0 - boxA) / elapsed * settings.boxOpenSpeed
        
        boxX = boxX + deltaX
        boxY = boxY + deltaY
        boxW = boxW + deltaWidth
        boxH = boxH + deltaHeight
        boxA = boxA + deltaAlpha
        -- debugPrint("deltaWidth: " .. deltaWidth .. ", deltaHeight: " .. deltaHeight .. ", boxW: " .. boxW .. ", boxH: " .. boxH .. ", elapsed: " .. elapsed)
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
    if (isBoxOpening and (math.ceil(boxW) == settings.boxWidth or math.floor(boxW) == settings.boxWidth)) then boxW = settings.boxWidth end
    if (isBoxOpening and (math.ceil(boxH) == settings.boxHeight or math.floor(boxH) == settings.boxHeight)) then boxH = settings.boxHeight end
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

    if (isBoxOpening and boxW >= settings.boxWidth) then
        isBoxOpen = true
        isBoxOpening = false
        isBoxClosing = false
    end
    if (isBoxClosing and boxW <= 0) then
        isBoxOpen = false
        isBoxOpening = false
        isBoxClosing = false
    end
end

function handleUpdate_Soul(elapsed)
    -- Soul state
    if isBoxOpen then
        isSoulInvincible = false
        maySoulMove = true
    else
        isSoulInvincible = true
        maySoulMove = false
    end

    -- Soul color
    setProperty('utbsSoul.color', soulColor)
    local targetAlpha = getProperty('utbsBattleBox.alpha')
    setProperty('utbsSoul.alpha', targetAlpha)

    -- Soul controls
    left, down, up, right, action = accessControls()

    soulMode.onSoulInput(self, elapsed, left, down, up, right, action)

    -- Constrain soul position to bounds.
    if soulXPos < boxLeftBound then 
        soulXPos = boxLeftBound
    end
    if soulXPos > boxRightBound then 
        soulXPos = boxRightBound
    end
    if soulYPos < boxTopBound then 
        soulYPos = boxTopBound
    end
    if soulYPos > boxBottomBound then 
        soulYPos = boxBottomBound
    end

    -- Use the newly set soulXPos and soulYPos to update the soul's position.
    local boxX = getProperty('utbsBattleBox.x')
    local boxY = getProperty('utbsBattleBox.y')
    setProperty("utbsSoul.x", soulXPos + boxX)
    setProperty("utbsSoul.y", soulYPos + boxY)
end

function accessControls()
    -- TODO: Is there a nicer method?
    local useGamepad = false
    if (getPropertyFromClass('flixel.FlxG', 'gamepads.numActiveGamepads') > 0) then
        useGamepad = true
    end

    local right = getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.D') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.L') or
    (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.DPAD_RIGHT') or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.LEFT_STICK_DIGITAL_RIGHT')))
    
    local left = getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.A') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.J') or
    (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.DPAD_LEFT') or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.LEFT_STICK_DIGITAL_LEFT')))
    
    local up = getPropertyFromClass('flixel.FlxG', 'keys.pressed.UP') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.W') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.I') or
    (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.DPAD_UP') or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.LEFT_STICK_DIGITAL_UP')))
    
    local down = getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.S') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.K') or
    (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.DPAD_DOWN') or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.LEFT_STICK_DIGITAL_DOWN')))

    local action = getPropertyFromClass('flixel.FlxG', 'keys.pressed.SPACE') or getPropertyFromClass('flixel.FlxG', 'keys.pressed.Z') or
    (useGamepad and (getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.A') or getPropertyFromClass('flixel.FlxG', 'gamepads.lastActive.pressed.A')))

    return left, down, up, right, action
end

function handleUpdate_Score()
    local text = getProperty("scoreTxt.text")

    -- Trim the last 2 characters.
    text = string.sub(text, 1, string.len(text) - 2)
    -- Add the damage
    text = text .. " Damage: " .. timesHit .. "\n"
    
    setProperty("scoreTxt.text", text, false)
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

        -- Getter and setter functions
        getSettings = function() return settings end,

        getSoulMayMove = function() return maySoulMove end,
        setSoulMayMove = function(mayMove) maySoulMove = mayMove end,

        getSoulIsInvincible = function() return isSoulInvincible end,
        setSoulIsInvincible = function(isInvincible) isSoulInvincible = isInvincible end,

        getSoulPosition = function() return soulXPos, soulYPos end,
        setSoulPosition = function(x, y) soulXPos = x soulYPos = y end,
    }
end

self = buildState()

return self