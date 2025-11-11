local marks = {} -- 马克思！！？？
local mark_mat = Material('hitman/mark.png')
local mark_death_mat = Material('hitman/mark_death.png')
local white = Color(255, 255, 255)

local function Elasticity(x)
	if x >= 1 then return 1 end
	return x * 1.4301676 + sin(x * 4.0212386) * 0.55866
end

local timecheck
hook.Add('PostDrawOpaqueRenderables', 'pointshoot.drawmark', function(bDrawingDepth, bDrawingSkybox)
    local curtime = CurTime()
    if timecheck == curtime then return end
    timecheck = curtime

    if not marks or #marks < 1 then return end

    local ds = RealFrameTime() * 5

    for i = #marks, 1, -1 do
        local Type = marks[i].type
        local pos = marks[i].pos
        local size = marks[i].size or 0
        local ent = marks[i].ent

        if not isbool(ent) and not IsValid(ent) then
            table.remove(marks, i)
            continue
        elseif not isbool(ent) then
            pos = ent:LocalToWorld(pos)
        end

        local mat = Type == 0 and mark_mat or mark_death_mat
        local realsize = Elasticity(size) * 100

        render.SetMaterial(mat)
        render.DrawSprite(pos, realsize, realsize, white)

        marks[i].size = math.Clamp(marks[i].size + ds, 0, 1)
    end
end)

function SWEP:EnableDrawMarks()
    if marks ~= self.marks then 
        marks = self.marks
    end
end

function SWEP:DisableDrawMarks()
    marks = nil
end

function SWEP:AddMark(tr)
    self.marks = self.marks or {}
    table.insert(self.marks, {
        type = tr.HitGroup == HITGROUP_HEAD and 1 or 0,
        pos = tr.HitPos,
        ent = tr.Entity
    })
end
