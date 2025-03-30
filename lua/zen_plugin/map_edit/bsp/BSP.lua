module("zen")

---@class zen.bsp
bsp = _GET("bsp")

local META_FILE = FindMetaTable("File") --[[@class File]]

bsp.LUMP_TYPES = {
    LUMP_UNKNOWN = -1,
    -- v21
    LUMP_PROPCOLLISION = { id = 22, version = 21 },
    LUMP_PROPHULLS = { id = 23, version = 21 },
    LUMP_PROPHULLVERTS = { id = 24, version = 21 },
    LUMP_PROPTRIS = { id = 25, version = 21 },
    LUMP_PROP_BLOB = { id = 49, version = 21 },
    LUMP_PHYSLEVEL = { id = 62, version = 21 },
    LUMP_DISP_MULTIBLEND = { id = 63, version = 21 },
    -- v20
    LUMP_FACEIDS = { id = 11, version = 20 },
    LUMP_UNUSED0 = { id = 22, version = 20 },
    LUMP_UNUSED1 = { id = 23, version = 20 },
    LUMP_UNUSED2 = { id = 24, version = 20 },
    LUMP_UNUSED3 = { id = 25, version = 20 },
    LUMP_PHYSDISP = { id = 28, version = 20 },
    LUMP_WATEROVERLAYS = { id = 50, version = 20 },
    LUMP_LEAF_AMBIENT_INDEX_HDR = { id = 51, version = 20 },
    LUMP_LEAF_AMBIENT_INDEX = { id = 52, version = 20 },
    LUMP_LIGHTING_HDR = { id = 53, version = 20 },
    LUMP_WORLDLIGHTS_HDR = { id = 54, version = 20 },
    LUMP_LEAF_AMBIENT_LIGHTING_HDR = { id = 55, version = 20 },
    LUMP_LEAF_AMBIENT_LIGHTING = { id = 56, version = 20 },
    LUMP_XZIPPAKFILE = { id = 57, version = 20 },
    LUMP_FACES_HDR = { id = 58, version = 20 },
    LUMP_MAP_FLAGS = { id = 59, version = 20 },
    LUMP_OVERLAY_FADES = { id = 60, version = 20 },
    LUMP_OVERLAY_SYSTEM_LEVELS = { id = 61, version = 20 },
    -- v19 and previous
    LUMP_ENTITIES = 0,
    LUMP_PLANES = 1,
    LUMP_TEXDATA = 2,
    LUMP_VERTEXES = 3,
    LUMP_VISIBILITY = 4,
    LUMP_NODES = 5,
    LUMP_TEXINFO = 6,
    LUMP_FACES = 7,
    LUMP_LIGHTING = 8,
    LUMP_OCCLUSION = 9,
    LUMP_LEAFS = 10,
    LUMP_UNDEFINED = 11,
    LUMP_EDGES = 12,
    LUMP_SURFEDGES = 13,
    LUMP_MODELS = 14,
    LUMP_WORLDLIGHTS = 15,
    LUMP_LEAFFACES = 16,
    LUMP_LEAFBRUSHES = 17,
    LUMP_BRUSHES = 18,
    LUMP_BRUSHSIDES = 19,
    LUMP_AREAS = 20,
    LUMP_AREAPORTALS = 21,
    LUMP_PORTALS = 22,
    LUMP_CLUSTERS = 23,
    LUMP_PORTALVERTS = 24,
    LUMP_CLUSTERPORTALS = 25,
    LUMP_DISPINFO = 26,
    LUMP_ORIGINALFACES = 27,
    LUMP_UNUSED = 28,
    LUMP_PHYSCOLLIDE = 29,
    LUMP_VERTNORMALS = 30,
    LUMP_VERTNORMALINDICES = 31,
    LUMP_DISP_LIGHTMAP_ALPHAS = 32,
    LUMP_DISP_VERTS = 33,
    LUMP_DISP_LIGHTMAP_SAMPLE_POSITIONS = 34,
    LUMP_GAME_LUMP = 35,
    LUMP_LEAFWATERDATA = 36,
    LUMP_PRIMITIVES = 37,
    LUMP_PRIMVERTS = 38,
    LUMP_PRIMINDICES = 39,
    LUMP_PAKFILE = 40,
    LUMP_CLIPPORTALVERTS = 41,
    LUMP_CUBEMAPS = 42,
    LUMP_TEXDATA_STRING_DATA = 43,
    LUMP_TEXDATA_STRING_TABLE = 44,
    LUMP_OVERLAYS = 45,
    LUMP_LEAFMINDISTTOWATER = 46,
    LUMP_FACE_MACRO_TEXTURE_INFO = 47,
    LUMP_DISP_TRIS = 48,
    LUMP_PHYSCOLLIDESURFACE = 49
}


bsp.HEADER_LUMPS = 64
bsp.HEADER_LUMPS_TF = 128
bsp.HEADER_SIZE = 1036
bsp.MAX_LUMPFILES = 128

local Read = META_FILE.Read
local ReadByte = META_FILE.ReadByte
local ReadDouble = META_FILE.ReadDouble
local ReadFloat = META_FILE.ReadFloat
local ReadLine = META_FILE.ReadLine
local ReadLong = META_FILE.ReadLong
local ReadShort = META_FILE.ReadShort
local ReadUInt64 = META_FILE.ReadUInt64
local ReadULong = META_FILE.ReadULong
local ReadUShort = META_FILE.ReadUShort

--- Return Lamp data from BSP lumps
---@param BSP zen.bsp.BSP
---@param lump_type string
---@return zen.bsp.Lump?
function bsp.GetLumpData(BSP, lump_type)
    local lump = bsp.LUMP_TYPES[lump_type]
    if not lump then
        error("Lump type " .. tostring(lump_type) .. " not found")
    end

    local lump_id = type(lump) == "table" and lump.id or lump
    ---@cast lump_id integer

    return BSP.lumps[lump_id]
end

--- Read data from a lump
---@param BSP zen.bsp.BSP
---@param Lump zen.bsp.Lump
function bsp.ReadLumpData(BSP, Lump)
    local LumpFunc = bsp.mtLump_Readers[Lump.fourCC]
    if not LumpFunc then
        error("Lump read function for " .. tostring(Lump.fourCC) .. " not found")
    end

    assert(type(LumpFunc) == "function", "Lump read function for " .. tostring(Lump.fourCC) .. " is not a function")

    local BB = bsp.CreateBuffer(BSP.file_path, Lump.ofs)

    local suc, data = xpcall(LumpFunc, ErrorNoHaltWithStack, BSP, BB, Lump)
    BB.close()

    if not suc then
        error("Error reading lump " .. tostring(Lump.fourCC) .. ": " .. tostring(data))
    end

    return data
end

bsp.mtLump_Readers = bsp.mtLump_Readers or {}

---@param lump_type string
---@param func fun(BSP: zen.bsp.BSP, BB: zen.bsp.Buffer, Lump: zen.bsp.Lump)
function bsp.RegisterLumpReadFunction(lump_type, func)
    bsp.mtLump_Readers[lump_type] = func
end

---@param file_path string
---@param Offset number?
---@param fileMode string?
---@param PATH string?
---@return zen.bsp.Buffer
function bsp.CreateBuffer(file_path, Offset, fileMode, PATH)
    fileMode = fileMode or "rb"
    PATH = PATH or "GAME"

    local File = file.Open(file_path, fileMode, PATH)
    if not File then error("File not found: " .. tostring(file_path)) end
    ---@cast File File

    ---@class zen.bsp.Buffer
    local BB = {}

    ---@return number
    function BB.limit() return File:Size() end

    ---@param add number
    function BB.seekCurrent(add) return File:Seek(File:Tell() + add) end

    // Read functions

    ---@param length number
    ---@return string
    function BB.get(length) return File:Read() end

    -- Get one byte
    ---@return boolean
    function BB.getBool() return File:ReadBool() end

    -- Get 1 byte (8 bits)
    ---@return number
    function BB.getByte() return File:ReadByte() end

    -- Get 8 bytes (64 bits)
    ---@return number
    function BB.getDouble() return File:ReadDouble() end

    -- Get 4 bytes (32 bits)
    ---@return number
    function BB.getFloat() return File:ReadFloat() end

    ---@return string
    function BB.getLine() return File:ReadLine() end

    -- Get 4 bytes (32 bits)
    ---@return number
    function BB.getLong() return File:ReadLong() end
    BB.getInt = BB.getLong

    -- Get 2 bytes (16 bits)
    ---@return number
    function BB.getShort() return File:ReadShort() end

    -- Get 8 bytes (64 bits)
    ---@return string
    function BB.getUInt64() return File:ReadUInt64() end

    -- Get 4 bytes (32 bits)
    ---@return number
    function BB.getULong() return File:ReadULong() end

    -- Get 2 bytes (16 bits)
    ---@return number
    function BB.getUShort() return File:ReadUShort() end

    -- Read with offset and len
    ---@param offset number
    ---@param len number
    ---@return string
    function BB.readSeparate(offset, len)
        local oldPos = File:Tell()
        File:Seek(offset)
        local data = File:Read(len)
        File:Seek(oldPos)
        return data
    end



    // Write functions

    ---@param data string
    function BB.write(data) return File:Write(data) end

    ---@param data boolean
    function BB.writeBool(data) return File:WriteBool(data) end

    ---@param data number
    function BB.writeByte(data) return File:WriteByte(data) end

    ---@param data number
    function BB.writeDouble(data) return File:WriteDouble(data) end

    ---@param data number
    function BB.writeFloat(data) return File:WriteFloat(data) end

    ---@param data number
    function BB.writeLong(data) return File:WriteLong(data) end
    BB.writeInt = BB.writeLong

    ---@param data number
    function BB.writeShort(data) return File:WriteShort(data) end

    ---@param data string
    function BB.writeUInt64(data) return File:WriteUInt64(data) end

    ---@param data number
    function BB.writeULong(data) return File:WriteULong(data) end

    ---@param data number
    function BB.writeUShort(data) return File:WriteUShort(data) end

    -- Write with offset and len
    ---@param offset number
    ---@param data string
    function BB.writeSeparate(offset, data)
        local oldPos = File:Tell()
        File:Seek(offset)
        File:Write(data)
        File:Seek(oldPos)
    end

    function BB.close() File:Close() end


    if Offset then
        File:Seek(Offset)
    end


    return BB
end


--- Read all lumps from the BSP file
---@param BSP zen.bsp.BSP
---@param BB zen.bsp.Buffer
function bsp.loadLumps(BSP, BB)

    ---@type integer
    local numLumps

    for k = 0, bsp.MAX_LUMPFILES, 1 do
        BSP.lumps[k] = {}

        ---@class zen.bsp.Lump
        local Lump = BSP.lumps[k]
        Lump.ofs = BB.getInt()
        Lump.len = BB.getInt()
        Lump.vers = BB.getInt()
        Lump.fourCC = BB.getInt()


        -- Fix invalid offsets
        if Lump.ofs > BB.limit() then
            local ofsOld = Lump.ofs
            Lump.ofs = BB.limit()
            Lump.len = 0
            print(string.format("Invalid lump offset %d in %s, assuming %d", ofsOld, bsp.LUMP_HEADERS[k] or "UNKNOWN", Lump.ofs))
        elseif Lump.ofs < 0 then
            local ofsOld = Lump.ofs
            Lump.ofs = 0
            Lump.len = 0
            print(string.format("Negative lump offset %d in %s, assuming %d", ofsOld, bsp.LUMP_HEADERS[k] or "UNKNOWN", Lump.ofs))
        end

        -- Fix invalid lengths
        if Lump.ofs + Lump.len > BB.limit() then
            local lenOld = Lump.len
            Lump.len = BB.limit() - Lump.ofs
            print(string.format("Invalid lump length %d in %s, assuming %d", lenOld, bsp.LUMP_HEADERS[k] or "UNKNOWN", Lump.len))
        elseif Lump.len < 0 then
            local lenOld = Lump.len
            Lump.len = 0
            print(string.format("Negative lump length %d in %s, assuming %d", lenOld, bsp.LUMP_HEADERS[k] or "UNKNOWN", Lump.len))
        end

        Lump.buffer = BB.readSeparate(Lump.ofs, Lump.len)

    end
end

-- Read game lumps
---@param BSP zen.bsp.BSP
function bsp.loadGameLumps(BSP)

    ---@class zen.bsp.Lump.LUMP_GAME_LUMP: zen.bsp.Lump
    local Lump = bsp.GetLumpData(BSP, "LUMP_GAME_LUMP")
    assert(Lump != nil, "LUMP_GAME_LUMP not found")

    local inBB = bsp.CreateBuffer(BSP.file_path, Lump.ofs)


    Lump.glumps = inBB.getInt()

    Lump.gLumps = {}
    for i = 0, Lump.glumps, 1 do
        Lump.gLumps[i] = {}

        ---@class zen.bsp.Lump.LUMP_GAME_LUMP.gLumps
        local gLump = Lump.gLumps[i]

        gLump.fourCC = inBB.getInt()
        gLump.flags = inBB.getUShort()
        gLump.vers = inBB.getUShort()

        gLump.ofs = inBB.getInt()
        gLump.len = inBB.getInt()

        if gLump.flags == 1 then
            inBB.seekCurrent(8)
            gLump.nextOfs = inBB.getInt()
            if gLump.nextOfs == 0 then
                gLump.nextOfs = Lump.ofs + Lump.len
            end
            gLump.len = gLump.nextOfs - gLump.ofs
        end

        if gLump.ofs - Lump.ofs > 0 then
            gLump.ofs = gLump.ofs - Lump.ofs
        end

        -- Fix invalid offsets
        if gLump.ofs > Lump.len then
            local ofsOld = gLump.ofs
            gLump.ofs = Lump.len
            gLump.len = 0
            print(string.format("Invalid game lump offset %d in %s, assuming %d", ofsOld, gLump.fourCC, gLump.ofs))
        elseif gLump.ofs < 0 then
            local ofsOld = gLump.ofs
            gLump.ofs = 0
            gLump.len = 0
            print(string.format("Negative game lump offset %d in %s, assuming %d", ofsOld, gLump.fourCC, gLump.ofs))
        end

    end

end



-- Decompile BSP file
-- Sources: https://github.com/ata4/bspsrc
---@param file_path string
function bsp.ReadBSP(file_path)
    local BB = bsp.CreateBuffer(file_path)

    ---@class zen.bsp.BSP
    local BSP = {}
    BSP.ident = BB.getInt()
    if BSP.ident == 0x504B0304 or BSP.ident == 0x504B0506 or BSP.ident == 0x504B0708 then
        error("File is a zip archive. Make sure to first extract any BSP file it might contain and then select these for decompilation.")
    end

    BSP.file_path = file_path
    BSP.lumps = {}
    BSP.version = BB.getInt()

    bsp.loadLumps(BSP, BB)
    bsp.loadGameLumps(BSP)

    BSP.mapRev = BB.getInt()

    BB.close()

    return BSP
end

-- Write BSP file
---@param BSP zen.bsp.BSP
---@param file_path string
function bsp.WriteBSP(BSP, file_path)
    local BB = bsp.CreateBuffer(file_path, nil, "wb", "DATA")

    BB.writeInt(BSP.ident)
    BB.writeInt(BSP.version)
    for k = 0, bsp.MAX_LUMPFILES, 1 do
        local Lump = BSP.lumps[k]
        if not Lump then
            error("Lump " .. tostring(k) .. " not found")
        end

        BB.writeInt(Lump.ofs)
        BB.writeInt(Lump.len)
        BB.writeInt(Lump.vers)
        BB.writeInt(Lump.fourCC)

        if Lump.len == 0 then continue end

        if type(Lump.buffer) == "string" then
            BB.writeSeparate(Lump.ofs, Lump.buffer)
        end
    end

    BB.close()
end


---@param map string?
function bsp.ReExportMap(map)
    map = map or game.GetMap()

    local File = file.Open("maps/" .. map .. ".bsp", "rb", "GAME")
    if not File then
        error("File not found: " .. map)
    end

    file.CreateDir("maps")
    local FileOut = file.Open("maps/" .. map .. ".bsp.dat", "wb", "DATA")
    if not FileOut then
        error("File not found: " .. map)
    end

    local FileData = File:Read(File:Size())
    FileOut:Write(FileData)
    FileOut:Close()
    File:Close()

    print("Exported map: " .. map)
end

if SERVER then
    concommand.Add("zen_bsp_save_sv", function(ply, cmd, args)
        if IsValid(ply) and !ply:IsSuperAdmin() then return end

        local map = args[1] or game.GetMap()
        bsp.ReExportMap(map)
    end)
elseif CLIENT_DLL then
    concommand.Add("zen_bsp_save_cl", function(ply, cmd, args)
        local map = args[1] or game.GetMap()
        bsp.ReExportMap(map)
    end)
end

