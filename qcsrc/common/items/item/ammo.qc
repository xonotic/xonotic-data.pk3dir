#include "ammo.qh"

#ifdef MENUQC
#include <common/colors.qh>
#include <common/weapons/all.qh>

string _Ammo_generate_description(entity ammo_type_ent, Resource ammo_res)
{
    string s = sprintf(_("The %s ammo type is used by the:"), COLORED_NAME(ammo_type_ent));
    FOREACH(Weapons, true, {
        if (it.ammo_type == ammo_res)
            s = strcat(s, "\n", COLORED_NAME(it));
    });
    return s;
}

METHOD(Shells, describe, string(Shells this))
{
    TC(Shells, this);
    return _Ammo_generate_description(this, RES_SHELLS);
}

METHOD(Bullets, describe, string(Bullets this))
{
    TC(Bullets, this);
    return _Ammo_generate_description(this, RES_BULLETS);
}

METHOD(Rockets, describe, string(Rockets this))
{
    TC(Rockets, this);
    return _Ammo_generate_description(this, RES_ROCKETS);
}

METHOD(Cells, describe, string(Cells this))
{
    TC(Cells, this);
    return _Ammo_generate_description(this, RES_CELLS);
}
#endif
