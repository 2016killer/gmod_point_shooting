function SWEP:FireBullet(bulletInfo)
    
end


function SWEP:Fire(endpos)
	local vm = self:GetOwner():GetViewModel(0)
	
	if not IsValid(vm) then
		return
	end
	
	local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
	
	if (seq == -1) then
		return
	end
	
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)

	self:AddBulletTrail(EyePos(), endpos, 5, 100, 500, 0.5)

    return true
end

