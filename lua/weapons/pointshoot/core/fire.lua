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
    local bulletInfo = self.BulletInfo
	bulletInfo.Attacker = owner
	bulletInfo.Inflictor = self
	bulletInfo.Damage = 1000
	bulletInfo.Dir = (endpos - start):GetNormal()
	bulletInfo.Src = self:GetPos()
	self:FireBullets(bulletInfo)
	debugoverlay.Sphere(endpos, 5, 2, blue)
	debugoverlay.Line(start, endpos, 2, blue)
end

function SWEP:ClientFire(mark)
	local vm = self:GetOwner():GetViewModel(0)
	
	if not IsValid(vm) then
		return
	end
	
	local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
	
	if (seq == -1) then
		return
	end
	
	local endpos = self:GetMarkPos(mark)
	if not endpos then
		return
	end

	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)

	local start = EyePos()
	
	self:AddBulletTrail(start, endpos, 3, 200, 1000)
	self:EmitSound('Weapon_Pistol.Single')

	debugoverlay.Sphere(endpos + Vector(0, 0, 10), 5, 2, yellow)
	debugoverlay.Line(start, endpos + Vector(0, 0, 10), 2, yellow)
end
