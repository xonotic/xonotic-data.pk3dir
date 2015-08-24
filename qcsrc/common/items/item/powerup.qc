#include "powerup.qh"
#include "../../../server/t_items.qh"

#ifndef SVQC
.int m_itemid;
#endif
REGISTER_ITEM(Strength, Powerup) {
    this.m_model    =   "models/items/g_strength.md3";
    this.m_sound    =   "misc/powerup.wav";
    this.m_name     =   "Strength Powerup";
    this.m_icon     =   "strength";
    this.m_itemid   =   IT_STRENGTH;
}
REGISTER_ITEM(Shield, Powerup) {
    this.m_model    =   "models/items/g_invincible.md3";
    this.m_sound    =   "misc/powerup_shield.wav";
    this.m_name     =   "Shield";
    this.m_icon     =   "shield";
    this.m_itemid   =   IT_INVINCIBLE;
}
