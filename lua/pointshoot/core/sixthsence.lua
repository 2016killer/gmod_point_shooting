--[[
    作者: 白狼
]]
if SERVER then return end


sixthsense = sixthsense or {}
local sixthsense = sixthsense
concommand.Add('sixthsense_debug', function()
	PrintTable(sixthsense)
end)

local sixthsense_rt = GetRenderTarget('sixthsense_rt',  ScrW(), ScrH())
local sixthsense_mat = CreateMaterial('sixthsense_mat', 'UnLitGeneric', {
	['$basetexture'] = sixthsense_rt:GetName(),
	['$translucent'] = 1,
	['$vertexcolor'] = 1,
	['$alpha'] = 1
})
sixthsense.color1 = Color(0, 0, 0, 100)
sixthsense.color2 = Color(255, 255, 255, 255)
sixthsense.color3 = Color(255, 255, 255, 255)
concommand.Add('sixthsense', function(ply, cmd, args)
	if not sixthsense.enable or (sixthsense.alphaRate and sixthsense.alphaRate <= 0.2) then
		sixthsense:Start(LocalPlayer(), unpack(args))
		surface.PlaySound('dishonored/darkvision_scan.wav')
	end
end)

function sixthsense:Filter(ent)
	if not IsValid(ent) then
		return false
	end

	if not isfunction(ent.DrawModel) or not ent:GetModel() then
		return false
	end 

	local class = ent:GetClass()
	if ent:IsRagdoll() or ent:GetOwner() == LocalPlayer() or ent:GetParent() == LocalPlayer() or class == 'lg_ragdoll' then
		return false
	end

	if ent:GetMaxHealth() > 2 or ent:IsNPC() or scripted_ents.GetStored(class) or ent:IsVehicle() or ent:IsWeapon() or class == 'prop_dynamic' then
		return true
	end

	return false
end

local function ClampAbs(num, min, max)
	return math.Clamp(math.abs(num), min, max)
end

function sixthsense:Start(ply, targerRange, duration, durationAlpha, limitent, cycle)
	self.curRange = 0
	self.alphaRate = 1

	self.targerRange = ClampAbs(targerRange or 1000, 1, 10000)
	self.limitent = ClampAbs(limitent or 30, 5, 100)
	self.duration = ClampAbs(duration or 1, 0.1, 10)
	self.durationAlpha = ClampAbs(durationAlpha or 2, 0.1, 10)

	self.entqueue = {}

	local pos = ply:GetPos()
	local entities = ents.FindInSphere(
		pos,
		0.25 * (self.targerRange / self.duration) * self.durationAlpha + self.targerRange
	)

	table.sort(entities, function(a, b)
		return (a:GetPos() - pos):LengthSqr() < (b:GetPos() - pos):LengthSqr()
	end)

	for i, ent in ipairs(entities) do
		if #self.entqueue >= self.limitent then
			break
		end

		if ent:GetClass() == 'npc_grenade_frag' then
			local grenade = ClientsideModel(ent:GetModel())
			grenade:SetPos(ent:GetPos())
			grenade:SetAngles(ent:GetAngles())
			grenade:SetParent(ent)
			grenade.remove = true
			table.insert(self.entqueue, grenade)

			ent:CallOnRemove('sixthsense_grenade', function() if IsValid(grenade) then grenade:Remove() end end)
	
			continue
		end

		if not self:Filter(ent) then
			continue
		end

		table.insert(self.entqueue, ent)
	end

	self.cycle = cycle
	self.StartTime = RealTime()
	self.enable = true
end

function sixthsense:Clean()
	self.enable = nil
	self.curRange = nil
	self.alphaRate = nil
	
	self.targerRange = nil
	self.limitent = nil
	self.duration = nil
	self.durationAlpha = nil
	self.entqueue = {}
	
	self.cycle = nil
	self.StartTime = nil
end

function sixthsense:Think()
	if not self.enable then
		return
	end

	local dt = RealTime() - self.StartTime
	local rate = dt / self.duration

	self.curRange = rate * self.targerRange
	if dt >= self.duration then
		self.alphaRate = math.Clamp(1 - (dt - self.duration) / self.durationAlpha, 0, 1)
	end

	if dt >= self.duration + self.durationAlpha then
		if not self.cycle then
			self:Clean()
			return
		end
		self:Start(LocalPlayer(), self.targerRange, self.duration, self.durationAlpha, self.limitent, self.oneshot)
		surface.PlaySound('dishonored/darkvision_scan.wav')
	end
end

hook.Add('Think', 'sixthsense', function() sixthsense:Think() end)

local white = Color(255, 255, 255, 255)
local wireframe_mat = Material('models/wireframe')
local vol_light001_mat = Material('Models/effects/vol_light001')
function sixthsense:Draw()
	if not self.enable then
		return 
	end
	local plypos = LocalPlayer():GetPos()
	local curRangeSqr = self.curRange * self.curRange

	local len = #self.entqueue
	if len > 0 then
		render.PushRenderTarget(sixthsense_rt)
			render.Clear(0, 0, 0, 0, true, true)
			
			render.MaterialOverride(wireframe_mat)
				for _, ent in ipairs(self.entqueue) do
					if not IsValid(ent) then
						continue
					end

					if plypos:DistToSqr(ent:GetPos()) > curRangeSqr + 40000 then
						continue
					end

					ent:DrawModel()
				end
			render.MaterialOverride()

		render.PopRenderTarget()
	end

	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SuppressEngineLighting(true)
		// 全屏
		render.SetStencilWriteMask(1)
		render.SetStencilTestMask(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_INCR)
		render.SetMaterial(vol_light001_mat)
		render.DrawSphere(plypos, self.curRange, 8, 8, white)
	
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		cam.Start2D()
			surface.SetDrawColor(self.color1.r, self.color1.g, self.color1.b, self.color1.a * self.alphaRate)
			surface.DrawRect(0, 0, ScrW(), ScrH())
			if len > 0 then
				surface.SetDrawColor(self.color3.r, self.color3.g, self.color3.b, 255)
				sixthsense_mat:SetFloat('$alpha', self.alphaRate)
				surface.SetMaterial(sixthsense_mat)
				surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
			end
		cam.End2D()

		// 遮罩
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_INCR)
		render.SetMaterial(vol_light001_mat)
		render.DrawSphere(plypos, self.curRange + 20, 8, 8, white)


		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		cam.Start2D()
			surface.SetDrawColor(self.color2.r, self.color2.g, self.color2.b, self.color2.a * self.alphaRate)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		cam.End2D()

	render.SetStencilEnable(false)
	render.SuppressEngineLighting(false)
end

hook.Add('PostDrawOpaqueRenderables', 'sixthsense', function() 
	local succ, err = pcall(sixthsense.Draw, sixthsense)
	if not succ then
		print(err)
		render.SuppressEngineLighting(true)
		render.SetStencilEnable(false)
	end
end)