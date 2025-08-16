#include "strength.qh"

#ifdef SVQC
METHOD(StrengthStatusEffect, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(removal_type == STATUSEFFECT_REMOVE_TIMEOUT && wasactive && IS_PLAYER(actor))
    {
        //Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERDOWN_STRENGTH, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERDOWN_STRENGTH);
    }
    if(wasactive)
        stopsound(actor, CH_TRIGGER_SINGLE); // get rid of the pickup sound
    actor.effects &= ~(EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT);
    SUPER(StrengthStatusEffect).m_remove(this, actor, removal_type);
}
METHOD(StrengthStatusEffect, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive && IS_PLAYER(actor))
    {
        if(!g_cts)
            Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_STRENGTH, actor.netname);
        Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_POWERUP_STRENGTH);
    }
    SUPER(StrengthStatusEffect).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(StrengthStatusEffect, m_tick, void(StatusEffect this, entity actor))
{
    play_countdown(actor, StatusEffects_gettime(this, actor), SND_POWEROFF);
    actor.effects |= (EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT);
    SUPER(StrengthStatusEffect).m_tick(this, actor);
}
#endif // SVQC
#ifdef CSQC
METHOD(StrengthStatusEffect, m_active, bool(StatusEffect this, entity actor))
{
    if(autocvar__hud_configure)
        return true;
    return SUPER(StrengthStatusEffect).m_active(this, actor);
}
METHOD(StrengthStatusEffect, m_tick, void(StatusEffect this, entity actor))
{
    if(this.m_hidden)
        return;

    float currentTime = (autocvar__hud_configure) ? 15 : bound(0, actor.statuseffect_time[this.m_id] - time, 99);
    addPowerupItem(this.m_name, this.m_icon, autocvar_hud_progressbar_strength_color, currentTime, this.m_lifetime, (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT));
}
#endif // CSQC
#ifdef MENUQC
METHOD(StrengthItem, describe, string(StrengthItem this))
{
    TC(StrengthItem, this);
    return sprintf(_("The %s powerup greatly increases the damage you deal, until the powerup expires. "
        "It also increases the knockback that your attacks deal.\n\n"
        "The damage and knockback you deal to yourself also increases but by a smaller amount.\n\n"
        "The %s is one of the most sought after items on a map due to its ability to allow you to easily dominate a map, so it's often highly contested when it spawns in.\n\n%s"),
        COLORED_NAME(this), COLORED_NAME(this),
        _("Since it is a powerup, it will drop if you die while holding it.") // shared message
    );
}
#endif // MENUQC
