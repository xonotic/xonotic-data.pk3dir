#include "nades.qh"

#include "nade/_mod.qh"

#ifdef SVQC
bool autocvar_g_nades_nade_small;
float autocvar_g_nades_spread = 0.04;
#endif

REGISTER_STAT(NADES_SMALL, INT, autocvar_g_nades_nade_small)

#ifdef GAMEQC

REPLICATE(cvar_cl_nade_type, string, "cl_nade_type");
REPLICATE(cvar_cl_pokenade_type, string, "cl_pokenade_type");

entity Nade_TrailEffect(int proj, int nade_team)
{
	switch (proj)
	{
		case PROJECTILE_NADE:       return EFFECT_NADE_TRAIL(nade_team);
		case PROJECTILE_NADE_BURN:  return EFFECT_NADE_TRAIL_BURN(nade_team);
	}

	FOREACH(Nades, true, {
		for (int j = 0; j < 2; ++j)
		{
			if (it.m_projectile[j] == proj)
			{
				string trail = it.m_trail[j].eent_eff_name;
				if (trail) return it.m_trail[j];
				break;
			}
		}
	});

	return EFFECT_Null;
}

#endif // GAMEQC
