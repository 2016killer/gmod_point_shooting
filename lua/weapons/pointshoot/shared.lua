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
SWEP.Category = 'Legend'
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
	Damage = 10000,
	Num = 1,
	Tracer = 1,
}

SWEP.MarksBatchSize = 5

SWEP:RegisterServerToClient('STCStart')
SWEP:RegisterClientToServer('CTSFinish')
SWEP:RegisterClientToServer('CTSExecuteRequest')
SWEP:RegisterServerToClient('STCExecute')
SWEP:RegisterClientToServer('CTSBreak')
SWEP:RegisterClientToServer('CTSShoot')
SWEP:RegisterClientToServer('CTSAddMarks')

function SWEP:CTSAddMarks(...)
	if SERVER then
		self.Marks = self.Marks or {}
		table.Add(self.Marks, {...})
	end
end

function SWEP:ClientAddMark(tr)
    if SERVER then return end
    table.insert(self.Marks, self:PackMark(tr))
    self.markCount = self.markCount + 1
    
    if self.markCount >= self.MarksBatchSize then
        self:CallDoubleEnd('CTSAddMarks', unpack(
            self.Marks, 
            #self.Marks - self.markCount + 1, 
            #self.Marks
        ))
        self.markCount = 0
    end
end

function SWEP:STCStart()
	self.State = 'START'
	self.Marks = {}
	self.markCount = 0
	self.shootCount = 0
	self.fireTime = 0
	if SERVER then
		self:TimeScaleFadeIn(0, 0.1)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ParticleEffect()
		self:ScreenFlash(150, 0, 0.2)
	end
end

function SWEP:CTSExecuteRequest(...)
	self.State = 'EXECUTE_REQUESTING'
	if SERVER then
		self:TimeScaleFadeIn(0.3, 0)
		self:CallDoubleEnd('STCExecute')
	end
end

function SWEP:STCExecute()
	self.State = 'EXECUTE'
	if CLIENT then
		surface.PlaySound('hitman/execute.mp3')
	end
end

function SWEP:CTSFinish()
	self.State = 'FINISH'
	if SERVER then
		self:TimeScaleFadeIn(1, 0.1)
	elseif CLIENT then
		self:ClearParticle()
	end
end

function SWEP:CTSShoot(count)
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

function SWEP:CheckFireAble()
	return true
end


-- ================
-- 触发标记模式 或 不做任何事
-- ================
function SWEP:Deploy()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		self:Remove()
		return 
	end

	if SERVER and self.StartAtOnce then
		self:CallDoubleEnd('STCStart')
	end
	return true
end

-- ================
-- 执行点射
-- ================
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

	-- 瞄准、射击
	if self.State == 'EXECUTE' then
		if not self.Marks or #self.Marks < 1 then
			self:CallDoubleEnd('CTSFinish')
			return
		end

		if self.aiming or not self:CheckFireAble() then
			return
		end

		self:AutoAim(self.Marks[#self.Marks], 0.1, true)
		self.aiming = true
	end

	return true
end

hook.Add('PointShootAutoAimFinish', 'pointshoot.fire', function(wp, targetDir)
	if not IsValid(wp) then
		return
	end
	wp.aiming = false

	wp:ClientFire(targetDir)
	table.remove(wp.Marks, #wp.Marks)
	wp.shootCount = wp.shootCount + 1
	
	if wp.drawtime - wp.fireTime >= 0.1 and wp.shootCount > 0 then
		wp.fireTime = wp.drawtime
		wp:CallDoubleEnd('CTSShoot', wp.shootCount)
		wp.shootCount = 0
	end
end)

-- ================
-- 触发标记模式 或 标记
-- ================
function SWEP:PrimaryAttack()
	if SERVER and self.State ~= 'START' then
		self:CallDoubleEnd('STCStart')
	elseif CLIENT and self.State == 'START' then
		surface.PlaySound('hitman/mark.mp3')
		self:ClientAddMark(LocalPlayer():GetEyeTrace())
	end
end

-- ================
-- 执行点射
-- ================
function SWEP:SecondaryAttack()
	if CLIENT and self.State == 'START' and self.State ~= 'EXECUTE_REQUESTING' then
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
end

