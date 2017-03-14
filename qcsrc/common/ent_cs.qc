#include "ent_cs.qh"

#define ENTCS_SET_NORMAL(var, x) MACRO_BEGIN \
	var = x; \
MACRO_END

/** the engine player name strings are mutable! */
#define ENTCS_SET_MUTABLE_STRING(var, x) MACRO_BEGIN \
	if (var) strunzone(var); \
	var = strzone(x); \
MACRO_END

// #define PROP(public, fld, set, sv, cl)
#define ENTCS_NETPROPS(ent, PROP) PROP(false, sv_entnum, ENTCS_SET_NORMAL, {}, {}) /* sentinel */ \
	PROP(false, origin, ENTCS_SET_NORMAL, \
	{ WriteCoord(chan, ent.origin.x);  WriteCoord(chan, ent.origin.y); \
	  WriteCoord(chan, ent.origin.z); }, \
	{ ent.has_sv_origin = true; vector v; v.x = ReadCoord(); v.y = ReadCoord(); v.z = ReadCoord(); setorigin(ent, v); }) \
    \
	PROP(false, angles_y, ENTCS_SET_NORMAL, \
	{ WriteByte(chan, ent.angles.y / 360 * 256); }, \
	{ vector v = '0 0 0'; v.y = ReadByte() / 256 * 360; ent.angles = v; }) \
    \
	PROP(false, health, ENTCS_SET_NORMAL, \
	{ WriteByte(chan, bound(0, ent.health / 10, 255));  /* FIXME: use a better scale? */ }, \
	{ ent.healthvalue = ReadByte() * 10; }) \
    \
	PROP(false, armorvalue, ENTCS_SET_NORMAL, \
	{ WriteByte(chan, bound(0, ent.armorvalue / 10, 255));  /* FIXME: use a better scale? */ }, \
	{ ent.armorvalue = ReadByte() * 10; }) \
    \
	PROP(true, netname, ENTCS_SET_MUTABLE_STRING, \
	{ WriteString(chan, ent.netname); }, \
	{ if (ent.netname) strunzone(ent.netname); ent.netname = strzone(ReadString()); }) \
    \
	PROP(true, model, ENTCS_SET_NORMAL, \
	{ WriteString(chan, ent.model); }, \
	{ if (ent.model) strunzone(ent.model); ent.model = strzone(ReadString()); }) \
    \
	PROP(true, skin, ENTCS_SET_NORMAL, \
	{ WriteByte(chan, ent.skin); }, \
	{ ent.skin = ReadByte(); }) \
    \
    PROP(true, clientcolors, ENTCS_SET_NORMAL, \
	{ WriteByte(chan, ent.clientcolors); }, \
	{ ent.colormap = ReadByte(); }) \
    \
    PROP(true, frags, ENTCS_SET_NORMAL, \
	{ WriteShort(chan, ent.frags); }, \
	{ ent.frags = ReadShort(); }) \
    \
	/**/

#ifdef SVQC

	int ENTCS_PUBLICMASK = 0;
	STATIC_INIT(ENTCS_PUBLICMASK)
	{
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (public) { \
				ENTCS_PUBLICMASK |= BIT(i); \
			} \
			i += 1; \
		}
		ENTCS_NETPROPS(this, X);
		#undef X
		if (i >= BITS(16 - 1)) LOG_FATAL("Exceeded ENTCS_NETPROPS limit");
	}

	bool _entcs_send(entity this, entity to, int sf, int chan)
	{
		entity player = this.owner;
		sf |= BIT(0); // assume private
		do {
			if (IS_PLAYER(player))
			{
				if (radar_showennemies) break;
				if (SAME_TEAM(to, player)) break;
				if (!(IS_PLAYER(to) || to.caplayer) && time > game_starttime) break;
			}
			sf &= ENTCS_PUBLICMASK; // no private updates
		} while (0);

		sf |= this.m_forceupdate;
		this.m_forceupdate = 0;
		if (chan == MSG_ENTITY)
			WriteHeader(chan, ENT_CLIENT_ENTCS);
		else
			WriteHeader(chan, CLIENT_ENTCS);
		WriteByte(chan, etof(player) - 1);
		WriteShort(chan, sf);
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (sf & BIT(i)) { \
				sv; \
			} \
			i += 1; \
		}
		ENTCS_NETPROPS(this, X);
		#undef X
		return true;
	}

	bool entcs_send(entity this, entity to, int sf)
	{
		return _entcs_send(this, to, sf, MSG_ENTITY);
	}

	void entcs_think(entity this)
	{
		this.nextthink = time + 0.033333333333;  // TODO: increase this to like 0.15 once the client can do smoothing
		entity o = this.owner;
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (o.fld != this.fld) { \
				set(this.fld, o.fld); \
				this.SendFlags |= BIT(i); \
			} \
			i += 1; \
		}
		ENTCS_NETPROPS(this, X);
		#undef X
	    setorigin(this, this.origin);  // relink
	}

	void entcs_attach(entity player)
	{
		entity e = player.entcs = new(entcs_sender);
		e.owner = player;
		setthink(e, entcs_think);
		e.nextthink = time;
		Net_LinkEntity(e, false, 0, entcs_send);
		if (!IS_REAL_CLIENT(player)) return;
		FOREACH_CLIENT(true, {
			assert(it.entcs);
			_entcs_send(it.entcs, msg_entity = player, BITS(23), MSG_ONE);
		});
	}

	void entcs_detach(entity player)
	{
		if (!player.entcs) return;
		delete(player.entcs);
		player.entcs = NULL;
	}

#endif

#ifdef CSQC

	void Ent_RemoveEntCS(entity this)
	{
		int n = this.sv_entnum;
		entity e = entcs_receiver(n);
		entcs_receiver(n, NULL);
		if (e.netname) strunzone(e.netname);
		e.netname = string_null;
		if (e.model) strunzone(e.model);
		e.model = string_null;
		if (e != this) delete(e);
	}

	void entcs_think(entity this)
	{
		entity e = CSQCModel_server2csqc(this.sv_entnum);
		if (e == NULL)
		{
			this.has_origin = this.has_sv_origin;
			return;
		}
		this.has_origin = true;
		this.origin = e.origin;
		// `cl_forceplayermodels 1` sounds will be wrong until the player has been in the PVS, but so be it
		if (this.model != e.model)
		{
			if (this.model) strunzone(this.model);
			this.model = strzone(e.model);
		}
	}

	bool ReadEntcs(entity this)
	{
		int n = ReadByte();
		entity e = entcs_receiver(n);
		if (e == NULL)
		{
			if (!this)
				// initial = temp
				e = new_pure(entcs_receiver);
			else
				// initial = linked
				e = this;
			setthink(e, entcs_think);
			entcs_receiver(n, e);
		}
		else if (e != this && this)
		{
			// upgrade to linked
			delete(e);
			e = this;
			setthink(e, entcs_think);
			entcs_receiver(n, e);
		}

		InterpolateOrigin_Undo(e);
		e.sv_entnum = n;
		int sf = ReadShort();
		e.has_sv_origin = false;
		e.m_entcs_private = boolean(sf & BIT(0));
		int i = 0;
		#define X(public, fld, set, sv, cl) { \
			if (sf & BIT(i)) { \
				cl; \
			} \
			i += 1; \
		}
		ENTCS_NETPROPS(e, X);
		#undef X
		e.iflags |= IFLAG_ORIGIN;
		InterpolateOrigin_Note(e);
		getthink(e)(e);
		return true;
	}

	NET_HANDLE(ENT_CLIENT_ENTCS, bool isnew)
	{
		if (isnew)
		{
			make_pure(this);
			this.classname = "entcs_receiver";
			this.entremove = Ent_RemoveEntCS;
		}
		return ReadEntcs(this);
	}

	NET_HANDLE(CLIENT_ENTCS, bool isnew)
	{
		return ReadEntcs(NULL);
	}

#endif
