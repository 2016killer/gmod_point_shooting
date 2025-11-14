pointshoot.Marks = {}
pointshoot.mark_mat = Material('hitman/mark.png')
pointshoot.mark_death_mat = Material('hitman/mark_death.png')

function pointshoot:Elasticity(x)
	if x >= 1 then return 1 end
	return x * 1.4301676 + math.sin(x * 4.0212386) * 0.55866
end

local white = Color(255, 255, 255)
function pointshoot:DrawMarks()
    local Marks = self.Marks
    if not Marks or #Marks < 1 then 
        return 
    end
    local ds = self.drawdt * 5
    cam.Start3D()
        for _, mark in ipairs(Marks) do
            local pos = self:GetMarkPos(mark)
            // print(pos)
            if not pos then 
                continue
            end

            local size = self:GetMarkSize(mark)
            local mat = self:GetMarkType(mark) and mark_death_mat or mark_mat

            local realsize = self:Elasticity(size) * 16
            self:SetMarkSize(mark, math.Clamp(size + ds, 0, 1))

            render.SetMaterial(mat)
            render.DrawSprite(pos, realsize, realsize, white)
        end
    cam.End3D()  
end


