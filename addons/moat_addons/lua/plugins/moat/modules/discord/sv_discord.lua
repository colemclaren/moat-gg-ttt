util.AddNetworkString("discord.OAuth")

discord = {}
discord.clientID = "430843529510649897"
discord.clientSecret = "RGv7dtTRQt0TJAeBuy4GmE6IMH2oM5aQ"
discord.botToken = "NDMyMjg2MjU3NTMyNjMzMDk5.DarFxg.0BQ-eCKMMHnAXv2iTDMu03wCrQw"
discord.botClientID = "432286257532633099"
discord.botClientSecret = "i696pb2jZgFGY5ZhJ_-CkO0qs86BPeb_"
discord.users = {}


local function AuthedGet(bearer,url,succ,fail)
    HTTP({
        method = "GET",
        url = "http://discordapp.com/api/v6" .. url,
        headers = {
            ["Authorization"] = "Bearer " .. bearer
        },
        
        success = function(status, body,headers)
            succ(status,body)
            
        end,
        failed = function(err)
            print("Failed api",err)
        end,
    })
end
util.AddNetworkString("AmIDiscord")

function discord_(db)
    net.Receive("AmIDiscord",function(l,ply)
        if ply.Discorded then return end
        ply.Discorded = true
        local sid = ply:SteamID64()
        local q = db:query("SELECT * FROM moat_discord WHERE steamid = '" .. sid .. "';")
        function q:onSuccess(d)
            if #d < 1 then
                net.Start("AmIDiscord")
                net.WriteBool(false)
                net.Send(ply)
            else
                net.Start("AmIDiscord")
                net.WriteBool(true)
                net.Send(ply)
            end
        end
        q:start()
    end)

    local q = db:query("CREATE TABLE IF NOT EXISTS `moat_discord` ( `steamid` varchar(255) NOT NULL, `oauth` TEXT NOT NULL, PRIMARY KEY (steamid) ) ENGINE=MyISAM DEFAULT CHARSET=latin1;")
    q:start()

    net.Receive("discord.OAuth",function(l,ply)
        if (ply.DiscordCool or 0) > CurTime() then return end
        ply.DiscordCool = CurTime() + 10
        local sid = ply:SteamID64()
        local oauth = net.ReadString()
        print("Received",sid,oauth)
        discord.users[sid] = {
            oauth = oauth
        }
        HTTP({
            method = "POST",
            url = "https://discordapp.com/api/v6/oauth2/token",
            parameters = {
                client_id = discord.botClientID,
                client_secret = discord.botClientSecret,
                code = oauth,
                grant_type = "authorization_code",
                redirect_uri = "http://localhost/"
            },

            success = function(s,body)
                print("Succ",s,body)
                if s == 200 then
                    body = util.JSONToTable(body)
                    discord.users[ply:SteamID64()].bearer = body.access_token
                    print("Got bearer token for " .. ply:Nick() .. ": " .. body.access_token)
                    local token = body.access_token
                    AuthedGet(token,"/users/@me",function(code,body)
                        if code == 200 then
                            body = util.JSONToTable(body)
                            discord.users[sid].user = body
                            print("Got user info for " .. ply:Nick() .. " :: " .. body.username .. "#" .. body.discriminator)
                            --/guilds/{guild.id}/members/{user.id}
                            local id = body.id
                            HTTP({
                                method = "PUT",
                                url = "https://discordapp.com/api/v6/guilds/256324969842081793/members/" .. body.id,
                                headers = {
                                    ["Authorization"] = "Bot " .. discord.botToken
                                },
                                type = "application/json",
                                body = util.TableToJSON({
                                    ["access_token"] = token
                                }),

                                success = function(s,body)
                                    local sid = ply:SteamID64()
                                    local q = db:query("SELECT * FROM moat_discord WHERE steamid = '" .. sid .. "';")
                                    function q:onSuccess(d)
                                        if #d < 1 then
                                            local b = db:query("INSERT INTO moat_discord (steamid,oauth) VALUES ('" .. sid .. "', '" .. db:escape(oauth) .. "');")
                                            b:start()
                                            if IsValid(ply) then
                                                net.Start("discord.OAuth")
                                                net.WriteEntity(ply)
                                                net.Broadcast()
                                            end
                                            if s == 201 then
                                                print(ply:Nick() .. " Joined discord ")
                                            elseif s == 204 then
                                                print(ply:Nick() .. " was already in the discord")
                                            end
                                            ply:m_GiveIC(3000)
                                        else
                                            ply:SendLua([[chat.AddText(Color(255,0,0),"You already got a reward for joining the discord!")]]);
                                        end
                                    end
                                    q:start()

                                end,
                                failed = print,
                            })
                        end
                    end)
                end
            end,
            failed = function(...)
                print("Failed",...)
            end,
        })
    end)
end

hook.Add("SQLConnected", "DiscordSQL", function(db)
	discord_(db)
end)