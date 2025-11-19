--[[
    作者: 白狼
]]

local cvars = {
    {
        name = 'ps_sixthsense_range',
        default = '1000',
        call = 'GetInt',
        widget = 'NumSlider',
        min = 100,
        max = 2000,
        decimals = 0,
    },

    {
        name = 'ps_sixthsense_cost',
        default = '0.3',
        call = 'GetFloat',
        widget = 'NumSlider',
        min = 0,
        max = 1,
        decimals = 2,
    },

    {
        name = 'ps_sixthsense_ent_limit',
        default = '30',
        call = 'GetFloat',
        widget = 'NumSlider',
        min = 10,
        max = 60,
        decimals = 0,
    },

    {
        name = 'ps_sixthsense_duration',
        default = '1',
        call = 'GetFloat',
        widget = 'NumSlider',
        min = 0,
        max = 5,
        decimals = 1,
    }

}
for _, cvar in ipairs(cvars) do pointshoot:RegisterCVar(cvar) end
if SERVER then 
    cvars = nil 
elseif CLIENT then
    hook.Add('PopulateToolMenu', 'pointshoot.menu.sixthsense', function()
        spawnmenu.AddToolMenuOption('Options', 
            language.GetPhrase('#pointsh.category'), 
            'pointshoot.menu.sixthsense', 
            language.GetPhrase('#pointsh.menu.sixthsense'), '', '', 
            function(panel) pointshoot:CreateCVarsMenu(panel, cvars) end
        )
    end)
end

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
concommand.Add('sixthsense', function(ply)
	local curpower = LocalPlayer():GetNW2Float('psnw_power', 1)
	local powercost = pointshoot.CVarsCache.ps_sixthsense_cost
	if curpower < powercost then 
		return 
	end

	if not sixthsense.enable or (sixthsense.alphaRate and sixthsense.alphaRate <= 0.2) then
		pointshoot:CallDoubleEnd('CTSDecrPower', LocalPlayer(), powercost)
		sixthsense:Start(LocalPlayer(), 
			pointshoot.CVarsCache.ps_sixthsense_range,
			1,
			pointshoot.CVarsCache.ps_sixthsense_duration,
			pointshoot.CVarsCache.ps_sixthsense_ent_limit,
			false
		)
		surface.PlaySound('dishonored/darkvision_scan.wav')
	end
end)

concommand.Add('sixthsense_old', function(ply, cmd, args)
	local curpower = LocalPlayer():GetNW2Float('psnw_power', 1)
	local powercost = pointshoot.CVarsCache.ps_sixthsense_cost
	if curpower <= powercost then 
		return 
	end

	if not sixthsense.enable or (sixthsense.alphaRate and sixthsense.alphaRate <= 0.2) then
		pointshoot:CallDoubleEnd('CTSDecrPower', LocalPlayer(), powercost)
		sixthsense:Start(LocalPlayer(), unpack(args))
		surface.PlaySound('dishonored/darkvision_scan.wav')
	end
end)

sixthsense.WhiteList = {
	['combine_mine'] = true,
	['combine_mine_resistance'] = true,
}

function sixthsense:Filter(ent)
	if not IsValid(ent) then
		return nil
	elseif not isfunction(ent.DrawModel) or not ent:GetModel() then
		return nil
	end

	local class = ent:GetClass()
	if string.StartWith(class, 'mg_') then
		return nil
	elseif class == 'npc_grenade_frag' then
		local grenade = ClientsideModel(ent:GetModel())
		grenade:SetPos(ent:GetPos())
		grenade:SetAngles(ent:GetAngles())
		grenade:SetParent(ent)
		grenade.remove = true
		table.insert(self.entqueue, grenade)

		ent:CallOnRemove('sixthsense_grenade', function() if IsValid(grenade) then grenade:Remove() end end)

		return grenade
	elseif self.WhiteList[class] then
		return ent
	end


	if ent:IsRagdoll() or ent:GetOwner() == LocalPlayer() or ent:GetParent() == LocalPlayer() or class == 'lg_ragdoll' then
		return nil
	end

	if ent:GetMaxHealth() > 2 or ent:IsNPC() or scripted_ents.GetStored(class) or ent:IsVehicle() or ent:IsWeapon() or class == 'prop_dynamic' then
		return ent
	end

	return nil
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
	local speed = self.targerRange / self.duration
	local entities = ents.FindInSphere(
		pos,
		self.targerRange + math.min(
							0.25 * speed * math.max(self.durationAlpha - self.duration, 0), 
							self.targerRange
						)
	)

	table.sort(entities, function(a, b)
		return (a:GetPos() - pos):LengthSqr() < (b:GetPos() - pos):LengthSqr()
	end)

	for i, ent in ipairs(entities) do
		if #self.entqueue >= self.limitent then
			break
		end

		ent = self:Filter(ent)
		if ent then
			table.insert(self.entqueue, ent)
		end
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