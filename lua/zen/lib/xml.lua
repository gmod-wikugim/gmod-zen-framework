module("zen", package.seeall)

-- https://github.com/jonathanpoelen/lua-xmlparser

local string, pairs = string, pairs

local slashchar = string.byte('/', 1)
local E = string.byte('E', 1)


--! Return a document `table`.
--! @code
--!   document = {
--!     children = {
--!       { text=string } or
--!       { tag=string,
--!         attrs={ [name]=value ... },
--!         orderedattrs={ { name=string, value=string }, ... },
--!         children={ ... }
--!       },
--!       ...
--!     },
--!   }
--! @endcodes
--! @param[in] s string : xml data
--! @param[in] evalEntities boolean
--! @return table
function zen.ParseXML(s)
  -- remove comments
  s = s:gsub('<!%-%-(.-)%-%->', '')

  local t, l = {}, {}

  local addtext = function(txt)
    txt = txt:match'^%s*(.*%S)' or ''
    if #txt ~= 0 then
      t[#t+1] = {text=txt}
    end
  end

  s:gsub('<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)', function(type, name, closed, txt)
    -- open
    if #type == 0 then
      local attrs, orderedattrs = {}, {}
      if #closed == 0 then
        local len = 0
        for all,aname,_,value,starttxt in string.gmatch(txt, "(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))") do
          len = len + #all
          attrs[aname] = value
          orderedattrs[#orderedattrs+1] = {name=aname, value=value}
          if #starttxt ~= 0 then
            txt = txt:sub(len+1)
            closed = starttxt
            break
          end
        end
      end
      t[#t+1] = {tag=name, attrs=attrs, children={}, orderedattrs=orderedattrs}

      if closed:byte(1) ~= slashchar then
        l[#l+1] = t
        t = t[#t].children
      end

      addtext(txt)
    -- close
    elseif '/' == type then
      t = l[#l]
      l[#l] = nil

      addtext(txt)
    end
  end)

  return {children=t}
end