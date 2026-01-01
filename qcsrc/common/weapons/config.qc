#include "config.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/util.qh>
	#include <common/weapons/all.qh>
#endif

// ==========================
//  Balance Config Generator
// ==========================

void W_Config_Queue(string setting)
{
	if (WEP_CONFIG_COUNT <= MAX_CONFIG_SETTINGS - 1)
		config_queue[WEP_CONFIG_COUNT++] = setting;
}

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

	WEP_CONFIG_WRITETOFILE(
		"// ************************************************************************************ //\n"
		"// **                 WARNING - MANUALLY EDIT THIS FILE WITH CAUTION                 ** //\n"
		"// **                                                                                ** //\n"
		"// **  This file can be automatically generated with the command 'dumpweapons'.      ** //\n"
		"// **  This is useful to create custom weapon balance configs, after changing some   ** //\n"
		"// **  weapon balance cvars in-game.                                                 ** //\n"
		"// **  If you are creating a custom weapon balance config file, delete this.         ** //\n"
		"// **                                                                                ** //\n"
		"// **  If you are just editing the default weapon balance (bal-wep-xonotic.cfg),     ** //\n"
		"// **  please keep this comment as it contains helpful documentation.                ** //\n"
		"// **                                                                                ** //\n"
		"// **  These are the default weapon-related balance config settings, categorized by  ** //\n"
		"// **  weapon.                                                                       ** //\n"
		"// **  Other default settings are in balance-xonotic.cfg, which executes this file.  ** //\n"
		"// **  Other wep balance configs like bal-wep-nexuiz25.cfg first execute this, then  ** //\n"
		"// **  override some settings.                                                       ** //\n"
		"// **  Therefore any changes made to the default balance here will affect all        ** //\n"
		"// **  bal-wep-*.cfg files, unless you override it in such files.                    ** //\n"
		"// **                                                                                ** //\n"
		"// **  If you add a new weapon cvar, remove a weapon cvar, or rename a weapon cvar,  ** //\n"
		"// **  please regenerate this file with that command, or manually add it here.       ** //\n"
		"// **                                                                                ** //\n"
		"// ************************************************************************************ //\n"
		"\n");

	FOREACH(Weapons, it != WEP_Null, {
		if(it.spawnflags & WEP_FLAG_SPECIALATTACK)
			continue; // never include the attacks
		// step 1: clear the queue
		WEP_CONFIG_COUNT = 0;
		for (int x = 0; x < MAX_CONFIG_SETTINGS; ++x)
			config_queue[x] = string_null;

		// step 2: build new queue
		it.wr_config(it);

		if (WEP_CONFIG_COUNT > MAX_CONFIG_SETTINGS - 1)
		{
			LOG_INFOF("\n^1Dumping aborted^7: hit MAX_CONFIG_SETTINGS (%d) limit\n\n", MAX_CONFIG_SETTINGS);
			break;
		}

		// step 3: sort queue
		heapsort(WEP_CONFIG_COUNT, W_Config_Queue_Swap, W_Config_Queue_Compare, NULL);

		// step 4: write queue
		WEP_CONFIG_WRITETOFILE(sprintf(
			"// {{{ #%d: %s%s\n",
			wepcount,
			it.m_name,
			((it.spawnflags & WEP_FLAG_MUTATORBLOCKED) ? " (MUTATOR WEAPON)" : "")
		));
		for (int x = 0; x < WEP_CONFIG_COUNT; ++x)
			WEP_CONFIG_WRITETOFILE(config_queue[x]);
		WEP_CONFIG_WRITETOFILE("// }}}\n");

		// step 5: debug info
		LOG_INFOF("#%d: %s: %d settings...", i, it.m_name, WEP_CONFIG_COUNT);
		totalweapons += 1;
		totalsettings += WEP_CONFIG_COUNT;
		wepcount += 1;
	});
	#undef WEP_CONFIG_WRITETOFILE

	// extra information
	if (WEP_CONFIG_COUNT <= MAX_CONFIG_SETTINGS - 1)
		LOG_INFOF("Totals: %d weapons, %d settings", totalweapons, totalsettings);

	// clear queue now that we're finished
	WEP_CONFIG_COUNT = 0;
	for (int x = 0; x < MAX_CONFIG_SETTINGS; ++x)
		config_queue[x] = string_null;
}
