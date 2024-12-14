module("zen", package.seeall)

zen.IncludeCL("zen_plugin/map_edit/lib/cl_vector.lua")

zen.IncludeCL("zen_plugin/map_edit/lib/map_reader/cl_reader.lua")
zen.IncludeCL("zen_plugin/map_edit/lib/map_reader/cl_reader_api.lua")
zen.IncludeCL("zen_plugin/map_edit/lib/map_reader/cl_lump_list.lua")
zen.IncludeCL("zen_plugin/map_edit/lib/map_reader/lamps/LUMP_ENTITIES.lua")
zen.IncludeCL("zen_plugin/map_edit/lib/map_reader/lamps/LUMP_GAME_LUMP.lua")
zen.IncludeCL("zen_plugin/map_edit/lib/map_reader/structure/cl_bspinfo.lua")

zen.IncludeCL("zen_plugin/map_edit/lib/cl_mdl_export.lua")

zen.IncludeCL("zen_plugin/map_edit/cl_map_edit.lua")
zen.IncludeSV("zen_plugin/map_edit/sv_map_edit.lua")

zen.IncludeCL("zen_plugin/map_edit/features/pp_effects/cl_fullbright.lua")
zen.IncludeCL("zen_plugin/map_edit/features/pp_effects/cl_wireframe_entities.lua")
zen.IncludeCL("zen_plugin/map_edit/features/pp_effects/cl_wireframe_brushes.lua")

zen.IncludeCL("zen_plugin/map_edit/features/draw/cl_map_entities.lua")
zen.IncludeCL("zen_plugin/map_edit/features/draw/cl_players.lua")
-- zen.IncludeCL("zen_plugin/map_edit/modules/cl_points.lua")

-- zen.IncludeCL("zen_plugin/map_edit/modules/cl_world_click.lua")
-- zen.IncludeCL("zen_plugin/map_edit/modules/cl_origin_pos.lua")

zen.IncludeSH("zen_plugin/map_edit/modules/var_edit/sh_nvars.lua")
zen.IncludeSV("zen_plugin/map_edit/modules/var_edit/sv_nvars.lua")
zen.IncludeCL("zen_plugin/map_edit/modules/var_edit/cl_nvars.lua")
zen.IncludeCL("zen_plugin/map_edit/modules/var_edit/vgui/iproperties.lua")

zen.IncludeCL("zen_plugin/map_edit/spawnmenu/menu/menu.lua")
zen.IncludeCL("zen_plugin/map_edit/spawnmenu/menu/sheets/props.lua")
zen.IncludeCL("zen_plugin/map_edit/spawnmenu/menu/sheets/entity.lua")
-- zen.IncludeCL("zen_plugin/map_edit/spawnmenu/menu/sheets/props.lua")

zen.IncludeSV("zen_plugin/map_edit/spawnmenu/server/spawn/sv_prop.lua")
zen.IncludeSV("zen_plugin/map_edit/spawnmenu/server/spawn/sv_entity.lua")

zen.IncludeSH("zen_plugin/map_edit/tool_mode/sh_meta.lua")
zen.IncludeSH("zen_plugin/map_edit/tool_mode/sh_tool.lua")
zen.IncludeCL("zen_plugin/map_edit/tool_mode/cl_tool.lua")
zen.IncludeSV("zen_plugin/map_edit/tool_mode/sv_tool.lua")

--- SandBOX Tools
zen.IncludeSH("zen_plugin/map_edit/tool_mode/tools/sandbox/sh_sandbox.lua")
zen.IncludeSV("zen_plugin/map_edit/tool_mode/tools/sandbox/sv_sandbox.lua")

-- HAND Tool
zen.IncludeCL("zen_plugin/map_edit/tool_mode/tools/hand/cl_hand.lua")

-- DELETE Tool
zen.IncludeCL("zen_plugin/map_edit/tool_mode/tools/delete/cl_delete.lua")
zen.IncludeSV("zen_plugin/map_edit/tool_mode/tools/delete/sv_delete.lua")

-- CONVEX Tool
zen.IncludeCL("zen_plugin/map_edit/tool_mode/tools/select_convex/cl_convex.lua")
zen.IncludeSV("zen_plugin/map_edit/tool_mode/tools/select_convex/sv_convex.lua")

-- MOVE Tool
zen.IncludeCL("zen_plugin/map_edit/tool_mode/tools/move/cl_move.lua")
zen.IncludeSV("zen_plugin/map_edit/tool_mode/tools/move/sv_move.lua")

-- Physgun Tool
zen.IncludeSH("zen_plugin/map_edit/tool_mode/tools/physgun/sh_physgun.lua")
zen.IncludeCL("zen_plugin/map_edit/tool_mode/tools/physgun/cl_physgun.lua")
zen.IncludeSV("zen_plugin/map_edit/tool_mode/tools/physgun/sv_physgun.lua")

// Mods
zen.IncludeCL("zen_plugin/map_edit/mods/cl_mod_loader.lua")

zen.IncludeCL("zen_plugin/map_edit/mods/mods/cl_particle_viewer.lua")
zen.IncludeCL("zen_plugin/map_edit/mods/mods/cl_essentials.lua")
zen.IncludeCL("zen_plugin/map_edit/mods/mods/cl_view.lua")

zen.IncludeCL("zen_plugin/map_edit/vgui/spawnmenu/cl_zspawn_menu.lua")
zen.IncludeCL("zen_plugin/map_edit/vgui/spawnmenu/cl_ztree_node.lua")
zen.IncludeCL("zen_plugin/map_edit/vgui/spawnmenu/cl_ztree.lua")