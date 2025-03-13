#include "config.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/turrets/all.qh>
	#include <common/util.qh>
#endif

// ==========================
//  Turret Config Generator
// ==========================

#ifdef SVQC

void T_Config_Queue(string setting)
{
	if (TUR_CONFIG_COUNT <= MAX_CONFIG_SETTINGS - 1)
		config_queue[TUR_CONFIG_COUNT++] = setting;
}

void T_Config_Queue_Swap(float root, float child, entity pass)
{
	string oldroot = config_queue[root];
	config_queue[root] = config_queue[child];
	config_queue[child] = oldroot;
}

float T_Config_Queue_Compare(float root, float child, entity pass)
{
	float i, r, c;

	for(i = 1; i <= 100; ++i)
	{
		r = str2chr(config_queue[root], i);
		c = str2chr(config_queue[child], i);
		if(r == c) { continue; }
		else if(c > r) { return -1; }
		else { return 1; }
	}

	return 0;
}

void Dump_Turret_Settings()
{
	#define TUR_CONFIG_WRITETOFILE(str) write_String_To_File(tur_config_file, str, tur_config_alsoprint)
	int totalsettings = 0;
	FOREACH(Turrets, it != TUR_Null, {
		// step 1: clear the queue
		TUR_CONFIG_COUNT = 0;
		for (int j = 0; j < MAX_CONFIG_SETTINGS; ++j)
			config_queue[j] = string_null;

		// step 2: build new queue
		it.tr_config(it);

		if (TUR_CONFIG_COUNT > MAX_CONFIG_SETTINGS - 1)
		{
			LOG_INFOF("\n^1Dumping aborted^7: hit MAX_CONFIG_SETTINGS (%d) limit\n\n", MAX_CONFIG_SETTINGS);
			break;
		}

		// step 3: sort queue
		heapsort(TUR_CONFIG_COUNT, T_Config_Queue_Swap, T_Config_Queue_Compare, NULL);

		// step 4: write queue
		TUR_CONFIG_WRITETOFILE(sprintf("// {{{ #%d: %s\n", i, it.m_name));
		for (int j = 0; j < TUR_CONFIG_COUNT; ++j)
			TUR_CONFIG_WRITETOFILE(config_queue[j]);
		TUR_CONFIG_WRITETOFILE("// }}}\n");

		// step 5: debug info
		LOG_INFOF("#%d: %s: %d settings...", i, it.m_name, TUR_CONFIG_COUNT);
		totalsettings += TUR_CONFIG_COUNT;
	});
	#undef TUR_CONFIG_WRITETOFILE

	// extra information
	if (TUR_CONFIG_COUNT <= MAX_CONFIG_SETTINGS - 1)
		LOG_INFOF("Totals: %d turrets, %d settings", (REGISTRY_COUNT(Turrets) - 1), totalsettings);

	// clear queue now that we're finished
	TUR_CONFIG_COUNT = 0;
	for (int j = 0; j < MAX_CONFIG_SETTINGS; ++j)
		config_queue[j] = string_null;
}

#endif
