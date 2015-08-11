#include "powerup.qh"
#include "../../../server/t_items.qh"

REGISTER_ITEM(Strength, Powerup) {
    this.m_model    =   "models/items/g_strength.md3";
    this.m_sound    =   "misc/powerup.wav";
    this.m_name     =   "Strength Powerup";
#ifdef SVQC
    this.m_itemid   =   IT_STRENGTH;
#endif
}
REGISTER_ITEM(Shield, Powerup) {
    this.m_model    =   "models/items/g_invincible.md3";
    this.m_sound    =   "misc/powerup_shield.wav";
    this.m_name     =   "Shield";
#ifdef SVQC
    this.m_itemid   =   IT_INVINCIBLE;
#endif
}
