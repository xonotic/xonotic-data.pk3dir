#include "items.qh"

#include <client/main.qh>
#include <common/items/_mod.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <lib/csqcmodel/common.qh>
#include <lib/warpzone/common.qh>

.vector item_glowmod;
.int item_simple;
.float alpha;
.bool pushable;
.float anim_start_time; // reusing for bob waveform synchronisation
.vector angles_held; // reusing for (re)storing original angles
.float wait, delay, pointtime; // reusing for despawn effects
.vector m_mins, m_maxs; // reusing for storing standard bbox (same purpose as in SVQC itemdef)

HashMap ENT_CLIENT_ITEM_simple;
STATIC_INIT(ENT_CLIENT_ITEM_simple)
{
	HM_NEW(ENT_CLIENT_ITEM_simple);
}
SHUTDOWN(ENT_CLIENT_ITEM_simple)
{
	HM_DELETE(ENT_CLIENT_ITEM_simple);
}

void ItemSetModel(entity this, bool wantsimple)
{
	if(wantsimple)
	{
		string _fn2 = substring(this.mdl, 0 , strlen(this.mdl) -4);
		#define extensions(x) \
		x(iqm) \
		x(dpm) \
		x(md3) \
		x(mdl) \
		/**/
		#define tryext(ext) { \
			string s = strcat(_fn2, autocvar_cl_simpleitems_postfix, "." #ext); \
			string cached = HM_gets(ENT_CLIENT_ITEM_simple, s); \
			if (cached == "") { \
				HM_sets(ENT_CLIENT_ITEM_simple, s, cached = fexists(s) ? "1" : "0"); \
			} \
			if (cached != "0") { \
				this.model = s; \
				this.item_simple = 1; \
				break; \
			} \
		}
		do {
			extensions(tryext);
			this.model = this.mdl; // fall back to 3d model
			this.item_simple = -1; // don't retry every frame
			LOG_TRACEF("Simple item requested for %s but no model exists for it", this.mdl);
		} while (0);
		#undef tryext
		#undef extensions
	}
	else
	{
		this.model = this.mdl;
		this.item_simple = 0;
	}

	// this.model is an engine string so it doesn't need to be zoned and can't be unzoned
	if(this.model == "")
		LOG_WARNF("this.model is unset for item %s", this.classname);
	precache_model(this.model);
	_setmodel(this, this.model);
	setsize(this, this.m_mins, this.m_maxs);
}

void ItemDraw(entity this)
{
	bool wantsimple = autocvar_cl_simple_items && (this.ItemStatus & ITS_ALLOWSI);
	if(wantsimple != this.item_simple && this.item_simple != -1)
		ItemSetModel(this, wantsimple);

	// no bobbing applied to simple items, for consistency's sake (no visual difference between ammo and weapons)
	bool animate = (autocvar_cl_items_animate & 1) && this.item_simple <= 0 && (this.ItemStatus & (ITS_ANIMATE1 | ITS_ANIMATE2));

	// rotation must be set before running physics
	if(!animate)
	{
		this.avelocity_y = 0;
		this.angles = this.angles_held; // restore angles sent from server
	}
	else if(!this.avelocity_y) // unset by MOVETYPE_TOSS or animation was disabled previously
	{
		if(this.ItemStatus & ITS_ANIMATE1)
			this.avelocity_y = 180;
		else if(this.ItemStatus & ITS_ANIMATE2)
			this.avelocity_y = -90;
	}

	// CSQC physics OR bobbing (both would look weird)
	float bobheight = 0; // reset bob offset if animations are disabled
	if(this.move_movetype && (!IS_ONGROUND(this) || this.velocity != '0 0 0'))
	{
		// this isn't equivalent to player prediction but allows smooth motion with very low ISF_LOCATION rate
		// which requires running this even if the item is just outside visible range (it could be moving into range)
		if(animate)
			bobheight = this.origin_z - this.oldorigin_z;
		Movetype_Physics_NoMatchTicrate(this, frametime, true);
		this.oldorigin = this.origin; // update real (SVQC equivalent) origin
		if(animate)
		{
			if(bobheight)
			{
				this.anim_start_time += frametime; // bobbing is paused this frame
				this.oldorigin_z -= bobheight; // restore bob offset (CSQC physics uses the offset bbox)
			}
			else
			{
				this.anim_start_time = time; // starting our bob animation from NOW
				if(this.ItemStatus & ITS_ANIMATE1)
					bobheight = 10; // height of wave at 0 time
				else if(this.ItemStatus & ITS_ANIMATE2)
					bobheight = 8; // height of wave at 0 time
			}
		}
	}
	else if(animate)
	{
		this.angles += this.avelocity * frametime; // MOVETYPE_TOSS does this while it's moving

		if(this.ItemStatus & ITS_ANIMATE1)
			bobheight = 10 + 8 * sin((time - this.anim_start_time) * 2);
		else if(this.ItemStatus & ITS_ANIMATE2)
			bobheight = 8 + 4 * sin((time - this.anim_start_time) * 3);
	}

	// apply new bob offset
	if (bobheight != this.origin_z - this.oldorigin_z)
	{
		this.origin_z = this.oldorigin_z + bobheight;
		this.mins_z = this.m_mins.z - bobheight; // don't want the absmin and absmax to bob
		this.maxs_z = this.m_maxs.z - bobheight;
	}

	// set alpha based on distance
	this.alpha = 1;
	this.drawmask = 0;
	if(this.fade_end && !warpzone_warpzones_exist)
	{
		vector org = getpropertyvec(VF_ORIGIN);
		if(vdist(org - this.origin, >, this.fade_end))
			this.alpha = 0; // save on some processing
		else if(autocvar_cl_items_fadedist > 0)
		{
			this.fade_start = max(500, this.fade_end - autocvar_cl_items_fadedist);
			if(vdist(org - this.origin, >, this.fade_start))
				this.alpha = bound(0, (this.fade_end - vlen(org - this.origin - 0.5 * (this.mins + this.maxs))) / (this.fade_end - this.fade_start), 1);
		}
	}

	if(!this.alpha)
		return;

	// modify alpha based on availability and vehicle hud
	if(this.ItemStatus & ITS_AVAILABLE)
	{
		if(hud) // apparently this means we're in a vehicle lol
		{
			this.alpha *= autocvar_cl_items_vehicle_alpha;
			this.colormod = this.glowmod = autocvar_cl_items_vehicle_color;
		}
		else if(this.ItemStatus & ITS_STAYWEP)
		{
			this.alpha *= autocvar_cl_weapon_stay_alpha;
			this.colormod = this.glowmod = autocvar_cl_weapon_stay_color;
		}
		else
		{
			this.colormod = '1 1 1';
			this.glowmod = this.item_glowmod;
		}
	}
	else
	{
		this.alpha *= autocvar_cl_ghost_items;
		this.colormod = this.glowmod = autocvar_cl_ghost_items_color;
	}

	if(!this.alpha)
		return;

	// loot item despawn effects
	if(this.ItemStatus & ITS_EXPIRING)
	{
		if(!this.wait) // when receiving the first message with ITS_EXPIRING set
		{
			this.wait = time + IT_DESPAWNFX_TIME; // it will despawn then
			this.delay = 0.25;
		}

		if(autocvar_cl_items_animate & 2)
			this.alpha *= (this.wait - time) / IT_DESPAWNFX_TIME;

		if((autocvar_cl_items_animate & 4) && time >= this.pointtime)
		{
			pointparticles(EFFECT_ITEM_DESPAWN, this.origin + '0 0 16', '0 0 0', 1);
			if (this.delay > 0.0625)
				this.delay *= 0.5;
			this.pointtime = time + this.delay;
		}
	}

	this.drawmask = this.alpha <= 0 ? 0 : MASK_NORMAL;
}

void ItemRemove(entity this)
{
	strfree(this.mdl);
}

NET_HANDLE(ENT_CLIENT_ITEM, bool isnew)
{
	int sf = ReadByte();

	if(sf & ISF_LOCATION)
	{
		float bobheight = this.origin_z - this.oldorigin_z;
		this.origin = this.oldorigin = ReadVector();
		this.origin_z += bobheight; // restore animation offset (SVQC physics is unaware of CSQC bbox offset)
		setorigin(this, this.origin); // link
	}

	if(sf & ISF_ANGLES)
	{
		this.angles = this.angles_held = ReadAngleVector();
	}

	if(sf & ISF_STATUS) // need to read/write status first so model can handle simple, fb etc.
	{
		int prevItemStatus = this.ItemStatus;
		this.ItemStatus = ReadByte();

		if(this.ItemStatus & ITS_ALLOWFB)
			this.effects |= EF_FULLBRIGHT;
		else
			this.effects &= ~EF_FULLBRIGHT;

		if(this.ItemStatus & ITS_AVAILABLE)
		{
			if(this.solid != SOLID_TRIGGER)
			{
				this.solid = SOLID_TRIGGER;
				setorigin(this, this.origin); // link it to the area grid
			}

			if(this.ItemStatus & ITS_GLOW)
				this.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
			if(!(prevItemStatus & ITS_AVAILABLE) && this.alpha && !isnew)
				pointparticles(EFFECT_ITEM_RESPAWN, (this.absmin + this.absmax) * 0.5, '0 0 0', 1);
		}
		else
		{
			if(this.solid != SOLID_NOT)
			{
				this.solid = SOLID_NOT;
				setorigin(this, this.origin); // optimisation: unlink it from the area grid
			}

			if(this.ItemStatus & ITS_GLOW)
				this.effects &= ~(EF_ADDITIVE | EF_FULLBRIGHT);
			if((prevItemStatus & ITS_AVAILABLE) && this.alpha)
				pointparticles(EFFECT_ITEM_PICKUP, (this.absmin + this.absmax) * 0.5, '0 0 0', 1);
		}
	}

	if(sf & (ISF_SIZE | ISF_SIZE2)) // always true when it's spawned (in CSQC's perspective)
	{
		if(isnew)
		{
			IL_PUSH(g_drawables, this);
			this.draw = ItemDraw;
			this.flags |= FL_ITEM;
			this.entremove = ItemRemove;
		}

		if(sf & ISF_SIZE && !(sf & ISF_SIZE2)) // Small
		{
			this.m_mins = ITEM_S_MINS;
			this.m_maxs = ITEM_S_MAXS;
		}
		else if(!(sf & ISF_SIZE) && sf & ISF_SIZE2) // Large
		{
			this.m_mins = ITEM_D_MINS;
			this.m_maxs = ITEM_L_MAXS;
		}
		else // Default
		{
			this.m_mins = ITEM_D_MINS;
			this.m_maxs = ITEM_D_MAXS;
		}

		this.fade_end = ReadShort();

		strcpy(this.mdl, ReadString());
		this.item_simple = -2;

		this.skin = ReadByte();
	}

	if(sf & ISF_COLORMAP)
	{
		this.colormap = ReadShort();
		this.item_glowmod_x = ReadByte() / 255.0;
		this.item_glowmod_y = ReadByte() / 255.0;
		this.item_glowmod_z = ReadByte() / 255.0;
	}

	if(sf & ISF_DROP)
	{
		this.gravity = 1;
		this.pushable = true;
		set_movetype(this, MOVETYPE_TOSS);
		this.velocity = ReadVector();
	}
	else if (this.gravity) // caution: kludge FIXME (with sv_legacy_bbox_expand)
	{
		// workaround for prediction errors caused by bbox discrepancy between SVQC and CSQC
		this.gravity = 0; // don't do this kludge again
		this.pushable = false; // no fun allowed
		set_movetype(this, MOVETYPE_NONE); // disable physics
		this.velocity = '0 0 0'; // disable it more
		SET_ONGROUND(this); // extra overkill
	}

	if(sf & ISF_REMOVEFX && !(sf & (ISF_SIZE | ISF_SIZE2))) // TODO !isnew isn't reliable for this... are we double sending initialisations?
	{
		// no longer available to pick up, about to be removed
		if (this.drawmask) // this.alpha > 0
			pointparticles(EFFECT_ITEM_PICKUP, (this.absmin + this.absmax) * 0.5, '0 0 0', 1);
		// removing now causes CSQC_Ent_Remove() to spam
		this.drawmask = 0;
		IL_REMOVE(g_drawables, this);
		this.solid = SOLID_NOT;
	}

	return true;
}
