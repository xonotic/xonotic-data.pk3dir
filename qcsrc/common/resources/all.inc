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
	ATTRIB(AmmoResource, m_color, vector, '1 1 1');
ENDCLASS(AmmoResource)

// NOTE: ammo resource registration order should match ammo (item) registration order
// see REGISTER_ITEM calls order
// ALSO make sure m_name and m_icon fields match ammo item registries

REGISTER_RESOURCE(SHELLS, NEW(AmmoResource)) {
	this.netname = "shells";
#ifdef GAMEQC
	this.m_field = ammo_shells;
#endif
	this.m_name  = _("Shells");
	this.m_icon  = "ammo_shells";
	this.m_color = '0.604 0.647 0.671';
}
REGISTER_RESOURCE(BULLETS, NEW(AmmoResource)) {
	this.netname = "bullets";
#ifdef GAMEQC
	this.m_field = ammo_nails;
#endif
	this.m_name  = _("Bullets");
	this.m_icon  = "ammo_bullets";
	this.m_color = '0.678 0.941 0.522';
}
REGISTER_RESOURCE(ROCKETS, NEW(AmmoResource)) {
	this.netname = "rockets";
#ifdef GAMEQC
	this.m_field = ammo_rockets;
#endif
	this.m_name  = _("Rockets");
	this.m_icon  = "ammo_rockets";
	this.m_color = '0.918 0.686 0.525';
}
REGISTER_RESOURCE(CELLS, NEW(AmmoResource)) {
	this.netname = "cells";
#ifdef GAMEQC
	this.m_field = ammo_cells;
#endif
	this.m_name  = _("Cells");
	this.m_icon  = "ammo_cells";
	this.m_color = '0.545 0.882 0.969';
}
REGISTER_RESOURCE(FUEL, NEW(AmmoResource)) {
	this.netname  = "fuel";
#ifdef GAMEQC
	this.m_field  = ammo_fuel;
#endif
	this.m_name   = _("Fuel");
	this.m_icon   = "ammo_fuel";
	this.m_color  = '0.984 0.878 0.506';
#ifdef CSQC
	this.m_hidden = true; // displayed in a separate panel
#endif
}
