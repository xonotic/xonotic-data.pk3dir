#include "buffs.qh"

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
