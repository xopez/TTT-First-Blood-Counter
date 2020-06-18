AddCSLuaFile()
if SERVER then
	local firstBlood = {}
	util.AddNetworkString("ChatMessage")
	util.AddNetworkString("ViewFB")
	print( "First Blood Counter loaded!" )
	function sqlMakeFBDatabase()
		if !sql.TableExists( "first_blood" ) then
			local query = "CREATE TABLE first_blood ( SID string, Num int, Deaths int)"
			result = sql.Query( query )
		end
	end
	sqlMakeFBDatabase()
	function sqlInsertFirstBlood( victim , attacker)
		if sql.TableExists( "first_blood" ) then
			if(attacker && attacker.IsValid && attacker:IsValid() && attacker.IsPlayer && attacker:IsPlayer())then	
				local getAttQuery = "SELECT * FROM first_blood WHERE SID = '" .. attacker:SteamID() .. "'"
				getAttResult = sql.Query( getAttQuery )
				if getAttResult == nil then
					local query = "INSERT INTO first_blood ('SID', 'Num', 'Deaths') VALUES ( '" .. attacker:SteamID() .. "', '" .. 1 .. "', '" .. 0 .. "')"
					result = sql.Query( query )	
				else
					local query = "UPDATE first_blood SET Num = '" .. getAttResult[1]["Num"] + 1 .. "' WHERE SID = '" .. attacker:SteamID() .."'"
					result = sql.Query( query )
				end
			end
			if(victim && victim.IsValid && victim:IsValid() && victim.IsPlayer && victim:IsPlayer())then
				local getVicQuery = "SELECT * FROM first_blood WHERE SID = '" .. victim:SteamID() .. "'"
				getVicResult = sql.Query( getVicQuery )
				if getVicResult == nil then
					local query = "INSERT INTO first_blood ('SID', 'Num', 'Deaths') VALUES ( '" .. victim:SteamID() .. "', '" .. 0 .. "', '" .. 1 .. "')"
					result = sql.Query( query )
				else
					local query = "UPDATE first_blood SET Deaths = '" .. getVicResult[1]["Deaths"] + 1 .. "' WHERE SID = '" .. victim:SteamID() .."'"
					result = sql.Query( query )
				end
				local getAllQuery = "SELECT * FROM first_blood"
				getAllResult = sql.Query( getAllQuery )
				if getAllResult == nil then return else PrintTable(getAllResult) end
			end
		end
	end
	function isGroup( ply )
		return true
	end
	function sqlScrubFBDatabase()
		if sql.TableExists( "first_blood" ) then
			local query = "DELETE FROM first_blood"
			local result = sql.Query( query )
			local query = "DELETE FROM first_blood"
			local result = sql.Query( query )
		end
	end
	hook.Add( "PlayerSay", "ScrubFBDatabase", function( ply, text )
	local phrase = string.lower("!scrubFB")
	local split = string.Explode( " ", text )
	local cmd = string.lower(split[ 1 ])
		if cmd == phrase and (ply:IsAdmin() or ply:IsSuperAdmin()) then
			sqlScrubFBDatabase()
			ply:PrintMessage( HUD_PRINTTALK, "FirstBlood: Databases deleted!\n" )
			return
		end
		if cmd == phrase and (not ply:IsAdmin() or not ply:IsSuperAdmin()) then
			ply:PrintMessage( HUD_PRINTTALK, "FirstBlood: You are not allowed to reset the First Blood Counter!\n" )
		end
	end)
	hook.Add( "PlayerSay", "printFB", function( ply, text )
	local phrase = string.lower("!printFB")
	local split = string.Explode( " ", text )
	local cmd = string.lower(split[ 1 ])
		if cmd == phrase and isGroup(ply) then
			local getAllQuery = "SELECT * FROM first_blood"
			getAllResult = sql.Query( getAllQuery )
			if getAllResult == nil then return else PrintTable(getAllResult) end
			return
		end
	end)
	hook.Add( "PlayerSay", "ViewFB", function( ply, text )
	local phrase = string.lower("!FirstBlood")
	local split = string.Explode( " ", text )
	local cmd = string.lower(split[ 1 ])
		if cmd == phrase and isGroup(ply) then
			local getAllQuery = "SELECT * FROM first_blood ORDER BY Deaths DESC"
			getAllResult = sql.Query( getAllQuery )
			if (getAllResult) then			
				net.Start("ViewFB")
				net.WriteTable(getAllResult)
				net.Send(ply)
				return
			else
				Msg( "\nFirstBlood: Table is empty!\n" )
				ply:PrintMessage( HUD_PRINTTALK, "FirstBlood: No first blood's fallen!\n" )
			end
		end
	end)
	hook.Add( "TTTBeginRound", "firstBlood", function(ply) 
		firstBlood = { ["Victim"] = "", ["Attacker"] = "" }
	end)
	hook.Add( "PlayerDeath", "firstBloodDeath", function( victim, inflictor, attacker) 	
		if attacker == victim then return end
		if firstBlood["Victim"] == ""  then 
			firstBlood = { ["Victim"] = victim, ["Attacker"] = attacker}	
			sqlInsertFirstBlood( victim, attacker)
		end
	end)
end
