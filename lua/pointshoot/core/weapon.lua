function SWEP:ServerFire(wp, mark)
	if not IsValid(wp) then
		return
	end

	local endpos = self:GetMarkPos(mark)
	if not endpos then
		return
	end
	local owner = wp:GetOwner()
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

	wp:FireBullets(bulletInfo)
	wp:SetClip1(wp:Clip1() - 1)
end

function SWEP:ClientFire(dir, rate, index)
	if not dir then return end

	local vm = self:GetOwner():GetViewModel(index)
	
	if not IsValid(vm) then return end
	
	local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
	
	if (seq == -1) then return end
	
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)

	self:EmitSound('Weapon_Pistol.Single')
end