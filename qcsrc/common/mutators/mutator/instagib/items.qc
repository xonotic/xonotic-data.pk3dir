#include "../../../items/all.qh"
#include "../../../items/item/ammo.qh"
#include "../../../items/item/powerup.qh"

float instagib_respawntime_ammo = 45;
float instagib_respawntimejitter_ammo = 0;
GETTER(float, instagib_respawntime_ammo)
GETTER(float, instagib_respawntimejitter_ammo)

#ifndef MENUQC
MODEL(VaporizerCells_ITEM, Item_Model("a_cells.md3"));
SOUND(VaporizerCells, "misc/itempickup");
#endif

REGISTER_ITEM(VaporizerCells, Ammo) {
#ifndef MENUQC
    this.m_model                =   MDL_VaporizerCells_ITEM;
    this.m_sound                =   SND_VaporizerCells;
#endif
    this.m_name                 =   "Vaporizer Ammo";
    this.m_icon                 =   "ammo_supercells";
#ifdef SVQC
    this.m_botvalue             =   100;
    this.m_itemid               =   IT_CELLS;
    this.m_respawntime          =   GET(instagib_respawntime_ammo);
    this.m_respawntimejitter    =   GET(instagib_respawntimejitter_ammo);
#endif
}

#ifndef MENUQC
MODEL(ExtraLife_ITEM, Item_Model("g_h100.md3"));
SOUND(ExtraLife, "misc/megahealth");
#endif

REGISTER_ITEM(ExtraLife, Powerup) {
#ifndef MENUQC
    this.m_model                =   MDL_ExtraLife_ITEM;
    this.m_sound                =   SND_ExtraLife;
#endif
    this.m_name                 =   "Extra life";
    this.m_icon                 =   "item_mega_health";
    this.m_color                =   '1 0 0';
    this.m_waypoint             =   _("Extra life");
    this.m_waypointblink        =   2;
    this.m_itemid               =   IT_NAILS;
}

#ifndef MENUQC
MODEL(Invisibility_ITEM, Item_Model("g_strength.md3"));
SOUND(Invisibility, "misc/powerup");
#endif

REGISTER_ITEM(Invisibility, Powerup) {
#ifndef MENUQC
    this.m_model            =   MDL_Invisibility_ITEM;
    this.m_sound            =   SND_Invisibility;
#endif
    this.m_name             =   "Invisibility";
    this.m_icon             =   "strength";
    this.m_color            =   '0 0 1';
    this.m_waypoint         =   _("Invisibility");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_STRENGTH;
}

#ifndef MENUQC
MODEL(Speed_ITEM, Item_Model("g_invincible.md3"));
SOUND(Speed, "misc/powerup_shield");
#endif

REGISTER_ITEM(Speed, Powerup) {
#ifndef MENUQC
    this.m_model            =   MDL_Speed_ITEM;
    this.m_sound            =   SND_Speed;
#endif
    this.m_name             =   "Speed";
    this.m_icon             =   "shield";
    this.m_color            =   '1 0 1';
    this.m_waypoint         =   _("Speed");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_INVINCIBLE;
}
