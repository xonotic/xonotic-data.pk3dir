#include "powerups.qh"

#ifdef CSQC
METHOD(Strength, m_active, bool(StatusEffects this, entity actor))
{
    if(autocvar__hud_configure)
        return true;
    return SUPER(Strength).m_active(this, actor);
}
METHOD(Strength, m_tick, void(StatusEffects this, entity actor))
{
    if(this.m_hidden)
        return;

    float currentTime = (autocvar__hud_configure) ? 15 : bound(0, actor.statuseffect_time[this.m_id] - time, 99);
    addPowerupItem(this.m_name, this.m_icon, autocvar_hud_progressbar_strength_color, currentTime, this.m_lifetime, (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT));
}

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

METHOD(Shield, m_active, bool(StatusEffects this, entity actor))
{
    if(autocvar__hud_configure)
        return true;
    return SUPER(Shield).m_active(this, actor);
}
METHOD(Shield, m_tick, void(StatusEffects this, entity actor))
{
    if(this.m_hidden)
        return;

    float currentTime = (autocvar__hud_configure) ? 27 : bound(0, actor.statuseffect_time[this.m_id] - time, 99);
    addPowerupItem(this.m_name, this.m_icon, autocvar_hud_progressbar_shield_color, currentTime, this.m_lifetime, (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT));
}
#endif
