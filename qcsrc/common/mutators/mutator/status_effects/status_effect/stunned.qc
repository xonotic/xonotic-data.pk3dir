#include "stunned.qh"

#ifdef SVQC
METHOD(Stunned, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    actor.effects &= ~EF_SHOCK;
    SUPER(Stunned).m_remove(this, actor, removal_type);
}
#if 0
// TODO: some infinite source of stunning? e.g. some electric current
METHOD(Stunned, m_persistent, bool(StatusEffect this, entity actor))
{
    return true;
}
#endif
METHOD(Stunned, m_tick, void(StatusEffect this, entity actor))
{
    if(STAT(FROZEN, actor))
    {
        this.m_remove(this, actor, STATUSEFFECT_REMOVE_NORMAL);
        return;
    }
    //Shock_ApplyDamage(actor);
    actor.effects |= EF_SHOCK;
    SUPER(Stunned).m_tick(this, actor);
}
#endif
