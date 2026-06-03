-- Installer for the RS Autocrafting Monitor.
--
-- On an Advanced Computer:
--   wget run https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main/install.lua
--
-- Fetches every program file into the current directory and runs a quick
-- peripheral check. Does not reboot - that's left to you so you can review
-- the output and fix any setup issues first.

local REPO = "https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main"

local FILES = {
    "startup.lua",
    "config.lua",
    "bridge.lua",
    "tracker.lua",
    "history.lua",
    "watchdog.lua",
    "display.lua",
    "swatch.lua",
}

local MONITOR_TYPES = { "monitor" }
local BRIDGE_TYPES  = { "rsBridge", "rs_bridge", "advancedperipherals:rs_bridge" }
local BRIDGE_FUZZY  = "rsbridge"

local function fetch(name)
    local res, err = http.get(REPO .. "/" .. name)
    if not res then return nil, err or "no response" end
    local body = res.readAll()
    res.close()
    return body
end

local function writeFile(name, body)
    if fs.exists(name) then fs.delete(name) end
    local f, err = fs.open(name, "w")
    if not f then return false, err end
    f.write(body)
    f.close()
    return true
end

local function matchesAny(name, candidates, fuzzy)
    if peripheral.hasType then
        for _, c in ipairs(candidates) do
            if peripheral.hasType(name, c) then return c end
        end
    end
    local t = peripheral.getType(name)
    if not t then return nil end
    for _, c in ipairs(candidates) do
        if t == c then return t end
    end
    if fuzzy and t:lower():find(fuzzy) then return t end
end

local function findPeripheral(candidates, fuzzy)
    for _, n in ipairs(peripheral.getNames()) do
        local matched = matchesAny(n, candidates, fuzzy)
        if matched then return n, matched end
    end
end

local function dumpPeripherals()
    local names = peripheral.getNames()
    if #names == 0 then
        print("  (none)")
        return
    end
    for _, n in ipairs(names) do
        print(("  %-14s %s"):format(n, peripheral.getType(n) or "?"))
    end
end

if not http then
    printError("HTTP is disabled on this computer - enable http_enable in CC config.")
    return
end

print("Installing RS Autocrafting Monitor...")
print()

local failed = {}
for _, name in ipairs(FILES) do
    io.write(("  %-14s "):format(name))
    local body, err = fetch(name)
    if not body then
        print("FAIL: " .. tostring(err))
        failed[#failed + 1] = name
    else
        local ok, werr = writeFile(name, body)
        if not ok then
            print("WRITE FAIL: " .. tostring(werr))
            failed[#failed + 1] = name
        else
            print(("ok (%d bytes)"):format(#body))
        end
    end
end

print()
if #failed > 0 then
    printError("Failed: " .. table.concat(failed, ", "))
    printError("Fix the errors above and re-run the installer.")
    return
end

local monName,    monType    = findPeripheral(MONITOR_TYPES)
local bridgeName, bridgeType = findPeripheral(BRIDGE_TYPES, BRIDGE_FUZZY)

print(("Monitor:   %s"):format(
    monName    and (monName    .. " (" .. monType    .. ")") or "NOT FOUND"))
print(("RS Bridge: %s"):format(
    bridgeName and (bridgeName .. " (" .. bridgeType .. ")") or "NOT FOUND"))
print()

if not (monName and bridgeName) then
    printError("One or more peripherals are missing.")
    print()
    print("All peripherals currently visible:")
    dumpPeripherals()
    print()
    if monName and not bridgeName then
        print("If your RS Bridge appears above with a type that isn't")
        print("rsBridge / rs_bridge, set bridgeName in config.lua to")
        print("the name shown, then run 'startup' or 'reboot'.")
    else
        print("Direct attach: place the computer touching both blocks.")
        print("Modem network: attach wired modems and right-click them")
        print("to activate (green ring), then link with networking cable.")
    end
else
    print("All set. Run 'startup' to launch now, or 'reboot' to")
    print("have it start automatically on world load.")
end
