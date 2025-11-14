function pointshoot:ServerFire(wp, mark)
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

function pointshoot:ClientFire(dir, rate, index)
	if not dir then return end

	local vm = self:GetOwner():GetViewModel(index)
	
	if not IsValid(vm) then return end
	
	local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
	
	if (seq == -1) then return end
	
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)

	self:EmitSound('Weapon_Pistol.Single')
end


function pointshoot:WeaponParse(wp)
	if not IsValid(wp) or wp:Clip1() <= 0 then return end

	local class = wp:GetClass()
	local isscripted = wp:IsScripted()
	if not isscripted then
		return self.noscriptedguns[class]
	else
		local istfa = weapons.IsBasedOn(class, 'tfa_gun_base')
	end
end


pointshoot.noscriptedguns = {
	['weapon_pistol'] = {
		interval = 0.1,
		Damage = 10
	},
	['weapon_357'] = {
		interval = 0.3,
		Damage = 60
	},
	['weapon_ar2'] = {
		interval = 0.05,
		Damage = 20
	},
	['weapon_crossbow'] = {
		interval = 0.5,
		Damage = 150,
	},
	['weapon_shotgun'] = {
		interval = 0.5,
		Damage = 45,
	},
	['weapon_smg1'] = {
		interval = 0.01,
		Damage = 6,
	},
}
