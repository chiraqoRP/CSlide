-- REFERENCE: https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/client/c_vehicle_jeep.cpp#L279

local traceUp = Vector(0, 0, 8)
local traceDown = Vector(0, 0, 16)
function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local scale = data:GetScale()
	local underwater = data:GetFlags() > 0
	local surfaceColor = render.GetSurfaceColor(
		pos + traceUp,
		pos - traceDown
	)

	if underwater then
		surfaceColor = (surfaceColor * 0.25 + Vector(0.75, 0.75, 0.75)) * 255
		scale = scale / 2
	end

	local offset = Vector(
		pos.x + math.Rand(scale * -16.0, scale * 16.0),
		pos.y + math.Rand(scale * -16.0, scale * 16.0),
		pos.z
	)

	local emitter = ParticleEmitter(offset, false)
	emitter:SetNearClip(32.0, 64.0)

	if !emitter then
		return
	end

	local particle = emitter:Add(underwater and "effects/splash4" or "particle/particle_smokegrenade", offset)

	if !particle then
		return
	end

	particle:SetDieTime(math.Rand(0.25, 0.5))

	local velocity = VectorRand(-1.0, 1.0)
	velocity:Normalize()
	velocity.z = velocity.z + math.Rand(16.0, 32.0) * (scale * 2.0)

	particle:SetVelocity(velocity)

	local colorBase = math.random(100, 150)
	local color = Color(
		16 + (surfaceColor.r * colorBase),
		8 + (surfaceColor.g * colorBase),
		(surfaceColor.b * colorBase)
	)

	particle:SetColor(color.r, color.g, color.b)
	particle:SetStartAlpha(math.Rand(64.0 * scale, 128.0 * scale))
	particle:SetEndAlpha(0)
	particle:SetStartSize(math.random(16, 24) * scale)
	particle:SetEndSize(math.random(32, 48) * scale)
	particle:SetRoll(math.random(0, 360))
	particle:SetRollDelta(math.Rand(-2.0, 2.0))
	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end