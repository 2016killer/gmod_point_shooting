pointshoot = pointshoot or {}
// local pointshoot = {}
local pointshoot = pointshoot or {}

pointshoot.SafeCall = function(func, ...)
	if not isfunction(func) then
		print(string.format('[pointshoot]: Error: %s is not a function', tostring(func)))
		return false
	end

	local result = table.Pack(pcall(func, ...))
	if not result[1] then 
		print(string.format('[pointshoot]: Error: %s', result[2]))
		return false
	else 
		return unpack(result, 2)
	end
end

pointshoot.Enabled = nil
pointshoot.Executed = nil
pointshoot.Targets = nil
pointshoot.TargetsHitBoxBone = nil
if CLIENT then
	hook.Add('KeyPress', 'pointshoot.inserttarget', function(ply, key)
		if not pointshoot.Enabled then
			return
		end
		if key == IN_ATTACK then
			pointshoot:Select(LocalPlayer():GetEyeTrace())
		elseif key == IN_ATTACK2 then
			pointshoot:Execute(LocalPlayer():GetEyeTrace())
		end
	end)
elseif SERVER then
	util.AddNetworkString('pointshootStart')
	util.AddNetworkString('pointshootFinish')

	function pointshoot:Check(ply, wpclassList)
		if self.Enabled or not ply:Alive() then 
			return false
		end 

		for i = #wpclassList, 1, -1 do
			local wpclass = wpclassList[i]
			local wp = ply:GetWeapon(wpclass)

			if not IsValid(wp) or wp:Clip1() <= 0 then
				table.remove(wpclassList, i)
			end
		end

		if #wpclassList > 0 then
			return true
		else
			return false
		end
	end

	concommand.Add('pointshooting', function(ply, cmd, args)
		local wpclassList = args
		if #wpclassList < 1 then
			table.insert(wpclassList, ply:GetActiveWeapon():GetClass())
		end

		if pointshoot:Check(ply, wpclassList) then
			pointshoot:Start(ply, wpclassList)
		end
	end)
end

if CLIENT then
	net.Receive('pointshootStart', function()
		local wpclassList = net.ReadTable(true)
		pointshoot:Start(LocalPlayer(), wpclassList)
	end)
elseif SERVER then
	net.Receive('pointshootFinish', function(len, ply)
		local targets = net.ReadTable(true)
		local hitboxbones = net.ReadTable(true)
		pointshoot:Finish(ply, targets, hitboxbones)
	end)
end

function pointshoot:Start(ply, wpclassList)
	self.SafeCall(self.StartEffect, self, ply, wpclassList)
	if CLIENT then
		self.Enabled = true

		self.wpclassList = wpclassList
		self.Targets = {}
		self.TargetsHitBoxBone = {}
		self.Executed = false
	elseif SERVER then
		self.Enabled = ply

		net.Start('pointshootStart')
			net.WriteTable(wpclassList, true)
		net.Send(ply)
	end
end

function pointshoot:Select(tr)
	self.SafeCall(self.SelectEffect, self, tr)
	if CLIENT then
		local target = IsValid(tr.Entity) and tr.Entity or false
		local hitthing = tr.HitBoxBone or tr.HitPos

		self.Targets = self.Targets or {}
		self.TargetsHitBoxBone = self.TargetsHitBoxBone or {}

		table.insert(self.Targets, target)
		table.insert(self.TargetsHitBoxBone, hitthing)
	elseif SERVER then
		return
	end
end

function pointshoot:Execute()
	self.SafeCall(self.StartEffectClear, self)
	self.SafeCall(self.SelectEffectClear, self)
	self.SafeCall(self.ExecuteEffect, self)
	if CLIENT then
		self.Executed = true
	elseif SERVER then
		return
	end
end


function pointshoot:Finish(ply, targets, hitboxbones)
	self.SafeCall(self.ExecuteEffectClear, self)
	self.SafeCall(self.FinishEffect, self, ply, targets, hitboxbones)
	if CLIENT then
		self.Enabled = false
		self.wpclassList = nil
		self.Targets = nil
		self.TargetsHitBoxBone = nil
		self.Executed = false

		net.Start('pointshootFinish')
			net.WriteTable(targets or {}, true)
			net.WriteTable(hitboxbones or {}, true)
		net.SendToServer()
	elseif SERVER then
		self.Enabled = nil
	end
end
