#include "powerup.qh"

#ifndef SVQC
.int m_itemid;
#endif

#ifndef MENUQC
MODEL(Strength_ITEM, Item_Model("g_strength.md3"));
SOUND(Strength, "misc/powerup");
#endif

REGISTER_ITEM(Strength, Powerup) {
#ifndef MENUQC
    this.m_model            =   MDL_Strength_ITEM;
    this.m_sound            =   SND_Strength;
#endif
    this.m_name             =   "Strength Powerup";
    this.m_icon             =   "strength";
    this.m_color            =   '0 0 1';
    this.m_waypoint         =   _("Strength");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_STRENGTH;
}

#ifndef MENUQC
MODEL(Shield_ITEM, Item_Model("g_invincible.md3"));
SOUND(Shield, "misc/powerup_shield");
#endif

REGISTER_ITEM(Shield, Powerup) {
#ifndef MENUQC
    this.m_model            =   MDL_Shield_ITEM;
    this.m_sound            =   SND_Shield;
#endif
    this.m_name             =   "Shield";
    this.m_icon             =   "shield";
    this.m_color            =   '1 0 1';
    this.m_waypoint         =   _("Shield");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_INVINCIBLE;
}
