#include "invisibility.qh"

#ifdef SVQC
METHOD(InvisibilityStatusEffect, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(removal_type == STATUSEFFECT_REMOVE_TIMEOUT && wasactive && IS_PLAYER(actor))
    {
        //Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERDOWN_INVISIBILITY, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERDOWN_INVISIBILITY);
    }
    if(wasactive)
        stopsound(actor, CH_TRIGGER_SINGLE); // get rid of the pickup sound
    if(!actor.vehicle)
    {
        actor.alpha = default_player_alpha;
        if(actor.exteriorweaponentity)
            actor.exteriorweaponentity.alpha = default_weapon_alpha;
    }
    SUPER(InvisibilityStatusEffect).m_remove(this, actor, removal_type);
}
METHOD(InvisibilityStatusEffect, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive && IS_PLAYER(actor))
    {
        if(!g_cts)
            Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_INVISIBILITY, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERUP_INVISIBILITY);
    }
    SUPER(InvisibilityStatusEffect).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(InvisibilityStatusEffect, m_tick, void(StatusEffect this, entity actor))
{
    play_countdown(actor, StatusEffects_gettime(this, actor), SND_POWEROFF);
    if(!actor.vehicle)
    {
        actor.alpha = autocvar_g_balance_powerup_invisibility_alpha;
        if(actor.exteriorweaponentity)
            actor.exteriorweaponentity.alpha = autocvar_g_balance_powerup_invisibility_alpha;
    }
    SUPER(InvisibilityStatusEffect).m_tick(this, actor);
}
#endif
