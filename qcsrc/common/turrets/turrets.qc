#include "all.qh"

// TURRET PLUGIN SYSTEM
entity turret_info[TUR_MAXCOUNT];
entity dummy_turret_info;

void register_turret(float id, float(float) func, float turretflags, vector min_s, vector max_s, string modelname, string headmodelname, string shortname, string mname)
{
	entity e;
	turret_info[id - 1] = e = spawn();
	e.classname = "turret_info";
	e.turretid = id;
	e.netname = shortname;
	e.turret_name = mname;
	e.turret_func = func;
	e.mdl = modelname;
	e.cvar_basename = shortname;
	e.spawnflags = turretflags;
	e.mins = min_s;
	e.maxs = max_s;
	e.model = strzone(strcat("models/turrets/", modelname));
	e.head_model = strzone(strcat("models/turrets/", headmodelname));
}
float t_null(float dummy) { return 0; }
void register_turrets_done()
{
	dummy_turret_info = spawn();
	dummy_turret_info.classname = "turret_info";
	dummy_turret_info.turretid = 0; // you can recognize dummies by this
	dummy_turret_info.netname = "";
	dummy_turret_info.turret_name = "Turret";
	dummy_turret_info.turret_func = t_null;
	dummy_turret_info.mdl = "";
	dummy_turret_info.mins = '-0 -0 -0';
	dummy_turret_info.maxs = '0 0 0';
	dummy_turret_info.model = "";
}
entity get_turretinfo(float id)
{
	entity m;
	if(id < TUR_FIRST || id > TUR_LAST)
		return dummy_turret_info;
	m = turret_info[id - 1];
	if(m)
		return m;
	return dummy_turret_info;
}
