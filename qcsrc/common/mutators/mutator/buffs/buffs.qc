#include "buffs.qh"

string BUFF_NAME(int i)
{
    Buff b = REGISTRY_GET(StatusEffect, i);
    return strcat(rgb_to_hexcolor(b.m_color), b.m_name);
}

#ifdef GAMEQC
REPLICATE(cvar_cl_buffs_autoreplace, bool, "cl_buffs_autoreplace");
#endif
