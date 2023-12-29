-- =======================
-- UNDERTALE BATTLE SYSTEM
-- =======================
--
-- scripts/attacks/singleBone.lua
-- * Script handling the Sans attack which sends a single bone across the screen.

local timer = 4
local damage = 50

function getName()
    return "Single Bone";
end

function onRegister(self)
    debugPrint("UTBS: Registered attack 'singleBone'!");
end

function spawnAttack(self, data)
    debugPrint(tostring(data))

    -- Called when the attack is first used.
    -- This should return a table of functions and variables to keep track of the attack.
    local bone = self.spawnBullet('utbs/attacks/spr_s_boneloop_0', -200, 50, timer, damage)

    -- Additional initialization
    bone.scaleX = 2
    bone.scaleY = 2
    bone.velocityX = 125
    bone.fadeInDuration = 0.25
    bone.fadeOutDuration = 0.25

    -- Define callback functions which we can execute. These are optional!
    bone.onUpdate = onBoneUpdate
    bone.onHit = onBoneHit
    bone.onKill = onBoneKill
end

function onBoneUpdate(self, bullet, elapsed)
    -- Called every frame while the bullet is active.

    -- debugPrint('Custom update function for ' .. bullet.name .. ' (' .. tostring(bullet.timer) .. ')!')
end

function onBoneHit(self, bullet)
    -- Called when the bullet hits a player
    -- Return true to deal damage to the player (if no callback is assigned, this is true by default)
    return true
end

function onBoneKill(self, bullet)
    -- Called when the bullet is destroyed (either by timer or by the box closing).
    -- You don't have to kill the sprite here, that's done automatically.
end

return {
    getName = getName,
    onRegister = onRegister,
    spawnAttack = spawnAttack,
}