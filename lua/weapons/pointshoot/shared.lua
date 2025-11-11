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
AddCSLuaFile('call.lua')
include('call.lua')
LoadLuaFiles('core')



SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = 'Fake Gun'
SWEP.Category = 'Other'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_pistol.mdl'
SWEP.WorldModel = 'models/weapons/v_pistol.mdl'
SWEP.Spawnable = true

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0

SWEP:RegisterServerToClient('STCStart')
SWEP:RegisterClientToServer('CTSFinish')
SWEP:RegisterClientToServer('CTSExecuteRequest')
SWEP:RegisterServerToClient('STCExecute')
SWEP:RegisterClientToServer('CTSBreak')

function SWEP:STCStart()
	self.State = 'START'
	if SERVER then
		self:TimeScaleFadeIn(0, 0.1)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ParticleEffect()
		self:ScreenFlash(150, 0, 0.2)
		self.marks = {}
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
		self.targetCheck = nil
		self:AutoAim()
		surface.PlaySound('hitman/execute.mp3')
	end
end

function SWEP:CTSFinish()
	self.State = 'FINISH'
	if SERVER then
		self:TimeScaleFadeIn(1, 0.1)
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
		if not self.marks or #self.marks < 1 then
			self:CallDoubleEnd('CTSFinish')
			return
		end

		local targetCheck = self:CheckTarget()
		print(targetCheck, self.targetCheck)
		local needShoot = not targetCheck and self.targetCheck
		if needShoot then
			if self:Fire() then
				needShoot = false
				table.remove(self.marks, #self.marks)
			else
				return
			end
		end

		if not targetCheck then
			local mark = self.marks[#self.marks]
			self:AutoAim(mark.pos, mark.ent, 0.1, true)
		end

		self.targetCheck = targetCheck
	end

	
	return true
end

function SWEP:PrimaryAttack()
	if SERVER and self.State ~= 'START' then
		self:CallDoubleEnd('STCStart')
	elseif CLIENT and self.State == 'START' then
		surface.PlaySound('hitman/mark.mp3')
		self:EnableDrawMarks()
		self:AddMark(LocalPlayer():GetEyeTrace())
	end
end

function SWEP:SecondaryAttack()
	if CLIENT and self.State == 'START' and self.State ~= 'EXECUTE_REQUESTING' then
		self:CallDoubleEnd('CTSExecuteRequest')
	end
end

