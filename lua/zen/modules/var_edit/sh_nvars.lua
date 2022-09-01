iperm.RegisterPermission("zen.variable_edit.nvars", iperm.flags.NO_TARGET, "Access to edit entity nvars!")

izen.nvars = izen.nvars or {}
zen.nvars = izen.nvars

zen.nvars.TYPE_NVARS = 1
zen.nvars.TYPE_NWVARS = 2
zen.nvars.TYPE_SETVARS = 3
zen.nvars.TYPE_FUNC = 4
zen.nvars.TYPE_VARIABLE = 5

zen.nvars.ents_base = {}
zen.nvars.ents_base["player"] = {"Health", "Armor", "MaxHealth", "MaxArmor", "Name", "Model"}