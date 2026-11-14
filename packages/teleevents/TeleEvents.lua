-- This is an event handler for ComputerCraft. It takes event arguments returned
--   by os.pullEvent or os.pullEventRaw and processes them into an object with
--   methods for better accessibility and usability.

-- Key presses and mouse clicks are also tracked so that it's easier to tell if
--   a button is currently pressed or not. This is useful for multi-key events
--   such as pressing Ctrl+C, for example.

-- You can get this program from https://pastebin.com/KA2dK07y
-- This program requires two additional files to work. To get this program
--   run the following commands:
--     pastebin get Rac6Jxjg "/API/LibAppend.lua"
--     pastebin get t2TvSiSU "/API/Class.lua"
--     pastebin get KA2dK07y "/API/events.lua"

-- Make sure that all of these files are saved to "/API" in the root directory
--   in order for all programs that use this one to work properly.

-- Add this to your program using 'dofile("/API/events.lua")'' and call 'event =
--   Events()' to create an events object.

-- Call events.getEvent() for os.pullEvent(), and events.getRawEvent() for
--   os.pullEventRaw() and events.queueEvent() for os.queueEvent().

-- Event parameters are automatically stored in events[n]. All you have to do is
--   call events[1] for the event name, events[2] for its first parameter, etc.

-- Call events.isPressed() to check if a key or mouse click is currently being
--   pressed. Scroll down to learn the function arguments.

-- Call events.mousePos() to get the position of a mouse button if it is
--   currently being pressed. Pass the mouse button id as this function's
--   argument.

dofile("/apis/LibAppend.lua")
dofile("/apis/TeleClass.lua")

Events = Class(function()
local readOnly = {}
local event = {}
local eventSize = 0
local pressed = {key = {}, click = {}}
local mousePos = {
    [1] = vector.new(0, 0),
    [2] = vector.new(0, 0),
    [3] = vector.new(0, 0),
    ["left"] = vector.new(0, 0),
    ["right"] = vector.new(0, 0),
    ["middle"] = vector.new(0, 0)
}

local clearEvents = function()
    for a = 1, eventSize do
        readOnly[a] = nil
    end
    eventSize = 0
end
local refreshEvents = function()
    clearEvents()
    for a, b in ipairs(event) do
        readOnly[a] = b
    end
    eventSize = #event
end
local pressButton = function(t, k, x, y)
    local click = {[1] = "left", [2] = "right", [3] = "middle"}
    if t == "mouse_click" then
        pressed.click[k] = true
        pressed.click[click[k]] = true
        mousePos[k] = vector.new(x, y)
        mousePos[click[k]] = vector.new(x, y)
    elseif t == "mouse_up" then
        pressed.click[k] = false
        pressed.click[click[k]] = false
        mousePos[k] = vector.new(0, 0)
        mousePos[click[k]] = vector.new(0, 0)
    elseif t == "key" then
        pressed.key[k] = true
        pressed.key[keys.getName(k)] = true
    elseif t == "key_up" then
        pressed.key[k] = false
        pressed.key[keys.getName(k)] = false
    end
    pressed.key.shift = pressed.key.leftShift or pressed.key.rightShift
    pressed.key.ctrl = pressed.key.leftCtrl or pressed.key.rightCtrl
    pressed.key.alt = pressed.key.leftAlt or pressed.key.rightAlt
    pressed.key.enterKey = pressed.key.enter or pressed.key.numPadEnter
end

-- Call events[n] to get the nth parameter in the event.
readOnly.getEvent = function(...)
    event = {os.pullEvent(...)}
    refreshEvents()
    pressButton(event[1], event[2], event[3], event[4])
    return event
end
readOnly.getRawEvent = function(...)
    event = {os.pullEventRaw(...)}
    refreshEvents()
    pressButton(event[1], event[2], event[3], event[4])
    return event
end
readOnly.queueEvent = function(...)
    os.queueEvent(...)
end

-- t = "key" or "click"
-- k = the mouse/key id or name.
-- Example 1: events.isPressed("key", keys.leftShift) -> true or false if left shift is pressed.
-- Example 2: events.isPressed("key", "rightShift") -> true or false if right shift is pressed.
-- Example 3: events.isPressed("click", 1) -> true or false if left mouse click is pressed.
-- Example 4: events.isPressed("click", "right") -> true or false if right mouse click is pressed.
-- Look up the keys API for specific key names and id numbers.
readOnly.isPressed = function(t, k)
    if not OR(t, "click", "key") then
        error('bad argument #1 (expected "click" or "key")', 2)
    end
    if pressed[t][k] == nil then return false
    else return pressed[t][k] end
end

-- If specified mouse button is pressed, returns the x,y coordinate, else returns nil.
readOnly.mousePos = function(k)
    if pressed.click[k] then return mousePos[k].x, mousePos[k].y
    else return nil end
end

return {
    protected = true,
    readOnly = readOnly,
    meta = {
        __len = function() return #event end
    }
}
end)

--[[ Changelog
2024/01/03:
• Added general identifiers for keys that have duplicates on the keyboard:
  'shift', 'ctrl', 'alt', and 'enterkey'

2023/12/03:
• Removed 'sleep' and 'sleepRaw' due to redundancy. They worked perfectly for
  one specific situation, but they didn't work as intended for anything else.

2023/12/02:
• 'sleep' and 'sleepRaw' now return the timer value.

2023/12/01:
• Added comment to 'isPressed' for checking mouse clicks with strings.
• Added additional return values for 'isPressed' and 'mousePos' if the values
  being checked are nil.

2023/07/08:
• Removed event.eventIs() due to lack of use as well as it not always working as
  intended. Normal comparison operators are more practical, as well as the OR()
  and isBetween() functions from LibAppend.
• Changed comments at the top from saying to use 'require' to saying to use
  'dofile', which I forgot to do two updates ago.

2023/05/08:
• Added 'sleep' and 'sleepRaw'. Read the comments above the methods for info.

2023/05/06:
• Changed 'require' to 'dofile' which does the same thing but makes this API
  backwards compatible.
• 'mousePos' now uses the vector API from 'LibAppend'.

2023/03/09:
• Changed events class to a class header to reflect the changes made to
  "Class.lua".

2023/02/27:
• Changed 'protected' to 'readOnly' to reflect the changes made to "Class.lua".

2023/02/20:
• protected.isPressed() - swapped the 'or' comparison with the 'OR()' function
  from LibAppend.

2023/02/08:
• Version 2.0. The program has been completely revamped.
• Instead of setting a table with keys based on specific events, which was not
  actually that helpful, this helps streamline event processing.
• events.listen() has been replaced with events.getEvent().
• events.rawListen() has been replaced with events.getRawEvent().
• events.queue() has been replaced with events.queueEvent().
• Call events[n] to get the nth parameter of the event.
• events.eventIs() has been added in an attempt to help greatly reduce the amount
  of code needed for conditional statements revolving specifically around event
  parameters.
• Mouse button and key presses are now being tracked. Use events.isPressed() to
  check if a button is currently being pressed.
• Use events.mousePos() to get the current position of the specified mouse button,
  or nil if the specified mouse button is not pressed.

2022/06/29:
• Moved all functions into a table.

2022/06/26:
• Added eventQueue() to handle queuing events with os.queueEvent().
]]