#include "../../common/items/item.qh"

#define WITH(it) this.m_##it;
#define CONFIGURE(...) MAP(WITH, __VA_ARGS__)

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
    this.m_name                 =   "Extralife";
    this.m_icon                 =   "item_mega_health";
#ifdef SVQC
    this.m_itemid               =   IT_NAILS;
    this.m_botvalue             =   BOT_PICKUP_RATING_HIGH;
#endif
}

#undef WITH
#undef CONFIGURE
