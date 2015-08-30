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

void func_vectormamamam_controller_think()
{SELFPARAM();
	self.nextthink = time + 0.1;

	if(self.owner.active != ACTIVE_ACTIVE)
	{
		self.owner.velocity = '0 0 0';
		return;
	}

	if(self.owner.classname == "func_vectormamamam") // don't brake stuff if the func_vectormamamam was killtarget'ed
		self.owner.velocity = (self.owner.destvec + func_vectormamamam_origin(self.owner, 0.1) - self.owner.origin) * 10;
}

void func_vectormamamam_findtarget()
{SELFPARAM();
	if(self.target != "")
		self.wp00 = find(world, targetname, self.target);

	if(self.target2 != "")
		self.wp01 = find(world, targetname, self.target2);

	if(self.target3 != "")
		self.wp02 = find(world, targetname, self.target3);

	if(self.target4 != "")
		self.wp03 = find(world, targetname, self.target4);

	if(!self.wp00 && !self.wp01 && !self.wp02 && !self.wp03)
		objerror("No reference entity found, so there is nothing to move. Aborting.");

	self.destvec = self.origin - func_vectormamamam_origin(self, 0);

	entity controller;
	controller = spawn();
	controller.classname = "func_vectormamamam_controller";
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_vectormamamam_controller_think;
}

void spawnfunc_func_vectormamamam()
{SELFPARAM();
	if (self.noise != "")
	{
		precache_sound(self.noise);
		soundto(MSG_INIT, self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_IDLE);
	}

	if(!self.targetfactor)
		self.targetfactor = 1;

	if(!self.target2factor)
		self.target2factor = 1;

	if(!self.target3factor)
		self.target3factor = 1;

	if(!self.target4factor)
		self.target4factor = 1;

	if(vlen(self.targetnormal))
		self.targetnormal = normalize(self.targetnormal);

	if(vlen(self.target2normal))
		self.target2normal = normalize(self.target2normal);

	if(vlen(self.target3normal))
		self.target3normal = normalize(self.target3normal);

	if(vlen(self.target4normal))
		self.target4normal = normalize(self.target4normal);

	self.blocked = generic_plat_blocked;
	if(self.dmg && (self.message == ""))
		self.message = " was squished";
    if(self.dmg && (self.message == ""))
		self.message2 = "was squished by";
	if(self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;
	self.dmgtime2 = time;

	if(self.netname == "")
		self.netname = "1 0 0 0 1";

	if (!InitMovingBrushTrigger())
		return;

	// wait for targets to spawn
	self.SUB_NEXTTHINK = self.SUB_LTIME + 999999999;
	self.SUB_THINK = SUB_NullThink; // for PushMove

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	self.effects |= EF_LOWPRECISION;

	self.active = ACTIVE_ACTIVE;

	InitializeEntity(self, func_vectormamamam_findtarget, INITPRIO_FINDTARGET);
}
#endif
