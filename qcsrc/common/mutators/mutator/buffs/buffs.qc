#include "buffs.qh"

string BUFF_NAME(int i)
{
	Buff b = REGISTRY_GET(StatusEffects, i);
	return strcat(rgb_to_hexcolor(b.m_color), b.m_name);
}

#ifdef SVQC
string Buff_CompatName(string buffname)
{
	switch (buffname)
	{
		case "ammoregen":              return "ammo";        // Q3TA ammoregen
		case "doubler":                return "inferno";     // Q3TA doubler
		case "scout":                  return "bash";        // Q3TA scout
		case "guard":                  return "resistance";  // Q3TA guard
		case "revival": case "regen":  return "medic";       // WOP revival, Q3A regen
		case "jumper":                 return "jump";        // WOP jumper
		case "invulnerability":        return "vampire";     // Q3TA invulnerability
		case "kamikaze":               return "vengeance";   // Q3TA kamikaze
		case "teleporter":             return "swapper";     // Q3A personal teleporter
		default:                       return buffname;
	}
}
#endif

#ifdef GAMEQC
REPLICATE(cvar_cl_buffs_autoreplace, bool, "cl_buffs_autoreplace");
#endif
