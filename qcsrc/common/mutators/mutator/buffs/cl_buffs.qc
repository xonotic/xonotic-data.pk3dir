#include "cl_buffs.qh"

REGISTER_MUTATOR(cl_buffs, true);
MUTATOR_HOOKFUNCTION(cl_buffs, WP_Format)
{
	entity this = M_ARGV(0, entity);
	string s = M_ARGV(1, string);
	if (s == WP_Buff.netname || s == RADARICON_Buff.netname)
	{
		Buff b = REGISTRY_GET(StatusEffects, this.wp_extra);
		M_ARGV(2, vector) = b.m_color;
		M_ARGV(3, string) = b.m_name;
		M_ARGV(4, string) = b.m_icon;
		return true;
	}
}
