#include "ent_cs.qh"

// #define PROP(public, fld, sv, cl)
#define ENTCS_NETPROPS(PROP) \
	PROP(true, sv_entnum, \
	{ WriteByte(MSG_ENTITY, etof(player) - 1); }, \
	{ this.sv_entnum = ReadByte(); }) \
    \
	PROP(false, origin, \
	{ WriteShort(MSG_ENTITY, this.origin.x);  WriteShort(MSG_ENTITY, this.origin.y); \
	  WriteShort(MSG_ENTITY, this.origin.z); }, \
	{ this.has_sv_origin = true; vector v; v.x = ReadShort(); v.y = ReadShort(); v.z = ReadShort(); setorigin(this, v); }) \
    \
	PROP(false, angles_y, \
	{ WriteByte(MSG_ENTITY, this.angles.y / 360 * 256); }, \
	{ vector v = '0 0 0'; v.y = ReadByte() / 256 * 360; this.angles = v; }) \
    \
	PROP(false, health, \
	{ WriteByte(MSG_ENTITY, this.health / 10);  /* FIXME: use a better scale? */ }, \
	{ this.healthvalue = ReadByte() * 10; }) \
    \
	PROP(false, armorvalue, \
	{ WriteByte(MSG_ENTITY, this.armorvalue / 10);  /* FIXME: use a better scale? */ }, \
	{ this.armorvalue = ReadByte() * 10; }) \
    \
	PROP(true, netname, \
	{ WriteString(MSG_ENTITY, this.netname); }, \
	{ if (this.netname) strunzone(this.netname); this.netname = strzone(ReadString()); }) \
    \
	PROP(true, model, \
	{ WriteString(MSG_ENTITY, this.model); }, \
	{ if (this.model) strunzone(this.model); this.model = strzone(ReadString()); }) \
    \
	PROP(true, skin, \
	{ WriteByte(MSG_ENTITY, this.skin); }, \
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

	bool entcs_send(entity this, entity to, int sf)
	{
		entity player = this.owner;
		sf |= 1;
		if (IS_PLAYER(to) || to.caplayer)                                  // unless spectating,
		{
			bool same_team = (to == player) || (teamplay && player.team == to.team);
			if (!same_team && !radar_showennemies) sf &= ENTCS_PUBLICMASK; // no private updates
		}
		sf |= this.m_forceupdate;
		this.m_forceupdate = 0;
		bool valid =
		    IS_PLAYER(player)             // player must be active
		    && player.deadflag == DEAD_NO // player must be alive
		    || player == to               // player is self
		;
		if (!valid) sf = 0;
		WriteHeader(MSG_ENTITY, ENT_CLIENT_ENTCS);
		WriteShort(MSG_ENTITY, sf);
		int i = 1;
		#define X(public, fld, sv, cl) { if (sf & BIT(i)) sv; } i += 1;
		ENTCS_NETPROPS(X);
	#undef X
		return true;
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
		entcs_receiver(this.sv_entnum, NULL);
	}

	void entcs_think()
	{
		SELFPARAM();
		this.nextthink = time;
		entity e = CSQCModel_server2csqc(this.sv_entnum + 1);
		bool exists = e != NULL;
		if (exists)
		{
			this.has_origin = true;
			this.origin = e.origin;
			// `cl_forceplayermodels 1` sounds will be wrong until the player has been in the PVS, but so be it
			if (this.model != e.model)
			{
				if (this.model) strunzone(this.model);
				this.model = strzone(e.model);
			}
		}
		else
		{
			this.has_origin = this.has_sv_origin;
		}
	}

	NET_HANDLE(ENT_CLIENT_ENTCS, bool isnew)
	{
		if (isnew)
		{
			make_pure(this);
			this.classname = "entcs_receiver";
			this.entremove = Ent_RemoveEntCS;
			this.think = entcs_think;
			this.nextthink = time;
		}
		InterpolateOrigin_Undo(this);
		int sf = ReadShort();
		this.has_sv_origin = false;
		this.m_entcs_private = boolean(sf & 1);
		int i = 1;
		#define X(public, fld, sv, cl) { if (sf & BIT(i)) cl; } i += 1;
		ENTCS_NETPROPS(X);
	#undef X
		entcs_receiver(this.sv_entnum, this);
		this.iflags |= IFLAG_ORIGIN;
		InterpolateOrigin_Note(this);
		return true;
	}

#endif
