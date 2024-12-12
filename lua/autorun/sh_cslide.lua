CSlide = true

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")
local eGetNW2Bool = ENTITY.GetNW2Bool

function PLAYER:IsSliding()
    return eGetNW2Bool(self, "CSlide.IsSliding", false)
end

local pIsSliding = PLAYER.IsSliding
local eSetNW2Bool = ENTITY.SetNW2Bool

function PLAYER:SetIsSliding(bSliding)
    eSetNW2Bool(self, "CSlide.IsSliding", bSliding)
end

local eGetNW2Float = ENTITY.GetNW2Float

function PLAYER:GetSlideTime()
    return eGetNW2Float(self, "CSlide.Time", 0)
end

local eSetNW2Float = ENTITY.SetNW2Float

function PLAYER:SetSlideTime(flTime)
    eSetNW2Float(self, "CSlide.Time", flTime)
end

local MAT_WATER = 91
local dir = ")player/slide/%s"
local startSounds = {
    [MAT_CONCRETE] = {
        string.format(dir, "concrete_start_01.ogg"),
        string.format(dir, "concrete_start_02.ogg"),
        string.format(dir, "concrete_start_03.ogg"),
        string.format(dir, "concrete_start_04.ogg")
    },
    [MAT_DIRT] = {
        string.format(dir, "dirt_start_01.ogg"),
        string.format(dir, "dirt_start_02.ogg"),
        string.format(dir, "dirt_start_03.ogg"),
        string.format(dir, "dirt_start_04.ogg")
    },
    [MAT_GRASS] = {
        string.format(dir, "grass_start_01.ogg"),
        string.format(dir, "grass_start_02.ogg"),
        string.format(dir, "grass_start_03.ogg"),
        string.format(dir, "grass_start_04.ogg")
    },
    [MAT_METAL] = {
        string.format(dir, "solidmetal_start_01.ogg"),
        string.format(dir, "solidmetal_start_02.ogg"),
        string.format(dir, "solidmetal_start_03.ogg"),
        string.format(dir, "solidmetal_start_04.ogg")
    },
    [MAT_SAND] = {
        string.format(dir, "sand_start_01.ogg"),
        string.format(dir, "sand_start_02.ogg"),
        string.format(dir, "sand_start_03.ogg")
    },
    [MAT_SLOSH] = {
        string.format(dir, "mud_start_01.ogg"),
        string.format(dir, "mud_start_02.ogg"),
        string.format(dir, "mud_start_03.ogg"),
        string.format(dir, "mud_start_04.ogg")
    },
    [MAT_WOOD] = {
        string.format(dir, "wood_start_01.ogg"),
        string.format(dir, "wood_start_02.ogg"),
        string.format(dir, "wood_start_03.ogg"),
        string.format(dir, "wood_start_04.ogg")
    },
    [MAT_WATER] = {
        string.format(dir, "water_start_01.ogg"),
        string.format(dir, "water_start_02.ogg"),
        string.format(dir, "water_start_03.ogg"),
        string.format(dir, "water_start_04.ogg")
    }
}

startSounds[MAT_SNOW] = startSounds[MAT_SAND]
startSounds[MAT_VENT] = startSounds[MAT_METAL]

local loopSounds = {
    [MAT_CONCRETE] = string.format(dir, "concrete_loop_01.wav"),
    [MAT_DIRT] = string.format(dir, "dirt_loop_01.wav"),
    [MAT_GRASS] = string.format(dir, "grass_loop_01.wav"),
    [MAT_METAL] = string.format(dir, "metal_loop_01.wav"),
    [MAT_SAND] = string.format(dir, "sand_loop_01.wav"),
    [MAT_SLOSH] = string.format(dir, "mud_loop_01.wav"),
    [MAT_WOOD] = string.format(dir, "wood_loop_01.wav"),
    [MAT_WATER] = string.format(dir, "water_loop_01.wav")
}

local function GetSoundFilter(ply, pos)
    local filter = RecipientFilter()
    filter:AddPAS(pos)
    filter:RemovePlayer(ply)

    return filter
end

loopSounds[MAT_SNOW] = loopSounds[MAT_SAND]
loopSounds[MAT_VENT] = loopSounds[MAT_METAL]

local soundTrSub = Vector(0, 0, 32)

local function PlaySound(ply, mv)
    local origin = mv:GetOrigin()
    local filter = nil

    if SERVER then
        filter = GetSoundFilter(ply, origin)
    end

    local tr = util.TraceLine({
        start = origin,
        endpos = origin - soundTrSub,
        filter = ply
    })

    local loopSnd = loopSounds[tr.MatType] or loopSounds[MAT_CONCRETE]
    local inWater = bit.band(util.PointContents(tr.HitPos), CONTENTS_WATER) == CONTENTS_WATER

    if inWater then
        loopSnd = loopSounds[MAT_WATER]
    end

    -- FIXME: Fails to loop(?)
    ply:EmitSound(loopSnd, 60, 100, 0.25, CHAN_AUTO, 0, 0, filter)

    ply.SlideLoop = loopSnd

    local snds = startSounds[tr.MatType] or startSounds[MAT_CONCRETE]

    if inWater then
        snds = startSounds[MAT_WATER]
    end

    local sndSeed = math.Round(util.SharedRandom("CSlide.Impact", 1, #snds))
    local startSnd = snds[sndSeed]

    ply:EmitSound(startSnd, 75, 100 + math.random(-4, 4), 0.25, CHAN_BODY, 0, 0, filter)

    ply.SlideStart = startSnd
end

-- Disabled by default because it looks bad with viewmodel tilt.
local handAnim = CreateClientConVar("cl_slide_vmanip", 0, true, false, "Enables/disables the hand animation when sliding.", 0, 1)
local startTime = 0

function PLAYER:SlideStart(mv, time)
    self:SetIsSliding(true)
    self:SetSlideTime(CurTime() + time)
    self:AddEFlags(EFL_NO_DAMAGE_FORCES)

    -- TODO: why did we do this
    mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))

    -- faggot
    self.OldFriction = self:GetFriction()
    self:SetFriction(self.OldFriction * 0.1)

    local clientFirstPredict = CLIENT and IsFirstTimePredicted()

    if SERVER or clientFirstPredict then
        PlaySound(self, mv)
    end

    if clientFirstPredict and VManip and handAnim:GetBool() then
        VManip:PlayAnim("vault")
    end

    if CLIENT then
        startTime = CurTime()
    end
end

local exitSounds = {
    [MAT_CONCRETE] = {
        string.format(dir, "concrete_exit_01.ogg"),
        string.format(dir, "concrete_exit_02.ogg"),
        string.format(dir, "concrete_exit_03.ogg")
    },
    [MAT_DIRT] = {
        string.format(dir, "dirt_exit_01.ogg"),
        string.format(dir, "dirt_exit_02.ogg"),
        string.format(dir, "dirt_exit_03.ogg")
    },
    [MAT_GRASS] = {
        string.format(dir, "grass_exit_01.ogg"),
        string.format(dir, "grass_exit_02.ogg"),
        string.format(dir, "grass_exit_03.ogg")
    },
    [MAT_METAL] = {
        string.format(dir, "solidmetal_exit_01.ogg"),
        string.format(dir, "solidmetal_exit_02.ogg"),
        string.format(dir, "solidmetal_exit_03.ogg")
    },
    [MAT_SAND] = {
        string.format(dir, "sand_exit_01.ogg"),
        string.format(dir, "sand_exit_02.ogg"),
        string.format(dir, "sand_exit_03.ogg")
    },
    [MAT_SLOSH] = {
        string.format(dir, "mud_exit_01.ogg"),
        string.format(dir, "mud_exit_02.ogg"),
        string.format(dir, "mud_exit_03.ogg")
    },
    [MAT_WOOD] = {
        string.format(dir, "wood_exit_01.ogg"),
        string.format(dir, "wood_exit_02.ogg"),
        string.format(dir, "wood_exit_03.ogg"),
    },
    [MAT_WATER] = {
        string.format(dir, "water_exit_01.ogg"),
        string.format(dir, "water_exit_02.ogg"),
        string.format(dir, "water_exit_03.ogg")
    }
}

exitSounds[MAT_SNOW] = exitSounds[MAT_SAND]
exitSounds[MAT_VENT] = exitSounds[MAT_METAL]

local function StopSound(ply, mv)
    ply:StopSound(ply.SlideLoop or "")

    local origin = mv:GetOrigin()
    local filter = nil

    if SERVER then
        filter = GetSoundFilter(ply, origin)
    end

    local tr = util.TraceLine({
        start = origin,
        endpos = origin - soundTrSub,
        filter = ply
    })

    local snds = exitSounds[tr.MatType] or exitSounds[MAT_CONCRETE]
    local inWater = bit.band(util.PointContents(tr.HitPos), CONTENTS_WATER) == CONTENTS_WATER

    if inWater then
        snds = exitSounds[MAT_WATER]
    end

    local sndSeed = math.Round(util.SharedRandom("CSlide.Exit", 1, #snds))
    local exitSnd = snds[sndSeed]

    ply:EmitSound(exitSnd, 75, 100 + math.random(-4, 4), 0.25, CHAN_BODY, 0, 0, filter)

    ply.SlideExit = exitSnd
end

local cooldown = CreateConVar("sv_cslide_cooldown", 0.5, cf, "Controls how long players have to wait to slide again.", 0)
local endTime = 0

function PLAYER:SlideCancel(mv)
    self:SetIsSliding(false)
    self:SetSlideTime(self:IsFlagSet(FL_ONGROUND) and CurTime() + self:GetUnDuckSpeed() + cooldown:GetFloat() or 0)
    self:SetNW2Float("CSlide.LastZ", nil)
    self:RemoveEFlags(EFL_NO_DAMAGE_FORCES)

    -- faggot
    self:SetFriction(self.OldFriction)

    local clientFirstPredict = CLIENT and IsFirstTimePredicted()

    if SERVER or clientFirstPredict then
        StopSound(self, mv)
    end

    if CLIENT then
        endTime = CurTime()
    end
end

local moveRW = false

hook.Add("StartCommand", "CSlide.PreventSprint", function(ply, cmd)
    if !pIsSliding(ply) then
        return
    end

    cmd:RemoveKey(IN_WALK)
    cmd:RemoveKey(IN_SPEED)
    cmd:ClearMovement()

    -- TODO: Compare to minSpeed if we ever try adding this back.
    -- Disabled for now, doesn't feel good and reduces responsiveness in my opinion.
    -- local slideEnd = math.max(0.1, ply:GetVelocity():Length() * 0.01)

    -- if (ply:GetSlideTime() - CurTime()) / slideEnd >= 0.45 then
    --     cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
    -- end
end)

local IN_MOVE = bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)

local function ShouldStartSlide(ply, mv, cmd, maxSpeed, velLength)
    if pIsSliding(ply) then
        return false
    end

    -- COMMENT: IN_SPEED check might break sliding for some users
    if !mv:KeyDown(IN_MOVE) or !mv:KeyDown(IN_DUCK) or !mv:KeyDown(IN_SPEED) then
        return false
    end

    if !ply:IsFlagSet(FL_ONGROUND) then
        return false
    end

    -- ISSUE: May be causing prediction issues.
    -- if !ply:IsFlagSet(FL_ANIMDUCKING) then
    --     return false
    -- end

    local curTime = CurTime()

    if ply:GetSlideTime() >= curTime then
        return false
    end

    -- COMMENT:
    local minSpeed = maxSpeed * 0.5 -- (maxSpeed + crouchMaxSpeed) / 2

    -- COMMENT:
    if velLength < minSpeed then
        return false
    end

    return true
end

local function RefreshLoopSound(ply, origin)
    if !ply.SlideLoop then
        return
    end

    local filter = nil

    if SERVER then
        filter = GetSoundFilter(ply, origin)
    end

    local tr = util.TraceLine({
        start = origin,
        endpos = origin - soundTrSub,
        filter = ply
    })

    local loopSnd = loopSounds[tr.MatType] or loopSounds[MAT_CONCRETE]
    local inWater = bit.band(util.PointContents(tr.HitPos), CONTENTS_WATER) == CONTENTS_WATER

    if inWater then
        loopSnd = loopSounds[MAT_WATER]
    end

    local clientFirstPredict = CLIENT and IsFirstTimePredicted()

    if !clientFirstPredict or loopSnd == ply.SlideLoop then
        return
    end

    ply:StopSound(ply.SlideLoop)

    -- FIXME: Fails to loop(?)
    ply:EmitSound(loopSnd, 60, 100, 0.25, CHAN_AUTO, 0, 0, filter)

    ply.SlideLoop = loopSnd
end

local function SlideEffect(ply, mv)
    if CLIENT and !IsFirstTimePredicted() then
        return
    end

    local origin = mv:GetOrigin()
    local filter = !game.SinglePlayer()

    if CLIENT and !filter then
        filter = nil
    end

    -- HACK: util.Effect networks to all clients which results in effects being delayed for the current prediction player.
    -- Denying networking to that player means we can have the effect on their client follow their origin without doubling.
    if SERVER and filter then
        filter = RecipientFilter()
        filter:AddPVS(origin)
        filter:RemovePlayer(ply)
    end

    local effect = EffectData()
    effect:SetOrigin(mv:GetOrigin())
    effect:SetScale(1)
    effect:SetFlags(ply:WaterLevel())

    util.Effect("slidedust", effect, true, filter)
end

local pGetWalkSpeed = PLAYER.GetWalkSpeed
local pGetRunSpeed = PLAYER.GetRunSpeed
local cf = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local enabled = CreateConVar("sv_cslide", 1, cf, "Enables/disables sliding for players serverside.", 0, 1)
local speedCap = CreateConVar("sv_cslide_max_speed", -1, cf, "Limits the max velocity players can reach. Set to 0 for infinite, -1 for auto-calculate.", -1)

-- TODO: real slide sequence via dynabase
hook.Add("SetupMove", "CSlide", function(ply, mv, cmd)
    if !enabled:GetBool() then
        return
    end

    if moveRW == false then
        moveRW = GetConVar("sv_kait_enabled") or GetConVar("kait_movement_enabled")
    end

    local runSpeed = pGetRunSpeed(ply)
    local moveRWEnabled = moveRW and moveRW:GetBool()

    -- WORKAROUND: Movement reworked mults run speed by 1.5 for some reason.
    if moveRWEnabled then
        runSpeed = runSpeed / 1.5
    end

    local isSliding = pIsSliding(ply)
    local velocity = mv:GetVelocity()
    local velLength = velocity:Length()
    local walkSpeed = pGetWalkSpeed(ply)

    if !isSliding then
        local shouldSlide = ShouldStartSlide(ply, mv, cmd, runSpeed, velLength)

        if !shouldSlide then
            return
        end

        local slideSpeed = velLength / walkSpeed

        ply:SlideStart(mv, slideSpeed)

        isSliding = true
    end

    if !isSliding then
        return
    end

    local origin = mv:GetOrigin()

    -- If the material we're on changes, kill the current loop sound and start a new one.
    RefreshLoopSound(ply, origin)

    local lastZ = ply:GetNW2Float("CSlide.LastZ", origin.z - velocity:GetNormalized().z)

    -- COMMENT: Controls whether slide time and speed will be increased or decreased.
    local speedMul = math.Clamp(lastZ - origin.z, -1.0, 1.0) * engine.TickInterval() -- * 0.5
    local curTime = CurTime()

    ply:SetSlideTime(math.min(ply:GetSlideTime() + speedMul * velLength / walkSpeed, curTime + 1.5))

    local defMax = speedCap:GetFloat()
    local maxSpeed = defMax == -1 and runSpeed * 1.5
        or defMax == 0 and math.huge
        or defMax

    local newVelocity = Vector(
        math.Clamp(velocity.x * (1 + speedMul), -maxSpeed, maxSpeed),
        math.Clamp(velocity.y * (1 + speedMul), -maxSpeed, maxSpeed),
        velocity.z
    )

    local onGround = ply:IsFlagSet(FL_ONGROUND)

    if !onGround then
        newVelocity.z = ply:GetJumpPower()
    end

    mv:SetVelocity(newVelocity)

    local minSpeed = walkSpeed * ply:GetCrouchedWalkSpeed()

    if mv:KeyReleased(IN_DUCK) or !onGround or velLength <= minSpeed or curTime > ply:GetSlideTime() then
        ply:SlideCancel(mv)
    end

    ply:SetNW2Float("CSlide.LastZ", origin.z)

    SlideEffect(ply, mv)
end)

hook.Add("PlayerFootstep", "CSlide.SilenceFootsteps", function(ply)
    if pIsSliding(ply) then
        return true
    end
end)

if CLIENT then
    local pShouldDrawLocalPlayer = PLAYER.ShouldDrawLocalPlayer
    local shouldRoll = CreateClientConVar("cl_cslide_roll", 1, true, false, "Enables/disables view roll when sliding.", 0, 1)
    local lastRoll = 0
    local t = 0.05

    hook.Add("CalcView", "CSlide.ViewRoll", function(ply, origin, angles, fov)
        if !shouldRoll:GetBool() then
            return
        end

        local sliding = pIsSliding(ply)

        if pShouldDrawLocalPlayer(ply) or (!sliding and lastRoll == 0) then
            return
        end

        t = sliding and 0.05 or t + (2 * FrameTime())

        local roll = 0

        if sliding then
            local velocity = ply:GetVelocity()
            local slideAngle = velocity:Angle()
            local slideTime = math.max(0.1, math.sqrt(velocity:Length()) * 0.1)
            local frac = (ply:GetSlideTime() - CurTime()) / slideTime

            -- REFERENCE: https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/baseplayer_shared.cpp#L1728
            roll = math.Clamp((slideAngle:Right():Dot(angles:Forward()) * 15) * frac, -30, 30)
        end

        lastRoll = Lerp(math.ease.InSine(t), lastRoll, roll)
        angles.r = lastRoll
    end)

    local eGetTable = ENTITY.GetTable
    local eGetOwner = ENTITY.GetOwner

    local function ShouldTilt(wep)
        local wepTable = eGetTable(wep)

        if wepTable.SuppressSlidingViewModelTilt then
            return false
        end

        local ply = eGetOwner(wep)

        if !IsValid(ply) or !ply:IsPlayer() then
            return false
        end

        -- mw creators love to make their own sub-base and i'm too lazy to find the special ENT.IsMWWep var
        if string.find(wepTable.Base or "", "mg_base") and isfunction(wepTable.GetToggleAim) and wep:GetToggleAim() then
            return false
        end

        if wepTable.ARC9 and wep:GetInSights() then
            return false
        end

        if string.Left(wepTable.Base or "", 5) == "bobs_" and wep:GetIronsights() then
            return false
        end

        if wepTable.CW20Weapon and wepTable.dt.State == CW_AIMING then
            return
        end

        if wepTable.ArcCW and wep:GetState() == ArcCW.STATE_SIGHTS then
            return false
        end

        if wepTable.IsTFAWeapon and wep:GetIronSights() then
            return false
        end

        return true, ply
    end

    local vmTilt = CreateClientConVar("cl_cslide_vm", 1, true, false, "Enables/disables viewmodel tilt when sliding.", 0, 1)
    local transitionTime = 0.25
    local originMod = Vector(0, 2, -6)

    hook.Add("CalcViewModelView", "CSlide.TiltVM", function(wep, vm, oldPos, oldAng, pos, ang)
        if !vmTilt:GetBool() then
            return
        end

        local shouldTilt, owner = ShouldTilt(wep)

        if !shouldTilt then
            return
        end

        local isSliding = pIsSliding(owner)
        local time = isSliding and startTime or endTime
        local posFrac = math.Clamp(math.TimeFraction(time, time + transitionTime, CurTime()), 0, 1)

        if !isSliding then
            -- Opposite of our above posFrac calc, 0 --> 1 to 1 --> 0.
            local maxPos = math.Clamp((endTime - startTime) / transitionTime, 0, 1)

            posFrac = math.Clamp(maxPos - posFrac, 0, 1)
        end

        -- Don't waste resources modifying our vm when the result will be the same.
        if posFrac == 0 then
            return
        end

        local posProgress = math.ease.InOutQuad(posFrac)

        pos:Add(LerpVector(posProgress, vector_origin, LocalToWorld(originMod, angle_zero, vector_origin, ang)))
        ang:RotateAroundAxis(ang:Forward(), Lerp(posProgress, 0, -45))
    end)
end