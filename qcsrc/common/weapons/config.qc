#include "config.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/util.qh>
    #include "all.qh"
#endif

// ==========================
//  Balance Config Generator
// ==========================

void W_Config_Queue_Swap(int root, int child, entity pass)
{
	string oldroot = config_queue[root];
	config_queue[root] = config_queue[child];
	config_queue[child] = oldroot;
}

float W_Config_Queue_Compare(int root, int child, entity pass)
{
	return strcmp(config_queue[root], config_queue[child]);
}

void Dump_Weapon_Settings()
{
	int totalweapons = 0, totalsettings = 0;
	int wepcount = 1;
	#define WEP_CONFIG_WRITETOFILE(str) write_String_To_File(wep_config_file, str, wep_config_alsoprint)
	FOREACH(Weapons, it != WEP_Null, {
		if((it.spawnflags & WEP_FLAG_HIDDEN) && (it.spawnflags & WEP_FLAG_MUTATORBLOCKED) && !(it.spawnflags & WEP_FLAG_NORMAL))
			continue; // never include the attacks
		// step 1: clear the queue
		WEP_CONFIG_COUNT = 0;
		for (int x = 0; x <= MAX_CONFIG_SETTINGS; ++x)
			config_queue[x] = string_null;

		// step 2: build new queue
		it.wr_config(it);

		// step 3: sort queue
		heapsort(WEP_CONFIG_COUNT, W_Config_Queue_Swap, W_Config_Queue_Compare, NULL);

		// step 4: write queue
		WEP_CONFIG_WRITETOFILE(sprintf(
			"// {{{ #%d: %s%s\n",
			wepcount,
			it.m_name,
			((it.spawnflags & WEP_FLAG_MUTATORBLOCKED) ? " (MUTATOR WEAPON)" : "")
		));
		for (int x = 0; x <= WEP_CONFIG_COUNT; ++x) { WEP_CONFIG_WRITETOFILE(config_queue[x]); }
		WEP_CONFIG_WRITETOFILE("// }}}\n");

		// step 5: debug info
		LOG_INFOF("#%d: %s: %d settings...", i, it.m_name, WEP_CONFIG_COUNT);
		totalweapons += 1;
		totalsettings += WEP_CONFIG_COUNT;
		wepcount += 1;
	});
	#undef WEP_CONFIG_WRITETOFILE

	// clear queue now that we're finished
	WEP_CONFIG_COUNT = 0;
	for(int x = 0; x <= MAX_CONFIG_SETTINGS; ++x)
		config_queue[x] = string_null;

	// extra information
	LOG_INFOF("Totals: %d weapons, %d settings", totalweapons, totalsettings);
}
