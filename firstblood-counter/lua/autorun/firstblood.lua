if SERVER then
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
        if not steamid then
            return
        end
        local current = tonumber(
            sql.QueryValue("SELECT " .. stat .. " FROM first_blood WHERE SID = '" .. steamid .. "'")
        ) or 0
        if
            current == 0
            and not sql.QueryValue("SELECT SID FROM first_blood WHERE SID = '" .. steamid .. "'")
        then
            local num, deaths =
                (stat == "Num" and increment or 0), (stat == "Deaths" and increment or 0)
            sql.Query(
                string.format(
                    "INSERT INTO first_blood (SID, Num, Deaths) VALUES ('%s', %d, %d)",
                    steamid,
                    num,
                    deaths
                )
            )
        else
            sql.Query(
                string.format(
                    "UPDATE first_blood SET %s = %d WHERE SID = '%s'",
                    stat,
                    current + increment,
                    steamid
                )
            )
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
        elseif cmd == "!firstblood" or cmd == "!fb" then
            if isGroup(ply) then
                local getAllResult = sql.Query("SELECT * FROM first_blood ORDER BY Deaths DESC")
                    or {}
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
        if attacker == victim then
            return
        end
        if firstBlood.Victim == "" then
            firstBlood = { Victim = victim, Attacker = attacker }
            sqlInsertFirstBlood(victim, attacker)
        end
    end)
else
    surface.CreateFont("Stats", { font = "Bebas Neue", size = 40, weight = 500, antialias = true })
    surface.CreateFont(
        "Category",
        { font = "Bebas Neue", size = 26, weight = 500, antialias = true }
    )
    surface.CreateFont("List", { font = "Tuffy", size = 14, weight = 500, antialias = true })

    local FB = {}
    local DPanel, PlayerList

    local COLORS = {
        bgDark = Color(44, 62, 80),
        bgMid = Color(54, 73, 93),
        border = Color(54, 73, 103),
        scrollBar = Color(75, 75, 75),
        btnRed = Color(152, 0, 0),
        white = Color(255, 255, 255),
    }

    local function TextSize(font, msg)
        surface.SetFont(font)
        return surface.GetTextSize(msg)
    end

    local function wrapString(str, maxLen)
        return (#str > maxLen) and (str:sub(1, maxLen) .. "...") or str
    end

    local function requestPlayerNameAsync(sid, callback)
        local sid64 = util.SteamIDTo64(sid)
        if not sid64 then
            callback("Unknown")
            return
        end
        steamworks.RequestPlayerInfo(sid64, function()
            local name = steamworks.GetPlayerName(sid64)
            if name == "" then
                name = "Bot"
            end
            if callback then
                callback(name)
            end
        end)
    end

    local function updatePlayerList(value4)
        if not IsValid(PlayerList) then
            return
        end
        PlayerList:Clear()

        local _, nameHeight = TextSize("List", "Name")
        local dataList = {}
        if FB and #FB == 0 then
            for _, v in pairs(FB) do
                table.insert(dataList, v)
            end
        else
            dataList = FB or {}
        end
        for _, v in ipairs(dataList) do
            local playerPanel = vgui.Create("DPanel")
            playerPanel:SetTall(25)

            local displayName = "Loading..."
            requestPlayerNameAsync(v.SID, function(newName)
                newName = wrapString(newName or "Unknown", 30)
                displayName = newName
                if IsValid(playerPanel) then
                    playerPanel:InvalidateLayout(true)
                end
            end)

            playerPanel.Paint = function(s, w, h)
                draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.bgMid, value4))
                draw.DrawText(
                    displayName,
                    "List",
                    (460 / 5) + 6,
                    (h / 2 - nameHeight / 2) - 1,
                    ColorAlpha(COLORS.white, value4),
                    TEXT_ALIGN_CENTER
                )
                draw.DrawText(
                    v.Num or 0,
                    "List",
                    (460 / 10 * 3.7) + 68,
                    (h / 2 - nameHeight / 2) - 1,
                    ColorAlpha(COLORS.white, value4),
                    TEXT_ALIGN_CENTER
                )
                draw.DrawText(
                    v.Deaths or 0,
                    "List",
                    (460 / 10 * 7) + 68,
                    (h / 2 - nameHeight / 2) - 1,
                    ColorAlpha(COLORS.white, value4),
                    TEXT_ALIGN_CENTER
                )
            end

            PlayerList:AddItem(playerPanel)
        end
    end

    local function FirstBlood()
        local value, value2, value3, value4 = 0, 0, 0, 0
        local speed, speed2 = 8, 1

        DPanel = vgui.Create("DFrame")
        DPanel:SetPos(ScrW() / 2 - 250, ScrH() / 2 - 350)
        DPanel:SetSize(500, 700)
        DPanel:SetTitle("")
        DPanel:SetDraggable(false)
        DPanel:ShowCloseButton(true)
        DPanel:MakePopup()
        DPanel:SetFocusTopLevel(true)

        local headerText = {
            { "First Blood Counter", "Stats", 250, 28 },
            { "Name", "Category", (480 / 5) + 20, 81 },
            { "First Bloods", "Category", (460 / 10 * 3.7) + 80, 81 },
            { "First Deaths", "Category", (460 / 10 * 7) + 80, 81 },
        }

        local boxLayout = {
            { 0, 0, 500, 700, COLORS.bgDark },
            { 4, 4, 492, 50, COLORS.bgMid },
            { 0, 0, 500, 2, COLORS.border },
            { 0, 698, 500, 2, COLORS.border },
            { 0, 0, 2, 700, COLORS.border },
            { 498, 0, 2, 700, COLORS.border },
            { 8, 62, 484, 38, COLORS.bgMid },
            { 8, 100, 2, 591, COLORS.bgMid },
            { 490, 100, 2, 591, COLORS.bgMid },
            { 8, 689, 484, 2, COLORS.bgMid },
        }

        function DPanel:Paint(w, h)
            value = Lerp(speed * FrameTime(), value, 255)
            value2 = Lerp(speed * FrameTime(), value2, 200)
            value3 = Lerp(speed * FrameTime(), value3, 150)
            value4 = Lerp(speed2 * FrameTime(), value4, 255)

            for _, b in ipairs(boxLayout) do
                draw.RoundedBox(0, b[1], b[2], b[3], b[4], ColorAlpha(b[5], value))
            end
            for _, t in ipairs(headerText) do
                draw.SimpleText(
                    t[1],
                    t[2],
                    t[3],
                    t[4],
                    ColorAlpha(COLORS.white, value),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end

        PlayerList = vgui.Create("DScrollPanel", DPanel)
        PlayerList:SetPos(10, 104)
        PlayerList:SetSize(477, 566)

        local dBar = PlayerList:GetVBar()
        dBar.Paint = function(w, h)
            draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.scrollBar, value3))
        end
        dBar.btnUp.Paint = function(w, h)
            draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.btnRed, value2))
        end
        dBar.btnDown.Paint = function(w, h)
            draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.btnRed, value2))
        end
        dBar.btnGrip.Paint = function(w, h)
            draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.white, value))
        end
    end

    net.Receive("ViewFB", function()
        FB = net.ReadTable()
        if not IsValid(DPanel) then
            FirstBlood()
        end
        updatePlayerList(255)
    end)
end
