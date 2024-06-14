module("zen", package.seeall)

if SERVER then
    resource.AddWorkshop("3267517036") -- zen framework content
end

-- Lua include list
zen.IncludeSH("zen/config.lua")
zen.IncludeSH("zen/lib/hook.lua")
zen.IncludeSH("zen/lib/table.lua")
zen.IncludeSH("zen/lib/util.lua")
zen.IncludeSH("zen/lib/string.lua")
-- zen.IncludeSH("zen/lib/xml.lua")
zen.IncludeSH("zen/lib/sql.lua")
zen.IncludeCL("zen/lib/cl_input.lua")
zen.IncludeCL("zen/lib/cvars.lua")
zen.IncludeCL("zen/lib/developer.lua")
zen.IncludeSH("zen/lib/material.lua")
zen.IncludeSH("zen/lib/player_data.lua")
zen.IncludeSH("zen/lib/anim.lua")

zen.IncludeSH("zen/lib/network/sh_nt.lua")
zen.IncludeSV("zen/lib/network/sv_nt.lua")
zen.IncludeCL("zen/lib/network/cl_nt.lua")

zen.IncludeSH("zen/lib/network/channels/sh_channel_lua.lua")
zen.IncludeSH("zen/lib/network/channels/sh_string_id.lua")
zen.IncludeSH("zen/lib/network/channels/sh_entity_vars.lua")
zen.IncludeSH("zen/lib/network/channels/sh_table_edit.lua")
zen.IncludeSH("zen/lib/network/channels/sh_shared_hooks.lua")
zen.IncludeSH("zen/lib/network/channels/sh_commands.lua")
zen.IncludeSH("zen/lib/network/channels/sh_message.lua")
zen.IncludeSH("zen/lib/network/channels/sh_auto.lua")

zen.IncludeCL("zen/lib/interface/ui/cl_fonts.lua")
zen.IncludeCL("zen/lib/interface/ui/cl_debug.lua")
zen.IncludeCL("zen/lib/interface/draw/cl_draw.lua")
zen.IncludeCL("zen/lib/interface/draw/cl_draw_3d.lua")
zen.IncludeCL("zen/lib/interface/draw/cl_draw_3d2d.lua")
zen.IncludeCL("zen/lib/interface/gui/cl_gui.lua")
zen.IncludeCL("zen/lib/interface/gui/cl_skin.lua")
zen.IncludeCL("zen/lib/interface/gui/cl_params.lua")
zen.IncludeCL("zen/lib/interface/gui/cl_presets.lua")
zen.IncludeCL("zen/lib/interface/gui/cl_panels.lua")

zen.IncludeCL("zen/lib/interface/gui/skin/cl_main.lua")

zen.IncludeCL("zen/lib/interface/gui/panels/cl_button.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_frame.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_input.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_autosave.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_help.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_layout.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_html_material.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_html_button.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_spawn_icon.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_image.lua")
zen.IncludeCL("zen/lib/interface/gui/panels/cl_scroll_list.lua")

zen.IncludeSH("zen/modules/save/sh_base.lua")
zen.IncludeSH("zen/modules/save/sh_player.lua")
zen.IncludeSH("zen/modules/permission/sh_permission.lua")
zen.IncludeSV("zen/modules/permission/sv_permission.lua")
zen.IncludeCL("zen/modules/permission/cl_permission.lua")

zen.IncludeSV("zen/modules/console/sv_console.lua")
zen.IncludeCL("zen/modules/console/cl_console.lua")

zen.IncludeSH("zen/modules/command/sh_command.lua")
zen.IncludeSH("zen/modules/command/sh_network.lua")
zen.IncludeSV("zen/modules/command/list/sv_perms.lua")
zen.IncludeSV("zen/modules/command/list/sv_base.lua")
zen.IncludeCL("zen/modules/command/list/cl_macros.lua")
zen.IncludeSV("zen/modules/command/list/sv_go.lua")
zen.IncludeSV("zen/modules/command/list/sv_super.lua")
zen.IncludeCL("zen/modules/command/auto_complete/player.lua")
zen.IncludeCL("zen/modules/command/auto_complete/permissions.lua")
zen.IncludeCL("zen/modules/command/auto_complete/vector.lua")
zen.IncludeCL("zen/modules/command/auto_complete/angle.lua")
zen.IncludeCL("zen/modules/command/auto_complete/boolean.lua")

zen.IncludeCL("zen/modules/hud/cl_hud.lua")

zen.IncludeCL("zen/modules/fast_command/cl_fast_command.lua")

zen.IncludeSH("zen/modules/zone/sh_base.lua")
zen.IncludeSH("zen/modules/zone/sh_player.lua")


zen.IncludeCL("zen/menu/permission/cl_menu.lua")


zen.IncludePlugins()

if file.Exists("zen_sub/browser.lua", "LUA") then
    zen.IncludeSH("zen_sub/browser.lua")
end
