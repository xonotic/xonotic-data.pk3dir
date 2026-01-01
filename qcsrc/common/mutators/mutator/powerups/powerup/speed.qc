#include "speed.qh"

#ifdef SVQC
METHOD(SpeedStatusEffect, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(removal_type == STATUSEFFECT_REMOVE_TIMEOUT && wasactive && IS_PLAYER(actor))
    {
        //Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERDOWN_SPEED, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERDOWN_SPEED);
    }
    if(wasactive)
        stopsound(actor, CH_TRIGGER_SINGLE); // get rid of the pickup sound
    SUPER(SpeedStatusEffect).m_remove(this, actor, removal_type);
}
METHOD(SpeedStatusEffect, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive && IS_PLAYER(actor))
    {
        if(!g_cts)
            Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_SPEED, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERUP_SPEED);
    }
    SUPER(SpeedStatusEffect).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(SpeedStatusEffect, m_tick, void(StatusEffect this, entity actor))
{
    play_countdown(actor, StatusEffects_gettime(this, actor), SND_POWEROFF);
    SUPER(SpeedStatusEffect).m_tick(this, actor);
}
#endif // SVQC
#ifdef MENUQC
METHOD(SpeedItem, describe, string(SpeedItem this))
{
	TC(SpeedItem, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s powerup increases your movement speed, attack speed, and health regeneration speed while the powerup is active. "
	      "However, it also makes you a bit more vulnerable to incoming attacks."), COLORED_NAME(this));
	PAR(_("Since it is a powerup, it will drop if you die while holding it.")); // shared message
	return PAGE_TEXT;
}
#endif // MENUQC
