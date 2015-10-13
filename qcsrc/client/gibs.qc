#include "gibs.qh"

#include "rubble.qh"
#include "../common/movetypes/movetypes.qh"

.float scale;
.float alpha;
.float cnt;
.float gravity;

void Gib_Delete()
{SELFPARAM();
	remove(self);
}

string species_prefix(int specnum)
{
	switch(specnum)
	{
		case SPECIES_HUMAN:       return "";
		case SPECIES_ALIEN:       return "alien_";
		case SPECIES_ROBOT_SHINY: return "robot_";
		case SPECIES_ROBOT_RUSTY: return "robot_"; // use the same effects, only different gibs
		case SPECIES_ROBOT_SOLID: return "robot_"; // use the same effects, only different gibs
		case SPECIES_ANIMAL:      return "animal_";
		case SPECIES_RESERVED:    return "reserved_";
		default:         return "";
	}
}

void Gib_setmodel(entity gib, string mdlname, int specnum)
{
	switch(specnum)
	{
		case SPECIES_ROBOT_RUSTY:
		case SPECIES_ROBOT_SHINY:
		case SPECIES_ROBOT_SOLID:
			if(specnum != SPECIES_ROBOT_SOLID || mdlname == "models/gibs/chunk.mdl")
			{
				if(mdlname == "models/gibs/bloodyskull.md3")
					setmodel(gib, MDL_GIB_ROBO);
				else
					setmodel(gib, MDL_GIB_ROBO_RANDOM());
				if(specnum == SPECIES_ROBOT_SHINY)
				{
					gib.skin = 1;
					gib.colormod = '2 2 2';
				}
				gib.scale = 1;
				break;
			}
		default:
			_setmodel(gib, mdlname);
			gib.skin = specnum;
			break;
	}
}

void new_te_bloodshower (int ef, vector org, float explosionspeed, int howmany)
{
	float i, pmod;
	pmod = autocvar_cl_particles_quality;
	for (i = 0; i < 50 * pmod; ++i)
		pointparticles(ef, org, randomvec() * explosionspeed, howmany / 50);
}

void SUB_RemoveOnNoImpact()
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		Gib_Delete();
}

void Gib_Touch()
{SELFPARAM();
	// TODO maybe bounce of walls, make more gibs, etc.

	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		Gib_Delete();
		return;
	}

	if(!self.silent)
		sound(self, CH_PAIN, SND_GIB_SPLAT_RANDOM(), VOL_BASE, ATTEN_NORM);
	pointparticles(_particleeffectnum(strcat(species_prefix(self.cnt), "blood")), self.origin + '0 0 1', '0 0 30', 10);

	Gib_Delete();
}

void Gib_Draw(entity this)
{
	vector oldorg;
	oldorg = self.origin;

	Movetype_Physics_MatchTicrate(autocvar_cl_gibs_ticrate, autocvar_cl_gibs_sloppy);
	if(wasfreed(self))
		return;

	if(self.touch == Gib_Touch) // don't do this for the "chunk" thingie...
		// TODO somehow make it spray in a direction dependent on self.angles
		trailparticles(self, _particleeffectnum(strcat(species_prefix(self.cnt), EFFECT_TR_SLIGHTBLOOD.eent_eff_name)), oldorg, self.origin);
	else
		trailparticles(self, _particleeffectnum(strcat(species_prefix(self.cnt), EFFECT_TR_BLOOD.eent_eff_name)), oldorg, self.origin);

	self.renderflags = 0;

	// make gibs die faster at low view quality
	// if view_quality is 0.5, we want to have them die twice as fast
	self.nextthink -= frametime * (1 / bound(0.01, view_quality, 1.00) - 1);

	self.alpha = bound(0, self.nextthink - time, 1);

	if(self.alpha < ALPHA_MIN_VISIBLE)
	{
		self.drawmask = 0;
		Gib_Delete();
	}
}

void TossGib (string mdlname, vector safeorg, vector org, vector vconst, vector vrand, int specnum, bool destroyontouch, bool issilent)
{
	entity gib;

	// TODO remove some gibs according to cl_nogibs
	gib = RubbleNew("gib");
	gib.classname = "gib";
	gib.move_movetype = MOVETYPE_BOUNCE;
	gib.gravity = 1;
	gib.solid = SOLID_CORPSE;
	gib.cnt = specnum;
	gib.silent = issilent;
	Gib_setmodel(gib, mdlname, specnum);

	setsize (gib, '-8 -8 -8', '8 8 8');

	gib.draw = Gib_Draw;
	if(destroyontouch)
		gib.move_touch = Gib_Touch;
	else
		gib.move_touch = SUB_RemoveOnNoImpact;

	// don't spawn gibs inside solid - just don't
	if(org != safeorg)
	{
		tracebox(safeorg, gib.mins, gib.maxs, org, MOVE_NOMONSTERS, gib);
		org = trace_endpos;
	}

	gib.move_origin = org;
	setorigin(gib, org);
	gib.move_velocity = vconst * autocvar_cl_gibs_velocity_scale + vrand * autocvar_cl_gibs_velocity_random + '0 0 1' * autocvar_cl_gibs_velocity_up;
	gib.move_avelocity = prandomvec() * vlen(gib.move_velocity) * autocvar_cl_gibs_avelocity_scale;
	gib.move_time = time;
	gib.damageforcescale = autocvar_cl_gibs_damageforcescale;

	gib.nextthink = time + autocvar_cl_gibs_lifetime * (1 + prandom() * 0.15);
	gib.drawmask = MASK_NORMAL;

	RubbleLimit("gib", autocvar_cl_gibs_maxcount, Gib_Delete);
}

void Ent_GibSplash(bool isNew)
{SELFPARAM();
	int amount, type, specnum;
	vector org, vel;
	string specstr;
	bool issilent;
	string gentle_prefix = "morphed_";

	float randomvalue;
	int c;

	type = ReadByte(); // gibbage type
	amount = ReadByte() / 16.0; // gibbage amount
	org.x = ReadShort() * 4 + 2;
	org.y = ReadShort() * 4 + 2;
	org.z = ReadShort() * 4 + 2;
	vel = decompressShortVector(ReadShort());

	float cl_gentle_gibs = autocvar_cl_gentle_gibs;
	if(cl_gentle_gibs || autocvar_cl_gentle)
		type |= 0x80; // set gentle bit

	if(type & 0x80)
	{
		if(cl_gentle_gibs == 2)
			gentle_prefix = "";
		else if(cl_gentle_gibs == 3)
			gentle_prefix = "happy_";
	}
	else if(autocvar_cl_particlegibs)
	{
		type |= 0x80;
		gentle_prefix = "particlegibs_";
	}

	if (!(cl_gentle_gibs || autocvar_cl_gentle))
		amount *= 1 - autocvar_cl_nogibs;

	if(autocvar_ekg)
		amount *= 5;

	if(amount <= 0 || !isNew)
		return;

	setorigin(self, org); // for the sounds

	specnum = (type & 0x78) / 8; // blood/gibmodel type: using four bits (0..7, bit indexes 3,4,5)
	issilent = (type & 0x40);
	type = type & 0x87; // remove the species bits: bit 7 = gentle, bit 0,1,2 = kind of gib
	specstr = species_prefix(specnum);

	switch(type)
	{
		case 0x01:
			if(!issilent)
				sound (self, CH_PAIN, SND_GIB, VOL_BASE, ATTEN_NORM);

			if(prandom() < amount)
				TossGib ("models/gibs/eye.md3", org, org, vel, prandomvec() * 150, specnum, 0, issilent);
			new_te_bloodshower(_particleeffectnum(strcat(specstr, "bloodshower")), org, 1200, amount);
			if(prandom() < amount)
				TossGib ("models/gibs/bloodyskull.md3", org, org + 16 * prandomvec(), vel, prandomvec() * 100, specnum, 0, issilent);

			for(c = 0; c < amount; ++c)
			{
				randomvalue = amount - c;

				if(prandom() < randomvalue)
					TossGib ("models/gibs/arm.md3", org, org + 16 * prandomvec() + '0 0 8', vel, prandomvec() * (prandom() * 120 + 90), specnum,0, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/arm.md3", org, org + 16 * prandomvec() + '0 0 8', vel, prandomvec() * (prandom() * 120 + 90), specnum,0, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/chest.md3", org, org + 16 * prandomvec(), vel, prandomvec() * (prandom() * 120 + 80), specnum,0, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/smallchest.md3", org, org + 16 * prandomvec(), vel, prandomvec() * (prandom() * 120 + 80), specnum,0, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/leg1.md3", org, org + 16 * prandomvec() + '0 0 -5', vel, prandomvec() * (prandom() * 120 + 85), specnum,0, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/leg2.md3", org, org + 16 * prandomvec() + '0 0 -5', vel, prandomvec() * (prandom() * 120 + 85), specnum,0, issilent);

				// these splat on impact
				if(prandom() < randomvalue)
					TossGib ("models/gibs/chunk.mdl", org, org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/chunk.mdl", org, org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/chunk.mdl", org, org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);
				if(prandom() < randomvalue)
					TossGib ("models/gibs/chunk.mdl", org, org + 16 * prandomvec(), vel, prandomvec() * 450, specnum,1, issilent);
			}
			break;
		case 0x02:
			pointparticles(_particleeffectnum(strcat(specstr, "blood")), org, vel, amount * 16);
			break;
		case 0x03:
			if(prandom() < amount)
				TossGib ("models/gibs/chunk.mdl", org, org, vel, prandomvec() * (prandom() * 30 + 20), specnum, 1, issilent); // TODO maybe adjust to more randomization?
			break;
		case 0x81:
			pointparticles(_particleeffectnum(strcat(gentle_prefix, "damage_dissolve")), org, vel, amount);
			break;
		case 0x82:
			pointparticles(_particleeffectnum(strcat(gentle_prefix, "damage_hit")), org, vel, amount * 16);
			break;
		case 0x83:
			// no gibs in gentle mode, sorry
			break;
	}
}
