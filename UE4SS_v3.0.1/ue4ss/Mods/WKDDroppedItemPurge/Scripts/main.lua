--[[
                                            ██╗    ██╗██╗  ██╗██████╗ 
                                            ██║    ██║██║ ██╔╝██╔══██╗
                                            ██║ █╗ ██║█████╔╝ ██║  ██║
                                            ██║███╗██║██╔═██╗ ██║  ██║
                                            ╚███╔███╔╝██║  ██╗██████╔╝
                                            ╚══╝╚══╝ ╚═╝  ╚═╝╚═════╝ 
██████╗ ███████╗    ██╗    ██╗██╗███████╗███████╗     ██████╗ ██╗     ██████╗     ███╗   ███╗ █████╗ ███╗   ██╗
██╔══██╗██╔════╝    ██║    ██║██║██╔════╝██╔════╝    ██╔═══██╗██║     ██╔══██╗    ████╗ ████║██╔══██╗████╗  ██║
██████╔╝███████╗    ██║ █╗ ██║██║███████╗█████╗      ██║   ██║██║     ██║  ██║    ██╔████╔██║███████║██╔██╗ ██║
██╔══██╗╚════██║    ██║███╗██║██║╚════██║██╔══╝      ██║   ██║██║     ██║  ██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║
██║  ██║███████║    ╚███╔███╔╝██║███████║███████╗    ╚██████╔╝███████╗██████╔╝    ██║ ╚═╝ ██║██║  ██║██║ ╚████║
╚═╝  ╚═╝╚══════╝     ╚══╝╚══╝ ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚══════╝╚═════╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
---------------------------------------------------------------------------------------------------------------]]
local DEBUG = false
local BIND_KEY = 118 -- Default = 118 (F7). Can be changed using one of the KEY_NAMES below.
local ModName = "WKDDroppedItemPurge"
local CLEAN_RADIUS = 99999999 -- Default = 99999999. This will clear everything dropped that is currently loaded into memory. This will not delete any dropped item outside of the loaded chunk your character is in.

local KEY_NAMES = {
    [19]  = "Pause/Break",
    [20]  = "Caps Lock",
    [33]  = "Page Up",
    [34]  = "Page Down",
    [35]  = "End",
    [36]  = "Home",
    [37]  = "Left Arrow",
    [38]  = "Up Arrow",
    [39]  = "Right Arrow",
    [40]  = "Down Arrow",
    [44]  = "Print Screen",
    [45]  = "Insert",
    [46]  = "Delete",
    [57]  = "9",
    [96]  = "NumPad 0",
    [97]  = "NumPad 1",
    [98]  = "NumPad 2",
    [99]  = "NumPad 3",
    [100] = "NumPad 4",
    [101] = "NumPad 5",
    [102] = "NumPad 6",
    [103] = "NumPad 7",
    [104] = "NumPad 8",
    [105] = "NumPad 9",
    [106] = "NumPad *",
    [107] = "NumPad +",
    [109] = "NumPad -",
    [110] = "NumPad .",
    [111] = "NumPad /",
    [112] = "F1",
    [113] = "F2",
    [114] = "F3",
    [115] = "F4",
    [116] = "F5",
    [117] = "F6",
    [118] = "F7",
    [119] = "F8",
    [120] = "F9",
    [121] = "F10",
    [122] = "F11",
    [123] = "F12",
}

local function keyName(code)
    return KEY_NAMES[code] or ("VK_" .. tostring(code))
end

local function log(msg) print("["..ModName.."] " .. msg) end
local function dbg(msg) if DEBUG then log("[DEBUG] " .. msg) end end

do
    local info = debug.getinfo(1, "S")
    local source = info and info.source or ""
    if source:sub(1, 1) == "@" then source = source:sub(2) end
    source = source:gsub("\\", "/")
    local ModNameN = source:match("/Mods/([^/]+)/Scripts/") or source:match("/Mods/([^/]+)/")
    if not ModNameN then
        log("ERROR: Could not determine mod name. Mod will not run.")
        return
    end
    if ModNameN ~= ModName then
        log("ERROR: Mod mismatch. Expected '" .. ModName .. "' but found '" .. ModNameN .. "'. Mod will not run.")
        return
    end
end

-- Helpers
local function safe_pcall(fn)
    local ok, res = pcall(fn)
    if ok then return true, res end
    return false, nil
end

local function is_vector(v)
    return type(v) == "table"
        and type(v.X) == "number"
        and type(v.Y) == "number"
        and type(v.Z) == "number"
end

local function dist_sq(a, b)
    local dx = (a.X or 0) - (b.X or 0)
    local dy = (a.Y or 0) - (b.Y or 0)
    local dz = (a.Z or 0) - (b.Z or 0)
    return dx*dx + dy*dy + dz*dz
end

local function get_player_controller_and_pawn()
    local PC = FindFirstOf("PlayerController")
    if not PC then return nil, nil end
    local pawn = PC.Pawn
    if not pawn or not pawn:IsValid() then return PC, nil end
    return PC, pawn
end

local function count_list(list)
    if not list then return 0 end
    if type(list) == "table" then return #list end
    if list.Num then
        local ok, n = safe_pcall(function() return list:Num() end)
        return ok and n or 0
    end
    return 0
end

local function get_list_item(list, i)
    if type(list) == "table" then return list[i] end
    local ok, v = safe_pcall(function() return list:Get(i) end)
    return ok and v or nil
end

local function safe_destroy(actor)
    if not actor or not actor:IsValid() then return false end
    if actor.K2_DestroyActor then
        safe_pcall(function() actor:K2_DestroyActor() end)
        return true
    end
    if actor.Destroy then
        safe_pcall(function() actor:Destroy() end)
        return true
    end
    return false
end

local function delete_nearby_dropped_items()
    local _, pawn = get_player_controller_and_pawn()
    if not pawn then
        log("No valid pawn found.")
        return
    end

    local okLoc, pLoc = safe_pcall(function() return pawn:K2_GetActorLocation() end)
    if not okLoc or not is_vector(pLoc) then
        log("Could not read pawn location.")
        return
    end

    local r2 = CLEAN_RADIUS * CLEAN_RADIUS
    local list = FindAllOf("BP_RuntimeSpawnedWorldItem_C")
    local n = count_list(list)

    if n == 0 then
        log("No dropped items found.")
        return
    end

    local deleted = 0

    for i = 1, n do
        local a = get_list_item(list, i)
        if a and a:IsValid() and a.K2_GetActorLocation then
            local okA, aLoc = safe_pcall(function() return a:K2_GetActorLocation() end)
            if okA and is_vector(aLoc) and dist_sq(pLoc, aLoc) <= r2 then
                if safe_destroy(a) then
                    deleted = deleted + 1
                end
            end
        end
    end

    log("Purged all dropped items in the current chunk.")
end

RegisterKeyBind(BIND_KEY, {}, function()
    delete_nearby_dropped_items()
end)

log("Loaded. Key: " .. tostring(BIND_KEY) .. " (" .. keyName(BIND_KEY) .. ") | Radius=" .. tostring(CLEAN_RADIUS))