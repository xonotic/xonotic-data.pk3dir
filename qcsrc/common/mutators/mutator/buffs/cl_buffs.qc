#include "cl_buffs.qh"

REGISTER_MUTATOR(cl_buffs, true);
MUTATOR_HOOKFUNCTION(cl_buffs, HUD_Powerups_add)
{
	int allBuffs = STAT(BUFFS);
	if (allBuffs)
		FOREACH(Buffs, it.m_itemid & allBuffs, {
			addPowerupItem(it.m_name, strcat("buff_", it.netname), it.m_color, bound(0, STAT(BUFF_TIME) - time, 99), 60);
		});
}
MUTATOR_HOOKFUNCTION(cl_buffs, WP_Format)
{
    entity this = M_ARGV(0, entity);
    string s = M_ARGV(1, string);
    if (s == WP_Buff.netname || s == RADARICON_Buff.netname)
    {
        Buff b = Buffs_from(this.wp_extra);
        M_ARGV(2, vector) = b.m_color;
        M_ARGV(3, string) = b.m_name;
        M_ARGV(4, string) = strcat("buff_", b.netname);
        return true;
    }
}
