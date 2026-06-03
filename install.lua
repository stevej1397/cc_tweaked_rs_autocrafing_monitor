-- Installer for the RS Autocrafting Monitor.
--
-- On an Advanced Computer:
--   wget run https://raw.githubusercontent.com/stevej1397/cc_tweaked_rs_autocrafing_monitor/main/install.lua
--
-- Fetches every program file into the current directory and runs a quick
-- peripheral check. Does not reboot - that's left to you so you can review
-- the output and fix any modem-network issues first.

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

local function findByType(typeName)
    for _, n in ipairs(peripheral.getNames()) do
        if peripheral.getType(n) == typeName then return n end
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

local mon    = findByType("monitor")
local bridge = findByType("rsBridge")
print(("Monitor:   %s"):format(mon or "NOT FOUND"))
print(("RS Bridge: %s"):format(bridge or "NOT FOUND"))
print()

if not (mon and bridge) then
    printError("One or more peripherals are missing.")
    print("Check that wired modems on the monitor and RS Bridge are")
    print("activated (green ring) and on the same network as this")
    print("computer, then run 'startup' or 'reboot'.")
else
    print("All set. Run 'startup' to launch now, or 'reboot' to")
    print("have it start automatically on world load.")
end
