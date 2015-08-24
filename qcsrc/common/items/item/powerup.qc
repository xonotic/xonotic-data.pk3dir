#include "powerup.qh"
#include "../../../server/t_items.qh"

#ifndef SVQC
.int m_itemid;
#endif
REGISTER_ITEM(Strength, Powerup) {
    this.m_model            =   "g_strength.md3";
    this.m_sound            =   "misc/powerup.wav";
    this.m_name             =   "Strength Powerup";
    this.m_icon             =   "strength";
    this.m_color            =   '0 0 1';
    this.m_waypoint         =   _("Strength");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_STRENGTH;
}
REGISTER_ITEM(Shield, Powerup) {
    this.m_model            =   "g_invincible.md3";
    this.m_sound            =   "misc/powerup_shield.wav";
    this.m_name             =   "Shield";
    this.m_icon             =   "shield";
    this.m_color            =   '1 0 1';
    this.m_waypoint         =   _("Shield");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_INVINCIBLE;
}
