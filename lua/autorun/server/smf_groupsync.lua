--SMF Group Sync by Godz

--Config
local DB_HOST = ""
local DB_USERNAME = ""
local DB_PASSWORD = ""
local DB_SMF_DATABASE = ""
local DB_PORT = 3306

--Currently only supports SMF
local Forum_Mod = "smf"

--Should it sync according to SMF's groups?
local SMF_to_ULX = true

--Should it sync according to ULX's groups?
local ULX_to_SMF = true

--"SteamID" or "IP". If you have "IP" enabled, you don't have
--to have Steam logins setup but this method is dangerous
--if someone has the same IP of someone you are syncing.
--Keep "SteamID" if possible.
local Sync_Method = "SteamID"

--Your ULX group must equal your SMF group's ID.
--See Facepunch/Coderhire post for details.
GroupID={
    ["user"]=0, --0 is the default SMF group
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
	ServerLog("[SMF Group Sync] "..msg.."\n")
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

function splitPort( ip )
	local pos = string.find( ip, ":" )
	local str = string.sub( ip, 1, pos - 1 )
	
	return str
end


if Forum_Mod == "smf" and Sync_Method = "SteamID" then
	querycheck = "SELECT * FROM smf_members WHERE member_name="..steamID..";"
	queryB = "UPDATE smf_members SET id_group="..getID.." WHERE member_ip='"..splitPort(ply:IPAddress()).."';"
elseif Forum_Mod == "smf" and Sync_Method == "IP" then
	querycheck = "SELECT * FROM smf_members WHERE member_ip='"ply:IPAddress()"'"
	queryB = "UPDATE smf_members SET id_group="..getID.." WHERE member_ip='"..splitPort(ply:IPAddress()).."';"
elseif Forum_Mod == "mybb" then
	timer.Simple(10, function() log("Error: MyBB is not supported yet. Talk with Godz if you would like to see this happen.") end)
elseif Forum_Mod != "smf" then 
	timer.Simple(10, function() log("Error: \""..Forum_Mod.."\" is not a valid forum mod.") end)
elseif Sync_Method == "" or nil then
	timer.Simple(10, function() log("Please choose a sync method.") end)
else
	timer.Simple(10, function() log("Something went wrong, please contact Godz.") end)
end

function FlipTable( table , NewTable )
	local NewTable = {}
	
	for k, v in next, table do
		local key = k
		local value = tostring(v)

		table.v = k
	end

	return NewTable
end


function playerJoin( ply )
	
   local steamID = ply:SteamID64()
   local getID = GroupID[ply:GetUserGroup()]
    
    QueryDB(querycheck, function(data)
		
		if ULX_to_SMF then
			if data[1]["id_group"] != getID then
		
				--made an empty function because I don't know if you can have an empty arg like this
				QueryDB( queryB, function() end )		
			
			end
		end
		
		if SMF_to_ULX then
			FlipTable(GroupID, ReversedGroupID)

			ULib.ucl.addUser(ply:SteamID(), {}, {}, ReversedGroupID[data[1]["id_group"]])
		end
    end)
    
end
hook.Add("PlayerInitialSpawn", "queryOnJoin", playerJoin)
--hook.Add("UCLChanged", "queryOnGroupChange", playerJoin)

concommand.Add( "sync_status", function()
	log(db:status())
end )

db:connect()
