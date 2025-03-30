module("zen")

local File
local ReadedBytes = 0

---@type table<string, table<number, table<string, string>>>
local mt_Structures = {}

---@param name string
---@param tbl table<number, table<string, string>>
function RegisterStructure(name, tbl)
    mt_Structures[name] = tbl
end

-------------

---@type table<string, fun(self:table, type_name:string, index_name:string)>
local mt_Readers = {}

---@param type_name string
---@param func fun(self:table, type_name:string, index_name:string)
local function addReader(type_name, func)

    mt_Readers[type_name] = func
end


-------------

---@type table<string, fun(self:table, type_name:string, count:number, index_name:string)>
local mt_ReadersArray = {}


---@param type_name string
---@param func fun(self:table, type_name:string, count:number, index_name:string)
local function addReaderArray(type_name, func)

    mt_ReadersArray[type_name] = func
end

-------------

addReader("int", function (self, type_name, index_name)
    self[index_name] = File:ReadLong()
    ReadedBytes = ReadedBytes + 32
end)

addReader("ushort", function (self, type_name, index_name)
    self[index_name] = File:ReadUShort()
    ReadedBytes = ReadedBytes + 16
end)

addReader("float", function (self, type_name, index_name)
    self[index_name] = File:ReadFloat()
    ReadedBytes = ReadedBytes + 32
end)

addReader("boolean", function (self, type_name, index_name)
    self[index_name] = File:ReadBool()
    ReadedBytes = ReadedBytes + 8
end)


addReader("vector", function (self, type_name, index_name)
    self[index_name] = Vector(
        File:ReadFloat(),
        File:ReadFloat(),
        File:ReadFloat()
    )
    ReadedBytes = ReadedBytes + 32 * 3
end)

addReader("angle", function (self, type_name, index_name)
    self[index_name] = Angle(
        File:ReadFloat(),
        File:ReadFloat(),
        File:ReadFloat()
    )
    ReadedBytes = ReadedBytes + 32 * 3
end)

-------------


addReader("fl_data", function (self, type_name, index_name)
    assert(self.fileofs, "no self.fileofs exists for ".. index_name)
    assert(self.filelen, "no self.filelen exists for ".. index_name)


    if self.fileofs and self.filelen then
        local now_pointer = File:Tell()
        File:Seek(self.fileofs)
        self[index_name] = File:Read(self.filelen)
        ReadedBytes = ReadedBytes + self.filelen

        File:Seek(now_pointer)
    end
end)


local string_gmatch = string.gmatch
addReader("hammer_string_table", function (self, type_name, index_name)
    if self.raw then
        self[index_name] = {}
        local new_table = self[index_name]

        for key, value in string_gmatch(self.raw, '"([^"]+)" "([^"]+)"') do
            rawset(new_table, key, value)
        end
    end
end)

addReader("hammer_keyvaluestable", function (self, type_name, index_name)
    self[index_name] = util.HammerKeyValuesTableToTable(self.raw)
end)


-------------

addReaderArray("char", function (self, type_name, count, index_name)
    self[index_name] = File:Read(count)
    ReadedBytes = ReadedBytes + count
end)


-------------


RegisterStructure("bspinfo", {
    {"int", "iden"},
    {"int", "version"},
    {"*bspinfo_lamps[64]", "lamps", arrayKeyCalc = function(self, id) return LUMP_HEADERS[id] end},
    {"int", "mapRevision"}
})


RegisterStructure("bspinfo_lamps", {
    {"int", "fileofs"},
    {"int", "filelen"},
    {"int", "version"},
    {"char[4]", "fourCC"},
    {"fl_data", "raw"}
})

RegisterStructure("bspinfo_lamp.LUMP_ENTITIES", {
    {"hammer_keyvaluestable", "items"},
})




-------------

local function getReader(type_name)
    local funcReader = mt_Readers[type_name]
    if funcReader then return funcReader, false end

    local type_name_word, bytes = type_name:match("([%w_]+)%[(%d+)%]")
    bytes = tonumber(bytes)
    if type_name_word and bytes then
        local funcReader = mt_ReadersArray[type_name_word]
        if funcReader then
            return funcReader, true, bytes
        end
    end

    error("reader is unavaliable: " .. tostring(type_name))
end


---@param self table
---@param structure_name string
---@param level? number
local function ReadStructure(self, structure_name, level)
    level = level or 0
    assert(isstring(structure_name), "structure_name must be string")

    local STRUCTURE = mt_Structures[structure_name]
    assert(istable(STRUCTURE), "structure '" .. structure_name .. "' not exists!")

    print(string.rep("\t|", level), structure_name, ":")

    level = level + 1

    for id, v in ipairs(STRUCTURE) do
        local type_name, index_name = v[1], v[2]

        print(string.rep("\t|", level), ">", type_name, " / ", index_name)

        if type_name[1] == "*" then
            local clear_type_name = type_name:sub(2, #type_name)

            local only_type_word, size = clear_type_name:match("([%w_]+)%[(%d+)%]")
            size = tonumber(size)

            local arrayKeyCalc = v.arrayKeyCalc

            if only_type_word then
                assert(size, "size not avaliable for: " .. type_name)

                self[index_name] = {}
                for k = 1, size do
                    k = arrayKeyCalc and arrayKeyCalc(self, k) or k
                    self[index_name][k] = {}
                    ReadStructure(self[index_name][k], only_type_word, level + 1)
                end
            else
                self[index_name] = {}
                ReadStructure(self[index_name], type_name, level+1)
            end


            continue
        end

        local funcReader, bArray, count = getReader(type_name)
        if bArray then
            funcReader(self, type_name, count, index_name)
        else
            funcReader(self, type_name, index_name)
        end


    end

    -- print("ReadStructure")
end

local function addColor(value)
    local type_value = type(value)

    if type_value == "string" then
        return Color(255, 255, 0), value
    end

    if type_value == "number" then
        return Color(0, 255, 0), value
    end

    return value
end

local function printT(tbl, level)
    level = level or 0

    for k, v in pairs(tbl) do
        if istable(v) then
            print(string.rep("\t|", level), addColor(k))
            printT(v, level + 1)
        else
            if type(v) == "string" then
                local v_text = tostring(v)
                print(string.rep("\t|", level), tostring(k), " = ", addColor(v_text:sub(1, 50)))
            else
                print(string.rep("\t|", level), tostring(k), " = ", addColor(v))
            end
        end

    end

end

local function StartRead(map_name, SOURCE)
    map_name = map_name or game.GetMap()

    assert(isstring(map_name), "map_name must be a string")
    local map_path = "maps/" .. map_name .. ".bsp"

    assert(file.Exists(map_path, "GAME"), "Map file not found: " .. map_path)

    File = file.Open(map_path, "rb", "GAME")
    ReadedBytes = 0
    assert(File, "file not opened")

    local BSP = {}

    ReadStructure(BSP, "bspinfo")

    ReadStructure(BSP.lamps.LUMP_ENTITIES, "bspinfo_lamp.LUMP_ENTITIES")



    printT(BSP)


    local size = File:Size()
    local percentage = math.Round( (100 - (size - ReadedBytes) / size * 100), 5 )
    print("Readed: ", ReadedBytes , "/" , size, " (", percentage, "%)")

    File:Close()



    return BSP
end

-- StartRead()

