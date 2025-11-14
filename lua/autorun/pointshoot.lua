pointshoot = pointshoot or {}

AddCSLuaFile()
AddCSLuaFile('pointshoot/common.lua')
include('pointshoot/common.lua')

if SERVER then
	concommand.Add('pointshoot_print_sv', function()
		PrintTable(self.Marks)
	end)

	concommand.Add('pointshoot', function(ply)
		pointshoot:Run(ply)
	end)

elseif CLIENT then
	concommand.Add('pointshoot_print_cl', function()
		PrintTable(self.Marks)
	end)

	hook.Add('InputMouseApply', 'FreezeTurning', function(cmd)
		// cmd:RemoveKey(IN_ATTACK)
		// return true
	end)
end


function pointshoot:Run(ply)
	if self.State ~= self.STATE_FINISH then return end
	local wp = ply:GetActiveWeapon()
	local wpinfo = self:WeaponParse(wp)
	if not wpinfo then return end
	self.wpinfo = wpinfo
	self:CallDoubleEnd('STCStart', ply)
end


pointshoot:RegisterServerToClient('STCStart')
pointshoot:RegisterClientToServer('CTSFinish')
pointshoot:RegisterClientToServer('CTSExecuteRequest')
pointshoot:RegisterServerToClient('STCExecute')
pointshoot:RegisterClientToServer('CTSBreak')
pointshoot:RegisterClientToServer('CTSShoot')
pointshoot:RegisterClientToServer('CTSAddMarks')

pointshoot.STATE_START = 0
pointshoot.STATE_EXECUTE_REQUESTING = 1
pointshoot.STATE_EXECUTE = 2
pointshoot.STATE_FINISH = nil
-- ================
-- 客户端添加标记, 每添加 MarksBatchSize 个后向服务器端同步
-- ================
pointshoot.Marks = {}
pointshoot.State = nil
pointshoot.MarksBatchSize = 5

function pointshoot:CTSAddMarks(...)
	if CLIENT then return end
	self.Marks = {}
	table.Add(self.Marks, {...})
end

function pointshoot:ClientAddMark(tr)
    if SERVER then return end
    table.insert(self.Marks, self:PackMark(tr))
    self.markCount = self.markCount + 1
    
    if self.markCount >= self.MarksBatchSize then
        self:CallDoubleEnd(
			'CTSAddMarks',
			nil,
			unpack(
				self.Marks, 
				#self.Marks - self.markCount + 1, 
				#self.Marks
			)
		)
        self.markCount = 0
    end
end

function pointshoot:CleanMark()
	self.Marks = {}
	self.markCount = 0
end

function pointshoot:CleanAim()
	self.shootCount = 0
	self.fireTime = 0
	self.aiming = false
end

function pointshoot:STCStart(ply)
	self:CleanAim()
	self:CleanMark()
	self.State = self.STATE_START
	self:StartEffect(ply)
end

function pointshoot:CTSExecuteRequest(ply)
	self.State = self.STATE_EXECUTE_REQUESTING
	if SERVER then
		self:CallDoubleEnd('STCExecute', ply)
	end
end

function pointshoot:STCExecute(ply)
	self.State = self.STATE_EXECUTE
	self:ExecuteEffect(ply)
end

function pointshoot:CTSFinish(ply)
	self.State = nil
	self:FinishEffect(ply)
end

function pointshoot:CTSShoot(count)
	if SERVER then
		if not istable(self.Marks) or #self.Marks < 1 then
			return
		end
		local len = #self.Marks
		for i = len, math.max(len - count + 1, 1), -1 do
			self:ServerFire(self.Marks[i])
			table.remove(self.Marks, i)
		end
	end
end

function pointshoot:CheckFireAble()
	return RealTime() > self:GetNextPrimaryFire()
end

function pointshoot:AutoAim(wp)
	if SERVER then return end

	-- 瞄准、射击
    if not self.Marks or #self.Marks < 1 then
        self:CallDoubleEnd('CTSFinish')
        return
    end

    if self.aiming or not self:CheckFireAble() then
        return
    end

    self:Aim(self.Marks[#self.Marks], 0.1, true)
    self.aiming = true

	return true
end


hook.Add('PointShootAimFinish', 'pointshoot.fire', function(wp, targetDir)
	if not IsValid(wp) then
		return
	end
	wp.aiming = false

	wp:ClientFire(targetDir)
	table.remove(wp.Marks, #wp.Marks)
	wp.shootCount = wp.shootCount + 1
	
	if #wp.Marks < 1 or (wp.drawtime - wp.fireTime >= 0.25 and wp.shootCount > 0) then
		wp.fireTime = wp.drawtime
		wp:CallDoubleEnd('CTSShoot', wp.shootCount)
		wp.shootCount = 0
	end

	wp:SetNextPrimaryFire(RealTime() + 0.05)
end)


function pointshoot:MouseLeftPress()
	if SERVER then return end
	if self.State ~= self.STATE_START then return end
	surface.PlaySound('hitman/mark.mp3')
	self:ClientAddMark(LocalPlayer():GetEyeTrace())
end

function pointshoot:SecondaryAttack()
	if SERVER then return end
	if self.State ~= self.STATE_START then return end
	self:CallDoubleEnd('CTSExecuteRequest')

	-- 发送剩余的标记
	local len = #self.Marks
	local left = len % self.MarksBatchSize
	if left > 0 then
		self:CallDoubleEnd('CTSAddMarks', unpack(
			self.Marks, 
			len - left + 1, 
			len
		))
	end
end



local function LoadLuaFiles(dirname)
	local path = 'pointshoot/' .. dirname .. '/'
	local filelist = file.Find(path .. '*.lua', 'LUA')

	for _, filename in pairs(filelist) do
		client = string.StartWith(filename, 'cl_')
		server = string.StartWith(filename, 'sv_')

		if SERVER then
			if not client then
				include(path .. filename)
				print('[PointShoot]: AddFile:' .. filename)
			end

			if not server then
				AddCSLuaFile(path .. filename)
			end
		else
			if client or not server then
				include(path .. filename)
				print('[PointShoot]: AddFile:' .. filename)
			end
		end
	end
end

LoadLuaFiles('core')
LoadLuaFiles('effect')