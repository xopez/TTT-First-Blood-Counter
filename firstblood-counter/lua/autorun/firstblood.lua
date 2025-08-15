if CLIENT then
    surface.CreateFont("Stats", { font = "Bebas Neue", size = 40, weight = 500, antialias = true })
    surface.CreateFont(
        "Category",
        { font = "Bebas Neue", size = 26, weight = 500, antialias = true }
    )
    surface.CreateFont("List", { font = "Tuffy", size = 14, weight = 500, antialias = true })
    local FB = {}
    function TextSize(font, msg)
        surface.SetFont(font)
        return surface.GetTextSize(msg)
    end
    function wrapString(str, width)
        return (string.len(str) > width) and (string.sub(str, 1, width) .. "...") or str
    end
    function FirstBlood()
        local value, value2, value3, value4 = 0, 0, 0, 0
        local speed, speed2 = 8, 1
        local DPanel = vgui.Create("DFrame")
        DPanel:SetPos(ScrW() / 2 - 250, ScrH() / 2 - 350)
        DPanel:SetSize(500, 700)
        DPanel:SetTitle("")
        DPanel:SetDraggable(false)
        DPanel:ShowCloseButton(true)
        DPanel:MakePopup()
        DPanel:SetFocusTopLevel(true)
        DPanel.Paint = function()
            value = Lerp(speed * FrameTime(), value, 255)
            value2 = Lerp(speed * FrameTime(), value2, 200)
            value3 = Lerp(speed * FrameTime(), value3, 150)
            value4 = Lerp(speed2 * FrameTime(), value4, 255)
            local colors = {
                bg = Color(44, 62, 80, value),
                header = Color(54, 73, 93, value),
                border = Color(54, 73, 103, value),
            }
            draw.RoundedBox(0, 0, 0, 500, 700, colors.bg)
            draw.RoundedBox(0, 4, 4, 492, 50, colors.header)
            draw.RoundedBox(0, 0, 0, 500, 2, colors.border)
            draw.RoundedBox(0, 0, 698, 500, 2, colors.border)
            draw.RoundedBox(0, 0, 0, 2, 700, colors.border)
            draw.RoundedBox(0, 498, 0, 2, 700, colors.border)
            draw.RoundedBox(0, 8, 62, 484, 38, colors.header)
            draw.RoundedBox(0, 8, 100, 2, 591, colors.header)
            draw.RoundedBox(0, 490, 100, 2, 591, colors.header)
            draw.RoundedBox(0, 8, 689, 484, 2, colors.header)
            draw.SimpleText(
                "First Blood Counter",
                "Stats",
                250,
                28,
                Color(255, 255, 255, value),
                1,
                1
            )
            draw.SimpleText("Name", "Category", 116, 81, Color(255, 255, 255, value), 1, 1)
            draw.SimpleText("First Bloods", "Category", 250, 81, Color(255, 255, 255, value), 1, 1)
            draw.SimpleText("First Deaths", "Category", 370, 81, Color(255, 255, 255, value), 1, 1)
        end
        local PlayerList = vgui.Create("DScrollPanel", DPanel)
        PlayerList:SetPos(10, 104)
        PlayerList:SetSize(477, 566)
        PlayerList:SetPadding(0)
        PlayerList.Paint = function() end
        local dBar = PlayerList:GetVBar()
        function dBar:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(75, 75, 75, value3))
        end
        function dBar.btnUp:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(152, 0, 0, value2))
        end
        function dBar.btnDown:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(152, 0, 0, value2))
        end
        function dBar.btnGrip:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, value))
        end
        for k, v in pairs(FB) do
            local playerPanel = vgui.Create("DPanel")
            playerPanel:SetPos(3, (26 * (k - 1)) + (k - 1))
            playerPanel:SetSize(490, 25)
            playerPanel.Paint = function()
                local _, nameHeight = TextSize("List", "Name")
                local sid64 = util.SteamIDTo64(v["SID"])
                steamworks.RequestPlayerInfo(sid64)
                draw.RoundedBox(0, 0, 0, 490, 25, Color(54, 73, 93, value4))
                local pname = steamworks.GetPlayerName(sid64)
                if pname == "" then
                    pname = "Bot"
                end
                draw.DrawText(
                    wrapString(pname, 30),
                    "List",
                    98,
                    (25 / 2 - nameHeight / 2) - 1,
                    Color(255, 255, 255, value4),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                draw.DrawText(
                    v["Num"],
                    "List",
                    250,
                    (25 / 2 - nameHeight / 2) - 1,
                    Color(255, 255, 255, value4),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                draw.DrawText(
                    v["Deaths"],
                    "List",
                    370,
                    (25 / 2 - nameHeight / 2) - 1,
                    Color(255, 255, 255, value4),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
            PlayerList:AddItem(playerPanel)
        end
    end
    net.Receive("ViewFB", function(len, ply)
        FB = net.ReadTable()
        FirstBlood()
    end)
else
    local firstBlood = {}
    util.AddNetworkString("ChatMessage")
    util.AddNetworkString("ViewFB")
    print("First Blood Counter loaded!")
    function sqlMakeFBDatabase()
        if not sql.TableExists("first_blood") then
            local query = "CREATE TABLE first_blood ( SID string, Num int, Deaths int)"
            result = sql.Query(query)
        end
    end
    sqlMakeFBDatabase()
    function sqlInsertFirstBlood(victim, attacker)
        if sql.TableExists("first_blood") then
            if
                attacker
                and attacker.IsValid
                and attacker:IsValid()
                and attacker.IsPlayer
                and attacker:IsPlayer()
            then
                local getAttQuery = "SELECT * FROM first_blood WHERE SID = '"
                    .. attacker:SteamID()
                    .. "'"
                getAttResult = sql.Query(getAttQuery)
                if getAttResult == nil then
                    local query = "INSERT INTO first_blood ('SID', 'Num', 'Deaths') VALUES ( '"
                        .. attacker:SteamID()
                        .. "', '"
                        .. 1
                        .. "', '"
                        .. 0
                        .. "')"
                    result = sql.Query(query)
                else
                    local query = "UPDATE first_blood SET Num = '"
                        .. getAttResult[1]["Num"] + 1
                        .. "' WHERE SID = '"
                        .. attacker:SteamID()
                        .. "'"
                    result = sql.Query(query)
                end
            end
            if
                victim
                and victim.IsValid
                and victim:IsValid()
                and victim.IsPlayer
                and victim:IsPlayer()
            then
                local getVicQuery = "SELECT * FROM first_blood WHERE SID = '"
                    .. victim:SteamID()
                    .. "'"
                getVicResult = sql.Query(getVicQuery)
                if getVicResult == nil then
                    local query = "INSERT INTO first_blood ('SID', 'Num', 'Deaths') VALUES ( '"
                        .. victim:SteamID()
                        .. "', '"
                        .. 0
                        .. "', '"
                        .. 1
                        .. "')"
                    result = sql.Query(query)
                else
                    local query = "UPDATE first_blood SET Deaths = '"
                        .. getVicResult[1]["Deaths"] + 1
                        .. "' WHERE SID = '"
                        .. victim:SteamID()
                        .. "'"
                    result = sql.Query(query)
                end
                local getAllQuery = "SELECT * FROM first_blood"
                getAllResult = sql.Query(getAllQuery)
                if getAllResult == nil then
                    return
                else
                    PrintTable(getAllResult)
                end
            end
        end
    end
    function isGroup(ply)
        return true
    end
    function sqlScrubFBDatabase()
        if sql.TableExists("first_blood") then
            local query = "DELETE FROM first_blood"
            local result = sql.Query(query)
        end
    end
    hook.Add("PlayerSay", "ScrubFBDatabase", function(ply, text)
        local phrase = string.lower("!scrubFB")
        local split = string.Explode(" ", text)
        local cmd = string.lower(split[1])
        if cmd == phrase and (ply:IsAdmin() or ply:IsSuperAdmin()) then
            sqlScrubFBDatabase()
            ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: Databases deleted!\n")
            return
        end
        if cmd == phrase and (not ply:IsAdmin() or not ply:IsSuperAdmin()) then
            ply:PrintMessage(
                HUD_PRINTTALK,
                "FirstBlood: You are not allowed to reset the First Blood Counter!\n"
            )
        end
    end)
    hook.Add("PlayerSay", "printFB", function(ply, text)
        local phrase = string.lower("!printFB")
        local split = string.Explode(" ", text)
        local cmd = string.lower(split[1])
        if cmd == phrase and isGroup(ply) then
            local getAllQuery = "SELECT * FROM first_blood"
            getAllResult = sql.Query(getAllQuery)
            if getAllResult == nil then
                return
            else
                PrintTable(getAllResult)
            end
            return
        end
    end)
    hook.Add("PlayerSay", "ViewFB", function(ply, text)
        local split = string.Explode(" ", text)
        local cmd = string.lower(split[1])
        if (cmd == "!firstblood" or cmd == "!fb") and isGroup(ply) then
            local getAllResult = sql.Query("SELECT * FROM first_blood ORDER BY Deaths DESC")
            if getAllResult then
                net.Start("ViewFB")
                net.WriteTable(getAllResult)
                net.Send(ply)
            else
                Msg("\nFirstBlood: Table is empty!\n")
                ply:PrintMessage(HUD_PRINTTALK, "FirstBlood: No first blood's fallen!\n")
            end
        end
    end)
    hook.Add("TTTBeginRound", "firstBlood", function(ply)
        firstBlood = { ["Victim"] = "", ["Attacker"] = "" }
    end)
    hook.Add("PlayerDeath", "firstBloodDeath", function(victim, inflictor, attacker)
        if attacker == victim then
            return
        end
        if firstBlood["Victim"] == "" then
            firstBlood = { ["Victim"] = victim, ["Attacker"] = attacker }
            sqlInsertFirstBlood(victim, attacker)
        end
    end)
    hook.Add("TTTEndRound", "AnnounceFirstBlood", function(result)
        if firstBlood and firstBlood["Victim"] ~= "" and firstBlood["Attacker"] ~= "" then
            local attacker = firstBlood["Attacker"]
            local victim = firstBlood["Victim"]
            if
                IsValid(attacker)
                and attacker:IsPlayer()
                and IsValid(victim)
                and victim:IsPlayer()
            then
                local attSteamID = attacker:SteamID()
                local vicSteamID = victim:SteamID()
                if attSteamID == "" then
                    attSteamID = "Bot"
                end
                if vicSteamID == "" then
                    vicSteamID = "Bot"
                end
                local attCount, attDeaths, vicCount, vicDeaths = 0, 0, 0, 0
                local attResult = sql.Query(
                    "SELECT Num, Deaths FROM first_blood WHERE SID = '" .. attSteamID .. "'"
                )
                if attResult and attResult[1] then
                    attCount = tonumber(attResult[1]["Num"]) or 0
                    attDeaths = tonumber(attResult[1]["Deaths"]) or 0
                end
                local vicResult = sql.Query(
                    "SELECT Num, Deaths FROM first_blood WHERE SID = '" .. vicSteamID .. "'"
                )
                if vicResult and vicResult[1] then
                    vicCount = tonumber(vicResult[1]["Num"]) or 0
                    vicDeaths = tonumber(vicResult[1]["Deaths"]) or 0
                end
                -- Line 1: First Blood
                for _, ply in ipairs(player.GetAll()) do
                    ply:PrintMessage(
                        HUD_PRINTTALK,
                        string.format(
                            "First Blood! %s killed %s first!",
                            attacker:Nick(),
                            victim:Nick()
                        )
                    )
                    -- Line 2: Stats
                    ply:PrintMessage(
                        HUD_PRINTTALK,
                        string.format(
                            "%s: %d First Bloods / %d First Deaths   |   %s: %d First Bloods / %d First Deaths",
                            attacker:Nick(),
                            attCount,
                            attDeaths,
                            victim:Nick(),
                            vicCount,
                            vicDeaths
                        )
                    )
                    -- Line 3: Hint
                    ply:PrintMessage(HUD_PRINTTALK, "Type !fb to see all stats.")
                end
            end
        end
    end)
end
