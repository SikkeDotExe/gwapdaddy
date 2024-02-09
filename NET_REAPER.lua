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

-- Libraries
util.require_natives(1676318796)

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
        source_url="https://raw.githubusercontent.com/MyUsername/MyProjectName/main/MyScriptName.lua",
        script_relpath=SCRIPT_RELPATH,
        verify_file_begins_with="--"
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
        Kick_Method = 3,
        Crash_Method = 3,

        To_Level_Up_To = 120,
        RP_Loop = false,

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

        Ignore_Interior = false,

        Commands_Enabled = false,
        Commands_Default_Prefix = ";",
        Commands_Prefix = Commands_Default_Prefix,

        Current_Car = 0,
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

            ["bring"] = {Alias = {}, Description = "Brings player(s) to you.", Rank = 1, Fire = function(whofired, target, args)
                if target then
                    for next = 1, #target do
                        menu.trigger_commands("as "..players.get_name(whofired).." summon "..players.get_name(target[next]))
                    end
                end
            end},

            ["bounty"] = {Alias = {}, Description = "", Rank = 1, Fire = function(whofired, target, args)
                if target then
                    for next = 1, #target do
                        menu.trigger_commands("bounty"..players.get_name(target).." 10000")
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

            ["explode"] = {Alias = {"expl"}, Description = "Explodes a player.", Rank = 2, Fire = function(whofired, target, args)
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
        },

        NOTIFICATION_COLOR = {
            Normal = "2",
            Grey = "5",
            Red = "6",
            Light_Blue = "9",
            Yellow = "12",
            Purple = "21",
            Pink = "24",
            Green = "25",
            Light_Pink = "30",
            Teal = "37",
            Lime = "46",
            Orange = "130",
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
        },

        METHOD = {
            PLAYER = {
                {1, "All"},
                {2, "Modders"},
                {3, "Strangers"},
                {4, "Plebs"},
            },
            KICK = {
                {1, "[ADDICT] Unfair"},
                {2, "[ADDICT] Eviction Notice"},
                {3, "[STAND] Aggressive"},
                {4, "[HOST] Host"},
                {5, "[HOST] Ban"},
                {6, "[HOST] Blacklist"},
            },
            CRASH = {
                {1, "[NET] Express"},
                {2, "[NET] Dynamite"},
                {3, "[STAND] Elegant"}
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

        KICK_PLAYER = function(player_id)
            local TargetName = players.get_name(player_id)
        
            if player_id ~= players.get_host() then
                menu.trigger_commands("loveletterkick"..TargetName)
            end
        
            util.yield(5000)
        
            if players.exists(player_id) then
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
        
        TRIGGER_COLLECTIBLE_LOOP = function(player_id, i)
            if players.get_rank(player_id) >= NET.VARIABLE.To_Level_Up_To then return end
            NET.FUNCTION.FIRE_EVENT(968269233, player_id, {players.user(), 4, i, 1, 1, 1})
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
                        elseif players.get_money(Current_Player) > 100000000 then
                            menu.set_menu_name(Arg1, Arg2.."] [+$100M]")
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
            local Players = players.list(false)
            for next = 1, #Players do
                if players.is_marked_as_modder(Players[next]) then
                    NET.FUNCTION.KICK_PLAYER(Players[next])
                end
            end
        end,
    },

    COMMAND = {

        KICK = {
            LEGIT = function(player_id)
                local TargetName = players.get_name(player_id)
                menu.trigger_commands("pickupkick"..TargetName)
                menu.trigger_commands("orgasmkick"..TargetName)
                menu.trigger_commands("aids"..TargetName)
            end,

            NET = function(player_id) -- (S3)
                menu.trigger_commands("givesh" .. players.get_name(player_id))
                NET.FUNCTION.FIRE_EVENT(921195243, player_id, {64,20,0})
                NET.FUNCTION.FIRE_EVENT(1925046697, player_id, {64,20,1})
                NET.FUNCTION.FIRE_EVENT(728200248, player_id, {64,7,0,0})
                NET.FUNCTION.FIRE_EVENT(-800312339, player_id, {64,0,26})
                NET.FUNCTION.FIRE_EVENT(1932558939, player_id, {64,0,26})
            end,

            UNFAIR = function(player_id) -- (S3)
                local int_min = -2147483647
                local int_max = 2147483647
                for i = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {12, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                    NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {12, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
                end
                menu.trigger_commands("givesh" .. players.get_name(player_id))
                util.yield()
                for i = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(-1638522928, player_id, {12, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, player_id, math.random(int_min, int_max)})
                    NET.FUNCTION.FIRE_EVENT(1017995959, player_id, {27, 0})
                end
            end,

            EVICTION_NOTICE = function(player_id)
                local int_min = -2147483647
                local int_max = 2147483647
                for i = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), player_id, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1})
                end
                menu.trigger_commands("givesh" .. players.get_name(player_id))
                util.yield()
                for i = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1, player_id, math.random(int_min, int_max)})
                    NET.FUNCTION.FIRE_EVENT(1613825825, player_id, {20, 1, -1, -1, -1, -1})
                end
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
                        Notify("Unable to get rid of player.", Notification_Colors.Red)
                        return
                    end
        
                    NET.FUNCTION.CRASH_PLAYER(player_id)
                    NET.FUNCTION.KICK_PLAYER(player_id)
        
                elseif TargetName ~= HostName then -- If the player isn't host
                    -- If we're next in line to get host
                    if players.get_host_queue_position(players.user()) == 1 and not NET.FUNCTION.IS_PLAYER_A_THREAT(players.get_host()) then
                        NET.FUNCTION.CRASH_PLAYER(players.get_host())
                        NET.FUNCTION.KICK_PLAYER(players.get_host())
        
                        util.yield(35000) -- We wait and assume that this is enough time for the host to be gone
        
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

            ["2TAKE1"] = function(player_id)
                NET.FUNCTION.CRASH_PLAYER(player_id)
            end,

            WARHEAD = function(player_id)
                NET.FUNCTION.CRASH_PLAYER(player_id)
                menu.trigger_commands("footlettuce"..TargetName)
                if players.get_vehicle_model(player_id) then
                    menu.trigger_commands("slaughter"..TargetName)
                end
            end,

            EXPRESS = function(player_id) -- (S3)
                local int_min = -2147483647
                local int_max = 2147483647
                for next = 1, 30 do
                    --NET.FUNCTION.FIRE_EVENT(-375628860, player_id, {1, -2147483645})
                    NET.FUNCTION.FIRE_EVENT(-375628860, player_id, {1, math.random(int_min, int_max)})
                end
            end,

            DYNAMITE = function(player_id) -- (S2)
                menu.trigger_commands("givesh"..players.get_name(player_id))

                for next = 1, 15 do
                    NET.FUNCTION.FIRE_EVENT(2067191610, player_id, {0, 0, -12988, -99097, 0})
                    NET.FUNCTION.FIRE_EVENT(323285304, player_id, {0, 0, -12988, -99097, 0})
                    NET.FUNCTION.FIRE_EVENT(495813132, player_id, {0, 0, -12988, -99097, 0})
                    NET.FUNCTION.FIRE_EVENT(323285304, player_id, {323285304, 64,2139114019,14299,40016,11434,4595,25992})
                end
            end,

            SUPER = function(player_id)
                NET.COMMAND.CRASH.CHINESE(player_id)
                NET.COMMAND.CRASH.JESUS(player_id)
                NET.COMMAND.CRASH.LAMP(player_id)
                NET.COMMAND.CRASH.WEED(player_id)
            end,

            CHINESE = function(player_id)
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
                    util.yield(25)
                end
                util.yield(2500)
                for i = 1, 10 do
                    entities.delete_by_handle(ped[i])
                    util.yield(25)
                end
            end,

            JESUS = function(player_id)
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

            LAMP = function(player_id)
                NET.FUNCTION.BLOCK_SYNCS(player_id, function()
                    local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)))
                    OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
                    util.yield(1000)
                    entities.delete_by_handle(object)
                end)
            end,

            WEED = function(player_id)
                local cord = players.get_position(player_id)
                local a1 = entities.create_object(-930879665, cord)
                local a2 = entities.create_object(3613262246, cord)
                local b1 = entities.create_object(452618762, cord)
                local b2 = entities.create_object(3613262246, cord)
                for i = 1, 10 do
                    util.request_model(-930879665)
                    util.yield(10)
                    util.request_model(3613262246)
                    util.yield(10)
                    util.request_model(452618762)
                    util.yield(300)
                    entities.delete_by_handle(a1)
                    entities.delete_by_handle(a2)
                    entities.delete_by_handle(b1)
                    entities.delete_by_handle(b2)
                    util.request_model(452618762)
                    util.yield(10)
                    util.request_model(3613262246)
                    util.yield(10)
                    util.request_model(-930879665)
                    util.yield(10)
                end
            end,

            TASK = function(player_id)
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
                        NET.FUNCTION.NOTIFY("Host has not been recognized as a threat, removing player..", NET.TABLE.NOTIFICATION_COLOR.Green)
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
            local ToKick = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                ToKick = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToKick, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToKick = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToKick, Players[next])
                    end
                end
            end
        
            for next = 1, #ToKick do
                if players.exists(ToKick[next]) then
                    if NET.VARIABLE.Ignore_Host and players.get_host() == ToKick[next] then return end
                    local PlayerName = players.get_name(ToKick[next])
                    if NET.VARIABLE.Kick_Method == 1 then -- Unfair
                        NET.COMMAND.KICK.UNFAIR(ToKick[next])
                    elseif NET.VARIABLE.Kick_Method == 2 then -- Eviction Notice
                        NET.COMMAND.KICK.EVICTION_NOTICE(ToKick[next])
                    elseif NET.VARIABLE.Kick_Method == 3 then -- Aggressive
                        util.toast("fired")
                        NET.COMMAND.KICK.AGGRESSIVE(ToKick[next])
                    elseif NET.VARIABLE.Kick_Method == 4 then -- Host Kick / Votekick
                        menu.trigger_commands("hostkick"..PlayerName)
                    elseif NET.VARIABLE.Kick_Method == 5 then -- Ban / "Player has been removed for cheating"
                        menu.trigger_commands("ban"..PlayerName)
                    elseif NET.VARIABLE.Kick_Method == 6 then -- Desync Kick
                        menu.trigger_commands("blacklist"..PlayerName)
                    end
                end
        
                util.yield(100)
            end
        end,

        CRASH_PLAYERS = function()
            local ToCrash = {}
            local Players = players.list(false)
        
            if NET.VARIABLE.Players_To_Affect == 1 then
                ToCrash = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToCrash, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToCrash = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToCrash, Players[next])
                    end
                end
            end
        
            for next = 1, #ToCrash do
                if players.exists(ToCrash[next]) then
                    if NET.VARIABLE.Ignore_Host and players.get_host() == ToCrash[next] then return end
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

        CRASH_ALL = function() -- AIO
            local time = (util.current_time_millis() + 2000)
            while time > util.current_time_millis() do
                local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id))
                for i = 1, 10 do
                    AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', pc.x, pc.y, pc.z, 'MP_MISSION_COUNTDOWN_SOUNDSET', 1, 10000, 0)
                end
                util.yield_once()
            end
        end,

        GIVE_PLAYER_RP = function(player_id, delay)
            if not delay then delay = 5 end

            if delay == 0 then
                for i = 20, 24 do
                    NET.FUNCTION.TRIGGER_COLLECTIBLE_LOOP(player_id, i)
                end
            elseif delay == 5 then
                NET.FUNCTION.TRIGGER_COLLECTIBLE_LOOP(player_id, math.random(20, 24)) -- limiting the amount of script events sent to prevent a fatal error
            else
                for i = 20, 24 do
                    NET.FUNCTION.TRIGGER_COLLECTIBLE_LOOP(player_id, i)
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

        FREEBIES = function(Enabled)
            if Enabled then
                menu.trigger_commands("givecollectiblesall")
                menu.trigger_commands("rplobby on")
                menu.trigger_commands("ceopayall on")
                menu.trigger_commands("armallall")
                menu.trigger_commands("loopbountyall on")
                menu.trigger_commands("commendhelpfulall")
                menu.trigger_commands("commendfriendlyall")
            else
                menu.trigger_commands("rplobby off")
                menu.trigger_commands("ceopayall off")
                menu.trigger_commands("loopbountyall off")
            end

            NET.VARIABLE.RP_Loop = Enabled
        end,

        GIVE_PLAYERS_RP = function()
            local ToGive = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                ToGive = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToGive, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToGive = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToGive, Players[next])
                    end
                end
            end
        
            for next = 1, #ToGive do
                if players.exists(ToGive[next]) then
                    if NET.VARIABLE.Ignore_Host and players.get_host() == ToGive[next] then return end
                    NET.COMMAND.GIVE_PLAYER_RP(ToGive[next], 0)
                end
            end
        end,

        GHOST_PLAYERS = function(Enabled)
            local ToGhost = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                ToGhost = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToGhost, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToGhost = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToGhost, Players[next])
                    end
                end
            end
        
            for next = 1, #ToGhost do
                if players.exists(ToGhost[next]) then
                    if NET.VARIABLE.Ignore_Host and players.get_host() == ToGhost[next] then return end
                    NETWORK.SET_REMOTE_PLAYER_AS_GHOST(ToGhost[next], Enabled)
                end
            end
        end,

        SUMMON_PLAYERS = function()
            local ToTP = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                ToTP = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToTP, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToTP = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToTP, Players[next])
                    end
                end
            end
        
            for next = 1, #ToTP do
                if players.exists(ToTP[next]) then
                    if NET.VARIABLE.Ignore_Interior and players.is_in_interior(ToTP[next]) then return end
                    menu.trigger_commands("tp"..players.get_name(ToTP[next]))
                end
            end
        end,

        TELEPORT_PLAYERS_TO_WAYPOINT = function()
            local ToTP = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                ToTP = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToTP, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToTP = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToTP, Players[next])
                    end
                end
            end
        
            for next = 1, #ToTP do
                if players.exists(ToTP[next]) then
                    if NET.VARIABLE.Ignore_Interior and players.is_in_interior(ToTP[next]) then return end
                    menu.trigger_commands("wpsummon"..players.get_name(ToTP[next]))
                end
            end
        end,

        TELEPORT_PLAYERS_TO_CASINO = function()
            local ToTP = {}

            if NET.VARIABLE.Players_To_Affect == 1 then
                ToTP = players.list(false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 2 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if players.is_marked_as_modder(Players[next]) then
                        table.insert(ToTP, Players[next])
                    end
                end
            end
        
            if NET.VARIABLE.Players_To_Affect == 3 then
                ToTP = players.list(false, false)
            end
        
            if NET.VARIABLE.Players_To_Affect == 4 then
                local Players = players.list(false)
                for next = 1, #Players do
                    if not players.is_marked_as_modder(Players[next]) then
                        table.insert(ToTP, Players[next])
                    end
                end
            end
        
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
            if NET.VARIABLE.Current_Car ~= 0 then 
                VEHICLE.TOGGLE_VEHICLE_MOD(NET.VARIABLE.Current_Car, 22, true)
                for i=1, 12 do
                    VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(NET.VARIABLE.Current_Car, i)  
                    util.yield(200)
                end
            end
        end,
    },

    PROFILE = {}, -- Menu Profiles

    CREATE_NET_PROFILE = function(player_id)
        if NET.VARIABLE.Players_To_Affect == 2 and not players.is_marked_as_modder(player_id) then return end
        if NET.VARIABLE.Players_To_Affect == 4 and players.is_marked_as_modder(player_id) then return end

        NET.VARIABLE.Players_Count = NET.VARIABLE.Players_Count + 1
        NET.PROFILE[tostring(player_id)] = {}
        NET.PROFILE[tostring(player_id)].Menu = menu.list(PLAYERS_LIST, players.get_name(player_id), {}, "")
        util.create_thread(function()
            while true do
                if IS_CLOSING or not players.exists(player_id) then break end
                if NET.PROFILE[tostring(player_id)] then
                    if menu.is_ref_valid(menu.player_root(player_id)) then
                        local Country = tostring(menu.ref_by_rel_path(menu.player_root(player_id), "Information>Connection>Country").value)
                        menu.set_help_text(NET.PROFILE[tostring(player_id)].Menu,
                        "Location: "..Country
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
        --[[
            MODDED EVENT
            (S3)
            {0: 1450115979, 1: 16, 2: 2097152}

            (SA) -- 2, 3, 11, | Doesnt change
            {0: -642704387, 1: 16, 2: 2097152, 3: 782258655, 4: -345121748, 5: -1843768720, 6: -1736840549, 7: -525937562, 8: -1698401700, 9: -636934661, 10: -1204525798, 11: 21, 12: -296292909, 13: 649616346, 14: -1799648362}

            (S8) -- Only 3 changes
            {0: -1986344798, 1: 16, 2: 2097152, 3: 1441003728, 4: 0, 5: 0}
        ]]

        menu.toggle(NET.PROFILE[tostring(player_id)].Menu, "Pacify", {}, "Blocked by most menus, will also most likely ruin the player's scripts.", function(Enabled) NET.COMMAND.PACIFY_PLAYER(player_id, Enabled) end)
        local MODERATE_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Moderate")
        local KICK_OPTIONS = menu.list(MODERATE_LIST, "Kicks")
        menu.action(KICK_OPTIONS, "[STAND] Legit Kick", {"lkick"}, "Don't use agaisn't modders.", function() NET.COMMAND.KICK.LEGIT(player_id) end)
        menu.action(KICK_OPTIONS, "[NET] NET Kick", {"netkick"}, "Just like unfair but different method.", function() NET.COMMAND.KICK.NET(player_id) end)
        menu.action(KICK_OPTIONS, "[ADDICT] Unfair Kick", {"se3kick"}, "Blocked by most menus.", function() NET.COMMAND.KICK.UNFAIR(player_id) end)
        menu.action(KICK_OPTIONS, "[ADDICT] Eviction Notice", {"ekick"}, "Blocked by popular menus.", function() NET.COMMAND.KICK.EVICTION_NOTICE(player_id) end)
        menu.action(KICK_OPTIONS, "[STAND] Aggressive Kick", {"akick"}, "Very effective agaisn't modders with protections.", function() NET.COMMAND.KICK.AGGRESSIVE(player_id) end)
        menu.action(KICK_OPTIONS, "[STAND] Wrath Kick", {"wkick"}, "Will try to get host to kick target if available. If not, will try everything to get rid of the target.", function() NET.COMMAND.KICK.WRATH(player_id) end)
        local CRASH_OPTIONS = menu.list(MODERATE_LIST, "Crashes")
        menu.divider(CRASH_OPTIONS, "Modern Crashes")
        menu.action(CRASH_OPTIONS, "[STAND] 2Take1 Crash", {"2t1crash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH["2TAKE1"](player_id) end)
        menu.action(CRASH_OPTIONS, "[STAND] Warhead Crash", {"warcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.WARHEAD(player_id) end)
        menu.action(CRASH_OPTIONS, "[NET] Express Crash", {"xcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.EXPRESS(player_id) end) -- (S3)
        menu.action(CRASH_OPTIONS, "[NET] Dynamite Crash", {"dcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.DYNAMITE(player_id) end) -- (S2)
        menu.divider(CRASH_OPTIONS, "Ryze Crashes")
        menu.action(CRASH_OPTIONS, "[NET] Super Crash", {"supercrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.SUPER(player_id) end)
        menu.action(CRASH_OPTIONS, "Chinese Crash", {"ccrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.CHINESE(player_id) end)
        menu.action(CRASH_OPTIONS, "Jesus Crash", {"jcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.JESUS(player_id) end)
        menu.action(CRASH_OPTIONS, "Lamp Crash", {"lcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.LAMP(player_id) end)
        menu.action(CRASH_OPTIONS, "Weed Crash", {"wcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.WEED(player_id) end)
        menu.action(CRASH_OPTIONS, "Task Crash", {"tcrash"}, "Blocked by most menus.", function() NET.COMMAND.CRASH.TASK(player_id) end)
        local TROLLING_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Trolling")
        menu.divider(TROLLING_LIST, "Unblockable & Undetected")
        menu.toggle_loop(TROLLING_LIST, "Smokescreen", {""}, "Fills up their screen with black smoke.", function() NET.COMMAND.SMOKESCREEN_PLAYER(player_id) end, function() local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) GRAPHICS.REMOVE_PARTICLE_FX(ptfx) STREAMING.REMOVE_NAMED_PTFX_ASSET("scr_as_trans") end)
        menu.toggle_loop(TROLLING_LIST, "Launch Player", {""}, "Works on most menus.", function() NET.COMMAND.LAUNCH_PLAYER(player_id) end, function() if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then entities.delete(veh) end end)
        menu.toggle_loop(TROLLING_LIST, "Stumble Player", {""}, "", function() NET.COMMAND.STUMBLE_PLAYER(player_id) end)
        local PROP_GLITCH_LIST = menu.list(TROLLING_LIST, "Prop Glitch Loop")
        menu.list_select(PROP_GLITCH_LIST, "Object", {""}, "Object to glitch the player.", NET.TABLE.GLITCH_OBJECT.NAME, 1, function(index) NET.VARIABLE.Object_Hash = util.joaat(NET.TABLE.GLITCH_OBJECT.OBJECT[index]) end)
        menu.slider(PROP_GLITCH_LIST, "Spawn delay", {""}, "", 0, 3000, 50, 10, function(amount) delay = amount end)
        menu.toggle(PROP_GLITCH_LIST, "Glitch player", {}, "", function(toggled) NET.COMMAND.GLITCH_PLAYER(player_id, toggled) end)
        local NEUTRAL_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Neutral")
        menu.toggle(NEUTRAL_LIST, "Spectate", {}, "", function(Enabled) NET.COMMAND.SPECTATE_PLAYER(player_id, Enabled) end)
        menu.toggle_loop(NEUTRAL_LIST, "Ghost Player", {""}, "Ghosts the selected player.", function() NETWORK.SET_REMOTE_PLAYER_AS_GHOST(player_id, true) end, function() NETWORK.SET_REMOTE_PLAYER_AS_GHOST(player_id, false) end)
        menu.toggle(NEUTRAL_LIST, "Fake Money Drop", {""}, "", function(Enabled) NET.COMMAND.FAKE_MONEY_DROP(player_id, Enabled) end)
        local FRIENDLY_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Friendly")
        local SPAWN_VEHICLE_LIST = menu.list(FRIENDLY_LIST, "Spawn Vehicle") for i, types in pairs(NET.TABLE.VEHICLE) do local LIST = menu.list(SPAWN_VEHICLE_LIST, tostring(i)) for j, k in pairs(types) do menu.action(LIST, "Spawn - "..tostring(k), {}, "", function() menu.trigger_commands("as "..players.get_name(player_id).." "..k) end) end end
        menu.toggle_loop(FRIENDLY_LIST, "RP Drop", {}, "Will give rp until player is level 120.", function() NET.COMMAND.GIVE_PLAYER_RP(player_id, 0) end)
        menu.toggle(FRIENDLY_LIST, "Money Drop", {}, "Limited money drop, must be close to player for it to work best.", function(Enabled) NET.COMMAND.MONEY_DROP_PLAYER(player_id, Enabled) end)
        menu.action(FRIENDLY_LIST, "Give All Collectibles", {}, "Up to $300k.", function() menu.trigger_commands("givecollectibles"..players.get_name(player_id)) end)
        menu.action(FRIENDLY_LIST, "Gift Spawned Vehicle", {}, "", function() menu.trigger_commands("gift"..players.get_name(player_id)) end)
        menu.toggle(FRIENDLY_LIST, "Helpful Events", {""}, "Never Wanted, Off The Radar, Vehicle God, Auto-Heal.", function(Enabled) NET.COMMAND.HELPFUL_EVENTS(player_id, Enabled) end)
        menu.action(FRIENDLY_LIST, "Fix Loading Screen", {"fix"}, "Useful when stuck in a loading screen.", function() NET.COMMAND.FIX_LOADING_SCREEN(player_id) end)
        menu.action(FRIENDLY_LIST, "Reduce Loading Time", {""}, "Attempts to help the player by giving them script host.", function() NET.COMMAND.GIVE_SCRIPT_HOST(player_id) end)
        local TELEPORT_LIST = menu.list(NET.PROFILE[tostring(player_id)].Menu, "Teleport")
        menu.action(TELEPORT_LIST, "Goto", {""}, "", function() menu.trigger_commands("tp"..players.get_name(player_id)) end)
        menu.action(TELEPORT_LIST, "Bring", {""}, "", function() menu.trigger_commands("summon"..players.get_name(player_id)) end)
        menu.action(TELEPORT_LIST, "Teleport Into Their Vehicle", {""}, "", function() menu.trigger_commands("tpveh"..players.get_name(player_id)) end)
        menu.action(TELEPORT_LIST, "Teleport To Casino", {""}, "", function() menu.trigger_commands("casinotp"..players.get_name(player_id)) end)
        menu.toggle(NET.PROFILE[tostring(player_id)].Menu, "Block Traffic", {}, "Stops exchanging data with player.", function(Enabled) local TargetName = players.get_name(player_id) if Enabled then menu.trigger_commands("timeout"..TargetName.." on") else menu.trigger_commands("timeout"..TargetName.." off") end end)
        menu.action(NET.PROFILE[tostring(player_id)].Menu, "Delete", {}, "Glitched?", function() NET.PROFILE[tostring(player_id)].Menu:delete() end)
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

local Title = menu.divider(menu.my_root(), "NET.REAPER V2")

-- Main Options
local SELF_LIST = menu.list(menu.my_root(), "Self")
local PROFILES_LIST = menu.list(SELF_LIST, "Profiles")
menu.list_select(PROFILES_LIST, "Profiles", {}, "", NET.TABLE.PROFILE, 1, function(Value) NET.VARIABLE.Current_Profile = NET.TABLE.PROFILE[Value] end)
menu.toggle(PROFILES_LIST, "Mute Notifications", {}, "", NET.COMMAND.MUTE_STAND_REACTION_NOTIFICATIONS)
menu.toggle(PROFILES_LIST, "Disable Reactions", {}, "Disables kick & crash reactions.", NET.COMMAND.DISABLE_STAND_REACTIONS)
menu.action(PROFILES_LIST, "Set Profile", {}, "", function() if NET.VARIABLE.Current_Profile == 1 then NET.COMMAND.SET_PROFILE_DEFAULT() elseif NET.VARIABLE.Current_Profile == 2 then NET.COMMAND.SET_PROFILE_STRICT() elseif NET.VARIABLE.Current_Profile == 3 then NET.COMMAND.SET_PROFILE_WARRIOR() end end)
local WEAPON_LIST = menu.list(SELF_LIST, "Weapons")
menu.toggle_loop(WEAPON_LIST, "Hitbox Expander", {}, "Expands every player's hitbox.", NET.COMMAND.EXPAND_ALL_HITBOXES)
menu.toggle_loop(WEAPON_LIST,"Rocket Aimbot", {}, "Lock onto players with homing rpg.", NET.COMMAND.LOCK_ONTO_PLAYERS, function() for i, player_id in pairs(players.list_except(true)) do local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id) PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY(players.user(), ped) end end)
local VEHICLE_LIST = menu.list(SELF_LIST, "Vehicle")
menu.toggle_loop(VEHICLE_LIST, "Vehicle Rocket Aimbot", {}, "", NET.COMMAND.VEH_ROCKET_AIMBOT)
menu.toggle_loop(VEHICLE_LIST,"Rainbow Headlights", {""}, "", function(Enabled) NET.COMMAND.RAINBOW_HEADLIGHTS(Enabled) end)
local WORLD_LIST = menu.list(SELF_LIST, "World")
menu.list_select(WORLD_LIST, "Stations", {}, "", NET.TABLE.RADIO.NAME, 1, function(index) NET.VARIABLE.Selected_Loud_Radio = NET.TABLE.RADIO.STATION[index] end)
menu.toggle_loop(WORLD_LIST, "Toggle Radio", {}, "Networked", function() NET.COMMAND.TOGGLE_RADIO() end, function() if NET.VARIABLE.Party_Bus ~= nil then entities.delete_by_handle(NET.VARIABLE.Party_Bus) NET.VARIABLE.Party_Bus = nil end end)
menu.toggle_loop(WORLD_LIST, "Laser Show", {}, "Networked", NET.COMMAND.LASER_SHOW)
local PROTECTION_LIST = menu.list(SELF_LIST, "Protections")
menu.toggle_loop(PROTECTION_LIST, "Anti Tow-Truck", {}, "", function() if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(NET.VARIABLE.Current_Car) end end)
PLAYERS_LIST = menu.list(menu.my_root(), "Players")
menu.list_select(PLAYERS_LIST, "Target", {}, "", NET.TABLE.METHOD.PLAYER, 1, function(Value) NET.VARIABLE.Players_To_Affect = Value NET.CREATE_NET_PROFILES_SPECIFIC() end)
menu.toggle(PLAYERS_LIST, "Ignore Host", {}, "Great option if you don't want to get host kicked.", function(Enabled) NET.VARIABLE.Ignore_Host = Enabled end)
local ALL_PLAYERS_LIST = menu.list(PLAYERS_LIST, "All Players", {}, "Related to target.")
local MODERATE_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Moderate")
menu.divider(MODERATE_PLAYERS_LIST, "Kicks") -- Kicks
menu.list_select(MODERATE_PLAYERS_LIST, "Kick Method", {}, "", NET.TABLE.METHOD.KICK, 3, function(Value) NET.VARIABLE.Kick_Method = Value end)
menu.action(MODERATE_PLAYERS_LIST, "Kick Players", {}, "", NET.COMMAND.KICK_PLAYERS)
menu.divider(MODERATE_PLAYERS_LIST, "Crashes") -- Crashes
menu.list_select(MODERATE_PLAYERS_LIST, "Crash Method", {}, "", NET.TABLE.METHOD.CRASH, 3, function(Value) NET.VARIABLE.Crash_Method = Value end)
menu.action(MODERATE_PLAYERS_LIST, "AIO Crash All", {}, "Blocked by most menus, will go undetected for the most part.", NET.COMMAND.CRASH_ALL)
menu.action(MODERATE_PLAYERS_LIST, "Crash Players", {}, "", NET.COMMAND.CRASH_PLAYERS)
menu.divider(MODERATE_PLAYERS_LIST, "Block Options") -- Block
menu.toggle(MODERATE_PLAYERS_LIST, "Auto Kick Modders In Session", {"irondome"}, "Recommended to use when host.", function(Enabled) NET.VARIABLE.No_Modders_Session = Enabled end)
menu.toggle(MODERATE_PLAYERS_LIST, "Block Modders From Joining", {""}, "Recommended to use when host.", function(Enabled) NET.VARIABLE.Block_Modders = Enabled end)
local RECOVERY_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Recovery")
menu.toggle_loop(RECOVERY_PLAYERS_LIST, "RP Loop", {"rplobby"}, "Will level up players until level 120.", NET.COMMAND.GIVE_PLAYERS_RP)
menu.toggle(RECOVERY_PLAYERS_LIST, "Freebies", {"bless"}, "Handout freebies.", NET.COMMAND.FREEBIES)
menu.toggle(RECOVERY_PLAYERS_LIST, "Rig Casino", {}, "Rig casino for everyone!", NET.COMMAND.RIG_CASINO)
menu.toggle(RECOVERY_PLAYERS_LIST, "Money Drop", {}, "Drops figurines on nearby players.", NET.COMMAND.MONEY_DROP)
local TELEPORT_PLAYERS_LIST = menu.list(ALL_PLAYERS_LIST, "Teleport")
menu.toggle(TELEPORT_PLAYERS_LIST, "Ignore Interior", {}, "Will ignore players who are inside an interior.", function(Enabled) NET.VARIABLE.Ignore_Interior = Enabled end)
menu.action(TELEPORT_PLAYERS_LIST, "Teleport To Me", {}, "", NET.COMMAND.SUMMON_PLAYERS)
menu.action(TELEPORT_PLAYERS_LIST, "Teleport To My Waypoint", {}, "", NET.COMMAND.TELEPORT_PLAYERS_TO_WAYPOINT)
menu.action(TELEPORT_PLAYERS_LIST, "Teleport To Casino", {}, "", NET.COMMAND.TELEPORT_PLAYERS_TO_CASINO)
menu.toggle(ALL_PLAYERS_LIST, "Ghost Players", {}, "", function(Enabled) NET.COMMAND.GHOST_PLAYERS(Enabled) end)
local SESSION_LIST = menu.list(menu.my_root(), "Session")
menu.toggle(SESSION_LIST, "Chat Commands", {}, "Say ;help.", function(Enabled) NET.VARIABLE.Commands_Enabled = Enabled end)
menu.toggle(SESSION_LIST, "Session Overlay", {}, "General information about the server.", function(Enabled) NET.COMMAND.SESSION_OVERLAY(Enabled) end)
local HOST_LIST = menu.list(SESSION_LIST, "Host Tools")
menu.divider(HOST_LIST, "Host")
menu.toggle_loop(HOST_LIST, "Host Addict", {}, "Automates the process of becoming host by calculating risks and giving you the best available session.", NET.COMMAND.HOST_ADDICT)
menu.action(HOST_LIST, "Become Host", {}, "", NET.COMMAND.BECOME_HOST)
menu.divider(HOST_LIST, "Script Host")
menu.toggle_loop(HOST_LIST, "Script Host Addict", {}, "Gatekeep script host with all of your might.", NET.COMMAND.BECOME_SCRIPT_HOST)
menu.action(HOST_LIST, "Become Script Host", {""}, "", NET.COMMAND.BECOME_SCRIPT_HOST)
menu.action(SESSION_LIST, "Server Hop", {}, "", function() menu.trigger_commands("playermagnet 30") menu.trigger_commands("go public") end)
menu.action(SESSION_LIST, "Rejoin", {}, "", function() menu.trigger_commands("rejoin") end)
local UNSTUCK_LIST = menu.list(SESSION_LIST, "Unstuck", {}, "Every methods to get unstuck.")
menu.action(UNSTUCK_LIST, "Abort Transition", {}, "", function() menu.trigger_commands("aborttransition") end)
menu.action(UNSTUCK_LIST, "Unstuck", {}, "", function() menu.trigger_commands("unstuck") end)
menu.action(UNSTUCK_LIST, "Quick Bail", {}, "", function() menu.trigger_commands("quickbail") end)
menu.action(UNSTUCK_LIST, "Quit To SP", {}, "", function() menu.trigger_commands("quittosp") end)
menu.action(UNSTUCK_LIST, "Force Quit To SP", {}, "", function() menu.trigger_commands("forcequittosp") end)
menu.action(menu.my_root(), "Credits", {}, "Made by @getfev, Scripts from JinxScript, Ryze & Addict Script.", function() util.toast("Made by @getfev, Scripts from JinxScript, Ryze & Addict Script") end)

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

    if NET.VARIABLE.RP_Loop then
        repeat util.yield(1000) until NET.FUNCTION.IS_NET_PLAYER_OK(player_id)
        menu.trigger_commands("givecollectibles"..players.get_name(player_id))
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

util.create_tick_handler(function()
    -- Menu stuff
    NET.FUNCTION.UPDATE_MENU()
    NET.FUNCTION.CHECK_FOR_2TAKE1()
    if NET.VARIABLE.No_Modders_Session then NET.FUNCTION.KICK_MODDERS() end
    NET.VARIABLE.Current_Car = entities.get_user_vehicle_as_handle(false)
    util.yield(1000)
end) 

util.keep_running()
