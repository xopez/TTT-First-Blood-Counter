AddCSLuaFile()

if SERVER then
    local firstBlood = {}
    util.AddNetworkString("ChatMessage")
    util.AddNetworkString("ViewFB")
    print("First Blood Counter loaded!")

    -- Create database if it doesn't exist
    local function sqlMakeFBDatabase()
        if not sql.TableExists("first_blood") then
            local query = "CREATE TABLE first_blood ( SID string, Num int, Deaths int)"
            sql.Query(query)
        end
    end
    sqlMakeFBDatabase()

    -- Insert or update first blood data
    local function sqlInsertFirstBlood(victim, attacker)
        if not sql.TableExists("first_blood") then return end

        if IsValid(attacker) and attacker:IsPlayer() then
            local getAttResult = sql.Query("SELECT * FROM first_blood WHERE SID = '" .. attacker:SteamID() .. "'")
            if not getAttResult then
                sql.Query("INSERT INTO first_blood ('SID', 'Num', 'Deaths') VALUES ( '" .. attacker:SteamID() .. "', 1, 0)")
            else
                sql.Query("UPDATE first_blood SET Num = '" .. (getAttResult[1]["Num"] + 1) .. "' WHERE SID = '" .. attacker:SteamID() .. "'")
            end
        end

        if IsValid(victim) and victim:IsPlayer() then
            local getVicResult = sql.Query("SELECT * FROM first_blood WHERE SID = '" .. victim:SteamID() .. "'")
            if not getVicResult then
                sql.Query("INSERT INTO first_blood ('SID', 'Num', 'Deaths') VALUES ( '" .. victim:SteamID() .. "', 0, 1)")
            else
                sql.Query("UPDATE first_blood SET Deaths = '" .. (getVicResult[1]["Deaths"] + 1) .. "' WHERE SID = '" .. victim:SteamID() .. "'")
            end
        end
    end

    -- Simple group/admin check (no ULib needed)
    local function isGroup(ply)
        return ply:IsAdmin() or ply:IsSuperAdmin()
    end

    -- Delete all data
    local function sqlScrubFBDatabase()
        if sql.TableExists("first_blood") then
            sql.Query("DELETE FROM first_blood")
        end
    end

    -- Chat commands
    hook.Add("PlayerSay", "ScrubFBDatabase", function(ply, text)
        local cmd = string.lower(string.Explode(" ", text)[1] or "")
        if cmd == "!scrubfb" then
            if isGroup(ply) then
                sqlScrubFBDatabase()
                ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: Database cleared!")
            else
                ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: You are not allowed to reset the database!")
            end
            return ""
        end
    end)

    hook.Add("PlayerSay", "printFB", function(ply, text)
        if string.lower(string.Explode(" ", text)[1] or "") == "!printfb" and isGroup(ply) then
            local getAllResult = sql.Query("SELECT * FROM first_blood")
            if getAllResult then
                PrintTable(getAllResult)
            end
            return ""
        end
    end)

    hook.Add("PlayerSay", "ViewFB", function(ply, text)
        if string.lower(string.Explode(" ", text)[1] or "") == "!firstblood" and isGroup(ply) then
            local getAllResult = sql.Query("SELECT * FROM first_blood ORDER BY Deaths DESC")
            if getAllResult then
                net.Start("ViewFB")
                net.WriteTable(getAllResult)
                net.Send(ply)
            else
                ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: No entries yet!")
            end
            return ""
        end
    end)

    -- Hooks
    hook.Add("TTTBeginRound", "firstBlood", function()
        firstBlood = { Victim = "", Attacker = "" }
    end)

    hook.Add("PlayerDeath", "firstBloodDeath", function(victim, _, attacker)
        if attacker == victim then return end
        if firstBlood.Victim == "" then
            firstBlood = { Victim = victim, Attacker = attacker }
            sqlInsertFirstBlood(victim, attacker)
        end
    end)
end
