local function LoadLuaFiles(dirname)
	local path = 'weapons/pointshoot/' .. dirname .. '/'
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
AddCSLuaFile()
AddCSLuaFile('common.lua')
include('common.lua')
LoadLuaFiles('core')



SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = 'PointShoot'
SWEP.Category = 'Other'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_pistol.mdl'
SWEP.WorldModel = 'models/weapons/w_pistol.mdl'
SWEP.Spawnable = true

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0

SWEP.BulletInfo = {
	Spread = Vector(0, 0, 0),
	Force = 1000,
	Damage = 10000
}


SWEP:RegisterServerToClient('STCStart')
SWEP:RegisterClientToServer('CTSFinish')
SWEP:RegisterClientToServer('CTSExecuteRequest')
SWEP:RegisterServerToClient('STCExecute')
SWEP:RegisterClientToServer('CTSBreak')
SWEP:RegisterClientToServer('CTSAddMarks')

function SWEP:CTSAddMarks(...)
	if SERVER then
		self.Marks = self.Marks or {}
		table.Add(self.Marks, {...})
	end
end

function SWEP:STCStart()
	self.State = 'START'
	if SERVER then
		self.Marks = {}
		self:TimeScaleFadeIn(0, 0.1)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ParticleEffect()
		self:ScreenFlash(150, 0, 0.2)
		self.Marks = {}
	end
end

function SWEP:CTSExecuteRequest()
	self.State = 'EXECUTE_REQUESTING'
	if SERVER then
		self:TimeScaleFadeIn(0.3, 0)
		self:CallDoubleEnd('STCExecute')
	end
end

function SWEP:STCExecute()
	self.State = 'EXECUTE'
	if CLIENT then
		self.aimIdleLast = nil
		self:AimClear()
		surface.PlaySound('hitman/execute.mp3')
	end
end

function SWEP:CTSFinish()
	self.State = 'FINISH'
	if SERVER then
		self:TimeScaleFadeIn(1, 0.1)
		if not istable(self.Marks) or #self.Marks < 1 then
			return
		end
		PrintTable(self.Marks)
		for _, mark in pairs(self.Marks) do
			// local bulletInfo = {
			// 	Num = 1,
			// 	Src = mark.pos,
			// 	Dir = (mark.pos - mark.ent:GetPos()):GetNormal(),
			// 	Spread = Vector(0, 0, 0),
			// 	Force = 1000,
			// 	Damage = 1000,
			// 	AmmoType = 'self.Primary.Ammo',
			// }
			// self:FireBullets(bulletInfo, suppressHostEvents=false)
		end
	elseif CLIENT then
		self:DisableDrawMarks()
	end
end


function SWEP:Deploy()
	if SERVER and self.StartAtOnce then
		self:CallDoubleEnd('STCStart')
	end
	return true
end

function SWEP:Think()
	if SERVER then
		return
	end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

	-- 单人模式客户端需要自行捕获攻击键
	if game.SinglePlayer() then
		local attackKeyDown = owner:KeyDown(IN_ATTACK)
		
		if not self.attackKey and attackKeyDown then
			self:PrimaryAttack()
		end
		self.attackKey = owner:KeyDown(IN_ATTACK)

		local attack2KeyDown = owner:KeyDown(IN_ATTACK2)
		if not self.attack2Key and attack2KeyDown then
			self:SecondaryAttack()
		end
		self.attack2Key = owner:KeyDown(IN_ATTACK2)
	end

	if self.State == 'EXECUTE' then
		local aimIdle = self:AimIdle()
		local needShoot = not aimIdle and self.aimIdleLast
		if needShoot then
			local pos = istable(aimIdle) and aimIdle[1] or aimIdle

			if not self:Fire(pos) then
				return
			end

			needShoot = false
			table.remove(self.Marks, #self.Marks)
		end

		if not self.Marks or #self.Marks < 1 then
			self:CallDoubleEnd('CTSFinish')
			return
		end

		if not aimIdle then
			self:AutoAim(self.Marks[#self.Marks], 0, true)
		end

		self.aimIdleLast = aimIdle
	end


	
	return true
end

function SWEP:PrimaryAttack()
	if SERVER and self.State ~= 'START' then
		self:CallDoubleEnd('STCStart')
	elseif CLIENT and self.State == 'START' then
		surface.PlaySound('hitman/mark.mp3')
		table.insert(self.Marks, self:PackMark(LocalPlayer():GetEyeTrace()))
		if #self.Marks >= 5 then
			self:CallDoubleEnd('CTSAddMarks', unpack(self.Marks, #self.Marks - 4, #self.Marks))
		end
	end
end

function SWEP:SecondaryAttack()
	if CLIENT and self.State == 'START' and self.State ~= 'EXECUTE_REQUESTING' then
		self:CallDoubleEnd('CTSExecuteRequest')
	end
end

