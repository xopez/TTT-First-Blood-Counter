if CLIENT then
    surface.CreateFont("Stats", { font = "Bebas Neue", size = 40, weight = 500, antialias = true })
    surface.CreateFont("Category", { font = "Bebas Neue", size = 26, weight = 500, antialias = true })
    surface.CreateFont("List", { font = "Tuffy", size = 14, weight = 500, antialias = true })

    local FB = {}

    local function TextSize(font, msg)
        surface.SetFont(font)
        local w, h = surface.GetTextSize(msg)
        return w, h
    end

    local function wrapString(str, maxLen)
        if #str > maxLen then
            str = string.sub(str, 1, maxLen) .. "..."
        end
        return str
    end

    local function FirstBlood()
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
            value  = Lerp(speed * FrameTime(), value, 255)
            value2 = Lerp(speed * FrameTime(), value2, 200)
            value3 = Lerp(speed * FrameTime(), value3, 150)
            value4 = Lerp(speed2 * FrameTime(), value4, 255)

            draw.RoundedBox(0, 0, 0, 500, 700, Color(44, 62, 80, value))
            draw.RoundedBox(0, 4, 4, 492, 50, Color(54, 73, 93, value))
            draw.RoundedBox(0, 0, 0, 500, 2, Color(54, 73, 103, value))
            draw.RoundedBox(0, 0, 698, 500, 2, Color(54, 73, 103, value))
            draw.RoundedBox(0, 0, 0, 2, 700, Color(54, 73, 103, value))
            draw.RoundedBox(0, 498, 0, 2, 700, Color(54, 73, 103, value))

            draw.RoundedBox(0, 8, 62, 484, 38, Color(54, 73, 93, value))
            draw.RoundedBox(0, 8, 100, 2, 591, Color(54, 73, 93, value))
            draw.RoundedBox(0, 490, 100, 2, 591, Color(54, 73, 93, value))
            draw.RoundedBox(0, 8, 689, 484, 2, Color(54, 73, 93, value))

            draw.SimpleText("First Blood Counter", "Stats", 500 / 2, 28, Color(255, 255, 255, value), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Name", "Category", (480 / 5) + 20, 81, Color(255, 255, 255, value), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("First Bloods", "Category", (460 / 10 * 3.7) + 80, 81, Color(255, 255, 255, value), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("First Deaths", "Category", (460 / 10 * 7) + 80, 81, Color(255, 255, 255, value), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local PlayerList = vgui.Create("DScrollPanel", DPanel)
        PlayerList:SetPos(10, 104)
        PlayerList:SetSize(477, 566)

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

        for k, v in ipairs(FB) do
            local playerPanel = vgui.Create("DPanel")
            playerPanel:SetPos(3, (26 * (k - 1)) + (k - 1))
            playerPanel:SetSize(490, 25)
            playerPanel.Paint = function()
                local _, nameHeight = TextSize("List", "Name")
                steamworks.RequestPlayerInfo(util.SteamIDTo64(v["SID"]))

                draw.RoundedBox(0, 0, 0, 490, 25, Color(54, 73, 93, value4))
                local name = steamworks.GetPlayerName(util.SteamIDTo64(v["SID"]))
                if name == "" then name = "Bot" end
                draw.DrawText(wrapString(name, 30), "List", (460 / 5) + 6, (25 / 2 - nameHeight / 2) - 1, Color(255, 255, 255, value4), TEXT_ALIGN_CENTER)
                draw.DrawText(v["Num"], "List", (460 / 10 * 3.7) + 68, (25 / 2 - nameHeight / 2) - 1, Color(255, 255, 255, value4), TEXT_ALIGN_CENTER)
                draw.DrawText(v["Deaths"], "List", (460 / 10 * 7) + 68, (25 / 2 - nameHeight / 2) - 1, Color(255, 255, 255, value4), TEXT_ALIGN_CENTER)
            end
            PlayerList:AddItem(playerPanel)
        end
    end

    -- Receive and display scoreboard
    net.Receive("ViewFB", function()
        FB = net.ReadTable()
        FirstBlood()
    end)
end
