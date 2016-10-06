#include "wepent.qh"

#define WEPENT_SET_NORMAL(var, x) MACRO_BEGIN \
	var = x; \
MACRO_END

/** the engine player name strings are mutable! */
#define WEPENT_SET_MUTABLE_STRING(var, x) MACRO_BEGIN \
	if (var) strunzone(var); \
	var = strzone(x); \
MACRO_END

#ifdef SVQC
	.int w_sv_entnum;
	.Weapon w_m_switchweapon;
	.Weapon w_m_switchingweapon;
	.Weapon w_m_weapon;
	//.float w_weapon_nextthink;
	.float w_m_alpha;
	.float w_vortex_charge;
	.int w_m_gunalign;
	.bool w_porto_v_angle_held;
	.int w_tuba_instrument;
#endif

// #define PROP(public, fld, set, sv, cl)
#define WEPENT_NETPROPS(PROP) PROP(false, sv_entnum, WEPENT_SET_NORMAL, {}, {}) /* sentinel */ \
	PROP(false, m_switchweapon, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_switchweapon.m_id); }, \
	{ (viewmodels[this.m_wepent_slot]).switchweapon = Weapons_from(ReadByte()); }) \
    \
    PROP(false, m_switchingweapon, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_switchingweapon.m_id); }, \
	{ (viewmodels[this.m_wepent_slot]).switchingweapon = Weapons_from(ReadByte()); }) \
    \
    PROP(false, m_weapon, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_weapon.m_id); }, \
	{ (viewmodels[this.m_wepent_slot]).activeweapon = Weapons_from(ReadByte()); }) \
    \
    PROP(false, m_alpha, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_alpha * 16); }, \
	{ (viewmodels[this.m_wepent_slot]).alpha = ReadByte() / 16; }) \
    \
    PROP(false, vortex_charge, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.vortex_charge * 16); }, \
	{ (viewmodels[this.m_wepent_slot]).vortex_charge = ReadByte() / 16; }) \
    \
    PROP(false, m_gunalign, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.m_gunalign); }, \
	{ (viewmodels[this.m_wepent_slot]).m_gunalign = ReadByte(); }) \
    \
    PROP(false, porto_v_angle_held, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.porto_v_angle_held); if(this.porto_v_angle_held) { \
		 WriteAngle(chan, this.porto_v_angle.x); WriteAngle(chan, this.porto_v_angle.y); \
		} }, \
	{ (viewmodels[this.m_wepent_slot]).angles_held_status = ReadByte(); if((viewmodels[this.m_wepent_slot]).angles_held_status) { \
		(viewmodels[this.m_wepent_slot]).angles_held_x = ReadAngle(); (viewmodels[this.m_wepent_slot]).angles_held_y = ReadAngle(); (viewmodels[this.m_wepent_slot]).angles_held_z = 0; } \
		else { (viewmodels[this.m_wepent_slot]).angles_held = '0 0 0'; } }) \
    \
    PROP(false, tuba_instrument, WEPENT_SET_NORMAL, \
	{ WriteByte(chan, this.tuba_instrument); }, \
	{ (viewmodels[this.m_wepent_slot]).tuba_instrument = ReadByte(); }) \
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
		if (i >= BITS(16 - 1)) LOG_FATAL("Exceeded WEPENT_NETPROPS limit");
	}

	bool _wepent_send(entity this, entity to, int sf, int chan)
	{
		sf |= this.m_forceupdate;
		this.m_forceupdate = 0;
		if (chan == MSG_ENTITY)
			WriteHeader(chan, ENT_CLIENT_WEPENT);
		else
			WriteHeader(chan, CLIENT_WEPENT);
		.entity weaponentity = this.weaponentity_fld;
		WriteByte(chan, weaponslot(weaponentity));
		WriteShort(chan, sf);
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

	void wepent_update(entity this)
	{
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (this.w_##fld != this.fld) { \
				set(this.w_##fld, this.fld); \
				this.SendFlags |= BIT(i); \
			} \
			i += 1; \
		}
		WEPENT_NETPROPS(X);
	#undef X
	}

	void wepent_link(entity wep)
	{
		Net_LinkEntity(wep, false, 0, wepent_send);
	}

#endif

#ifdef CSQC

	bool ReadWepent(entity this)
	{
		this.m_wepent_slot = ReadByte();
		int sf = ReadShort();
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
		if (isnew)
		{
			make_pure(this);
			this.classname = "wepent_receiver";
		}
		return ReadWepent(this);
	}

	NET_HANDLE(CLIENT_WEPENT, bool isnew)
	{
		return ReadWepent(NULL);
	}

#endif
