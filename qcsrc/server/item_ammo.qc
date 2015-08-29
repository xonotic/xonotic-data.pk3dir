typedef void(float id, float itemtype, void() spawnfunc) item_ammo_acceptor;

// TODO define them in the balance configs
float autocvar_g_balance_ammodistribution_nudgefactor_min = 0.7;
float autocvar_g_balance_ammodistribution_nudgefactor_max = 1.4;
float autocvar_g_balance_ammodistribution_inner_exponent = -1;
float autocvar_g_balance_ammodistribution_outer_exponent = 2;
float autocvar_g_balance_ammodistribution_outer_nonmatch_exponent = -2;
float autocvar_g_balance_ammodistribution_distance_short = 64 * 2.125 + 1;
float autocvar_g_balance_ammodistribution_distance_medium = 512 + 1;
// NOTE: these also exist per weapon
float autocvar_g_balance_ammodistribution_modifier_shells = 1;
float autocvar_g_balance_ammodistribution_modifier_bullets = 1;
float autocvar_g_balance_ammodistribution_modifier_cells = 1;
float autocvar_g_balance_ammodistribution_modifier_plasma = 1;
float autocvar_g_balance_ammodistribution_modifier_rockets = 1;
float autocvar_g_balance_ammodistribution_modifier_fuel = 1;

#define ITEM_AMMO_COUNT 6
void() item_ammo_spawnfunc(float i)
{
	switch (i)
	{
		case 0: return spawnfunc_item_shells;
		case 1: return spawnfunc_item_bullets;
		case 2: return spawnfunc_item_cells;
		case 3: return spawnfunc_item_plasma;
		case 4: return spawnfunc_item_rockets;
		case 5: return spawnfunc_item_fuel;
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
		case 3: m = autocvar_g_balance_ammodistribution_modifier_plasma; break;
		case 4: m = autocvar_g_balance_ammodistribution_modifier_rockets; break;
		case 5: m = autocvar_g_balance_ammodistribution_modifier_fuel; break;
		default: error("item_ammo_wtf");
	}
	if (m == 0)
		return 1;
	if (m < 0)
		return 0;
	return m;
};
Ammo item_ammo_type(int i)
{
	switch (i)
	{
		case 0: return ITEM_Shells;
		case 1: return ITEM_Bullets;
		case 2: return ITEM_Cells;
		case 3: return ITEM_Plasma;
		case 4: return ITEM_Rockets;
		case 5: return ITEM_JetpackFuel;
		default: error("item_ammo_wtf");
	}
	return ITEM_Shells;
}

string Item_CounterFieldName(Ammo a) { return a.m_name; }
.int Item_CounterField(Ammo a)
{
	switch (a) {
		case ITEM_Shells: return ammo_shells;
		case ITEM_Bullets: return ammo_nails;
		case ITEM_Cells: return ammo_cells;
		case ITEM_Plasma: return ammo_plasma;
		case ITEM_Rockets: return ammo_rockets;
		case ITEM_JetpackFuel: return ammo_fuel;
		default: return ammo_none;
    }
}

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

const float ITEM_AMMO_PRIORITY_UNDEFINED = -1;
const float ITEM_AMMO_PRIORITY_UNIQUE = 1;
const float ITEM_AMMO_PRIORITY_FORBIDDEN = 0;
const float ITEM_AMMO_PRIORITY_NOTTHERE = 2;
const float ITEM_AMMO_PRIORITY_FAR = 4;
const float ITEM_AMMO_PRIORITY_MEDIUM = 6;
const float ITEM_AMMO_PRIORITY_SHORT = 8;

float item_ammo_picked;
.string save_classname;
void item_ammo_pick()
{
	entity w, a;
	float i, j;

	// Run only once.
	if (item_ammo_picked)
		return;
	item_ammo_picked = 1;

	// Find the items we care about.
	entity ammolist = findchain(classname, "item_ammo");
	entity weaponlist = findchainflags(flags, FL_WEAPON);

	// Count the ammo items. We'll need this in many places.
	float n_ammo = 0;
	for (a = ammolist; a; a = a.chain)
		++n_ammo;

	// Find out how many we want of each item.
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		item_ammo_count[i] = 0;
		item_ammo_mincount[i] = 0;
	}
	for (j = WEP_FIRST; j <= WEP_LAST; ++j)
		if (start_weapons & get_weaponinfo(j).weapons)
			for (i = 0; i < ITEM_AMMO_COUNT; ++i)
				if (get_weaponinfo(j).items & item_ammo_type(i).m_itemid)
				{
					item_ammo_mincount[i] = 1;
					// Just 1, even in teamplay! On
					// properly designed maps, these
					// low-priority items will end up in an
					// neutral area.
				}
	float n_weapons = 0;
	for (w = weaponlist; w; w = w.chain)
	{
		float n_ammotypes = 0;
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			if (get_weaponinfo(w.weapon).items & item_ammo_type(i).m_itemid)
				++n_ammotypes;
		if (!n_ammotypes)
			continue;

		// Teamed items count as 1 item in total.
		float n_itemteams = 1;
		if (w.team)
		{
			entity w2;
			for(w2 = world; (w2 = findfloat(w2, team, w.team)); )
				if (w2 != w)
					if(w2.flags & FL_WEAPON)
						++n_itemteams;
		}

		n_weapons += 1.0 / n_itemteams;

		// A weapon also counts as 1 in total, no matter how many ammo
		// types it uses.
		float weight = 1.0 / (n_ammotypes * n_itemteams);
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
			if (get_weaponinfo(w.weapon).items & item_ammo_type(i).m_itemid)
			{
				item_ammo_count[i] += item_ammo_modifier(i) * item_ammo_weaponmodifier(w.weapon) * weight;
				// Weapon exists on the map! No "bonus" for
				// start weapons needed any more, as the weapon
				// pickup serves as ammo too.
				item_ammo_mincount[i] = 0;
			}
	}
	float n_count = 0;
	float n_mincount = 0;
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		n_count += item_ammo_count[i];
		n_mincount += item_ammo_mincount[i];
	}
	// Scale the ratio by the numbers of available guns.
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
	{
		float c_i = item_ammo_count[i];
		float m_i = item_ammo_mincount[i];
		item_ammo_count[i]    = m_i + max(0,  ceil(c_i * (n_ammo - n_mincount) / n_count * autocvar_g_balance_ammodistribution_nudgefactor_max));
		// Obviously >=
		item_ammo_mincount[i] = m_i + max(0, floor(c_i * (n_ammo - n_mincount) / n_count * autocvar_g_balance_ammodistribution_nudgefactor_min));
		dprint(sprintf("Item %s distribution: at least %d, at most %d, distribution input %d %f\n", Item_CounterFieldName(item_ammo_type(i)), item_ammo_mincount[i], item_ammo_count[i], m_i, c_i));
	}
	// Recalculate minimum counts, as we just changed item_ammo_mincount[]
	n_mincount = 0;
	for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		n_mincount += item_ammo_mincount[i];

	// Check for sane distribution.
	if (n_ammo < n_weapons * 0.5)
		print("^3WARNING: not enough ammo items. Expect to run out of ammo.\n");
	if (n_ammo > n_weapons * 2.0)
		print("^3WARNING: too many ammo items. Expect to swim in ammo.\n");

	// Find the weights and priorities.
	for (a = ammolist; a; a = a.chain)
	{
		float totalsum = 0;
		float maxprio = ITEM_AMMO_PRIORITY_UNDEFINED;
		float maxprio_count = 0;
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
				if (get_weaponinfo(w.weapon).items & item_ammo_type(i).m_itemid)
				{
					float dist = vlen(w.origin - a.item_ammo_origin);
					if (mindist < 0 || dist < mindist)
						mindist = dist;
					sum += pow(dist, autocvar_g_balance_ammodistribution_inner_exponent);
				}
			if (mindist < 0)
				a.item_ammo_weight[i] = weight;  // To be fixed later.
			else
				a.item_ammo_weight[i] = pow(sum, autocvar_g_balance_ammodistribution_outer_exponent) * weight;

			// Mapper said to not place this item here? FINE.
			if (forbid)
				a.item_ammo_priority[i] = ITEM_AMMO_PRIORITY_FORBIDDEN;
			// Not there? Quite low prio, then.
			else if (mindist < 0)
				a.item_ammo_priority[i] = ITEM_AMMO_PRIORITY_NOTTHERE;
			// Distance based decisions.
			else if (mindist <= autocvar_g_balance_ammodistribution_distance_short)
				a.item_ammo_priority[i] = ITEM_AMMO_PRIORITY_SHORT;
			else if (mindist <= autocvar_g_balance_ammodistribution_distance_medium)
				a.item_ammo_priority[i] = ITEM_AMMO_PRIORITY_MEDIUM;
			else
				a.item_ammo_priority[i] = ITEM_AMMO_PRIORITY_FAR;
			if (a.item_ammo_priority[i] > maxprio)
			{
				maxprio = a.item_ammo_priority[i];
				maxprio_count = 1;
			}
			else if (a.item_ammo_priority[i] == maxprio)
				++maxprio_count;
			totalsum += sum;
		}
		for (i = 0; i < ITEM_AMMO_COUNT; ++i)
		{
			// If item is not there at all, we could not assign a
			// weight. Assign a weight based on the inverse of the
			// other item weights (i.e. put it where it's least in
			// the way for other items).
			if (a.item_ammo_priority[i] == ITEM_AMMO_PRIORITY_NOTTHERE)
				a.item_ammo_weight[i] *= pow(totalsum, autocvar_g_balance_ammodistribution_outer_nonmatch_exponent);
			// Boost if the highest priority is unique (respect
			// mapper's intentions).
			if (a.item_ammo_priority[i] == maxprio && maxprio_count == 1)
				a.item_ammo_priority[i] |= ITEM_AMMO_PRIORITY_UNIQUE;
		}
	}

	// Make sure the selected item types are cleared.
	for (a = ammolist; a; a = a.chain)
		a.item_ammo_chosen_type = -1;

	// Distribute them properly. Remember the highest unfulfilled priority
	// for warnings.
	float max_unfulfilled_priority = ITEM_AMMO_PRIORITY_UNDEFINED;
	while (n_ammo > 0)
	{
		// Randomly pick one of the remaining item spawn points, and a
		// corresponding item type. Honor priorities and weights.
		RandomSelection_Init();
		for (a = ammolist; a; a = a.chain)
			if (a.item_ammo_chosen_type == -1)
				for (i = 0; i < ITEM_AMMO_COUNT; ++i)
					if (((n_ammo <= n_mincount) ? item_ammo_mincount[i] : item_ammo_count[i]) > 0)
						RandomSelection_Add(a, i, string_null, a.item_ammo_weight[i], a.item_ammo_priority[i]);
		a = RandomSelection_chosen_ent;
		i = RandomSelection_chosen_float;

		// Selection failed?
		if (!a)
			error("Nothing to select. Probably a bug in this code.");

		dprint(sprintf("%v (%v): %s -> %s (%d)\n", a.origin, a.item_ammo_origin, a.save_classname, Item_CounterFieldName(item_ammo_type(i)), a.item_ammo_priority[i]));

		// Assign the selected item type to the selected item.
		a.item_ammo_chosen_type = i;

		// Test for unfulfilled priorities.
		for (j = 0; j < ITEM_AMMO_COUNT; ++j)
			if (j != i)
				if (a.item_ammo_priority[j] >= a.item_ammo_priority[i])
					if (a.item_ammo_priority[j] > max_unfulfilled_priority)
						max_unfulfilled_priority = a.item_ammo_priority[j];

		// Decrease the count of remaining items.
		if (item_ammo_mincount[i] > 0)
			--n_mincount;
		--item_ammo_mincount[i];
		--item_ammo_count[i];
		--n_ammo;
	}

	// Report the highest unfulfilled priority.
	switch (max_unfulfilled_priority)
	{
		case ITEM_AMMO_PRIORITY_SHORT | ITEM_AMMO_PRIORITY_UNIQUE:
			print("^3WARNING: short-range distribution could not be fulfilled with the available item counts. Random selection has taken place.\n");
			break;
		case ITEM_AMMO_PRIORITY_SHORT:
			print("^3WARNING: short-range distribution is ambiguous. Random selection has taken place.\n");
			break;
		case ITEM_AMMO_PRIORITY_MEDIUM | ITEM_AMMO_PRIORITY_UNIQUE:
			print("^3WARNING: medium-range distribution could not be fulfilled with the available item counts. Random selection has taken place.\n");
			break;
		case ITEM_AMMO_PRIORITY_MEDIUM:
			print("^3WARNING: medium-range distribution is ambiguous. Random selection has taken place.\n");
			break;
	}

	// Recount the item counts for debugging.
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
