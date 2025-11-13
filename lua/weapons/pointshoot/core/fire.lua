local blue = Color(0, 150, 255)
local yellow = Color(255, 255, 0)
function SWEP:ServerFire(mark)
	local endpos = self:GetMarkPos(mark)
	if not endpos then
		return
	end
	local owner = self:GetOwner()
	if not IsValid(owner) then
		return
	end

	local start = owner:EyePos()
	local bulletInfo = {
		Spread = Vector(0, 0, 0),
		Force = 1000,
		Damage = 10000,
		Num = 1,
		Tracer = 0,
		Attacker = owner,
		Inflictor = self,
		Damage = 1000,
		Dir = (endpos - start):GetNormal(),
		Src = start
	}
	self:FireBullets(bulletInfo)
	// debugoverlay.Sphere(endpos, 5, 2, blue)
	// debugoverlay.Line(start, endpos, 2, blue)
end

function SWEP:ClientFire(dir)
	if not dir then return end

	local vm = self:GetOwner():GetViewModel(0)
	
	if not IsValid(vm) then return end
	
	local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
	
	if (seq == -1) then return end
	
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)

	local start = EyePos()
	
	self:AddBulletTrail(start, dir, 3, 200, 1000)
	self:EmitSound('Weapon_Pistol.Single')
end
