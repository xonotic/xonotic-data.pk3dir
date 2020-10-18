#include "buffs.qh"

string BUFF_NAME(int i)
{
    Buff b = REGISTRY_GET(Buffs, i);
    return strcat(rgb_to_hexcolor(b.m_color), b.m_name);
}

entity buff_FirstFromFlags(int _buffs)
{
    if (flags)
    {
        FOREACH(Buffs, it.m_itemid & _buffs, { return it; });
    }
    return BUFF_Null;
}
