-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/attacks/sineBones.lua
-- * Script handling the Sans attack which sends bones across the screen in a wave.

function getName()
    return "Sine Bones";
end

function onRegister(self)
    debugPrint("UTBS: Registered attack 'sineBones'!");
end

function spawnAttack(self, params)
    -- Called when the attack is first used.
    -- This should return a table of functions and variables to keep track of the attack.

end

function buildAttack()


    return {
        -- Attack info
        getName = getName,

        spriteGroup = {},
    }
end

function isAttackOver(self)
    -- Called to check if the attack is over.
    -- If this returns true, the attack will be ended by the main script.
    return false;
end

function onEndAttack(self)
    -- Called when the attack is ended by the main script.
    -- Use this for cleanup.
end

return {
    getName = getName,
    onRegister = onRegister,
    spawnAttack = spawnAttack,
}