#include "items.qh"

#include <client/main.qh>
#include <common/items/_mod.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <lib/csqcmodel/common.qh>
#include <lib/warpzone/common.qh>

bool autocvar_cl_ghost_items_vehicle = true;
.vector item_glowmod;
.bool item_simple; // probably not really needed, but better safe than sorry
.float alpha;
.bool pushable;
void Item_SetAlpha(entity this)
{
	bool veh_hud = (hud && autocvar_cl_ghost_items_vehicle);

	if(!veh_hud && (this.ItemStatus & ITS_AVAILABLE))
	{
		this.alpha = 1;
		this.colormod = '1 1 1';
		this.glowmod = this.item_glowmod;
	}
	else
	{
		this.alpha = autocvar_cl_ghost_items;
		this.colormod = this.glowmod = autocvar_cl_ghost_items_color;
	}

	if((!veh_hud) && (this.ItemStatus & ITS_STAYWEP))
	{
		this.colormod = this.glowmod = autocvar_cl_weapon_stay_color;
		this.alpha = autocvar_cl_weapon_stay_alpha;
	}

	this.drawmask = ((this.alpha <= 0) ? 0 : MASK_NORMAL);
}

void ItemDraw(entity this)
{
    if(this.gravity)
    {
        Movetype_Physics_MatchServer(this, false);
        if(IS_ONGROUND(this))
        { // For some reason avelocity gets set to '0 0 0' here ...
            this.oldorigin = this.origin;
            this.gravity = 0;

            if(autocvar_cl_animate_items)
            { // ... so reset it if animations are requested.
                if(this.ItemStatus & ITS_ANIMATE1)
                    this.avelocity = '0 180 0';

                if(this.ItemStatus & ITS_ANIMATE2)
                    this.avelocity = '0 -90 0';
            }

            // delay is for blocking item's position for a while;
            // it's a workaround for dropped weapons that receive the position
            // another time right after they spawn overriding animation position
            this.onground_time = time + 0.5;
        }
    }
    else if (autocvar_cl_animate_items && !this.item_simple) // no bobbing applied to simple items, for consistency's sake (no visual difference between ammo and weapons)
    {
        if(this.ItemStatus & ITS_ANIMATE1)
        {
        	this.angles += this.avelocity * frametime;
            float fade_in = bound(0, time - this.onground_time, 1);
            setorigin(this, this.oldorigin + fade_in * ('0 0 10' + '0 0 8' * sin((time - this.onground_time) * 2)));
        }

        if(this.ItemStatus & ITS_ANIMATE2)
        {
        	this.angles += this.avelocity * frametime;
            float fade_in = bound(0, time - this.onground_time, 1);
            setorigin(this, this.oldorigin + fade_in * ('0 0 8' + '0 0 4' * sin((time - this.onground_time) * 3)));
        }
    }

    Item_SetAlpha(this);
}

void Item_PreDraw(entity this)
{
	if(warpzone_warpzones_exist)
	{
		setpredraw(this, func_null); // no need to keep running this
		return;
	}
	float alph;
	vector org = getpropertyvec(VF_ORIGIN);
	//if(!checkpvs(org, this)) // this makes sense as long as we don't support recursive warpzones
		//alph = 0; // this shouldn't be needed, since items behind walls are culled anyway
	if(this.fade_start)
	{
		if(vdist(org - this.origin, >, this.fade_end))
			alph = 0; // save on some processing
		else if(vdist(org - this.origin, <, this.fade_start))
			alph = 1; // more processing saved
		else
			alph = bound(0, (this.fade_end - vlen(org - this.origin - 0.5 * (this.mins + this.maxs))) / (this.fade_end - this.fade_start), 1);
	}
	else
		alph = 1;
	//printf("%v <-> %v\n", view_origin, this.origin + 0.5 * (this.mins + this.maxs));
	if(!hud && (this.ItemStatus & ITS_AVAILABLE))
		this.alpha = alph;
	if(alph <= 0)
		this.drawmask = 0;
	//else
		//this.drawmask = MASK_NORMAL; // reset by the setalpha function
}

void ItemRemove(entity this)
{
	strfree(this.mdl);
}

HashMap ENT_CLIENT_ITEM_simple;
STATIC_INIT(ENT_CLIENT_ITEM_simple)
{
	HM_NEW(ENT_CLIENT_ITEM_simple);
}
SHUTDOWN(ENT_CLIENT_ITEM_simple)
{
	HM_DELETE(ENT_CLIENT_ITEM_simple);
}

NET_HANDLE(ENT_CLIENT_ITEM, bool isnew)
{
    int sf = ReadByte();

    if(sf & ISF_LOCATION)
    {
        vector org = ReadVector();
        setorigin(this, org);
        this.oldorigin = org;
    }

    if(sf & ISF_ANGLES)
    {
        this.angles = ReadAngleVector();
    }

    if(sf & ISF_SIZE)
    {
        setsize(this, '-16 -16 0', '16 16 48');
    }

    if(sf & ISF_STATUS) // need to read/write status first so model can handle simple, fb etc.
    {
        this.ItemStatus = ReadByte();

        Item_SetAlpha(this);

        if(this.ItemStatus & ITS_ALLOWFB)
            this.effects |= EF_FULLBRIGHT;
        else
            this.effects &= ~EF_FULLBRIGHT;

        if(this.ItemStatus & ITS_GLOW)
        {
            if(this.ItemStatus & ITS_AVAILABLE)
                this.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
            else
                this.effects &= ~(EF_ADDITIVE | EF_FULLBRIGHT);
        }
    }

    if(sf & ISF_MODEL)
    {
        this.drawmask  = MASK_NORMAL;
		set_movetype(this, MOVETYPE_TOSS);
		if (isnew) IL_PUSH(g_drawables, this);
        this.draw       = ItemDraw;
        this.solid = SOLID_TRIGGER;
        //this.flags |= FL_ITEM;

        this.fade_end = ReadShort();
        this.fade_start = ReadShort();
        if(!warpzone_warpzones_exist && this.fade_start && !autocvar_cl_items_nofade)
        	setpredraw(this, Item_PreDraw);

		strfree(this.mdl);

        string _fn = ReadString();
        this.item_simple = false; // reset it!

        if(autocvar_cl_simple_items && (this.ItemStatus & ITS_ALLOWSI))
        {
            string _fn2 = substring(_fn, 0 , strlen(_fn) -4);
            this.item_simple = true;

			#define extensions(x) \
				x(md3) \
				x(dpm) \
				x(iqm) \
				x(mdl) \
				/**/
			#define tryext(ext) { \
				string s = strcat(_fn2, autocvar_cl_simpleitems_postfix, "." #ext); \
				string cached = HM_gets(ENT_CLIENT_ITEM_simple, s); \
				if (cached == "") { \
					HM_sets(ENT_CLIENT_ITEM_simple, s, cached = fexists(s) ? "1" : "0"); \
				} \
				if (cached != "0") { \
					strcpy(this.mdl, s); \
					break; \
				} \
			}
			do {
				extensions(tryext);
				this.item_simple = false;
                LOG_TRACEF("Simple item requested for %s but no model exists for it", _fn);
			} while (0);
			#undef tryext
			#undef extensions
        }

        if(!this.item_simple)
            strcpy(this.mdl, _fn);

        if(this.mdl == "")
            LOG_WARNF("this.mdl is unset for item %s", this.classname);

        precache_model(this.mdl);
        _setmodel(this, this.mdl);

        this.skin = ReadByte();

        setsize(this, '-16 -16 0', '16 16 48');
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
        //this.angles = '0 0 0';
        set_movetype(this, MOVETYPE_TOSS);
        this.velocity = ReadVector();
        setorigin(this, this.oldorigin);

        if(!this.move_time)
        {
            this.move_time = time;
            this.spawntime = time;
        }
        else
            this.move_time = max(this.move_time, time);
    }

    if(autocvar_cl_animate_items)
    {
        if(this.ItemStatus & ITS_ANIMATE1)
            this.avelocity = '0 180 0';

        if(this.ItemStatus & ITS_ANIMATE2)
            this.avelocity = '0 -90 0';
    }

    this.entremove = ItemRemove;

    return true;
}
