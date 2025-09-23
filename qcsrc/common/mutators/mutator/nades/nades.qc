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
#ifdef MENUQC
#include "../hook/hook.qh"
#include "../offhand_blaster/offhand_blaster.qh"
#include "../overkill/overkill.qh"

METHOD(MutatorNades, describe, string(MutatorNades this))
{
	TC(MutatorNades, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator gives all players offhand nades that can be primed then thrown by pressing %s twice. "
	      "If the %s and %s mutators are disabled, they can also be thrown by holding then releasing %s."), COLORED_NAME(this), strcat("^3", _("drop weapon"), "^7"), COLORED_NAME(MUTATOR_offhand_blaster), COLORED_NAME(MUTATOR_hook), strcat("^3", _("hook"), "^7"));
	PAR(_("There are multiple types of nades that can be selected, and many configuration options for this mutator, "
	      "so they may act a little differently depending on the server you play on."));
	PAR(_("This mutator is enabled by default in %s."), COLORED_NAME(MUTATOR_ok));
	return PAGE_TEXT;
}
#endif // MENUQC
