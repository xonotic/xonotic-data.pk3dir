typedef void(float id, float itemtype, void() spawnfunc) item_ammo_acceptor;

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
float item_ammo_count[ITEM_AMMO_COUNT];
.float item_ammo_weight[ITEM_AMMO_COUNT];
.float item_ammo_priority[ITEM_AMMO_COUNT];
.float item_ammo_chosen_type;

float autocvar_g_balance_ammodistribution_nudgevalue = 0;
float autocvar_g_balance_ammodistribution_inner_exponent = -1;
float autocvar_g_balance_ammodistribution_outer_exponent = 2;
float autocvar_g_balance_ammodistribution_p3distance = 96;
float autocvar_g_balance_ammodistribution_p2distance = 512;

float item_ammo_picked;
void item_ammo_pick()
{
	if (item_ammo_picked)
		return;
	item_ammo_picked = 1;

	entity ammos = findchain(classname, "item_ammo");
	entity weapons = findchainflags(flags, FL_WEAPON);

	entity w, a;
	float i;

	float n_w = 0;
	for (w = weapons; w; w = w.chain)
		++n_w;
	float n_a = 0;
	for (a = ammos; a; a = a.chain)
		++n_a;

	// Find the weights and priorities.
	for (a = ammos; a; a = a.chain)
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
			for (w = weapons; w; w = w.chain)
				if (get_weaponinfo(w.weapon).items & item_ammo_type(i))
				{
					float dist = vlen(w.origin - a.origin);
					if (mindist < 0 || dist < mindist)
						mindist = dist;
					sum += pow(dist, autocvar_g_balance_ammodistribution_inner_exponent);
				}
			a.item_ammo_weight[i] = pow(sum, autocvar_g_balance_ammodistribution_outer_exponent) * weight;
			if (forbid || mindist < 0)
				a.item_ammo_priority[i] = 0;
			else if (mindist <= autocvar_g_balance_ammodistribution_p3distance)
				a.item_ammo_priority[i] = 3;
			else if (mindist <= autocvar_g_balance_ammodistribution_p2distance)
				a.item_ammo_priority[i] = 2;
			else
				a.item_ammo_priority[i] = 1;
		}

	// Find out how many we want of each item.
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		item_ammo_count[i] = 0;
	for (w = weapons; w; w = w.chain)
	{
		float c = 0;
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			if (get_weaponinfo(w.weapon).items & item_ammo_type(i))
				++c;
		if (!c)
		{
			// Ammoless weapon is not a weapon.
			--n_w;
			continue;
		}
		c = 1.0 / c;
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			if (get_weaponinfo(w.weapon).items & item_ammo_type(i))
				item_ammo_count[i] += c;
	}
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		item_ammo_count[i] = ceil(item_ammo_count[i] * n_a / n_w + autocvar_g_balance_ammodistribution_nudgevalue);

	// Make sure the selected item types are cleared.
	for (a = ammos; a; a = a.chain)
		a.item_ammo_chosen_type = -1;

	// Distribute them properly.
	while (n_a > 0)
	{
		// Randomly pick one of the remaining item spawn points, and a
		// corresponding item type. Honor priorities and weights.
		RandomSelection_Init();
		for (a = ammos; a; a = a.chain)
			if (a.item_ammo_chosen_type == -1)
				for (i = 0; i < ITEM_AMMO_COUNT; ++i)
					if (item_ammo_count[i] > 0)
						RandomSelection_Add(a, i, string_null, a.item_ammo_weight[i], a.item_ammo_priority[i]);
		a = RandomSelection_chosen_ent;
		i = RandomSelection_chosen_float;

		if (!a)
			error("Nothing to select.");

		// Assign the selected item type to the selected item.
		a.item_ammo_chosen_type = i;

		print(sprintf("%v: %s -> %s\n", a.origin, a.save_classname, Item_CounterFieldName(item_ammo_type(i))));

		// Decrease the count of remaining items.
		--item_ammo_count[i];
		--n_a;
	}

	// SPAWN SPAWN SPAWN
	for (a = ammos; a; a = a.chain)
	{
		if (a.item_ammo_chosen_type == -1)
			error("item_ammo_wtf");
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			a.(Item_CounterField(item_ammo_type(i))) = 0;
		self = a;
		item_ammo_spawnfunc(a.item_ammo_chosen_type)();
	}
}

void spawnfunc_item_ammo()
{
	InitializeEntity(self, item_ammo_pick, INITPRIO_FIRST);
}
