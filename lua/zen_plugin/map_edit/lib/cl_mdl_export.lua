/*
    It's zen sub-subsystem for Export Models
    author: gmod-developer@srdev.pw

    Features:
    - Export all files with .mdl filename like .mdl .dx80.vtx .dx90.vtx .phy .sw.vtx .vvd and etc..
    - Export materials for the model. vmt and vtf
    - Parse all VMT for all external pathes

    Coming soon:
    - Export submodels with submaterials.

    Coming not soon:
    - Decompling model files (mdl, vvd) to smd, qc, ...
    - Decompling vtf files to .png .jpg .jpeg .tga .bmp and also .gif
*/



local PACKAGE_NAME    = "MDL Exporter"
local PACKAGE_VERSION = "1.1"


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

local function readMdl(filePath)
    local mdlTable = {}

    -- Open the MDL file
    local fl = file.Open(filePath, "rb", "GAME")
    if not fl then
        error("Could not open file: " .. filePath)
    end

    local function readBool() return tonumber(fl:Read(1)) == 1 end
    local function readInt() return fl:ReadLong() end
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


    mdlTable.id = readInt()
    mdlTable.version = readInt()
    mdlTable.checksum  = readInt()
    mdlTable.name = readString(64)

    mdlTable.dataLength = readInt()

    mdlTable.eyeposition = readVector()
    mdlTable.illumposition = readVector()
    mdlTable.hull_min = readVector()
    mdlTable.hull_max = readVector()

    mdlTable.view_bbmin = readVector()
    mdlTable.view_bbmax = readVector()

    mdlTable.flags = readInt()

    // mstudiobone_t
    mdlTable.bone_count = readInt();    // Number of data sections (of type mstudiobone_t)
    mdlTable.bone_offset = readInt();   // Offset of first data section

    // mstudiobonecontroller_t
    mdlTable.bonecontroller_count = readInt();
    mdlTable.bonecontroller_offset = readInt();

    // mstudiohitboxset_t
    mdlTable.hitbox_count = readInt();
    mdlTable.hitbox_offset = readInt();

    // mstudioanimdesc_t
    mdlTable.localanim_count = readInt();
    mdlTable.localanim_offset = readInt();

    // mstudioseqdesc_t
    mdlTable.localseq_count = readInt();
    mdlTable.localseq_offset = readInt();

    -- mdlTable.bSeqAvailable = readBool()

    mdlTable.activitylistversion = readInt(); // ??
    mdlTable.eventsindexed = readInt();       // ??

    // VMT texture filenames
    // mstudiotexture_t
    mdlTable.texture_count = readInt();
    mdlTable.texture_offset = readInt();

    // This offset points to a series of ints.
    // Each int value, in turn, is an offset relative to the start of this header/the-file,
    // At which there is a null-terminated string.
    mdlTable.texturedir_count = readInt();
    mdlTable.texturedir_offset = readInt();

    // Each skin-family assigns a texture-id to a skin location
    mdlTable.skinreference_count = readInt();
    mdlTable.skinrfamily_count = readInt();
    mdlTable.skinreference_index = readInt();

    // mstudiobodyparts_t
    mdlTable.bodypart_count = readInt();
    mdlTable.bodypart_offset = readInt();

    // Local attachment points
    // mstudioattachment_t
    mdlTable.attachment_count = readInt();
    mdlTable.attachment_offset = readInt();

    // Node values appear to be single bytes, while their names are null-terminated strings.
    mdlTable.localnode_count = readInt();
    mdlTable.localnode_index = readInt();
    mdlTable.localnode_name_index = readInt();

    // mstudioflexdesc_t
    mdlTable.flexdesc_count = readInt();
    mdlTable.flexdesc_index = readInt();

    // mstudioflexcontroller_t
    mdlTable.flexcontroller_count = readInt();
    mdlTable.flexcontroller_index = readInt();

    // mstudioflexrule_t
    mdlTable.flexrules_count = readInt();
    mdlTable.flexrules_index = readInt();

    // IK probably referse to inverse kinematics
    // mstudioikchain_t
    mdlTable.ikchain_count = readInt();
    mdlTable.ikchain_index = readInt();

    // Information about any "mouth" on the model for speech animation
    // More than one sounds pretty creepy.
    // mstudiomouth_t
    mdlTable.mouths_count = readInt();
    mdlTable.mouths_index = readInt();

    // mstudioposeparamdesc_t
    mdlTable.localposeparam_count = readInt();
    mdlTable.localposeparam_index = readInt();

    /*
     * For anyone trying to follow along, as of this writing,
     * the next "surfaceprop_index" value is at position 0x0134 (308)
     * from the start of the file.
     */

    // Surface property value (single null-terminated string)
    mdlTable.surfaceprop_index = readInt();

    // Unusual: In this one index comes first, then count.
    // Key-value data is a series of strings. If you can't find
    // what you're interested in, check the associated PHY file as well.
    mdlTable.keyvalue_index = readInt();
    mdlTable.keyvalue_count = readInt();

    // More inverse-kinematics
    // mstudioiklock_t
    mdlTable.iklock_count = readInt();
    mdlTable.iklock_index = readInt();

    mdlTable.mass = readFloat()

    mdlTable.contents = readInt();    // contents flag, as defined in bspflags.h
                            // not all content types are valid; see
                            // documentation on $contents QC command

    // Other models can be referenced for re-used sequences and animations
    // (See also: The $includemodel QC option.)
    // mstudiomodelgroup_t
    mdlTable.includemodel_count = readInt();
    mdlTable.includemodel_index = readInt();

    mdlTable.virtualModel = readInt();    // Placeholder for mutable-void*
    // Note that the SDK only compiles as 32-bit, so an int and a pointer are the same size (4 bytes)

    // mstudioanimblock_t
    mdlTable.animblocks_name_index = readInt();
    mdlTable.animblocks_count = readInt();
    mdlTable.animblocks_index = readInt();

    mdlTable.animblockModel = readInt(); // Placeholder for mutable-void*

    // Points to a series of bytes?
    mdlTable.bonetablename_index = readInt();

    mdlTable.vertex_base = readInt();    // Placeholder for void*
    mdlTable.offset_base = readInt();    // Placeholder for void*

    // Used with $constantdirectionallight from the QC
    // Model should have flag #13 set if enabled
    mdlTable.directionaldotproduct = readBool();

    mdlTable.rootLod = readBool();    // Preferred rather than clamped

    // 0 means any allowed, N means Lod 0 -> (N-1)
    mdlTable.numAllowedRootLods = readBool();

    mdlTable.unused1 = readInt(); // ??

    // mstudioflexcontrollerui_t
    mdlTable.flexcontrollerui_count = readInt();
    mdlTable.flexcontrollerui_index = readInt();

    mdlTable.vertAnimFixedPointScale = readFloat(); // ??
    mdlTable.unused2 = readInt();

    /**
     * Offset for additional header information.
     * May be zero if not present, or also 408 if it immediately
     * follows this studiohdr_t
     */
    // studiohdr2_t
    mdlTable.studiohdr2index = readInt();

    mdlTable.unused3 = readInt(); // ??


    local function DECLARE_BYTESWAP_DATADESC(func, optionalOffset)
        local currentTell = fl:Tell()

        if optionalOffset then
            fl:Seek(optionalOffset)
        end

        func()

        fl:Seek(currentTell)
    end

    if mdlTable.texture_count > 0 then
        DECLARE_BYTESWAP_DATADESC(function()
            mdlTable.textures = {}

            for i = 0, mdlTable.texture_count - 1 do
                local texture = {}

                texture.name_offset = readInt(); // Offset for null-terminated string
                texture.flags = readInt();

                -- texture.name = readStringSeparate(texture.name_offset, 64) 437700+5075

                texture.used = readInt();        // Padding?
                texture.unused = readInt();      // Padding.

                texture.material = readInt()//readString(64);        // Placeholder for IMaterial
                texture.client_material = readInt(); // Placeholder for void*

                //texture.unused2 = {}

                for k = 1 , 10 do
                    //texture.unused2[k] = readInt()//readByteAsNumber(10); // Final padding
                    readInt()
                end


                DECLARE_BYTESWAP_DATADESC(function()
                    texture.name = readAutoString():gsub("%z", "")
                end, mdlTable.texture_offset + texture.name_offset + i * 64)


                mdlTable.textures[i] = texture
            end


        end, mdlTable.texture_offset)

        if mdlTable.texturedir_count > 0 then
            mdlTable.texturesdir = {}
            DECLARE_BYTESWAP_DATADESC(function()

                for k = 1, mdlTable.texturedir_count do

                    DECLARE_BYTESWAP_DATADESC(function()
                        mdlTable.texturesdir[k] = readAutoString():gsub("\\", "/"):gsub("%z", "")
                    end, readInt())

                end

            end, mdlTable.texturedir_offset)


        end
    end


    return mdlTable
end

/*

-----------------------------------------------------
--- EXPORTER ----------------------------------------
-----------------------------------------------------

*/

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

local VMT_Export = {
    ["$basetexture"] = true,
    ["$bumpmap"] = true,
    ["$detail"] = true,
    ["$selfillum"] = true,
    ["$phongexponenttexture"] = true,
    ["$phongboost"] = true,
    ["$iris"] = true,
    ["$corneatexture"] = true,
    ["$lightwarptexture"] = true,
    ["$envmap"] = true,
    ["$ambientoccltexture"] = true,
    ["include"] = true,
    ["$selfillummask"] = true,
    ["$phongwarptexture"] = true,
    ["$envmapmask"] = true,
}


local MaterialsEXT = {
    [".vmt"] = true,
    [".png"] = true,
    [".jpg"] = true,
    [".jpeg"] = true,
    [".gif"] = true,
    [".tga"] = true,
    [".cache"] = true,
}

local ModelEXT = {
    [".mdl"] = true,
    [".dx80.vtx"] = true,
    [".dx90.vtx"] = true,
    [".phy"] = true,
    [".sw.vtx"] = true,
    [".vvd"] = true,
}

local function export_model(model)
    log(PACKAGE_NAME, ": Start exporting..")
    log("Export version: ",  PACKAGE_VERSION)
    log("Model: ",  model)

    local model_name = get_name(model)

    local bSuccess, MDL = pcall(readMdl, model)

    if !bSuccess then
        log("MDL cannot be readed!")
        return
    end

    local files_to_export = {}
    local function AddToExport(full_path)
        files_to_export[full_path] = true
    end

    local function ParseVMT_Pathes(VMT_DATA, _result)
        _result = _result or {}

        local not_supported = {}

        for k, v in pairs(VMT_DATA) do
            k = lower(k)
            if type(v) == "string" then
                if VMT_Export[k] then
                    if k == "include" then
                        ins(_result, {k, v})
                        continue
                    end

                    if (k == "envmapmask" or k == "$envmap") and v == "env_cubemap" then continue end

                    ins(_result, {k,"materials/" .. _CPaths(v) .. ".vtf"})
                else
                    --- Try find any not supports patches
                    do
                        local path = _CPaths("materials",  (v .. ".vtf"))
                        if FileExists(path) then
                            ins(not_supported, k)
                            ins(_result, {k, path})
                        end
                    end

                    do
                        local path = _CPaths(v)
                        if FileExists(path) then
                            ins(_result, {k, path})
                        end
                    end
                end
            end

            if type(v) == "table" then
                ParseVMT_Pathes(v, _result)
            end
        end

        if next(not_supported) != nil then
            log(color_warn, _C(not_supported, "/"),  " : Look like VMT param not defined, but founded!. Contact the tool developer if you have latest version!")
        end

        return _result
    end

    ---@param material_name string
    ---@param pathes string[]
    ---@return boolean bFounded, string sFoundedPath, string sFoundedEXT
    local function SearchMaterial(material_name, pathes)
        local bFounded = false
        local sFoundedPath = ""
        local sFoundedEXT = ""

        for k, possible_path in pairs(pathes) do
            local FilesFounded = {}

            if next(FilesFounded) == nil then
                for ext in pairs(MaterialsEXT) do
                    local single_path = _CPaths("materials", possible_path, lower(material_name) .. ext)
                    if FileExists( single_path ) then
                        ins(FilesFounded, single_path)

                        bFounded = true
                        sFoundedPath = single_path
                        sFoundedEXT = ext
                    end
                end
            end
        end

        return bFounded, sFoundedPath, sFoundedEXT
    end

    --- Search ext list for mdl_path
    ---@param mdl_path string
    ---@return boolean bFounded, table<string, string> tFoundedEXT, integer amount
    local function SearchModelEXT(mdl_path)
        local bFounded = false
        local tFoundedEXT = {}
        local iAmount = 0

        local mdl_name = get_name(mdl_path)
        local mdl_dir = get_dir(mdl_path)

        local SearchPath = _CPaths(mdl_dir) .. ("/" .. mdl_name .. ".*")
        local FilesFounded = FileSearch(SearchPath)

        for k, file_path in pairs(FilesFounded) do
            local ext = get_ext(file_path)

            if !lmatch(file_path, mdl_name .. "%..*") then continue end


            if ModelEXT[ext] then
                tFoundedEXT[ext] = file_path
                bFounded = true
                iAmount = iAmount + 1
            end
        end

        return bFounded, tFoundedEXT, iAmount
    end

    do -- Model extension
        local bFounded, tFoundedEXT, amount = SearchModelEXT(model)

        if bFounded then
            log("Model extension(",  amount,  "): ", color_green, _C(table.GetKeys(tFoundedEXT), " "))

            for k, v in pairs(tFoundedEXT) do
                AddToExport(v)
            end

            if !tFoundedEXT[".phy"] then
                log(color_warn, "WARN: Model don't have physics!")
            end
        else
            log("Model extension: ", color_red, "not found")
        end
    end

    local material_count = MDL.texture_count
    local material_patches_count = MDL.texturedir_count

    log("Material pathes count: ", material_patches_count)

    if MDL.texturedir_count > 0 then
        if MDL.texturesdir then
            for k, v in pairs(MDL.texturesdir) do
                log("- ", v)
            end
        end
    end


    log("Material amount: ", material_count)

    local not_exported_materials = {}

    if material_count > 0 then
        log("Searching materials:")
        for k, v in pairs(MDL.textures) do
            local bFounded, sFoundedPath, sFoundedEXT, amount = SearchMaterial(v.name, MDL.texturesdir)

            if bFounded then
                log("- ", v.name, ": ", color_green, sFoundedPath)
                AddToExport(sFoundedPath)
            else
                log("- ", v.name, ": ", color_red, " Not founded!")
                ins(not_exported_materials, v.name)
            end


            if sFoundedEXT == ".vmt" then
                local VMT_Dirt = FileRead(sFoundedPath)

                if !VMT_Dirt or #VMT_Dirt <= 0 then
                    log(color_red, "VMT founded, but cannot be readed")
                else
                    local VMT_DATA = util.KeyValuesToTable(VMT_Dirt)
                    if !VMT_DATA or next(VMT_DATA) == nil then
                        log(color_red, "VMT founded and readed, but it looks like corruped")
                    else
                        local VMT_Patches = ParseVMT_Pathes(VMT_DATA)
                        if next(VMT_Patches) == nil then
                            log(color_red, "VMT parsed, but not any path didn't founded!")
                        else
                            for _, v in pairs(VMT_Patches) do
                                local name = v[1]
                                local path = v[2]
                                if FileExists(path) then
                                    log(" - ", name, ": ", color_green, path)
                                    AddToExport(path)
                                else
                                    log("  - ", name, ": ", color_red, "Not founded: ", path)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for file_path, v in pairs(files_to_export) do
        local data = FileRead(file_path)
        if !data then
            log(color_red, file_path, ": Cannot be readed..")
            continue
        end

        local file_name = string.GetFileFromFilename(file_path)
        local SECOND_PATH = _CPaths("export_model/", model_name, "", file_path)
        FileWrite(SECOND_PATH, data, true)
    end

    -- Write MODEL_INFO with model path and information
    do
        local readme_path = _CPaths("export_model/", model_name, "MODEL_INFO.txt")
        local readme_data = _C{
            PACKAGE_NAME, " v", PACKAGE_VERSION, "\n",
            "Model: ", model, "\n",
            "Exported at: ", os.date("%Y-%b-%d %H:%M:%S"), "\n",
            "\n",
            "Exported files:\n",
        }

        for file_path, v in pairs(files_to_export) do
            readme_data = readme_data .. ("- " .. file_path .. "\n")
        end

        -- Add not exported materials
        if next(not_exported_materials) != nil then
            readme_data = readme_data .. "\nNot exported materials:\n"
            for k, v in pairs(not_exported_materials) do
                readme_data = readme_data .. ("- " .. v .. "\n")
            end
        end

        FileWrite(readme_path, readme_data, true)
    end

    -- Echo result path
    local finish_path = "garrysmod/data/export_model/" .. model_name
    log("Result path: <GMOD_PATH>", finish_path, " (Saved in Clipboard)")
    SetClipboardText(finish_path)

    /*
    if CLIENT_DLL then
        util.PrecacheModel(model)
    end


    local model_name = string.StripExtension(string.GetFileFromFilename(model))
    local model_path = string.GetPathFromFilename(model)

    local VMT_Founded = {}


    local data_to_export = {}

    local AutoExportPath



    local function DataToExport(new_file_path, data)
        table.insert(files_to_export, {
            new_file_path = new_file_path,
            data = data,
        })
    end


    local function ResolveVMT(vmtPath)
        if VMT_Founded[vmtPath] then return end

        VMT_Founded[vmtPath] = true

        local VMT_DATA = file.Read(vmtPath, "GAME")


        local VMT = util.KeyValuesToTable(VMT_DATA)

        if !VMT then
            log(vmtPath .. ": Failed to parse VMT")
            return
        end

        local function Check(someVMT)
            for k, v in pairs(someVMT) do
                if type(v) == "string" and VMT_Export[k] then
                    local FullPath = "materials/" .. v
                    -- log("Add:", FullPath)
                    local bFounded = AutoExportPath(FullPath)
                    if (bFounded == false) then
                        log(FullPath, ": Do not exits, please be careful!")
                    end
                end

                if type(v) == "table" then
                    Check(v)
                end
            end
        end

        Check(VMT)
    end

    ---@param ItemName string Should be name without paint and path
    ---@param Dir string Should be global path without
    local function ExportPath(ItemName, Dir)
        if ItemName[#ItemName] == "/" then
            ItemName = ItemName:sub(1, #ItemName - 1)
        end

        if Dir[#Dir] != "/" then
            Dir = Dir .. "/"
        end

        -- log(Dir, " | ", ItemName, " --> ", Dir .. lower(ItemName))

        local search_path  = Dir .. lower(ItemName) .. ".*"
        local files = file.Find(search_path, "GAME")

        // models/player/hazmat/hazmat.mdl
        -- log(search_path)

        -- PrintTable(files)

        local iFoundCount = 0

        if files then
            for _, fl_name in pairs(files) do
                local ItemFullPath = Dir .. fl_name

                if ItemFullPath:match(Dir .. ItemName .. "%..*") or lower(ItemFullPath):match(lower(Dir .. ItemName) .. "%..*") then
                    iFoundCount = iFoundCount + 1
                    local EXT = fl_name:match("%..*")
                    local RealFileName = ItemName .. EXT

                    if EXT == ".vmt" then
                        ResolveVMT(ItemFullPath)
                    end

                    AddToExport(ItemFullPath, RealFileName)
                else
                    log(ItemFullPath .. ": Skipped")
                end
            end
        end

        -- log("Founded:", iFoundCount)

        return iFoundCount > 0
    end

    function AutoExportPath(FullPathWithFileName)
        local Name = string.StripExtension(string.GetFileFromFilename(FullPathWithFileName))
        local Dir = string.GetPathFromFilename(FullPathWithFileName)

        -- log(Dir, " | " , Name)

        return ExportPath(Name, Dir)
    end

    // Main Model
    local bFounded = AutoExportPath(model)
    if (bFounded == false) then
        AutoExportPath("models/" .. lower(MDL.name))
    end

    // Textures
    do
        local texture_list = {}

        for _, v in pairs(MDL.textures) do
            table.insert(texture_list, v.name)
        end

        local textures_pathes = MDL.texturesdir

        if MDL.texture_count > 0 and next(textures_pathes) == nil then
            error("Texture cannot be founded. Model is broken!")
        end

        local possible_texture_patches = {}
        for _, texture_dir in pairs(textures_pathes) do
            for _, texture_name in pairs(texture_list) do
                local TextureDir = "materials/" .. texture_dir .. texture_name
                AutoExportPath(TextureDir)
            end
        end
    end

    // TODO: Submodels and submodel materials reader!

    */


    /*
        ---------------------------------
        ----------- SAVING --------------
        ---------------------------------
    */

    /*

    local save_path = "export_model/" .. model_name

    if ( !file.IsDir(save_path, "DATA") ) then
        file.CreateDir(save_path)
    end

    local tRename = {}

    for k, v in pairs(files_to_export) do
        local FullPath = v.full_path

        local LocalPath = v.new_file_path
        local FullNewPath = save_path .. "/" .. LocalPath

        if lower(FullNewPath) != FullNewPath then
            local current = string.GetFileFromFilename(lower(FullNewPath))
            local shouldBE = string.GetFileFromFilename(FullNewPath)
            tRename[current] = shouldBE
        end

        if !file.Exists(FullPath, "GAME") then
            log(FullPath .. ": Not founded")
            continue
        end

        local data = file.Read(FullPath, "GAME")

        if data == "" or data == nil then
            log(FullPath .. ": Can't be readed")
            continue
        end

        local bResult = FileWrite(FullNewPath, data)
        if (bResult == true) then
            -- local RelativePath = string.GetPathFromFilename(FullPath)
            FileWrite(save_path .. "/addon/" ..  FullPath, data, true)
        end
    end


    if next(tRename) != nil then
        local windowsCMD = {}
        local linuxSH = {}

        local windows_name = "=== export auto-fix ===.cmd"
        local linux_name = "=== export auto-fix ===.sh"

        local windows_name_dat = "=== export auto-fix ===.cmd.dat"
        local linux_name_dat = "=== export auto-fix ===.sh.dat"

        for current, shouldBE in pairs(tRename) do
            ins(windowsCMD, _C{'move "', current, '" "', shouldBE, '";'})
            ins(linuxSH, _C{'mv "', current, '" "', shouldBE, '";'})
        end

        ins(windowsCMD, _C{'del /Q /F "', windows_name, '";'})
        ins(windowsCMD, _C{'del /Q /F "', windows_name_dat, '";'})
        ins(windowsCMD, _C{'del /Q /F "', linux_name, '";'})
        ins(windowsCMD, _C{'del /Q /F "', linux_name_dat, '";'})
        ins(linuxSH, _C{'rm -f "', windows_name, '";'})
        ins(linuxSH, _C{'rm -f "', windows_name_dat, '";'})
        ins(linuxSH, _C{'rm -f "', linux_name, '";'})
        ins(linuxSH, _C{'rm -f "', linux_name_dat, '";'})


        file.Write(save_path .. "/" .. windows_name_dat, _C(windowsCMD, "\n"))
        file.Write(save_path .. "/" .. linux_name_dat, _C(linuxSH, "\n"))
    end
    */

    /*
    for k, v in pairs(data_to_export) do
        local LocalPath = v.new_file_path
        local FullNewPath = save_path .. "/" .. LocalPath

        FileWrite(FullNewPath)
    end


    local finish_path = "garrysmod/data/" .. save_path

    log("Result path: <GMOD_PATH>", save_path, " (Saved in Clipboard)")
    SetClipboardText(finish_path)
    */
end

concommand.Add("export_model", function(ply, cmd, args)
    local model = args[1]

    if !model or model == "" then
        log("Usage: export_model <model_path>")
        return
    end

    export_model(model)
end, nil, "Export model by path. Usage: export_model <model_path>")

-- Concommand to export my LocalPlayer() model
concommand.Add("export_mymodel", function(ply, cmd, args)
    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end

    local model = ply:GetModel()

    export_model(model)
end, nil, "Export your player model")

-- Concommand to export this entity model
concommand.Add("export_thismodel", function(ply, cmd, args)
    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end

    local tr = ply:GetEyeTrace()
    if !tr then return end
    if !IsValid(tr.Entity) then
        log("You don't looking at entity!")
        return
    end

    local model = tr.Entity:GetModel()
    if !model or model == "" then
        log("Entity don't have model!")
        return
    end

    export_model(model)
end, nil, "Export entity model which you looking at")


return {
    PACKAGE_NAME = PACKAGE_NAME,
    PACKAGE_VERSION = PACKAGE_NAME,
    ReadMDL = readMdl,
    ExportModel = export_model,
}