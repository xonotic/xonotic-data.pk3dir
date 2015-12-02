#include "ammo.qh"
#ifdef SVQC
    #include "../../../server/t_items.qh"
#endif

#ifndef MENUQC
MODEL(Bullets_ITEM, Item_Model("a_bullets.mdl"));
#endif

REGISTER_ITEM(Bullets, Ammo) {
#ifndef MENUQC
    this.m_model    =   MDL_Bullets_ITEM;
#endif
    this.m_name     =   "bullets";
    this.m_icon     =   "ammo_bullets";
#ifdef SVQC
    this.m_botvalue =   2000;
    this.m_itemid   =   IT_NAILS;
#endif
}

#ifndef MENUQC
MODEL(Cells_ITEM, Item_Model("a_cells.md3"));
#endif

REGISTER_ITEM(Cells, Ammo) {
#ifndef MENUQC
    this.m_model    =   MDL_Cells_ITEM;
#endif
    this.m_name     =   "cells";
    this.m_icon     =   "ammo_cells";
#ifdef SVQC
    this.m_botvalue =   2000;
    this.m_itemid   =   IT_CELLS;
#endif
}

#ifndef MENUQC
MODEL(Plasma_ITEM, Item_Model("a_cells.md3"));
#endif

REGISTER_ITEM(Plasma, Ammo) {
#ifndef MENUQC
    this.m_model    =   MDL_Plasma_ITEM;
#endif
    this.m_name     =   "plasma";
    this.m_icon     =   "ammo_plasma";
#ifdef SVQC
    this.m_botvalue =   2000;
    this.m_itemid   =   IT_PLASMA;
#endif
}

#ifndef MENUQC
MODEL(Rockets_ITEM, Item_Model("a_rockets.md3"));
#endif

REGISTER_ITEM(Rockets, Ammo) {
#ifndef MENUQC
    this.m_model    =   MDL_Rockets_ITEM;
#endif
    this.m_name     =   "rockets";
    this.m_icon     =   "ammo_rockets";
#ifdef SVQC
    this.m_botvalue =   3000;
    this.m_itemid   =   IT_ROCKETS;
#endif
}

#ifndef MENUQC
MODEL(Shells_ITEM, Item_Model("a_shells.md3"));
#endif

REGISTER_ITEM(Shells, Ammo) {
#ifndef MENUQC
    this.m_model    =   MDL_Shells_ITEM;
#endif
    this.m_name     =   "shells";
    this.m_icon     =   "ammo_shells";
#ifdef SVQC
    this.m_botvalue =   500;
    this.m_itemid   =   IT_SHELLS;
#endif
}
