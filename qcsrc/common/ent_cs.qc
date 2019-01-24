#include "ent_cs.qh"
#include <common/gamemodes/_mod.qh>
#include <common/resources.qh>
#ifdef SVQC
#include <server/resources.qh>
#endif

REGISTRY(EntCSProps, BITS(16) - 1)
#define EntCSProps_from(i) _EntCSProps_from(i, NULL)
REGISTER_REGISTRY(EntCSProps)
REGISTRY_SORT(EntCSProps)
REGISTRY_CHECK(EntCSProps)
STATIC_INIT(RegisterEntCSProps_renumber) { FOREACH(EntCSProps, true, it.m_id = i); }

.bool m_public;
.bool(entity ent, entity player) m_check;
.void(entity ent, entity player) m_set;
.void(int chan, entity ent) m_send;
.void(entity ent) m_receive;

#ifdef SVQC
#define _ENTCS_PROP(id, ispublic, checkprop, setprop, svsend, clreceive) \
	void id##_set(entity ent, entity player) { setprop(ent.(checkprop), player.(checkprop)); } \
	void id##_send(int chan, entity ent) { LAMBDA(svsend); } \
	REGISTER(EntCSProps, ENTCS_PROP, id, m_id, new_pure(entcs_prop)) { \
		this.m_public = ispublic; \
		this.m_check = id##_check; \
		this.m_set = id##_set; \
		this.m_send = id##_send; \
	}

#define ENTCS_PROP(id, ispublic, checkprop, setprop, svsend, clreceive) \
	bool id##_check(entity ent, entity player) { return (ent.(checkprop) != player.(checkprop)); } \
	_ENTCS_PROP(id, ispublic, checkprop, setprop, svsend, clreceive)

#define ENTCS_PROP_CODED(id, ispublic, checkprop, setprop, decfactor, svsend, clreceive) \
	bool id##_check(entity ent, entity player) { \
		return (floor(ent.(checkprop)) / decfactor != floor(player.(checkprop)) * decfactor); \
	} \
	_ENTCS_PROP(id, ispublic, checkprop, setprop, svsend, clreceive)

#elif defined(CSQC)
#define ENTCS_PROP(id, ispublic, checkprop, setprop, svsend, clreceive) \
	void id##_receive(entity ent) { LAMBDA(clreceive); } \
	REGISTER(EntCSProps, ENTCS_PROP, id, m_id, new_pure(entcs_prop)) { \
		this.m_public = ispublic; \
		this.m_receive = id##_receive; \
	}

#define ENTCS_PROP_CODED(id, ispublic, checkprop, setprop, decfactor, svsend, clreceive) \
	ENTCS_PROP(id, ispublic, checkprop, setprop, svsend, clreceive)
#endif

#ifdef SVQC
#define ENTCS_PROP_RESOURCE(id, ispublic, checkprop, setprop, decfactor, svsend, clreceive) \
	bool id##_check(entity ent, entity player) { \
		return (floor(GetResourceAmount(ent, checkprop) / decfactor) != floor(GetResourceAmount(player, checkprop) / decfactor)); \
	} \
	void id##_set(entity ent, entity player) { SetResourceAmountExplicit(ent, checkprop, GetResourceAmount(player, checkprop)); } \
	void id##_send(int chan, entity ent) { LAMBDA(svsend); } \
	REGISTER(EntCSProps, ENTCS_PROP, id, m_id, new_pure(entcs_prop)) { \
		this.m_public = ispublic; \
		this.m_check = id##_check; \
		this.m_set = id##_set; \
		this.m_send = id##_send; \
	}
#elif defined(CSQC)
#define ENTCS_PROP_RESOURCE(id, ispublic, checkprop, setprop, decfactor, svsend, clreceive) \
	void id##_receive(entity ent) { LAMBDA(clreceive); } \
	REGISTER(EntCSProps, ENTCS_PROP, id, m_id, new_pure(entcs_prop)) { \
		this.m_public = ispublic; \
		this.m_receive = id##_receive; \
	}
#endif

#define ENTCS_SET_NORMAL(var, x) MACRO_BEGIN \
	var = x; \
MACRO_END

/** the engine player name strings are mutable! */
#define ENTCS_SET_MUTABLE_STRING(var, x) MACRO_BEGIN \
	strcpy(var, x); \
MACRO_END

ENTCS_PROP(ENTNUM, false, sv_entnum, ENTCS_SET_NORMAL, {}, {}) /* sentinel */

ENTCS_PROP(ORIGIN, false, origin, ENTCS_SET_NORMAL,
	{ WriteVector(chan, ent.origin); },
	{ ent.has_sv_origin = true; vector v = ReadVector(); setorigin(ent, v); })

#define DEC_FACTOR (360 / 256)
ENTCS_PROP_CODED(ANGLES, false, angles_y, ENTCS_SET_NORMAL, DEC_FACTOR,
	{ WriteByte(chan, ent.angles.y / DEC_FACTOR); },
	{ vector v = '0 0 0'; v.y = ReadByte() * DEC_FACTOR; ent.angles = v; })
#undef DEC_FACTOR

// FIXME: use a better scale?
#define DEC_FACTOR 10
ENTCS_PROP_RESOURCE(HEALTH, false, RESOURCE_HEALTH, ENTCS_SET_NORMAL, DEC_FACTOR,
	{ WriteByte(chan, bound(0, GetResourceAmount(ent, RESOURCE_HEALTH) / DEC_FACTOR, 255)); },
	{ ent.healthvalue = ReadByte() * DEC_FACTOR; })

ENTCS_PROP_RESOURCE(ARMOR, false, RESOURCE_ARMOR, ENTCS_SET_NORMAL, DEC_FACTOR,
	{ WriteByte(chan, bound(0, GetResourceAmount(ent, RESOURCE_ARMOR) / DEC_FACTOR, 255)); },
	{ SetResourceAmountExplicit(ent, RESOURCE_ARMOR, ReadByte() * DEC_FACTOR); })
#undef DEC_FACTOR

ENTCS_PROP(NAME, true, netname, ENTCS_SET_MUTABLE_STRING,
	{ WriteString(chan, ent.netname); },
	{ strcpy(ent.netname, ReadString()); })

ENTCS_PROP(MODEL, true, model, ENTCS_SET_NORMAL,
	{ WriteString(chan, ent.model); },
	{ strcpy(ent.model, ReadString()); })

ENTCS_PROP(SKIN, true, skin, ENTCS_SET_NORMAL,
	{ WriteByte(chan, ent.skin); },
	{ ent.skin = ReadByte(); })

ENTCS_PROP(CLIENTCOLORS, true, clientcolors, ENTCS_SET_NORMAL,
	{ WriteByte(chan, ent.clientcolors); },
	{ ent.colormap = ReadByte(); })

ENTCS_PROP(FRAGS, true, frags, ENTCS_SET_NORMAL,
	{ WriteShort(chan, ent.frags); },
	{ ent.frags = ReadShort(); })

#ifdef SVQC

	int ENTCS_PUBLICMASK = 0;
	STATIC_INIT(ENTCS_PUBLICMASK)
	{
		FOREACH(EntCSProps, it.m_public,
		{
			ENTCS_PUBLICMASK |= BIT(it.m_id);
		});
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
		FOREACH(EntCSProps, sf & BIT(it.m_id),
		{
			it.m_send(chan, this);
		});
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
		FOREACH(EntCSProps, it.m_check(this, o),
		{
			it.m_set(this, o);
			this.SendFlags |= BIT(it.m_id);
		});
	    setorigin(this, this.origin);  // relink
	}

	void entcs_attach(entity player)
	{
		entity e = CS(player).entcs = new(entcs_sender);
		e.owner = player;
		setthink(e, entcs_think);
		e.nextthink = time;
		Net_LinkEntity(e, false, 0, entcs_send);
		if (!IS_REAL_CLIENT(player)) return;
		FOREACH_CLIENT(true, {
			assert(CS(it).entcs);
			_entcs_send(CS(it).entcs, msg_entity = player, BITS(23), MSG_ONE);
		});
	}

	void entcs_detach(entity player)
	{
		if (!CS(player).entcs) return;
		delete(CS(player).entcs);
		CS(player).entcs = NULL;
	}

#endif

#ifdef CSQC

	void Ent_RemoveEntCS(entity this)
	{
		int n = this.sv_entnum;
		entity e = entcs_receiver(n);
		entcs_receiver(n, NULL);
		strfree(e.netname);
		strfree(e.model);
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
			strcpy(this.model, e.model);
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
		FOREACH(EntCSProps, sf & BIT(it.m_id),
		{
			it.m_receive(e);
		});
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
