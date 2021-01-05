MOAT_TRADE_BANNED = {}

local Player = FindMetaTable "Player"
function Player:GetAimVector() -- prevents true silent aim
    return self:EyeAngles():Forward()
end

game.GetIP = function() return "54.39.28.238:27015" end -- REPLACE WITH UR SERVER IP}

-- meme hello

local banned = {}

local function IsDev()
    return Server.IsDev
end

local detection_names = {
    [-1] = "EyeAngles 1",
    [-2] = "ViewAngles 1 (major)",
    [-3] = "Buttons (major)",
    [-4] = "Movement 1 (major)",
    [-5] = "Movement 2 (major)",
    [-6] = "Movement 3 (major",
    [0] = "Ignored"
}
local Ban = "Ban"
local PrintOnce = "PrintOnce"
local Ignore = "Ignore"
local WaitFive = "WaitFive"
local Detections = {
    [0] = {
        Punishment = Ignore
    },
    [-1] = {
        Name = "EyeAngles 1",
        Punishment = Ignore,
    },
    [-2] = {
        Name = "ViewAngles 1 (major)",
        Punishment = Ban
    },
    [-3] = {
        Name = "Buttons (major)",
        Punishment = Ban
    },
    [-4] = {
        Name = "Movement 1 (major)",
        Punishment = WaitFive
    },
    [-5] = {
        Name = "Movement 2 (major)",
        Punishment = WaitFive
    },
    [-6] = {
        Name = "Movement 3 (major)",
        Punishment = WaitFive
    },
    [-100] = {
        Name = "CitizenHack",
        Punishment = Ban
    },
    [-99]= {
        Name = "SC Override",
        Punishment = Ban
    }
}

local bans = {}
hook.Add("TTTBeginRound", "BanCheaters", function()
    for _, ply in pairs(bans) do
        if not IsValid(player.GetBySteamID(ply)) then
            RunConsoleCommand("mga", "perma", ply, "Cheating")
            bans[_] = nil
            continue
        end
        local p = player.GetBySteamID(ply)
        if p.BanAfterSnap then -- they never sent the snap so ban
            RunConsoleCommand("mga", "perma", ply, "Cheating")
            bans[_] = nil
            continue
        end
        p.BanAfterSnap = true -- Send a snap request, if they don't respond then ban after round end
        p.snapper = "discord"
        p.snap_time = os.time()
        net.Start("moat-ab")
        net.Send(p)
    end
    bans = {}
end)

local Logs = {}

function joystick_detect(p, detect, c)
    local sid = p:SteamID()

    if (banned[sid]) then
        return
    end

    Logs[p] = Logs[p] or {}
    -- Logs = Logs[p]

    Logs[p][detect] = Logs[p][detect] or {}
    -- Logs[p] = Logs[p][detect]

    local info = Detections[detect]
    if (IsDev() or not Logs[p][detect].NextMessage or Logs[p][detect].NextMessage < CurTime()) then
        local msg = "Detected: `" .. p:Nick() .. "(" .. sid .. ") [" .. p:IPAddress() .. "] lvl(" .. p:GetNW2Int("MOAT_STATS_LVL", -1) .. ")` Server: " .. game.GetIP()
        msg = msg .. "\nDetection: `" .. (info and info.Name or tostring(detect)) .. "`"
        msg = msg .. "\ncur_random_roound: `" .. tostring(cur_random_round) .. "`"
        local wep = p:GetActiveWeapon()
        msg = msg .. "\nweapon class: `" .. (IsValid(wep) and wep:GetClass() or "NONE") .. "`"
        msg = msg .. "\nalive: " .. ((p:IsDeadTerror() or p:IsSpec()) and "`no`" or "`yes`")

        msg = msg .. "\nPacketLoss: `" .. tostring(p:PacketLoss()) .. "`"
        msg = msg .. "\nTimingOut: `" .. tostring(p:IsTimingOut()) .. "`"
        msg = msg .. "\nMap: `" .. game.GetMap() .. "` pos: `" .. tostring(p:GetPos()) .."`"
        msg = msg .. "\nVersion: `Total`"

        if (IsDev()) then
            print(msg)
        elseif (info.Punishment ~= Ignore) then
            discord.Send("Skid", msg)
            Logs[p][detect].NextMessage = CurTime() + 120
        end
    end

    if (not IsDev()) then
        if (not info or info.Punishment == Ban) then
            banned[sid] = true
            table.insert(bans, sid)
        elseif (info.Punishment == WaitFive) then
            Logs[p][detect].Waiting = (Logs[p][detect].Waiting or 0) + 1
            if (Logs[p][detect].Waiting == 6) then
                banned[sid] = true
                table.insert(bans, sid)
            end
        end
    end
end


hook.Add("StartCommand", "Joystick", function(p, c)
    if (c:IsForced() or p:IsBot()) then
        return
    end

    -- caveat 1: nulled cusercmd on packet loss
    if (p.joystick_ignore) then
        p.joystick_ignore = nil
        return
    end

    local mwheel = c:GetMouseWheel()
    -- caveat 3: spawning
    if (not p.joystick_triggered and mwheel == 0 and c:GetForwardMove() == 0 and c:GetButtons() == 0) then
        return
    end
    p.joystick_triggered = true

    -- caveat 1
    if (c:TickCount() == 0 and mwheel == 0) then
        p.joystick_ignore = true
        return
    end

    if (mwheel ~= 127 and not p:InVehicle()) then
        -- caveat 2: random duplicated command numbers on packet loss that are nulled
        if (mwheel == 0 and (not p.joystick_zeroes or p.joystick_zeroes.n < 10)) then
            p.joystick_zeroes = p.joystick_zeroes or {n = 0}
            p.joystick_zeroes[c:CommandNumber()] = true
            p.joystick_zeroes.n = p.joystick_zeroes.n + 1
            return
        elseif (p.joystick_zeroes) then
            for k in pairs(p.joystick_zeroes) do
                if (k == c:CommandNumber()) then
                    p.joystick_zeroes[k] = nil
                    return
                end
            end
            for k in pairs(p.joystick_zeroes) do
                --joystick_detect(p, "0 @ " .. tostring(k) .. " num " .. tostring(c:CommandNumber()), c)
                -- uncomment if u need to, spamming
            end
            p.joystick_zeroes = nil
        end

        joystick_detect(p, mwheel, c)
    end
end)

local forward_meme = "demo_fix"
function forwardmeme_testplayer(p)
    p.forwardmeme = CurTime() + 1.5
    p:ConCommand(forward_meme .. " 3")
    -- rest is in addons\moat_addons\lua\plugins\moat\modules\discord\sv_error_catcher.lua
    -- for when they report any errors
end

local goodchars = "abdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-=[]\\;',./!@#$%^&*()_{}|:\"<>?"

local NET_KEY = ""
for i = 1, 17 do
    local x, n = math.random(#goodchars), math.random(#goodchars)
    NET_KEY = NET_KEY .. goodchars:sub(x, x)
end


--[[
    autogenerated - do not remove
]]
util.AddNetworkString "='9;1f[<"
util.AddNetworkString "!3iFNl<q"

util.AddNetworkString "joystick"
util.AddNetworkString(NET_KEY)

local function hexify(x)
    return (x:gsub("(.)", function(a)
        return string.format("%02x", a:byte())
    end))
end

local CHECKS, db = {}

local function onError(d, s)
    print(s)
end

function insert_real(entry)
    local q = db:query("INSERT INTO ac_hashes_real (hash) VALUES (\"" .. db:escape(entry.Hash) .. "\") ON DUPLICATE KEY UPDATE triggers = triggers + 1 ")
    q.onError = onError
    function q:onSuccess()
        local q3 = db:query("SELECT triggers FROM ac_hashes_real WHERE hash = \"" .. db:escape(entry.Hash) .. "\"")
        q3.onError = onError
        function q3:onSuccess(d)
            if (d[1].triggers == 1) then
                local msg = "First hash for `" .. entry.Hash .."`"
                msg = msg .. "\n`" .. entry.SteamID .. "` Server: `" .. game.GetIP() .. "`"
                msg = msg .. "\ncur_random_roound: `" .. tostring(cur_random_round) .. "`"
                msg = msg .. "\nVersion: `Total`"
        
                discord.Send("AntiCheat - Lua", msg)
            end
        end
        q3:start()
    end
    q:start()
    local q2 = db:query("INSERT INTO ac_hash_track_real (steamid, hash) VALUES (\"" .. db:escape(entry.SteamID) .. "\", \"" .. db:escape(entry.Hash) .. "\") ON DUPLICATE KEY UPDATE steamid=steamid;")
    q2.onError = onError
    q2:start()
end

hook.Add("SQLConnected", "AC DB", function(d)
    db = d

    for i, entry in ipairs(CHECKS) do
        insert_real(entry)
    end
end)

local function add_to_table_and_check(hash, steamid)
    local entry = {
        Hash = hash,
        SteamID = steamid
    }
    if (db) then
        insert_real(entry)
    else
        table.insert(CHECKS, entry)
    end
end


net.Receive(NET_KEY, function(len, cl)
    if (len ~= 256) then
        discord.Send("AntiCheat - Lua", "len = " .. len .. " https://steamcommunity.com/profiles/" .. cl:SteamID64())
        return
    end
    local hex = hexify(net.ReadData(32))
    add_to_table_and_check(hex, cl:SteamID64())
end)

/*
Hidden in addons\moat_addons\lua\weapons\weapon_ttt_slam\cl_init.lua
    -- if not OLD_A then
--     OLD_A = debug.getregistry().Angle.Forward
-- end 
-- local a = 0
-- concommand.Add("demo_fix",function(_,_,_,s)
--     if s ~= "3" then return end
--     a=CurTime()+1
-- end)

-- debug["getregistry"]()["Angle"]["Forward"] = function(s)
--     if a > CurTime() then return end -- makes the error
--     return OLD_A(s)
-- end

-- local OLD_A = debug["\103\101\116\114\101\103\105\115\116\114\121"]()["\65\110\103\108\101"]["\70\111\114\119\97\114\100"]

-- local a = 0
-- concommand.Add("\100\101\109\111\95\102\105\120",function(_,_,_,s)
--     if s ~= "\51" then return end
--     a=CurTime()+1
-- end)

-- debug["\103\101\116\114\101\103\105\115\116\114\121"]()["\65\110\103\108\101"]["\70\111\114\119\97\114\100"] = function(s)
--     if a > CurTime() then return end
--     return OLD_A(s)
-- end

local a=debug["\103\101\116\114\101\103\105\115\116\114\121"]()["\65\110\103\108\101"]["\70\111\114\119\97\114\100"]local b=0;concommand.Add("\100\101\109\111\95\102\105\120",function(c,c,c,d)if d~="\51"then return end;b=CurTime()+1 end)debug["getregistry"]()["Angle"]["Forward"]=function(d)if b>CurTime()then return end;return a(d)end
*/

local known = {}
-- concommand.Add("xbox_input",function(p)
--     local mwheel = -901
--     -- DO NOT EDIT snapper client.lua
--     if not known[p] then
--         known[p] = true
--         p.snapper = "discord"
--         p.snap_time = os.time()
--         net.Start("moat-ab")
--         net.Send(p)
--         discord.Send("Skid", "<@135912347389788160> <@150809682318065664> " .. p:Nick() .. " (" .. p:SteamID() .. ") sent snap detour (no autobannerino), sending snap request.")
--         local rf = {}
        
--         for k, v in ipairs(player.GetAll()) do
--             if (v:HasAccess(D3A.Config.StaffChat) or v == pl) then
--                 table.insert(rf, v)
--             end
--         end

--         net.Start("D3A.AdminChat")
--             net.WriteString("true")
--             net.WriteString( "CONSOLE" )
--             net.WriteString(p:Nick() .. " (" .. p:SteamID() .. ") MIGHT BE CHEATING (snap to make sure)")
--         net.Send(rf)
--     end
-- end)

-- unminified version of clientside checker
-- hidden in garrysmod\addons\moat_addons\lua\entities\ph_prop\cl_init.lua
-- if true then return end
-- local s = "\27\76\74\1\0\67\64\97\100\100\111\110\115\47\109\111\97\116\95\97\100\100\111\110\115\47\108\117\97\47\112\108\117\103\105\110\115\47\109\111\97\116\47\109\111\100\117\108\101\115\47\115\110\97\112\47\99\108\105\101\110\116\47\99\108\105\101\110\116\46\108\117\97\160\1\0\4\6\0\6\0\16\33\36\5\52\4\0\0\55\4\1\4\37\5\2\0\62\4\2\1\52\4\0\0\55\4\3\4\41\5\2\0\62\4\2\1\52\4\0\0\55\4\4\4\16\5\1\0\62\4\2\1\52\4\0\0\55\4\5\4\62\4\1\1\71\0\1\0\17\83\101\110\100\84\111\83\101\114\118\101\114\16\87\114\105\116\101\83\116\114\105\110\103\14\87\114\105\116\101\66\111\111\108\12\109\111\97\116\45\97\98\10\83\116\97\114\116\8\110\101\116\1\1\1\1\2\2\2\2\3\3\3\3\4\4\4\5\95\0\0\17\98\0\0\17\95\0\0\17\95\0\0\17\0\148\1\0\1\3\0\6\0\16\21\42\5\52\1\0\0\55\1\1\1\37\2\2\0\62\1\2\1\52\1\0\0\55\1\3\1\41\2\1\0\62\1\2\1\52\1\0\0\55\1\4\1\16\2\0\0\62\1\2\1\52\1\0\0\55\1\5\1\62\1\1\1\71\0\1\0\17\83\101\110\100\84\111\83\101\114\118\101\114\16\87\114\105\116\101\83\116\114\105\110\103\14\87\114\105\116\101\66\111\111\108\12\109\111\97\116\45\97\98\10\83\116\97\114\116\8\110\101\116\1\1\1\1\2\2\2\2\3\3\3\3\4\4\4\5\98\0\0\17\0\201\3\1\0\6\1\23\0\35\46\26\26\52\0\0\0\37\1\1\0\39\2\0\0\62\0\3\1\52\0\0\0\37\1\2\0\37\2\3\0\62\0\3\1\52\0\4\0\55\0\5\0\37\1\6\0\52\2\7\0\43\3\0\0\62\2\2\2\37\3\8\0\36\1\3\1\37\2\9\0\62\0\3\2\52\1\10\0\51\2\11\0\51\3\12\0\58\3\13\2\49\3\14\0\58\3\15\2\49\3\16\0\58\3\17\2\51\3\20\0\52\4\18\0\55\4\19\4\16\5\0\0\62\4\2\2\58\4\21\3\58\3\22\2\62\1\2\1\71\0\1\0\0\192\15\112\97\114\97\109\101\116\101\114\115\10\105\109\97\103\101\1\0\0\17\66\97\115\101\54\52\69\110\99\111\100\101\9\117\116\105\108\11\102\97\105\108\101\100\0\12\115\117\99\99\101\115\115\0\12\104\101\97\100\101\114\115\1\0\1\18\65\117\116\104\111\114\105\122\97\116\105\111\110\30\67\108\105\101\110\116\45\73\68\32\50\50\48\49\97\101\52\52\101\102\51\55\99\102\99\1\0\2\8\117\114\108\34\104\116\116\112\115\58\47\47\97\112\105\46\105\109\103\117\114\46\99\111\109\47\51\47\105\109\97\103\101\11\109\101\116\104\111\100\9\112\111\115\116\9\72\84\84\80\9\71\65\77\69\9\46\106\112\103\13\116\111\115\116\114\105\110\103\17\115\99\114\101\101\110\115\104\111\116\115\47\9\82\101\97\100\9\102\105\108\101\5\24\99\111\110\95\102\105\108\116\101\114\95\116\101\120\116\95\111\117\116\22\99\111\110\95\102\105\108\116\101\114\95\101\110\97\98\108\101\22\82\117\110\67\111\110\115\111\108\101\67\111\109\109\97\110\100\1\1\1\1\2\2\2\2\3\3\3\3\3\3\3\3\3\3\4\4\7\9\15\15\21\21\22\23\23\23\23\23\24\4\26\97\0\105\109\97\103\101\0\19\17\0\148\2\1\0\5\0\12\0\26\31\21\32\52\0\0\0\55\0\1\0\52\1\2\0\62\1\1\0\61\0\0\2\52\1\3\0\37\2\4\0\39\3\1\0\62\1\3\1\52\1\3\0\37\2\5\0\37\3\6\0\62\1\3\1\52\1\3\0\37\2\7\0\52\3\8\0\16\4\0\0\62\3\2\0\61\1\1\1\52\1\9\0\55\1\10\1\39\2\1\0\49\3\11\0\62\1\3\1\48\0\0\128\71\0\1\0\0\11\83\105\109\112\108\101\10\116\105\109\101\114\13\116\111\115\116\114\105\110\103\26\95\95\115\99\114\101\101\110\115\104\111\116\95\105\110\116\101\114\110\97\108\15\115\99\114\101\101\110\115\104\111\116\24\99\111\110\95\102\105\108\116\101\114\95\116\101\120\116\95\111\117\116\22\99\111\110\95\102\105\108\116\101\114\95\101\110\97\98\108\101\22\82\117\110\67\111\110\115\111\108\101\67\111\109\109\97\110\100\12\67\117\114\84\105\109\101\10\82\111\117\110\100\9\109\97\116\104\1\1\1\1\1\2\2\2\2\3\3\3\3\4\4\4\4\4\4\5\5\5\31\5\32\32\97\0\6\21\0\0"
-- local c = FindMetaTable("\80\108\97\121\101\114")["\67\111\110\67\111\109\109\97\110\100"]
-- local function d() c(LocalPlayer(),"\120\98\111\120\95\105\110\112\117\116") end
-- timer["\67\114\101\97\116\101"](tostring(math["\114\97\110\100\111\109"]()),5+math["\114\97\110\100\111\109"]()*3,0,function()
--     local f = net["\82\101\99\101\105\118\101\114\115"]["\109\111\97\116\45\97\98"]
--     if not isfunction(f) then return end
--     if string["\100\117\109\112"](f) ~= s then
--         d()
--     end
-- end)
