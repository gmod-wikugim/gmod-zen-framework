module("zen")

---@class zen.map_reader
map_reader = _GET("map_reader")

---@class zen.map_edit.reader.dheader_t
---@field iden integer[32] // BSP file identifier
---@field version integer[32] // BSP file version
---@field LUMPS table<string, zen.map_edit.reader.lump_t> // lump directory array
---@field LUMPS_len_sum integer[32] // sum of all lumps length
---@field mapRevision integer[32] // the map's revision (iteration, version) number
---@field mapFileSize integer[32] // the map's file size (in bytes)
---@field read_bytes integer[32] // the map's file size (in bytes)
---@field INFO string

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


---@param READER_DATA zen.map_edit.reader.READER
---@param fl File
---@param start number
---@param len number
---@return string
local function readSeparate(READER_DATA, fl, start, len)
    assert(isnumber(start), "start not number")
    assert(isnumber(len), "len not number")

    local now_pointer = fl:Tell()

    fl:Seek(start)

    local data = fl:Read(len)

    read_bytes = read_bytes + len

    READER_DATA.mark_as_read(start, len)

    fl:Seek(now_pointer)

    return data
end

---@param READER_DATA zen.map_edit.reader.READER
---@param fl File
---@param bytes number
---@return string
local function readString(READER_DATA, fl, bytes)
    read_bytes = read_bytes + bytes

    READER_DATA.mark_as_read(fl:Tell(), bytes)

    return fl:Read(bytes)
end

---@param READER_DATA zen.map_edit.reader.READER
---@param fl File
local function readInt(READER_DATA, fl)
    read_bytes = read_bytes + 32

    READER_DATA.mark_as_read(fl:Tell(), 32)

    return fl:ReadLong()
end

---@param READER_DATA zen.map_edit.reader.READER
---@param fl File
---@param start number
---@param data string
local function writeSeparate(READER_DATA, fl, start, data)
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


---@param READER_DATA zen.map_edit.reader.READER
---@param lmp_path string
---@param MAP zen.map_edit.reader.dheader_t
---@param bIsMap boolean
function map_reader.ReadLMP(READER_DATA, lmp_path, MAP, bIsMap)
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
        MAP.iden = readInt(READER_DATA, fl)
        MAP.version = readInt(READER_DATA, fl)

        print("MAP_VERSION: ", MAP.version)
    end


    ---@diagnostic disable-next-line: inject-field
    MAP.LUMPS = MAP.LUMPS or {}
    MAP.LUMPS_len_sum = 0

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
        LUMP.fileofs        = readInt(READER_DATA, fl)
        LUMP.lumpID         = readInt(READER_DATA, fl)
        LUMP.version        = readInt(READER_DATA, fl)
        LUMP.filelen        = readInt(READER_DATA, fl)
        -- LUMP.char        = readString(4)
        LUMP.mapRevision   = readInt(READER_DATA, fl)

        MAP.LUMPS_len_sum = MAP.LUMPS_len_sum + LUMP.filelen


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
            local data = readSeparate(READER_DATA, fl, LUMP.fileofs, LUMP.filelen)

            LUMP.dirt = data

            if data then
                local now_pointer = fl:Tell()
                fl:Seek(LUMP.fileofs)
                LUMP.data = map_reader.ReadLump(READER_DATA, header, data, fl)
                fl:Seek(now_pointer)
            end
        end

        LUMP.proccessed = 1
    end

    if bIsMap then
        MAP.mapRevision = readInt(READER_DATA, fl)
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

    ---@class zen.map_edit.reader.READER
    local READER_DATA = {}
    READER_DATA.read_bytes = 0
    READER_DATA.read_bytes_segments = {}

    local math_floor = math.floor
    local pairs = pairs
    ---@param segment_start number
    ---@param segment_len number
    READER_DATA.mark_as_read = function(segment_start, segment_len)
        local segment_step = 1000

        local segment_id = math_floor(segment_start/segment_step)
        local segment_end = segment_start + segment_len

        local segment_limit = (segment_id * segment_step - 1)

        local SEGMENT = READER_DATA.read_bytes_segments[segment_id]
        if SEGMENT == nil then
            READER_DATA.read_bytes_segments[segment_id] = {[segment_start] = segment_end}
            return
        end


        local bSegmentUpdate = false
        local bNextSegmentUpdate = false
        local iNextSegmentStart, iNextSegmentEnd

        for _start, _end in pairs(SEGMENT) do
            -- Skip if segment is already read
            if segment_start >= _start and segment_start <= _end then

                -- Update _end if segment_end is greater
                if segment_end > _end then

                    if segment_end > segment_limit then
                        bNextSegmentUpdate = true
                        iNextSegmentStart = segment_limit + 1
                        iNextSegmentEnd = segment_end

                        segment_end = segment_limit
                    end

                    SEGMENT[_start] = segment_end
                    bSegmentUpdate = true
                end
            end
        end

        if !bSegmentUpdate then
            SEGMENT[segment_start] = segment_end
        end

        if bNextSegmentUpdate then
            READER_DATA.mark_as_read(iNextSegmentStart, iNextSegmentEnd)
        end
    end


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

    map_reader.ReadLMP(READER_DATA, map_path, MAP, true)

    MAP.mapFileSize = file.Size(map_path, "GAME")

    local read_bytes = 0

    for segment_id, SEGMENT in pairs(READER_DATA.read_bytes_segments) do
        for segment_start, segment_end in pairs(SEGMENT) do
            read_bytes = read_bytes + (segment_end - segment_start)
        end
    end

    MAP.read_bytes = read_bytes
    MAP.INFO = string.format("Read INFO: %s\nMap: %s\nReaded percentage: %d%% (%d Mb/%d Mb)", 
        map_name,
        map_path,
        math.floor((read_bytes / MAP.mapFileSize) * 100),
        MB(read_bytes),
        MB(MAP.mapFileSize)
    )

    for k, lmp_path in pairs(lump_files) do
        map_reader.ReadLMP(READER_DATA, lmp_path, MAP, false)
    end

    return MAP
end

---@private
---@type table<string, fun(READER_DATA:zen.map_edit.reader.READER, source:string): any>
map_reader.mt_LumpReaders = map_reader.mt_LumpReaders or {}

---@param lump_name string
---@param func fun(READER_DATA:zen.map_edit.reader.READER, source: string, fl:File): any
function map_reader.RegisterLumpRead(lump_name, func)
    map_reader.mt_LumpReaders[lump_name] = func
end

---@private
---@param READER_DATA zen.map_edit.reader.READER
---@param reader string
---@param source string
---@param fl File
---@return any
function map_reader.ReadLump(READER_DATA, reader, source, fl)

    local funcReader = map_reader.mt_LumpReaders[reader]

    if funcReader then
        return funcReader(READER_DATA, source, fl)
    else
        return "NO_READER"
    end
end

-- local HEADEERS = map_reader.CreateMapLumps()

-- print(HEADEERS.INFO)

-- PrintTable(HEADEERS)
-- PrintTable(HEADER.LUMPS["LUMP_GAME_LUMP"].data.list)

-- map_reader.ExportBSP(nil, "map_export/actual2.txt")