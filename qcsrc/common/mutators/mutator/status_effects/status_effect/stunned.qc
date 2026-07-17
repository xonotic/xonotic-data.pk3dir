#include "stunned.qh"

#ifdef SVQC
METHOD(Stunned, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    actor.effects &= ~EF_SHOCK;
    SUPER(Stunned).m_remove(this, actor, removal_type);
}
METHOD(Stunned, m_tick, void(StatusEffect this, entity actor))
{
    SUPER(Stunned).m_tick(this, actor);
    if(!this.m_active(this, actor))
        return;
    if(STAT(FROZEN, actor))
    {
        this.m_remove(this, actor, STATUSEFFECT_REMOVE_NORMAL);
        return;
    }
    actor.effects |= EF_SHOCK;
}
#endif
