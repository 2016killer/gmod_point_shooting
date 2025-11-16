--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
local pointshoot = pointshoot
pointshoot.Marks = {}

if SERVER then
    concommand.Add('pointshoot_debug_wpdata_sv', function(ply)
        local wp = ply:GetActiveWeapon()
        print(wp:GetClass())
        if not istable(wp.Primary) then return end
        print('------Primary------')
        PrintTable(wp.Primary)
        if not istable(wp.Bullet) then return end
        print('------Bullet------')
        PrintTable(wp.Bullet)
    end)
elseif CLIENT then
    concommand.Add('pointshoot_debug_wpdata_cl', function(ply)
        local wp = ply:GetActiveWeapon()
        print(wp:GetClass())
        if not istable(wp.Primary) then return end
        print('------Primary------')
        PrintTable(wp.Primary)
        if not istable(wp.Bullet) then return end
        print('------Bullet------')
        PrintTable(wp.Bullet)
    end)

    concommand.Add('pointshoot_debug_seq_cl', function(ply)
        local wp = ply:GetActiveWeapon()
        print(wp:GetClass(), wp:GetSequence(), ply:GetViewModel():GetSequence())
    end)

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
LoadLuaFiles('effects')