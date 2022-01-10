#include "superweapons.qh"

#ifdef SVQC
METHOD(Superweapons, m_persistent, bool(StatusEffects this, entity actor))
{
    return (actor.items & IT_UNLIMITED_SUPERWEAPONS);
}
#endif

#ifdef CSQC
METHOD(Superweapons, m_active, bool(StatusEffects this, entity actor))
{
    if(autocvar__hud_configure)
        return true;
    return SUPER(Superweapons).m_active(this, actor);
}
METHOD(Superweapons, m_tick, void(StatusEffects this, entity actor))
{
    if(this.m_hidden)
        return;

    int allItems = STAT(ITEMS);

    // Prevent stuff to show up on mismatch that will be fixed next frame
    if(!(allItems & IT_SUPERWEAPON) && !autocvar__hud_configure)
        return;

    if(allItems & IT_UNLIMITED_SUPERWEAPONS)
        return;

    float currentTime = (autocvar__hud_configure) ? 13 : bound(0, actor.statuseffect_time[this.m_id] - time, 99);
    addPowerupItem(this.m_name, this.m_icon, autocvar_hud_progressbar_superweapons_color, currentTime, this.m_lifetime, (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT));
}
#endif
