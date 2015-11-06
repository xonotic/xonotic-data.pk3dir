#include "cl_generator.qh"

.float alpha;
.float scale;
.int count;
.float max_health;

void ons_generator_ray_draw(entity this)
{
	if(time < self.move_time)
		return;

	self.move_time = time + 0.05;

	if(self.count > 10)
	{
		remove(self);
		return;
	}

	if(self.count > 5)
		self.alpha -= 0.1;
	else
		self.alpha += 0.1;

	self.scale += 0.2;
	self.count +=1;
}

void ons_generator_ray_spawn(vector org)
{
	entity e = new(ons_ray);
	setmodel(e, MDL_ONS_RAY);
	setorigin(e, org);
	e.angles = randomvec() * 360;
	e.move_origin = org;
	e.movetype = MOVETYPE_NONE;
	e.alpha = 0;
	e.scale = random() * 5 + 8;
	e.move_time = time + 0.05;
	e.drawmask = MASK_NORMAL;
	e.draw = ons_generator_ray_draw;
}

void generator_draw(entity this)
{
	if(time < self.move_time)
		return;

	if(self.health > 0)
	{
		// damaged fx (less probable the more damaged is the generator)
		if(random() < 0.9 - self.health / self.max_health)
		if(random() < 0.01)
		{
			pointparticles(EFFECT_ELECTRO_BALLEXPLODE, self.origin + randompos('-50 -50 -20', '50 50 50'), '0 0 0', 1);
			sound(self, CH_TRIGGER, SND_ONS_ELECTRICITY_EXPLODE, VOL_BASE, ATTEN_NORM);
		}
		else
			pointparticles(EFFECT_ONS_GENERATOR_DAMAGED, self.origin + randompos('-60 -60 -20', '60 60 60'), '0 0 0', 1);

		self.move_time = time + 0.1;

		return;
	}

	if(self.count <= 0)
		return;

	vector org;
	int i;

	// White shockwave
	if(self.count==40||self.count==20)
	{
		sound(self, CH_TRIGGER, SND_ONS_SHOCKWAVE, VOL_BASE, ATTEN_NORM);
		pointparticles(EFFECT_ELECTRO_COMBO, self.origin, '0 0 0', 6);
	}

	// rays
	if(random() > 0.25)
	{
		ons_generator_ray_spawn(self.origin);
	}

	// Spawn fire balls
	for(i=0;i < 10;++i)
	{
		org = self.origin + randompos('-30 -30 -30' * i + '0 0 -20', '30 30 30' * i + '0 0 20');
		pointparticles(EFFECT_ONS_GENERATOR_GIB, org, '0 0 0', 1);
	}

	// Short explosion sound + small explosion
	if(random() < 0.25)
	{
		te_explosion(self.origin);
		sound(self, CH_TRIGGER, SND_GRENADE_IMPACT, VOL_BASE, ATTEN_NORM);
	}

	// Particles
	org = self.origin + randompos(self.mins + '8 8 8', self.maxs + '-8 -8 -8');
	pointparticles(EFFECT_ONS_GENERATOR_EXPLODE, org, '0 0 0', 1);

	// Final explosion
	if(self.count==1)
	{
		org = self.origin;
		te_explosion(org);
		pointparticles(EFFECT_ONS_GENERATOR_EXPLODE2, org, '0 0 0', 1);
		sound(self, CH_TRIGGER, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	}

	self.move_time = time + 0.05;

	self.count -= 1;
}

void generator_damage(float hp)
{SELFPARAM();
	if(hp <= 0)
		setmodel(self, MDL_ONS_GEN_DEAD);
	else if(hp < self.max_health * 0.10)
		setmodel(self, MDL_ONS_GEN9);
	else if(hp < self.max_health * 0.20)
		setmodel(self, MDL_ONS_GEN8);
	else if(hp < self.max_health * 0.30)
		setmodel(self, MDL_ONS_GEN7);
	else if(hp < self.max_health * 0.40)
		setmodel(self, MDL_ONS_GEN6);
	else if(hp < self.max_health * 0.50)
		setmodel(self, MDL_ONS_GEN5);
	else if(hp < self.max_health * 0.60)
		setmodel(self, MDL_ONS_GEN4);
	else if(hp < self.max_health * 0.70)
		setmodel(self, MDL_ONS_GEN3);
	else if(hp < self.max_health * 0.80)
		setmodel(self, MDL_ONS_GEN2);
	else if(hp < self.max_health * 0.90)
		setmodel(self, MDL_ONS_GEN1);
	else if(hp <= self.max_health || hp >= self.max_health)
		setmodel(self, MDL_ONS_GEN);

	setsize(self, GENERATOR_MIN, GENERATOR_MAX);
}

void generator_construct()
{SELFPARAM();
	self.netname = "Generator";
	self.classname = "onslaught_generator";

	setorigin(self, self.origin);
	setmodel(self, MDL_ONS_GEN);
	setsize(self, GENERATOR_MIN, GENERATOR_MAX);

	self.move_movetype	= MOVETYPE_NOCLIP;
	self.solid			= SOLID_BBOX;
	self.movetype		= MOVETYPE_NOCLIP;
	self.move_origin	= self.origin;
	self.move_time		= time;
	self.drawmask		= MASK_NORMAL;
	self.alpha			= 1;
	self.draw			= generator_draw;
}

.vector glowmod;
void generator_changeteam()
{SELFPARAM();
	if(self.team)
	{
		self.glowmod = Team_ColorRGB(self.team - 1);
		self.teamradar_color = Team_ColorRGB(self.team - 1);
		self.colormap = 1024 + (self.team - 1) * 17;
	}
	else
	{
		self.colormap = 1024;
		self.glowmod = '1 1 0';
		self.teamradar_color = '1 1 0';
	}
}

NET_HANDLE(ENT_CLIENT_GENERATOR, bool isnew)
{
	return = true;
	int sf = ReadByte();

	if(sf & GSF_SETUP)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);

		self.health = ReadByte();
		self.max_health = ReadByte();
		self.count = ReadByte();
		self.team = ReadByte();

		if(!self.count)
			self.count = 40;

		generator_changeteam();
		generator_construct();
	}

	if(sf & GSF_STATUS)
	{
		int _tmp;
		_tmp = ReadByte();
		if(_tmp != self.team)
		{
			self.team = _tmp;
			generator_changeteam();
		}

		_tmp = ReadByte();

		if(_tmp != self.health)
			generator_damage(_tmp);

		self.health = _tmp;
	}
}
