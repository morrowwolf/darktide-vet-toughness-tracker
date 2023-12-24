return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`toughness_tracker` encountered an error loading the Darktide Mod Framework.")

		new_mod("toughness_tracker", {
			mod_script       = "toughness_tracker/scripts/mods/toughness_tracker/toughness_tracker",
			mod_data         = "toughness_tracker/scripts/mods/toughness_tracker/toughness_tracker_data",
			mod_localization = "toughness_tracker/scripts/mods/toughness_tracker/toughness_tracker_localization",
		})
	end,
	packages = {},
}
