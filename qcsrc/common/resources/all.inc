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

REGISTER_RESOURCE(SHELLS, NEW(AmmoResource)) {
	this.netname = "shells";
#ifdef GAMEQC
	this.m_field = ammo_shells;
#endif
}
REGISTER_RESOURCE(BULLETS, NEW(AmmoResource)) {
	this.netname = "bullets";
#ifdef GAMEQC
	this.m_field = ammo_nails;
#endif
}
REGISTER_RESOURCE(ROCKETS, NEW(AmmoResource)) {
	this.netname = "rockets";
#ifdef GAMEQC
	this.m_field = ammo_rockets;
#endif
}
REGISTER_RESOURCE(CELLS, NEW(AmmoResource)) {
	this.netname = "cells";
#ifdef GAMEQC
	this.m_field = ammo_cells;
#endif
}
REGISTER_RESOURCE(PLASMA, NEW(AmmoResource)) {
	this.netname = "plasma";
#ifdef GAMEQC
	this.m_field = ammo_plasma;
#endif
#ifdef CSQC
	this.m_hidden = true; // WIP ammo type
#endif
}
REGISTER_RESOURCE(FUEL, NEW(AmmoResource)) {
	this.netname = "fuel";
#ifdef GAMEQC
	this.m_field = ammo_fuel;
#endif
#ifdef CSQC
	this.m_hidden = true; // displayed in a separate panel
#endif
}
