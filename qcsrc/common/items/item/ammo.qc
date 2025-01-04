#include "ammo.qh"

#ifdef MENUQC
#include <common/weapons/all.qh>

METHOD(Ammo, describe, string(Ammo this))
{
    TC(Ammo, this);
    entity ammo = GetAmmoResource(this);
    string s = sprintf(_("The %s ammo type is used by the:"), COLORED_NAME(this));
    FOREACH(Weapons, it.ammo_type == ammo, {
        s = strcat(s, "\n", COLORED_NAME(it));
    });
    return s;
}
#endif
