#include "burning.qh"

#ifdef SVQC
METHOD(SpawnShield, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    actor.effects &= ~(EF_ADDITIVE | EF_FULLBRIGHT);
    SUPER(SpawnShield).m_remove(this, actor, removal_type);
}
METHOD(SpawnShield, m_tick, void(StatusEffect this, entity actor))
{
    SUPER(SpawnShield).m_tick(this, actor);
    if(!this.m_active(this, actor))
        return;
    if(time >= game_starttime)
        actor.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
}
#endif
