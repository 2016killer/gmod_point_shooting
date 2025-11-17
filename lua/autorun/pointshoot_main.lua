--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
pointshoot.emptyfunc = function() end
pointshoot.WhiteList = pointshoot.WhiteList or {}
pointshoot.WhiteListBase = pointshoot.WhiteListBase or {}
pointshoot.Marks = {}



if SERVER then
    concommand.Add('pointshoot_debug_sv', function(ply)
        PrintTable(pointshoot)
    end)
elseif CLIENT then
    concommand.Add('pointshoot_debug_cl', function(ply)
        PrintTable(pointshoot)
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
LoadLuaFiles('weapon_support')