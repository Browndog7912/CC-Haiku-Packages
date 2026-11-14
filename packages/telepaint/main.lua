-- The following APIs are required for this program:
-- pastebin get Rac6Jxjg /API/LibAppend.lua
-- pastebin get t2TvSiSU /API/Class.lua
-- pastebin get KA2dK07y /API/Events.lua

-- Attribution: The file saving and loading functions have taken inspiration
-- from this program:
-- • https://www.computercraft.info/forums2/index.php?/topic/27331-micropaint-experimental-painting-program-for-tiny-pixels/

-- More info at: https://forums.computercraft.cc/index.php?topic=536.0
-- For some reason, images aren't showing up for me on the forum post no matter
-- what I do to try and update it, so here's an imgur album:
-- https://imgur.com/a/M9vQ2lS

require("/apis/TeleEvents")
require("/apis/bpi")

local termSize = vector.new(term.getSize())
local event = Events()
local image, color, menu

image = Class(function()
    local ro = {}

    local filePath
    local symbols = {
        [128] = {{1, 1}, {1, 1}, {1, 1}},
        [129] = {{0, 1}, {1, 1}, {1, 1}},
        [130] = {{1, 0}, {1, 1}, {1, 1}},
        [131] = {{0, 0}, {1, 1}, {1, 1}},
        [132] = {{1, 1}, {0, 1}, {1, 1}},
        [133] = {{0, 1}, {0, 1}, {1, 1}},
        [134] = {{1, 0}, {0, 1}, {1, 1}},
        [135] = {{0, 0}, {0, 1}, {1, 1}},
        [136] = {{1, 1}, {1, 0}, {1, 1}},
        [137] = {{0, 1}, {1, 0}, {1, 1}},
        [138] = {{1, 0}, {1, 0}, {1, 1}},
        [139] = {{0, 0}, {1, 0}, {1, 1}},
        [140] = {{1, 1}, {0, 0}, {1, 1}},
        [141] = {{0, 1}, {0, 0}, {1, 1}},
        [142] = {{1, 0}, {0, 0}, {1, 1}},
        [143] = {{0, 0}, {0, 0}, {1, 1}},
        [144] = {{1, 1}, {1, 1}, {0, 1}},
        [145] = {{0, 1}, {1, 1}, {0, 1}},
        [146] = {{1, 0}, {1, 1}, {0, 1}},
        [147] = {{0, 0}, {1, 1}, {0, 1}},
        [148] = {{1, 1}, {0, 1}, {0, 1}},
        [149] = {{0, 1}, {0, 1}, {0, 1}},
        [150] = {{1, 0}, {0, 1}, {0, 1}},
        [151] = {{0, 0}, {0, 1}, {0, 1}},
        [152] = {{1, 1}, {1, 0}, {0, 1}},
        [153] = {{0, 1}, {1, 0}, {0, 1}},
        [154] = {{1, 0}, {1, 0}, {0, 1}},
        [155] = {{0, 0}, {1, 0}, {0, 1}},
        [156] = {{1, 1}, {0, 0}, {0, 1}},
        [157] = {{0, 1}, {0, 0}, {0, 1}},
        [158] = {{1, 0}, {0, 0}, {0, 1}},
        [159] = {{0, 0}, {0, 0}, {0, 1}}
    }

    local source = {}
    source.image = {}
    source.scroll = vector.new()

    local teletext = {}
    teletext.image = {}
    teletext.scroll = vector.new()
    teletext.select = vector.new()

    local startDrag = vector.new()

    ro.resize = function()
        source.pos = vector.new(1, 1)
        source.size = vector.new(math.floor((termSize.x-1)*2/3), termSize.y)
        source.win = window.create(term.current(), 1, 1, source.size.x, source.size.y)
        teletext.pos = vector.new(source.size.x+2, 1)
        teletext.size = vector.new(math.ceil(source.size.x/2), math.ceil(source.size.y/3))
        teletext.win = window.create(term.current(), teletext.pos.x, 1, teletext.size.x, teletext.size.y)
    end

    ro.sourcePos = function()
        return vector.new(source.pos.x, source.pos.y)
    end
    ro.telePos = function()
        return vector.new(teletext.pos.x, teletext.pos.y)
    end
    ro.sourceSize = function()
        return vector.new(source.size.x, source.size.y)
    end
    ro.teleSize = function()
        return vector.new(teletext.size.x, teletext.size.y)
    end
    ro.pixelPos = function()
        local x, y, z = teletext.select.x, teletext.select.y
        if teletext.image[y] and teletext.image[y][x] then
            z = teletext.image[y][x].bCol
        else
            z = "f"
        end
        local returnPos = vector.new(
            teletext.select.x - teletext.scroll.x + teletext.pos.x - 1,
            teletext.select.y - teletext.scroll.y,
            2 ^ (15 - tonumber(z, 16))
        )
        if isBetween(returnPos.x, teletext.pos.x, termSize.x, true)
        and isBetween(returnPos.y, 1, teletext.size.y, true) then
            return returnPos
        end
    end

    local drawImage = function(i)
        local pos = vector.new()
        for y = 1, i.size.y do
            pos.y = i.scroll.y+y
            for x = 1, i.size.x do
                pos.x = i.scroll.x+x
                i.win.setCursorPos(x, y)
                if i.image[pos.y] and i.image[pos.y][pos.x] then
                    term.blit(i.image[pos.y][pos.x].text, i.image[pos.y][pos.x].tCol, i.image[pos.y][pos.x].bCol)
                else
                    term.blit("\127", "7", "f")
                end
            end
        end
    end
    ro.drawSource = function()
        drawImage(source)
    end
    ro.drawTele = function()
        drawImage(teletext)
        term.setCursorPos(teletext.pos.x-1, teletext.size.y+1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.black)
        term.write("x" .. teletext.scroll.x .. "y" .. teletext.scroll.y .. "  ")
        term.setCursorPos(teletext.pos.x, teletext.size.y+2)
        term.setBackgroundColor(colors.black)
        local x, y, pixel = teletext.select.x, teletext.select.y
        if teletext.image[y] and teletext.image[y][x] then
            pixel = teletext.image[y][x]
        end
        if pixel then
            term.blit(pixel.text, pixel.tCol, pixel.bCol)
            term.setTextColor(colors.red)
            term.write('  "\\' .. pixel.text:byte() .. '"')
        else
            term.write("         ")
        end
    end

    local convertPixel = function(pos)
        local pixelPos = vector.new(math.ceil(pos.x/2), math.ceil(pos.y/3))
        local pixelKeys = {text = 2, tCol = 0, bCol = 1}
        local symbol = {[2] = "\128"}
        local target = {{1, 1}, {1, 1}, {1, 1}}
        local nilTarget = {{false, false}, {false, false}, {false, false}}

        if source.image[pos.y+2] and source.image[pos.y+2][pos.x+1] then
            symbol[0] = source.image[pos.y+2][pos.x+1].bCol
            symbol[1] = source.image[pos.y+2][pos.x+1].bCol
        else
            symbol[0] = color.color(1)
            symbol[1] = color.color(1)
        end

        for y = 0, 2 do
            for x = 0, 1 do
                if source.image[pos.y+y] and source.image[pos.y+y][pos.x+x] then
                    if symbol[0] == symbol[1]
                    and source.image[pos.y+y][pos.x+x].bCol ~= symbol[1] then
                        symbol[0] = source.image[pos.y+y][pos.x+x].bCol
                    end
                else
                    nilTarget[y+1][x+1] = true
                end
            end
        end

        for y = 0, 2 do
            for x = 0, 1 do
                if source.image[pos.y+y] and source.image[pos.y+y][pos.x+x] then
                    if source.image[pos.y+y][pos.x+x].bCol == symbol[0] then
                        target[y+1][x+1] = 0
                    elseif source.image[pos.y+y][pos.x+x].bCol == symbol[1] then
                        target[y+1][x+1] = 1
                    else
                        target[y+1][x+1] = 1 - color.ditherMode()
                    end
                end
            end
        end

        local targetCheck = true
        for a, b in pairs(symbols) do
            local sourceCheck = true
            for y = 1, 3 do
                for x = 1, 2 do
                    sourceCheck = sourceCheck and target[y][x] == b[y][x]
                    targetCheck = targetCheck and nilTarget[y][x]
                end
            end
            if targetCheck then
                break
            end
            if sourceCheck then
                symbol[2] = string.char(a)
                break
            end
        end

        if targetCheck then
            if teletext.image[pixelPos.y] then
                teletext.image[pixelPos.y][pixelPos.x] = nil
                if textutils.serialize(teletext.image[pixelPos.y]) == "{}" then
                    teletext.image[pixelPos.y] = nil
                end
            end
        else
            teletext.image[pixelPos.y] = teletext.image[pixelPos.y] or {}
            teletext.image[pixelPos.y][pixelPos.x] = {
                text = symbol[2],
                tCol = symbol[0],
                bCol = symbol[1]
            }
        end
        ro.drawTele()
    end

    ro.convertImage = function()
        for y, a in pairs(teletext.image) do
            for x, b in pairs(teletext.image[y]) do
                convertPixel(vector.new(x*2-1, y*3-2))
            end
        end
    end

    local scroll = function(x, y)
        x, y = x or 0, y or 0
        source.scroll = source.scroll + vector.new(x, y)
        if source.scroll.x < 0 then
            source.scroll.x = 0
        end
        if source.scroll.y < 0 then
            source.scroll.y = 0
        end
        teletext.scroll = vector.new(
            math.floor(source.scroll.x/2),
            math.floor(source.scroll.y/3)
        )
        ro.drawSource()
        ro.drawTele()
    end

    local convertSource = function(sourceX, sourceY, pixel)
        local charCode = pixel.text:byte()
        for a, b in ipairs(symbols[charCode]) do
            local y = sourceY+a-1
            source.image[y] = source.image[y] or {}
            for c, d in ipairs(b) do
                local x = sourceX+c-1
                source.image[y][x] = {
                    text = " ",
                    tCol = "0"
                }
                if d == 0 then
                    source.image[y][x].bCol = pixel.tCol
                else
                    source.image[y][x].bCol = pixel.bCol
                end
            end
        end
    end

    ro.ui = function()
        if OR(event[1], "mouse_click", "mouse_drag") then
            if event.isPressed("key", keys.leftShift) or event.isPressed("key", keys.leftShift) then
                if startDrag.x > 0 and startDrag.y > 0 then
                    local delta = startDrag - vector.new(event[3], event[4])
                    if not(event[3] <= source.size.x) then
                        delta.x = delta.x * 2
                        delta.y = delta.y * 3
                    end
                    scroll(delta.x, delta.y)
                end
                startDrag = vector.new(event[3], event[4])
            elseif event[3] <= source.size.x then
                local pos = vector.new(event[3]+source.scroll.x, event[4]+source.scroll.y)
                source.image[pos.y] = source.image[pos.y] or {}
                if event[2] == 2 then
                    source.image[pos.y][pos.x] = nil
                    if textutils.serialize(source.image[pos.y]) == "{}" then
                        source.image[pos.y] = nil
                    end
                elseif event[2] == 3 then
                    if source.image[pos.y] and source.image[pos.y][pos.x] then
                        color.color(0, source.image[pos.y][pos.x].bCol)
                        color.drawColor()
                    end
                else
                    source.image[pos.y][pos.x] = {
                        text = " ",
                        tCol = "0",
                        bCol = color.color(event[2]-1)
                    }
                end
                convertPixel(vector.new(math.ceil(pos.x/2)*2-1, math.ceil(pos.y/3)*3-2))
                ro.drawSource()
            elseif event[3] >= teletext.pos.x then
                if event[2] == 1 then
                    teletext.select.x = event[3]-teletext.pos.x+teletext.scroll.x+1
                    teletext.select.y = event[4]+teletext.scroll.y
                else
                    teletext.select = vector.new()
                end
                ro.drawTele()
            end
        elseif event[1] == "mouse_up" then
            startDrag = vector.new()
        elseif event[1] == "mouse_scroll" then
            if event[3] <= source.size.x then
                if event.isPressed("key", keys.leftShift) or event.isPressed("key", keys.rightShift) then
                    scroll(event[2], 0)
                else
                    scroll(0, event[2])
                end
            else
                if event.isPressed("key", keys.leftShift) or event.isPressed("key", keys.rightShift) then
                    scroll(event[2]*2, 0)
                else
                    scroll(0, event[2]*3)
                end
            end
        end
    end

    ro.save = function()
        menu.canSave(bpi.save(teletext.image, filePath)+1)
    end

    local load = function()
        teletext.image = bpi.load(filePath)
        for y, a in pairs(teletext.image) do
            for x, b in pairs(a) do
                convertSource(x*2-1, y*3-2, b)
            end
        end
    end

    return {
        ctor = function(path)
            if path == nil or path == "" then
                error("Usage: telepaint <path>", 0)
            end
            if path:sub(1, 1) == "/" then
                filePath = path
            else
                filePath = shell.dir() .. path
            end
            if filePath:sub(filePath:len()-3, filePath:len()) ~= ".bpi" then
                filePath = filePath .. ".bpi"
            end
            if fs.exists(filePath) then
                load()
            end
            ro.resize()
        end,
        protected = true,
        readOnly = ro
    }
end)(...)

color = Class(function()
    local ro = {}
    local pos = vector.new(image.telePos().x, image.teleSize().y+3)
    local col = {[0] = "0", [1] = "f"}
    local ditherMode = 0

    ro.resize = function()
        pos = vector.new(image.telePos().x, image.teleSize().y+3)
    end

    ro.pos = function()
        return vector.new(pos.x, pos.y)
    end

    ro.color = function(n, c)
        for a = 0, 15 do
            if c == tobase(a, 16):lower() then
                col[n] = c
            end
        end
        if OR(n, 0, 1) then
            return col[n]
        else
            return col[0], col[1]
        end
    end

    ro.ditherMode = function()
        return ditherMode
    end

    ro.drawColor = function()
        for a = 0, 15 do
            term.setCursorPos(pos.x+a%8, pos.y+math.floor(a/8))
            term.blit(" ", "0", tobase(a, 16))
        end
        term.setCursorPos(pos.x+8, pos.y)
        term.blit(" ", "0", col[0])
        term.setCursorPos(pos.x+8, pos.y+1)
        term.blit(" ", "0", col[1])
        term.setCursorPos(pos.x, pos.y+2)
        term.blit("Dither: " .. ditherMode, "00000000f", "ffffffff0")
    end

    ro.ui = function()
        if event[1] == "mouse_click" and isBetween(event[2], 0, 3)
        and isBetween(event[3], pos.x, pos.x+7, true)
        and isBetween(event[4], pos.y, pos.y+1, true) then
            col[event[2]-1] = tobase((event[3] - pos.x) + (event[4] - pos.y) * 8, 16):lower()
            ro.drawColor()
            image.convertImage()
        elseif event[1] == "mouse_click" and event[4] == pos.y+2 then
            ditherMode = 1 - ditherMode
            ro.drawColor()
            image.convertImage()
        elseif event[1] == "char" and OR(event[2], "0", "1") then
            ditherMode = tonumber(event[2])
            ro.drawColor()
            image.convertImage()
        end
    end

    return {
        protected = true,
        readOnly = ro
    }
end)()

menu = Class(function()
    local ro = {}
    local pos = vector.new(image.telePos().x, image.teleSize().y+6)
    local selectSave = true
    local menuOpen = false
    local menuText = 0
    local text = {
        [0] = {"Ctrl or", "click to"},
        [1] = {"The file", "was saved"},
        [2] = {"Unable to", "save file"},
        [3] = {"File size", "too big!"},
    }

    ro.resize = function()
        pos = vector.new(image.telePos().x, image.teleSize().y+6)
    end

    ro.pos = function()
        return vector.new(pos.x, pos.y)
    end

    ro.menuOpen = function()
        return menuOpen
    end

    ro.drawMenu = function()
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.yellow)
        term.setCursorPos(pos.x, pos.y)
        term.write(text[menuText][1])
        term.setCursorPos(pos.x, pos.y+1)
        term.write(text[menuText][2])
        term.setCursorPos(pos.x, pos.y+2)
        term.blit("Save Exit", "fffffffff", "8888f8888")
        term.setTextColor(colors.white)
        term.setCursorPos(pos.x+4, pos.y+2)
        if menuOpen then
            if selectSave then term.write("\17")
            else term.write("\16") end
        else
            term.write(" ")
        end
    end

    ro.canSave = function(i)
        menuText = expect.range(i, 0, #text)
        ro.drawMenu()
    end

    ro.ui = function()
        if event[1] == "key" and OR(event[2], keys.leftCtrl, keys.rightCtrl) then
            menuOpen = not menuOpen
            ro.drawMenu()
        elseif (event[1] == "key" and event[2] == keys.left)
        or (event[1] == "mouse_click" and event[2] == 1
        and isBetween(event[3], pos.x-1, pos.x+4) and event[4] == pos.y+2) then
            selectSave = true
            ro.drawMenu()
            if event[1] == "mouse_click" then
                menuOpen = true
                event.queueEvent("key", keys.enter)
            end
        elseif (event[1] == "key" and event[2] == keys.right)
        or (event[1] == "mouse_click" and event[2] == 1
        and isBetween(event[3], pos.x+4, pos.x+9) and event[4] == pos.y+2) then
            selectSave = false
            ro.drawMenu()
            if event[1] == "mouse_click" then
                menuOpen = true
                event.queueEvent("key", keys.enter)
            end
        elseif event[1] == "key" and OR(event[2], keys.enter, keys.numPadEnter) then
            if selectSave then
                image.save()
                menuOpen = false
                ro.drawMenu()
            else
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1, 1)
                error()
            end
        end
    end

    return {
        protected = true,
        readOnly = ro
    }
end)()

local drawAll = function()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    if termSize.x < 26 or termSize.y < 12 then
        error("Minimum term size is 26x12. Actual term size is " .. termSize.x .. "x" .. termSize.y, 0)
    end
    paintutils.drawFilledBox(1, 1, image.sourceSize().x+1, termSize.y, colors.gray)
    paintutils.drawFilledBox(image.telePos().x, 1, termSize.x, image.teleSize().y+1, colors.gray)
    image.drawSource()
    image.drawTele()
    color.drawColor()
    menu.drawMenu()
end

drawAll()
while true do
    local pixelPos = image.pixelPos()
    if pixelPos then
        term.setCursorPos(pixelPos.x, pixelPos.y)
        term.setTextColor(pixelPos.z)
        term.setCursorBlink(true)
    end
    event.getEvent()
    term.setCursorBlink(false)
    if event[1] == "key" and OR(event[2], keys.leftCtrl, keys.rightCtrl)
    or (event[1] == "mouse_click" and event[2] == 1
    and isBetween(event[3], menu.pos().x, menu.pos().x+8, true)
    and event[4] == menu.pos().y+2) or menu.menuOpen() then
        menu.ui()

    elseif (event[1] == "mouse_click" and isBetween(event[2], 0, 3)
    and isBetween(event[3], color.pos().x, color.pos().x+8, true)
    and isBetween(event[4], color.pos().y, color.pos().y+3, true))
    or (event[1] == "char" and OR(event[2], "0", "1")) then
        color.ui()

    elseif (OR(event[1], "mouse_click", "mouse_drag", "mouse_scroll")
    and (event[3] <= image.sourceSize().x
    or (event[3] >= image.telePos().x and event[4] <= image.teleSize().y)))
    or event[1] == "mouse_up" then
        image.ui()

    elseif event[1] == "term_resize" then
        termSize = vector.new(term.getSize())
        image.resize()
        color.resize()
        menu.resize()
        drawAll()
    end
end

--[[ Changelog
2024/09/09:
• Fixed color menu not being drawn in the correct Y position when resizing
  the screen.

2024/05/14:
• Changed 'doFile' to 'require'.
• Added API for bpi. Files will now be saved and loaded using this API.
• Added a link to an imgur album with all the screenshots since they don't seem
  to want to show up in the forum post for some reason.

2023/07/10:
• One more revision to the save/load functions, hopeully the last for a while.
  The .bpi file size has been reduced once again.
• The length of the x and y coordinates are now only 1 byte collectively.
• 4 bits for length of x, and another 4 bits for the length of y.
• Posted to Pastebin and the computercraft.cc forums.

2023/07/09:
• Revised the save and load functions again. Files will no longer be limitted to
  a maximum size of 256 KB.
  • An extra byte will be used to tell how many bytes the x and y coordinates
    are, with the max number of bytes per coordinate being 32 (256 bits).
  • Coordinates whose values are less than 256 will only be one byte in the
    file, less than 65536 will be two bytes, and so on.
  • This also means that the file size will compound based on how big the image
    is. I still can't imagine anyone making images that big, but at least now
    that silly file size restriction has been removed while still keeping the
    file sizes relatively low.
• The main menu will now tell you if the file is too big for the remaining space
  in the computer. It will also tell you this if a coordinate is more than 256
  bits (which shouldn't even be possible).
• The main menu will tell you if it was unable to open the file for saving for
  any other reason.
• The main menu will tell you if the file was saved successfuly.
• The restriction to scrolling has also been removed.
• The scroll position is now being printed on the border.
• The colors have been moved around to make room for a new feature.
• Left clicking on the output image will select a pixel. The pixel will be
  highlighted with the shell cursor, and the pixel along with its character code
  will be displayed at the top of the menu window.
• Right or middle clicking on the output image will deselect the pixel.

2023/07/08:
• Renamed the program to "telepaint.lua" so as to not conflict with the name
  of the program credited in the attribution.
• All variables referencing the micro image have been renamed to 'teletext' or
  'tele*'.
• Changed right click to erase and middle click to pick a color on the canvas.
• The second selected color is now only used for converting transparent pixels to
  the background color of the output image.
• The outputs of the 'tobase' function are now being converted to lower case to
  prevent errors with reading the text and background colors.
• Revised the save and load functions to reduce the file size.
• The output image size is now limited to 256x256 characters, which is 512x768
  teletext pixels. This sets the maximum file size to 256 KB which is an eighth
  of the default capacity of a CC computer. That much shouldn't even be needed
  for ComputerCraft, but this way the entire byte for each coordinate gets used.
• Fixed the dithering effect being applied to pixels with the text and
  background colors. The effect should only be applied to additional colors.

2023/07/07:
• Changing the selected colors or the dithering mode will update the entire
  micro image with the new settings.
• Using the scroll wheel while the mouse is over the source or micro image will
  scroll the image vertically.
• Holding Shift while scrolling will scroll horizontally.
• Scrolling over the micro image will have a vertical magnitude of 3 and a
  horizontal magnitude of 2.
• Holding Shift while click anddragging the mouse on either the source or micro
  image will pan the image by their respective magnitude.
• Files can now be saved using the save button. Keyboard and mouse both work.
• Loading a file works the same way as the built in paint program.
  Usage: micropaint <path>

2023/07/06:
• "Pixels" can now be painted to the source image.
• The source image will immediately be converted to the micro image when
  painting.
• The primary color is the color of the bottom-right most pixel in the micro
  pixel.
• The secondary color is the first color in the micro pixel (going from top left
  to bottom right) that is not the primary color.
• When the dithering mode is 0, any colors that are not the primary or secondary
  are converted to the primary.
• When the dithering mode is 1, any colors that are not the primary or secondary
  are converted to the secondary.
• If the secondary pixels are transparent, it will use the primary color for
  those pixels.
• If the primary pixel is transparent, it will use the color selected for right
  click as the primary color.

2023/07/05:
• Created UI with all of the menu controls being functional.
• The window to the left will be the source image, containing ComputerCraft
  "pixels".
• The window to the top right will be the micro image, containing the symbols
  converted from the source image.
• Transparency is represented by the character "\127" with a black background
  and gray text color.
• The window to the bottom right contains all of the menu options.
• Clicking the color pixels with left or right click changes the selected
  color for left or right click.
• Clicking "Dither: #" toggles the dithering mode.
• Clicking the "Save" button initiates the save function. The actual save
  function has not been implemented yet.
• Clicking the "Exit" button exits the program.
• Pressing Ctrl toggles an arrow cursor pointing at the "Save" or "Exit"
  buttons. Left or right arrow keys change what it points at, and Enter
  initiates the button's action.

2023/07/04:
• Made prototype for converting ComputerCraft "pixels" to the pixel symbols
  of character codes between 128 and 159.
]]