#include "shield.qh"

#ifdef SVQC
METHOD(ShieldStatusEffect, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(removal_type == STATUSEFFECT_REMOVE_TIMEOUT && wasactive && IS_PLAYER(actor))
    {
        //Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERDOWN_SHIELD, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERDOWN_SHIELD);
    }
    if(wasactive)
        stopsound(actor, CH_TRIGGER_SINGLE); // get rid of the pickup sound
    actor.effects &= ~(EF_RED | EF_ADDITIVE | EF_FULLBRIGHT);
    SUPER(ShieldStatusEffect).m_remove(this, actor, removal_type);
}
METHOD(ShieldStatusEffect, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive && IS_PLAYER(actor))
    {
        if(!g_cts)
            Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_SHIELD, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERUP_SHIELD);
    }
    SUPER(ShieldStatusEffect).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(ShieldStatusEffect, m_tick, void(StatusEffect this, entity actor))
{
    play_countdown(actor, StatusEffects_gettime(this, actor), SND_POWEROFF);
    actor.effects |= (EF_RED | EF_ADDITIVE | EF_FULLBRIGHT);
    SUPER(ShieldStatusEffect).m_tick(this, actor);
}
#endif // SVQC
#ifdef CSQC
METHOD(ShieldStatusEffect, m_active, bool(StatusEffect this, entity actor))
{
    if(autocvar__hud_configure)
        return true;
    return SUPER(ShieldStatusEffect).m_active(this, actor);
}
METHOD(ShieldStatusEffect, m_tick, void(StatusEffect this, entity actor))
{
    if(this.m_hidden)
        return;

    float currentTime = (autocvar__hud_configure) ? 27 : bound(0, actor.statuseffect_time[this.m_id] - time, 99);
    addPowerupItem(this.m_name, this.m_icon, autocvar_hud_progressbar_shield_color, currentTime, this.m_lifetime, (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT));
}
#endif // CSQC
#ifdef MENUQC
METHOD(ShieldItem, describe, string(ShieldItem this))
{
	TC(ShieldItem, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s powerup greatly decreases the damage you take until the powerup expires, having a compounding effect with armor. "
	      "It also makes you more resistant to knockback."), COLORED_NAME(this));
	PAR(_("Since it is a powerup, it will drop if you die while holding it.")); // shared message
	return PAGE_TEXT;
}
#endif // MENUQC
