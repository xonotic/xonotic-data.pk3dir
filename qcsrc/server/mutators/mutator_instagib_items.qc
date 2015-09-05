#include "../../common/items/item.qh"

float instagib_respawntime_ammo = 45;
float instagib_respawntimejitter_ammo = 0;
GETTER(float, instagib_respawntime_ammo)
GETTER(float, instagib_respawntimejitter_ammo)

REGISTER_ITEM(VaporizerCells, Ammo) {
    this.m_model                =   "a_cells.md3";
    this.m_sound                =   "misc/itempickup.wav";
    this.m_name                 =   "Vaporizer Ammo";
    this.m_icon                 =   "ammo_supercells";
#ifdef SVQC
    this.m_botvalue             =   100;
    this.m_itemid               =   IT_CELLS;
    this.m_respawntime          =   GET(instagib_respawntime_ammo);
    this.m_respawntimejitter    =   GET(instagib_respawntimejitter_ammo);
#endif
}

REGISTER_ITEM(ExtraLife, Powerup) {
    this.m_model                =   "g_h100.md3";
    this.m_sound                =   "misc/megahealth.wav";
    this.m_name                 =   "Extra life";
    this.m_icon                 =   "item_mega_health";
    this.m_color                =   '1 0 0';
    this.m_waypoint             =   _("Extra life");
    this.m_waypointblink        =   2;
    this.m_itemid               =   IT_NAILS;
}

REGISTER_ITEM(Invisibility, Powerup) {
    this.m_model            =   "g_strength.md3";
    this.m_sound            =   "misc/powerup.wav";
    this.m_name             =   "Invisibility";
    this.m_icon             =   "strength";
    this.m_color            =   '0 0 1';
    this.m_waypoint         =   _("Invisibility");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_STRENGTH;
}

REGISTER_ITEM(Speed, Powerup) {
    this.m_model            =   "g_invincible.md3";
    this.m_sound            =   "misc/powerup_shield.wav";
    this.m_name             =   "Speed";
    this.m_icon             =   "shield";
    this.m_color            =   '1 0 1';
    this.m_waypoint         =   _("Speed");
    this.m_waypointblink    =   2;
    this.m_itemid           =   IT_INVINCIBLE;
}
