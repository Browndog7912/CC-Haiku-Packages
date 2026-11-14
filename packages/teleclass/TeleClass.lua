-- This is a script that attempts emulate the creation of class based objects
--   used within OOP languages.
-- C++ is the inspiration for the design of this script.
-- You can get this program from https://pastebin.com/t2TvSiSU
-- If you are running this in ComputerCraft, use the following command to
--   download it: pastebin get t2TvSiSU "/API/Class.lua"
-- In ComputerCraft, this file should be in "/API/" in the root directory to
--   ensure all programs that use this script function properly.
-- An in depth guide to this script can be found here:
--   https://pastebin.com/upj3fgyZ

-- Sets a protected metatable.
readOnly = function(t, meta, ro)
  meta = meta or {}
  meta.__pairs = meta.__pairs or function()
    local keys = {}
    for _, o in pairs({t, ro}) do
      for k, v in next, o do
        keys[k] = v
      end
    end
    return next, keys
  end
  meta.__index = ro or meta.__index
  meta.__metatable = meta.__metatable or false
  return setmetatable(t, meta)
end

-- Checks if values are or are NOT of specified types.
typeCheck = function(member, memberName, types, level, invert)
  local err = true
  level = level or 3
  local errorMessage = "expected '"..memberName.."' to be type "

  for a, b in ipairs(types) do
    if a > 1 then errorMessage = errorMessage.." or " end
    errorMessage = errorMessage..b
    if (not invert and type(member) == b) or (invert and not type(member) == b) then
      err = false
      break
    end
  end
  errorMessage = errorMessage..", got "..type(member)
  if err then error(errorMessage, level) end
end

-- Object Constructor.
Object = function(class, ...)
  typeCheck(class, "class", {"table"})
  typeCheck(class.ctor, "ctor", {"function", "nil"})
  typeCheck(class.protected, "protected", {"boolean", "nil"})
  typeCheck(class.public, "public", {"table", "nil"})
  typeCheck(class.readOnly, "readOnly", {"table", "nil"})
  typeCheck(class.meta, "meta", {"table", "nil"})

  class.public = class.public or {}
  class.meta = class.meta or {}

  class.meta.__len = class.meta.__len or function()
    local size = 0
    for k, v in ipairs(class.public) do
      size = size + 1
    end
    return size
  end
  if class.ctor == nil then
    class.meta.__call = class.meta.__call or function() end
  else
    class.meta.__call = function(self, ...)
      return class.ctor(...)
    end
  end
  if class.protected then
    class.meta.__newindex = function() error("attempt to update a protected object", 2) end
  end

  class.meta.__call(nil, ...)
  local obj = readOnly(class.public, class.meta, class.readOnly)
  return obj
end
  
  -- Class Constructor.
Class = function(header)
  typeCheck(header, "header", {"function"})
  local h = header()
  typeCheck(h, "head", {"table"})
  typeCheck(h.ctor, "ctor", {"function", "nil"})
  typeCheck(h.protected, "protected", {"boolean", "nil"})
  typeCheck(h.public, "public", {"table", "nil"})
  typeCheck(h.readOnly, "readOnly", {"table", "nil"})
  typeCheck(h.meta, "meta", {"table", "nil"})

  return readOnly({}, {
      __index = {h = header},
      __call = function(self, ...) return Object(header(...), ...) end,
      __newindex = function() error("attempt to update a class, access denied", 3) end
  })
end

--[[ Changelog:
The changelog has been moved to https://pastebin.com/PTWQcPsP
]]