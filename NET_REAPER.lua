--[[
                          /$$                                                                   
                      | $$                                                                   
 /$$$$$$$   /$$$$$$  /$$$$$$       /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$ 
| $$__  $$ /$$__  $$|_  $$_/      /$$__  $$ /$$__  $$ |____  $$ /$$__  $$ /$$__  $$ /$$__  $$
| $$  \ $$| $$$$$$$$  | $$       | $$  \__/| $$$$$$$$  /$$$$$$$| $$  \ $$| $$$$$$$$| $$  \__/
| $$  | $$| $$_____/  | $$ /$$   | $$      | $$_____/ /$$__  $$| $$  | $$| $$_____/| $$      
| $$  | $$|  $$$$$$$  |  $$$$//$$| $$      |  $$$$$$$|  $$$$$$$| $$$$$$$/|  $$$$$$$| $$      
|__/  |__/ \_______/   \___/ |__/|__/       \_______/ \_______/| $$____/  \_______/|__/      
                                                               | $$                          
                                                               | $$                          
                                                               |__/                           
]]

--[[
Version 2.0a

Dev Note: Player list improvements have not been tested on a long-term period

[+] Improved Player List
[+] Improved Freemode Death
[+] Improved Kick From Vehicle
[-] Removed Spawn Player Vehicle
[-] Removed Host Addict
]]

-- Settings
VERSION = "2.0a"
REFRESH_TIME = 1000 -- Playerlist refresh time (ms)
IN_DEV = false -- Disables auto-updater and enables debug features
IS_CLOSING = false -- Signals loops to break when true

-- Auto Update
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    local auto_update_complete = nil util.toast("Installing auto-updater...", TOAST_ALL)
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
        function(result, headers, status_code)
            local function parse_auto_update_result(result, headers, status_code)
                local error_prefix = "Error downloading auto-updater: "
                if status_code ~= 200 then util.toast(error_prefix..status_code, TOAST_ALL) return false end
                if not result or result == "" then util.toast(error_prefix.."Found empty file.", TOAST_ALL) return false end
                filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                if file == nil then util.toast(error_prefix.."Could not open file for writing.", TOAST_ALL) return false end
                file:write(result) file:close() util.toast("Successfully installed auto-updater lib", TOAST_ALL) return true
            end
            auto_update_complete = parse_auto_update_result(result, headers, status_code)
        end, function() util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL) end)
    async_http.dispatch() local i = 1 while (auto_update_complete == nil and i < 40) do util.yield(250) i = i + 1 end
    if auto_update_complete == nil then error("Error downloading auto-updater lib. HTTP Request timeout") end
    auto_updater = require("auto-updater")
end
if auto_updater == true then error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again") end

if not IN_DEV then
    auto_updater.run_auto_update({
        source_url="https://raw.githubusercontent.com/SikkeDotExe/gwapdaddy/main/NET_REAPER.lua",
        script_relpath=SCRIPT_RELPATH,
        verify_file_begins_with="--",
        dependencies = {

        },
    })
end

-- Libraries
util.require_natives(1676318796)
require "lib.net.Intro"

-- My own implementation of the find function.
table.find = function(t, k)
    for next = 1, #t do
        if t[next] == k then
            return true
        end
    end
    return false
end

-- Core | This is where all the functions are located.
NET2 = {
    MENU = {
        Profiles = {},
        ToDisplay = 1,
        IgnoreHost = false,

        DOES_PROFILE_EXIST = function(parent, RID)
            local FoundProfile, ProfileIndex = false
            for next = 1, #NET2.MENU.Profiles do
                if NET2.MENU.Profiles[next] and NET2.MENU.Profiles[next].RID then -- fixed error 88?
                    if NET2.MENU.Profiles[next].RID == RID then
                        FoundProfile = true
                        ProfileIndex = next
                    end
                end
            end

            local FoundMenu, Menu = false
            local Commands = parent:getChildren()
            for c = 1, #Commands do
                local menu_name = menu.get_menu_name(Commands[c])
                local strings = string.split(menu_name, " [")
                if #strings > 0 and ProfileIndex then
                    local format = string.lower(strings[1])
                    if format == NET2.MENU.Profiles[ProfileIndex].Name then
                        FoundMenu = true
                        Menu = Commands[c]
                    end
                end
            end

            if FoundProfile and FoundMenu then
                return Menu, ProfileIndex
            end 
        end,

        CREATE_PROFILE = function(parent, player_id)
            local RID = players.get_rockstar_id(player_id)
            local TargetName = players.get_name(player_id)

            local profile_exists = NET2.MENU.DOES_PROFILE_EXIST(parent, RID)
            if profile_exists then return profile_exists end

            local idx = #NET2.MENU.Profiles + 1
            NET2.MENU.Profiles[idx] = {Name = string.lower(TargetName), RID = RID}

            local Menu = menu.list(parent, players.get_name_with_tags(player_id))
            local TROLLING_LIST = menu.list(Menu, "Trolling")
            menu.toggle_loop(TROLLING_LIST, "Kick From Vehicle", {}, "Blocked by most menus.", function() NET2.QUICK.EVENT.KICK_FROM_VEHICLE(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Spam Particles", {}, "Blocked by most menus.", function() NET2.PLAYER.PARTICLES(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Force Camera Forward", {}, "Blocked by most menus.", function() NET2.QUICK.EVENT.FORCE_CAMERA_FORWARD(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Freeze", {}, "Blocked by most menus.", function() NET2.QUICK.EVENT.FREEZE(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Emp", {}, "Blocked by most menus.", function() NET2.PLAYER.EMP(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Raygun", {}, "Blocked by most menus.", function() NET2.PLAYER.RAGDOLL(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Stun", {}, "Blocked by most menus.", function() NET2.PLAYER.STUN(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Object Spam", {}, "Blocked by most menus.", function() NET2.PLAYER.GLITCH(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Launch", {}, "Blocked by popular menus.", function() NET2.PLAYER.LAUNCH(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Stumble", {}, "Blocked by popular menus.", function() NET2.PLAYER.STUMBLE(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Glitch", {}, "Blocked by most menus.", function() NET2.QUICK.EVENT.GLITCH(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Explode", {}, "You will not be blamed in the killfeed.", function() NET2.QUICK.EXPLODE(player_id) end)
            menu.toggle_loop(TROLLING_LIST, "Kill", {}, "You will always be blamed.\nWorks for players in interior.", function() NET2.QUICK.KILL(player_id) end)
            menu.action(TROLLING_LIST, "Send Corrupt Invitation", {}, "Blocked by most menus.\nIf the player accepts they will be stuck in an infinite loading screen.", function() NET2.QUICK.EVENT.CORRUPT_INVITE(player_id) end)
            local NEUTRAL_LIST = menu.list(Menu, "Neutral")
            menu.toggle(NEUTRAL_LIST, "Spectate", {}, "", function(Enabled) menu.trigger_commands("spectate"..TargetName..(Enabled and " on" or " off")) end)
            menu.toggle_loop(NEUTRAL_LIST, "Ghost Player", {}, "", function() NET2.PLAYER.GHOST(player_id, true) end, function() NET2.PLAYER.GHOST(player_id, false) end)
            menu.toggle(NEUTRAL_LIST, "Fake Money Drop", {}, "", function(Enabled) menu.trigger_commands("fakemoneydrop"..TargetName..(Enabled and " on" or " off")) end)
            menu.toggle_loop(NEUTRAL_LIST, "Vanity Particles", {}, "", function() NET2.PLAYER.VANITY_PARTICLES(player_id) end)
            local FRIENDLY_LIST = menu.list(Menu, "Friendly")
            menu.toggle_loop(FRIENDLY_LIST, "Explosive Ammo", {}, "Works better if the player is close.", function() NET2.PLAYER.EXPLOSIVE_AMMO(player_id) end)
            menu.toggle_loop(FRIENDLY_LIST, "RP Drop", {}, "Will give rp until player is level 120.", function() NET2.QUICK.EVENT.GIVE_RP(player_id, 0) end)
            menu.toggle(FRIENDLY_LIST, "Money Drop", {}, "Limited money drop, must be close to player.", function(Enabled) menu.trigger_commands("figurines"..TargetName..(Enabled and " on" or " off")) menu.trigger_commands("ceopay"..TargetName..(Enabled and " on" or " off")) end)
            menu.action(FRIENDLY_LIST, "Give All Collectibles", {}, "Up to $300k.\nCan only be used once per player.", function() NET2.QUICK.GIVE_ALL_COLLECTIBLES(player_id) end)
            menu.action(FRIENDLY_LIST, "Gift Spawned Vehicle", {}, "Spawn fully tuned deathbike2 for best results.\nPlayer must have full garage.\nGifts the latest spawned car.", function() menu.trigger_commands("gift"..TargetName) end)
            menu.action(FRIENDLY_LIST, "Give Script Host", {}, "Reduces loading time.", function() NET2.QUICK.GIVE_SCRIPT_HOST(player_id) end)
            menu.action(FRIENDLY_LIST, "Fix Loading Screen", {"fix"}, "Useful when stuck in a loading screen.", function() NET2.QUICK.GIVE_SCRIPT_HOST(player_id) menu.trigger_commands("aptme"..TargetName) end)
            local TELEPORT_LIST = menu.list(Menu, "Teleport")
            menu.action(TELEPORT_LIST, "Teleport To Player", {}, "", function() NET2.FUNCTION.TELEPORT_TO(player_id) end)
            menu.action(TELEPORT_LIST, "Teleport Into Their Vehicle", {}, "", function() NET2.FUNCTION.TELEPORT_INTO_PLAYER_VEHICLE(player_id) end)
            menu.action(TELEPORT_LIST, "Teleport To Me", {}, "Blocked by most menus.\nPlayer must be in a vehicle.", function() NET2.PLAYER.TELEPORT_TO(player_id, NET2.UTIL.GET_PLAYER_COORDS(players.user())) end)
            menu.action(TELEPORT_LIST, "Teleport To My Waypoint", {}, "Blocked by most menus.\nPlayer must be in a vehicle.", function() NET2.PLAYER.TELEPORT_TO(player_id, NET2.UTIL.GET_BLIP_POSITION()) end)
            menu.action(TELEPORT_LIST, "Teleport To Casino", {}, "", function() menu.trigger_commands("casinotp"..TargetName) end)
            menu.toggle(Menu, "Timeout", {}, "", function(Enabled) menu.trigger_commands("timeout"..TargetName..(Enabled and " on" or " off")) end)
            menu.action(Menu, "Remove", {}, "Blocked by popular menus.", function() NET2.QUICK.KICK(player_id) end)
            menu.action(Menu, "Freemode Death", {}, "Blocked by most menus", function() NET2.QUICK.SCRIPTKICK(player_id) end)
            local CRASH_LIST = menu.list(Menu, "Crashes")
            menu.action(CRASH_LIST, "Express Crash", {}, "Blocked by popular menus.", function() NET2.QUICK.CRASH.EXPRESS(player_id) end)
            menu.action(CRASH_LIST, "Script Crash", {}, "Blocked by most menus.", function() NET2.QUICK.CRASH.SCRIPT(player_id) end)
            menu.action(CRASH_LIST, "Object Crash", {}, "Blocked by most menus.\nPlayers close to the target may be affected.", function() NET2.QUICK.CRASH.OBJECT(player_id) end)
            menu.action(CRASH_LIST, "Zoo Crash", {}, "Blocked by most menus.\nPlayers close to the target may be affected.", function() NET2.QUICK.CRASH.ZOO(player_id) end)
            menu.action(CRASH_LIST, "Lamp Crash", {}, "Blocked by most menus.\nPlayers close to the target may be affected.", function() NET2.QUICK.CRASH.LAMP(player_id) end)

            util.create_thread(function()
                repeat util.yield(REFRESH_TIME)
                until not players.exists(player_id)
                Menu:delete()
                NET2.MENU.Profiles[idx] = nil
                util.stop_thread()
            end)

            return Menu
        end,

        REFRESH_PROFILES = function(parent)
            local Players = players.list()
            for next = 1, #Players do
                local CurrentMenu, ProfileIndex = NET2.MENU.CREATE_PROFILE(parent, Players[next])

                if nomodders then
                    if players.is_marked_as_modder(Players[next]) then
                        if Players[next] ~= players.user() then
                            NET2.QUICK.KICK(Players[next])
                        end
                    end
                end

                if CurrentMenu then
                    -- Stats
                    local Is_Modder = players.is_marked_as_modder(Players[next])
                    local Is_Modded = NET2.UTIL.IS_PLAYER_STATS_MODDED(Players[next])
                    local Is_Griefing = NET2.UTIL.IS_PLAYER_FLAGGED(Players[next], "Attacking While Invulnerable")

                    local Args = ""
                    if Players[next] == players.user() then Args = " [SELF]"
                    elseif NET2.UTIL.IS_PLAYER_FLAGGED(Players[next], "2Take1 User") then Args = " [2TAKE1]"
                    elseif Is_Modded then Args = " [$MOD]" end

                    local visible = true
                    if NET2.MENU.ToDisplay == 2 then
                        if not Is_Modder and not Is_Modded and not Is_Griefing then visible = false end
                    elseif NET2.MENU.ToDisplay == 3 then
                        if Is_Modder or Is_Modded or Is_Griefing then visible = false end
                    elseif NET2.MENU.IgnoreHost then
                        if players.get_host() == Players[next] then visible = false end
                    end

                    local Country
                    local Region
                    local City

                    local Success, err = pcall(function()
                        Country = menu.ref_by_rel_path(menu.player_root(Players[next]), "Information>Connection>Country")
                        Region = menu.ref_by_rel_path(menu.player_root(Players[next]), "Information>Connection>Region")
                        City = menu.ref_by_rel_path(menu.player_root(Players[next]), "Information>Connection>City")
                    end)

                    if Success then
                        Country = Country.value ~= "" and tostring(Country.value) or ""
                        Region = Region.value ~= "" and tostring(Region.value)..", " or ""
                        City = City.value ~= "" and tostring(City.value)..", " or ""
                    else Country = "A" Region = "/" City = "N" end

                    if CurrentMenu:isValid() then
                         menu.set_help_text(CurrentMenu,
                        "Location: "..City..Region..Country
                        .."\nRank: "..tostring(players.get_rank(Players[next]))
                        .."\nMoney: $"..tostring(NET2.UTIL.FORMAT_NUMBER(players.get_money(Players[next])))
                        .."\nK/D: "..tostring(players.get_kd(Players[next]))
                        .."\nPing: "..tostring(NETWORK.NETWORK_GET_AVERAGE_PING(Players[next]))
                        .."\nInVehicle: "..tostring(NET2.UTIL.IS_PLAYER_IN_VEHICLE(Players[next]) and true or false)
                        )

                        menu.set_menu_name(CurrentMenu, players.get_name_with_tags(Players[next])..Args)
                        menu.set_visible(CurrentMenu, visible)
                    end
                end
            end

            menu.set_menu_name(PLAYER_COUNT, "Players ("..#Players..")")
        end,
    },

    QUICK = {
        BECOME_HOST = function()
            local Host = players.get_host()
            if Host == players.user() then
                util.toast("You are the host.")
            elseif players.is_marked_as_modder(Host) then
                util.toast("High risk of karma, please remove player manually if you think this is a mistake.")
            else
                NET2.QUICK.KICK(Host)
            end
        end,

        BECOME_SCRIPT_HOST = function()
            if players.get_script_host() == players.user() then
                return
            end

            if players.get_script_host() ~= players.user() then
                util.request_script_host("freemode")
            end
        end,

        GIVE_SCRIPT_HOST = function(player_id)
            NET2.QUICK.BECOME_SCRIPT_HOST()
            repeat util.yield() until players.get_script_host() == players.user()
            if players.exists(player_id) then
                util.give_script_host("freemode", player_id)
            end
        end,

        GIVE_ALL_COLLECTIBLES = function(player_id)
            for category = 0, 20 do
                for collectible = 0, 100 do
                    NET2.UTIL.FIRE_EVENT(968269233, player_id, {players.user(), category, collectible, 1, 1, 1})
                end
            end
        end,

        KILL = function(player_id)
            local DF_IsAccurate, DF_IgnorePedFlags, DF_SuppressImpactAudio, DF_IgnoreRemoteDistCheck = 1, 16, 4096, 524288
            local Type = nil
            if not players.is_in_interior(player_id) then
                Type = util.joaat("WEAPON_ASSAULTRIFLE_MK2")
            else
                Type = util.joaat("WEAPON_SNOWBALL")
            end
            NET2.UTIL.SHOOT_EVENT(player_id, Type, 500, DF_IsAccurate | DF_IgnorePedFlags | DF_SuppressImpactAudio | DF_IgnoreRemoteDistCheck)
        end,

        EXPLODE = function(player_id)
            NET2.UTIL.SPAWN_EXPLOSION(players.get_position(player_id), 1, true, false, false)
        end,

        KICK = function(player_id)
            local delay = 500
            local x = {"ban", "loveletterkick", "hostkick", "nonhostkick", "aids"}
            local y = function(s) menu.trigger_commands(s..""..players.get_name(player_id)) end
            local z = function(i) for n = i, #x do y(x[n]) util.yield(10) end end
            if players.get_host() == players.user() then y(x[1]) delay = 5
            elseif players.get_host() == player_id then z(3)
            else z(2) end
            util.yield(delay)
        end,

        SCRIPTKICK = function(player_id)
            NET2.QUICK.GIVE_SCRIPT_HOST(player_id)
            local handle = NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(player_id)
            local functions = {1450115979, 623462469, -2102799478, 1980857009, -2051197492, -1013606569, -1852117343, -353458099, -1713699293, -1604421397, -1544003568, -1101672680}
            local Random = math.random(-2147483647, 2147483647)
            -- Doesn't fire a detection on Stand.
            NET2.UTIL.FIRE_EVENT(1017995959, player_id, {27, 0})
            --S0
            NET2.UTIL.FIRE_EVENT(-1986344798, player_id, {Random, Random, 0, 0})
            for next = 1, #functions do
                NET2.UTIL.FIRE_EVENT(functions[next], player_id, {handle})
                NET2.UTIL.FIRE_EVENT(functions[next], player_id, {handle, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
            end
            -- Eviction Notice (S0)
            NET2.UTIL.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1, player_id, Random})
            NET2.UTIL.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1, Random, Random, Random, Random, Random, Random, Random, player_id, Random, Random, Random})
            NET2.UTIL.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1})
            --S1 - May not work () Tested w/ and w/o SH | Is Detected, Doesn't Kick
            NET2.UTIL.FIRE_EVENT(-901348601, player_id, {Random})
            --S2 - May not work () Tested w/ and w/o SH | Is Detected, Doesn't Kick
            NET2.UTIL.FIRE_EVENT(-445044249, player_id, {handle, players.user(), -1, -1})
            NET2.UTIL.FIRE_EVENT(446749111, player_id, {handle, Random, 0})
            --S3
            NET2.UTIL.FIRE_EVENT(-1638522928, player_id, {handle, players.user(), 0, 0, math.random(-1, 1), 0, 0, 0, 0, 0, 0, 0, 0, math.random(-1, 1), math.random(-1, 1)})
            NET2.UTIL.FIRE_EVENT(2079562891, player_id, {Random, 0, Random})
            NET2.UTIL.FIRE_EVENT(1214811719, player_id, {Random, 1, 1, 1, Random})
            NET2.UTIL.FIRE_EVENT(1504695802, player_id, {Random, Random})
            NET2.UTIL.FIRE_EVENT(1932558939, player_id, {Random, 0, Random})
            NET2.UTIL.FIRE_EVENT(-800312339, player_id, {Random, 0, Random})
            NET2.UTIL.FIRE_EVENT(921195243, player_id, {Random, Random, 0})
            NET2.UTIL.FIRE_EVENT(1925046697, player_id, {Random, Random, 1})
            NET2.UTIL.FIRE_EVENT(-69240130, player_id, {Random, 0, 0, Random})
            NET2.UTIL.FIRE_EVENT(1318264045, player_id, {Random, 0, 0, 0, Random, 0, 0})
            NET2.UTIL.FIRE_EVENT(1638329709, player_id, {Random, 0, Random, 0, 0})
            NET2.UTIL.FIRE_EVENT(-642704387, player_id, {Random, Random, 0, 0, 0, 0, 0, 0, 0, Random, 0, 0, 0})
            NET2.UTIL.FIRE_EVENT(-904539506, player_id, {Random, Random})
            NET2.UTIL.FIRE_EVENT(630191280, player_id, {Random, Random, Random, Random, 0, 0, Random, 0})
            NET2.UTIL.FIRE_EVENT(728200248, player_id, {Random, Random, Random})
            NET2.UTIL.FIRE_EVENT(-1091407522, player_id, {Random, 1, Random})
            --S4 - May not work () Tested w/ and w/o SH | Is Detected, Doesn't Kick
            NET2.UTIL.FIRE_EVENT(1269949700, player_id, {handle, 0, Random})
            NET2.UTIL.FIRE_EVENT(-1547064369, player_id, {Random, 0, Random})
            NET2.UTIL.FIRE_EVENT(-2122488865, player_id, {handle, 0, Random})
            NET2.UTIL.FIRE_EVENT(-2026172248, player_id, {handle, 0, 0, 0, 1})
            -- Mailbomb (S5) - Works
            NET2.UTIL.FIRE_EVENT(1450115979, player_id, {math.random(1, 256), math.random(1, 512), math.random(0, 1)})
            -- Orgasm (MS3) (MS8)
            NET2.UTIL.FIRE_EVENT(1450115979, player_id, {Random, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
            NET2.UTIL.FIRE_EVENT(-1986344798, player_id, {Random, Random, 0, 0})
        end,

        CRASH = {
            SERVER = {
                AIO = function() -- Ryze
                    local time = (util.current_time_millis() + 2000)
                    while time > util.current_time_millis() do
                        local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
                        for i = 1, 10 do
                            AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', pc.x, pc.y, pc.z, 'MP_MISSION_COUNTDOWN_SOUNDSET', 1, 10000, 0)
                        end
                        util.yield_once()
                    end
                end,

                MOONSTAR = function() -- Night
                    local user = players.user()
                    local user_ped = players.user_ped()
                    local pos = players.get_position(user)
                    local cspped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                    local TPpos = ENTITY.GET_ENTITY_COORDS(cspped, true)
                    local cargobob = NET2.UTIL.SPAWN_VEHICLE(0XFCFCB68B, TPpos, true)
                    local cargobobPos = ENTITY.GET_ENTITY_COORDS(cargobob, true)
                    local veh = NET2.UTIL.SPAWN_VEHICLE(0X187D938D, TPpos, true)
                    local vehPos = ENTITY.GET_ENTITY_COORDS(veh, true)
                    local newRope = PHYSICS.ADD_ROPE(TPpos.x, TPpos.y, TPpos.z, 0, 0, 10, 1, 1, 0, 1, 1, false, false, false, 1.0, false, 0)
                    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, veh, cargobobPos.x, cargobobPos.y, cargobobPos.z, vehPos.x, vehPos.y, vehPos.z, 2, false, false, 0, 0, "Center", "Center")
                    util.yield(80)
                    PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), 0xFBF7D21F)
                    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
                    TASK.TASK_PARACHUTE_TO_TARGET(user_ped, pos.x, pos.y, pos.z)
                    util.yield()
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
                    util.yield(250)
                    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
                    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
                    util.yield(1000)
                    ENTITY.SET_ENTITY_HEALTH(user_ped, 0)
                    NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x,pos.y,pos.z, 0, false, false, 0)
                    util.yield(2500)
                    entities.delete_by_handle(cargobob)
                    entities.delete_by_handle(veh)
                    PHYSICS.DELETE_CHILD_ROPE(newRope)
                end,

                ROPE = function() -- Night
                    local getEntityCoords = ENTITY.GET_ENTITY_COORDS
                    local getPlayerPed = PLAYER.GET_PLAYER_PED
                    local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                    local ppos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                    local p_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                    pos.x = pos.x+5
                    ppos.z = ppos.z+1
                    Utillitruck3 = entities.create_vehicle(2132890591, pos, 0)
                    Utillitruck3_pos = ENTITY.GET_ENTITY_COORDS(Utillitruck3)
                    kur = entities.create_ped(26, 2727244247, ppos, 0)
                    kur_pos = ENTITY.GET_ENTITY_COORDS(kur)
                    PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),0xE5022D03)
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                    util.yield(50)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()),p_pos.x,p_pos.y,p_pos.z,false,true,true)
                    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 0xFBAB5776, 1000, false)
                    TASK.TASK_PARACHUTE_TO_TARGET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()),-1087,-3012,13.94)
                    util.yield(500)
                    for next = 1, 2 do
                        ENTITY.SET_ENTITY_INVINCIBLE(kur, true)
                        newRope = PHYSICS.ADD_ROPE(pos.x, pos.y, pos.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true, "Center")
                        PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, Utillitruck3, kur, Utillitruck3_pos.x, Utillitruck3_pos.y, Utillitruck3_pos.z, kur_pos.x, kur_pos.y, kur_pos.z, 2, 0, 0, "Center", "Center") 
                        util.yield(100)
                    end
                    PHYSICS.ROPE_LOAD_TEXTURES()
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                    util.yield(1000)
                    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID())
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                    local hashes = {2132890591, 2727244247, 1663218586, -891462355}
                    local pc = getEntityCoords(getPlayerPed(players.user()))
                    local veh = VEHICLE.CREATE_VEHICLE(hashes[i], pc.x + 5, pc.y, pc.z, 0, true, true, false)
                    local ped = PED.CREATE_PED(26, hashes[2], pc.x, pc.y, pc.z + 1, 0, true, false)
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                    ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
                    ENTITY.SET_ENTITY_VISIBLE(ped, false, 0)
                    ENTITY.SET_ENTITY_VISIBLE(veh, false, 0)
                    local rope = PHYSICS.ADD_ROPE(pc.x + 5, pc.y, pc.z, 0, 0, 0, 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1, true, 0)
                    local vehc = getEntityCoords(veh); local pedc = getEntityCoords(ped)
                    PHYSICS.ATTACH_ENTITIES_TO_ROPE(rope, veh, ped, vehc.x, vehc.y, vehc.z, pedc.x, pedc.y, pedc.z, 2, 0, 0, "Center", "Center")
                    util.yield(1000)
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh); NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ped)
                    PHYSICS.DELETE_CHILD_ROPE(rope)
                    PHYSICS.ROPE_UNLOAD_TEXTURES()
                end,

                LAND = function() -- Night
                    NET2.FUNCTION.CHANGE_PLAYER_MODEL(0x9C9EFFD8)
                    local land_area = {
                        v3(1798.031,-2831.863,3.562),
                        v3(-245.300,-656.019,33.168),
                        v3(-2561.787,3175.436,32.820),
                        v3(58.667,7198.895,3.372),
                        v3(1279.582,3064.881,40.534),
                        v3(3003.555,5777.601,300.729),
                        v3(460.582,5572.078,781.179),
                        v3(3615.213,5024.245,11.396),
                        v3(3668.583,5645.834,11.537),
                        v3(2027.388,-1588.856,251.008),
                        v3(-1240.75,-587.97,27.25)
                    }
                    for i ,crashpos in pairs(land_area) do
                        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),0xE5022D03)
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped(players.user()))
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                        util.yield(30)
                        local crash_num = 2
                        pack_crash = util.create_thread(function()
                            while crash_num == 2 do
                                for set_para_packmodel = 0 ,50 do
                                    util.yield(100)
                                end
                            end
                        end, nil)
                        pos = crashpos
                        pos.z = pos.z + 0.22
                        local p_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(crashpos, pos.x, pos.y, pos.z)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()),p_pos.x,p_pos.y,p_pos.z,false,true,true)
                        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(players.user_ped(players.user()),0xFBAB5776, 1000, false)
                        TASK.TASK_PARACHUTE_TO_TARGET(players.user_ped(players.user()),-1087,-3012,13.94)
                        util.yield(600)
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped(players.user()))		
                        util.yield(1000)
                    end
                    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID())
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped(players.user()))
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(players.user_ped(players.user()),-1087,-3012,13.94)
                end,

                UMBRELLAV8 = function() -- Night
                    local models = {1381105889, 720581693, 1117917059, 4237751313, 2365747570, 2186304526}
                    for next = 1, #models do
                        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
                        object_hash = models[next]
                        STREAMING.REQUEST_MODEL(object_hash)
                        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
                            util.yield()
                        end
                        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),object_hash)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0,0,500, 0, 0, 1)
                        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
                        util.yield(1000)
                        for i = 0 , 2 do
                            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
                        end
                        util.yield(1000)
                        menu.trigger_commands("tpmazehelipad")
                    end
                end,

                UMBRELLAV1 = function() -- Night
                    local SelfPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
                    local PreviousPlayerPos = ENTITY.GET_ENTITY_COORDS(SelfPlayerPed, true)
                    for n = 0 , 3 do
                        local object_hash = util.joaat("prop_logpile_06b")
                        STREAMING.REQUEST_MODEL(object_hash)
                        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
                            util.yield()
                        end
                        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),object_hash)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, 0,0,500, false, true, true)
                        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(SelfPlayerPed, 0xFBAB5776, 1000, false)
                        util.yield(1000)
                        for i = 0 , 20 do
                            PED.FORCE_PED_TO_OPEN_PARACHUTE(SelfPlayerPed)
                        end
                        util.yield(1000)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z, false, true, true)
                    
                        local object_hash2 = util.joaat("prop_beach_parasol_03")
                        STREAMING.REQUEST_MODEL(object_hash2)
                        while not STREAMING.HAS_MODEL_LOADED(object_hash2) do
                            util.yield()
                        end
                        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(),object_hash2)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, 0,0,500, 0, 0, 1)
                        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(SelfPlayerPed, 0xFBAB5776, 1000, false)
                        util.yield(1000)
                        for i = 0 , 20 do
                            PED.FORCE_PED_TO_OPEN_PARACHUTE(SelfPlayerPed)
                        end
                        util.yield(1000)
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z, false, true, true)
                    end
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z, false, true, true)
                end,
            },

            EXPRESS = function(player_id) -- (NB)
                local DF_IgnoreRemoteDistCheck = 524288
                NET2.UTIL.SHOOT_EVENT(player_id, 0xFF956666, 1, DF_IgnoreRemoteDistCheck)
            end,

            SCRIPT = function(player_id) -- (S0) (S2) (S3) (S4)
                NET2.QUICK.GIVE_SCRIPT_HOST(player_id)

                for next = 1, 15 do
                    local Random = math.random(-2147483647, 2147483647)
                    -- (S3)
                    NET2.UTIL.FIRE_EVENT(1103127469, player_id, {4194304, 180, 3, Random, Random, 13, 10, Random, Random, Random, Random, Random, Random, Random, 0, 0, Random, Random, Random, Random, Random, 1, Random, Random})
                    NET2.UTIL.FIRE_EVENT(-375628860, player_id, {player_id, Random})
                    -- (S4)
                    -- Random?
                    NET2.UTIL.FIRE_EVENT(800157557, player_id, {134217728, 385726943, Random})
                    -- (S2)
                    NET2.UTIL.FIRE_EVENT(2067191610, player_id, {0, 0, -12988, -99097, 0})
                    NET2.UTIL.FIRE_EVENT(323285304, player_id, {0, 0, -12988, -99097, 0})
                    NET2.UTIL.FIRE_EVENT(495813132, player_id, {0, 0, -12988, -99097, 0})
                    -- (S0)
                    NET2.UTIL.FIRE_EVENT(323285304, player_id, {Random, 64, Random, 14299, 40016, 11434, 4595, 25992})
                end
            end,

            OBJECT = function(player_id) -- (XF)
                CRASH_OBJECT = {
                    "proc_brittlebush_01", "proc_dryplantsgrass_01", "proc_dryplantsgrass_02", "proc_grasses01",
                    "prop_dryweed_002_a", "prop_fernba", "prop_fernbb", "prop_weed_001_aa", "prop_weed_002_ba",
                    "urbandryfrnds_01", "urbangrnfrnds_01", "urbangrngrass_01", "urbanweeds01", "urbanweeds01_l1",
                    "urbanweeds02", "v_proc2_temp", "prop_dandy_b", "prop_pizza_box_03", "proc_meadowmix_01",
                    "proc_grassplantmix_02", "h4_prop_bush_mang_ad", "h4_prop_bush_seagrape_low_01", "prop_saplin_002_b",
                    "proc_leafyplant_01", "prop_saplin_002_c", "proc_sml_reeds_01b", "prop_grass_dry_02",
                    "proc_sml_reeds_01c", "prop_grass_dry_03", "prop_grass_ca", "h4_prop_grass_med_01",
                    "h4_prop_bush_fern_tall_cc", "h4_prop_bush_ear_aa", "h4_prop_bush_fern_low_01", "proc_lizardtail_01",
                    "proc_drygrassfronds01", "prop_grass_da", "prop_small_bushyba", "urbandrygrass_01",
                    "proc_drygrasses01", "h4_prop_bush_ear_ab", "proc_dry_plants_01", "proc_desert_sage_01",
                    "prop_saplin_001_c", "proc_drygrasses01b", "h4_prop_weed_groundcover_01", "proc_grasses01b",
                    "prop_saplin_001_b", "proc_lupins_01", "proc_grassdandelion01", "h4_prop_bush_mang_low_ab",
                    "h4_prop_grass_tropical_lush_01", "proc_indian_pbrush_01", "proc_stones_02", "h4_prop_grass_wiregrass_01",
                    "proc_sml_reeds_01", "proc_leafybush_01", "h4_prop_bush_buddleia_low_01", "proc_stones_03",
                    "proc_grassplantmix_01", "h4_prop_bush_mang_low_aa", "proc_meadowpoppy_01", "prop_grass_001_a",
                    "proc_forest_ivy_01", "proc_stones_04", "prop_tall_drygrass_aa", "prop_thindesertfiller_aa",
                }
                for next = 1, #CRASH_OBJECT do
                    if players.exists(player_id) then
                        Current_Object = NET2.UTIL.SPAWN_OBJECT(util.joaat(CRASH_OBJECT[next]), players.get_position(player_id))
                        util.yield(10)
                        entities.delete_by_handle(Current_Object)
                    else
                        break
                    end
                end
            end,

            ZOO = function(player_id) -- (X9)
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))

                local zoo = {}
                local models = {1794449327, -1011537562, -541762431}

                -- Preheat
                for next = 1, #models do
                    NET2.UTIL.REQUEST_MODEL(models[next], function()
                        zoo[next] = entities.create_ped(28, models[next], pos, 0)
                    end)
                end

                -- Crash
                for animal = 1, #zoo do
                    WEAPON.GIVE_WEAPON_TO_PED(zoo[animal], -1813897027, 1, true, true)
                    TASK.TASK_THROW_PROJECTILE(zoo[animal], pos.x, pos.y, pos.z, 0, 0)
                    ENTITY.FREEZE_ENTITY_POSITION(zoo[animal], true)
                    ENTITY.SET_ENTITY_VISIBLE(zoo[animal], false, 0)
                end

                -- Cleanup
                util.yield(2500)
                for animal = 1, #zoo do
                    entities.delete_by_handle(zoo[animal])
                end
            end,

            LAMP = function(player_id) -- (XJ)
                local model = util.joaat("prop_fragtest_cnst_04")
                NET2.UTIL.REQUEST_MODEL(model, function()
                    local object = entities.create_object(model, ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                    OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    util.yield(1500)
                    entities.delete_by_handle(object)
                end)
            end,
        },

        EVENT = {
            KICK_FROM_VEHICLE = function(player_id)
                NET2.UTIL.FIRE_EVENT(-503325966, player_id, {NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(player_id), 0, 0, 0, 0, 0, 0, 0})
            end,

            GLITCH = function(player_id)
                if players.is_in_interior(player_id) then
                    NET2.UTIL.FIRE_EVENT(-1338917610, player_id, {player_id, player_id, player_id, math.random(-2147483647, 2147483647), player_id})
                else
                    local handle = NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(player_id)
                    NET2.UTIL.FIRE_EVENT(-1604421397, player_id, {players.user(), 1, 4, handle, handle, handle, handle, 1, 1})
                    --NET.FUNCTION.FIRE_EVENT(891653640, player_id, {math.random(1, 32), 32, handle, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                end
            end,

            CORRUPT_INVITE = function(player_id)
                NET2.UTIL.FIRE_EVENT(996099702, player_id, {player_id, math.random(1, 6)})
            end,

            FORCE_CAMERA_FORWARD = function(player_id)
                NET2.UTIL.FIRE_EVENT(800157557, player_id, {player_id, 225624744, math.random(0, 9999)})
            end,

            GIVE_RP = function(player_id, delay)
                local GIVE_COLLECTIBLE = function(player_id, i)
                    if players.get_rank(player_id) >= 120 then return end
                    NET2.UTIL.FIRE_EVENT(968269233, player_id, {players.user(), 4, i, 1, 1, 1})
                end
    
                if not delay then delay = 0 end
    
                if delay == 0 then
                    for i = 20, 24 do
                        GIVE_COLLECTIBLE(player_id, i)
                    end
                elseif delay == 5 then
                    GIVE_COLLECTIBLE(player_id, math.random(20, 24)) -- limiting the amount of script events sent to prevent a fatal error
                else
                    for i = 20, 24 do
                        GIVE_COLLECTIBLE(player_id, i)
                    end
                    util.yield(delay)
                end
            end,

            FREEZE = function(player_id)
                NET2.UTIL.FIRE_EVENT(-1253241415, player_id, {1, 0, 1, 0})
            end,
        },
    },

    UTIL = {
        REQUEST_MODEL = function(hash, callback)
            local result
            local model_hash = hash
            STREAMING.REQUEST_MODEL(model_hash)
            while (not STREAMING.HAS_MODEL_LOADED(model_hash)) do util.yield() end
            if callback then result = callback() end
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model_hash)
            return result
        end,

        --https://github.com/DurtyFree/gta-v-data-dumps/blob/master/ObjectList.ini
        SPAWN_OBJECT = function(model, position, invisible, dynamic)
            local spawned = NET2.UTIL.REQUEST_MODEL(model, function() return OBJECT.CREATE_OBJECT(model, position.x, position.y, position.z, true, true, dynamic) end)
            ENTITY.SET_ENTITY_VISIBLE(spawned, not invisible)
            ENTITY.FREEZE_ENTITY_POSITION(spawned, not dynamic)
            return spawned
        end,

        --https://github.com/DurtyFree/gta-v-data-dumps/blob/master/peds.json
        SPAWN_PED = function(model, position, invincible, invisible, pedtype)
            local spawned = NET2.UTIL.REQUEST_MODEL(model, function() return PED.CREATE_PED(pedtype or 26, model, position.x, position.y, position.z, 0, true, true) end)
            ENTITY.SET_ENTITY_INVINCIBLE(spawned, invincible)
            ENTITY.SET_ENTITY_VISIBLE(spawned, not invisible)
            return spawned
        end,

        --https://github.com/DurtyFree/gta-v-data-dumps/blob/master/vehicles.json
        SPAWN_VEHICLE = function(model, position, invincible, invisible)
            local spawned = NET2.UTIL.REQUEST_MODEL(model, function() return VEHICLE.CREATE_VEHICLE(model, position.x, position.y, position.z, 0, true, true, false) end)
            ENTITY.SET_ENTITY_INVINCIBLE(spawned, invincible)
            ENTITY.SET_ENTITY_VISIBLE(spawned, not invisible)
            return spawned
        end,

        --https://github.com/DurtyFree/gta-v-data-dumps/blob/master/particleEffectsCompact.json
        SPAWN_PTFX = function(fxasset, asset, position, scale)
            STREAMING.REQUEST_NAMED_PTFX_ASSET(fxasset)
            while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(fxasset) do util.yield() end
            GRAPHICS.USE_PARTICLE_FX_ASSET(fxasset)
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(asset, position.x, position.y, position.z, 0, 0, 0, 2.5, false, false, false)
            GRAPHICS.REMOVE_PARTICLE_FX(fxasset)
        end,

        SPAWN_EXPLOSION = function(position, type, audible, invisible, nodamage)
            if position then
                FIRE.ADD_EXPLOSION(position.x, position.y, position.z, type or 1, 100, audible, invisible, 0, nodamage)
            end
        end,

        ATTACH_ENTITIES = function(object1, object2, collision, isPed, position, rotation)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                object1, object2, 0,
                position and position.x or 0,
                position and position.y or 0,
                position and position.z or 0,
                rotation and rotation.x or 0,
                rotation and rotation.y or 0,
                rotation and rotation.z or 0, 0, 0,
                collision or false,
                isPed or false, 0, true
            )
        end,

        FIRE_EVENT = function(first_arg, receiver, args)
            table.insert(args, 1, first_arg)
            util.trigger_script_event(1 << receiver, args)
        end,

        SHOOT_EVENT = function(player_id, weapon, damage, flags)
            local CWeaponDamageEventTrigger = memory.rip(memory.scan("E8 ? ? ? ? 44 8B 65 80 41 FF C7") + 1)
            local pPed = entities.handle_to_pointer(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
            util.call_foreign_function(CWeaponDamageEventTrigger, entities.handle_to_pointer(players.user_ped()), pPed, pPed + 0x90, 0, 1, weapon, damage, 0, 0, flags, 0, 0, 0, 0, 0, 0, 0, 0.0)
        end,

        -- ... is for additional arguments. Example use case; Backstab All
        FIRE_FOR_PLAYERS = function(selection, ignorehost, ignoremods, callback, ...)
            local Players = NET2.UTIL.GET_PLAYERS(selection, ignorehost, ignoremods)
        
            for next = 1, #Players do
                if players.exists(Players[next]) then
                    callback(Players[next], ...)
                end
        
                util.yield(5)
            end
        end,

        IS_PLAYER_STATS_MODDED = function(player_id)
            local Likelyness = 0
            local Threshold = 3
            local Modded_Ranks = {666, 777, 808, 888, 999, 696, 669, 6969, 420, 1337}
            local Limit = 2500
            local Limit2 = 5000

            local Player_Rank = players.get_rank(player_id)
            local Player_Money = players.get_money(player_id)
            local Player_KD, Player_Kills = players.get_kd(player_id), players.get_kills(player_id)

            for next = 1, #Modded_Ranks do
                if Player_Rank == Modded_Ranks[next] then
                    Likelyness = Likelyness + 2
                    break
                end
            end

            if Player_Rank > Limit then
                Likelyness = Likelyness + 2
            end

            if Player_Rank > Limit2 then
                Likelyness = Likelyness + 3
            end

            if Player_Money > 500000000 then
                Likelyness = Likelyness + 3
            elseif Player_Money > 100000000 then
                Likelyness = Likelyness + 2
            elseif Player_Money > 50000000 then
                Likelyness = Likelyness + 1
            end

            if Player_KD >= 2 and Player_KD < 4 then
                Likelyness = Likelyness + 1
            elseif Player_KD > 4 and Player_Kills > 100 then
                Likelyness = Likelyness + 3
            elseif Player_KD < 0 then
                Likelyness = Likelyness + 3
            end

            if Likelyness >= Threshold then
                return true
            end

            return false
        end,

        IS_PLAYER_READY = function(player_id, assert_playing, assert_done_transition)
            if not NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then return false end
            if assert_playing and not PLAYER.IS_PLAYER_PLAYING(player_id) then return false end
            if assert_done_transition then
                if player_id == memory.read_int(memory.script_global(2672741 + 3)) then
                    return memory.read_int(memory.script_global(2672741 + 2)) ~= 0
                elseif memory.read_int(memory.script_global(2657921 + 1 + (player_id * 463))) ~= 4 then
                    return false
                end
            end
            return true
        end,

        IS_PLAYER_FLAGGED = function(player_id, detection)
            if players.exists(player_id) and menu.player_root(player_id):isValid() then
                for i, cmd in pairs(menu.player_root(player_id):getChildren()) do
                    if cmd:getType() == COMMAND_LIST_CUSTOM_SPECIAL_MEANING and cmd:refByRelPath(detection):isValid() and players.exists(player_id) then
                        return true
                    end
                end
            end
            return false
        end,

        IS_PLAYER_IN_VEHICLE = function(player_id)
            local Ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            if PED.IS_PED_IN_ANY_VEHICLE(Ped) then
                return PED.GET_VEHICLE_PED_IS_USING(Ped)
            end
            return false
        end,
        
        GET_PLAYERS = function(selection, ignorehost, ignoremods)
            local Table = {}
            local Table_SANITIZED = {}

            if selection == 1 then
                Table = players.list(false)
            end
        
            if selection == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) or NET2.UTIL.IS_PLAYER_FLAGGED(Players[next], "Attacking While Invulnerable") or NET2.UTIL.IS_PLAYER_STATS_MODDED(Players[next]) then
                        table.insert(Table, Players[next])
                    end
                end
            end
        
            --if selection == 3 then
                --Table = players.list(false, false)
            --end
        
            if selection == 3 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) and not NET2.UTIL.IS_PLAYER_FLAGGED(Players[next], "Attacking While Invulnerable") and not NET2.UTIL.IS_PLAYER_STATS_MODDED(Players[next]) then
                        table.insert(Table, Players[next])
                    end
                end
            end
        
            for next = 1, #Table do
                if players.exists(Table[next]) then
                    if ignorehost and players.get_host() == Table[next] then
                    else
                        table.insert(Table_SANITIZED, Table[next])
                    end
                end
            end

            return Table_SANITIZED
        end,

        GET_BLIP_POSITION = function()
            local BlipCoords = HUD.GET_BLIP_INFO_ID_COORD(HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID()))
            local ground = false
            repeat ground, BlipCoords.z = util.get_ground_z(BlipCoords.x, BlipCoords.y) util.yield() until ground

            return BlipCoords
        end,

        GET_SHOT_COORDS = function(player_id)
            local impact = v3.new()
            WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id), memory.addrof(impact))
            if impact.x ~= 0 and impact.y ~= 0 and impact.z ~= 0 then
                return impact
            end
            return nil
        end,

        GET_PLAYER_PED = function(player_id)
            return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        end,

        GET_PLAYER_COORDS = function(player_id)
            return ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
        end,

        SET_PLAYER_MODEL = function(model)
            NET2.FUNCTION.REQUEST_MODEL(model, function() PLAYER.SET_PLAYER_MODEL(model) end)
        end,

        FORMAT_NUMBER = function(number)
            local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
            int = int:reverse():gsub("(%d%d%d)", "%1,")
            return minus .. int:reverse():gsub("^,", "") .. fraction
        end,
    },

    PLAYER = {
        --[[ Backup function since we have an event which is better.
        KICK_FROM_VEHICLE = function(player_id)
            local Ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local Vehicle = PED.GET_VEHICLE_PED_IS_USING(Ped)
            VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(Vehicle, players.user_ped(), 0)
            local Timeout = 0
            repeat
                util.yield(100)
                Timeout = Timeout + 1
            until not PED.IS_PED_IN_ANY_VEHICLE(Ped) or Timeout == 50
            VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(Vehicle, Ped, 0)
        end,
        ]]
        SMOKESCREEN = function(player_id)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_as_trans")
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_as_trans")
            if ptfx == nil or not GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(ptfx) then
                ptfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY("scr_as_trans_smoke", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, false, false, false, 0, 0, 0, 255)
            end
        end,

        PARTICLES = function(player_id)
            NET2.UTIL.SPAWN_PTFX("scr_rcbarry2", "scr_exp_clown", ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)), 1)
        end,

        STUMBLE = function(player_id)
            local Vents = {}
            local mdl = util.joaat("prop_roofvent_06a")
            local pos = players.get_position(player_id)
            pos.z = pos.z - 2.4
            util.request_model(mdl)
            local temp_v3 = v3.new(0, 0, 0)
            local middleVent = entities.create_object(mdl, v3(pos.x, pos.y, pos.z))
            ENTITY.SET_ENTITY_VISIBLE(middleVent, false)
            for i = 1, 4 do
                local angle = (i / 4) * 360
                temp_v3.z = angle
                local obj_pos = temp_v3:toDir()
                obj_pos:mul(1.25)
                obj_pos:add(pos)
                Vents[i] = entities.create_object(mdl, obj_pos)
                ENTITY.SET_ENTITY_VISIBLE(Vents[i], false)
            end
            util.yield(500)
            entities.delete(middleVent)
            for i, obj in pairs(Vents) do
                entities.delete(obj)
            end
        end,

        LAUNCH = function(player_id)
            local muleMdl = util.joaat("mule5")
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local pos = players.get_position(player_id)
            util.request_model(muleMdl)
                        
            veh = entities.create_vehicle(muleMdl, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 1.0, -3.0), ENTITY.GET_ENTITY_HEADING(ped))
            entities.set_can_migrate(veh, false)
            ENTITY.SET_ENTITY_VISIBLE(veh, false)
            util.yield(500)
            ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(2500)
            entities.delete(veh)
            repeat
                util.yield()
            until ENTITY.GET_ENTITY_SPEED(ped) < 30.0

            if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then entities.delete(veh) end
        end,

        VANITY_PARTICLES = function(player_id, index)
            local PTFX = {"hacklol", "scr_sum2_hal_hunted_respawn", "scr_sum2_hal_rider_weak_blue", "scr_sum2_hal_rider_weak_green", "scr_sum2_hal_rider_weak_orange", "scr_sum2_hal_rider_weak_greyblack"}
            local player_pos = players.get_position(player_id)
            local ptfx = ((index == nil or index == 1) and PTFX[math.random(1, #PTFX)]) or PTFX[index]
            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sum2_hal")
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sum2_hal")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfx, player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            util.yield(200)
        end,

        STUN = function(player_id)
            local DF_IsAccurate, DF_IgnorePedFlags, DF_SuppressImpactAudio, DF_IgnoreRemoteDistCheck = 1, 16, 4096, 524288
            NET2.UTIL.SHOOT_EVENT(player_id, util.joaat("weapon_stungun_mp"), 0, DF_IsAccurate | DF_IgnorePedFlags | DF_SuppressImpactAudio | DF_IgnoreRemoteDistCheck)
        end,

        TELEPORT_TO = function(player_id, position)
            local Ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            if not PED.IS_PED_IN_ANY_VEHICLE(Ped) then
                util.toast("Player must be in a vehicle. OR You can use Stand's Teleport.")
            else -- THIS WORKS | Repeat until ped position = position?
                local TpVehicle = PED.GET_VEHICLE_PED_IS_USING(Ped)
                for next = 1, 10 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(TpVehicle)
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(TpVehicle, position.x, position.y, position.z, false, false, false)
                    util.yield(100)
                end
                entities.delete_by_handle(TpVehicle)
            end
        end,

        EMP = function(player_id)
            NET2.UTIL.SPAWN_EXPLOSION(players.get_position(player_id), 65, true, false, true)
        end,

        RAGDOLL = function(player_id)
            NET2.UTIL.SPAWN_EXPLOSION(players.get_position(player_id), 70, true, false, true)
        end,

        GLITCH = function(player_id)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
            if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) > 1000.0 and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
                return
            end
            local glitch_hash = util.joaat("prop_ld_ferris_wheel")
            local poopy_butt = util.joaat("rallytruck")
            util.request_model(glitch_hash)
            util.request_model(poopy_butt)
            local stupid_object = entities.create_object(glitch_hash, pos)
            local glitch_vehicle = entities.create_vehicle(poopy_butt, pos, 0)
            ENTITY.SET_ENTITY_VISIBLE(stupid_object, false)
            ENTITY.SET_ENTITY_VISIBLE(glitch_vehicle, false)
            ENTITY.SET_ENTITY_INVINCIBLE(stupid_object, true)
            ENTITY.SET_ENTITY_COLLISION(stupid_object, true, true)
            ENTITY.APPLY_FORCE_TO_ENTITY(glitch_vehicle, 1, 0.0, 10, 10, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(10)
            entities.delete_by_handle(stupid_object)
            entities.delete_by_handle(glitch_vehicle)
            util.yield(10)
        end,

        GHOST = function(player_id, enabled)
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(player_id, enabled)
        end,

        EXPLOSIVE_AMMO = function(player_id)
            NET2.UTIL.SPAWN_EXPLOSION(NET2.UTIL.GET_SHOT_COORDS(player_id), 1, true, false, false)
        end,
    },

    FUNCTION = {
        RESET_ANIMATION = function()
            if TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 56) then
                PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
            end
        end,

        EXPAND_ALL_HITBOXES = function()
            local BONE = { 31086, 24816, 40269, 45509, 0, 51826, 5827 }
            for i, player_id in pairs(players.list_except()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local pPed = entities.handle_to_pointer(ped)
                local pedPtr = entities.handle_to_pointer(players.user_ped())
                local wpn = WEAPON.GET_SELECTED_PED_WEAPON(players.user_ped())
                local dmg = WEAPON.GET_WEAPON_DAMAGE(wpn, 0)
                if PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(players.user(), ped) and PED.IS_PED_SHOOTING(players.user_ped()) and not NETWORK.IS_ENTITY_A_GHOST(ped) then
                    boneIndex = BONE[math.random(#BONE)]
                    local boneCoords = PED.GET_PED_BONE_COORDS(ped, boneIndex, 0.0, 0.0, 0.0)
                    NET2.UTIL.SHOOT_EVENT(player_id, wpn, dmg, 1 << 0 | 1 << 9 | 1 << 19)
                end
            end
        end,

        LOCK_ONTO_PLAYERS = function()
            for i, player_id in pairs(players.list_except(true)) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                PLAYER.ADD_PLAYER_TARGETABLE_ENTITY(players.user(), ped)
                ENTITY.SET_ENTITY_IS_TARGET_PRIORITY(ped, false, 400.0)    
            end
        end,

        STOP_LOCKING_ONTO_PLAYERS = function()
            for i, player_id in pairs(players.list_except(true)) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY(players.user(), ped)
            end
        end,

        TOGGLE_RADIO = function()
            if radio == nil then radio = 1 end
            local RADIO = {"RADIO_11_TALK_02", "RADIO_12_REGGAE", "RADIO_13_JAZZ", "RADIO_14_DANCE_02", "RADIO_15_MOTOWN", "RADIO_20_THELAB", "RADIO_16_SILVERLAKE", "RADIO_17_FUNK", "RADIO_18_90S_ROCK", "RADIO_21_DLC_XM17", "RADIO_22_DLC_BATTLE_MIX1_RADIO", "RADIO_23_DLC_XM19_RADIO", "RADIO_19_USER", "RADIO_01_CLASS_ROCK", "RADIO_02_POP", "RADIO_03_HIPHOP_NEW", "RADIO_04_PUNK", "RADIO_05_TALK_01", "RADIO_06_COUNTRY", "RADIO_07_DANCE_01", "RADIO_08_MEXICAN", "RADIO_09_HIPHOP_OLD", "RADIO_36_AUDIOPLAYER", "RADIO_35_DLC_HEI4_MLR", "RADIO_34_DLC_HEI4_KULT", "RADIO_27_DLC_PRHEI4"}
            local ped = players.user_ped()
            if partybus == nil then
                local offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.5)
                local hash = util.joaat("pbus2")
                util.request_model(hash)
                partybus = entities.create_vehicle(hash, offset, 0)
                entities.set_can_migrate(partybus, false)
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(partybus, false, false)
                ENTITY.SET_ENTITY_INVINCIBLE(partybus, true)
                ENTITY.FREEZE_ENTITY_POSITION(partybus, true)
                ENTITY.SET_ENTITY_VISIBLE(partybus, false, 0)
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(partybus, true, true)
                local ped_hash = util.joaat("a_m_y_acult_02")
                util.request_model(ped_hash)
                local driver = entities.create_ped(1, ped_hash, offset, 0)
                PED.SET_PED_INTO_VEHICLE(driver, partybus, -1)
                VEHICLE.SET_VEHICLE_ENGINE_ON(partybus, true, true, false)
                VEHICLE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(partybus, true)
                util.yield(500)
                AUDIO.SET_VEH_RADIO_STATION(partybus, RADIO[radio])
                util.yield(500)
                TASK.TASK_LEAVE_VEHICLE(driver, partybus, 16)
                entities.delete(driver)
            else
                local offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.5)
                ENTITY.SET_ENTITY_COORDS(partybus, offset.x, offset.y, offset.z, false, false, false, false)
                AUDIO.SET_VEH_RADIO_STATION(partybus, RADIO[radio])
                entities.request_control(partybus)
            end
        end,

        STOP_RADIO = function()
            if partybus ~= nil then entities.delete_by_handle(partybus) partybus = nil end
        end,

        SUPER_RADAR = function(Enabled)
            radar = Enabled
            if Enabled then
                util.create_thread(function()
                    repeat HUD.SET_RADAR_ZOOM(1400) util.yield(100) until not radar
                    HUD.SET_RADAR_ZOOM(0)
                    util.stop_thread()
                end)
            end
        end,

        LASER_SHOW = function()
            local ped = players.user_ped()
            local weaponHash = util.joaat("weapon_heavysniper_mk2")
            local dictionary = "weap_xs_weapons"
            local ptfx_name = "bullet_tracer_xs_sr"
            STREAMING.REQUEST_NAMED_PTFX_ASSET(dictionary)
            GRAPHICS.USE_PARTICLE_FX_ASSET(dictionary)
            GRAPHICS.SET_PARTICLE_FX_NON_LOOPED_COLOUR(math.random(255), math.random(255), math.random(255))
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, math.random(-100, 100), math.random(-100, 100), 100)
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfx_name, pos.x, pos.y, pos.z, 90, math.random(360), 0.0, 1.0, true, true, true, true)
        end,

        ANTI_TOW_TRUCK = function()
            if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
                VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(entities.get_user_vehicle_as_handle(false))
                VEHICLE.SET_VEHICLE_DISABLE_TOWING(entities.get_user_vehicle_as_handle(false), true)
            end
        end,

        PUNISH_SPECTATORS = function()
            local _players = players.list(false, false)
            for i, player in pairs(_players) do
                local spectating = players.get_spectate_target(player)
                if spectating == players.user() then
                    menu.trigger_commands("timeout"..players.get_name(player).." on")
                end
            end
        end,

        VEHICLE_ROCKET_AIMBOT = function()
            for i, player_id in pairs(players.list_except(true)) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local pedDistance = v3.distance(players.get_position(players.user()), players.get_position(player_id))
                if not PLAYER.IS_PLAYER_DEAD(ped) and PAD.IS_CONTROL_PRESSED(0, 70) and pedDistance < 250.0 and not players.is_in_interior(player_id) and VEHICLE.GET_VEHICLE_HOMING_LOCKON_STATE(entities.get_user_vehicle_as_handle()) == 0 then
                    local pos = players.get_position(player_id)
                    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(players.user_ped(), ped, pos.X, pos.Y, pos.Z)
                end
            end
        end,

        RAINBOW_HEADLIGHTS = function(Enabled)
            local Current_Car = entities.get_user_vehicle_as_handle(false)
            if entities.Current_Car ~= 0 then 
                VEHICLE.TOGGLE_VEHICLE_MOD(Current_Car, 22, true)
                for i=1, 12 do
                    VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(Current_Car, i)  
                    util.yield(200)
                end
            end
        end,

        RAINBOW_NEONS = function(Enabled)
            if Enabled then
                menu.trigger_commands("neoncolourrainbow 10")
                menu.trigger_commands("neoncoloursaturation 100")
                menu.trigger_commands("neoncolourvalue 100")
                menu.trigger_commands("vehneonall on")
            else
                menu.trigger_commands("neoncolourrainbow 0")
                menu.trigger_commands("vehneonall off")
            end
        end,

        DRIFT_MODE = function(Enabled)
            VEHICLE.SET_DRIFT_TYRES(PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())), Enabled)
        end,

        LOUD_RADIO = function(Enabled)
            AUDIO.SET_VEHICLE_RADIO_LOUD(PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())), Enabled)
        end,

        FILL_BOOST = function()
            local Ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            if PED.IS_PED_IN_ANY_VEHICLE(Ped) then
                local Vehicle = PED.GET_VEHICLE_PED_IS_USING(Ped)
                if VEHICLE.GET_HAS_ROCKET_BOOST(Vehicle) then
                    VEHICLE.SET_ROCKET_BOOST_FILL(Vehicle, 100.0)
                end
            end
        end,

        STOP_BOOST = function()
            VEHICLE.SET_ROCKET_BOOST_ACTIVE(PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())), false)
        end,

        TELEPORT_TO = function(player_id, coords)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
            if player_id then
                local position = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, position.x, position.y, position.z, false, false, false)
            else
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, coords.x, coords.y, coords.z, false, false, false)
            end
        end,

        TELEPORT_INTO_PLAYER_VEHICLE = function(player_id)
            local TargetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            if PED.IS_PED_IN_ANY_VEHICLE(TargetPed) then
                local Ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
                local Vehicle = PED.GET_VEHICLE_PED_IS_USING(TargetPed)
                local EntityVehicle = ENTITY.GET_ENTITY_MODEL(Vehicle)
                local Seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(EntityVehicle)

                if Seats == 1 then
                    util.toast("Vehicle has only 1 seat.")
                    return
                end

                for Seat = -1, Seats - 1 do
                    if VEHICLE.IS_VEHICLE_SEAT_FREE(Vehicle, Seat) then
                        NET2.FUNCTION.TELEPORT_TO(player_id)
                        PED.SET_PED_INTO_VEHICLE(Ped, Vehicle, Seat)
                        return
                    end
                end
            else
                util.toast("Player is not in a vehicle.")
            end
        end,

        ROLL_DOWN_WINDOW = function(option)
            VEHICLE.ROLL_DOWN_WINDOW(PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())), option-1)
        end,

        ROLL_UP_WINDOW = function(option)
            VEHICLE.ROLL_UP_WINDOW(PED.GET_VEHICLE_PED_IS_USING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())), option-1)
        end,
    },

    DETECTION = {
        -- JinxScript stuff..

        CHECK_FOR_2TAKE1 = function()
            for i, player_id in pairs(players.list_except()) do
                local vehicle = NET2.UTIL.IS_PLAYER_IN_VEHICLE(player_id)
                if vehicle
                and DECORATOR.DECOR_GET_INT(vehicle, "MPBitset") == 1024
                and players.get_weapon_damage_modifier(player_id) == 1
                and not players.is_godmode(player_id)
                and not DECORATOR.DECOR_GET_BOOL(vehicle, "CreatedByPegasus")
                and memory.read_int(memory.script_global(1845263 + 1 + (player_id * 877) + 9)) == 0 then
                    if not NET2.UTIL.IS_PLAYER_FLAGGED(player_id, "2Take1 User") then
                        players.add_detection(player_id, "2Take1 User", TOAST_ALL, 100)
                        return
                    end
                end
            end
        end,

        CHECK_FOR_YIM = function()
            for i, player_id in pairs(players.list_except()) do
                if tonumber(players.get_host_token(player_id)) == 41 then
                    if not NET2.UTIL.IS_PLAYER_FLAGGED(player_id, "YimMenu Base") then
                        players.add_detection(player_id, "YimMenu Base", TOAST_ALL, 100)
                        return
                    end
                end
            end
        end,
    },
}

-- UI
local Title = menu.divider(menu.my_root(), "NET.REAPER")

local SELF_LIST = menu.list(menu.my_root(), "Self")
local WEAPON_LIST = menu.list(SELF_LIST, "Weapons")
menu.toggle_loop(WEAPON_LIST, "Explosive Ammo", {}, "", function() NET2.PLAYER.EXPLOSIVE_AMMO(players.user()) end)
menu.toggle_loop(WEAPON_LIST, "Fast Hand", {}, "Faster weapon swapping.", NET2.FUNCTION.RESET_ANIMATION)
menu.toggle_loop(WEAPON_LIST, "Hitbox Expander", {}, "Expands every player's hitbox.", NET2.FUNCTION.EXPAND_ALL_HITBOXES)
menu.toggle_loop(WEAPON_LIST, "Rocket Aimbot", {}, "Lock onto players with homing rpg.", NET2.FUNCTION.LOCK_ONTO_PLAYERS, NET2.FUNCTION.STOP_LOCKING_ONTO_PLAYERS)
local RADIO_LIST = menu.list(SELF_LIST, "JBL Speaker")
menu.list_select(RADIO_LIST, "Radio Station", {}, "", {"Blaine County Radio", "The Blue Ark", "Worldwide FM", "FlyLo FM", "The Lowdown 9.11", "The Lab", "Radio Mirror Park", "Space 103.2", "Vinewood Boulevard Radio", "Blonded Los Santos 97.8 FM", "Los Santos Underground Radio", "iFruit Radio", "Motomami Lost Santos", "Los Santos Rock Radio", "Non-Stop-Pop FM", "Radio Los Santos", "Channel X", "West Coast Talk Radio", "Rebel Radio", "Soulwax FM", "East Los FM", "West Coast Classics", "Media Player", "The Music Locker", "Kult FM", "Still Slipping Los Santos"}, 1, function(index) radio = index end)
menu.toggle_loop(RADIO_LIST, "Play Music", {}, "Networked", NET2.FUNCTION.TOGGLE_RADIO, NET2.FUNCTION.STOP_RADIO)
local VANITY_LIST = menu.list(SELF_LIST, "Vanity Particles")
menu.list_select(VANITY_LIST, "Particles", {}, "", {"Rainbow", "Brown", "Blue", "Green", "Orange", "Greyblack"}, 1, function(Value) vanity = Value end)
menu.toggle_loop(VANITY_LIST, "Enable", {}, "", function(Enabled) NET2.PLAYER.VANITY_PARTICLES(players.user(), vanity) end)
menu.toggle(SELF_LIST, "Passive Mode", {}, "Ghost yourself from everybody.", function(Enabled) NETWORK.SET_LOCAL_PLAYER_AS_GHOST(Enabled) end)
menu.toggle(SELF_LIST, "Super Radar", {}, "Unzooms the minimap.", function(Enabled) NET2.FUNCTION.SUPER_RADAR(Enabled) end)
local VEHICLE_LIST = menu.list(menu.my_root(), "Vehicle")
menu.toggle_loop(VEHICLE_LIST, "Vehicle Rocket Aimbot", {}, "", NET2.FUNCTION.VEHICLE_ROCKET_AIMBOT)
menu.toggle_loop(VEHICLE_LIST,"Rainbow Headlights", {""}, "", function(Enabled) NET2.FUNCTION.RAINBOW_HEADLIGHTS(Enabled) end)
menu.toggle(VEHICLE_LIST,"Rainbow Neons", {""}, "", function(Enabled) NET2.FUNCTION.RAINBOW_NEONS(Enabled) end)
menu.toggle(VEHICLE_LIST, "Drift Tyres", {}, "", function(Enabled) NET2.FUNCTION.DRIFT_MODE(Enabled) end)
menu.toggle(VEHICLE_LIST, "Loud Radio", {}, "Not sure this is networked.", function(Enabled) NET2.FUNCTION.LOUD_RADIO(Enabled) end)
menu.toggle_loop(VEHICLE_LIST, "Keep Boost Full", {}, "", NET2.FUNCTION.FILL_BOOST, NET2.FUNCTION.STOP_BOOST)
local VEHICLE_WINDOWS_LIST = menu.list(VEHICLE_LIST, "Vehicle Windows")
menu.list_action(VEHICLE_WINDOWS_LIST, "Roll Up Window", {}, "", {"Left Front", "Right Front", "Left Back", "Right Back"}, function(Option) NET2.FUNCTION.ROLL_UP_WINDOW(Option) end)
menu.list_action(VEHICLE_WINDOWS_LIST, "Roll Down Window", {}, "", {"Left Front", "Right Front", "Left Back", "Right Back"}, function(Option) NET2.FUNCTION.ROLL_DOWN_WINDOW(Option)  end)
local ONLINE_LIST = menu.list(menu.my_root(), "Online")
local PROTECTION_LIST = menu.list(ONLINE_LIST, "Protections")
menu.toggle_loop(PROTECTION_LIST, "Anti Tow-Truck", {}, "", NET2.FUNCTION.ANTI_TOW_TRUCK)
menu.toggle_loop(PROTECTION_LIST, "Anti Spectator", {}, "You will stand still on the other player's screen.", NET2.FUNCTION.PUNISH_SPECTATORS)
ENTITY_THROTTLER_LIST = menu.list(PROTECTION_LIST, "Entity Throttler", {}, "Great anti object crash & anti ferris wheel troll.") pcall(require("lib.net.Throttler"))
local SELF_RECOVERY_LIST = menu.list(ONLINE_LIST, "Recovery")
SLOTBOT_LIST = menu.list(SELF_RECOVERY_LIST, "[SAFE] Slotbot", {}, "", function() require("lib.net.SlotBot") end)
MONEY_LIST = menu.list(SELF_RECOVERY_LIST, "[SAFE] Money Recovery", {}, "", function() require("lib.net.Money") end)
local HOST_LIST = menu.list(ONLINE_LIST, "Host Tools")
menu.divider(HOST_LIST, "Host")
menu.action(HOST_LIST, "Become Host", {}, "", NET2.QUICK.BECOME_HOST)
menu.divider(HOST_LIST, "Script Host")
menu.toggle_loop(HOST_LIST, "Script Host Addict", {}, "Gatekeep script host with all of your might.", NET2.QUICK.BECOME_SCRIPT_HOST)
menu.action(HOST_LIST, "Become Script Host", {""}, "", NET2.QUICK.BECOME_SCRIPT_HOST)
menu.toggle(ONLINE_LIST, "Session Overlay", {}, "General information about the server.", function(Enabled) local Commands = {"infotime", "infotps", "infoplayers", "infowhospectateswho", "infomodder", "infohost", "infonexthost", "infoscripthost"} for next = 1, #Commands do menu.trigger_commands(Commands[next].. (Enabled and " on" or " off")) util.yield(100) end end)
menu.action(ONLINE_LIST, "Server Hop", {}, "", function() menu.trigger_commands("playermagnet 30") menu.trigger_commands("go public") end)
menu.action(ONLINE_LIST, "Rejoin", {}, "", function() menu.trigger_commands("rejoin") end)
local UNSTUCK_LIST = menu.list(ONLINE_LIST, "Unstuck", {}, "Every methods to get unstuck.")
menu.action(UNSTUCK_LIST, "Abort Transition", {}, "", function() menu.trigger_commands("aborttransition") end)
menu.action(UNSTUCK_LIST, "Unstuck", {}, "", function() menu.trigger_commands("unstuck") end)
menu.action(UNSTUCK_LIST, "Quick Bail", {}, "", function() menu.trigger_commands("quickbail") end)
menu.action(UNSTUCK_LIST, "Quit To SP", {}, "", function() menu.trigger_commands("quittosp") end)
menu.action(UNSTUCK_LIST, "Force Quit To SP", {}, "", function() menu.trigger_commands("forcequittosp") end)
local PLAYERS_LIST = menu.list(menu.my_root(), "Players")
menu.list_select(PLAYERS_LIST, "Target", {}, "", {"All", "Modders", "Plebs"}, 1, function(Index) NET2.MENU.ToDisplay = Index end)
menu.toggle(PLAYERS_LIST, "Ignore Host", {}, "Good for karma.", function(Enabled) NET2.MENU.IgnoreHost = Enabled end)
local ALL_PLAYERS_LIST = menu.list(PLAYERS_LIST, "All Players")
local TROLLING_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Trolling")
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Force All Cameras Forward", {}, "Blocked by most menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EVENT.FORCE_CAMERA_FORWARD) end)
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Kick All From Vehicle", {}, "Blocked by most menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EVENT.KICK_FROM_VEHICLE) end)
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Stun All", {}, "", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.PLAYER.STUN) end)
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Freeze All", {}, "Blocked by most menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EVENT.FREEZE) end)
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Kill All", {}, "You will be blamed in the killfeed.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.KILL) end)
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Explode All", {}, "You will not be blamed in the killfeed.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EXPLODE) end)
menu.toggle_loop(TROLLING_PLAYERS_LIST, "Glitch All", {}, "Blocked by most menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EVENT.GLITCH) end)
menu.action(TROLLING_PLAYERS_LIST, "Send All Corrupt Invite", {}, "Blocked by most menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EVENT.CORRUPT_INVITE) end)
local RECOVERY_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Recovery")
menu.toggle_loop(RECOVERY_PLAYERS_LIST, "RP Loop", {"rplobby"}, "Will level up players until level 120.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.EVENT.GIVE_RP) end)
menu.action(RECOVERY_PLAYERS_LIST, "Give All Collectibles", {"bless"}, "Gives all collectibles. (Up to $300k).", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.GIVE_ALL_COLLECTIBLES) end)
menu.toggle(RECOVERY_PLAYERS_LIST, "Rig Casino", {}, "HOW TO USE:\nStay inside casino.\nPlayers must have casino membership to earn alot.\nBlackjack: Stand if number is high, double down if low.\nRoulette: Max bet on Red 1 and Max Bet on Red 1st 12.", function(Enabled) menu.trigger_commands("rigblackjack"..(Enabled and " on" or " off")) menu.trigger_commands("rigroulette"..(Enabled and " 1" or " -1")) end)
local MODERATE_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Moderate")
menu.action(MODERATE_PLAYERS_LIST, "Remove All", {}, "Blocked by popular menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.KICK) end)
menu.action(MODERATE_PLAYERS_LIST, "Freemode Death All", {}, "Blocked by most menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.SCRIPTKICK) end)
menu.action(MODERATE_PLAYERS_LIST, "Express Crash All", {}, "Blocked by popular menus.", function() NET2.UTIL.FIRE_FOR_PLAYERS(NET2.MENU.ToDisplay, NET2.MENU.IgnoreHost, NET2.MENU.ToDisplay == 3 and true, NET2.QUICK.CRASH.EXPRESS) end)
local SERVER_CRASHES = menu.list(MODERATE_PLAYERS_LIST, "Server Crashes")
menu.action(SERVER_CRASHES, "[RYZE] AIO Crash", {}, "Blocked by most menus.", NET2.QUICK.CRASH.SERVER.AIO)
menu.action(SERVER_CRASHES, "[NIGHT] Moonstar Crash", {}, "Blocked by most menus.", NET2.QUICK.CRASH.SERVER.MOONSTAR)
menu.action(SERVER_CRASHES, "[NIGHT] Rope Crash", {}, "Blocked by most menus.", NET2.QUICK.CRASH.SERVER.ROPE)
menu.action(SERVER_CRASHES, "[NIGHT] Land Crash", {}, "Blocked by most menus.", NET2.QUICK.CRASH.SERVER.LAND)
menu.action(SERVER_CRASHES, "[NIGHT] Umbrella V8 Crash", {}, "Blocked by most menus.", NET2.QUICK.CRASH.SERVER.UMBRELLAV8)
menu.action(SERVER_CRASHES, "[NIGHT] Umbrella V1 Crash", {}, "Blocked by most menus.", NET2.QUICK.CRASH.SERVER.UMBRELLAV1)
menu.toggle(MODERATE_PLAYERS_LIST, "Automatic Modders Removal", {"irondome"}, "Recommended to use when host.", function(Enabled) nomodders = Enabled end)
PLAYER_COUNT = menu.divider(PLAYERS_LIST, "Players")
local WORLD_LIST = menu.list(menu.my_root(), "World")
menu.toggle_loop(WORLD_LIST, "Laser Show", {}, "Networked", NET2.FUNCTION.LASER_SHOW)
CONSTRUCTOR_LIST = menu.list(WORLD_LIST, "Constructor") pcall(require("lib.net.Constructor"))
menu.action(menu.my_root(), "Credits", {}, "Made by @getfenv.", function() util.toast("I made the script and took some functions from the following scripts; JinxScript, Ryze Stand, Night LUA, Addict Script.") end)

-- Main loop of the script.
util.create_thread(function()
    repeat
        NET2.MENU.REFRESH_PROFILES(PLAYERS_LIST)
        NET2.DETECTION.CHECK_FOR_2TAKE1()
        NET2.DETECTION.CHECK_FOR_YIM()
        util.yield(REFRESH_TIME)
    until IS_CLOSING

    util.stop_thread()
end)

util.on_stop(function()
    IS_CLOSING = true
    nomodders = false
    NET2 = nil
end)
