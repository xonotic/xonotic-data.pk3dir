#ifdef SVQC

#include "../../../server/_all.qh"

#include "../../../server/g_subs.qh"
#include "../../../server/waypointsprites.qh"
#include "../../../server/g_damage.qh"
#include "../../../server/bot/bot.qh"
#include "../../common/csqcmodel_settings.qh"
#include "../../../csqcmodellib/sv_model.qh"
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
{
	entity dbr = spawn();
	setorigin(dbr, self.absmin
	           + '1 0 0' * random() * (self.absmax.x - self.absmin.x)
	           + '0 1 0' * random() * (self.absmax.y - self.absmin.y)
	           + '0 0 1' * random() * (self.absmax.z - self.absmin.z));
	setmodel (dbr, debrisname );
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
{
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

	CSQCMODEL_AUTOUPDATE();
}

void func_breakable_look_destroyed()
{
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
		setmodel(self, self.mdl_dead);
		self.effects &= ~EF_NODRAW;
	}

	CSQCMODEL_AUTOUPDATE();

	self.solid = SOLID_NOT;
}

void func_breakable_look_restore()
{
	setmodel(self, self.mdl);
	self.effects &= ~EF_NODRAW;

	if(self.mdl_dead != "") // only do this if we use mdl_dead, to behave better with misc_follow
		setorigin(self, self.dropped_origin);

	CSQCMODEL_AUTOUPDATE();

	self.solid = SOLID_BSP;
}

void func_breakable_behave_destroyed()
{
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
{
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
		sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
}

void func_breakable_init_for_player(entity player)
{
	if (self.noise1 && self.state == 0 && clienttype(player) == CLIENTTYPE_REAL)
	{
		msg_entity = player;
		soundto (MSG_ONE, self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	}
}

void func_breakable_destroyed()
{
	func_breakable_look_destroyed();
	func_breakable_behave_destroyed();

	CSQCMODEL_AUTOUPDATE();
}

void func_breakable_restore()
{
	func_breakable_look_restore();
	func_breakable_behave_restore();

	CSQCMODEL_AUTOUPDATE();
}

vector debrisforce; // global, set before calling this
void func_breakable_destroy() {
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
		sound (self, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);

	if(self.dmg)
		RadiusDamage(self, activator, self.dmg, self.dmg_edge, self.dmg_radius, self, world, self.dmg_force, DEATH_HURTTRIGGER, world);

	if(self.cnt)
		Send_Effect((effects_ent[self.cnt - 1]).eent_eff_name, self.absmin * 0.5 + self.absmax * 0.5, '0 0 0', self.count);

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
{
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
		W_PrepareExplosionByDamage(attacker, func_breakable_destroy);
	}
}

void func_breakable_reset()
{
	self.team = self.team_saved;
	func_breakable_look_restore();
	if(self.spawnflags & 1)
		func_breakable_behave_destroyed();
	else
		func_breakable_behave_restore();

	CSQCMODEL_AUTOUPDATE();
}

// destructible walls that can be used to trigger target_objective_decrease
void spawnfunc_func_breakable()
{
	float n, i;
	if(!self.health)
		self.health = 100;
	self.max_health = self.health;

	// yes, I know, MOVETYPE_NONE is not available here, not that one would want it here anyway
	if(!self.debrismovetype) self.debrismovetype = MOVETYPE_BOUNCE;
	if(!self.debrissolid) self.debrissolid = SOLID_NOT;
	if(self.debrisvelocity == '0 0 0') self.debrisvelocity = '0 0 140';
	if(self.debrisvelocityjitter == '0 0 0') self.debrisvelocityjitter = '70 70 70';
	if(self.debrisavelocityjitter == '0 0 0') self.debrisavelocityjitter = '600 600 600';
	if(!self.debristime) self.debristime = 3.5;
	if(!self.debristimejitter) self.debristime = 2.5;

	if(self.mdl != "")
		self.cnt = particleeffectnum(self.mdl);
	if(self.count == 0)
		self.count = 1;

	if(self.message == "")
		self.message = "got too close to an explosion";
	if(self.message2 == "")
		self.message2 = "was pushed into an explosion by";
	if(!self.dmg_radius)
		self.dmg_radius = 150;
	if(!self.dmg_force)
		self.dmg_force = 200;

	self.mdl = self.model;
	SetBrushEntityModel();

	if(self.spawnflags & 4)
		self.use = func_breakable_destroy;
	else
		self.use = func_breakable_restore;

	if(self.spawnflags & 4)
	{
		self.takedamage = DAMAGE_NO;
		self.event_damage = func_null;
		self.bot_attack = false;
	}

	// precache all the models
	if (self.mdl_dead)
		precache_model(self.mdl_dead);
	n = tokenize_console(self.debris);
	for(i = 0; i < n; ++i)
		precache_model(argv(i));
	if(self.noise)
		precache_sound(self.noise);
	if(self.noise1)
		precache_sound(self.noise1);

	self.team_saved = self.team;
	self.dropped_origin = self.origin;

	self.reset = func_breakable_reset;
	func_breakable_reset();

	self.init_for_player_needed = 1;
	self.init_for_player = func_breakable_init_for_player;

	CSQCMODEL_AUTOINIT();
}

// for use in maps with a "model" key set
void spawnfunc_misc_breakablemodel() {
	spawnfunc_func_breakable();
}
#endif
