#include "burning.qh"

#ifdef SVQC
METHOD(Burning, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    actor.effects &= ~EF_FLAME;
    SUPER(Burning).m_remove(this, actor, removal_type);
}
METHOD(Burning, m_persistent, bool(StatusEffect this, entity actor))
{
    return (autocvar_g_balance_contents_playerdamage_lava_burn && actor.waterlevel && actor.watertype == CONTENT_LAVA);
}
METHOD(Burning, m_tick, void(StatusEffect this, entity actor))
{
    if(STAT(FROZEN, actor) || (actor.waterlevel && actor.watertype != CONTENT_LAVA))
    {
        this.m_remove(this, actor, STATUSEFFECT_REMOVE_NORMAL);
        return;
    }
    Fire_ApplyDamage(actor);
    actor.effects |= EF_FLAME;
    SUPER(Burning).m_tick(this, actor);
}
#endif
