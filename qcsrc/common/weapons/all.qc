#ifndef WEAPONS_ALL_C
#define WEAPONS_ALL_C

#include "all.qh"

#if defined(CSQC)
	#include "../../client/defs.qh"
	#include "../constants.qh"
	#include "../stats.qh"
	#include "../../lib/warpzone/anglestransform.qh"
	#include "../../lib/warpzone/common.qh"
	#include "../../lib/warpzone/client.qh"
	#include "../util.qh"
	#include "../buffs/all.qh"
	#include "../../client/autocvars.qh"
	#include "../deathtypes/all.qh"
	#include "../../lib/csqcmodel/interpolate.qh"
	#include "../movetypes/movetypes.qh"
	#include "../../client/main.qh"
	#include "../../lib/csqcmodel/cl_model.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "../../lib/warpzone/anglestransform.qh"
    #include "../../lib/warpzone/common.qh"
    #include "../../lib/warpzone/util_server.qh"
    #include "../../lib/warpzone/server.qh"
    #include "../constants.qh"
    #include "../stats.qh"
    #include "../teams.qh"
    #include "../util.qh"
    #include "../buffs/all.qh"
    #include "../monsters/all.qh"
    #include "config.qh"
    #include "../../server/weapons/csqcprojectile.qh"
    #include "../../server/weapons/tracing.qh"
    #include "../../server/t_items.qh"
    #include "../../server/autocvars.qh"
    #include "../../server/constants.qh"
    #include "../../server/defs.qh"
    #include "../notifications.qh"
    #include "../deathtypes/all.qh"
    #include "../../server/mutators/mutators_include.qh"
    #include "../mapinfo.qh"
    #include "../../server/command/common.qh"
    #include "../../lib/csqcmodel/sv_model.qh"
    #include "../../server/portals.qh"
    #include "../../server/g_hook.qh"
#endif
#ifndef MENUQC
#include "calculations.qc"
#endif
#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION

// WEAPON PLUGIN SYSTEM

WepSet WepSet_FromWeapon(int a) {
	a -= WEP_FIRST;
	if (Weapons_MAX > 24)
	if (a >= 24) {
		a -= 24;
		if (Weapons_MAX > 48)
		if (a >= 24) {
			a -= 24;
			return '0 0 1' * power2of(a);
		}
		return '0 1 0' * power2of(a);
	}
	return '1 0 0' * power2of(a);
}
#ifdef SVQC
void WepSet_AddStat()
{
	addstat(STAT_WEAPONS, AS_INT, weapons_x);
	if (Weapons_MAX > 24)
	addstat(STAT_WEAPONS2, AS_INT, weapons_y);
	if (Weapons_MAX > 48)
	addstat(STAT_WEAPONS3, AS_INT, weapons_z);
}
void WepSet_AddStat_InMap()
{
	addstat(STAT_WEAPONSINMAP, AS_INT, weaponsinmap_x);
	if (Weapons_MAX > 24)
	addstat(STAT_WEAPONSINMAP2, AS_INT, weaponsinmap_y);
	if (Weapons_MAX > 48)
	addstat(STAT_WEAPONSINMAP3, AS_INT, weaponsinmap_z);
}
void WriteWepSet(float dst, WepSet w)
{
	if (Weapons_MAX > 48)
	WriteInt72_t(dst, w);
	else if (Weapons_MAX > 24)
	WriteInt48_t(dst, w);
	else
	WriteInt24_t(dst, w.x);
}
#endif
#ifdef CSQC
WepSet WepSet_GetFromStat()
{
	WepSet w = '0 0 0';
	w.x = getstati(STAT_WEAPONS);
	if (Weapons_MAX > 24)
	w.y = getstati(STAT_WEAPONS2);
	if (Weapons_MAX > 48)
	w.z = getstati(STAT_WEAPONS3);
	return w;
}
WepSet WepSet_GetFromStat_InMap()
{
	WepSet w = '0 0 0';
	w_x = getstati(STAT_WEAPONSINMAP);
	if (Weapons_MAX > 24)
	w_y = getstati(STAT_WEAPONSINMAP2);
	if (Weapons_MAX > 48)
	w_z = getstati(STAT_WEAPONSINMAP3);
	return w;
}
WepSet ReadWepSet()
{
	if (Weapons_MAX > 48)
	return ReadInt72_t();
	if (Weapons_MAX > 24)
	return ReadInt48_t();
	return ReadInt24_t() * '1 0 0';
}
#endif

string W_FixWeaponOrder(string order, float complete)
{
	return fixPriorityList(order, WEP_FIRST, WEP_LAST, WEP_IMPULSE_BEGIN - WEP_FIRST, complete);
}
string W_NameWeaponOrder_MapFunc(string s)
{
	entity wi;
	if(s == "0" || stof(s))
	{
		wi = get_weaponinfo(stof(s));
		if(wi != WEP_Null)
			return wi.netname;
	}
	return s;
}

string W_UndeprecateName(string s)
{
	switch ( s )
	{
		case "nex"            : return "vortex";
		case "rocketlauncher" : return "devastator";
		case "laser"          : return "blaster";
		case "minstanex"      : return "vaporizer";
		case "grenadelauncher": return "mortar";
		case "uzi"            : return "machinegun";
		default               : return s;
	}
}
string W_NameWeaponOrder(string order)
{
	return mapPriorityList(order, W_NameWeaponOrder_MapFunc);
}
string W_NumberWeaponOrder_MapFunc(string s)
{
	int i;
	if(s == "0" || stof(s))
		return s;
	s = W_UndeprecateName(s);
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
		if(s == get_weaponinfo(i).netname)
			return ftos(i);
	return s;
}
string W_NumberWeaponOrder(string order)
{
	return mapPriorityList(order, W_NumberWeaponOrder_MapFunc);
}

float W_FixWeaponOrder_BuildImpulseList_buf[Weapons_MAX];
string W_FixWeaponOrder_BuildImpulseList_order;
void W_FixWeaponOrder_BuildImpulseList_swap(int i, int j, entity pass)
{
	float h;
	h = W_FixWeaponOrder_BuildImpulseList_buf[i];
	W_FixWeaponOrder_BuildImpulseList_buf[i] = W_FixWeaponOrder_BuildImpulseList_buf[j];
	W_FixWeaponOrder_BuildImpulseList_buf[j] = h;
}
float W_FixWeaponOrder_BuildImpulseList_cmp(int i, int j, entity pass)
{
	entity e1, e2;
	float d;
	e1 = get_weaponinfo(W_FixWeaponOrder_BuildImpulseList_buf[i]);
	e2 = get_weaponinfo(W_FixWeaponOrder_BuildImpulseList_buf[j]);
	d = (e1.impulse + 9) % 10 - (e2.impulse + 9) % 10;
	if(d != 0)
		return -d; // high impulse first!
	return
		strstrofs(strcat(" ", W_FixWeaponOrder_BuildImpulseList_order, " "), sprintf(" %d ", W_FixWeaponOrder_BuildImpulseList_buf[i]), 0)
		-
		strstrofs(strcat(" ", W_FixWeaponOrder_BuildImpulseList_order, " "), sprintf(" %d ", W_FixWeaponOrder_BuildImpulseList_buf[j]), 0)
		; // low char index first!
}
string W_FixWeaponOrder_BuildImpulseList(string o)
{
	int i;
	W_FixWeaponOrder_BuildImpulseList_order = o;
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
		W_FixWeaponOrder_BuildImpulseList_buf[i - WEP_FIRST] = i;
	heapsort(WEP_LAST - WEP_FIRST + 1, W_FixWeaponOrder_BuildImpulseList_swap, W_FixWeaponOrder_BuildImpulseList_cmp, world);
	o = "";
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
		o = strcat(o, " ", ftos(W_FixWeaponOrder_BuildImpulseList_buf[i - WEP_FIRST]));
	W_FixWeaponOrder_BuildImpulseList_order = string_null;
	return substring(o, 1, -1);
}

string W_FixWeaponOrder_AllowIncomplete(string order)
{
	return W_FixWeaponOrder(order, 0);
}

string W_FixWeaponOrder_ForceComplete(string order)
{
	if(order == "")
		order = W_NumberWeaponOrder(cvar_defstring("cl_weaponpriority"));
	return W_FixWeaponOrder(order, 1);
}

void W_RandomWeapons(entity e, float n)
{
	int i, j;
	WepSet remaining;
	WepSet result;
	remaining = e.weapons;
	result = '0 0 0';
	for(i = 0; i < n; ++i)
	{
		RandomSelection_Init();
		for(j = WEP_FIRST; j <= WEP_LAST; ++j)
			if(remaining & WepSet_FromWeapon(j))
				RandomSelection_Add(world, j, string_null, 1, 1);
		result |= WepSet_FromWeapon(RandomSelection_chosen_float);
		remaining &= ~WepSet_FromWeapon(RandomSelection_chosen_float);
	}
	e.weapons = result;
}

string GetAmmoPicture(.int ammotype)
{
	switch (ammotype)
	{
		case ammo_shells:  return ITEM_Shells.m_icon;
		case ammo_nails:   return ITEM_Bullets.m_icon;
		case ammo_rockets: return ITEM_Rockets.m_icon;
		case ammo_cells:   return ITEM_Cells.m_icon;
		case ammo_plasma:  return ITEM_Plasma.m_icon;
		case ammo_fuel:    return ITEM_JetpackFuel.m_icon;
		default: return ""; // wtf, no ammo type?
	}
}

#ifdef CSQC
.int GetAmmoFieldFromNum(int i)
{
	switch(i)
	{
		case 0: return ammo_shells;
		case 1: return ammo_nails;
		case 2: return ammo_rockets;
		case 3: return ammo_cells;
		case 4: return ammo_plasma;
		case 5: return ammo_fuel;
		default: return ammo_none;
	}
}

int GetAmmoStat(.int ammotype)
{
	switch(ammotype)
	{
		case ammo_shells: return STAT_SHELLS;
		case ammo_nails: return STAT_NAILS;
		case ammo_rockets: return STAT_ROCKETS;
		case ammo_cells: return STAT_CELLS;
		case ammo_plasma: return STAT_PLASMA;
		case ammo_fuel: return STAT_FUEL;
		default: return -1;
	}
}
#endif

string W_Sound(string w_snd)
{
	#define extensions(X) X(wav) X(ogg)
	#define tryext(ext) { if (fexists(strcat("sound/", output = strcat("weapons/", w_snd, "."#ext)))) break; }
	string output;
	do {
		extensions(tryext);
		#undef tryext
		#undef extensions
		output = strcat("weapons/", w_snd);
	} while (0);

#ifdef SVQC
	MUTATOR_CALLHOOK(WeaponSound, w_snd, output);
	return weapon_sound_output;
#else
	return output;
#endif
}

string W_Model(string w_mdl)
{
	string output = strcat("models/weapons/", w_mdl);
#ifdef SVQC
	MUTATOR_CALLHOOK(WeaponModel, w_mdl, output);
	return weapon_model_output;
#else
	return output;
#endif
}

#endif
