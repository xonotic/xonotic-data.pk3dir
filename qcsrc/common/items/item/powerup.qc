#include "powerup.qh"
#include "../../../server/t_items.qh"

#ifndef SVQC
.int m_itemid;
#endif

#ifndef MENUQC
MODEL(Strength_ITEM, Item_Model("g_strength.md3"));
#endif

REGISTER_ITEM(Strength, Powerup) {
#ifndef MENUQC
    this.m_model            =   MDL_Strength_ITEM;
#endif
    this.m_sound            =   "misc/powerup.wav";
    this.m_name             =   "Strength Powerup";
    this.m_icon             =   "strength";
    this.m_color            =   '0 0 1';
    this.m_waypoint         =   _("Strength");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_STRENGTH;
}

#ifndef MENUQC
MODEL(Shield_ITEM, Item_Model("g_invincible.md3"));
#endif

REGISTER_ITEM(Shield, Powerup) {
#ifndef MENUQC
    this.m_model            =   MDL_Shield_ITEM;
#endif
    this.m_sound            =   "misc/powerup_shield.wav";
    this.m_name             =   "Shield";
    this.m_icon             =   "shield";
    this.m_color            =   '1 0 1';
    this.m_waypoint         =   _("Shield");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_INVINCIBLE;
}
