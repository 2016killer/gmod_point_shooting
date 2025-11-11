local marks = {} -- 马克思！！？？
local mark_mat = Material('hitman/mark.png')
local mark_death_mat = Material('hitman/mark_death.png')
local white = Color(255, 255, 255)

local function Elasticity(x)
	if x >= 1 then return 1 end
	return x * 1.4301676 + math.sin(x * 4.0212386) * 0.55866
end

local timecheck
hook.Add('HUDPaint', 'pointshoot.drawmark', function()
    if not marks or #marks < 1 then return end
    cam.Start3D()
        local curtime = CurTime()
        local ds = nil
        if timecheck == curtime then 
            ds = 0
        else
            ds = RealFrameTime() * 5
            timecheck = curtime
        end

        for i = #marks, 1, -1 do
            local mark = marks[i]
            local Type = mark.type
            local pos = mark.pos
            local size = mark.size or 0
            local ent = mark.ent

            if not isbool(ent) and not IsValid(ent) then
                table.remove(marks, i)
                continue
            elseif not isbool(ent) then
                pos = ent:LocalToWorld(pos)
            end

            local mat = Type == 0 and mark_mat or mark_death_mat
            local realsize = Elasticity(size) * 8

            render.SetMaterial(mat)
            render.DrawSprite(pos, realsize, realsize, white)

            mark.size = math.Clamp(size + ds, 0, 1)
        end
    cam.End3D()
end)

function SWEP:EnableDrawMarks()
    self.marks = self.marks or {}
    if marks ~= self.marks then 
        marks = self.marks
    end
end

function SWEP:DisableDrawMarks()
    marks = nil
    self.marks = {}
end

function SWEP:AddMark(tr)
    table.insert(self.marks, {
        type = tr.HitGroup == HITGROUP_HEAD and 1 or 0,
        pos = IsValid(tr.Entity) and tr.Entity:WorldToLocal(tr.HitPos) or tr.HitPos,
        ent = IsValid(tr.Entity) and tr.Entity or false
    })
end
