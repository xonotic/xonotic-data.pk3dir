#include "vectormamamam.qh"
#ifdef SVQC
// reusing some fields havocbots declared
.entity wp00, wp01, wp02, wp03;

.float targetfactor, target2factor, target3factor, target4factor;
.vector targetnormal, target2normal, target3normal, target4normal;

vector func_vectormamamam_origin(entity o, float timestep)
{
	vector p;
	entity e;
	int myflags = o.spawnflags;
	vector v = '0 0 0';

	e = o.wp00;
	if(e)
	{
		p = e.origin + timestep * e.velocity;
		if(myflags & PROJECT_ON_TARGETNORMAL)
			v = v + (p * o.targetnormal) * o.targetnormal * o.targetfactor;
		else
			v = v + (p - (p * o.targetnormal) * o.targetnormal) * o.targetfactor;
	}

	e = o.wp01;
	if(e)
	{
		p = e.origin + timestep * e.velocity;
		if(myflags & PROJECT_ON_TARGET2NORMAL)
			v = v + (p * o.target2normal) * o.target2normal * o.target2factor;
		else
			v = v + (p - (p * o.target2normal) * o.target2normal) * o.target2factor;
	}

	e = o.wp02;
	if(e)
	{
		p = e.origin + timestep * e.velocity;
		if(myflags & PROJECT_ON_TARGET3NORMAL)
			v = v + (p * o.target3normal) * o.target3normal * o.target3factor;
		else
			v = v + (p - (p * o.target3normal) * o.target3normal) * o.target3factor;
	}

	e = o.wp03;
	if(e)
	{
		p = e.origin + timestep * e.velocity;
		if(myflags & PROJECT_ON_TARGET4NORMAL)
			v = v + (p * o.target4normal) * o.target4normal * o.target4factor;
		else
			v = v + (p - (p * o.target4normal) * o.target4normal) * o.target4factor;
	}

	return v;
}

void func_vectormamamam_controller_think(entity this)
{
	this.nextthink = time + VECTORMAMAMAM_TIMESTEP;

	if(this.owner.active != ACTIVE_ACTIVE)
	{
		this.owner.velocity = '0 0 0';
		return;
	}

	if(this.owner.classname == "func_vectormamamam") // don't brake stuff if the func_vectormamamam was killtarget'ed
		this.owner.velocity = (this.owner.destvec + func_vectormamamam_origin(this.owner, VECTORMAMAMAM_TIMESTEP) - this.owner.origin) * 10;
}

void func_vectormamamam_findtarget(entity this)
{
	if(this.target && this.target != "")
		this.wp00 = find(NULL, targetname, this.target);

	if(this.target2 && this.target2 != "")
		this.wp01 = find(NULL, targetname, this.target2);

	if(this.target3 && this.target3 != "")
		this.wp02 = find(NULL, targetname, this.target3);

	if(this.target4 && this.target4 != "")
		this.wp03 = find(NULL, targetname, this.target4);

	if(!this.wp00 && !this.wp01 && !this.wp02 && !this.wp03)
		objerror(this, "No reference entity found, so there is nothing to move. Aborting.");

	this.destvec = this.origin - func_vectormamamam_origin(this, 0);

	entity controller = new_pure(func_vectormamamam_controller);
	controller.owner = this;
	controller.nextthink = time + 1;
	setthink(controller, func_vectormamamam_controller_think);
}

void func_vectormamamam_setactive(entity this, int astate)
{
	if (astate == ACTIVE_TOGGLE)
	{
		if(this.active == ACTIVE_ACTIVE)
			this.active = ACTIVE_NOT;
		else
			this.active = ACTIVE_ACTIVE;
	}
	else
		this.active = astate;

	if(this.active  == ACTIVE_NOT)
	{
		stopsound(this, CH_TRIGGER_SINGLE);
	}
	else
	{
		if(this.noise && this.noise != "")
		{
			_sound(this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE);
		}
	}
}

void func_vectormamamam_init_for_player(entity this, entity player)
{
	if (this.noise && this.noise != "" && this.active == ACTIVE_ACTIVE && IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		soundto(MSG_ONE, this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE, 0);
	}
}

spawnfunc(func_vectormamamam)
{
	if (this.noise != "")
	{
		precache_sound(this.noise);
	}

	if(!this.targetfactor)
		this.targetfactor = 1;

	if(!this.target2factor)
		this.target2factor = 1;

	if(!this.target3factor)
		this.target3factor = 1;

	if(!this.target4factor)
		this.target4factor = 1;

	if(this.targetnormal)
		this.targetnormal = normalize(this.targetnormal);

	if(this.target2normal)
		this.target2normal = normalize(this.target2normal);

	if(this.target3normal)
		this.target3normal = normalize(this.target3normal);

	if(this.target4normal)
		this.target4normal = normalize(this.target4normal);

	setblocked(this, generic_plat_blocked);
	if(this.dmg && (!this.message || this.message == ""))
		this.message = " was squished";
    if(this.dmg && (!this.message2 || this.message2 == ""))
		this.message2 = "was squished by";
	if(this.dmg && (!this.dmgtime))
		this.dmgtime = 0.25;
	this.dmgtime2 = time;

	if (!InitMovingBrushTrigger(this))
		return;

	// wait for targets to spawn
	this.nextthink = this.ltime + 999999999;
	setthink(this, SUB_NullThink); // for PushMove

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	this.effects |= EF_LOWPRECISION;

	this.setactive = func_vectormamamam_setactive;
	this.setactive(this, ACTIVE_ACTIVE);

	// maybe send sound to new players
	IL_PUSH(g_initforplayer, this);
	this.init_for_player = func_vectormamamam_init_for_player;

	InitializeEntity(this, func_vectormamamam_findtarget, INITPRIO_FINDTARGET);
}
#endif
