/*
    It's zen sub-subsystem for Export Map
    author: gmod-developer@srdev.pw

    Features:
    - Read map lumps
*/



local PACKAGE_NAME    = "BSP Exporter"
local PACKAGE_VERSION = "1.0"


/*

-----------------------------------------------------
--- MDL PARSER --------------------------------------
-----------------------------------------------------

*/

local color_client  = Color(255, 125, 0)
local color_server  = Color(0, 125, 255)
local color_default = Color(200, 200, 200)
local color_white   = Color(255,255,255)
local color_green   = Color(0,255,0)
local color_red     = Color(255,0,0)
local color_warn    = Color(255,125,0)

local i, lastcolor
local MsgC = MsgC
local IsColor = IsColor
local _sub = string.sub
local function log(...)
    local args = {...}
    local count = #args

    local text_color = CLIENT and color_client or color_server

    i = 0

    MsgC(text_color, "z> ", color_default)
    if count > 0 then
        while i < count do
            i = i + 1
            local dat = args[i]
            if type(dat) == "string" and _sub(dat, 1, 1) == "#" and lang.L then
                dat = lang.L(dat)
            end
            if IsColor(dat) then
                lastcolor = dat
                continue
            end
            if lastcolor then
                MsgC(lastcolor, dat)
            else
                MsgC(dat)
            end
        end

        if lastcolor then
            lastcolor = nil
        end
    end
    MsgC("\n", color_white)
end

local lower = string.lower
local ins = table.insert
local _C = table.concat
local get_dir = string.GetPathFromFilename
local get_filename = string.GetFileFromFilename


--- Smart function to Concat pathes
---@vararg string
---@return string
local function _CPaths(...)
    local path_array = {...}

    for k, str in pairs(path_array) do
        // Change \ to /
        str = str:gsub("\\", "/")

        // Remove /.*
        str = str:gsub("/(%.%*)$", "")

        // Remove / from line start
        str = str:gsub("^([/]*)", "")

        // Remove / from line end
        str = str:gsub("([/]*)$", "")


        path_array[k] = str
    end

    return _C(path_array, "/")
end

--- Return extension from path, include double.point extension
---@param path string
---@return string
local function get_ext(path) return path:match("[%w_-]+(%..*)$") or "" end

--- Return upper directory
---@param path string
---@return string
local function get_dir(path)
    // Change \ to /
    path = path:gsub("\\", "/")

    return path:match("(.*)/.*$") or ""
end

--- Return filename without extension from path
---@param path string
---@return string
local function get_name(path)
    path = string.GetFileFromFilename(path)

    return path:match("([^.]*)")
end

local function lmatch(word, pattern)
    word = lower(word)
    pattern = lower(pattern)
    return word:match(pattern)
end


local function CreateDirectory(dir)
    if !file.IsDir(dir, "DATA") then
        file.CreateDir(dir)
        if !file.IsDir(dir, "DATA") then
            log("Failed to create directory: " .. dir)
        end
    end
end

local function FileWrite(path, data, bNotLog)
    local Dir = string.GetPathFromFilename(path)
    CreateDirectory(Dir)

    local bWithDatExt = false

    local fl = file.Open( path, "wb", "DATA" )
    if (!fl) then
        fl = file.Open(path .. ".dat", "wb", "DATA")
        if(!fl) then
            if !bNotLog then
                log(path, ": Cannot be open for writing operations.. (include with .dat ext)")
            end
            return false
        end
    end

    fl:Write(data)
    fl:Close()

    if !bNotLog then
        if bWithDatExt then
            log(path, ": Success writen with .dat ext")
        else
            log(path, ": Success writen")
        end
    end

    return true
end

--- Get file data
---@param path string
---@param GPATH string?
local function FileRead(path, GPATH)
    GPATH = GPATH or "GAME"
    return file.Read(path, GPATH)
end

--- Check file is exists
---@param path string
---@param GPATH string?
---@return boolean
local function FileExists(path, GPATH)
    GPATH = GPATH or "GAME"
    local bExists = file.Exists(path, GPATH)
    return bExists
end

--- Search files by patters, and return full path
---@param path string
---@param GPATH string?
---@return string[]
local function FileSearch(path, GPATH)
    GPATH = GPATH or "GAME"
    local files = file.Find(path, GPATH)
    local dir = get_dir(path)

    local result = {}
    if files then
        for k, v in pairs(files) do
            local nice_path = _CPaths(dir, v)
            ins(result, nice_path)
        end
    end

    return result
end

local function readBsp(filePath)

    /*
        Read functions
    */


    local bspTable = {}

    -- Open the BSP file
    local fl = file.Open(filePath, "rb", "GAME")
    if not fl then
        error("Could not open file: " .. filePath)
    end

    local function readBool() return tonumber(fl:Read(1)) == 1 end
    local function readInt() return fl:ReadLong() end
    local function readShort() return fl:ReadShort() end
    local function readFloat() return fl:ReadFloat() end
    local function readString(amount) return fl:Read(amount) end
    local function readStringSeparate(start, len)
        local now_pointer = fl:Tell()
            fl:Seek(start)
            local data = fl:Read(len)
            fl:Seek(now_pointer)
        return data
    end
    local function readNumberSeparate(start, len)
        return tonumber(readStringSeparate)
    end
    local function readByteAsNumber(amount) return tonumber(fl:Read(amount)) end
    local function readVector()
        return Vector(readFloat(),readFloat(),readFloat())
    end
    local function readQuaternion()
        return {readFloat(),readFloat(),readFloat(),readFloat()}
    end
    local function readRadianEuler()
        return {readFloat(),readFloat(),readFloat()}
    end
    local function readMatrix3x4_t()
        local m = {}
        for i = 1, 3 do
            m[i] = {}
            for j = 1, 4 do
                m[i][j] = readFloat()
            end
        end
        return m
    end
    local function readAutoString()
        local tbl = {}

        // TODO: Be ceraful
        for k = 1, 128 do
            local char = fl:Read(1)
            if char == "\0" then
                break;
            end

            table.insert(tbl, char)
        end

        return table.concat(tbl)
    end

    local function readIntArray(amount)
        local tbl = {}

        for k = 1, amount do
            table.insert(tbl, readInt())
        end

        return tbl
    end

    local function readFloatArray(amount)
        local tbl = {}

        for k = 1, amount do
            table.insert(tbl, readFloat())
        end

        return tbl
    end

    local function readArrayFunc(amount, func)
        local tbl = {}

        for k = 1, amount do
            tbl[k] = func()
        end

        return tbl
    end

    local function readSwapArrayFunc(offset, amount, func)
        local currentTell = fl:Tell()

        fl:Seek(offset)

        local tbl = readArrayFunc(amount, func)

        fl:Seek(currentTell)

        return tbl
    end

    local function DECLARE_BYTESWAP_DATADESC(func, optionalOffset)
        local currentTell = fl:Tell()

        if optionalOffset then
            fl:Seek(optionalOffset)
        end

        func()

        fl:Seek(currentTell)
    end



    local HEADER_LUMPS = 64

    local function readLumps()
        local lumps = {}

        for k = 0, HEADER_LUMPS-1 do
            local lump = {}
            lump.fileofs = readInt()
            lump.filelen = readInt()
            lump.version = readInt()
            lump.uncompressedSize = readInt()

            lumps[k] = lump
        end

        return lumps
    end


    /*
        Custom stuff next:
    */

    -- Read dheader_t
    bspTable.ident = readInt()
    bspTable.version = readInt()

    bspTable.lump_t = readLumps()

    bspTable.mapRevision = readInt()


    log("Map readed:", filePath)
    PrintTable(bspTable)


    return bspTable
end

/*

-----------------------------------------------------
--- EXPORTER ----------------------------------------
-----------------------------------------------------

*/


concommand.Add("export_current_map", function (ply, cmd, args, argStr)
    readBsp(_CPaths("maps", game.GetMap() .. ".bsp"))
end)



return {
    PACKAGE_NAME = PACKAGE_NAME,
    PACKAGE_VERSION = PACKAGE_NAME,
}