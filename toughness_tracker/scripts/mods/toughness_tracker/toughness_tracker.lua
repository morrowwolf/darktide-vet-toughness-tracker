local mod = get_mod("toughness_tracker")

mod.melee_attack_types ={
"melee",
"push",
}
mod.melee_damage_profiles ={
}
mod.melee_elites = {
	"cultist_berzerker",
	"renegade_berzerker",
	"renegade_executor",
	"chaos_ogryn_bulwark",
	"chaos_ogryn_executor",
}
mod.ranged_elites = {
	"cultist_gunner",
	"renegade_gunner",
	"cultist_shocktrooper",
	"renegade_shocktrooper",
	"chaos_ogryn_gunner",
}
mod.specials = {
	"chaos_poxwalker_bomber",
	"renegade_grenadier",
	"cultist_grenadier",
	"renegade_sniper",
	"renegade_flamer",
	"cultist_flamer",
}
mod.disablers = {
	"chaos_hound",
	"chaos_hound_mutator",
	"cultist_mutant",
	"renegade_netgunner",
}

local function player_from_unit(unit)
	local players = Managers.player:players()
	for _, player in pairs(players) do
		if player.player_unit == unit then
			return player
		end
	end
	return nil
end

local function calculate_effective_percent(total_percents, specific_percent, effective_amount_regained)
	local percent_of_effective_total = specific_percent / total_percents

	return effective_amount_regained * percent_of_effective_total
end

mod:hook_safe(CLASS.AttackReportManager, "add_attack_result", function(self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike, ...)
	local scoreboard = get_mod("scoreboard")
	
	if scoreboard == nil then
		return
	end

	local Breed = scoreboard:original_require("scripts/utilities/breed")
	local player = attacking_unit and player_from_unit(attacking_unit)

	if player == nil then
		return
	end

	local debug_mode = mod:get("debug")
	local account_id = player:account_id() or player:name()

	if damage <= 0 then
		return
	end

	local unit_data_extension = ScriptUnit.has_extension(attacked_unit, "unit_data_system")
	local breed_or_nil = unit_data_extension and unit_data_extension:breed()
	local target_is_minion = breed_or_nil and Breed.is_minion(breed_or_nil)

	if target_is_minion == false then
		return
	end

	if attack_result ~= "died" then
		return
	end

	local player_toughness_extension = ScriptUnit.has_extension(player.player_unit, "toughness_system")
	local amount_regained = 0

	if player_toughness_extension == nil then
		if debug_mode then mod:echo("no toughness extension") end
		return
	end

	local max_toughness = player_toughness_extension:max_toughness()

	if max_toughness == nil then
		if debug_mode then mod:echo("nil toughness") end
		return
	end

	if debug_mode then mod:echo("Max toughness: " .. max_toughness) end
	
	local out_for_blood_percent = 0.035
	local melee_percent = 0.05
	local elite_percent = 0.3
	local headshot_percent = 0.15

	local temp_regain = max_toughness * out_for_blood_percent
	amount_regained = amount_regained + temp_regain
	if debug_mode then mod:echo("Kill registered: " .. temp_regain) end
	scoreboard:update_stat("hypothetical_out_for_blood", account_id, temp_regain)

	local melee = false
	local elite = false
	local headshot = false

	if table.array_contains(mod.melee_attack_types, attack_type) or table.array_contains(mod.melee_damage_profiles, damage_profile.name) then
		temp_regain = max_toughness * melee_percent
		amount_regained = amount_regained + temp_regain
		if debug_mode then mod:echo("Melee kill registered: " .. temp_regain) end
		scoreboard:update_stat("hypothetical_melee_toughness", account_id, temp_regain)

		melee = true
	end

	if table.array_contains(mod.melee_elites, breed_or_nil.name) or table.array_contains(mod.ranged_elites, breed_or_nil.name) or table.array_contains(mod.specials, breed_or_nil.name) or table.array_contains(mod.disablers, breed_or_nil.name) then
		temp_regain = max_toughness * elite_percent
		amount_regained = amount_regained + temp_regain
		if debug_mode then mod:echo("Elite kill registered: " .. temp_regain) end
		scoreboard:update_stat("hypothetical_confirmed_kill", account_id, temp_regain)
		
		elite = true
	end

	if hit_weakspot and not melee then
		temp_regain = max_toughness * headshot_percent
		amount_regained = amount_regained + temp_regain
		if debug_mode then mod:echo("Headshot kill registered: " .. temp_regain) end
		scoreboard:update_stat("hypothetical_exhilarating_takedown", account_id, temp_regain)
		
		headshot = true
	end

	if debug_mode then mod:echo("Total hypothetical regained: " .. amount_regained) end

	scoreboard:update_stat("hypothetical_total_toughness", account_id, amount_regained)

	local effective_amount_regained = math.min(player_toughness_extension:toughness_damage(), amount_regained)

	if debug_mode then mod:echo("Total effective regained: " .. effective_amount_regained) end

	scoreboard:update_stat("effective_total_toughness", account_id, effective_amount_regained)

	local effective_total_percents = out_for_blood_percent

	if melee then
		effective_total_percents = effective_total_percents + melee_percent
	end

	if elite then
		effective_total_percents = effective_total_percents + elite_percent
	end

	if headshot then
		effective_total_percents = effective_total_percents + headshot_percent
	end

	if debug_mode then mod:echo("effective total percents: " .. effective_total_percents) end

	local effective_out_for_blood = calculate_effective_percent(effective_total_percents, out_for_blood_percent, effective_amount_regained)
	if debug_mode then mod:echo("effective out for blood: " .. effective_out_for_blood) end
	scoreboard:update_stat("effective_out_for_blood", account_id, effective_out_for_blood)

	if melee then
		local effective_melee = calculate_effective_percent(effective_total_percents, melee_percent, effective_amount_regained)
		if debug_mode then mod:echo("effective melee: " .. effective_melee) end
		scoreboard:update_stat("effective_melee_toughness", account_id, effective_melee)
	end

	if elite then
		local effective_confirmed_kill = calculate_effective_percent(effective_total_percents, elite_percent, effective_amount_regained)
		if debug_mode then mod:echo("effective elite: " .. effective_confirmed_kill) end
		scoreboard:update_stat("effective_confirmed_kill", account_id, calculate_effective_percent(effective_total_percents, elite_percent, effective_amount_regained))
	end

	if headshot then
		local effective_exhilarating_takedown = calculate_effective_percent(effective_total_percents, headshot_percent, effective_amount_regained)
		if debug_mode then mod:echo("effective headshot: " .. effective_exhilarating_takedown) end
		scoreboard:update_stat("effective_exhilarating_takedown", account_id, effective_exhilarating_takedown)
	end

	local coherency_extension = ScriptUnit.extension(player.player_unit, "coherency_system")

	if coherency_extension == nil then
		if debug_mode then mod:echo("no coherency extension") end
		return
	end

	local units_in_coherency = coherency_extension:in_coherence_units()

	local shared_amount = 0

	for unit, _ in pairs(units_in_coherency) do
		if unit == player.player_unit then 
			goto continue 
		end

		local unit_toughness_extension = ScriptUnit.has_extension(unit, "toughness_system")

		if debug_mode then mod:echo("Toughness Damage: " .. unit_toughness_extension:toughness_damage()) end

		shared_amount = shared_amount + math.min(unit_toughness_extension:toughness_damage(), (amount_regained * 0.15))

		if debug_mode then mod:echo("New Shared Amount: " .. shared_amount) end


		::continue::
	end

	scoreboard:update_stat("born_leader", account_id, shared_amount)

end)


mod.scoreboard_rows = {
	{
		name = "total_toughness",
		text = "row_total_toughness",
		group = "group_2",
		summary = {
			"hypothetical_total_toughness",
			"effective_total_toughness",
		},
		validation = "ASC",
		iteration = "ADD",
		setting = "total_toughness",
	},
	{
		name = "hypothetical_total_toughness",
		text = "row_hypothetical_total_toughness",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "total_toughness",
		setting = "total_toughness",
	},
	{
		name = "effective_total_toughness",
		text = "row_effective_total_toughness",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "total_toughness",
		setting = "total_toughness",
	},
	{
		name = "melee_toughness",
		text = "row_melee_toughness",
		group = "group_2",
		summary = {
			"hypothetical_melee_toughness",
			"effective_melee_toughness",
		},
		validation = "ASC",
		iteration = "ADD",
		setting = "melee_toughness",
	},
	{
		name = "hypothetical_melee_toughness",
		text = "row_hypothetical_melee_toughness",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "melee_toughness",
		setting = "melee_toughness",
	},
	{
		name = "effective_melee_toughness",
		text = "row_effective_melee_toughness",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "melee_toughness",
		setting = "melee_toughness",
	},
	{
		name = "exhilarating_takedown",
		text = "row_exhilarating_takedown",
		group = "group_2",
		summary = {
			"hypothetical_exhilarating_takedown",
			"effective_exhilarating_takedown",
		},
		validation = "ASC",
		iteration = "ADD",
		setting = "exhilarating_takedown",
	},
	{
		name = "hypothetical_exhilarating_takedown",
		text = "row_hypothetical_exhilarating_takedown",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "exhilarating_takedown",
		setting = "exhilarating_takedown",
	},
	{
		name = "effective_exhilarating_takedown",
		text = "row_effective_exhilarating_takedown",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "exhilarating_takedown",
		setting = "exhilarating_takedown",
	},
	{
		name = "confirmed_kill",
		text = "row_confirmed_kill",
		group = "group_2",
		summary = {
			"hypothetical_confirmed_kill",
			"effective_confirmed_kill",
		},
		validation = "ASC",
		iteration = "ADD",
		setting = "confirmed_kill",
	},
	{
		name = "hypothetical_confirmed_kill",
		text = "row_hypothetical_confirmed_kill",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "confirmed_kill",
		setting = "confirmed_kill",
	},
	{
		name = "effective_confirmed_kill",
		text = "row_effective_confirmed_kill",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "confirmed_kill",
		setting = "confirmed_kill",
	},
	{
		name = "out_for_blood",
		text = "row_out_for_blood",
		group = "group_2",
		summary = {
			"hypothetical_out_for_blood",
			"effective_out_for_blood",
		},
		validation = "ASC",
		iteration = "ADD",
		setting = "out_for_blood",
	},
	{
		name = "hypothetical_out_for_blood",
		text = "row_hypothetical_out_for_blood",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "out_for_blood",
		setting = "out_for_blood",
	},
	{
		name = "effective_out_for_blood",
		text = "row_effective_out_for_blood",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		parent = "out_for_blood",
		setting = "out_for_blood",
	},
	{
		name = "born_leader",
		text = "row_born_leader",
		group = "group_2",
		validation = "ASC",
		iteration = "ADD",
		setting = "born_leader",
	},
}
