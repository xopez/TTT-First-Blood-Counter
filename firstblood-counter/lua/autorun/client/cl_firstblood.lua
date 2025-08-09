surface.CreateFont("Stats",    { font = "Bebas Neue", size = 40, weight = 500, antialias = true })
surface.CreateFont("Category", { font = "Bebas Neue", size = 26, weight = 500, antialias = true })
surface.CreateFont("List",     { font = "Tuffy",      size = 14, weight = 500, antialias = true })

local FB = {}
local DPanel, PlayerList
local steamCache = {}

local COLORS = {
    bgDark    = Color(44, 62, 80),
    bgMid     = Color(54, 73, 93),
    border    = Color(54, 73, 103),
    scrollBar = Color(75, 75, 75),
    btnRed    = Color(152, 0, 0),
    white     = Color(255, 255, 255)
}

-- helpfuction
local function TextSize(font, msg)
    surface.SetFont(font)
    return surface.GetTextSize(msg)
end

local function wrapString(str, maxLen)
    return (#str > maxLen) and (str:sub(1, maxLen) .. "...") or str
end

-- async
local function requestPlayerNameAsync(sid, callback)
    if steamCache[sid] then
        callback(steamCache[sid])
        return
    end

    local sid64 = util.SteamIDTo64(sid)
    steamCache[sid] = "Loading..."

    steamworks.RequestPlayerInfo(sid64, function()
        local name = steamworks.GetPlayerName(sid64)
        if name == "" then name = "Bot" end
        steamCache[sid] = name
        if callback then callback(name) end
    end)
end

-- get playerlist
local function updatePlayerList(value4)
    PlayerList:Clear()
    local _, nameHeight = TextSize("List", "Name")

    for _, v in ipairs(FB) do
        local playerPanel = vgui.Create("DPanel")
        playerPanel:SetTall(25)

        local displayName = steamCache[v.SID] or "Loading..."
        requestPlayerNameAsync(v.SID, function(newName)
            displayName = wrapString(newName, 30)
            if IsValid(playerPanel) then playerPanel:InvalidateLayout(true) end
        end)

        playerPanel.Paint = function()
            draw.RoundedBox(0, 0, 0, playerPanel:GetWide(), 25, ColorAlpha(COLORS.bgMid, value4))
            draw.DrawText(displayName, "List", (460/5)+6,       (25/2 - nameHeight/2) - 1, ColorAlpha(COLORS.white, value4), TEXT_ALIGN_CENTER)
            draw.DrawText(v.Num,       "List", (460/10*3.7)+68, (25/2 - nameHeight/2) - 1, ColorAlpha(COLORS.white, value4), TEXT_ALIGN_CENTER)
            draw.DrawText(v.Deaths,    "List", (460/10*7)+68,   (25/2 - nameHeight/2) - 1, ColorAlpha(COLORS.white, value4), TEXT_ALIGN_CENTER)
        end

        PlayerList:AddItem(playerPanel)
    end
end

-- Main function
local function FirstBlood()
    local value, value2, value3, value4 = 0, 0, 0, 0
    local speed, speed2 = 8, 1

    DPanel = vgui.Create("DFrame")
    DPanel:SetPos(ScrW()/2 - 250, ScrH()/2 - 350)
    DPanel:SetSize(500, 700)
    DPanel:SetTitle("")
    DPanel:SetDraggable(false)
    DPanel:ShowCloseButton(true)
    DPanel:MakePopup()
    DPanel:SetFocusTopLevel(true)

    local function updateValues()
        value  = Lerp(speed  * FrameTime(), value,  255)
        value2 = Lerp(speed  * FrameTime(), value2, 200)
        value3 = Lerp(speed  * FrameTime(), value3, 150)
        value4 = Lerp(speed2 * FrameTime(), value4, 255)
    end

    local headerText = {
        { "First Blood Counter", "Stats",    250,                 28 },
        { "Name",                "Category", (480/5)+20,          81 },
        { "First Bloods",        "Category", (460/10*3.7)+80,      81 },
        { "First Deaths",        "Category", (460/10*7)+80,        81 }
    }

    local boxLayout = {
        {0,   0,   500, 700, COLORS.bgDark},
        {4,   4,   492, 50,  COLORS.bgMid},
        {0,   0,   500, 2,   COLORS.border},
        {0, 698,   500, 2,   COLORS.border},
        {0,   0,     2, 700, COLORS.border},
        {498, 0,     2, 700, COLORS.border},
        {8,  62,   484, 38,  COLORS.bgMid},
        {8, 100,     2, 591, COLORS.bgMid},
        {490,100,    2, 591, COLORS.bgMid},
        {8, 689,   484, 2,   COLORS.bgMid}
    }

    DPanel.Paint = function()
        updateValues()
        for _, b in ipairs(boxLayout) do
            draw.RoundedBox(0, b[1], b[2], b[3], b[4], ColorAlpha(b[5], value))
        end
        for _, t in ipairs(headerText) do
            draw.SimpleText(t[1], t[2], t[3], t[4], ColorAlpha(COLORS.white, value), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        updatePlayerList(value4)
    end

    -- scrolling
    PlayerList = vgui.Create("DScrollPanel", DPanel)
    PlayerList:SetPos(10, 104)
    PlayerList:SetSize(477, 566)

    local dBar = PlayerList:GetVBar()
    dBar.Paint     = function(w, h) draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.scrollBar, value3)) end
    dBar.btnUp.Paint   = function(w, h) draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.btnRed, value2)) end
    dBar.btnDown.Paint = function(w, h) draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.btnRed, value2)) end
    dBar.btnGrip.Paint = function(w, h) draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(COLORS.white, value)) end
end

net.Receive("ViewFB", function()
    FB = net.ReadTable()
    if not IsValid(DPanel) then
        FirstBlood()
    else
        updatePlayerList(255)
    end
end)
