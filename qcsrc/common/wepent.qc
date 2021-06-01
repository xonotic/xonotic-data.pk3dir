#include "wepent.qh"

#define WEPENT_SET_NORMAL(var, x) MACRO_BEGIN \
	var = x; \
MACRO_END

// #define PROP(public, fld, set, sv, cl)
#define WEPENT_NETPROPS(PROP) PROP(false, sv_entnum, WEPENT_SET_NORMAL, {}, {}) /* sentinel */ \
	PROP(false, m_switchweapon, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_switchweapon.m_id); }, \
	{ (viewmodels[this.m_wepent_slot]).switchweapon = REGISTRY_GET(Weapons, ReadByte()); }) \
    \
    PROP(false, m_switchingweapon, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_switchingweapon.m_id); }, \
	{ (viewmodels[this.m_wepent_slot]).switchingweapon = REGISTRY_GET(Weapons, ReadByte()); }) \
    \
    PROP(false, m_weapon, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_weapon.m_id); }, \
	{ (viewmodels[this.m_wepent_slot]).activeweapon = REGISTRY_GET(Weapons, ReadByte()); }) \
    \
    PROP(false, m_alpha, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, rint(bound(-1, 254 * this.m_alpha, 254) - -1)); }, \
	{ (viewmodels[this.m_wepent_slot]).m_alpha = (ReadByte() + -1) / 254; }) \
    \
    PROP(false, vortex_charge, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.vortex_charge * 255); }, \
	{ (viewmodels[this.m_wepent_slot]).vortex_charge = ReadByte() / 255; }) \
    \
    PROP(false, oknex_charge, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.oknex_charge * 16); }, \
	{ (viewmodels[this.m_wepent_slot]).oknex_charge = ReadByte() / 16; }) \
    \
    PROP(false, m_gunalign, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_gunalign); }, \
	{ (viewmodels[this.m_wepent_slot]).m_gunalign = ReadByte(); }) \
    \
    PROP(false, porto_v_angle_held, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.porto_v_angle_held); if(this.porto_v_angle_held) { \
		 WriteAngleVector2D(chan, this.owner.porto_v_angle); \
		} }, \
	{ (viewmodels[this.m_wepent_slot]).angles_held_status = ReadByte(); if((viewmodels[this.m_wepent_slot]).angles_held_status) { \
		(viewmodels[this.m_wepent_slot]).angles_held = ReadAngleVector2D(); } \
		else { (viewmodels[this.m_wepent_slot]).angles_held = '0 0 0'; } }) \
    \
    PROP(false, tuba_instrument, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.tuba_instrument); }, \
	{ (viewmodels[this.m_wepent_slot]).tuba_instrument = ReadByte(); }) \
    \
    PROP(false, hagar_load, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.hagar_load); }, \
	{ (viewmodels[this.m_wepent_slot]).hagar_load = ReadByte(); }) \
    \
    PROP(false, minelayer_mines, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.minelayer_mines); }, \
	{ (viewmodels[this.m_wepent_slot]).minelayer_mines = ReadByte(); }) \
    \
    PROP(false, arc_heat_percent, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.arc_heat_percent * 255); }, \
	{ (viewmodels[this.m_wepent_slot]).arc_heat_percent = ReadByte() / 255; }) \
    \
    PROP(false, vortex_chargepool_ammo, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.vortex_chargepool_ammo * 16); }, \
	{ (viewmodels[this.m_wepent_slot]).vortex_chargepool_ammo = ReadByte() / 16; }) \
    \
	PROP(false, oknex_chargepool_ammo, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.oknex_chargepool_ammo * 16); }, \
	{ (viewmodels[this.m_wepent_slot]).oknex_chargepool_ammo = ReadByte() / 16; }) \
    \
	PROP(false, clip_load, WEPENT_SET_NORMAL, \
	{ WriteShort(chan, this.clip_load); }, \
	{ (viewmodels[this.m_wepent_slot]).clip_load = ReadShort(); }) \
    \
    PROP(false, clip_size, WEPENT_SET_NORMAL, \
	{ WriteShort(chan, this.clip_size); }, \
	{ (viewmodels[this.m_wepent_slot]).clip_size = ReadShort(); }) \
    \
    PROP(false, skin, WEPENT_SET_NORMAL, \
	{ WriteShort(chan, this.skin); }, \
	{ (viewmodels[this.m_wepent_slot]).m_skin = ReadShort(); }) \
    \
	/**/

#ifdef SVQC

	int WEPENT_PUBLICMASK = 0;
	STATIC_INIT(WEPENT_PUBLICMASK)
	{
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (public) { \
				WEPENT_PUBLICMASK |= BIT(i); \
			} \
			i += 1; \
		}
		WEPENT_NETPROPS(X);
	#undef X
		if (i >= BITS(24 - 1)) LOG_FATAL("Exceeded WEPENT_NETPROPS limit");
	}

	bool _wepent_send(entity this, entity to, int sf, int chan)
	{
		sf |= this.m_forceupdate;
		this.m_forceupdate = 0;
		if (chan == MSG_ENTITY)
			WriteHeader(chan, ENT_CLIENT_WEPENT);
		else
			WriteHeader(chan, CLIENT_WEPENT);
		.entity weaponentity = this.owner.weaponentity_fld;
		WriteByte(chan, weaponslot(weaponentity));
		WriteInt24_t(chan, sf);
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (sf & BIT(i)) { \
				sv; \
			} \
			i += 1; \
		}
		WEPENT_NETPROPS(X);
	#undef X
		return true;
	}

	bool wepent_send(entity this, entity to, int sf)
	{
		return _wepent_send(this, to, sf, MSG_ENTITY);
	}

	void wepent_think(entity this)
	{
		if(wasfreed(this.owner) || !this.owner)
		{
			delete(this);
			return;
		}

		this.nextthink = time;

		entity o = this.owner;

		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (this.fld != o.fld) { \
				set(this.fld, o.fld); \
				this.SendFlags |= BIT(i); \
			} \
			i += 1; \
		}
		WEPENT_NETPROPS(X);
	#undef X
	}

	bool wepent_customize(entity this, entity client)
	{
		entity e = WaypointSprite_getviewentity(client);
		.entity weaponentity = this.owner.weaponentity_fld;
		return e.(weaponentity) == this.owner;
	}

	void wepent_link(entity wep)
	{
		entity e = new_pure(wepent_sender);
		e.owner = wep;
		setthink(e, wepent_think);
		e.nextthink = time;
		//e.drawonlytoclient = wep.owner;
		setcefc(e, wepent_customize);
		Net_LinkEntity(e, false, 0, wepent_send);
	}

#endif

#ifdef CSQC

	bool ReadWepent(entity this)
	{
		int slot = ReadByte();
		this.m_wepent_slot = slot;
		viewmodels[slot].m_wepent_slot = slot;
		int sf = ReadInt24_t();
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (sf & BIT(i)) { \
				cl; \
			} \
			i += 1; \
		}
		WEPENT_NETPROPS(X);
	#undef X
		return true;
	}

	NET_HANDLE(ENT_CLIENT_WEPENT, bool isnew)
	{
		return ReadWepent(this);
	}

	NET_HANDLE(CLIENT_WEPENT, bool isnew)
	{
		return ReadWepent(NULL);
	}

#endif
