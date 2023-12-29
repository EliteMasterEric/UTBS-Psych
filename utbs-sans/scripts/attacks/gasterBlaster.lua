-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/attacks/gasterBlaster.lua
-- * Script handling the Gaster Blaster attack.

function getName()
    return "Gaster Blaster";
end

function onRegister(self)
    debugPrint("UTBS: Registered attack 'gasterBlaster'!");
end

function onUseAttack(self)
    -- Called when the attack is first used.
end

function onUpdateAttack(self)

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
    onUseAttack = onUseAttack,
    onUpdateAttack = onUpdateAttack,
    isAttackOver = isAttackOver,
    onEndAttack = onEndAttack
}