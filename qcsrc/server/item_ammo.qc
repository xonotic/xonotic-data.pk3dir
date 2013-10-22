typedef void(float id, float itemtype, void() spawnfunc) item_ammo_acceptor;

// TODO define them in the balance configs
float autocvar_g_balance_ammodistribution_nudgefactor_min = 0.7;
float autocvar_g_balance_ammodistribution_nudgefactor_max = 1.4;
float autocvar_g_balance_ammodistribution_inner_exponent = -1;
float autocvar_g_balance_ammodistribution_outer_exponent = 2;
float autocvar_g_balance_ammodistribution_outer_nonmatch_exponent = -2;
float autocvar_g_balance_ammodistribution_p3distance = 64 * 3 + 1;
float autocvar_g_balance_ammodistribution_p2distance = 1024 + 1;
// NOTE: these also exist per weapon
float autocvar_g_balance_ammodistribution_modifier_shells = 1;
float autocvar_g_balance_ammodistribution_modifier_bullets = 1;
float autocvar_g_balance_ammodistribution_modifier_cells = 1;
float autocvar_g_balance_ammodistribution_modifier_rockets = 1;
float autocvar_g_balance_ammodistribution_modifier_fuel = 1;

#define ITEM_AMMO_COUNT 5
void() item_ammo_spawnfunc(float i)
{
	switch (i)
	{
		case 0: return spawnfunc_item_shells;
		case 1: return spawnfunc_item_bullets;
		case 2: return spawnfunc_item_cells;
		case 3: return spawnfunc_item_rockets;
		case 4: return spawnfunc_item_fuel;
		default: error("item_ammo_wtf");
	}
	return spawnfunc_item_shells;
};
float item_ammo_weaponmodifier(float w)
{
	// autocvars are inconvenient here
	float m = cvar(strcat("g_balance_ammodistribution_modifier_", get_weaponinfo(w).netname));
	if (m == 0)
		return 1;
	if (m < 0)
		return 0;
	return m;
}
float item_ammo_modifier(float i)
{
	float m = 0;
	switch (i)
	{
		case 0: m = autocvar_g_balance_ammodistribution_modifier_shells; break;
		case 1: m = autocvar_g_balance_ammodistribution_modifier_bullets; break;
		case 2: m = autocvar_g_balance_ammodistribution_modifier_cells; break;
		case 3: m = autocvar_g_balance_ammodistribution_modifier_rockets; break;
		case 4: m = autocvar_g_balance_ammodistribution_modifier_fuel; break;
		default: error("item_ammo_wtf");
	}
	if (m == 0)
		return 1;
	if (m < 0)
		return 0;
	return m;
};
float item_ammo_type(float i)
{
	switch (i)
	{
		case 0: return IT_SHELLS;
		case 1: return IT_NAILS;
		case 2: return IT_CELLS;
		case 3: return IT_ROCKETS;
		case 4: return IT_FUEL;
		default: error("item_ammo_wtf");
	}
	return 0;
};
float item_ammo_mincount[ITEM_AMMO_COUNT];
float item_ammo_count[ITEM_AMMO_COUNT];
.float item_ammo_weight[ITEM_AMMO_COUNT];
.float item_ammo_priority[ITEM_AMMO_COUNT];
.float item_ammo_chosen_type;
.vector item_ammo_origin;

void item_ammo_findtarget()
{
	entity e;
	RandomSelection_Init();
	for (e = world; (e = find(e, targetname, self.target)); )
		RandomSelection_Add(e, 0, string_null, (e.cnt ? e.cnt : 1), 0);
	if (RandomSelection_chosen_ent)
		self.item_ammo_origin = e.origin;
}

float item_ammo_picked;
void item_ammo_pick()
{
	if (item_ammo_picked)
		return;
	item_ammo_picked = 1;

	entity ammolist = findchain(classname, "item_ammo");
	entity weaponlist = findchainflags(flags, FL_WEAPON);

	entity w, a;
	float i, j;

	float n_w = 0;
	for (w = weaponlist; w; w = w.chain)
		++n_w;
	float n_a = 0;
	for (a = ammolist; a; a = a.chain)
		++n_a;

	float n_teams = 1;
	if (have_team_spawns > 0)
	{
		CheckAllowedTeams(world);
		n_teams = (c1 >= 0) + (c2 >= 0) + (c3 >= 0) + (c4 >= 0);
	}

	// Find out how many we want of each item.
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		item_ammo_count[i] = 0;
		item_ammo_mincount[i] = 0;
	}
	for (j = WEP_FIRST; j <= WEP_LAST; ++j)
		if (start_weapons & get_weaponinfo(j).weapons)
			for (i = 0; i < ITEM_AMMO_COUNT; ++i)
				if (get_weaponinfo(j).items & item_ammo_type(i))
					item_ammo_mincount[i] = n_teams;
	for (w = weaponlist; w; w = w.chain)
	{
		float c = 0;
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			if (get_weaponinfo(w.weapon).items & item_ammo_type(i))
				++c;
		if (!c)
		{
			// Ammoless weapon is not a weapon.
			--n_w;
			// No need to remove it from the list though - no other
			// loop will do anything with it.
			continue;
		}
		c = 1.0 / c;
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			if (get_weaponinfo(w.weapon).items & item_ammo_type(i))
			{
				item_ammo_count[i] += item_ammo_modifier(i) * item_ammo_weaponmodifier(w.weapon) * c;
				item_ammo_mincount[i] = 0;  // n_teams;  // Not needed, weapons serve as ammo pickups too.
			}
	}
	float n_count = 0;
	float n_mincount = 0;
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		n_count += item_ammo_count[i];
		n_mincount += item_ammo_mincount[i];
	}
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		float c_i = item_ammo_count[i];
		float m_i = item_ammo_mincount[i];
		item_ammo_count[i]    = m_i + max(0,  ceil(c_i * (n_a - n_mincount) / n_count * autocvar_g_balance_ammodistribution_nudgefactor_max));
		// Obviously >=
		item_ammo_mincount[i] = m_i + max(0, floor(c_i * (n_a - n_mincount) / n_count * autocvar_g_balance_ammodistribution_nudgefactor_min));
		dprint(sprintf("Item %s distribution: at least %d, at most %d, distribution input %d %f\n", Item_CounterFieldName(item_ammo_type(i)), item_ammo_mincount[i], item_ammo_count[i], m_i, c_i));
	}

	// Find the weights and priorities.
	for (a = ammolist; a; a = a.chain)
	{
		float totalsum = 0;
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		{
			float weight = a.(Item_CounterField(item_ammo_type(i)));
			float forbid = weight < 0;
			if (weight == 0)
				weight = 1;
			else
				weight = fabs(weight);
			float sum = 0;
			float mindist = -1;
			for (w = weaponlist; w; w = w.chain)
				if (get_weaponinfo(w.weapon).items & item_ammo_type(i))
				{
					float dist = vlen(w.origin - a.item_ammo_origin);
					if (mindist < 0 || dist < mindist)
						mindist = dist;
					sum += pow(dist, autocvar_g_balance_ammodistribution_inner_exponent);
				}
			if (sum == 0)
				a.item_ammo_weight[i] = 0;
			else
				a.item_ammo_weight[i] = pow(sum, autocvar_g_balance_ammodistribution_outer_exponent) * weight;
			if (mindist < 0)
				a.item_ammo_priority[i] = 0;
			else if (forbid)
				a.item_ammo_priority[i] = 1;
			else if (mindist <= autocvar_g_balance_ammodistribution_p3distance)
				a.item_ammo_priority[i] = 4;
			else if (mindist <= autocvar_g_balance_ammodistribution_p2distance)
				a.item_ammo_priority[i] = 3;
			else
				a.item_ammo_priority[i] = 2;
			totalsum += sum;
		}
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		{
			float weight = a.(Item_CounterField(item_ammo_type(i)));
			if (a.item_ammo_weight[i] == 0)
				a.item_ammo_weight[i] = pow(totalsum, autocvar_g_balance_ammodistribution_outer_nonmatch_exponent) * weight;
		}
	}

	// Make sure the selected item types are cleared.
	for (a = ammolist; a; a = a.chain)
		a.item_ammo_chosen_type = -1;

	// Distribute them properly.
	n_mincount = 0;
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		n_mincount += item_ammo_mincount[i];
	while (n_a > 0)
	{
		// Randomly pick one of the remaining item spawn points, and a
		// corresponding item type. Honor priorities and weights.
		print(sprintf("%d %d\n", n_a, n_mincount));
		RandomSelection_Init();
		for (a = ammolist; a; a = a.chain)
			if (a.item_ammo_chosen_type == -1)
				for (i = 0; i < ITEM_AMMO_COUNT; ++i)
					if (((n_a <= n_mincount) ? item_ammo_mincount[i] : item_ammo_count[i]) > 0)
						RandomSelection_Add(a, i, string_null, a.item_ammo_weight[i], a.item_ammo_priority[i]);
		a = RandomSelection_chosen_ent;
		i = RandomSelection_chosen_float;

		if (!a)
		{
			if (n_mincount >= 0)
			{
				backtrace("Nothing to select. Retrying without mincount... (BTW: FIX YOUR MAP AND/OR THIS CODE)");
				n_mincount = 0;
				continue;
			}
			error("Nothing to select.");
		}

		// Assign the selected item type to the selected item.
		a.item_ammo_chosen_type = i;

		dprint(sprintf("%v (%v): %s -> %s\n", a.origin, a.item_ammo_origin, a.save_classname, Item_CounterFieldName(item_ammo_type(i))));

		// Decrease the count of remaining items.
		if (item_ammo_mincount[i] > 0)
			--n_mincount;
		--item_ammo_mincount[i];
		--item_ammo_count[i];
		--n_a;
	}

	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		if (item_ammo_count[i] - item_ammo_mincount[i] >= 2)
		{
			if (item_ammo_mincount[i] == 0)
				print(sprintf("WARNING: map might not have enough item_ammo near %s weapons\n", Item_CounterFieldName(item_ammo_type(i))));
			if (item_ammo_count[i] == 0)
				print(sprintf("WARNING: map might have too many item_ammo near %s weapons\n", Item_CounterFieldName(item_ammo_type(i))));
		}
	}

	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		item_ammo_count[i] = 0;
	for (a = ammolist; a; a = a.chain)
		++item_ammo_count[a.item_ammo_chosen_type];
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		dprint(sprintf("Item %s distribution: spawning %d\n", Item_CounterFieldName(item_ammo_type(i)), item_ammo_count[i]));

	// SPAWN SPAWN SPAWN
	for (a = ammolist; a; a = a.chain)
	{
		if (a.item_ammo_chosen_type == -1)
			error("item_ammo_wtf");
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			a.(Item_CounterField(item_ammo_type(i))) = 0;
		a.target = string_null;
		self = a;
		item_ammo_spawnfunc(a.item_ammo_chosen_type)();
	}
}

void spawnfunc_item_ammo()
{
	if (self.item_ammo_origin == '0 0 0')
		self.item_ammo_origin = self.origin;
	if (self.target != "")
		InitializeEntity(self, item_ammo_findtarget, INITPRIO_PREBECOME);
	InitializeEntity(self, item_ammo_pick, INITPRIO_BECOME);
}
