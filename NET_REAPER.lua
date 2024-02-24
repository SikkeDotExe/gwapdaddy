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
Version 1.4a
[+] Improved Airstrike Kick
[+] Added Pool's Closed Kick
[~] Fixed Airstrike Kick
[-] Removed Big Kick
[-] Removed Little Kick
[-] Removed Legit Kick
]]

IN_DEV = false
VERSION = "1.4a"

-- Libraries
util.require_natives(1676318796)
require "lib.net.Intro"

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

local PLAYERS_LIST
local PLAYERS_COUNT
local IS_CLOSING = false

table.find = function(t, k)
    for next = 1, #t do
        if t[next] == k then
            return true
        end
    end
    return false
end

NET = {
    VARIABLE = {
        GAME = {GlobalplayerBD = 2657921},
        Players_To_Affect = 1,
        Ignore_Host = false,
        Ignore_Modded_Stats = false,
        Kick_Method = 1,
        Crash_Method = 3,

        To_Level_Up_To = 120,

        Current_Profile = 1,

        Selected_Loud_Radio = "RADIO_11_TALK_02",
        Party_Bus = nil,

        Host_Addict_Kick_Cooldown = 0,

        Players_Count = 0,

        Is_Busy_Glitching = false,
        Glitch_Toggle = nil,
        Object_Hash = util.joaat("prop_ld_ferris_wheel"),

        Vents = {},

        Block_Modders = false,
        No_Modders_Session = false,
        Spectate_Loop = false,

        Ignore_Interior = false,

        Commands_Enabled = false,
        Commands_Default_Prefix = ";",
        Commands_Prefix = Commands_Default_Prefix,

        Auto_Ghost = false,
    },

    TABLE = {
        PLAYER_RANKED = { -- This is where we store all the players dynamically
            [players.get_name(players.user())] = {Rank = 4, Prefix = ";"}
        },

        PLAYER_COMMAND = {
            ["ping"] = {Alias = {}, Description = "pong", Rank = 1, Fire = function(whofired, target, args) -- example command
                menu.trigger_commands("say pong")
            end},

            ["toast"] = {Alias = {"print"}, Description = "Debug output.", Rank = 1, Fire = function(whofired, target, args) -- example command
                util.toast("Caller: "..players.get_name(whofired))

                if target then
                    util.toast("Target: "..players.get_name(target))
                end

                local output = args[1]
                for next = 2, #args do
                    output = output.." "..args[next]
                end

                util.toast("Arguments: "..output)
            end},

            ["help"] = {Alias = {}, Description = "General information, can also be used with a command as argument.", Rank = 1, Fire = function(whofired, target, args)
                if args[2] then
                    if NET.TABLE.PLAYER_COMMAND[args[2]] then
                        util.toast("["..args[2].."] - "..NET.TABLE.PLAYER_COMMAND[args[2]].Description)
                    else
                        util.toast("Invalid input.")
                    end
                else
                    -- Default
                    util.toast("General help information.")
                end
            end},

            ["prefix"] = {Alias = {}, Description = "Default prefix is ';'", Rank = 1, Fire = function(whofired, target, args)
                if args[2] and args[2] ~= "" or args[2] ~= " " or args[2] ~= "  " then
                    NET.TABLE.PLAYER_RANKED[players.get_name(whofired)].Prefix = args[2]
                else
                    util.toast("Invalid input.")
                end
            end},

            ["casino"] = {Alias = {}, Description = "", Rank = 1, Fire = function(whofired, target, args)
                menu.trigger_commands("casinotp"..players.get_name(whofired))
            end},

            ["unstuck"] = {Alias = {"fix"}, Description = "Useful when stuck is a loading screen.", Rank = 1, Fire = function(whofired, target, args)
                menu.trigger_commands("fix"..players.get_name(whofired))
            end},

            ["weapons"] = {Alias = {"guns"}, Description = "Gives all weapons.", Rank = 1, Fire = function(whofired, target, args)
                menu.trigger_commands("armsall"..players.get_name(whofired))
            end},

            ["goto"] = {Alias = {}, Description = "Teleport to a player.", Rank = 1, Fire = function(whofired, target, args)
                if target then
                    menu.trigger_commands("as "..players.get_name(target).." summon "..players.get_name(whofired))
                end
            end},

            ["bounty"] = {Alias = {}, Description = "", Rank = 1, Fire = function(whofired, target, args)
                if target then
                    for next = 1, #target do
                        menu.trigger_commands("bounty"..players.get_name(target).." 10000")
                    end
                end
            end},

            ["bring"] = {Alias = {}, Description = "Brings player(s) to you.", Rank = 2, Fire = function(whofired, target, args)
                if target then
                    for next = 1, #target do
                        menu.trigger_commands("as "..players.get_name(whofired).." summon "..players.get_name(target[next]))
                    end
                end
            end},

            ["ceokick"] = {Alias = {"mckick"}, Description = "", Rank = 2, Fire = function(whofired, target, args)
                if target then
                    menu.trigger_commands("ceokick"..players.get_name(target))
                end
            end},

            ["teleport"] = {Alias = {"tp"}, Description = "Teleports P1 to P2.", Rank = 2, Fire = function(whofired, target, args) -- 1 - 1 / not all players
                local Player1 = NET.FUNCTION.GET_PLAYER_FROM_ARG(whofired, args[2])
                local Player2 = NET.FUNCTION.GET_PLAYER_FROM_ARG(whofired, args[3])
                if Player1 and Player2 then
                    menu.trigger_commands("as "..players.get_name(Player2).." summon "..players.get_name(Player1))
                end
            end},

            ["explode"] = {Alias = {"expl", "boom", "jihad"}, Description = "Explodes a player.", Rank = 2, Fire = function(whofired, target, args)
                if target then
                    for next = 1, #target do
                        menu.trigger_commands("explode"..players.get_name(target[next]))
                    end
                end
            end},

            ["setrank"] = {Alias = {"rank"}, Description = "Changes a player's rank.", Rank = 4, Fire = function(whofired, target, args)
                if target and args[3] then
                    if tonumber(args[3]) ~= nil then
                        NET.TABLE.PLAYER_RANKED[players.get_name(target)].Rank = args[3]
                    end
                end
            end},
        },

        DETECTION = {
            {Name = "Rockstar Developer Flag", Threat = 3},
            {Name = "Spoofed Host Token (Aggressive)", Threat = 3},
            {Name = "Spoofed Host Token (Sweet Spot)", Threat = 3},
            {Name = "Spoofed Host Token (Handicap)", Threat = 3},
            {Name = "Spoofed Host Token (Other)", Threat = 3},
            {Name = "Hidden From Player List", Threat = 3},
            {Name = "Love Letter Lube", Threat = 3},
            {Name = "2Take1 User", Threat = 3},
            {Name = "Cheater Flag", Threat = 2},
            {Name = "Hidden From Player List", Threat = 2},
            {Name = "Rockstar QA Flag", Threat = 1},
            {Name = "Presence Spoofing", Threat = 1}, -- Detects Phantom X Confirmed
            {Name = "Off The Radar For Too Long", Threat = 1},
            {Name = "Modded Character Model", Threat = 1},
            {Name = "Damage Multiplier", Threat = 1},
            {Name = "Super Jump", Threat = 1},
            {Name = "Bounty Spam", Threat = 1},
            {Name = "Modded Bounty", Threat = 1},
            {Name = "Modded Explosion", Threat = 1},
            {Name = "Attacking While Invulnerable", Threat = 1},
            {Name = "YimMenu User", Threat = 0}, -- Detects Yim Skids & Ethereal.
        },

        RADIO = {
            NAME = {
                "Blaine County Radio",
                "The Blue Ark",
                "Worldwide FM",
                "FlyLo FM",
                "The Lowdown 9.11",
                "The Lab",
                "Radio Mirror Park",
                "Space 103.2",
                "Vinewood Boulevard Radio",
                "Blonded Los Santos 97.8 FM",
                "Los Santos Underground Radio",
                "iFruit Radio",
                "Motomami Lost Santos",
                "Los Santos Rock Radio",
                "Non-Stop-Pop FM",
                "Radio Los Santos",
                "Channel X",
                "West Coast Talk Radio",
                "Rebel Radio",
                "Soulwax FM",
                "East Los FM",
                "West Coast Classics",
                "Media Player",
                "The Music Locker",
                "Kult FM",
                "Still Slipping Los Santos"
            },
            
            STATION = {
                "RADIO_11_TALK_02", 
                "RADIO_12_REGGAE",
                "RADIO_13_JAZZ",
                "RADIO_14_DANCE_02",
                "RADIO_15_MOTOWN",
                "RADIO_20_THELAB",
                "RADIO_16_SILVERLAKE",
                "RADIO_17_FUNK",
                "RADIO_18_90S_ROCK",
                "RADIO_21_DLC_XM17",
                "RADIO_22_DLC_BATTLE_MIX1_RADIO",
                "RADIO_23_DLC_XM19_RADIO",
                "RADIO_19_USER",
                "RADIO_01_CLASS_ROCK",
                "RADIO_02_POP",
                "RADIO_03_HIPHOP_NEW",
                "RADIO_04_PUNK",
                "RADIO_05_TALK_01",
                "RADIO_06_COUNTRY", 
                "RADIO_07_DANCE_01",
                "RADIO_08_MEXICAN",
                "RADIO_09_HIPHOP_OLD",
                "RADIO_36_AUDIOPLAYER",
                "RADIO_35_DLC_HEI4_MLR",
                "RADIO_34_DLC_HEI4_KULT",
                "RADIO_27_DLC_PRHEI4"
            }
        },

        GLITCH_OBJECT = {
            NAME = {
                {1, "Ferris Wheel"},
                {2, "UFO"},
                {3, "Cement Mixer"},
                {4, "Scaffolding"},
                {5, "Garage Door"},
                {6, "Big Bowling Ball"},
                {7, "Big Soccer Ball"},
                {8, "Big Orange Ball"},
                {9, "Stunt Ramp"},
            },
            OBJECT = {
                "prop_ld_ferris_wheel",
                "p_spinning_anus_s",
                "prop_staticmixer_01",
                "prop_towercrane_02a",
                "des_scaffolding_root",
                "prop_sm1_11_garaged",
                "stt_prop_stunt_bowling_ball",
                "stt_prop_stunt_soccer_ball",
                "prop_juicestand",
                "stt_prop_stunt_jump_l",
            }
        },

        CRASH_OBJECT = {
            "proc_brittlebush_01",
            "proc_dryplantsgrass_01",
            "proc_dryplantsgrass_02",
            "proc_grasses01",
            "prop_dryweed_002_a",
            "prop_fernba",
            "prop_fernbb",
            "prop_weed_001_aa",
            "prop_weed_002_ba",
            "urbandryfrnds_01",
            "urbangrnfrnds_01",
            "urbangrngrass_01",
            "urbanweeds01",
            "urbanweeds01_l1",
            "urbanweeds02",
            "v_proc2_temp",
            "prop_dandy_b",
            "prop_pizza_box_03",
            "proc_meadowmix_01",
            "proc_grassplantmix_02",
            "h4_prop_bush_mang_ad",
            "h4_prop_bush_seagrape_low_01",
            "prop_saplin_002_b",
            "proc_leafyplant_01",
            "prop_saplin_002_c",
            "proc_sml_reeds_01b",
            "prop_grass_dry_02",
            "proc_sml_reeds_01c",
            "prop_grass_dry_03",
            "prop_grass_ca",
            "h4_prop_grass_med_01",
            "h4_prop_bush_fern_tall_cc",
            "h4_prop_bush_ear_aa",
            "h4_prop_bush_fern_low_01",
            "proc_lizardtail_01",
            "proc_drygrassfronds01",
            "prop_grass_da",
            "prop_small_bushyba",
            "urbandrygrass_01",
            "proc_drygrasses01",
            "h4_prop_bush_ear_ab",
            "proc_dry_plants_01",
            "proc_desert_sage_01",
            "prop_saplin_001_c",
            "proc_drygrasses01b",
            "h4_prop_weed_groundcover_01",
            "proc_grasses01b",
            "prop_saplin_001_b",
            "proc_lupins_01",
            "proc_grassdandelion01",
            "h4_prop_bush_mang_low_ab",
            "h4_prop_grass_tropical_lush_01",
            "proc_indian_pbrush_01",
            "proc_stones_02",
            "h4_prop_grass_wiregrass_01",
            "proc_sml_reeds_01",
            "proc_leafybush_01",
            "h4_prop_bush_buddleia_low_01",
            "proc_stones_03",
            "proc_grassplantmix_01",
            "h4_prop_bush_mang_low_aa",
            "proc_meadowpoppy_01",
            "prop_grass_001_a",
            "proc_forest_ivy_01",
            "proc_stones_04",
            "prop_tall_drygrass_aa", -- NET
            "prop_thindesertfiller_aa", -- NET
            
        },

        METHOD = {
            PLAYER = {
                {1, "All"},
                {2, "Modders"},
                {3, "Strangers"},
                {4, "Plebs"},
            },
            KICK = {
                {1, "[NET] Backstab"},
                {2, "[STAND] Host"},
                {3, "[HOST] Ban"},
                {4, "[HOST] Blacklist"},
            },
            CRASH = {
                {1, "[NET] Express"},
                {2, "[NET] Dynamite"},
                {3, "[STAND] Elegant"},
            },
        },

        SCRIPT = {
            "valentineRpReward2",
            "main_persistent",
            "cellphone_controller",
            "shop_controller",
            "stats_controller",
            "timershud",
            "am_npc_invites",
            "fm_maintain_cloud_header_data"
        },

        STAND = {
            PLAYER = {"godmode", "grace"},
            SESSION = {"seamless","skipbroadcast","speedupfmmc","speedupspawn","skipswoopdown","transitionhelper","showtransitionstate","lrnotify","autorejoindesynced"},
            SPOOFING = {"devflag","hosttokenspoofing"},
            ENHANCEMENT = {"noidlekick","fullplayerlist","nodeathbarriers"},
            REACTION = {
                RID_JOIN_REACT = "Online>Reactions>RID Join Reactions", -- N,B,K,L,B,C
                VOTE_KICK_REACT = "Online>Reactions>Vote Kick Reactions>Voting To Kick Me", -- N,K,L,B,C
                LOVE_LETTER_REACT = "Online>Reactions>Love Letter Kick Reactions", -- N,B
                REPORT_REACT = "Online>Reactions>Report Reactions", -- N,B,K,L,B,C
                PARTICLE_SPAM_REACT = "Online>Reactions>Particle Spam Reactions" -- N,B,K,L,B,C
            },
            PROTECTION = {
                "lessenhostkicks",
                "notifyloveletter",
                "desynckarma",
                "novotekicks", --sctv
                "blockjoinkarma",
                "blockentityspam",
                "drawpatch",
                "nobeast",
                "scripterrorrecovery",
                "forcerelayconnections",
                CRASH_EVENT = "Online>Protections>Events>Crash Event", -- N,B,K,L,B,C
                KICK_EVENT = "Online>Protections>Events>Kick Event", -- N,B,K,L,B,C
                MODDED_EVENT = "Online>Protections>Events>Modded Event", -- N,B,K,L,B,C
                UNUSUAL_EVENT = "Online>Protections>Events>Unusual Event", -- N,B
                CAMERA_EVENT = "Online>Protections>Events>Force Camera Forward", -- N,B,K,L,B,C
                FREEMODE_EVENT = "Online>Protections>Events>Start Freemode Mission (Not My Boss)", -- N,B,K,L,B,C
                TP_INTERIOR_EVENT = "Online>Protections>Events>Teleport To Interior (Not My Boss)", -- N,B,K,L,B,C
                RP_EVENT = "Online>Protections>Events>Give Collectible", -- N,B,K,L,B,C
                RP_BOSS_EVENT = "Online>Protections>Events>Give Collectible (Not My Boss)", -- N,B,K,L,B,C
                MC_KICK_EVENT = "Online>Protections>Events>CEO/MC Kick", -- N,B,K,L,B,C
                SCREEN_EVENT = "Online>Protections>Events>Infinite Loading Screen", -- N,B,K,L,B,C
                PHONE_EVENT = "Online>Protections>Events>Infinite Phone Ringing", -- N,B,K,L,B,C
                JOB_EVENT = "Online>Protections>Events>Send To Job", -- N,B,K,L,B,C
                TAKEOVER_EVENT = "Online>Protections>Events>Vehicle Takeover",-- N,B,K,L,B,C
                DISABLE_DRIVING_EVENT = "Online>Protections>Events>Disable Driving Vehicles",-- N,B,K,L,B,C
                KICK_VEHICLE_EVENT = "Online>Protections>Events>Kick From Vehicle", -- N,B,K,L,B,C
                KICK_INTERIOR_EVENT = "Online>Protections>Events>Kick From Interior",-- N,B,K,L,B,C
                FREEZE_EVENT = "Online>Protections>Events>Freeze", -- N,B,K,L,B,C
                SHAKE_EVENT = "Online>Protections>Events>Camera Shaking Event", -- N,B,K,L,B,C
                EXPLO_SPAM_EVENT = "Online>Protections>Events>Explosion Spam", -- N,B,K,L,B,C
                RAGDOLL_EVENT = "Online>Protections>Events>Ragdoll Event", -- N,B,K,L,B,C
                MODDED_DAMAGE_EVENT = "Online>Protections>Events>Modded Damage Event", -- N,B,K,L,B,C
                REMOVE_WEAPON_EVENT = "Online>Protections>Events>Remove Weapon Event", -- N,B,K,L,B,C
                PICKUP1_EVENT = "Online>Protections>Pickups>Any Pickup Collected", -- N,B
                PICKUP2_EVENT = "Online>Protections>Pickups>Cash Pickup Collected", -- N,B
                PICKUP3_EVENT = "Online>Protections>Pickups>RP Pickup Collected", -- N,B
                PICKUP4_EVENT = "Online>Protections>Pickups>Invalid Pickup Collected", -- N,B
                SYNC1_EVENT = "Online>Protections>Syncs>Cage", -- N,B,K,L,B,C
                SYNC2_EVENT = "Online>Protections>Syncs>World Object Sync", -- N,B,K,L,B,C
                SYNC3_EVENT = "Online>Protections>Syncs>Invalid Model Sync", -- N,B,K,L,B,C
                SYNC4_EVENT = "Online>Protections>Syncs>Attachment Spam", -- N,B,K,L,B,C
            },
            GAME = {"svmreimpl"}
        },

        PROFILE = {
            {1, "[UNDETECTED] Default"},
            {2, "[UNDETECTED] Strict"},
            {3, "[BEST] Warrior"},
        },

        BONE = {
            31086,
            24816,
            40269,
            45509,
            0,
            51826,
            5827,
        },

        VEHICLE = {
            ROCKET = {"voltic2","scramjet","vigilante"},
            SUPER = {"adder","entityxf","nero2","t20","thrax"},
            MOTO = {"deathbike2","manchez","faggio","oppressor","oppressor2","reever","bati","sanchez"},
            PLANE = {"strikeforce","cargoplane2","raiju","hydra","luxor2","lazer","pyro","seabreeze","microlight","molotok","vestra"},
            HELI = {"akula","anihilator2","buzzard","hunter","havok","savage","valkyrie","swift2"},
            MILITARY = {"apc","rhino","khanjali","thruster","nightshark","riot2","riot"},
        },
    },

    FUNCTION = {
        GET_PLAYERS_FROM_SELECTION = function()
            local Table = {}
            local Table_SANITIZED = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                Table = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(Table, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                Table = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(Table, Players[next])
                    end
                end
            end
        
            for next = 1, #Table do
                if players.exists(Table[next]) then
                    if NET.VARIABLE.Ignore_Host and players.get_host() == Table[next] then
                    elseif NET.VARIABLE.Ignore_Modded_Stats and NET.FUNCTION.IS_PLAYER_STATS_MODDED(Table[next]) then
                    else
                        table.insert(Table_SANITIZED, Table[next])
                    end
                end
            end

            return Table_SANITIZED
        end,

        GET_PLAYER_FROM_ARG = function(whofired, input)
            if not input or string.lower(input) == "me" or tonumber(input) ~= nil then
                return {whofired}
            end
            
            if string.lower(input) == "all" then
                return players.list(false)
            end

            if string.lower(input) == "modders" then
                local toret = {}
                for i,v in pairs(players.list(false)) do
                    if players.is_marked_as_modder(v) then
                        table.insert(toret, v)
                    end
                end

                return toret
            end

            if string.lower(input) == "friends" then
                return players.list(false, true, false)
            end

            if string.lower(input) == "strangers" then
                return players.list(false, false, true)
            end
            
            for i,v in pairs(players.list()) do
                if string.sub(string.lower(players.get_name(v)), 1, string.len(input)) == string.lower(input) then
                    return {v}
                end
            end
            
            return nil
        end,

        PROCESS_COMMAND = function(whofired, ...)
            local Args = string.split(string.lower(...), " ")
            local Player = NET.TABLE.PLAYER_RANKED[players.get_name(whofired)]

            local Index = 0
	        local Commands = {}

            -- Formats the arguments
            for i = 1, #Args do
                if string.sub(Args[i], 1, 1) == Player.Prefix then
                    Index = Index + 1
                    Commands[Index] = {}
                    table.insert(Commands[Index], string.sub(Args[i], 2, #Args[i]))
                else
                    table.insert(Commands[Index], Args[i])
                end
            end

            -- Executes the commands
	        for i, Arguments in pairs(Commands) do
			    for cmdName, cmdContent in pairs(NET.TABLE.PLAYER_COMMAND) do
				    if cmdName == Arguments[1] or table.find(cmdContent.Alias, Arguments[1]) then
					    if cmdContent.Rank > Player.Rank then return end

                        local target = nil
					    if Arguments[2] then
                            target = NET.FUNCTION.GET_PLAYER_FROM_ARG(whofired, Arguments[2])
					    end

                        cmdContent.Fire(whofired, target, Arguments)
					end
				end
			end
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
        
        IS_PLAYER_A_THREAT = function(player_id)
            local Result = 0
        
            for next = 1, #NET.TABLE.DETECTION do
                if NET.FUNCTION.IS_PLAYER_FLAGGED(player_id, NET.TABLE.DETECTION[next].Name) then
                    Result = Result + NET.TABLE.DETECTION[next].Threat
                end
            end
        
            if Result >= 3 then
                return true
            end
        
            return false
        end,

        IS_NET_PLAYER_OK = function(player_id, assert_playing, assert_done_transition)
            if not NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then return false end
            if assert_playing and not PLAYER.IS_PLAYER_PLAYING(player_id) then return false end
            if assert_done_transition then
                if player_id == memory.read_int(memory.script_global(2672741 + 3)) then
                    return memory.read_int(memory.script_global(2672741 + 2)) ~= 0
                elseif memory.read_int(memory.script_global(NET.VARIABLE.GAME.GlobalplayerBD + 1 + (player_id * 463))) ~= 4 then
                    return false
                end
            end
            return true
        end,

        IS_SPECTATING = function(player_id)
            return bitTest(memory.read_int(memory.script_global(GlobalplayerBD + 1 + (player_id * 463) + 199)), 2)
        end,

        KICK_PLAYER = function(player_id)
            local TargetName = players.get_name(player_id)
        
            if player_id ~= players.get_host() then
                menu.trigger_commands("loveletterkick"..TargetName)
            else
                menu.trigger_commands("hostkick"..TargetName)
                menu.trigger_commands("nonhostkick"..TargetName)
            end
        end,
        
        CRASH_PLAYER = function(player_id)
            local TargetName = players.get_name(player_id)
        
            menu.trigger_commands("steamroll"..TargetName)
            menu.trigger_commands("crash"..TargetName)
        end,
        
        BLOCK_SYNCS = function(player_id, callback)
            for _, i in ipairs(players.list(false, true, true)) do
                if i ~= player_id then
                    local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
                    menu.trigger_command(outSync, "on")
                end
            end
            util.yield(10)
            callback()
            for _, i in ipairs(players.list(false, true, true)) do
                if i ~= player_id then
                    local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
                    menu.trigger_command(outSync, "off")
                end
            end
        end,
        
        NOTIFY = function(Message, Color)
            HUD.THEFEED_SET_BACKGROUND_COLOR_FOR_NEXT_POST(Color)
            util.BEGIN_TEXT_COMMAND_THEFEED_POST(Message)
            HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
        end,
        
        FIRE_EVENT = function(first_arg, receiver, args)
            table.insert(args, 1, first_arg)
            util.trigger_script_event(1 << receiver, args)
        end,

        TRIGGER_GIVE_ALL_COLLECTIBLES = function(player_id)
            for next = 0, 20 do
                for zext = 0, 100 do
                    if next == 4 and zext > 24 then
                        -- Kick Event (S0)
                    else
                        NET.FUNCTION.FIRE_EVENT(968269233, player_id, {players.user(), next, zext, 1, 1, 1})
                    end
                end
            end
        end,
        
        CHANGE_MENU_REACTIONS = function(PATH, NOTIFICATION_BOOL, BLOCK_BOOL, KICK_BOOL, LOVE_LETTER_KICK_BOOL, BLACKLIST_KICK_BOOL, CRASH_BOOL)
            if NOTIFICATION_BOOL then menu.ref_by_path(PATH..">Notification").value = NOTIFICATION_BOOL end
            if BLOCK_BOOL then menu.ref_by_path(PATH..">Block").value = BLOCK_BOOL end
            if KICK_BOOL then menu.ref_by_path(PATH..">Kick").value = KICK_BOOL end
            if LOVE_LETTER_KICK_BOOL then menu.ref_by_path(PATH..">Love Letter Kick").value = LOVE_LETTER_KICK_BOOL end
            if BLACKLIST_KICK_BOOL then menu.ref_by_path(PATH..">Blacklist Kick").value = BLACKLIST_KICK_BOOL end
            if CRASH_BOOL then menu.ref_by_path(PATH..">Crash").value = CRASH_BOOL end
        end,

        CHECK_FOR_2TAKE1 = function()
            for i, player_id in pairs(players.list_except()) do -- Automatic 2t1 check because flip them
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
                local bitset = DECORATOR.DECOR_GET_INT(vehicle, "MPBitset")
                local pegasusveh = DECORATOR.DECOR_GET_BOOL(vehicle, "CreatedByPegasus")
                if NET.FUNCTION.IS_NET_PLAYER_OK(player_id) and bitset == 1024 and players.get_weapon_damage_modifier(player_id) == 1 and not players.is_godmode(player_id) and not pegasusveh and memory.read_int(memory.script_global(1845263 + 1 + (player_id * 877) + 9)) == 0 then
                    if not NET.FUNCTION.IS_PLAYER_FLAGGED(player_id, "2Take1 User") then
                        players.add_detection(player_id, "2Take1 User", TOAST_ALL, 100)
                        return
                    end
                end
            end
        end,

        CHECK_FOR_YIM = function()
            for i, player_id in pairs(players.list_except()) do
                if tonumber(players.get_host_token(player_id)) == 41 then
                    if not NET.FUNCTION.IS_PLAYER_FLAGGED(player_id, "YimMenu User") then
                        players.add_detection(player_id, "YimMenu User", TOAST_ALL, 100)
                        return
                    end
                end
            end
        end,

        FORMAT_NUMBER = function(number)
            local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
            int = int:reverse():gsub("(%d%d%d)", "%1,")
            return minus .. int:reverse():gsub("^,", "") .. fraction
        end,

        GET_PLAYER_DETECTIONS = function(player_id)
            local Detections = {}
            for next = 1, #NET.TABLE.DETECTION do
                if NET.FUNCTION.IS_PLAYER_FLAGGED(player_id, NET.TABLE.DETECTION[next].Name) then
                    table.insert(Detections, NET.TABLE.DETECTION[next].Name)
                end
            end

            return Detections
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

            if Player_Money > 50000000 then
                Likelyness = Likelyness + 1
            elseif Player_Money > 100000000 then
                Likelyness = Likelyness + 2
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

        UPDATE_MENU = function()
            menu.set_menu_name(PLAYERS_COUNT, "Players ("..NET.VARIABLE.Players_Count..")")
            for next = 1, #players.list() do -- Changes detection tags accordingly
                local Current_Player = players.list()[next]
                local Tags = players.get_tags_string(Current_Player)
                if Tags and #Tags > 0 then
                    if NET.PROFILE[tostring(Current_Player)] then
                        local Arg1 = NET.PROFILE[tostring(Current_Player)].Menu
                        local Arg2 = players.get_name(Current_Player).." ["..Tags
                        if Current_Player == players.user() then
                            menu.set_menu_name(Arg1, Arg2.."] [SELF]")
                        elseif NET.FUNCTION.IS_PLAYER_FLAGGED(Current_Player, "2Take1 User") then
                            menu.set_menu_name(Arg1, Arg2.."] [2TAKE1]")
                        elseif NET.FUNCTION.IS_PLAYER_A_THREAT(Current_Player) then
                            menu.set_menu_name(Arg1, Arg2.."] [THREAT]")
                        elseif NET.FUNCTION.IS_PLAYER_STATS_MODDED(Current_Player) then
                            menu.set_menu_name(Arg1, Arg2.."] [$MOD]")
                        elseif players.is_using_vpn(Current_Player) then
                            menu.set_menu_name(Arg1, Arg2.."] [VPN]")
                        else
                            menu.set_menu_name(Arg1, Arg2.."]")
                        end
                    end
                end
            end
        end,

        KICK_MODDERS = function()
            local Players = players.list(false, false)
            for next = 1, #Players do
                if players.is_marked_as_modder(Players[next]) then
                    NET.FUNCTION.KICK_PLAYER(Players[next])
                end
            end
        end,

        CHANGE_PLAYER_MODEL = function(hash)
            local model_hash = hash
            STREAMING.REQUEST_MODEL(model_hash)
            while (not STREAMING.HAS_MODEL_LOADED(model_hash)) do
                util.yield(0)
            end
            PLAYER.SET_PLAYER_MODEL(model_hash)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model_hash)
        end,

        SPAWN_VEHICLE = function(Hash, Pos, Heading, Invincible)
            STREAMING.REQUEST_MODEL(Hash)
            while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
            local SpawnedVehicle = entities.create_vehicle(Hash, Pos, Heading)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
            if Invincible then
                ENTITY.SET_ENTITY_INVINCIBLE(SpawnedVehicle, true)
            end
            return SpawnedVehicle
        end,
    },

    COMMAND = {

        KICK = {
            EVICTION_NOTICE = function(player_id)
                local int_min = -2147483647
                local int_max = 2147483647
                for i = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1}) -- Unique
                end
                menu.trigger_commands("givesh" .. players.get_name(player_id))
                util.yield()
                for i = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1, player_id, math.random(int_min, int_max)})
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1})
                end
            end,

            BACKSTAB = function(player_id) -- Net exclusive / S0
                for next = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(968269233, player_id, {players.user(), 4, math.random(25, 100), 1, 1, 1}) -- Unique
                end
            end,

            AIRSTRIKE = function(player_id) -- (S0) (S1) (S2) (S3) (S4) (S5)
                menu.trigger_commands("givesh"..players.get_name(player_id))
                --S0
                NET.FUNCTION.FIRE_EVENT(-1986344798, player_id, {268435456, 1062174267, 0, 0})
                NET.FUNCTION.FIRE_EVENT(623462469, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-2102799478, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(1980857009, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-2051197492, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1013606569, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1852117343, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-1544003568, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1101672680, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-353458099, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1713699293, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1986344798, player_id, {268435456, 1705660756, 0, 0})
                NET.FUNCTION.FIRE_EVENT(623462469, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-2102799478, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1013606569, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-353458099, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-1604421397, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-2051197492, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-1852117343, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1986344798, player_id, {268435456, 375213626, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1980857009, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1713699293, player_id, {268435456})
                NET.FUNCTION.FIRE_EVENT(-1604421397, player_id, {268435456})
                --S1
                NET.FUNCTION.FIRE_EVENT(-901348601, player_id, {268435456, 2128065066})
                --S2
                NET.FUNCTION.FIRE_EVENT(-445044249, player_id, {268435456, 28, -1, -1})
                NET.FUNCTION.FIRE_EVENT(446749111, player_id, {268435456, 215802216, 0})
                NET.FUNCTION.FIRE_EVENT(446749111, player_id, {268435456, 485910709, 0})
                --S3
                NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {268435456, 1229862208, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1})
                NET.FUNCTION.FIRE_EVENT(2079562891, player_id, {268435456, 0, 2057341618})
                NET.FUNCTION.FIRE_EVENT(1214811719, player_id, {268435456, 1, 1, 1, 1109529053})
                NET.FUNCTION.FIRE_EVENT(1504695802, player_id, {268435456, 235638072})
                NET.FUNCTION.FIRE_EVENT(1932558939, player_id, {268435456, 0, 684012593})
                NET.FUNCTION.FIRE_EVENT(-800312339, player_id, {268435456, 0, 104810707})
                NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {268435456, 1173460779, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1})
                NET.FUNCTION.FIRE_EVENT(921195243, player_id, {268435456, 1813250283, 0})
                NET.FUNCTION.FIRE_EVENT(1925046697, player_id, {268435456, 517205817, 1})
                NET.FUNCTION.FIRE_EVENT(2079562891, player_id, {268435456, 0, 128935700})
                NET.FUNCTION.FIRE_EVENT(-69240130, player_id, {268435456, 0, 0, 1692553960})
                NET.FUNCTION.FIRE_EVENT(1318264045, player_id, {268435456, 0, 0, 0, 998776432, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1504695802, player_id, {268435456, 753411571})
                NET.FUNCTION.FIRE_EVENT(1638329709, player_id, {268435456, 0, 745958345, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-642704387, player_id, {268435456, -994541138, 0, 0, 0, 0, 0, 0, 0, 1061753153, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-904539506, player_id, {268435456, 223139413})
                NET.FUNCTION.FIRE_EVENT(630191280, player_id, {268435456, 328915838, 2022981644, 399920876, 0, 0, 1710220306, 0})
                NET.FUNCTION.FIRE_EVENT(921195243, player_id, {268435456, 955220948, 0})
                NET.FUNCTION.FIRE_EVENT(1925046697, player_id, {268435456, 1836776922, 1})
                NET.FUNCTION.FIRE_EVENT(728200248, player_id, {268435456, 1917787690, 1607765286})
                NET.FUNCTION.FIRE_EVENT(1214811719, player_id, {268435456, 1, 1, 1, 940704673})
                NET.FUNCTION.FIRE_EVENT(1318264045, player_id, {268435456, 0, 0, 0, 833649510, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1504695802, player_id, {268435456, 937423268})
                NET.FUNCTION.FIRE_EVENT(-1091407522, player_id, {268435456, 1, 1735203472})
                NET.FUNCTION.FIRE_EVENT(1638329709, player_id, {268435456, 0, 869049141, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1932558939, player_id, {268435456, 0, 340366740})
                NET.FUNCTION.FIRE_EVENT(-642704387, player_id, {268435456, -994541138, 0, 0, 0, 0, 0, 0, 0, 841957651, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-800312339, player_id, {268435456, 0, 797935737})
                NET.FUNCTION.FIRE_EVENT(630191280, player_id, {268435456, 1853073811, 576308009, 1416651674, 0, 0, 1335345922, 0})
                NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {268435456, 635702722, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1})
                NET.FUNCTION.FIRE_EVENT(-69240130, player_id, {268435456, 0, 0, 1807427078})
                NET.FUNCTION.FIRE_EVENT(1214811719, player_id, {268435456, 1, 1, 1, 458921163})
                NET.FUNCTION.FIRE_EVENT(1638329709, player_id, {268435456, 0, 577623592, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1932558939, player_id, {268435456, 0, 797647480})
                NET.FUNCTION.FIRE_EVENT(630191280, player_id, {268435456, 1269567919, 117455618, 2112734064, 0, 0, 2038512487, 0})
                NET.FUNCTION.FIRE_EVENT(921195243, player_id, {268435456, 280501093, 0})
                NET.FUNCTION.FIRE_EVENT(728200248, player_id, {268435456, 1194964156, 357230186})
                NET.FUNCTION.FIRE_EVENT(1318264045, player_id, {268435456, 0, 0, 0, 134219114, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1091407522, player_id, {268435456, 1, 808555509})
                NET.FUNCTION.FIRE_EVENT(1638329709, player_id, {268435456, 0, 619225562, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1932558939, player_id, {268435456, 0, 490765514})
                NET.FUNCTION.FIRE_EVENT(-800312339, player_id, {268435456, 0, 1066529362})
                NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {268435456, 1826118122, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1})
                NET.FUNCTION.FIRE_EVENT(1925046697, player_id, {268435456, 1974290499, 1})
                NET.FUNCTION.FIRE_EVENT(1214811719, player_id, {268435456, 1, 1, 1, 411497286})
                NET.FUNCTION.FIRE_EVENT(1318264045, player_id, {268435456, 0, 0, 0, 1809210831, 0, 0})
                NET.FUNCTION.FIRE_EVENT(-1091407522, player_id, {268435456, 1, 513813295})
                NET.FUNCTION.FIRE_EVENT(1638329709, player_id, {268435456, 0, 748216566, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1932558939, player_id, {268435456, 0, 1579964530})
                NET.FUNCTION.FIRE_EVENT(-642704387, player_id, {268435456, -994541138, 0, 0, 0, 0, 0, 0, 0, 2082664489, 0, 0, 0})
                --S4
                NET.FUNCTION.FIRE_EVENT(1269949700, player_id, {268435456, 0, 2147483647})
                NET.FUNCTION.FIRE_EVENT(-1547064369, player_id, {268435456, 0, 2147483647})
                NET.FUNCTION.FIRE_EVENT(-2122488865, player_id, {268435456, 0, 2147483647})
                NET.FUNCTION.FIRE_EVENT(-2026172248, player_id, {268435456, 0, 0, 0, 1})
                --MS3
                NET.FUNCTION.FIRE_EVENT(1450115979, player_id, {268435456, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                NET.FUNCTION.FIRE_EVENT(1450115979, player_id, {268435456})
                --MS8
                NET.FUNCTION.FIRE_EVENT(-1986344798, player_id, {268435456, 78335916, 0, 0})

                -- Was used in unfair, S3??
                NET.FUNCTION.FIRE_EVENT(1017995959, player_id, {27, 0})

                -- Mailbomb (S5)
                NET.FUNCTION.FIRE_EVENT(1450115979, player_id, {67108864, 122, 1})
            end,

            AGGRESSIVE = function(player_id)
                NET.FUNCTION.KICK_PLAYER(player_id)
            end,

            WRATH = function(player_id)
                local HostName = players.get_name(players.get_host())
                local TargetName = players.get_name(player_id)
        
                if players.get_name(players.user()) == HostName then -- If we are host
                    menu.trigger_commands("ban"..TargetName)
        
                elseif TargetName == HostName then -- If the player is host.
                    if NET.FUNCTION.IS_PLAYER_A_THREAT(player_id) then
                        util.toast("Aborting.. Target is host and has been recognized as a threat.\nConsider switching session.")
                        return
                    end
        
                    NET.FUNCTION.CRASH_PLAYER(player_id)
                    NET.FUNCTION.KICK_PLAYER(player_id)
        
                elseif TargetName ~= HostName then -- If the player isn't host
                    -- If we're next in line to get host
                    if players.get_host_queue_position(players.user()) == 1 and not NET.FUNCTION.IS_PLAYER_A_THREAT(players.get_host()) then
                        local Host = players.get_host()
                        NET.FUNCTION.CRASH_PLAYER(Host)
                        NET.FUNCTION.KICK_PLAYER(Host)

                        -- Perfect behavior expected.
                        repeat util.yield(1000) until not players.exists(Host) or not NET.FUNCTION.IS_NET_PLAYER_OK(players.user()) or not NET.FUNCTION.IS_NET_PLAYER_OK(player_id)
        
                        if players.get_host() == players.user() and players.exists(player_id) then
                            menu.trigger_commands("ban"..TargetName)
                        end
                    end
        
                    -- Any means necessary
                    if players.exists(player_id) then
                        NET.FUNCTION.CRASH_PLAYER(player_id)
                        NET.FUNCTION.KICK_PLAYER(player_id)
                    end
                end
            end,
        },

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
                    menu.trigger_commands("anticrashcam on")
                    local user = players.user()
                    local user_ped = players.user_ped()
                    local pos = players.get_position(user)
                    local cspped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                    local TPpos = ENTITY.GET_ENTITY_COORDS(cspped, true)
                    local cargobob = NET.FUNCTION.SPAWN_VEHICLE(0XFCFCB68B, TPpos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
                    local cargobobPos = ENTITY.GET_ENTITY_COORDS(cargobob, true)
                    local veh = NET.FUNCTION.SPAWN_VEHICLE(0X187D938D, TPpos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
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
                    for i = 1, 5 do
                        util.spoof_script("freemode", SYSTEM.util.yield)
                    end
                    ENTITY.SET_ENTITY_HEALTH(user_ped, 0)
                    NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x,pos.y,pos.z, 0, false, false, 0)
                    util.yield(2500)
                    entities.delete_by_handle(cargobob)
                    entities.delete_by_handle(veh)
                    PHYSICS.DELETE_CHILD_ROPE(newRope)
                    menu.trigger_commands("anticrashcam off")
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
                    NET.FUNCTION.CHANGE_PLAYER_MODEL(0x9C9EFFD8)
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

            ["2TAKE1"] = function(player_id) -- (T9) (S3) (NB)
                NET.FUNCTION.CRASH_PLAYER(player_id)
            end,

            WARHEAD = function(player_id) -- (N4)
                local TargetName = players.get_name(player_id)
                menu.trigger_commands("footlettuce"..TargetName)
                if players.get_vehicle_model(player_id) then
                    menu.trigger_commands("slaughter"..TargetName)
                end
            end,

            MORTAR = function(player_id) -- (XF) Crash Objects
                for next = 1, #NET.TABLE.CRASH_OBJECT do
                    if players.exists(player_id) then
                        local Current_Object_Hash = util.joaat(NET.TABLE.CRASH_OBJECT[next])
                        util.request_model(Current_Object_Hash)
                        local Current_Object = entities.create_object(Current_Object_Hash, players.get_position(player_id))
                        util.yield(100)
                        entities.delete_by_handle(Current_Object)
                    else
                        break
                    end
                end
            end,

            EXPRESS = function(player_id) -- (S3) (STAND'S ELEGANT CRASH)
                for next = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(-375628860, player_id, {1, math.random(-2147483647, 2147483647)})
                end
            end,

            DYNAMITE = function(player_id) -- (S2)
                menu.trigger_commands("givesh"..players.get_name(player_id))
                NET.FUNCTION.FIRE_EVENT(2067191610, player_id, {0, 0, -12988, -99097, 0})
                NET.FUNCTION.FIRE_EVENT(323285304, player_id, {0, 0, -12988, -99097, 0})
                NET.FUNCTION.FIRE_EVENT(495813132, player_id, {0, 0, -12988, -99097, 0})
                NET.FUNCTION.FIRE_EVENT(323285304, player_id, {323285304, 64, 2139114019, 14299, 40016, 11434, 4595, 25992})
            end,

            CHICKEN = function(player_id) -- (X9)
                local chicken_model = util.joaat("A_C_HEN") or 1794449327
                util.request_model(chicken_model)
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
                local chicken  = entities.create_ped(28, chicken_model, pos, 0)
                WEAPON.GIVE_WEAPON_TO_PED(chicken, -1813897027, 1, true, true)
                util.yield(1000)
                TASK.TASK_THROW_PROJECTILE(chicken, pos.x, pos.y, pos.z, 0, 0)
                util.yield(5000)
                entities.delete(chicken)
            end,

            -- Night
            PHANTOM = function(player_id) -- (XM) (A0:221) (A0:205) (A0:38) (A0:445) (A0:238) (A0:241) (A0:218)
                local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local veh = entities.get_all_vehicles_as_handles()
                for i = 1, #veh do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh[i])
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh[i], 0, 0, 5)
                    TASK.TASK_VEHICLE_TEMP_ACTION(player, veh[i], 18, 777)
                    TASK.TASK_VEHICLE_TEMP_ACTION(player, veh[i], 17, 888)
                    TASK.TASK_VEHICLE_TEMP_ACTION(player, veh[i], 16, 999)
                end
                local ped_task = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(player_id))
                ENTITY.FREEZE_ENTITY_POSITION(PLAYER.GET_PLAYER_PED(player_id), true)
                entities.create_object(0x9cf21e0f , ped_task, true, false) 
                local Rui_task = NET.FUNCTION.SPAWN_VEHICLE(util.joaat("Ruiner2"), ped_task, ENTITY.GET_ENTITY_HEADING(TTPed), true)
                local ped_task2 = entities.create_ped(26 , util.joaat("ig_kaylee"), ped_task, 0)
                for i = 0, 10 do
                    local pedps = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(player_id))
                    local allpeds = entities.get_all_peds_as_handles()
                    local allvehicles = entities.get_all_vehicles_as_handles()
                    local allobjects = entities.get_all_objects_as_handles()
                    local ownped = players.user_ped(players.user())
                    local models = {0x78BC1A3C, 0x000B75B9, 0x15F27762, 0x0E512E79}
                    local vehicles = {0xD6BC7523, 0x1F3D44B5, 0x2A72BEAB, 0x174CB172, 0x78BC1A3C, 0x0E512E79}
                    for next = 1, #models do
                        util.request_model(models[next])
                    end
                    for next = 1, #vehicles do
                        NET.FUNCTION.SPAWN_VEHICLE(vehicles[next], pedps, 0)
                    end
                    for i = 1, #allpeds do
                        if allpeds[i] ~= ownped then
                            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(allpeds[i], 0, 0, 0)
                        end
                    end
                    for i = 1, #allvehicles do
                        if allvehicles[i] ~= ownvehicle then
                            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(allvehicles[i], 0, 0, 0)
                            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(allvehicles[i], 0, 0, 0)
                            VEHICLE.SET_TAXI_LIGHTS(allvehicles[i])
                        end
                    end
                    for i = 1, #allobjects do
                        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(allobjects[i], 0, 0, 0)
                    end
                    util.yield()
                end
                PED.RESURRECT_PED(players.user_ped(player_id))
                util.yield(2000)
                entities.delete_by_handle(Rui_task)
                entities.delete_by_handle(ped_task2)
            end,

            SOUP = function(player_id) -- (XA)
                util.request_model(-1011537562)
                util.request_model(-541762431)
                local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
                local PED1  = entities.create_ped(28,-1011537562,pos,0)
                local PED2  = entities.create_ped(28,-541762431,pos,0)
                WEAPON.GIVE_WEAPON_TO_PED(PED1,-1813897027,1,true,true)
                WEAPON.GIVE_WEAPON_TO_PED(PED2,-1813897027,1,true,true)
                util.yield(1000)
                TASK.TASK_THROW_PROJECTILE(PED1,pos.x,pos.y,pos.z,0,0)
                TASK.TASK_THROW_PROJECTILE(PED2,pos.x,pos.y,pos.z,0,0)
                util.yield(5000)
                entities.delete(PED1)
                entities.delete(PED2)
            end,

            -- Ryze
            CHINESE = function(player_id) -- (X8) (X9)
                local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local mdl = util.joaat("cs_taostranslator2")
                while not STREAMING.HAS_MODEL_LOADED(mdl) do
                    STREAMING.REQUEST_MODEL(mdl)
                    util.yield(5)
                end
        
                local ped = {}
                for i = 1, 10 do 
                    local coord = ENTITY.GET_ENTITY_COORDS(player, true)
                    local pedcoord = ENTITY.GET_ENTITY_COORDS(ped[i], false)
                    ped[i] = entities.create_ped(0, mdl, coord, 0)
        
                    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped[i], 0xB1CA77B1, 0, true)
                    WEAPON.SET_PED_GADGET(ped[i], 0xB1CA77B1, true)
        
                    ENTITY.SET_ENTITY_VISIBLE(ped[i], true)
                    -- Set on fire
                    local pos = ENTITY.GET_ENTITY_COORDS(ped[i], false)
                    FIRE.ADD_EXPLOSION(pos.x, pos.y, pos.z, 3, 10.0, false, true, 1.0, false, false)
                    util.yield(25)
                end
                util.yield(2500)
                for i = 1, 10 do
                    entities.delete_by_handle(ped[i])
                    util.yield(25)
                end
            end,

            JESUS = function(player_id) -- (A2:456)
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local pos = players.get_position(player_id)
                local mdl = util.joaat("u_m_m_jesus_01")
                local veh_mdl = util.joaat("oppressor")
                util.request_model(veh_mdl)
                util.request_model(mdl)
                    for i = 1, 10 do
                        if not players.exists(player_id) then
                            return
                        end
                        local veh = entities.create_vehicle(veh_mdl, pos, 0)
                        local jesus = entities.create_ped(2, mdl, pos, 0)
                        PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
                        util.yield(100)
                        TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
                        util.yield(1000)
                        entities.delete_by_handle(jesus)
                        entities.delete_by_handle(veh)
                    end
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
            end,

            LAMP = function(player_id) -- (XJ)
                NET.FUNCTION.BLOCK_SYNCS(player_id, function()
                    local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                    OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    util.yield(1000)
                    entities.delete_by_handle(object)
                end)
            end,

            TASK = function(player_id) -- (A0:57)
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local user = PLAYER.GET_PLAYER_PED(players.user())
                local pos = ENTITY.GET_ENTITY_COORDS(ped)
                local my_pos = ENTITY.GET_ENTITY_COORDS(user)
                local anim_dict = ("anim@mp_player_intupperstinker")
                STREAMING.REQUEST_ANIM_DICT(anim_dict)
                NET.FUNCTION.BLOCK_SYNCS(player_id, function()
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, pos.x, pos.y, pos.z, false, false, false)
                    util.yield(100)
                    TASK.TASK_SWEEP_AIM_POSITION(user, anim_dict, "take that", "stupid", "fish", -1, 0.0, 0.0, 0.0, 0.0, 0.0)
                    util.yield(100)
                end)
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(user)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(user, my_pos.x, my_pos.y, my_pos.z, false, false, false)
            end,
        },

        SET_PROFILE_DEFAULT = function()
            menu.ref_by_path("Online>Protections>Host-Controlled Kicks>Love Letter Lube").value = 2

            local Profile = {
                {NET.TABLE.STAND.PLAYER[1], "off"}, -- godmode
                {NET.TABLE.STAND.PLAYER[2], "off"}, -- no ragdoll
    
                {NET.TABLE.STAND.SESSION[1], "on"}, -- seamless
                {NET.TABLE.STAND.SESSION[2], "on"}, -- skipbroadcast
                {NET.TABLE.STAND.SESSION[3], "on"}, -- speedupfmmc
                {NET.TABLE.STAND.SESSION[4], "on"}, -- speedupspawn
                {NET.TABLE.STAND.SESSION[5], "on"}, -- skipswoopdown
                {NET.TABLE.STAND.SESSION[6], "on"}, -- transitionhelper
                {NET.TABLE.STAND.SESSION[7], "on"}, -- showtransitionstate
                {NET.TABLE.STAND.SESSION[8], "on"}, -- lrnotify
                {NET.TABLE.STAND.SESSION[9], "on"}, -- autorejoindesynced
    
                {NET.TABLE.STAND.SPOOFING[1], "off"}, -- devflag
                {NET.TABLE.STAND.SPOOFING[2], "off"}, -- hosttokenspoofing
    
                {NET.TABLE.STAND.PROTECTION[1], "on"}, -- lessenhostkicks
                {NET.TABLE.STAND.PROTECTION[2], "on"}, -- notifyloveletter
                {NET.TABLE.STAND.PROTECTION[3], "off"}, -- desynckarma
                {NET.TABLE.STAND.PROTECTION[4], "off"}, -- novotekicks
                {NET.TABLE.STAND.PROTECTION[5], "on"}, -- blockjoinkarma
                {NET.TABLE.STAND.PROTECTION[6], "on"}, -- blockentityspam
                {NET.TABLE.STAND.PROTECTION[8], "off"}, -- nobeast
    
                {NET.TABLE.STAND.PROTECTION[7], "on"}, -- drawpatch
                {NET.TABLE.STAND.PROTECTION[9], "on"}, -- scripterrorrecovery
                {NET.TABLE.STAND.PROTECTION[10], "on"}, -- forcerelayconnections
                {NET.TABLE.STAND.GAME[1], "on"} -- svmreimpl
            }
    
            for next = 1, #Profile do
                menu.trigger_commands(Profile[next][1].." "..Profile[next][2])
            end
    
            -- [[ 0 = Disabled, 1 = Strangers, 2 = All ]]
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.RID_JOIN_REACT, 2, 0, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.VOTE_KICK_REACT, 2, nil, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.LOVE_LETTER_REACT, 0, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.REPORT_REACT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.PARTICLE_SPAM_REACT, 2, 2, 0, 0, 0, 0)
    
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP1_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP2_EVENT, 2, 2) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP3_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP4_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC1_EVENT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC2_EVENT, 2, 2, 0, 0, 0, 0) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC3_EVENT, 2, 2, 0, 0, 0, 0) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC4_EVENT, 2, 2, 0, 0, 0, 0)
            
            -- [[ 0 = Disabled, 1 = Strangers, 2 = Friends & Strangers, 3 = All ]]
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CRASH_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MODDED_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.UNUSUAL_EVENT, 3, 3)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CAMERA_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.FREEMODE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.TP_INTERIOR_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RP_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RP_BOSS_EVENT, 3, 3, 0, 0, 0, 0) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MC_KICK_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SCREEN_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PHONE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.JOB_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.TAKEOVER_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.DISABLE_DRIVING_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_VEHICLE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_INTERIOR_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.FREEZE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SHAKE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.EXPLO_SPAM_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RAGDOLL_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MODDED_DAMAGE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.REMOVE_WEAPON_EVENT, 3, 3, 0, 0, 0, 0)
        end,

        SET_PROFILE_STRICT = function()
            menu.ref_by_path("Online>Protections>Host-Controlled Kicks>Love Letter Lube").value = 1

            local Profile = {
                {NET.TABLE.STAND.PLAYER[1], "off"}, -- godmode
                {NET.TABLE.STAND.PLAYER[2], "on"}, -- no ragdoll
    
                {NET.TABLE.STAND.SESSION[1], "on"}, -- seamless
                {NET.TABLE.STAND.SESSION[2], "on"}, -- skipbroadcast
                {NET.TABLE.STAND.SESSION[3], "on"}, -- speedupfmmc
                {NET.TABLE.STAND.SESSION[4], "on"}, -- speedupspawn
                {NET.TABLE.STAND.SESSION[5], "on"}, -- skipswoopdown
                {NET.TABLE.STAND.SESSION[6], "on"}, -- transitionhelper
                {NET.TABLE.STAND.SESSION[7], "on"}, -- showtransitionstate
                {NET.TABLE.STAND.SESSION[8], "on"}, -- lrnotify
                {NET.TABLE.STAND.SESSION[9], "on"}, -- autorejoindesynced
    
                {NET.TABLE.STAND.SPOOFING[1], "off"}, -- devflag
                {NET.TABLE.STAND.SPOOFING[2], "off"}, -- hosttokenspoofing
    
                {NET.TABLE.STAND.PROTECTION[1], "on"}, -- lessenhostkicks
                {NET.TABLE.STAND.PROTECTION[2], "on"}, -- notifyloveletter
                {NET.TABLE.STAND.PROTECTION[3], "on"}, -- desynckarma
                {NET.TABLE.STAND.PROTECTION[4], "sctv"}, -- novotekicks
                {NET.TABLE.STAND.PROTECTION[5], "on"}, -- blockjoinkarma
                {NET.TABLE.STAND.PROTECTION[6], "on"}, -- blockentityspam
                {NET.TABLE.STAND.PROTECTION[8], "on"}, -- nobeast
    
                {NET.TABLE.STAND.PROTECTION[7], "on"}, -- drawpatch
                {NET.TABLE.STAND.PROTECTION[9], "on"}, -- scripterrorrecovery
                {NET.TABLE.STAND.PROTECTION[10], "on"}, -- forcerelayconnections
                {NET.TABLE.STAND.GAME[1], "on"} -- svmreimpl
            }
    
            for next = 1, #Profile do
                menu.trigger_commands(Profile[next][1].." "..Profile[next][2])
            end
    
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.RID_JOIN_REACT, 2, 1, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.VOTE_KICK_REACT, 2, nil, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.LOVE_LETTER_REACT, 0, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.REPORT_REACT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.PARTICLE_SPAM_REACT, 2, 2, 0, 0, 0, 0)
            --
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP1_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP2_EVENT, 2, 2) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP3_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP4_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC1_EVENT, 2, 2, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC2_EVENT, 2, 2, 1, 0, 0, 0) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC3_EVENT, 2, 2, 1, 0, 0, 0) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC4_EVENT, 2, 2, 1, 0, 0, 0)
            --
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CRASH_EVENT, 3, 3, 1, 1, 1, 1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_EVENT, 3, 3, 1, 1, 1, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MODDED_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.UNUSUAL_EVENT, 3, 3)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CAMERA_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.FREEMODE_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.TP_INTERIOR_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RP_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RP_BOSS_EVENT, 3, 3, 0, 0, 0, 0) 
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MC_KICK_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SCREEN_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PHONE_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.JOB_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.TAKEOVER_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.DISABLE_DRIVING_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_VEHICLE_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_INTERIOR_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.FREEZE_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SHAKE_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.EXPLO_SPAM_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RAGDOLL_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MODDED_DAMAGE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.REMOVE_WEAPON_EVENT, 3, 3, 1, 0, 0, 0)
        end,

        SET_PROFILE_WARRIOR = function()
            menu.trigger_commands("spoofedhosttoken 0000000000000000")
            menu.ref_by_path("Online>Protections>Host-Controlled Kicks>Love Letter Lube").value = 0
    
            local Profile = {
                {NET.TABLE.STAND.PLAYER[1], "on"}, -- godmode
                {NET.TABLE.STAND.PLAYER[2], "on"}, -- no ragdoll
    
                {NET.TABLE.STAND.SESSION[1], "on"}, -- seamless
                {NET.TABLE.STAND.SESSION[2], "on"}, -- skipbroadcast
                {NET.TABLE.STAND.SESSION[3], "on"}, -- speedupfmmc
                {NET.TABLE.STAND.SESSION[4], "on"}, -- speedupspawn
                {NET.TABLE.STAND.SESSION[5], "on"}, -- skipswoopdown
                {NET.TABLE.STAND.SESSION[6], "on"}, -- transitionhelper
                {NET.TABLE.STAND.SESSION[7], "on"}, -- showtransitionstate
                {NET.TABLE.STAND.SESSION[8], "on"}, -- lrnotify
                {NET.TABLE.STAND.SESSION[9], "on"}, -- autorejoindesynced
    
                {NET.TABLE.STAND.SPOOFING[1], "on"}, -- devflag
                {NET.TABLE.STAND.SPOOFING[2], "on"}, -- hosttokenspoofing
    
                {NET.TABLE.STAND.PROTECTION[1], "on"}, -- lessenhostkicks
                {NET.TABLE.STAND.PROTECTION[2], "on"}, -- notifyloveletter
                {NET.TABLE.STAND.PROTECTION[3], "on"}, -- desynckarma
                {NET.TABLE.STAND.PROTECTION[4], "sctv"}, -- novotekicks
                {NET.TABLE.STAND.PROTECTION[5], "on"}, -- blockjoinkarma
                {NET.TABLE.STAND.PROTECTION[6], "on"}, -- blockentityspam
                {NET.TABLE.STAND.PROTECTION[8], "on"}, -- nobeast
    
                {NET.TABLE.STAND.PROTECTION[7], "on"}, -- drawpatch
                {NET.TABLE.STAND.PROTECTION[9], "on"}, -- scripterrorrecovery
                {NET.TABLE.STAND.PROTECTION[10], "on"}, -- forcerelayconnections
                {NET.TABLE.STAND.GAME[1], "on"} -- svmreimpl
            }
    
            for next = 1, #Profile do
                menu.trigger_commands(Profile[next][1].." "..Profile[next][2])
            end
    
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.RID_JOIN_REACT, 2, 0, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.VOTE_KICK_REACT, 2, nil, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.LOVE_LETTER_REACT, 0, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.REPORT_REACT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.REACTION.PARTICLE_SPAM_REACT, 2, 2, 0, 0, 0, 0)
            --
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP1_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP2_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP3_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PICKUP4_EVENT, 2, 2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC1_EVENT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC2_EVENT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC3_EVENT, 2, 2, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SYNC4_EVENT, 2, 2, 0, 0, 0, 0)
            --
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CRASH_EVENT, 3, 3, 1, 1, 1, 1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_EVENT, 3, 3, 1, 1, 1, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MODDED_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.UNUSUAL_EVENT, 3, 3)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CAMERA_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.FREEMODE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.TP_INTERIOR_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RP_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RP_BOSS_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MC_KICK_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SCREEN_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.PHONE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.JOB_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.TAKEOVER_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.DISABLE_DRIVING_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_VEHICLE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_INTERIOR_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.FREEZE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.SHAKE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.EXPLO_SPAM_EVENT, 3, 3, 1, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.RAGDOLL_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.MODDED_DAMAGE_EVENT, 3, 3, 0, 0, 0, 0)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.REMOVE_WEAPON_EVENT, 3, 3, 1, 0, 0, 0)
        end,

        HOST_ADDICT = function()
            if NET.FUNCTION.IS_NET_PLAYER_OK(players.user()) then
                if players.get_host() ~= players.user() then
                    if players.get_host_queue_position(players.user()) == 1 and not NET.FUNCTION.IS_PLAYER_A_THREAT(players.get_host()) then
                        local Current_Host = players.get_host()
                        if NET.VARIABLE.Host_Addict_Kick_Cooldown == 15 then
                            if players.exists(Current_Host) then
                                NET.FUNCTION.KICK_PLAYER(Current_Host)
                            else
                                NET.VARIABLE.Host_Addict_Kick_Cooldown = 0
                            end
                            NET.VARIABLE.Host_Addict_Kick_Cooldown = 0
                        else
                            NET.VARIABLE.Host_Addict_Kick_Cooldown = NET.VARIABLE.Host_Addict_Kick_Cooldown + 1
                        end
                    else
                        -- Server hopping with the best settings.
                        menu.trigger_commands("spoofedhosttoken 0000000000000000")
                        menu.trigger_commands("hosttokenspoofing on")
                        menu.trigger_commands("playermagnet 30")
                        menu.trigger_commands("go public")
                    end
                elseif players.get_host() == players.user() and #players.list() < 2 then
                    menu.trigger_commands("go public")
                end
            end
        end,

        BECOME_HOST = function()
            if players.get_host() == players.user() then
                util.toast("You are already Host.")
            end
        
            -- do we qualify?
            if players.get_host_queue_position(players.user()) == 1 then
                if NET.FUNCTION.IS_PLAYER_A_THREAT(players.get_host()) then
                    util.toast("High risk of karma, please kick player manually if you wish to continue.")
                else
                    util.toast("Removing player...")
                    NET.FUNCTION.KICK_PLAYER(players.get_host())
                end
            else
                util.toast("You do not qualify to become host.")
            end
        end,

        BECOME_SCRIPT_HOST = function()
            if players.get_script_host() ~= players.user() and NET.FUNCTION.IS_NET_PLAYER_OK(players.user()) then
                menu.trigger_commands("scripthost")
            end
        end,

        MUTE_STAND_REACTION_NOTIFICATIONS = function(Enabled)
            local Result1 = Enabled and 0 or 2
            local Result2 = Enabled and 0 or 3 
        
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Reactions.RID_JOIN_REACT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Reactions.VOTE_KICK_REACT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Reactions.REPORT_REACT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Reactions.PARTICLE_SPAM_REACT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.PICKUP1_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.PICKUP2_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.PICKUP3_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.PICKUP4_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.SYNC1_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.SYNC2_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.SYNC3_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.SYNC4_EVENT, Result1)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.CRASH_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.KICK_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.MODDED_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.UNUSUAL_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.CAMERA_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.FREEMODE_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.TP_INTERIOR_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.RP_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.RP_BOSS_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.MC_KICK_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.SCREEN_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.PHONE_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.JOB_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.TAKEOVER_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.DISABLE_DRIVING_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.KICK_VEHICLE_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.KICK_INTERIOR_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.FREEZE_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.SHAKE_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.EXPLO_SPAM_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.RAGDOLL_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.MODDED_DAMAGE_EVENT, Result2)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(Commands.Protections.REMOVE_WEAPON_EVENT, Result2)
        end,

        DISABLE_STAND_REACTIONS = function(Enabled)
            local Result = Enabled and 0 or 2

            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.CRASH_EVENT, nil, nil, Result, Result, Result, Result)
            NET.FUNCTION.CHANGE_MENU_REACTIONS(NET.TABLE.STAND.PROTECTION.KICK_EVENT, nil, nil, Result, Result, Result)
        end,

        SMOKESCREEN_PLAYER = function(player_id, Enabled)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_as_trans")
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_as_trans")
            if ptfx == nil or not GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(ptfx) then
                ptfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY("scr_as_trans_smoke", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, false, false, false, 0, 0, 0, 255)
            end
        end,

        GLITCH_PLAYER = function(player_id, toggled)
            NET.VARIABLE.Is_Busy_Glitching = toggled

            while NET.VARIABLE.Is_Busy_Glitching do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
                if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(player_id)) > 1000.0 
                and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
                    util.toast("Player too far away. :c")
                    menu.set_value(NET.VARIABLE.Glitch_Toggle, false);
                break end
    
                if not players.exists(player_id) then 
                    util.toast("Player does not exist. :c")
                    menu.set_value(NET.VARIABLE.Glitch_Toggle, false);
                break end
                local glitch_hash = NET.VARIABLE.Object_Hash
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
                util.yield(delay)
                entities.delete_by_handle(stupid_object)
                entities.delete_by_handle(glitch_vehicle)
                util.yield(delay)    
            end
        end,

        KICK_PLAYERS = function()
            local ToKick = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToKick do
                if players.exists(ToKick[next]) then
                    local PlayerName = players.get_name(ToKick[next])
                    if NET.VARIABLE.Kick_Method == 1 then -- Backstab / (S0)
                        NET.COMMAND.KICK.BACKSTAB(ToKick[next])
                    elseif NET.VARIABLE.Kick_Method == 2 then -- Host Kick / Votekick
                        menu.trigger_commands("hostkick"..PlayerName)
                    elseif NET.VARIABLE.Kick_Method == 3 then -- Ban / "Player has been removed for cheating"
                        menu.trigger_commands("ban"..PlayerName)
                    elseif NET.VARIABLE.Kick_Method == 4 then -- Desync Kick
                        menu.trigger_commands("blacklist"..PlayerName)
                    end
                end
        
                util.yield(100)
            end
        end,

        CRASH_PLAYERS = function()
            local ToCrash = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToCrash do
                if players.exists(ToCrash[next]) then
                    local PlayerName = players.get_name(ToCrash[next])
                    if NET.VARIABLE.Crash_Method == 1 then -- Express
                        NET.COMMAND.CRASH.EXPRESS(ToCrash[next])
                    elseif NET.VARIABLE.Crash_Method == 2 then -- Dynamite
                        NET.COMMAND.CRASH.DYNAMITE(ToCrash[next])
                    elseif NET.VARIABLE.Crash_Method == 3 then -- Elegant
                        menu.trigger_commands("crash"..PlayerName)
                    end
                end
        
                util.yield(100)
            end
        end,

        GIVE_PLAYER_RP = function(player_id, delay)
            local GIVE_COLLECTIBLE = function(player_id, i)
                if players.get_rank(player_id) >= NET.VARIABLE.To_Level_Up_To then return end
                NET.FUNCTION.FIRE_EVENT(968269233, player_id, {players.user(), 4, i, 1, 1, 1})
            end

            if not delay then delay = 5 end

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

        SPECTATE_PLAYER = function(player_id, Enabled)
            if Enabled then
                menu.trigger_commands("spectate"..players.get_name(player_id).." on")
            else
                menu.trigger_commands("spectate"..players.get_name(player_id).." off")
            end
        end,

        FAKE_MONEY_DROP = function(player_id, Enabled)
            local TargetName = players.get_name(player_id)
            if Enabled then
                menu.trigger_commands("fakemoneydrop"..TargetName.." on")
            else
                menu.trigger_commands("fakemoneydrop"..TargetName.." off")
            end
        end,

        STUMBLE_PLAYER = function(player_id)
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
                NET.VARIABLE.Vents[i] = entities.create_object(mdl, obj_pos)
                ENTITY.SET_ENTITY_VISIBLE(NET.VARIABLE.Vents[i], false)
            end
            util.yield(500)
            entities.delete(middleVent)
            for i, obj in pairs(NET.VARIABLE.Vents) do
                entities.delete(obj)
            end
        end,

        LAUNCH_PLAYER = function(player_id)
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
        end,

        MONEY_DROP = function(Enabled)
            if Enabled then
                menu.trigger_commands("figurinesall on")
                menu.trigger_commands("ceopayall on")
            else
                menu.trigger_commands("figurinesall off")
                menu.trigger_commands("ceopayall off")
            end
        end,

        MONEY_DROP_PLAYER = function(player_id, Enabled)
            local TargetName = players.get_name(player_id)
            if Enabled then
                menu.trigger_commands("figurines"..TargetName.." on")
                menu.trigger_commands("ceopay"..TargetName.." on")
            else
                menu.trigger_commands("figurines"..TargetName.." off")
                menu.trigger_commands("ceopay"..TargetName.." off")
            end
        end,

        EXPAND_ALL_HITBOXES = function()
            for i, player_id in pairs(players.list_except()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local pPed =  entities.handle_to_pointer(ped)
                local pedPtr = entities.handle_to_pointer(players.user_ped())
                local wpn = WEAPON.GET_SELECTED_PED_WEAPON(players.user_ped())
                local dmg = WEAPON.GET_WEAPON_DAMAGE(wpn, 0)
                if PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(players.user(), ped) and PED.IS_PED_SHOOTING(players.user_ped()) and not NETWORK.IS_ENTITY_A_GHOST(ped) then
                    boneIndex = NET.TABLE.BONE[math.random(#NET.TABLE.BONE)]
                    local boneCoords = PED.GET_PED_BONE_COORDS(ped, boneIndex, 0.0, 0.0, 0.0)
                    util.call_foreign_function(memory.rip(memory.scan("E8 ? ? ? ? 44 8B 65 80 41 FF C7") + 1), pedPtr, pPed, boneCoords, 0, 1, wpn, dmg, 0, 0, 1 << 0 | 1 << 9 | 1 << 19, 0, 0, 0, 0, 0, 0, 0, 0.0)
                end
            end
        end,

        VEH_ROCKET_AIMBOT = function()
            for i, player_id in pairs(players.list_except(true)) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                local pedDistance = v3.distance(players.get_position(players.user()), players.get_position(player_id))
                if not PLAYER.IS_PLAYER_DEAD(ped) and PAD.IS_CONTROL_PRESSED(0, 70) and pedDistance < 250.0 and not players.is_in_interior(player_id) and VEHICLE.GET_VEHICLE_HOMING_LOCKON_STATE(entities.get_user_vehicle_as_handle()) == 0 then
                    local pos = players.get_position(player_id)
                    VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(players.user_ped(), ped, pos.X, pos.Y, pos.Z)
                end
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

        TOGGLE_RADIO = function()
            local ped = players.user_ped()
            if NET.VARIABLE.Party_Bus == nil then
                local offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.5)
                local hash = util.joaat("pbus2")
                util.request_model(hash)
                NET.VARIABLE.Party_Bus = entities.create_vehicle(hash, offset, 0)
                entities.set_can_migrate(NET.VARIABLE.Party_Bus, false)
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(NET.VARIABLE.Party_Bus, false, false)
                ENTITY.SET_ENTITY_INVINCIBLE(NET.VARIABLE.Party_Bus, true)
                ENTITY.FREEZE_ENTITY_POSITION(NET.VARIABLE.Party_Bus, true)
                ENTITY.SET_ENTITY_VISIBLE(NET.VARIABLE.Party_Bus, false, 0)
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(NET.VARIABLE.Party_Bus, true, true)
                local ped_hash = util.joaat("a_m_y_acult_02")
                util.request_model(ped_hash)
                local driver = entities.create_ped(1, ped_hash, offset, 0)
                PED.SET_PED_INTO_VEHICLE(driver, NET.VARIABLE.Party_Bus, -1)
                VEHICLE.SET_VEHICLE_ENGINE_ON(NET.VARIABLE.Party_Bus, true, true, false)
                VEHICLE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(NET.VARIABLE.Party_Bus, true)
                util.yield(500)
                AUDIO.SET_VEH_RADIO_STATION(NET.VARIABLE.Party_Bus, NET.VARIABLE.Selected_Loud_Radio)
                util.yield(500)
                TASK.TASK_LEAVE_VEHICLE(driver, NET.VARIABLE.Party_Bus, 16)
                entities.delete(driver)
            else
                local offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.0, 3.5)
                ENTITY.SET_ENTITY_COORDS(NET.VARIABLE.Party_Bus, offset.x, offset.y, offset.z, false, false, false, false)
                AUDIO.SET_VEH_RADIO_STATION(NET.VARIABLE.Party_Bus, NET.VARIABLE.Selected_Loud_Radio)
                entities.request_control(NET.VARIABLE.Party_Bus)
            end
        end,

        HELPFUL_EVENTS = function(player_id, Enabled)
            local TargetName = players.get_name(player_id)
            local Commands = {"autoheal", "bail", "giveotr", "givevehgod"}
            for next = 1, #Commands do
                menu.trigger_commands(Commands[next]..TargetName..(Enabled and " on" or " off"))
                util.yield(100)
            end
        end,

        FIX_LOADING_SCREEN = function(player_id)
            local TargetName = players.get_name(player_id)
            menu.trigger_commands("givesh"..TargetName)
            menu.trigger_commands("aptme"..TargetName)
        end,

        GIVE_SCRIPT_HOST = function(player_id)
            local TargetName = players.get_name(player_id)
            menu.trigger_commands("givesh"..TargetName)
        end,

        SESSION_OVERLAY = function(Enabled)
            local Commands = {"infotime", "infotps", "infoplayers", "infowhospectateswho", "infomodder", "infohost", "infonexthost", "infoscripthost"}
            for next = 1, #Commands do
                menu.trigger_commands(Commands[next].. (Enabled and " on" or " off"))
                util.yield(100)
            end
        end,

        RIG_CASINO = function(Enabled)
            if Enabled then
                menu.trigger_commands("rigblackjack on")
                menu.trigger_commands("rigroulette 1")
            else
                menu.trigger_commands("rigblackjack off")
                menu.trigger_commands("rigroulette -1")
            end
        end,

        GIVE_PLAYER_FREEBIES = function(player_id, Enabled)
            local Player_Name = players.get_name(player_id)
            menu.trigger_commands("commendhelpful"..Player_Name)
            menu.trigger_commands("commendfriendly"..Player_Name)
            NET.FUNCTION.TRIGGER_GIVE_ALL_COLLECTIBLES(player_id)
            menu.trigger_commands("arm"..Player_Name.."all")
            menu.trigger_commands("ceopay"..Player_Name..(Enabled and " on" or " off"))
        end,

        FREEBIES = function(Enabled)
            menu.trigger_commands("rplobby "..(Enabled and "on" or "off"))
            
            local ToGive = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
            for next = 1, #ToGive do
                if players.exists(ToGive[next]) then
                    NET.COMMAND.GIVE_PLAYER_FREEBIES(ToGive[next], Enabled)
                    util.yield(100)
                end
            end
        end,

        GIVE_PLAYERS_RP = function()
            local ToGive = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToGive do
                if players.exists(ToGive[next]) then
                    NET.COMMAND.GIVE_PLAYER_RP(ToGive[next], 0)
                end
            end
        end,

        GHOST_PLAYERS = function(Enabled)
            local ToGhost = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToGhost do
                if players.exists(ToGhost[next]) then
                    NETWORK.SET_REMOTE_PLAYER_AS_GHOST(ToGhost[next], Enabled)
                end
            end

            NET.VARIABLE.Auto_Ghost = Enabled
        end,

        SUMMON_PLAYERS = function()
            local ToTP = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToTP do
                if players.exists(ToTP[next]) then
                    if NET.VARIABLE.Ignore_Interior and players.is_in_interior(ToTP[next]) then return end
                    menu.trigger_commands("tp"..players.get_name(ToTP[next]))
                end
            end
        end,

        TELEPORT_PLAYERS_TO_WAYPOINT = function()
            local ToTP = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToTP do
                if players.exists(ToTP[next]) then
                    if NET.VARIABLE.Ignore_Interior and players.is_in_interior(ToTP[next]) then return end
                    menu.trigger_commands("wpsummon"..players.get_name(ToTP[next]))
                end
            end
        end,

        TELEPORT_PLAYERS_TO_CASINO = function()
            local ToTP = NET.FUNCTION.GET_PLAYERS_FROM_SELECTION()
        
            for next = 1, #ToTP do
                if players.exists(ToTP[next]) then
                    if NET.VARIABLE.Ignore_Interior and  players.is_in_interior(ToTP[next]) then return end
                    menu.trigger_commands("casinotp"..players.get_name(ToTP[next]))
                end
            end
        end,

        PACIFY_PLAYER = function(player_id, Enabled)
            local TargetName = players.get_name(player_id)
            if Enabled then
                menu.trigger_commands("disarm"..TargetName.." on")
                menu.trigger_commands("nopassivemode"..TargetName.." on")
                menu.trigger_commands("mission"..TargetName)
                menu.trigger_commands("novehs"..TargetName)
            else
                menu.trigger_commands("disarm"..TargetName.." off")
                menu.trigger_commands("nopassivemode"..TargetName.." off")
            end
        end,

        LOCK_ONTO_PLAYERS = function()
            for i, player_id in pairs(players.list_except(true)) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                PLAYER.ADD_PLAYER_TARGETABLE_ENTITY(players.user(), ped)
                ENTITY.SET_ENTITY_IS_TARGET_PRIORITY(ped, false, 400.0)    
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

        PUNISH_SPECTATORS = function()
            if NET.VARIABLE.Spectate_Loop then
                for players.list_except() as player_id do
                    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
                    local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
                    local cam_dist = v3.distance(players.get_position(players.user()), players.get_cam_pos(player_id))
                    local pedDistance = v3.distance(players.get_position(players.user()), players.get_position(player_id))
                    local spectateTarget = players.get_spectate_target(player_id)
                    local driver = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1))
                    if NET.FUNCTION.IS_NET_PLAYER_OK(player_id, true, true) then
                        if PED.IS_PED_IN_ANY_VEHICLE(ped) and driver == player_id then
                            return
                        end
                        if cam_dist < 15.0 and pedDistance > 50.0 and not NET.FUNCTION.IS_SPECTATING(player_id) and spectateTarget == -1 and not NETWORK.NETWORK_IS_PLAYER_IN_MP_CUTSCENE(player_id) or spectateTarget == players.user()  then
                            util.toast(players.get_name(player_id).." is spectating you.")
                            menu.trigger_commands("timeout"..players.get_name(player_id).." on")
                            break
                        end
                    end
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

        VANITY_PARTICLES = function(player_id, index)
            local PTFX = {"hacklol", "scr_sum2_hal_hunted_respawn", "scr_sum2_hal_rider_weak_blue", "scr_sum2_hal_rider_weak_green", "scr_sum2_hal_rider_weak_orange", "scr_sum2_hal_rider_weak_greyblack"}
            local player_pos = players.get_position(player_id)
            local ptfx = ((index == nil or index == 1) and PTFX[math.random(1, #PTFX)]) or PTFX[index]
            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sum2_hal")
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sum2_hal")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfx, player_pos.x, player_pos.y, player_pos.z, 0, 0, 0, 2.5, false, false, false)
            util.yield(200)
        end,
    },

    PROFILE = {}, -- Menu Profiles

    CREATE_NET_PROFILE = function(player_id)
        if NET.VARIABLE.Players_To_Affect == 2 and not players.is_marked_as_modder(player_id) then return end
        if NET.VARIABLE.Players_To_Affect == 4 and players.is_marked_as_modder(player_id) then return end
        NET.VARIABLE.Players_Count = NET.VARIABLE.Players_Count + 1
        NET.PROFILE[tostring(player_id)] = {}
        NET.PROFILE[tostring(player_id)].Menu = menu.list(PLAYERS_LIST, players.get_name(player_id), {}, "")

        local MenuBuffer = NET.PROFILE[tostring(player_id)].Menu

        util.create_thread(function()
            while true do
                if IS_CLOSING or not players.exists(player_id) then break end
                if NET.PROFILE[tostring(player_id)] then
                    if menu.is_ref_valid(menu.player_root(player_id)) then
                        local Country = tostring(menu.ref_by_rel_path(menu.player_root(player_id), "Information>Connection>Country").value)
                        local Region = tostring(menu.ref_by_rel_path(menu.player_root(player_id), "Information>Connection>Region").value)
                        local City = tostring(menu.ref_by_rel_path(menu.player_root(player_id), "Information>Connection>City").value)
                        menu.set_help_text(NET.PROFILE[tostring(player_id)].Menu,
                        "Location: "..City..", "..Region..", "..Country
                        .."\nRank: "..tostring(players.get_rank(player_id))
                        .."\nMoney: $"..tostring(NET.FUNCTION.FORMAT_NUMBER(players.get_money(player_id)))
                        .."\nK/D: "..tostring(players.get_kd(player_id))
                    )
                    end
                end
                util.yield(1000)
            end
            util.stop_thread()
        end)

        menu.toggle(NET.PROFILE[tostring(player_id)].Menu, "Pacify", {}, "Blocked by most menus, will also most likely ruin the player's scripts.", function(Enabled) NET.COMMAND.PACIFY_PLAYER(player_id, Enabled) end)
        local MODERATE_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Moderate")
        local KICK_OPTIONS = menu.list(MODERATE_LIST, "Kicks")
        menu.action(KICK_OPTIONS, "[STAND] Wrath Kick", {"wkick"}, "Will try to get host to kick target if available. If not, will fallback onto Aggressive Kick.", function() NET.COMMAND.KICK.WRATH(player_id) end)
        menu.action(KICK_OPTIONS, "[STAND] Aggressive Kick", {"akick"}, "Unblockable if target isn't host & detected as a threat.", function() NET.COMMAND.KICK.AGGRESSIVE(player_id) end)
        menu.action(KICK_OPTIONS, "[STAND] Love Letter Kick", {}, "Discrete and unblockable.\nCannot be used against host.\nUnblockable when you are host.", function() menu.trigger_commands("loveletterkick"..players.get_name(player_id)) end)
        menu.action(KICK_OPTIONS, "[STAND] Host Kick", {}, "Very effective against modders with protections.\nUnblockable when you are host.", function() menu.trigger_commands("hostkick"..players.get_name(player_id)) end)
        menu.action(KICK_OPTIONS, "[NET] Airstrike Kick", {"airkick"}, "Blocked by popular menus.", function() NET.COMMAND.KICK.AIRSTRIKE(player_id) end)
        menu.action(KICK_OPTIONS, "[NET] Backstab Kick", {"stabkick"}, "Blocked by most menus.", function() NET.COMMAND.KICK.BACKSTAB(player_id) end)
        menu.action(KICK_OPTIONS, "[ADDICT] Eviction Notice", {"ekick"}, "Blocked by most menus.", function() NET.COMMAND.KICK.EVICTION_NOTICE(player_id) end)
        menu.action(KICK_OPTIONS, "[STAND] Pool's Closed Kick", {}, "Blocked by popular menus.", function() menu.trigger_commands("aids"..players.get_name(player_id)) end)
        local CRASH_OPTIONS = menu.list(MODERATE_LIST, "Crashes")
        menu.action(CRASH_OPTIONS, "[STAND] 2Take1 Crash", {"2t1crash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH["2TAKE1"](player_id) end)
        menu.action(CRASH_OPTIONS, "[STAND] Warhead Crash", {"warcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.WARHEAD(player_id) end)
        menu.action(CRASH_OPTIONS, "[NET] Mortar Crash", {""}, "Blocked by most menus.", function() NET.COMMAND.CRASH.MORTAR(player_id) end)
        menu.action(CRASH_OPTIONS, "[NET] Express Crash", {"xpresscrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.ELEGANT(player_id) end)
        menu.action(CRASH_OPTIONS, "[NET] Dynamite Crash", {"dcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.DYNAMITE(player_id) end)
        menu.action(CRASH_OPTIONS, "[NET] Chicken Crash", {"hencrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.CHICKEN(player_id) end)
        menu.action(CRASH_OPTIONS, "[NIGHT] Phantom Crash", {"phantomcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.PHANTOM(player_id) end)
        menu.action(CRASH_OPTIONS, "[NIGHT] Soup Crash", {"soupcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SOUP(player_id) end)
        menu.action(CRASH_OPTIONS, "[RYZE] Chinese Crash", {"ccrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.CHINESE(player_id) end)
        menu.action(CRASH_OPTIONS, "[RYZE] Jesus Crash", {"jcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.JESUS(player_id) end)
        menu.action(CRASH_OPTIONS, "[RYZE] Lamp Crash", {"lcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.LAMP(player_id) end)
        menu.action(CRASH_OPTIONS, "[RYZE] Task Crash", {"tcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.TASK(player_id) end)
        local TROLLING_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Trolling")
        menu.toggle_loop(TROLLING_LIST, "Smokescreen", {""}, "Fills up their screen with black smoke.", function() NET.COMMAND.SMOKESCREEN_PLAYER(player_id) end, function() local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) GRAPHICS.REMOVE_PARTICLE_FX(ptfx) STREAMING.REMOVE_NAMED_PTFX_ASSET("scr_as_trans") end)
        menu.toggle_loop(TROLLING_LIST, "Launch Player", {""}, "", function() NET.COMMAND.LAUNCH_PLAYER(player_id) end, function() if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then entities.delete(veh) end end)
        menu.toggle_loop(TROLLING_LIST, "Stumble Player", {""}, "", function() NET.COMMAND.STUMBLE_PLAYER(player_id) end)
        local PROP_GLITCH_LIST = menu.list(TROLLING_LIST, "Prop Glitch Loop")
        menu.list_select(PROP_GLITCH_LIST, "Object", {""}, "Object to glitch the player.", NET.TABLE.GLITCH_OBJECT.NAME, 1, function(index) NET.VARIABLE.Object_Hash = util.joaat(NET.TABLE.GLITCH_OBJECT.OBJECT[index]) end)
        menu.slider(PROP_GLITCH_LIST, "Spawn delay", {""}, "", 0, 3000, 50, 10, function(amount) delay = amount end)
        menu.toggle(PROP_GLITCH_LIST, "Glitch player", {}, "", function(toggled) NET.COMMAND.GLITCH_PLAYER(player_id, toggled) end)
        local NEUTRAL_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Neutral")
        menu.toggle(NEUTRAL_LIST, "Spectate", {}, "", function(Enabled) NET.COMMAND.SPECTATE_PLAYER(player_id, Enabled) end)
        menu.toggle_loop(NEUTRAL_LIST, "Ghost Player", {""}, "", function() NETWORK.SET_REMOTE_PLAYER_AS_GHOST(player_id, true) end, function() NETWORK.SET_REMOTE_PLAYER_AS_GHOST(player_id, false) end)
        menu.toggle(NEUTRAL_LIST, "Fake Money Drop", {""}, "", function(Enabled) NET.COMMAND.FAKE_MONEY_DROP(player_id, Enabled) end)
        menu.toggle_loop(NEUTRAL_LIST, "Vanity Particles", {}, "", function(Enabled) NET.COMMAND.VANITY_PARTICLES(player_id) end)
        local FRIENDLY_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Friendly")
        local SPAWN_VEHICLE_LIST = menu.list(FRIENDLY_LIST, "Spawn Vehicle") for i, types in pairs(NET.TABLE.VEHICLE) do local LIST = menu.list(SPAWN_VEHICLE_LIST, tostring(i)) for j, k in pairs(types) do menu.action(LIST, "Spawn - "..tostring(k), {}, "", function() menu.trigger_commands("as "..players.get_name(player_id).." "..k) end) end end
        menu.toggle_loop(FRIENDLY_LIST, "RP Drop", {}, "Will give rp until player is level 120.", function() NET.COMMAND.GIVE_PLAYER_RP(player_id, 0) end)
        menu.toggle(FRIENDLY_LIST, "Money Drop", {}, "Limited money drop, must be close to player.", function(Enabled) NET.COMMAND.MONEY_DROP_PLAYER(player_id, Enabled) end)
        menu.action(FRIENDLY_LIST, "Give All Collectibles", {}, "Up to $300k.\nCan only be used once per player.", function() NET.FUNCTION.TRIGGER_GIVE_ALL_COLLECTIBLES(player_id) end)--menu.trigger_commands("givecollectibles"..players.get_name(player_id)) end)
        menu.action(FRIENDLY_LIST, "Gift Spawned Vehicle", {}, "Spawn fully tuned deathbike2 for best results.\nPlayer must have full garage.\nGifts the latest spawned car.", function() menu.trigger_commands("gift"..players.get_name(player_id)) end)
        menu.toggle(FRIENDLY_LIST, "Helpful Events", {""}, "Never Wanted, Off The Radar, Vehicle God, Auto-Heal.", function(Enabled) NET.COMMAND.HELPFUL_EVENTS(player_id, Enabled) end)
        menu.action(FRIENDLY_LIST, "Fix Loading Screen", {"fix"}, "Useful when stuck in a loading screen.", function() NET.COMMAND.FIX_LOADING_SCREEN(player_id) end)
        menu.action(FRIENDLY_LIST, "Reduce Loading Time", {""}, "Attempts to help the player by giving them script host.", function() NET.COMMAND.GIVE_SCRIPT_HOST(player_id) end)
        local TELEPORT_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Teleport")
        menu.action(TELEPORT_LIST, "Goto", {""}, "", function() menu.trigger_commands("tp"..players.get_name(player_id)) end)
        menu.action(TELEPORT_LIST, "Bring", {""}, "", function() menu.trigger_commands("summon"..players.get_name(player_id)) end)
        menu.action(TELEPORT_LIST, "Teleport Into Their Vehicle", {""}, "", function() menu.trigger_commands("tpveh"..players.get_name(player_id)) end)
        menu.action(TELEPORT_LIST, "Teleport To Casino", {""}, "", function() menu.trigger_commands("casinotp"..players.get_name(player_id)) end)
        menu.toggle(NET.PROFILE[tostring(player_id)].Menu, "Block Traffic", {}, "Stops exchanging data with player.", function(Enabled) local TargetName = players.get_name(player_id) if Enabled then menu.trigger_commands("timeout"..TargetName.." on") else menu.trigger_commands("timeout"..TargetName.." off") end end)
        menu.action(NET.PROFILE[tostring(player_id)].Menu, "Delete", {}, "Delete the label if the player isn't in the session anymore.", function() MenuBuffer:delete() end)
    end,
    --SAVE_NET_PROFILE = function() end, -- ???
    REMOVE_NET_PROFILE = function(player_id)
        if not NET.PROFILE[tostring(player_id)] then return end
        NET.VARIABLE.Players_Count = NET.VARIABLE.Players_Count - 1
        NET.PROFILE[tostring(player_id)].Menu:delete()
        NET.PROFILE[tostring(player_id)] = nil
    end,

    REMOVE_ALL_NET_PROFILES = function()
        for i,v in pairs(NET.PROFILE) do
            NET.REMOVE_NET_PROFILE(tonumber(i))
        end
    end,

    CREATE_NET_PROFILES_SPECIFIC = function()
        NET.REMOVE_ALL_NET_PROFILES()
        
        local Players = players.list()
        if NET.VARIABLE.Players_To_Affect == 3 then
            Players = players.list(false, false)
        end

        for next = 1, #Players do
            if NET.VARIABLE.Players_To_Affect == 1 then
                NET.CREATE_NET_PROFILE(Players[next])
            elseif NET.VARIABLE.Players_To_Affect == 2 and players.is_marked_as_modder(Players[next]) then
                NET.CREATE_NET_PROFILE(Players[next])
            elseif NET.VARIABLE.Players_To_Affect == 3 then
                NET.CREATE_NET_PROFILE(Players[next])
            elseif NET.VARIABLE.Players_To_Affect == 4 and not players.is_marked_as_modder(Players[next]) then
                NET.CREATE_NET_PROFILE(Players[next])
            end
        end
    end,
}

-- Main Options
local Title = menu.divider(menu.my_root(), "NET.REAPER")
local SELF_LIST = menu.list(menu.my_root(), "Self")
local VANITY_LIST = menu.list(SELF_LIST, "Vanity Particles")
menu.list_select(VANITY_LIST, "Particles", {}, "", {"Rainbow", "Brown", "Blue", "Green", "Orange", "Greyblack"}, 1, function(Value) vanity = Value end)
menu.toggle_loop(VANITY_LIST, "Enable", {}, "", function(Enabled) NET.COMMAND.VANITY_PARTICLES(players.user(), vanity) end)
local PROFILES_LIST = menu.list(SELF_LIST, "Profiles")
menu.list_select(PROFILES_LIST, "Profiles", {}, "", NET.TABLE.PROFILE, 1, function(Value) NET.VARIABLE.Current_Profile = NET.TABLE.PROFILE[Value] end)
menu.toggle(PROFILES_LIST, "Mute Notifications", {}, "", NET.COMMAND.MUTE_STAND_REACTION_NOTIFICATIONS)
menu.toggle(PROFILES_LIST, "Disable Reactions", {}, "Disables kick & crash reactions.", NET.COMMAND.DISABLE_STAND_REACTIONS)
menu.action(PROFILES_LIST, "Set Profile", {}, "", function() if NET.VARIABLE.Current_Profile == 1 then NET.COMMAND.SET_PROFILE_DEFAULT() elseif NET.VARIABLE.Current_Profile == 2 then NET.COMMAND.SET_PROFILE_STRICT() elseif NET.VARIABLE.Current_Profile == 3 then NET.COMMAND.SET_PROFILE_WARRIOR() end end)
local WEAPON_LIST = menu.list(SELF_LIST, "Weapons")
menu.toggle_loop(WEAPON_LIST, "Fast Hand", {}, "Faster weapon swapping.", function() if TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 56) then PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped()) end end)
menu.toggle_loop(WEAPON_LIST, "Hitbox Expander", {}, "Expands every player's hitbox.", NET.COMMAND.EXPAND_ALL_HITBOXES)
menu.toggle_loop(WEAPON_LIST,"Rocket Aimbot", {}, "Lock onto players with homing rpg.", NET.COMMAND.LOCK_ONTO_PLAYERS, function() for i, player_id in pairs(players.list_except(true)) do local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY(players.user(), ped) end end)
local VEHICLE_LIST = menu.list(SELF_LIST, "Vehicle")
menu.toggle_loop(VEHICLE_LIST, "Vehicle Rocket Aimbot", {}, "", NET.COMMAND.VEH_ROCKET_AIMBOT)
menu.toggle_loop(VEHICLE_LIST,"Rainbow Headlights", {""}, "", function(Enabled) NET.COMMAND.RAINBOW_HEADLIGHTS(Enabled) end)
menu.toggle(VEHICLE_LIST,"Rainbow Neons", {""}, "", function(Enabled) NET.COMMAND.RAINBOW_NEONS(Enabled) end)
local WORLD_LIST = menu.list(SELF_LIST, "World")
menu.list_select(WORLD_LIST, "Stations", {}, "", NET.TABLE.RADIO.NAME, 1, function(index) NET.VARIABLE.Selected_Loud_Radio = NET.TABLE.RADIO.STATION[index] end)
menu.toggle_loop(WORLD_LIST, "Toggle Radio", {}, "Networked", function() NET.COMMAND.TOGGLE_RADIO() end, function() if NET.VARIABLE.Party_Bus ~= nil then entities.delete_by_handle(NET.VARIABLE.Party_Bus) NET.VARIABLE.Party_Bus = nil end end)
menu.toggle_loop(WORLD_LIST, "Laser Show", {}, "Networked", NET.COMMAND.LASER_SHOW)
local PROTECTION_LIST = menu.list(SELF_LIST, "Protections")
menu.toggle_loop(PROTECTION_LIST, "Anti Tow-Truck", {}, "", function() if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(entities.get_user_vehicle_as_handle(false)) end end)
menu.toggle(PROTECTION_LIST, "Anti Spectator", {}, "You will stand still on the other player's screen.", function(Enabled) NET.VARIABLE.Spectate_Loop = Enabled end)
ENTITY_THROTTLER_LIST = menu.list(PROTECTION_LIST, "Entity Throttler", {}, "Great anti object crash & anti ferris wheel troll.") pcall(require("lib.net.Throttler"))
local SELF_RECOVERY_LIST = menu.list(SELF_LIST, "Recovery")
SLOTBOT_LIST = menu.list(SELF_RECOVERY_LIST, "[SAFE] Slotbot", {}, "", function() require("lib.net.SlotBot") end)
MONEY_LIST = menu.list(SELF_RECOVERY_LIST, "[SAFE] Money Recovery", {}, "", function() require("lib.net.Money") end)
HEIST_CONTROL_LIST = menu.list(SELF_RECOVERY_LIST, "[RISKY] Heist Control", {}, "", function() require("lib.net.Heist") end)
BANAGER_LIST = menu.list(SELF_RECOVERY_LIST, "[RISKY] Musiness Banager", {}, "", function() require("lib.net.MusinessBanager") end)
PLAYERS_LIST = menu.list(menu.my_root(), "Players")
menu.list_select(PLAYERS_LIST, "Target", {}, "", NET.TABLE.METHOD.PLAYER, 1, function(Value) NET.VARIABLE.Players_To_Affect = Value NET.CREATE_NET_PROFILES_SPECIFIC() end)
menu.toggle(PLAYERS_LIST, "Ignore Host", {}, "Great option if you don't want to get host kicked.", function(Enabled) NET.VARIABLE.Ignore_Host = Enabled end)
menu.toggle(PLAYERS_LIST, "Ignore Modded Stats", {}, "Ignores players with modded stats.", function(Enabled) NET.VARIABLE.Ignore_Modded_Stats = Enabled end)
local ALL_PLAYERS_LIST = menu.list(PLAYERS_LIST, "All Players", {}, "Related to target.")
local MODERATE_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Moderate")
menu.divider(MODERATE_PLAYERS_LIST, "Kicks") -- Kicks
menu.list_select(MODERATE_PLAYERS_LIST, "Kick Method", {}, "", NET.TABLE.METHOD.KICK, 1, function(Value) NET.VARIABLE.Kick_Method = Value end)
menu.action(MODERATE_PLAYERS_LIST, "Kick Players", {}, "", NET.COMMAND.KICK_PLAYERS)
menu.divider(MODERATE_PLAYERS_LIST, "Crashes") -- Crashes
menu.list_select(MODERATE_PLAYERS_LIST, "Crash Method", {}, "", NET.TABLE.METHOD.CRASH, 3, function(Value) NET.VARIABLE.Crash_Method = Value end)
local SERVER_CRASH_LIST = menu.list(MODERATE_PLAYERS_LIST, "Server Crashes", {}, "These crashes will affect everyone in the server regardless of current target selection.")
menu.action(SERVER_CRASH_LIST, "[RYZE] AIO Crash", {}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SERVER.AIO() end)
menu.action(SERVER_CRASH_LIST, "[NIGHT] Moonstar Crash", {}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SERVER.MOONSTAR() end)
menu.action(SERVER_CRASH_LIST, "[NIGHT] Rope Crash", {}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SERVER.ROPE() end)
menu.action(SERVER_CRASH_LIST, "[NIGHT] Land Crash", {}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SERVER.LAND() end)
menu.action(SERVER_CRASH_LIST, "[NIGHT] Umbrella V8 Crash", {}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SERVER.UMBRELLAV8() end)
menu.action(SERVER_CRASH_LIST, "[NIGHT] Umbrella V1 Crash", {}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SERVER.UMBRELLAV1() end)
menu.action(MODERATE_PLAYERS_LIST, "Crash Players", {}, "", NET.COMMAND.CRASH_PLAYERS)
menu.divider(MODERATE_PLAYERS_LIST, "Block Options") -- Block
menu.toggle(MODERATE_PLAYERS_LIST, "Automatic Modders Removal", {"irondome"}, "Recommended to use when host.", function(Enabled) NET.VARIABLE.No_Modders_Session = Enabled end)
menu.toggle(MODERATE_PLAYERS_LIST, "Block Modders From Joining", {""}, "Recommended to use when host.", function(Enabled) NET.VARIABLE.Block_Modders = Enabled end)
local RECOVERY_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Recovery")
menu.toggle_loop(RECOVERY_PLAYERS_LIST, "RP Loop", {"rplobby"}, "Will level up players until level 120.", NET.COMMAND.GIVE_PLAYERS_RP)
menu.toggle(RECOVERY_PLAYERS_LIST, "Freebies", {"bless"}, "Handout freebies.", NET.COMMAND.FREEBIES)
menu.toggle(RECOVERY_PLAYERS_LIST, "Rig Casino", {}, "HOW TO USE:\nStay inside casino.\nPlayers must have casino membership to earn alot.\nBlackjack: Stand if number is high, double down if low.\nRoulette: Max bet on Red 1 and Max Bet on Red 1st 12.", NET.COMMAND.RIG_CASINO)
menu.toggle(RECOVERY_PLAYERS_LIST, "Money Drop", {}, "Drops figurines on nearby players.", NET.COMMAND.MONEY_DROP)
local TELEPORT_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Teleport")
menu.toggle(TELEPORT_PLAYERS_LIST, "Ignore Interior", {}, "Will ignore players who are inside an interior.", function(Enabled) NET.VARIABLE.Ignore_Interior = Enabled end)
menu.action(TELEPORT_PLAYERS_LIST, "Teleport To Me", {}, "", NET.COMMAND.SUMMON_PLAYERS)
menu.action(TELEPORT_PLAYERS_LIST, "Teleport To My Waypoint", {}, "", NET.COMMAND.TELEPORT_PLAYERS_TO_WAYPOINT)
menu.action(TELEPORT_PLAYERS_LIST, "Teleport To Casino", {}, "", NET.COMMAND.TELEPORT_PLAYERS_TO_CASINO)
menu.toggle(ALL_PLAYERS_LIST, "Ghost Players", {}, "", function(Enabled) NET.COMMAND.GHOST_PLAYERS(Enabled) end)
local SESSION_LIST = menu.list(menu.my_root(), "Session")
local HOST_LIST = menu.list(SESSION_LIST, "Host Tools")
menu.divider(HOST_LIST, "Host")
menu.toggle_loop(HOST_LIST, "Host Addict", {}, "Automates the process of becoming host by calculating risks and giving you the best available session.", NET.COMMAND.HOST_ADDICT)
menu.action(HOST_LIST, "Become Host", {}, "", NET.COMMAND.BECOME_HOST)
menu.divider(HOST_LIST, "Script Host")
menu.toggle_loop(HOST_LIST, "Script Host Addict", {}, "Gatekeep script host with all of your might.", NET.COMMAND.BECOME_SCRIPT_HOST)
menu.action(HOST_LIST, "Become Script Host", {""}, "", NET.COMMAND.BECOME_SCRIPT_HOST)
CONSTRUCTOR_LIST = menu.list(SESSION_LIST, "Constructor") pcall(require("lib.net.Constructor"))
menu.toggle(SESSION_LIST, "Chat Commands", {}, "Say ;help.", function(Enabled) NET.VARIABLE.Commands_Enabled = Enabled end)
menu.toggle(SESSION_LIST, "Session Overlay", {}, "General information about the server.", function(Enabled) NET.COMMAND.SESSION_OVERLAY(Enabled) end)
menu.action(SESSION_LIST, "Server Hop", {}, "", function() menu.trigger_commands("playermagnet 30") menu.trigger_commands("go public") end)
menu.action(SESSION_LIST, "Rejoin", {}, "", function() menu.trigger_commands("rejoin") end)
local UNSTUCK_LIST = menu.list(SESSION_LIST, "Unstuck", {}, "Every methods to get unstuck.")
menu.action(UNSTUCK_LIST, "Abort Transition", {}, "", function() menu.trigger_commands("aborttransition") end)
menu.action(UNSTUCK_LIST, "Unstuck", {}, "", function() menu.trigger_commands("unstuck") end)
menu.action(UNSTUCK_LIST, "Quick Bail", {}, "", function() menu.trigger_commands("quickbail") end)
menu.action(UNSTUCK_LIST, "Quit To SP", {}, "", function() menu.trigger_commands("quittosp") end)
menu.action(UNSTUCK_LIST, "Force Quit To SP", {}, "", function() menu.trigger_commands("forcequittosp") end)
menu.action(menu.my_root(), "Credits", {}, "Made by @getfev.\nScripts from JinxScript, Ryze, Night LUA & Addict Script.", function() return end)

PLAYERS_COUNT = menu.divider(PLAYERS_LIST, "")

for next = 1, #players.list() do
    if players.list()[next] ~= players.user() then NET.TABLE.PLAYER_RANKED[players.get_name(players.list()[next])] = {Rank = 1, Prefix = NET.VARIABLE.Commands_Default_Prefix} end
    NET.CREATE_NET_PROFILE(players.list()[next])
end

chat.on_message(function(whofired, reserved, message, team_chat, networked, is_auto)
    if not NET.VARIABLE.Commands_Enabled then return end
    if string.sub(message, 1, 1) == NET.TABLE.PLAYER_RANKED[players.get_name(whofired)].Prefix then
        NET.FUNCTION.PROCESS_COMMAND(whofired, message)
    end
end)

players.on_join(function(player_id)
    if NET.VARIABLE.Block_Modders and players.is_marked_as_modder(player_id) then
        NET.FUNCTION.KICK_PLAYER(player_id)
    end

    if NET.VARIABLE.Auto_Ghost then
        NETWORK.SET_REMOTE_PLAYER_AS_GHOST(player_id, NET.VARIABLE.Auto_Ghost)
    end

    if player_id ~= players.user() then NET.TABLE.PLAYER_RANKED[players.get_name(player_id)] = {Rank = 1, Prefix = NET.VARIABLE.Commands_Default_Prefix} end

    NET.CREATE_NET_PROFILE(player_id)
end)

players.on_leave(function(player_id)
    if player_id ~= players.user() then NET.TABLE.PLAYER_RANKED[players.get_name(player_id)] = nil end

    NET.REMOVE_NET_PROFILE(player_id)
end)

util.on_stop(function()
    IS_CLOSING = true
    NET = nil
end)

util.create_tick_handler(function() -- Move player stuff here instead of on_join & on_leave
    -- Menu stuff
    NET.FUNCTION.UPDATE_MENU()
    NET.FUNCTION.CHECK_FOR_2TAKE1()
    NET.FUNCTION.CHECK_FOR_YIM()
    NET.COMMAND.PUNISH_SPECTATORS()
    if NET.VARIABLE.No_Modders_Session then NET.FUNCTION.KICK_MODDERS() end
    util.yield(1000)
end) 

util.keep_running()

-- Stuff im working on below.

	-- Train models HAVE TO be loaded (requested) before you use this.
	-- freight,freightcar,freightgrain,freightcont1,freightcont2,freighttrailer
	--["CREATE_MISSION_TRAIN"]=--[[Vehicle (int)]] function(--[[int]] variation,--[[float]] x,--[[float]] y,--[[float]] z,--[[BOOL (bool)]] direction,--[[Any (int)]] p5,--[[Any (int)]] p6)

    --["SET_VEHICLE_FORCE_AFTERBURNER"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] toggle)

    --["SET_DISABLE_BMX_EXTRA_TRICK_FORCES"]=--[[void]] function(--[[Any (int)]] p0)

    --["SET_BIKE_EASY_TO_LAND"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] toggle)

    --["SET_SCRIPT_ROCKET_BOOST_RECHARGE_TIME"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[float]] seconds)
    --["GET_HAS_ROCKET_BOOST"]=--[[BOOL (bool)]] function(--[[Vehicle (int)]] vehicle)
    --["IS_ROCKET_BOOST_ACTIVE"]=--[[BOOL (bool)]] function(--[[Vehicle (int)]] vehicle)
    --["SET_ROCKET_BOOST_ACTIVE"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] active)
    --["SET_ROCKET_BOOST_FILL"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[float]] percentage)

    --entities.get_all_vehicles_as_pointers()
    --["GET_ALL_VEHICLES"]=--[[int]] function(--[[Any* (pointer)]] vehsStruct)

    --["SET_DRIFT_TYRES"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] toggle)

    --["SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON_SYNCED"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] canBeLockedOn,--[[BOOL (bool)]] p2)

    --["SET_GOON_BOSS_VEHICLE"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] toggle)

    -- http://www.calculateme.com/Speed/MetersperSecond/ToMilesperHour.htm
	--["SET_VEHICLE_FORWARD_SPEED"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[float]] speed)

    	-- windowIndex:
	-- 0 = Front Left Window
	-- 1 = Front Right Window
	-- 2 = Rear Left Window
	-- 3 = Rear Right Window
	-- 4 = Front Windscreen
	-- 5 = Rear Windscreen
	-- 6 = Mid Left
	-- 7 = Mid Right
	-- 8 = Invalid
    --["ROLL_DOWN_WINDOW"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[int]] windowIndex)
    --["ROLL_UP_WINDOW"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[int]] windowIndex)

    --["SET_VEHICLE_ALARM"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] state)
    --["START_VEHICLE_ALARM"]=--[[void]] function(--[[Vehicle (int)]] vehicle)

    --["SET_VEHICLE_LIGHT_MULTIPLIER"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[float]] multiplier)

    --["SET_TRAIN_SPEED"]=--[[void]] function(--[[Vehicle (int)]] train,--[[float]] speed)
    --["SET_TRAIN_CRUISE_SPEED"]=--[[void]] function(--[[Vehicle (int)]] train,--[[float]] speed)

    --["SET_VEHICLE_WILL_FORCE_OTHER_VEHICLES_TO_STOP"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] toggle)
    --["SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON"]=--[[void]] function(--[[Vehicle (int)]] vehicle,--[[BOOL (bool)]] p1)
