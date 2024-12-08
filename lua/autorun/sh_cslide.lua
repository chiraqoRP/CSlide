CSlide = true

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

function PLAYER:IsSliding()
    return self:GetNW2Bool("CSlide.IsSliding", false)
end

function PLAYER:SetIsSliding(bSliding)
    self:SetNW2Bool("CSlide.IsSliding", bSliding)
end

function PLAYER:GetSlideTime()
    return self:GetNW2Float("CSlide.Time", 0)
end

function PLAYER:SetSlideTime(flTime)
    self:SetNW2Float("CSlide.Time", flTime)
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
    [MAT_CONCRETE] = string.format(dir, "concrete_loop.wav"),
    [MAT_DIRT] = string.format(dir, "dirt_loop.wav"),
    [MAT_GRASS] = string.format(dir, "grass_loop.wav"),
    [MAT_METAL] = string.format(dir, "metal_loop.wav"),
    [MAT_SAND] = string.format(dir, "sand_loop.wav"),
    [MAT_SLOSH] = string.format(dir, "mud_loop.wav"),
    [MAT_WOOD] = string.format(dir, "wood_loop.wav"),
    [MAT_WATER] = string.format(dir, "water_loop.wav")
}

loopSounds[MAT_SNOW] = loopSounds[MAT_SAND]
loopSounds[MAT_VENT] = loopSounds[MAT_METAL]

local soundTrSub = Vector(0, 0, 32)

local function PlaySound(ply, mv)
    -- ply:StopSound(ply.SlideExit or "")

    local origin = mv:GetOrigin()
    local filter = nil

    if SERVER then
        filter = RecipientFilter()
        filter:AddPAS(origin)
        filter:RemovePlayer(ply)
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

local handAnim = CreateClientConVar("cl_slide_vmanip", 0, true, false, "", 0, 1)
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

    if SERVER or clientFirstPredict then
        print("started sliding")
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
    -- ply:StopSound(ply.SlideStart or "")

    local origin = mv:GetOrigin()
    local filter = nil

    if SERVER then
        filter = RecipientFilter()
        filter:AddPAS(origin)
        filter:RemovePlayer(ply)
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

    print("you are triggering multiple times ", exitSnd)

    ply:EmitSound(exitSnd, 75, 100 + math.random(-4, 4), 0.25, CHAN_BODY, 0, 0, filter)

    ply.SlideExit = exitSnd
end

local cooldown = 0.5
local endTime = 0

function PLAYER:SlideCancel(mv)
    self:SetIsSliding(false)
    self:SetSlideTime(self:OnGround() and CurTime() + self:GetUnDuckSpeed() + cooldown or 0)
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

    if SERVER or clientFirstPredict then
        print("stopped sliding")
    end
end

local moveRW = false

hook.Add("StartCommand", "CSlide.PreventSprint", function(ply, cmd)
    if !ply:IsSliding() then
        return
    end

    cmd:RemoveKey(IN_WALK)
    cmd:RemoveKey(IN_SPEED)
    cmd:ClearMovement()

    -- TODO: compare velocity to runspeed
    -- local slideEnd = math.max(0.1, ply:GetVelocity():Length() * 0.01)

    -- if (ply:GetSlideTime() - CurTime()) / slideEnd > 0.6 then
    --     cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
    -- end
end)

local IN_MOVE = bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)

local function ShouldStartSlide(ply, mv, cmd, maxSpeed, velLength)
    if ply:IsSliding() then
        return false
    end

    -- COMMENT: IN_SPEED check might break sliding for some users
    if !mv:KeyDown(IN_MOVE) or !mv:KeyDown(IN_DUCK) or !mv:KeyDown(IN_SPEED) then
        return false
    end

    if !ply:IsFlagSet(FL_ONGROUND) then
        return false
    end

    -- WARNING: May be causing prediction issues.
    -- if !ply:IsFlagSet(FL_ANIMDUCKING) then
    --     return false
    -- end

    local curTime = CurTime()

    if ply:GetSlideTime() >= curTime then
        return false
    end

    -- if math.abs(ply:GetWalkSpeed() - maxSpeed) < 25 then
    --     return false
    -- end

    -- local crouchMaxSpeed = ply:GetWalkSpeed() * ply:GetCrouchedWalkSpeed()

    -- COMMENT:
    local minSpeed = maxSpeed * 0.5 -- (maxSpeed + crouchMaxSpeed) / 2

    -- COMMENT:
    if velLength < minSpeed then
        return false
    end

    return true
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

local cf = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local enabled = CreateConVar("sv_cslide", 1, cf, "", 0, 1)
local speedCap = CreateConVar("sv_cslide_max_speed", -1, cf, "Limits the max velocity players can reach. Set to 0 for infinite, -1 for auto-calculate.", -1)

-- TODO: real slide sequence via dynabase
hook.Add("SetupMove", "CSlide", function(ply, mv, cmd)
    if !enabled:GetBool() then
        return
    end

    if moveRW == false then
        moveRW = GetConVar("sv_kait_enabled") or GetConVar("kait_movement_enabled")
    end

    local runSpeed = ply:GetRunSpeed()
    local moveRWEnabled = moveRW and moveRW:GetBool()

    -- WORKAROUND: Movement reworked mults run speed by 1.5 for some reason.
    if moveRWEnabled then
        runSpeed = runSpeed / 1.5
    end

    local velocity = mv:GetVelocity()
    local velLength = velocity:Length()
    local walkSpeed = ply:GetWalkSpeed()

    if !ply:IsSliding() then
        local shouldSlide = ShouldStartSlide(ply, mv, cmd, runSpeed, velLength)

        if !shouldSlide then
            return
        end

        local slideSpeed = velLength / walkSpeed

        ply:SlideStart(mv, slideSpeed)
    end

    if !ply:IsSliding() then
        return
    end

    local origin = mv:GetOrigin()
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
    if ply:IsSliding() then
        return true
    end
end)

if CLIENT then
    local shouldRoll = CreateClientConVar("cl_cslide_roll", 1, true, false, "Enables/disables view roll when sliding.", 0, 1)
    local lastRoll = 0
    local t = 0.05

    hook.Add("CalcView", "CSlide.ViewRoll", function(ply, origin, angles, fov)
        if !shouldRoll:GetBool() then
            return
        end

        local sliding = ply:IsSliding()

        if ply:ShouldDrawLocalPlayer() or (!sliding and lastRoll == 0) then
            return
        end

        t = sliding and 0.05 or t + (2 * FrameTime())

        local roll = 0

        if sliding then
            local velocity = ply:GetVelocity()
            local slideAngle = velocity:Angle()
            local slideTime = math.max(0.1, math.sqrt(velocity:Length()) * 0.1)

            roll = math.Clamp((slideAngle:Right():Dot(angles:Forward()) * 15) * ((ply:GetSlideTime() - CurTime()) / slideTime), -30, 30)
        end

        lastRoll = Lerp(math.ease.InSine(t), lastRoll, roll)
        angles.r = lastRoll
    end)

    local function ShouldTilt(wep)
        local wepTable = wep:GetTable()

        if wepTable.SuppressSlidingViewModelTilt then
            return false
        end

        local ply = wep:GetOwner()

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

        if string.find(wepTable.Base or "", "bobs_") and wep:GetIronsights() then
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

    local vmTilt = CreateClientConVar("cl_cslide_vm", 1, true, false, "Enable viewmodel tilt when sliding.", 0, 1)
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

        local isSliding = owner:IsSliding()
        local time = isSliding and startTime or endTime
        local posFrac = math.Clamp(math.TimeFraction(time, time + transitionTime, CurTime()), 0, 1)

        if !isSliding then
            -- Opposite of our above posFrac calc
            local maxPos = math.Clamp((endTime - startTime) / transitionTime, 0, 1)

            posFrac = math.Clamp(maxPos - posFrac, 0, 1)
        end

        -- comment: optimization :)
        if posFrac == 0 then
            return
        end

        local posProgress = math.ease.InOutQuad(posFrac)

        pos:Add(LerpVector(posProgress, vector_origin, LocalToWorld(originMod, angle_zero, vector_origin, ang)))
        ang:RotateAroundAxis(ang:Forward(), Lerp(posProgress, 0, -45))
    end)
end

concommand.Add("slidestop", function(ply, cmd, args, argStr)
    ply:SlideCancel()
end)