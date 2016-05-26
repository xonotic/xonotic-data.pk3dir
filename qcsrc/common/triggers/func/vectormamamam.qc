#ifdef SVQC
// reusing some fields havocbots declared
.entity wp00, wp01, wp02, wp03;

.float targetfactor, target2factor, target3factor, target4factor;
.vector targetnormal, target2normal, target3normal, target4normal;

vector func_vectormamamam_origin(entity o, float t)
{
	vector v, p;
	float f;
	entity e;

	f = o.spawnflags;
	v = '0 0 0';

	e = o.wp00;
	if(e)
	{
		p = e.origin + t * e.velocity;
		if(f & 1)
			v = v + (p * o.targetnormal) * o.targetnormal * o.targetfactor;
		else
			v = v + (p - (p * o.targetnormal) * o.targetnormal) * o.targetfactor;
	}

	e = o.wp01;
	if(e)
	{
		p = e.origin + t * e.velocity;
		if(f & 2)
			v = v + (p * o.target2normal) * o.target2normal * o.target2factor;
		else
			v = v + (p - (p * o.target2normal) * o.target2normal) * o.target2factor;
	}

	e = o.wp02;
	if(e)
	{
		p = e.origin + t * e.velocity;
		if(f & 4)
			v = v + (p * o.target3normal) * o.target3normal * o.target3factor;
		else
			v = v + (p - (p * o.target3normal) * o.target3normal) * o.target3factor;
	}

	e = o.wp03;
	if(e)
	{
		p = e.origin + t * e.velocity;
		if(f & 8)
			v = v + (p * o.target4normal) * o.target4normal * o.target4factor;
		else
			v = v + (p - (p * o.target4normal) * o.target4normal) * o.target4factor;
	}

	return v;
}

void func_vectormamamam_controller_think(entity this)
{
	self.nextthink = time + 0.1;

	if(self.owner.active != ACTIVE_ACTIVE)
	{
		self.owner.velocity = '0 0 0';
		return;
	}

	if(self.owner.classname == "func_vectormamamam") // don't brake stuff if the func_vectormamamam was killtarget'ed
		self.owner.velocity = (self.owner.destvec + func_vectormamamam_origin(self.owner, 0.1) - self.owner.origin) * 10;
}

void func_vectormamamam_findtarget(entity this)
{
	if(this.target != "")
		this.wp00 = find(world, targetname, this.target);

	if(this.target2 != "")
		this.wp01 = find(world, targetname, this.target2);

	if(this.target3 != "")
		this.wp02 = find(world, targetname, this.target3);

	if(this.target4 != "")
		this.wp03 = find(world, targetname, this.target4);

	if(!this.wp00 && !this.wp01 && !this.wp02 && !this.wp03)
		objerror("No reference entity found, so there is nothing to move. Aborting.");

	this.destvec = this.origin - func_vectormamamam_origin(this, 0);

	entity controller;
	controller = new(func_vectormamamam_controller);
	controller.owner = this;
	controller.nextthink = time + 1;
	setthink(controller, func_vectormamamam_controller_think);
}

spawnfunc(func_vectormamamam)
{
	if (this.noise != "")
	{
		precache_sound(this.noise);
		soundto(MSG_INIT, this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE);
	}

	if(!this.targetfactor)
		this.targetfactor = 1;

	if(!this.target2factor)
		this.target2factor = 1;

	if(!this.target3factor)
		this.target3factor = 1;

	if(!this.target4factor)
		this.target4factor = 1;

	if(vlen(this.targetnormal))
		this.targetnormal = normalize(this.targetnormal);

	if(vlen(this.target2normal))
		this.target2normal = normalize(this.target2normal);

	if(vlen(this.target3normal))
		this.target3normal = normalize(this.target3normal);

	if(vlen(this.target4normal))
		this.target4normal = normalize(this.target4normal);

	this.blocked = generic_plat_blocked;
	if(this.dmg && (this.message == ""))
		this.message = " was squished";
    if(this.dmg && (this.message == ""))
		this.message2 = "was squished by";
	if(this.dmg && (!this.dmgtime))
		this.dmgtime = 0.25;
	this.dmgtime2 = time;

	if(this.netname == "")
		this.netname = "1 0 0 0 1";

	if (!InitMovingBrushTrigger(this))
		return;

	// wait for targets to spawn
	this.SUB_NEXTTHINK = this.SUB_LTIME + 999999999;
	SUB_THINK(this, SUB_NullThink); // for PushMove

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	this.effects |= EF_LOWPRECISION;

	this.active = ACTIVE_ACTIVE;

	InitializeEntity(this, func_vectormamamam_findtarget, INITPRIO_FINDTARGET);
}
#endif
