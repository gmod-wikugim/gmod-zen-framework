module("zen")

---@class zen.map_reader
map_reader = _GET("map_reader")

---@class zen.map_edit.reader.dheader_t
---@field iden integer[32] // BSP file identifier
---@field version integer[32] // BSP file version
---@field LUMPS table<string, zen.map_edit.reader.lump_t> // lump directory array
---@field mapRevision integer[32] // the map's revision (iteration, version) number

---@class zen.map_edit.reader.lump_t
---@field fileofs integer[32] // offset into file (bytes)
---@field filelen integer[32] // offset into file (bytes)
---@field version integer[32] // lump format version
---@field header string
---@field data? string -- LUMP DATA
---@field dirt? string -- LUMP DIRT DATA
---@field lumpID number
---@field mapRevision number

local read_bytes = 0

---@param start number
---@param len number
---@return string
local function readSeparate(fl, start, len)
    assert(isnumber(start), "start not number")
    assert(isnumber(len), "len not number")

    local now_pointer = fl:Tell()

    fl:Seek(start)

    local data = fl:Read(len)

    read_bytes = read_bytes + len

    fl:Seek(now_pointer)

    return data
end

---@return string
local function readString(fl, bytes)
    read_bytes = read_bytes + bytes

    return fl:Read(bytes)
end

local function readInt(fl)
    read_bytes = read_bytes + 32

    return fl:ReadLong()
end

---@param start number
---@param data string
local function writeSeparate(fl, start, data)
    assert(isnumber(start), "start not number")
    assert(isstring(data), "data not is string")

    local now_pointer = fl:Tell()

    fl:Seek(start)

    fl:Write(data)

    fl:Seek(now_pointer)
end

---@param fl File
---@param data string
local function writeString(fl, data)
    fl:Write(data)
end

---@param fl File
---@param long number
local function writeInt(fl, long)
    fl:WriteLong(long)
end

---@param bytes number
---@return number MB
local function MB(bytes)
    return bytes / (1024 * 1024)
end

---@param input number|string
---@return string
local function MB_Nice(input)
    local bytes = isnumber(input) and input or #input
    ---@cast bytes number

    return table.concat({"(", math.Round(MB(bytes), 5), "Mb)"}, "")
end

---@param map_name? string
---@param export_path string
function map_reader.ExportBSP(map_name, export_path)
    local export_folder_path = string.GetPathFromFilename(export_path)
    if !file.IsDir(export_folder_path, "DATA") then
        ---@diagnostic disable-next-line: redundant-parameter
        file.CreateDir(export_folder_path, "DATA")
    end

    local fl = file.Open(export_path, "wb", "DATA")

    assert(fl != nil, "File can't be opened")

    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast fl File

    local MAP = map_reader.CreateMapLumps(map_name)

    /*
        dheader_t
        int			ident;
        int			version;
        lump_t		lumps[HEADER_LUMPS];
        int			mapRevision;				// the map's revision (iteration, version) number (added BSPVERSION 6)
    */

    print("Start exporting BSP")

    print("Writing map info... ")

    print("Writing MAP.iden... ")
    writeInt(fl, MAP.iden)
    print("Writing MAP.version... ")

    writeInt(fl, MAP.version)

    for k = 0, 60 do
        local header = LUMP_HEADERS[k]

        local LUMP = MAP.LUMPS[header]


        writeInt(fl, LUMP.fileofs)
        writeInt(fl, LUMP.lumpID)
        writeInt(fl, LUMP.version)
        writeInt(fl, LUMP.filelen)
        -- LUMP.char        = readString(4)
        writeInt(fl, LUMP.mapRevision)

        PrintTable(LUMP)


        /*
        lumpfileheader_t
        	int				lumpOffset;
            int				lumpID;
            int				lumpVersion;
            int				lumpLength;
            int				mapRevision;
        */

        if LUMP.filelen and LUMP.filelen > 0 then
            print("Writing lump: \t", LUMP.header, " / ", LUMP.filelen / (1024*1024))

            writeSeparate(fl, LUMP.fileofs, LUMP.dirt or "")
        end
    end


    writeInt(fl, MAP.mapRevision)

    print(MAP.mapRevision)

    fl:Flush()

    fl:Close()

    print("Map exported bsp to: ", export_path)
end


function map_reader.ReadLMP(lmp_path, MAP, bIsMap)
    local fl = file.Open(lmp_path, "rb", "GAME")
    assert(fl, "file not opened")

    /*
    dheader_t
        int			ident;
        int			version;
        lump_t		lumps[HEADER_LUMPS];
        int			mapRevision;				// the map's revision (iteration, version) number (added BSPVERSION 6)
    */

    if bIsMap then
        MAP.iden = readInt(fl)
        MAP.version = readInt(fl)

        print("MAP_VERSION: ", MAP.version)
    end

    ---@diagnostic disable-next-line: inject-field
    MAP.LUMPS = MAP.LUMPS or {}

    print("READ: ", lmp_path)

    for k = 0, 60, 1 do
        local header = LUMP_HEADERS[k]
        print("\t", k, " - ", header)
        MAP.LUMPS[header] = MAP.LUMPS[header] or {}

        /*
        lumpfileheader_t
        	int				lumpOffset;
            int				lumpID;
            int				lumpVersion;
            int				lumpLength;
            int				mapRevision;
        */


        local LUMP = MAP.LUMPS[header]
        LUMP.header         = header
        LUMP.fileofs        = readInt(fl)
        LUMP.lumpID         = readInt(fl)
        LUMP.version        = readInt(fl)
        LUMP.filelen        = readInt(fl)
        -- LUMP.char        = readString(4)
        LUMP.mapRevision   = readInt(fl)


        if !LUMP.fileofs then
            print(header)
            error("no LAMP.fileofs")
        end

        if !LUMP.filelen then
            print(header)
            error("no LAMP.filelen")
        end

        if LUMP.filelen == 0 then
            print("SKIP zero len\t", header)
            continue
        end

        if LUMP.fileofs == 0 then
            print("SKIP zero len\t", header)
            continue
        end

        if LUMP.fileofs > 0 and LUMP.filelen == 0 then
            LUMP._data_zero = 1
        end

        if LUMP.fileofs == 0 and LUMP.filelen == 0 then
            LUMP._data_exists = 0
        end


        if LUMP.fileofs > 0 && LUMP.filelen > 0  then
            LUMP._data_exists = 1
            local data = readSeparate(fl, LUMP.fileofs, LUMP.filelen)

            LUMP.dirt = data

            if data then
                local now_pointer = fl:Tell()
                fl:Seek(LUMP.fileofs)
                LUMP.data = map_reader.ReadLump(header, data, fl)
                fl:Seek(now_pointer)
            end
        end

        LUMP.proccessed = 1
    end

    if bIsMap then
        MAP.mapRevision = readInt(fl)
    end

    print("CLOSE: ", lmp_path)

    fl:Close()

end

---@param map_name? string map_name or game.GetMap()
---@return zen.map_edit.reader.dheader_t
function map_reader.CreateMapLumps(map_name)
    map_name = map_name or game.GetMap()

    assert(isstring(map_name), "map_name must be a string")
    local map_path = "maps/" .. map_name .. ".bsp"


    -- rp_bangclaw_opti



    local files = file.Find("maps/" .. map_name .. "_l_0.lmp", "GAME")

    local lump_files = {}

    if files then
        for k, v in pairs(files) do
            table.insert(lump_files, "maps/" .. v)
        end
    end

    assert(file.Exists(map_path, "GAME"), "Map file not found: " .. map_path)

    ---@type zen.map_edit.reader.dheader_t
    ---@diagnostic disable-next-line: missing-fields
    local MAP = {}

    map_reader.ReadLMP(map_path, MAP, true)

    for k, lmp_path in pairs(lump_files) do
        map_reader.ReadLMP(lmp_path, MAP, false)
    end

    return MAP
end

---@private
---@type table<string, fun(source:string): any>
map_reader.mt_LumpReaders = map_reader.mt_LumpReaders or {}

---@param lump_name string
---@param func fun(source: string, fl:File): any
function map_reader.RegisterLumpRead(lump_name, func)
    map_reader.mt_LumpReaders[lump_name] = func
end

---@private
---@param reader string
---@param source string
---@param fl File
---@return any
function map_reader.ReadLump(reader, source, fl)

    local funcReader = map_reader.mt_LumpReaders[reader]

    if funcReader then
        return funcReader(source, fl)
    else
        return "NO_READER"
    end
end

-- local HEADER = map_reader.CreateMapLumps()

-- PrintTable(HEADER)
-- PrintTable(HEADER.LUMPS["LUMP_GAME_LUMP"].data.list)

-- map_reader.ExportBSP(nil, "map_export/actual2.txt")