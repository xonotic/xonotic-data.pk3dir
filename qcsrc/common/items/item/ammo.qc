#include "ammo.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

REGISTER_ITEM(Bullets, Ammo) {
    this.m_model    =   "a_bullets.mdl";
    this.m_name     =   "bullets";
    this.m_icon     =   "ammo_bullets";
#ifdef SVQC
    this.m_botvalue =   2000;
    this.m_itemid   =   IT_NAILS;
#endif
}
REGISTER_ITEM(Cells, Ammo) {
    this.m_model    =   "a_cells.md3";
    this.m_name     =   "cells";
    this.m_icon     =   "ammo_cells";
#ifdef SVQC
    this.m_botvalue =   2000;
    this.m_itemid   =   IT_CELLS;
#endif
}
REGISTER_ITEM(Plasma, Ammo) {
    this.m_model    =   "a_cells.md3";
    this.m_name     =   "plasma";
    this.m_icon     =   "ammo_plasma";
#ifdef SVQC
    this.m_botvalue =   2000;
    this.m_itemid   =   IT_PLASMA;
#endif
}
REGISTER_ITEM(Rockets, Ammo) {
    this.m_model    =   "a_rockets.md3";
    this.m_name     =   "rockets";
    this.m_icon     =   "ammo_rockets";
#ifdef SVQC
    this.m_botvalue =   3000;
    this.m_itemid   =   IT_ROCKETS;
#endif
}
REGISTER_ITEM(Shells, Ammo) {
    this.m_model    =   "a_shells.md3";
    this.m_name     =   "shells";
    this.m_icon     =   "ammo_shells";
#ifdef SVQC
    this.m_botvalue =   500;
    this.m_itemid   =   IT_SHELLS;
#endif
}
