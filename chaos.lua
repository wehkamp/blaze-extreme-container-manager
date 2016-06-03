/*
 * Main objective:
 * Defend your containers against the zombie horde. A new zombie will spawn
 * every 5 seconds. Killed containers are respawned withing that same interval.
 */

MESOSURL = "mesos.some.where:8080"

PrintMessage(HUD_PRINTTALK, "Welcome to Half-Life2: Container Shooter!")
PrintMessage(HUD_PRINTTALK, "    * WehkampLabs *")

teams = {}
teams["model"] = "npc_citizen"
teams["green"] = {}
teams["green"]["vector"] = {}
teams["green"]["vector"]["x"] = 500
teams["green"]["vector"]["y"] = 500
teams["red"] = {}
teams["red"]["vector"] = {}
teams["red"]["vector"]["x"] = -700
teams["red"]["vector"]["y"] = -500
teams["purple"] = {}
teams["purple"]["vector"] = {}
teams["purple"]["vector"]["x"] = -2200
teams["purple"]["vector"]["y"] = -400
teams["ebony"] = {}
teams["ebony"]["vector"] = {}
teams["ebony"]["vector"]["x"] = -2100
teams["ebony"]["vector"]["y"] = 500
teams["magenta"] = {}
teams["magenta"]["vector"] = {}
teams["magenta"]["vector"]["x"] = -1700
teams["magenta"]["vector"]["y"] = 1900
teams["orange"] = {}
teams["orange"]["vector"] = {}
teams["orange"]["vector"]["x"] = 1300
teams["orange"]["vector"]["y"] = 3000
teams["ivory"] = {}
teams["ivory"]["vector"] = {}
teams["ivory"]["vector"]["x"] = 0
teams["ivory"]["vector"]["y"] = -1500

/*
 * The main loop, that shouldn't be named Main().
 */
function Main()
    /*
     * Gets the list of running application from Marathon.
     */
    // TODO: rewrite this http.Fetch() too
    http.Fetch( "http://"..MESOSURL.."/v2/apps",
        function(body, len, headers, code)
            httpConnected(body, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )

    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end

    httpConnected = function(body, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply")
            return
        end

        for k, v in pairs(util.JSONToTable(body)) do
            for key, app in pairs(v) do
                print("[Mesos] service "..app['id'].." of team "..app['labels']['team'])
                local n = entitiesSpawned(app['id'])
                if n < app['instances'] then
                    // Spawns something per each container in this app
                    for i=n+1,app['instances'],1 do
                        blazeSpawn(app['id'], app['labels']['team'], app['labels']['type'])
                    end
                end
            end
        end
    end

    /*
     * Returns the count of all NPCs spawned for this service.
     */
    entitiesSpawned = function(service)
        if not service then
            return 10000000
        end
        return table.Count(ents.FindByName(service))
    end

    /*
     * Does the actual spawn of a NPC/entity.
     */
    blazeSpawn = function(what, team, type)
        if not teams[team] then
            return
        end
        local e = teams["model"]
        PrintMessage(HUD_PRINTTALK, "Spawning for service "..what)

        ent = ents.Create(e)
        ent:SetName(what)
        local x = teams[team]["vector"]["x"]
        local y = teams[team]["vector"]["y"]
        ent:SetPos(Vector(math.random(x-300,x+200),math.random(y-300,y+200),150))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()

        // not everyone gets a crowbar
        if math.random(1,10) == 1 then
            ent:Give("ai_weapon_crowbar")
        end

        // all your base are belong to team purple
        if team == "purple" then
            ent:Give("ai_weapon_rpg")
        end

        // everyone should hate zombies!
        for _, zombie in pairs(ents.FindByClass("npc_zombie")) do
            ent:AddRelationship("npc_zombie D_HT 99")
        end

        ent:NavSetWanderGoal(400, 8000)
        ent:SetMovementActivity(ACT_WALK)
        ent:SetSchedule(SCHED_FORCED_GO)
    end

    /*
     * Kills a container that belongs to some service.
     */
    killContainer = function(service)
        local url = "http://"..MESOSURL.."/v2/apps/"..service.."/tasks"
        local data =
        {
            url = url,
            method = "GET",
            success = function(code, body, headers)
                if code != 200 then
                    PrintMessage(HUD_PRINTTALK, "[ERROR] Tasklist error: "..service)
                    return
                end
                for k, v in pairs(util.JSONToTable(body)) do
                    for key, task in pairs(v) do
                        doKillContainer(service, task['id'])
                        // lame way to only process the first container here
                        break
                    end
                end
            end,
            failed = function(message)
                print("[ERROR] failed")
            end
        }
        HTTP(data)
    end

    /*
     * This sends the DELETE to Marathon.
     */
    doKillContainer = function(service, killme)
        local url = "http://"..MESOSURL.."/v2/apps/"..service.."/tasks/"..killme
        local data =
        {
            url = url,
            method = "DELETE",
            parameters = {},
            success = function(code, body, headers)
                if code != 200 then
                    print("[ERROR] failed to shoot container!")
                    return
                end
                PrintMessage(HUD_PRINTTALK, "Container down for "..service)
            end,
            failed = function(message)
                print("[ERROR] failed")
            end
        }
        HTTP(data)
    end

    /*
     * Spawns a killer
     */
    blazeSpawnKiller = function(what, team, type)
        local e = "npc_zombie"
        ent = ents.Create(e)
        ent:SetName("none")
        ent:SetPos(Vector(math.random(1,-2000), math.random(1,2000), 200))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()
        ent:NavSetWanderGoal(1000, 200)
        ent:SetMovementActivity(ACT_WALK)
        ent:SetSchedule(SCHED_FORCED_GO)
    end

    blazeSpawnKiller()
end

// Do things when a NPC dies or something
hook.Add("OnNPCKilled", "OnNPCKilled", function(npc, attacker, inflictor)
    local you = attacker:GetName()

    // Spawn some goods when someone dies
    local goodies = {
        "item_healthkit",
        "item_ammo_smg1",
        "item_ammo_ar2",
        "item_ammo_crossbow",
        "item_box_buckshot"
    }
    local goods = ents.Create(table.Random(goodies))
	goods:SetPos(npc:LocalToWorld(npc:OBBCenter()))
	goods:Spawn()

    // Actually kill something on Mesos here
    // Example value of `npc`:
    //   NPC [184][npc_kleiner]
    for npcid in string.gmatch(tostring(npc), "%[([%d]+)%]") do
        eid = npcid
    end
    service = tostring(Entity(eid):GetName())
    if service != "none" then
        killContainer(service)
    end

    // Stuff that happens when the player inflicts death goes here
    if you != "none" then
        local theplayer = 1
        local ply = Entity(theplayer)
        local wp = ply:GetActiveWeapon():GetClass()
        PrintMessage(HUD_PRINTTALK, you.." killed "..npc:GetName().." using "..wp)
    end
end)

// headshot!
hook.Add("ScaleNPCDamage", "ScaleNPCDamage", function(deadplayer, hitgroup, dmginfo)
    if (hitgroup == 0) then
        PrintMessage(HUD_PRINTTALK, "HEADSHOT!")
    end
end)

// main()
timer.Create("Main()", 5, 0, Main)
