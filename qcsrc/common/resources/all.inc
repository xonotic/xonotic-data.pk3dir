REGISTER_RESOURCE(HEALTH, NEW(Resource)) {
	this.netname = "health";
#ifdef GAMEQC
	this.m_field = health;
#endif
}
REGISTER_RESOURCE(ARMOR, NEW(Resource)) {
	this.netname = "armor";
#ifdef GAMEQC
	this.m_field = armorvalue;
#endif
}

CLASS(AmmoResource, Resource)
#ifdef CSQC
	ATTRIB(AmmoResource, m_hidden, bool, false);
#endif
ENDCLASS(AmmoResource)

// NOTE: ammo resource registration order should match ammo (item) registration order
// see REGISTER_ITEM calls order
// ALSO make sure m_name and m_icon fields match ammo item registries

REGISTER_RESOURCE(SHELLS, NEW(AmmoResource)) {
	this.netname = "shells";
#ifdef GAMEQC
	this.m_field = ammo_shells;
#endif
	this.m_name = _("Shells");
	this.m_icon = "ammo_shells";
}
REGISTER_RESOURCE(BULLETS, NEW(AmmoResource)) {
	this.netname = "bullets";
#ifdef GAMEQC
	this.m_field = ammo_nails;
#endif
	this.m_name = _("Bullets");
	this.m_icon = "ammo_bullets";
}
REGISTER_RESOURCE(ROCKETS, NEW(AmmoResource)) {
	this.netname = "rockets";
#ifdef GAMEQC
	this.m_field = ammo_rockets;
#endif
	this.m_name = _("Rockets");
	this.m_icon = "ammo_rockets";
}
REGISTER_RESOURCE(CELLS, NEW(AmmoResource)) {
	this.netname = "cells";
#ifdef GAMEQC
	this.m_field = ammo_cells;
#endif
	this.m_name = _("Cells");
	this.m_icon = "ammo_cells";
}
REGISTER_RESOURCE(PLASMA, NEW(AmmoResource)) {
	this.netname = "plasma";
#ifdef GAMEQC
	this.m_field = ammo_plasma;
#endif
	this.m_name = _("Plasma");
	this.m_icon = "ammo_plasma";
#ifdef CSQC
	this.m_hidden = true; // WIP ammo type
#endif
}
REGISTER_RESOURCE(FUEL, NEW(AmmoResource)) {
	this.netname = "fuel";
#ifdef GAMEQC
	this.m_field = ammo_fuel;
#endif
	this.m_name = _("Fuel");
	this.m_icon = "ammo_fuel";
#ifdef CSQC
	this.m_hidden = true; // displayed in a separate panel
#endif
}
