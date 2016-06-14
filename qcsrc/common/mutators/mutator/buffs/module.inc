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

entity buff_FirstFromFlags(int _buffs)
{
    if (flags)
    {
        FOREACH(Buffs, it.m_itemid & _buffs, LAMBDA(return it));
    }
    return BUFF_Null;
}

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
    entity this = M_ARGV(0, entity);
    string s = M_ARGV(1, string);
    if (s == WP_Buff.netname || s == RADARICON_Buff.netname)
    {
        Buff b = Buffs_from(this.wp_extra);
        M_ARGV(2, vector) = b.m_color;
        M_ARGV(3, string) = b.m_prettyName;
        return true;
    }
}

#endif
#endif
