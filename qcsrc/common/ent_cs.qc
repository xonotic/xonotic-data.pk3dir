#include "ent_cs.qh"

// #define PROP(public, fld, sv, cl)
#define ENTCS_NETPROPS(PROP) \
	PROP(true, sv_entnum, \
	{ WriteByte(chan, etof(player) - 1); }, \
	{ this.sv_entnum = ReadByte(); }) \
    \
	PROP(false, origin, \
	{ WriteShort(chan, this.origin.x);  WriteShort(chan, this.origin.y); \
	  WriteShort(chan, this.origin.z); }, \
	{ this.has_sv_origin = true; vector v; v.x = ReadShort(); v.y = ReadShort(); v.z = ReadShort(); setorigin(this, v); }) \
    \
	PROP(false, angles_y, \
	{ WriteByte(chan, this.angles.y / 360 * 256); }, \
	{ vector v = '0 0 0'; v.y = ReadByte() / 256 * 360; this.angles = v; }) \
    \
	PROP(false, health, \
	{ WriteByte(chan, this.health / 10);  /* FIXME: use a better scale? */ }, \
	{ this.healthvalue = ReadByte() * 10; }) \
    \
	PROP(false, armorvalue, \
	{ WriteByte(chan, this.armorvalue / 10);  /* FIXME: use a better scale? */ }, \
	{ this.armorvalue = ReadByte() * 10; }) \
    \
	PROP(true, netname, \
	{ WriteString(chan, this.netname); }, \
	{ if (this.netname) strunzone(this.netname); this.netname = strzone(ReadString()); }) \
    \
	PROP(true, model, \
	{ WriteString(chan, this.model); }, \
	{ if (this.model) strunzone(this.model); this.model = strzone(ReadString()); }) \
    \
	PROP(true, skin, \
	{ WriteByte(chan, this.skin); }, \
	{ this.skin = ReadByte(); }) \
    \
	/**/

#ifdef SVQC

	int ENTCS_PUBLICMASK = 0;
	STATIC_INIT(ENTCS_PUBLICMASK)
	{
		int i = 1;
		#define X(public, fld, sv, cl) { if (public) ENTCS_PUBLICMASK |= BIT(i); } i += 1;
		ENTCS_NETPROPS(X);
	#undef X
		if (i >= BITS(16 - 1)) LOG_FATAL("Exceeded ENTCS_NETPROPS limit");
	}

	bool _entcs_send(entity this, entity to, int sf, int chan)
	{
		entity player = this.owner;
		sf |= BIT(0) | BIT(1);
		if (IS_PLAYER(to) || to.caplayer)                                  // unless spectating,
		{
			bool same_team = (to == player) || (teamplay && player.team == to.team);
			if (!same_team && !radar_showennemies) sf &= ENTCS_PUBLICMASK; // no private updates
		}
		sf |= this.m_forceupdate;
		this.m_forceupdate = 0;
		bool valid =
		    IS_PLAYER(player)             // player must be active
		    || player == to               // player is self
		;
		if (!valid) sf = 0;
		if (chan == MSG_ENTITY)
			WriteHeader(chan, ENT_CLIENT_ENTCS);
		else
			WriteHeader(chan, CLIENT_ENTCS);
		WriteByte(chan, etof(player) - 1);
		WriteShort(chan, sf);
		int i = 1;
		#define X(public, fld, sv, cl) { if (sf & BIT(i)) sv; } i += 1;
		ENTCS_NETPROPS(X);
	#undef X
		return true;
	}

	bool entcs_send(entity this, entity to, int sf)
	{
		return _entcs_send(this, to, sf, MSG_ENTITY);
	}

	void entcs_think()
	{
		SELFPARAM();
		this.nextthink = time + 0.033333333333;  // TODO: increase this to like 0.15 once the client can do smoothing
		entity o = this.owner;
		int i = 1;
		#define X(public, fld, sv, cl) \
			if (o.fld != this.fld) \
			{ \
				this.fld = o.fld; \
				this.SendFlags |= BIT(i); \
			} \
			i += 1;
		ENTCS_NETPROPS(X);
	#undef X
	}

	void entcs_attach(entity player)
	{
		entity e = player.entcs = new(entcs_sender);
		make_pure(e);
		e.owner = player;
		e.think = entcs_think;
		e.nextthink = time;
		Net_LinkEntity(e, false, 0, entcs_send);
		if (!IS_REAL_CLIENT(player)) return;
		FOR_EACH_CLIENT(e)
		{
			assert(e.entcs);
			_entcs_send(e.entcs, msg_entity = player, BITS(23), MSG_ONE);
		}
	}

	void entcs_detach(entity player)
	{
		if (!player.entcs) return;
		remove(player.entcs);
		player.entcs = NULL;
	}

#endif

#ifdef CSQC

	void Ent_RemoveEntCS()
	{
		SELFPARAM();
		int n = this.sv_entnum;
		entity e = entcs_receiver(n);
		entcs_receiver(n, NULL);
		if (e != this) remove(e);
	}

	void entcs_think()
	{
		SELFPARAM();
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
			if (this)
			{
				e = this;
			}
			else
			{
				e = new(entcs_receiver);
				make_pure(e);
			}
			e.sv_entnum = n;
			e.think = entcs_think;
			entcs_receiver(n, e);
		}
		else if (this && e != this)
		{
			this.classname = "entcs_gc";
			this.sv_entnum = n;
		}
		this = e;
		InterpolateOrigin_Undo(this);
		this.sv_entnum = n;
		int sf = ReadShort();
		this.has_sv_origin = false;
		this.m_entcs_private = boolean(sf & BIT(0));
		int i = 1;
		#define X(public, fld, sv, cl) { if (sf & BIT(i)) cl; } i += 1;
		ENTCS_NETPROPS(X);
	#undef X
		this.iflags |= IFLAG_ORIGIN;
		InterpolateOrigin_Note(this);
		WITH(entity, self, this, this.think());
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
