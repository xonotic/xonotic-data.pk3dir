#include "all.qc"
#ifdef SVQC
#include "buffs.qc"
#endif

#ifdef IMPLEMENTATION

string BUFF_NAME(int i)
{
    Buff b = Buffs_from(i);
    return sprintf("%s%s", rgb_to_hexcolor(b.m_color), b.m_prettyName);
}

#ifndef MENUQC
REGISTER_MUTATOR(buffs_flight, true);
MUTATOR_HOOKFUNCTION(buffs_flight, IsFlying)
{
    noref entity e = MUTATOR_ARGV(0, entity);
	return BUFFS_STAT(e) & BUFF_FLIGHT.m_itemid;
}
#endif

#ifdef CSQC
REGISTER_MUTATOR(cl_buffs, true);
MUTATOR_HOOKFUNCTION(cl_buffs, HUD_Powerups_add)
{
    int allBuffs = STAT(BUFFS);
    FOREACH(Buffs, it.m_itemid & allBuffs, LAMBDA(
		addPowerupItem(it.m_prettyName, strcat("buff_", it.m_name), it.m_color, bound(0, STAT(BUFF_TIME) - time, 99), 60);
	));
}
MUTATOR_HOOKFUNCTION(cl_buffs, WP_Format)
{
    entity this = MUTATOR_ARGV(0, entity);
    string s = MUTATOR_ARGV(0, string);
    if (s == WP_Buff.netname || s == RADARICON_Buff.netname)
    {
        Buff b = Buffs_from(this.wp_extra);
        MUTATOR_ARGV(0, vector) = b.m_color;
        MUTATOR_ARGV(0, string) = b.m_prettyName;
        return true;
    }
}

#endif
#endif
