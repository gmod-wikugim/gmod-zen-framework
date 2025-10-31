module("zen")

if SERVER then
    resource.AddWorkshop("3273398690") -- zen framework content
end

print("Thanks for using Zen Framework! Loading...")

-- Lua include list
zen.IncludeSH(
    "zen/config.lua"
)

-- Libraries include
zen.IncludeSH({
    "zen/lib/hook.lua",
    "zen/lib/table.lua",
    "zen/lib/language.lua",
    "zen/lib/util.lua",
    "zen/lib/string.lua",
    -- "zen/lib/xml.lua",
    "zen/lib/sql.lua",
    "zen/lib/material.lua",
    "zen/lib/player_data.lua",
    "zen/lib/anim.lua",
    "zen/lib/feature.lua",
    "zen/lib/meeting.lua",
    "zen/lib/cvars.lua",
    "zen/lib/developer.lua",
})

zen.IncludeCL({
    "zen/lib/cl_input.lua",
})

zen.IncludeSV({
    "zen/lib/db/db.lua"
})

-- Network include
zen.IncludeSH({
    "zen/lib/network/sh_meta_network.lua",
    "zen/lib/network/sh_nt.lua",
    "zen/lib/network/sh_new.lua",
    "zen/lib/network/channels/sh_channel_lua.lua",
    "zen/lib/network/channels/sh_string_id.lua",
    "zen/lib/network/channels/sh_entity_vars.lua",
    "zen/lib/network/channels/sh_table_edit.lua",
    "zen/lib/network/channels/sh_shared_hooks.lua",
    "zen/lib/network/channels/sh_message.lua",
    "zen/lib/network/channels/sh_auto.lua",
    "zen/lib/network/channels/sh_util.lua",
})

zen.IncludeSV({
    "zen/lib/network/sv_nt.lua"
})

zen.IncludeCL({
    "zen/lib/network/cl_nt.lua"
})

-- Interface include
zen.IncludeCL({
    "zen/lib/interface/ui/cl_fonts.lua",
    "zen/lib/interface/ui/cl_widget.lua",
    "zen/lib/interface/ui/cl_debug.lua",
    "zen/lib/interface/ui/cl_stencil_cut.lua",
    "zen/lib/interface/ui/cl_material_cache.lua",
    "zen/lib/interface/draw/cl_draw.lua",
    "zen/lib/interface/draw/cl_draw_3d.lua",
    "zen/lib/interface/draw/cl_draw_3d2d.lua",
    "zen/lib/interface/gui/cl_gui.lua",
    "zen/lib/interface/gui/cl_skin.lua",
    "zen/lib/interface/gui/cl_params.lua",
    "zen/lib/interface/gui/cl_presets.lua",
    "zen/lib/interface/gui/cl_panels.lua",

    "zen/lib/interface/gui/skin/cl_main.lua",

    "zen/lib/interface/gui/panels/cl_zpanel_base.lua",
    "zen/lib/interface/gui/panels/cl_zdrop_select.lua",
    "zen/lib/interface/gui/panels/cl_zlabel.lua",
    "zen/lib/interface/gui/panels/cl_zbutton.lua",
    "zen/lib/interface/gui/panels/cl_button.lua",
    "zen/lib/interface/gui/panels/cl_frame.lua",
    "zen/lib/interface/gui/panels/cl_input.lua",
    "zen/lib/interface/gui/panels/cl_autosave.lua",
    "zen/lib/interface/gui/panels/cl_help.lua",
    "zen/lib/interface/gui/panels/cl_layout.lua",
    "zen/lib/interface/gui/panels/cl_html_material.lua",
    "zen/lib/interface/gui/panels/cl_html_button.lua",
    "zen/lib/interface/gui/panels/cl_spawn_icon.lua",
    "zen/lib/interface/gui/panels/cl_image.lua",
    "zen/lib/interface/gui/panels/cl_scroll_list.lua",
    "zen/lib/interface/gui/panels/cl_scroll_vbar.lua",
    "zen/lib/interface/gui/panels/cl_content.lua",
    "zen/lib/interface/gui/panels/cl_check_box.lua",
    "zen/lib/interface/gui/panels/cl_check_box_label.lua",
    "zen/lib/interface/gui/panels/cl_free.lua",
    "zen/lib/interface/gui/panels/cl_text_button.lua",
})


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

zen.IncludeSH("zen/modules/player_mode/sh_player_mode.lua")
zen.IncludeSH("zen/modules/player_mode/sh_network.lua")


zen.IncludeSH("zen/modules/zone/sh_base.lua")
zen.IncludeSH("zen/modules/zone/sh_player.lua")


zen.IncludeCL("zen/menu/permission/cl_menu.lua")

--== PLUGINS ==--

for k, v in pairs(_CFG.OfficialPlugins) do
    zen.IncludePlugin(v)
end
-- zen.IncludePlugin("fun") // To Fix