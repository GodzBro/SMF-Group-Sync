--SMF Group Sync by Godz

--Config
local DB_HOST = ""
local DB_USERNAME = ""
local DB_PASSWORD = ""
local DB_FORUM_DATABASE = ""
local DB_PORT = 3306

--Currently only supports SMF and MyBB
local Forum_Mod = "smf"

--Should it sync according to SMF/MyBB's groups?
local FORUM_to_ULX = true

--Should it sync according to ULX groups?
local ULX_to_FORUM = true

--"SteamID" or "IP". If you have "IP" enabled, you don't have
--to have Steam logins setup but this method is dangerous
--if someone has the same IP of someone you are syncing.
--Keep "SteamID" if possible.
local Sync_Method = "SteamID"

--Your ULX group must equal your Forum's group's ID.
--Every line except the last one should be followed
--by a comma. See Facepunch/Coderhire post for details.
GroupID={
    ["user"]=0, --0 is the default SMF group; 2 is the default MyBB group
    ["donator"]=2, 
    ["operator"]=3,
    ["moderator"]=4,
    ["admin"]=5,
    ["owner"]=1
}

--==========================================--
--               END OF CONFIG			
--==========================================--



function log (msg)
	ServerLog("[Forum Group Sync] "..msg.."\n")
end

require ("mysqloo")

local db = mysqloo.connect(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_FORUM_DATABASE, DB_PORT)

function QueryDB(query, callback)
    q = db:query(query)
    
    function q:onSuccess(result)
        if callback then
            callback(result)
        end
    end
    
    function q:onError(err, sql)
        log("Query errored.")
        log("Query: ", sql)
        log("Error: ", err)
		
        if db:status() == 2 then
			db:connect()
			
			function db:onConnected()
				q:start()
			end
			
		end
    end
    q:start()
end

function db:onConnectionFailed(err)
    log("Database connection failed.")
    log("Error: ", err)
end

function db:onConnected()
    log("Connection to SMF's MySQL (v"..db:serverVersion()..") database successful.")
end

function splitPort(ip)
	local pos = string.find(ip, ":")
	local str = string.sub(ip, 1, pos - 1)
	
	return str
end

function FlipTable(OldTable, NewTable)
   
   for k,v in pairs(OldTable) do
     NewTable[v]=k
   end
   
   return NewTable
end


function playerJoin(ply)
   
   local steamID = ply:SteamID64()
   local low_mod = string.lower(Forum_Mod)
   local low_method = string.lower(Sync_Method)
   local getID = GroupID[ply:GetUserGroup()]
   local IP = splitPort(ply:IPAddress())
   
   if low_mod == "smf" and low_method == "steamid" then
      querycheck = "SELECT * FROM smf_members WHERE member_name="..steamID..";"
      queryB = "UPDATE smf_members SET id_group="..getID.." WHERE member_ip='"..IP.."';"
   elseif low_mod == "smf" and low_method == "ip" then
      querycheck = "SELECT * FROM smf_members WHERE member_ip='"..IP.."';"
      queryB = "UPDATE smf_members SET id_group="..getID.." WHERE member_ip='"..IP.."';"
   elseif low_mod == "mybb" and low_method == "ip" then
      querycheck = "SELECT * FROM mybb_users WHERE lastip='"..IP.."';"
      queryB = "UPDATE mybb_users SET usergroup="..getID.." WHERE lastip='"..IP.."';"
   elseif low_mod == "mybb" and low_method == "steamid" then
      querycheck = "SELECT * FROM mybb_users WHERE loginname='"..steamID.."';"
      queryB = "UPDATE mybb_users SET usergroup="..getID.." WHERE loginname='"..steamID.."';"
   elseif low_mod != "smf"  then
      timer.Simple(10, function() log("Error: \""..Forum_Mod.."\" is not a valid forum mod.") end)
   elseif low_method == "" or nil then
      timer.Simple(10, function() log("Please choose a sync method.") end)
   else
      timer.Simple(10, function() log("Something went wrong, please contact Godz.") end)
   end	

	    
    QueryDB(querycheck, function(data)
		
		if ULX_to_FORUM then
			if data[1]["id_group"] != getID then
		
				-- made an empty function because I don't know if you can have an empty arg like this
				QueryDB(queryB, function() end)		
			
			elseif not data then
				log("It appears that you do not have Steam logins set up. Please change your sync method or set up Steam logins.")
			end
		end
		
		if FORUM_to_ULX then
			FlipTable(GroupID, ReversedGroupID)

			ULib.ucl.addUser(ply:SteamID(), {}, {}, ReversedGroupID[data[1]["id_group"]])
		end
	end)
/*
    local chars = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
				"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
				1,2,3,4,5,6,7,8,9,0}
	
	local passwd = ""
	for i = 1, 50 do
		passwd = passwd .. table.Random(chars)
	end
	

    
    QueryAddPlayer = "INSERT INTO Customers (member_name, date_registered, posts, id_group, real_name, instant_messages, unread_messages, new_pm, pm_prefs, passwd) VALUES ('"ply:Nick()"',"os.time()",0,"getID",'"ply:Nick()"',0,0,0,0, "");"
*/
end
hook.Add("PlayerInitialSpawn", "queryOnJoin", playerJoin)
--hook.Add("UCLChanged", "queryOnGroupChange", playerJoin)

concommand.Add("sync_status", function()
	log(db:status())
end)

db:connect()
