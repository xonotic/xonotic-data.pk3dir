#include "frozen.qh"

#ifdef SVQC
.entity frozen_ice;

void Frozen_ice_remove(entity this)
{
    if(this.frozen_ice)
        delete(this.frozen_ice);
    this.frozen_ice = NULL;
}

void Frozen_ice_think(entity this)
{
    if(this.owner.frozen_ice != this || wasfreed(this.owner))
    {
        delete(this);
        return;
    }
    vector ice_org = this.owner.origin - '0 0 16';
    if(this.origin != ice_org)
        setorigin(this, ice_org);
    this.nextthink = time;
}

void Frozen_ice_create(entity this)
{
    entity ice = new(ice);
    // set_movetype(ice, MOVETYPE_FOLLOW) would rotate the ice model with the player
    ice.owner = this;
    ice.scale = this.scale;
    setthink(ice, Frozen_ice_think);
    ice.nextthink = time;
    ice.frame = floor(random() * 21); // ice model has 20 different looking frames
    // TODO: unique (less pronounced) model
    setmodel(ice, MDL_ICE);
    ice.alpha = 0.5;

    this.frozen_ice = ice;

    Frozen_ice_think(ice);
}

METHOD(Frozen, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive)
    {
        Frozen_ice_create(actor);
        RemoveGrapplingHooks(actor);
        // TODO: should hooks targeting this entity also be removed?
        // TODO: special items as well?
    }
    SUPER(Frozen).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(Frozen, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
    Frozen_ice_remove(actor);
    SUPER(Frozen).m_remove(this, actor, removal_type);
}
METHOD(Frozen, m_tick, void(StatusEffect this, entity actor))
{
    if(STAT(FROZEN, actor) || (actor.waterlevel && actor.watertype == CONTENT_LAVA))
    {
        this.m_remove(this, actor, STATUSEFFECT_REMOVE_NORMAL);
        return;
    }
    SUPER(Frozen).m_tick(this, actor);
}
#endif
#ifdef CSQC
METHOD(Frozen, m_tick, void(StatusEffect this, entity actor))
{
    vector col = '0.25 0.90 1';
    float alpha_fade = 0.3;
    drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), col, autocvar_hud_colorflash_alpha * alpha_fade, DRAWFLAG_ADDITIVE);
}
#endif
