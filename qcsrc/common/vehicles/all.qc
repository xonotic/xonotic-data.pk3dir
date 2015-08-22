#ifndef VEHICLES_ALL_C
#define VEHICLES_ALL_C

#include "all.qh"

#if defined(SVQC)
	#include "sv_vehicles.qc"
#elif defined(CSQC)
	#include "cl_vehicles.qc"
#endif

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION

#ifndef MENUQC
STATIC_INIT(vehicles_common_initialize)
{
#ifdef CSQC
	precache_model("models/vehicles/bomblet.md3");
	precache_model("models/vehicles/clusterbomb.md3");
	precache_model("models/vehicles/clusterbomb_fragment.md3");
	precache_model("models/vehicles/rocket01.md3");
	precache_model("models/vehicles/rocket02.md3");

	precache_sound ("vehicles/alarm.wav");
	precache_sound ("vehicles/alarm_shield.wav");
#endif // CSQC
#ifdef SVQC
	precache_sound("onslaught/ons_hit2.wav");
	precache_sound("onslaught/electricity_explode.wav");

	addstat(STAT_HUD, AS_INT, hud);
	addstat(STAT_VEHICLESTAT_HEALTH,  AS_INT, vehicle_health);
	addstat(STAT_VEHICLESTAT_SHIELD,  AS_INT, vehicle_shield);
	addstat(STAT_VEHICLESTAT_ENERGY,  AS_INT, vehicle_energy);

	addstat(STAT_VEHICLESTAT_W2MODE, AS_INT, vehicle_weapon2mode);

	addstat(STAT_VEHICLESTAT_AMMO1,   AS_INT, vehicle_ammo1);
	addstat(STAT_VEHICLESTAT_RELOAD1, AS_INT, vehicle_reload1);

	addstat(STAT_VEHICLESTAT_AMMO2,   AS_INT, vehicle_ammo2);
	addstat(STAT_VEHICLESTAT_RELOAD2, AS_INT, vehicle_reload2);
#endif // SVQC
}
#endif

entity get_vehicleinfo(int id)
{
	if (id < VEH_FIRST || id > VEH_LAST) return VEH_NULL;
	entity m = vehicle_info[id];
	return m ? m : VEH_NULL;
}

#endif
