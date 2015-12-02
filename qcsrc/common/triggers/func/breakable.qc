#ifdef SVQC

#include "../../../server/g_subs.qh"
#include "../../../server/g_damage.qh"
#include "../../../server/bot/bot.qh"
#include "../../../common/csqcmodel_settings.qh"
#include "../../../lib/csqcmodel/sv_model.qh"
#include "../../../server/weapons/common.qh"

.entity sprite;

.float dmg;
.float dmg_edge;
.float dmg_radius;
.float dmg_force;
.float debrismovetype;
.float debrissolid;
.vector debrisvelocity;
.vector debrisvelocityjitter;
.vector debrisavelocityjitter;
.float debristime;
.float debristimejitter;
.float debrisfadetime;
.float debrisdamageforcescale;
.float debrisskin;

.string mdl_dead; // or "" to hide when broken
.string debris; // space separated list of debris models
// other fields:
//   mdl = particle effect name
//   count = particle effect multiplier
//   targetname = target to trigger to unbreak the model
//   target = targets to trigger when broken
//   health = amount of damage it can take
//   spawnflags:
//     1 = start disabled (needs to be triggered to activate)
//     2 = indicate damage
//     4 = don't take direct damage (needs to be triggered to 'explode', then triggered again to restore)
// notes:
//   for mdl_dead to work, origin must be set (using a common/origin brush).
//   Otherwise mdl_dead will be displayed at the map origin, and nobody would
//   want that!

void func_breakable_damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force);

//
// func_breakable
// - basically func_assault_destructible for general gameplay use
//
void LaunchDebris (string debrisname, vector force)
{SELFPARAM();
	entity dbr = spawn();
	setorigin(dbr, self.absmin
	           + '1 0 0' * random() * (self.absmax.x - self.absmin.x)
	           + '0 1 0' * random() * (self.absmax.y - self.absmin.y)
	           + '0 0 1' * random() * (self.absmax.z - self.absmin.z));
	_setmodel (dbr, debrisname );
	dbr.skin = self.debrisskin;
	dbr.colormap = self.colormap; // inherit team colors
	dbr.owner = self; // do not be affected by our own explosion
	dbr.movetype = self.debrismovetype;
	dbr.solid = self.debrissolid;
	if(dbr.solid != SOLID_BSP) // SOLID_BSP has exact collision, MAYBE this works? TODO check this out
		setsize(dbr, '0 0 0', '0 0 0'); // needed for performance, until engine can deal better with it
	dbr.velocity_x = self.debrisvelocity.x + self.debrisvelocityjitter.x * crandom();
	dbr.velocity_y = self.debrisvelocity.y + self.debrisvelocityjitter.y * crandom();
	dbr.velocity_z = self.debrisvelocity.z + self.debrisvelocityjitter.z * crandom();
	self.velocity = self.velocity + force * self.debrisdamageforcescale;
	dbr.avelocity_x = random()*self.debrisavelocityjitter.x;
	dbr.avelocity_y = random()*self.debrisavelocityjitter.y;
	dbr.avelocity_z = random()*self.debrisavelocityjitter.z;
	dbr.damageforcescale = self.debrisdamageforcescale;
	if(dbr.damageforcescale)
		dbr.takedamage = DAMAGE_YES;
	SUB_SetFade(dbr, time + self.debristime + crandom() * self.debristimejitter, self.debrisfadetime);
}

void func_breakable_colormod()
{SELFPARAM();
	float h;
	if (!(self.spawnflags & 2))
		return;
	h = self.health / self.max_health;
	if(h < 0.25)
		self.colormod = '1 0 0';
	else if(h <= 0.75)
		self.colormod = '1 0 0' + '0 1 0' * (2 * h - 0.5);
	else
		self.colormod = '1 1 1';

	CSQCMODEL_AUTOUPDATE(self);
}

void func_breakable_look_destroyed()
{SELFPARAM();
	float floorZ;

	if(self.solid == SOLID_BSP) // in case a misc_follow moved me, save the current origin first
		self.dropped_origin = self.origin;

	if(self.mdl_dead == "")
		self.effects |= EF_NODRAW;
	else {
		if (self.origin == '0 0 0')	{	// probably no origin brush, so don't spawn in the middle of the map..
			floorZ = self.absmin.z;
			setorigin(self,((self.absmax+self.absmin)*.5));
			self.origin_z = floorZ;
		}
		_setmodel(self, self.mdl_dead);
		self.effects &= ~EF_NODRAW;
	}

	CSQCMODEL_AUTOUPDATE(self);

	self.solid = SOLID_NOT;
}

void func_breakable_look_restore()
{SELFPARAM();
	_setmodel(self, self.mdl);
	self.effects &= ~EF_NODRAW;

	if(self.mdl_dead != "") // only do this if we use mdl_dead, to behave better with misc_follow
		setorigin(self, self.dropped_origin);

	CSQCMODEL_AUTOUPDATE(self);

	self.solid = SOLID_BSP;
}

void func_breakable_behave_destroyed()
{SELFPARAM();
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	self.bot_attack = false;
	self.event_damage = func_null;
	self.state = 1;
	if(self.spawnflags & 4)
		self.use = func_null;
	func_breakable_colormod();
	if (self.noise1)
		stopsound (self, CH_TRIGGER_SINGLE);
}

void func_breakable_behave_restore()
{SELFPARAM();
	self.health = self.max_health;
	if(self.sprite)
	{
		WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
	}
	if(!(self.spawnflags & 4))
	{
		self.takedamage = DAMAGE_AIM;
		self.bot_attack = true;
		self.event_damage = func_breakable_damage;
	}
	self.state = 0;
	self.nextthink = 0; // cancel auto respawn
	func_breakable_colormod();
	if (self.noise1)
		_sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
}

void func_breakable_init_for_player(entity player)
{SELFPARAM();
	if (self.noise1 && self.state == 0 && clienttype(player) == CLIENTTYPE_REAL)
	{
		msg_entity = player;
		soundto (MSG_ONE, self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	}
}

void func_breakable_destroyed()
{SELFPARAM();
	func_breakable_look_destroyed();
	func_breakable_behave_destroyed();

	CSQCMODEL_AUTOUPDATE(self);
}

void func_breakable_restore()
{SELFPARAM();
	func_breakable_look_restore();
	func_breakable_behave_restore();

	CSQCMODEL_AUTOUPDATE(self);
}

vector debrisforce; // global, set before calling this
void func_breakable_destroy()
{SELFPARAM();
	float n, i;
	string oldmsg;

	activator = self.owner;
	self.owner = world; // set by W_PrepareExplosionByDamage

	// now throw around the debris
	n = tokenize_console(self.debris);
	for(i = 0; i < n; ++i)
		LaunchDebris(argv(i), debrisforce);

	func_breakable_destroyed();

	if(self.noise)
		_sound (self, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);

	if(self.dmg)
		RadiusDamage(self, activator, self.dmg, self.dmg_edge, self.dmg_radius, self, world, self.dmg_force, DEATH_HURTTRIGGER.m_id, world);

	if(self.cnt) // TODO
		__pointparticles(self.cnt, self.absmin * 0.5 + self.absmax * 0.5, '0 0 0', self.count);

	if(self.respawntime)
	{
		self.think = func_breakable_restore;
		self.nextthink = time + self.respawntime + crandom() * self.respawntimejitter;
	}

	oldmsg = self.message;
	self.message = "";
	SUB_UseTargets();
	self.message = oldmsg;
}

void func_breakable_damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.state == 1)
		return;
	if(self.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	if(self.team)
		if(attacker.team == self.team)
			return;
	self.pain_finished = time;
	self.health = self.health - damage;
	if(self.sprite)
	{
		WaypointSprite_Ping(self.sprite);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
	}
	func_breakable_colormod();

	if(self.health <= 0)
	{
		debrisforce = force;

		self.takedamage = DAMAGE_NO;
		self.event_damage = func_null;

		if(IS_CLIENT(attacker) && self.classname == "func_assault_destructible")
		{
			self.owner = attacker;
			self.realowner = attacker;
		}

		// do not explode NOW but in the NEXT FRAME!
		// because recursive calls to RadiusDamage are not allowed
		self.nextthink = time;
		self.think = func_breakable_destroy;
	}
}

void func_breakable_reset(entity this)
{
	this.team = this.team_saved;
	func_breakable_look_restore();
	if(this.spawnflags & 1)
		func_breakable_behave_destroyed();
	else
		func_breakable_behave_restore();

	CSQCMODEL_AUTOUPDATE(this);
}

// destructible walls that can be used to trigger target_objective_decrease
spawnfunc(func_breakable)
{
	float n, i;
	if(!this.health)
		this.health = 100;
	this.max_health = this.health;

	// yes, I know, MOVETYPE_NONE is not available here, not that one would want it here anyway
	if(!this.debrismovetype) this.debrismovetype = MOVETYPE_BOUNCE;
	if(!this.debrissolid) this.debrissolid = SOLID_NOT;
	if(this.debrisvelocity == '0 0 0') this.debrisvelocity = '0 0 140';
	if(this.debrisvelocityjitter == '0 0 0') this.debrisvelocityjitter = '70 70 70';
	if(this.debrisavelocityjitter == '0 0 0') this.debrisavelocityjitter = '600 600 600';
	if(!this.debristime) this.debristime = 3.5;
	if(!this.debristimejitter) this.debristime = 2.5;

	if(this.mdl != "")
		this.cnt = _particleeffectnum(this.mdl);
	if(this.count == 0)
		this.count = 1;

	if(this.message == "")
		this.message = "got too close to an explosion";
	if(this.message2 == "")
		this.message2 = "was pushed into an explosion by";
	if(!this.dmg_radius)
		this.dmg_radius = 150;
	if(!this.dmg_force)
		this.dmg_force = 200;

	this.mdl = this.model;
	SetBrushEntityModel();

	if(this.spawnflags & 4)
		this.use = func_breakable_destroy;
	else
		this.use = func_breakable_restore;

	if(this.spawnflags & 4)
	{
		this.takedamage = DAMAGE_NO;
		this.event_damage = func_null;
		this.bot_attack = false;
	}

	// precache all the models
	if (this.mdl_dead)
		precache_model(this.mdl_dead);
	n = tokenize_console(this.debris);
	for(i = 0; i < n; ++i)
		precache_model(argv(i));
	if(this.noise)
		precache_sound(this.noise);
	if(this.noise1)
		precache_sound(this.noise1);

	this.team_saved = this.team;
	this.dropped_origin = this.origin;

	this.reset = func_breakable_reset;
	this.reset(this);

	this.init_for_player_needed = 1;
	this.init_for_player = func_breakable_init_for_player;

	CSQCMODEL_AUTOINIT(this);
}

// for use in maps with a "model" key set
spawnfunc(misc_breakablemodel) {
	spawnfunc_func_breakable(this);
}
#endif
