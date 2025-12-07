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
	['combine_mine'] = 0,
	['grenade_helicopter'] = 0,
	['item_ammo_357'] = 1,
	['item_ammo_357_large'] = 1,
	['item_ammo_ar2'] = 1,
	['item_ammo_ar2_altfire'] = 1,
	['item_ammo_ar2_large'] = 1,
	['item_ammo_crossbow'] = 1,
	['item_ammo_pistol'] = 1,
	['item_ammo_pistol_large'] = 1,
	['item_ammo_smg1'] = 1,
	['item_ammo_smg1_grenade'] = 1,
	['item_ammo_smg1_large'] = 1,
	['item_battery'] = 1,
	['item_box_buckshot'] = 1,
	['item_healthcharger'] = 1,
	['item_healthkit'] = 1,
	['item_healthvial'] = 1,
	['item_rpg_round'] = 1,
	['item_suitcharger'] = 1,
	['combine_mine_resistance'] = 1,
}

sixthsense.BlackList = {
	['mg_viewmodel'] = -1,
	['lg_ragdoll'] = -1,
}


sixthsense.Filter = function(ent)
	if ent:GetOwner() == LocalPlayer() or ent:GetParent() == LocalPlayer() then
		return nil
	end

	local class = ent:GetClass()

	if sixthsense.WhiteList[class] then
		return sixthsense.WhiteList[class]
	end

	if sixthsense.BlackList[class] then
		return nil
	end

	if class == 'npc_grenade_frag' then
		if IsValid(ent.psss_skin) then
			ent.psss_skin:Remove()
		end

		local grenade = ClientsideModel(ent:GetModel())
		grenade:SetPos(ent:GetPos())
		grenade:SetAngles(ent:GetAngles())
		grenade:SetParent(ent)
		grenade:SetNoDraw(true)

		ent.psss_skin = grenade

		ent:CallOnRemove('sixthsense_grenade', function() if IsValid(grenade) then grenade:Remove() end end)

		return 0, grenade
	end

	if ent:IsNPC() then
		return 0
	end

	if ent:GetMaxHealth() > 2 or scripted_ents.GetStored(class) or ent:IsWeapon() or class == 'prop_dynamic' then
		return 1
	end

	if ent:IsVehicle() then
		return 2
	end

	return nil
end

local function ClampAbs(num, min, max)
	return math.Clamp(math.abs(num), min, max)
end

function sixthsense:Start(ply, targetRange, duration, durationAlpha, limitent, cycle, filterOverride)
	self.curRange = 0
	self.alphaRate = 1

	self.targetRange = ClampAbs(targetRange or 1000, 1, 10000)
	self.limitent = ClampAbs(limitent or 30, 5, 100)
	self.duration = ClampAbs(duration or 1, 0.1, 10)
	self.durationAlpha = ClampAbs(durationAlpha or 2, 0.1, 10)

	self.entqueue = {}

	local pos = ply:GetPos()
	local range = math.min(self.targetRange + 0.75 * (self.targetRange / self.duration) * self.durationAlpha, 2 * self.targetRange)
	local entities = ents.FindInSphere(pos, range)
	
	local filter = filterOverride or self.Filter
	local rangeSqr = range * range
	local weightTable = {}
	for i, ent in ipairs(entities) do 
		if not IsValid(ent) then
			continue
		elseif not isfunction(ent.DrawModel) then
			continue
		end

		local priority, entOverride = filter(ent)
		if priority == nil then 
			continue 
		end

		table.insert(
			weightTable, 
			{
				ent = IsValid(entOverride) and entOverride or ent, 
				priority = (ent:GetPos() - pos):LengthSqr() / rangeSqr + priority
			}
		)
	end

	table.sort(weightTable, function(a, b) return a.priority < b.priority end)

	// PrintTable(weightTable)

	for i = 1, math.min(self.limitent, #weightTable) do
		table.insert(self.entqueue, weightTable[i].ent)
	end

	self.cycle = cycle
	self.StartTime = RealTime()
	self.enable = true

	hook.Run('SixthSenseStart')
end

function sixthsense:Clean()
	self.enable = nil
	self.curRange = nil
	self.alphaRate = nil
	
	self.targetRange = nil
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

	self.curRange = rate * self.targetRange
	if dt >= self.duration then
		self.alphaRate = math.Clamp(1 - (dt - self.duration) / self.durationAlpha, 0, 1)
	end

	if dt >= self.duration + self.durationAlpha then
		if not self.cycle then
			self:Clean()
			return
		end
		self:Start(LocalPlayer(), self.targetRange, self.duration, self.durationAlpha, self.limitent, self.cycle)
		surface.PlaySound('dishonored/darkvision_scan.wav')
		hook.Run('SixthSenseEnd')
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
		render.SuppressEngineLighting(false)
		render.SetStencilEnable(false)
		render.MaterialOverride(nil)
	end
end)