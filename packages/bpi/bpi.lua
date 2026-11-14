--[[ This API is for loading and saving bpi files, which are my solution for
ComputerCraft image files with text, text color, and background color.
"BPI" stands for Better Paint Image.

Use 'bpi.load' with a file path to load an image.
The image table is formated as follows:
{
  [y] = { -- Y Coordinate
    [x] = { -- X Coordinate
      text = "c", -- Character
      tCol = "0", -- Text Color
      bCol = "f"  -- Background Color
    }
  }
}
The X and Y coordinates should be positive numbers greater than zero and less
than or equal to 2^128.

Use 'bpi.save' with an image table and a file path to save a bpi image.
Each pixel in the save file is formatted as follows:

X Length = 4 bits for the length in bytes of the X Coordinate.
Y Length = 4 bits for the legnth in bytes of the Y Coordinate.
X Coordinate = X Length bytes.
Y Coordinate = Y Length bytes.
Text Code = 1 byte for the text character code.
Text Color = 4 bits.
Background Color = 4 bits.

Each pixel may be between 5 and 35 total bytes depending on the size of the
coordinates. The pixels are not in any specific order. Empty spaces between
pixels may be treated as transparent pixels.

The Class API is required to run this program.
In the ComputerCraft terminal, run the following commands:
  Run 'pastebin get t2TvSiSU /API/Class.lua'
  Run 'pastebin get sSSyDAFm /API/bpi.lua'

Check out this post on the ComputerCraft forums to see how this file format can
can be used:
https://forums.computercraft.cc/index.php?topic=536.msg1750
]]

require("/apis/TeleClass")

bpi = Class(function()
local ro = {}

ro.save = function(image, path)
  local bin = {}
  local canSave = true

  local addByte = function(n)
    table.insert(bin, #bin+1, n)
  end

  local bitShift = function(n)
    local b = {}
    repeat
      table.insert(b, #b+1, bit32.band(n, 0xff))
      n = bit32.rshift(n, 8)
    until n == 0
    canSave = canSave and #b-1 <= 0xf
    -- Can't save if the X or Y coordinate is more than 16 bytes (128 bits)
    return b
  end

  for y, a in pairs(image) do
    for x, b in pairs(a) do
      local coords = {bitShift(x-1), bitShift(y-1)}
      addByte((#coords[2]-1) + bit32.lshift(#coords[1]-1, 4))

      for i, t in ipairs(coords) do
        for j, v in ipairs(t) do
          addByte(v)
        end
      end

      addByte(b.text:byte())
      addByte(tonumber(b.bCol, 16) + bit32.lshift(tonumber(b.tCol, 16), 4))
    end
  end

  canSave = canSave and #bin <= fs.getFreeSpace(shell.dir())
  if canSave then
    if path:sub(#path-3) ~= ".bpi" then
      path = path .. ".bpi"
    end
    local f = fs.open(path, "wb")
    if f then
      for i, v in ipairs(bin) do
        f.write(v)
      end
      f.close()
      return 0 -- Save successful
    else return 1 end -- Unknown error
  else return 2 end -- Image is too big/Out of space
end

ro.load = function(path)
  if path:sub(#path-3) ~= ".bpi" then
    path = path .. ".bpi"
  end
  if fs.exists(path) then
    local bin = {}
    local image = {}

    local f = fs.open(path, "rb")
    repeat
      local line = f.read()
      table.insert(bin, #bin+1, line)
    until line == nil
    f.close()

    local removeByte = function()
      local n = bin[1]
      table.remove(bin, 1)
      return n
    end

    local bitShift = function(l)
      local n = 0
      for i = 0, l do
        n = n + bit32.lshift(removeByte(), i*8)
      end
      return n
    end

    while #bin > 0 do
      local coordLength = removeByte()
      local teleX = bitShift(bit32.rshift(bit32.band(coordLength, 0xf0), 4))+1
      local teleY = bitShift(bit32.band(coordLength, 0x0f))+1
      image[teleY] = image[teleY] or {}
      image[teleY][teleX] = {}
      image[teleY][teleX].text = string.char(removeByte())
      local c = string.format("%02x", removeByte())
      image[teleY][teleX].tCol = c:sub(1, 1)
      image[teleY][teleX].bCol = c:sub(2, 2)
    end
    return image
  else
    error("File not found", 2)
  end
end

return {
  protected = true,
  readOnly = ro
}
end)()