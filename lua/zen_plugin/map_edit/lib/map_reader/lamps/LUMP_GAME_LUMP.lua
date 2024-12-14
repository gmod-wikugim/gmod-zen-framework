module("zen", package.seeall)

local STATIC_PROP_ID = 1936749168

local function GAMELUMP_MAKE_CODE(a, b, c, d)
    local sum = 0
    sum = sum + bit.lshift(string.byte(a), 24)
    sum = sum + bit.lshift(string.byte(b), 16)
    sum = sum + bit.lshift(string.byte(c), 8)
    sum = sum + bit.lshift(string.byte(d), 0)

    return sum
end

local GAMELUMP_DETAIL_PROPS = GAMELUMP_MAKE_CODE('d', 'p', 'r', 'p')                // 1685090928
local GAMELUMP_DETAIL_PROP_LIGHTING = GAMELUMP_MAKE_CODE('d', 'p', 'l', 't')        // 1685089396
local GAMELUMP_STATIC_PROPS = GAMELUMP_MAKE_CODE('s', 'p', 'r', 'p')                // 1936749168
local GAMELUMP_DETAIL_PROP_LIGHTING_HDR = GAMELUMP_MAKE_CODE('d', 'p', 'l', 'h')    // 1685089384



---commentErr
---@param source string
---@param fl File
local function read_source(source, fl)

    local function readSeparate(start, len)
        assert(isnumber(start), "start not number")
        assert(isnumber(len), "len not number")

        local now_pointer = fl:Tell()

        fl:Seek(start)

        local data = fl:Read(len)

        fl:Seek(now_pointer)

        return data
    end

    ---@return string
    local function readString(bytes)
        return fl:Read(bytes)
    end

    local function readInt()
        return fl:ReadLong()
    end

    local function readShort()
        return fl:ReadShort()
    end


    local function readUShort()
        return fl:ReadUShort()
    end

    local function readVector()
        return Vector(fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat())
    end

    local function readAngle()
        return Angle(fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat())
    end

    local function readColorRGBExp32()
        return 
    end

    local function readFloat()
        return fl:ReadFloat()
    end



    local GAME_LUMP_LIST = {} -- dgamelumpheader_t
    GAME_LUMP_LIST.lumpCount = readInt()
    GAME_LUMP_LIST.list = {}


    for id = 0, GAME_LUMP_LIST.lumpCount do
        GAME_LUMP_LIST.list[id] = {}
        local LUMP = GAME_LUMP_LIST.list[id] -- dgamelump_t


        LUMP.id = readInt()
        LUMP.flags = readUShort()
        LUMP.version = readUShort()
        LUMP.fileofs = readInt()
        LUMP.filelen = readInt()

        if LUMP.fileofs and LUMP.filelen > 0 then
            local now_pointer = fl:Tell()
            fl:Seek(LUMP.fileofs)

            if LUMP.id == GAMELUMP_STATIC_PROPS then
                LUMP.worldlist = {}
                LUMP.name = "StaticPropDictLump_t"

                LUMP.dictEntries = readInt()
                LUMP.names = {}
                for k = 1, LUMP.dictEntries do
                    LUMP.names[k] = readString(128)
                end
            end

            if LUMP.id == GAMELUMP_DETAIL_PROPS then
                LUMP.name = "StaticPropLeafLump_t"
                LUMP.leafEntries = readUShort()
            end

            if LUMP.id == 83 then
                LUMP.list = {}
                LUMP.name = "StaticPropLump_t"
                local ENT = LUMP.list
                ENT.origin = readVector()
                ENT.angles = readAngle()
                ENT.PropType = readUShort()
                ENT.FirstLeaf = readUShort()
                ENT.LeafCount = readUShort()

                ENT.Solid = readString(1)

                ENT.Skin = readInt()
                ENT.FadeMinDist = readFloat()
                ENT.FadeMaxDist = readFloat()
                ENT.LightingOrigin = readVector()

                ENT.ForcedFadeScale = readFloat()

                ENT.MinDXLevel = readUShort()
                ENT.MaxDXLevel = readUShort()

                ENT.Flags = readInt()
                ENT.LightmapResX = readUShort()
                ENT.LightmapResY = readUShort()

                -- ENT.MinCPULevel = readUShort()
                -- ENT.MaxCPULevel = readUShort()
                -- ENT.MinGPULevel = readUShort()
                -- ENT.MaxGPULevel = readUShort()

                -- ENT.
            end

            fl:Seek(now_pointer)
        end
    end

    return GAME_LUMP_LIST
end


map_reader.RegisterLumpRead("LUMP_GAME_LUMP", function (source, fl)
    return read_source(source, fl)
end)