--SMF Group Sync by Godz
--Config
local DB_HOST = ""
local DB_USERNAME = ""
local DB_PASSWORD = ""
local DB_FORUM_DATABASE = ""
local DB_PORT = 3306

local Forum_Mod = "smf" --currently only supports SMF

GroupID={
    ["user"]=0, -- 0 is the default group for SMF and 2 is the default for MyBB
    ["admin"]=12,
    ["moderator"]=13,
    ["owner"]=1,
    ["donator"]=15
}

--end of config

function log (msg)
	ServerLog(msg.."\n")
end

require ("mysqloo")

local dbconnected = false

local db = mysqloo.connect(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_FORUM_DATABASE, DB_PORT)

function QueryDB( query, callback )
    q = db:query(query)
    
    function q:onSuccess( result )
        if callback then
            callback(result)
        end
    end
    
    function q:onError(err, sql)
        log("[SMF Group Sync] SMF group sync query errored.")
        log("[SMF Group Sync] Query: ", sql)
        log("[SMF Group Sync] Error: ", err)
		
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
    log("[SMF Group Sync] SMF group sync database connection failed.")
    log("[SMF Group Sync] Error: ", err)
end

function db:onConnected()
    log("[SMF Group Sync] Group sync connected to SMF's MySQL (v"..db:serverVersion()..") database successfully.")
    dbconnected = true
end

function playerJoin( ply )
	
   local steamID = ply:SteamID64()
   local getID = GroupID[ply:GetUserGroup()]
   
   if Forum_Mod =="smf" then
   		Table_Prefix = "smf_"
   		querycheck = "SELECT * FROM "..Table_Prefix.."members WHERE member_name="..steamID..";"
   elseif Forum_Mod == "mybb" then
   		Table_Prefix = "mybb_"
   		querycheck = "SELECT * FROM "..Table_Prefix.."members WHERE member_name="..steamID..";"
   end
   
    local query = querycheck
    
    QueryDB(query, function(data)
		PrintTable(data)
        if data[1]["id_group"] != getID then
            local queryB = "UPDATE "..Table_Prefix.."members SET id_group="..getID.." WHERE member_name="..steamID..";"
			
			QueryDB(queryB, function() end)
        end
    end)
    
end
hook.Add("PlayerInitialSpawn", "queryOnJoin", playerJoin)
--hook.Add("UCLChanged", "queryOnGroupChange", playerJoin)

concommand.Add( "sync_status", function( ply, cmd, args, str )
	log(db:status())
end )

db:connect()
