-- lua/autorun/server/firstblood.lua
AddCSLuaFile()

local firstBlood = {}
util.AddNetworkString("ViewFB")
print("[First Blood] Counter loaded!")

local function sqlMakeFBDatabase()
    if not sql.TableExists("first_blood") then
        sql.Query("CREATE TABLE first_blood ( SID TEXT, Num INTEGER, Deaths INTEGER )")
    end
end
sqlMakeFBDatabase()

local function updateFirstBloodStat(steamid, stat, increment)
    if not steamid then return end
    local current = tonumber(sql.QueryValue("SELECT " .. stat .. " FROM first_blood WHERE SID = '" .. steamid .. "'")) or 0
    if current == 0 and not sql.QueryValue("SELECT SID FROM first_blood WHERE SID = '" .. steamid .. "'") then
        local num, deaths = (stat == "Num" and increment or 0), (stat == "Deaths" and increment or 0)
        sql.Query(string.format("INSERT INTO first_blood (SID, Num, Deaths) VALUES ('%s', %d, %d)", steamid, num, deaths))
    else
        sql.Query(string.format("UPDATE first_blood SET %s = %d WHERE SID = '%s'", stat, current + increment, steamid))
    end
end

local function sqlInsertFirstBlood(victim, attacker)
    if IsValid(attacker) and attacker:IsPlayer() then
        updateFirstBloodStat(attacker:SteamID(), "Num", 1)
    end
    if IsValid(victim) and victim:IsPlayer() then
        updateFirstBloodStat(victim:SteamID(), "Deaths", 1)
    end
end

local function isGroup(ply)
    return ply:IsAdmin() or ply:IsSuperAdmin()
end

local function sqlScrubFBDatabase()
    if sql.TableExists("first_blood") then
        sql.Query("DELETE FROM first_blood")
    end
end

hook.Add("PlayerSay", "FirstBloodCommands", function(ply, text)
    local cmd = string.lower(text:Trim())
    if cmd == "!scrubfb" then
        if isGroup(ply) then
            sqlScrubFBDatabase()
            ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: Database cleared!")
        else
            ply:PrintMessage(HUD_PRINTTALK, "You are not allowed to reset the database!")
        end
        return ""
    elseif cmd == "!printfb" then
        if isGroup(ply) then
            PrintTable(sql.Query("SELECT * FROM first_blood") or {})
        end
        return ""
    elseif cmd == "!firstblood" then
        if isGroup(ply) then
            local getAllResult = sql.Query("SELECT * FROM first_blood ORDER BY Deaths DESC") or {}
            if #getAllResult > 0 then
                net.Start("ViewFB")
                net.WriteTable(getAllResult)
                net.Send(ply)
            else
                ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: No entries yet!")
            end
        end
        return ""
    end
end)

hook.Add("TTTBeginRound", "firstBloodReset", function()
    firstBlood = { Victim = "", Attacker = "" }
end)

hook.Add("PlayerDeath", "firstBloodDeath", function(victim, _, attacker)
    if attacker == victim then return end
    if firstBlood.Victim == "" then
        firstBlood = { Victim = victim, Attacker = attacker }
        sqlInsertFirstBlood(victim, attacker)
    end
end)
