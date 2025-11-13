function SWEP:CreateFakeHand()
    if not IsValid(self) then
        return
    end

    if not IsValid(self.FakeHand) then
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then
            return
        end

        local hand = owner:GetHands()
        
        if not IsValid(hand) then
            return
        end

        local handmodel = hand:GetModel()
        if not handmodel then
            return
        end
        self.FakeHand = ClientsideModel(handmodel, RENDERGROUP_OPAQUE)
        self.FakeHand:SetNoDraw(true)
        self.FakeHand:SetPos(hand:GetPos())
        self.FakeHand:SetAngles(hand:GetAngles())
        self.FakeHand:SetParent(hand)
        self.FakeHand:AddEffects(EF_BONEMERGE)
        self.FakeHand:SetupBones()
    end
end


function SWEP:PostDrawViewModel(vm, weapon, ply)
    if not IsValid(self.FakeHand) then
        return
    end
    self.FakeHand:SetupBones()
    self.FakeHand:DrawModel()
end


function SWEP:CleanFakeHand()
    if IsValid(self.FakeHand) then
        self.FakeHand:Remove()
        self.FakeHand = nil
    end
end
