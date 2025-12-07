local pointshoot = pointshoot

function SWEP:MarkEffect(mark)
	if SERVER then
		return
	elseif CLIENT then
        if not istable(mark) then
            return
        end

        if #self.Marks == 1 then
            if not mark[1] then
                surface.PlaySound('hitman/mark1f.mp3')
            else
                surface.PlaySound('hitman/mark2f.mp3')
            end
        else
            if not mark[1] then
                surface.PlaySound('hitman/mark1.mp3')
            else
                surface.PlaySound('hitman/mark2.mp3')
            end
        end
	end
end

if CLIENT then
    SWEP.mark_mat = Material('hitman/mark.png')
    SWEP.mark_death_mat = Material('hitman/mark_death.png')

    function SWEP:Elasticity(x)
        if x >= 1 then return 1 end
        return x * 1.4301676 + math.sin(x * 4.0212386) * 0.55866
    end

    local white = Color(255, 255, 255)
    local pointshoot = pointshoot
    function SWEP:DrawMarks()
        local Marks = self.Marks
        if not Marks or #Marks < 1 then 
            return 
        end
        local ds = self.drawdt * 5
        cam.Start3D()
            for _, mark in ipairs(Marks) do
                local pos = pointshoot:GetMarkPos(mark)
                // print(pos)
                if not pos then 
                    continue
                end

                local size = pointshoot:GetMarkSize(mark)
                local mat = pointshoot:GetMarkType(mark) and self.mark_death_mat or self.mark_mat

                local realsize = self:Elasticity(size) * 16
                pointshoot:SetMarkSize(mark, math.Clamp(size + ds, 0, 1))

                render.SetMaterial(mat)
                render.DrawSprite(pos, realsize, realsize, white)
            end
        cam.End3D()
    end

    table.insert(SWEP.DrawHUDs, SWEP.DrawMarks)
end
