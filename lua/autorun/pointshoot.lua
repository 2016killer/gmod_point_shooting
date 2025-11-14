pointshoot = pointshoot or {}
if SERVER then
	concommand.Add('pointshoot_print_sv', function()
		PrintTable(self.Marks)
	end)
elseif CLIENT then
	concommand.Add('pointshoot_print_cl', function()
		PrintTable(self.Marks)
	end)
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
pointshoot.STATE_FINISH = 3
-- ================
-- 客户端添加标记, 每添加 MarksBatchSize 个后向服务器端同步
-- ================
pointshoot.Marks = {}
pointshoot.State = SERVER and {} or nil
function pointshoot:CTSAddMarks(ply, ...)
	if CLIENT then return end
	local idx = ply:EntIndex()
	self.Marks[idx] = self.Marks[idx] or {}
	table.Add(self.Marks[idx], {...})
end

function pointshoot:ClientAddMark(tr)
    if SERVER then return end
    table.insert(self.Marks, self:PackMark(tr))
    self.markCount = self.markCount + 1
    
    if self.markCount >= self.MarksBatchSize then
        self:CallDoubleEnd(
			'CTSAddMarks', 
			LocalPlayer(), 
			unpack(
				self.Marks, 
				#self.Marks - self.markCount + 1, 
				#self.Marks
			)
		)
        self.markCount = 0
    end
end

function pointshoot:CleanMark(ply)
    if SERVER then 
		local idx = ply:EntIndex()
		self.Marks[idx] = {}
	elseif CLIENT then
		self.Marks = {}
		self.markCount = 0
	end
end

function pointshoot:CleanClientAim()
    if SERVER then return end
	self.shootCount = 0
	self.fireTime = 0
	self.aiming = false
end

function pointshoot:STCStart(ply)
	self:CleanMark(ply)
	self:StartEffect()
	if SERVER then
		local idx = ply:EntIndex()
		self.State[idx] = self.STATE_START
	elseif CLIENT then
		self.State = self.STATE_START
		self:CleanClientAim()
	end
end

function pointshoot:CTSExecuteRequest(ply, ...)
	self.State = 'EXECUTE_REQUESTING'
	if SERVER then
		self:TimeScaleFadeIn(0.3, 0)
		self:CallDoubleEnd('STCExecute')
	elseif CLIENT then
		self:SetRightWeapon(self.parseList[1])
		self:SetLeftWeapon(self.parseList[2])
	end
end

function pointshoot:STCExecute()
	self.State = 'EXECUTE'
	if CLIENT then
		surface.PlaySound('hitman/execute.mp3')
	end
end

function pointshoot:CTSFinish()
	self.State = nil
	if SERVER then
		self:TimeScaleFadeIn(1, 0.1)
	elseif CLIENT then
		self:ClearParticle()
		self:CleanFakeHand()
		self:CleanViewModel()
	end
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


-- ================
-- 触发标记模式 或 不做任何事
-- ================
function pointshoot:Deploy()
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
function pointshoot:Think()
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
	
	if #wp.Marks < 1 or (wp.drawtime - wp.fireTime >= 0.25 and wp.shootCount > 0) then
		wp.fireTime = wp.drawtime
		wp:CallDoubleEnd('CTSShoot', wp.shootCount)
		wp.shootCount = 0
	end

	wp:SetNextPrimaryFire(RealTime() + 0.05)
end)

-- ================
-- 触发标记模式 或 标记
-- ================
function pointshoot:PrimaryAttack()
	if SERVER and self.State ~= 'START' and self.State ~= 'EXECUTE_REQUESTING' and self.State ~= 'EXECUTE' then
		self:CallDoubleEnd('STCStart')
	elseif CLIENT and self.State == 'START' then
		surface.PlaySound('hitman/mark.mp3')
		self:ClientAddMark(LocalPlayer():GetEyeTrace())
		self:SetClip1(self:Clip1() - 1)
		if self:Clip1() <= 0 then
			self:CallDoubleEnd('CTSExecuteRequest')
		end
	end
end

-- ================
-- 执行点射
-- ================
function pointshoot:SecondaryAttack()
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
AddCSLuaFile()
AddCSLuaFile('pointshoot/common.lua')
include('pointshoot/common.lua')
LoadLuaFiles('core')