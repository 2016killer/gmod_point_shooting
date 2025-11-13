sixthsense = sixthsense or {}
local sixthsense = sixthsense
concommand.Add('sixthsense_debug', function()
	PrintTable(sixthsense)
end)
local sixs_start_sound = CreateClientConVar('sixs_start_sound', 'darkvision_start.wav', true, false, '')
local sixs_scan_sound = CreateClientConVar('sixs_scan_sound', 'darkvision_scan.wav', true, false, '')
local sixs_stop_sound = CreateClientConVar('sixs_stop_sound', 'darkvision_end.wav', true, false, '')
local sixs_color1 = CreateClientConVar('sixs_color1', '0 0 0 170', true, false, '')
local sixs_color2 = CreateClientConVar('sixs_color2', '255 255 255 255', true, false, '')
local sixs_color3 = CreateClientConVar('sixs_color3', '255 255 255 255', true, false, '')


sixthsense.GetColorFromCVar = function(cvar)
	local colorStr = string.Split(cvar:GetString(), ' ')
	for i = #colorStr, 1, -1 do
		if string.Trim(colorStr[i]) == '' then
			table.remove(colorStr, i)
			continue
		end
	end
	local color = Color(
		tonumber(colorStr[1]) or 0,
		tonumber(colorStr[2]) or 0,
		tonumber(colorStr[3]) or 0,
		tonumber(colorStr[4]) or 0
	)
	return color
end

local sixthsense_rt = GetRenderTarget('sixthsense_rt',  ScrW(), ScrH())
local sixthsense_mat = CreateMaterial('sixthsense_mat', 'UnLitGeneric', {
	['$basetexture'] = sixthsense_rt:GetName(),
	['$translucent'] = 1,
	['$vertexcolor'] = 1,
	['$alpha'] = 1
})

sixthsense.currentRadius = 0
sixthsense.targetRadius = 0
sixthsense.speed = 0
sixthsense.speedFadeOut = 0
sixthsense.limitent = 30
sixthsense.scan_sound = ''
sixthsense.colors = {}
sixthsense.startcolors = {}

sixthsense.duration = 0
sixthsense.enable = false
sixthsense.flag1 = nil
sixthsense.flag2 = nil
sixthsense.timer = nil
sixthsense.period = 0
sixthsense.speedFadeOut2 = 0
sixthsense.oneshot = false

sixthsense.friendqueue = {}
sixthsense.enemyqueue = {}
sixthsense.vehiclequeue = {}
sixthsense.entqueue = {}

concommand.Add('sixthsense_new', function(ply, cmd, args)
	if sixthsense:Trigger(ply, args[1], args[2], args[3], {
		getcolor(sixs_color1:GetString()),
		getcolor(sixs_color2:GetString()),
		getcolor(sixs_color3:GetString()),
	}, sixs_scan_sound:GetString(), args[4]) then
		surface.PlaySound(sixs_start_sound:GetString())
	else
		surface.PlaySound(sixs_stop_sound:GetString())
	end
end)

concommand.Add('sixthsense_oneshot', function(ply, cmd, args)
	sixthsense:Start(ply, args[1], args[2], args[3], {
		getcolor(sixs_color1:GetString()),
		getcolor(sixs_color2:GetString()),
		getcolor(sixs_color3:GetString()),
	}, sixs_scan_sound:GetString(), args[4], true) 
	
	surface.PlaySound(sixs_start_sound:GetString())
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

	if ent:IsNPC() or scripted_ents.GetStored(class) or ent:IsVehicle() or ent:IsWeapon() or class == 'prop_dynamic' then
		return true
	end

	return false
end

function sixthsense:Start(ply, targetRadius, speed, limitent, startcolors, scan_sound, period, oneshot)
	self.flag1 = nil
	self.flag2 = nil
	self.timer = nil
	self.oneshot = oneshot or false
	self.currentRadius = 0
	
	self.targetRadius = math.max(1, math.abs(targetRadius or 1000))
	self.speed = math.max(1, math.abs(speed or 1000))
	self.speedFadeOut = 255 / self.targetRadius * self.speed
	self.limitent = math.max(5, math.abs(limitent or 30))
	self.period = math.max(0.5, math.abs(period or 5))
	self.speedFadeOut2 = 255 / self.period
	self.startcolors = startcolors or {
		Color(0, 0, 0, 255),
		Color(255, 255, 255, 255),
		Color(255, 255, 255, 255)
	}
	self.colors = table.Copy(self.startcolors)
	self.duration = self.targetRadius / self.speed
	self.scan_sound = scan_sound or sixs_scan_sound:GetString()

	self.entqueue = {}
	local entities = ents.FindInSphere(ply:GetPos(), self.targetRadius)
	for i, ent in ipairs(entities) do
		local len = #self.entqueue

		if len >= self.limitent then
			break
		end

		if not self:Filter(ent) then
			continue
		end

		table.insert(self.entqueue, ent)
	end

	self.enable = true
end

function sixthsense:Clear()
	self.enable = false

	self.currentRadius = 0
	self.targetRadius = 0
	self.speed = 0
	self.speedFadeOut = 0
	self.limitent = 0
	self.scan_sound = ''
	self.colors = {}
	self.startcolors = {}
	self.duration = 0
	self.entqueue = {}
	self.flag1 = nil
	self.flag2 = nil
	self.timer = nil
	self.period = 0
	self.speedFadeOut2 = 0
	self.oneshot = false
end

function sixthsense:Trigger(...)
	if not self.enable then
		self:Start(...)
		return true
	else
		self:Clear()
		return false
	end
end


function sixthsense:Think()
	if not self.enable then
		return
	end
	local dt = RealFrameTime()
	local speedFadeOut = self.speedFadeOut

	self.colors[1].a = math.Clamp(self.colors[1].a - dt * speedFadeOut, 0, 255)
	self.colors[2].a = math.Clamp(self.colors[2].a - dt * speedFadeOut, 0, 255)
	

	self.currentRadius = self.currentRadius + dt * self.speed
	self.timer = (self.timer or 0) + dt

	local flag1 = self.timer >= self.duration
	local flag2 = self.timer >= self.duration + self.period

	if flag1 then
		self.colors[3].a = math.Clamp(self.colors[3].a - dt * self.speedFadeOut2, 0, 255)
	end

	if not self.flag2 and flag2 then
		if self.oneshot then
			self:Clear()
			return
		else
			self:Start(LocalPlayer(), self.targetRadius, self.speed, self.limitent, self.startcolors)
			surface.PlaySound(self.scan_sound or sixs_scan_sound:GetString())
		end
	end

	self.flag1 = flag1
	self.flag2 = flag2
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
	local currentRadiusSqr = self.currentRadius * self.currentRadius
	local color1, color2, color3 = unpack(self.colors)
	
	local len = #self.entqueue

	if len > 0 then
		render.PushRenderTarget(sixthsense_rt)
			render.Clear(0, 0, 0, 0, true, true)
			
			render.MaterialOverride(wireframe_mat)
				for _, ent in ipairs(self.entqueue) do
					if not IsValid(ent) then
						continue
					end

					if plypos:DistToSqr(ent:GetPos()) > currentRadiusSqr + 40000 then
						continue
					end

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
		render.DrawSphere(plypos, self.currentRadius, 8, 8, white)
	
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		cam.Start2D()
			surface.SetDrawColor(color1.r, color1.g, color1.b, color1.a)
			surface.DrawRect(0, 0, ScrW(), ScrH())
			if len > 0 then
				surface.SetDrawColor(color3.r, color3.g, color3.b, 255)
				sixthsense_mat:SetFloat('$alpha', color3.a / 255)
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
		render.DrawSphere(plypos, self.currentRadius + 20, 8, 8, white)


		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		cam.Start2D()
			surface.SetDrawColor(color2.r, color2.g, color2.b, color2.a)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		cam.End2D()

	render.SetStencilEnable(false)
	render.SuppressEngineLighting(false)
end

local function DrawSafe()
	local succ, err = pcall(sixthsense.Draw, sixthsense)
	if not succ then
		print(err)
		render.SuppressEngineLighting(true)
		render.SetStencilEnable(false)
	end
end

hook.Add('PostDrawOpaqueRenderables', 'sixthsense', DrawSafe)
---------------------------------------------------
local function CreateColorEditor(cvar)
	local BGPanel = vgui.Create('DPanel')
	BGPanel:SetSize(200, 200)
	BGPanel.Color = getcolor(cvar:GetString())

	local color_label = Label(
		string.format('Color(%s, %s, %s, %s)', BGPanel.Color.r, BGPanel.Color.g, BGPanel.Color.b, BGPanel.Color.a)
		, BGPanel)
	color_label:SetPos(70, 180)
	color_label:SetSize(150, 20)
	color_label:SetHighlight(true)

	local function UpdateColors(r, g, b, a, noUpdateCvar)
		r = r or BGPanel.Color.r
		g = g or BGPanel.Color.g
		b = b or BGPanel.Color.b
		a = a or BGPanel.Color.a

		color_label:SetText('Color( '..r..', '..g..', '..b..', '..a..' )')

		BGPanel.Color.r = r
		BGPanel.Color.g = g
		BGPanel.Color.b = b
		BGPanel.Color.a = a

		if noUpdateCvar then
			return
		end

		cvar:SetString(
			string.format('%s %s %s %s', r, g, b, a)
		)
	end

	local DAlphaBar = vgui.Create('DAlphaBar', BGPanel)
	DAlphaBar:SetPos(25, 5)
	DAlphaBar:SetSize(15, 190)
	DAlphaBar:SetValue(BGPanel.Color.a)
	DAlphaBar.OnChange = function(self, newvalue)
		UpdateColors(nil, nil, nil, newvalue * 255)
	end

	local color_picker = vgui.Create('DRGBPicker', BGPanel)
	color_picker:SetPos(5, 5)
	color_picker:SetSize(15, 190)

	local color_cube = vgui.Create('DColorCube', BGPanel)
	color_cube:SetPos(50, 20)
	color_cube:SetSize(155, 155)


	function color_picker:OnChange(col)
		local h = ColorToHSV(col)
		local _, s, v = ColorToHSV(color_cube:GetRGB())
		
		col = HSVToColor(h, s, v)
		color_cube:SetColor(col)
		
		UpdateColors(col.r, col.g, col.b, nil)
	end

	function color_cube:OnUserChanged(col)
		UpdateColors(col.r, col.g, col.b, nil)
	end

	cvars.AddChangeCallback(cvar:GetName(), function(cvar, old, new) 
		if IsValid(BGPanel) then
			BGPanel.Color = getcolor(new) 
			UpdateColors(nil, nil, nil, nil, true)
		end
	end)

	return BGPanel
end

local function menu(panel)
	panel:Clear()

	local button = panel:Button('#default', '')
	button.DoClick = function()
		RunConsoleCommand('sixs_start_sound', 'darkvision_start.wav')
		RunConsoleCommand('sixs_scan_sound', 'darkvision_scan.wav')
		RunConsoleCommand('sixs_stop_sound', 'darkvision_end.wav')

		RunConsoleCommand(sixs_color1:GetName(), '0 0 0 170')
		RunConsoleCommand(sixs_color2:GetName(), '255 255 255 255')
		RunConsoleCommand(sixs_color3:GetName(), '255 255 255 255')
	end

	panel:TextEntry('#sixs.start_sound', 'sixs_start_sound')
	panel:TextEntry('#sixs.scan_sound', 'sixs_scan_sound')
	panel:TextEntry('#sixs.stop_sound', 'sixs_stop_sound')
	
	panel:AddItem(CreateColorEditor(sixs_color1))
	panel:AddItem(CreateColorEditor(sixs_color2))
	panel:AddItem(CreateColorEditor(sixs_color3))
end

-------------------------菜单
hook.Add('PopulateToolMenu', 'sixs.menu', function()
	spawnmenu.AddToolMenuOption(
		'Options', 
		language.GetPhrase('#sixs.menu.category'), 
		'sixs.menu',
		language.GetPhrase('#sixs.menu.name'), '', '', 
		menu
	)
end)

