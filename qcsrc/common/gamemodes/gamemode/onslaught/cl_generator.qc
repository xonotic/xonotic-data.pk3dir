#include "cl_generator.qh"

.float alpha;
.float scale;
.int count;
.float max_health;

void ons_generator_ray_draw(entity this)
{
	if(time < this.move_time)
		return;

	this.move_time = time + 0.05;

	if(this.count > 10)
	{
		IL_REMOVE(g_drawables, this);
		delete(this);
		return;
	}

	if(this.count > 5)
		this.alpha -= 0.1;
	else
		this.alpha += 0.1;

	this.scale += 0.2;
	this.count +=1;
}

void ons_generator_ray_spawn(vector org)
{
	entity e = new(ons_ray);
	setmodel(e, MDL_ONS_RAY);
	setorigin(e, org);
	e.angles = randomvec() * 360;
	set_movetype(e, MOVETYPE_NONE);
	e.alpha = 0;
	e.scale = random() * 5 + 8;
	e.move_time = time + 0.05;
	e.drawmask = MASK_NORMAL;
	e.draw = ons_generator_ray_draw;
	IL_PUSH(g_drawables, e);
}

void generator_draw(entity this)
{
	if(time < this.move_time)
		return;

	if(GetResource(this, RES_HEALTH) > 0)
	{
		// damaged fx (less probable the more damaged is the generator)
		if(random() < 0.9 - GetResource(this, RES_HEALTH) / this.max_health)
		if(random() < 0.01)
		{
			pointparticles(EFFECT_ONS_ELECTRICITY_EXPLODE, this.origin + randompos('-50 -50 -20', '50 50 50'), '0 0 0', 1);
			sound(this, CH_TRIGGER, SND_ONS_ELECTRICITY_EXPLODE, VOL_BASE, ATTEN_NORM);
		}
		else
			pointparticles(EFFECT_ONS_GENERATOR_DAMAGED, this.origin + randompos('-60 -60 -20', '60 60 60'), '0 0 0', 1);

		this.move_time = time + 0.1;

		return;
	}

	if(this.count <= 0)
		return;

	vector org;
	int i;

	// White shockwave
	if(this.count==40||this.count==20)
	{
		sound(this, CH_TRIGGER, SND_ONS_SHOCKWAVE, VOL_BASE, ATTEN_NORM);
		pointparticles(EFFECT_ONS_SHOCKWAVE, this.origin, '0 0 0', 6);
	}

	// rays
	if(random() > 0.25)
	{
		ons_generator_ray_spawn(this.origin);
	}

	// Spawn fire balls
	for(i=0;i < 10;++i)
	{
		org = this.origin + randompos('-30 -30 -30' * i + '0 0 -20', '30 30 30' * i + '0 0 20');
		pointparticles(EFFECT_ONS_GENERATOR_GIB, org, '0 0 0', 1);
	}

	// Short explosion sound + small explosion
	if(random() < 0.25)
	{
		te_explosion(this.origin);
		sound(this, CH_TRIGGER, SND_ONS_GENERATOR_EXPLODE, VOL_BASE, ATTEN_NORM);
	}

	// Particles
	org = this.origin + randompos(this.mins + '8 8 8', this.maxs + '-8 -8 -8');
	pointparticles(EFFECT_ONS_GENERATOR_EXPLODE, org, '0 0 0', 1);

	// Final explosion
	if(this.count==1)
	{
		org = this.origin;
		te_explosion(org);
		pointparticles(EFFECT_ONS_GENERATOR_EXPLODE2, org, '0 0 0', 1);
		sound(this, CH_TRIGGER, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	}

	this.move_time = time + 0.05;

	this.count -= 1;
}

void generator_damage(entity this, float hp)
{
	if(hp <= 0)
		setmodel(this, MDL_ONS_GEN_DEAD);
	else if(hp < this.max_health * 0.10)
		setmodel(this, MDL_ONS_GEN9);
	else if(hp < this.max_health * 0.20)
		setmodel(this, MDL_ONS_GEN8);
	else if(hp < this.max_health * 0.30)
		setmodel(this, MDL_ONS_GEN7);
	else if(hp < this.max_health * 0.40)
		setmodel(this, MDL_ONS_GEN6);
	else if(hp < this.max_health * 0.50)
		setmodel(this, MDL_ONS_GEN5);
	else if(hp < this.max_health * 0.60)
		setmodel(this, MDL_ONS_GEN4);
	else if(hp < this.max_health * 0.70)
		setmodel(this, MDL_ONS_GEN3);
	else if(hp < this.max_health * 0.80)
		setmodel(this, MDL_ONS_GEN2);
	else if(hp < this.max_health * 0.90)
		setmodel(this, MDL_ONS_GEN1);
	else if(hp <= this.max_health || hp >= this.max_health)
		setmodel(this, MDL_ONS_GEN);

	setsize(this, GENERATOR_MIN, GENERATOR_MAX);
}

void generator_construct(entity this, bool isnew)
{
	this.netname = "Generator";
	this.classname = "onslaught_generator";

	if(isnew)
	{
		IL_PUSH(g_onsgenerators, this);
		IL_PUSH(g_drawables, this);
	}

	setorigin(this, this.origin);
	setmodel(this, MDL_ONS_GEN);
	this.solid			= SOLID_BBOX; // before setsize to ensure area grid linking
	setsize(this, GENERATOR_MIN, GENERATOR_MAX);

	set_movetype(this, MOVETYPE_NOCLIP);
	set_movetype(this, MOVETYPE_NOCLIP);
	this.move_time		= time;
	this.drawmask		= MASK_NORMAL;
	this.alpha			= 1;
	this.draw			= generator_draw;
}

.vector glowmod;
void generator_changeteam(entity this)
{
	if(this.team)
	{
		this.glowmod = Team_ColorRGB(this.team - 1);
		this.teamradar_color = Team_ColorRGB(this.team - 1);
		this.colormap = 1024 + (this.team - 1) * 17;
	}
	else
	{
		this.colormap = 1024;
		this.glowmod = '1 1 0';
		this.teamradar_color = '1 1 0';
	}
}

NET_HANDLE(ENT_CLIENT_GENERATOR, bool isnew)
{
	return = true;
	int sf = ReadByte();

	if(sf & GSF_SETUP)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);

		SetResourceExplicit(this, RES_HEALTH, ReadByte());
		this.max_health = ReadByte();
		this.count = ReadByte();
		this.team = ReadByte();

		if(!this.count)
			this.count = 40;

		generator_changeteam(this);
		generator_construct(this, isnew);
	}

	if(sf & GSF_STATUS)
	{
		int _tmp;
		_tmp = ReadByte();
		if(_tmp != this.team)
		{
			this.team = _tmp;
			generator_changeteam(this);
		}

		_tmp = ReadByte();

		if(_tmp != GetResource(this, RES_HEALTH))
			generator_damage(this, _tmp);

		SetResourceExplicit(this, RES_HEALTH, _tmp);
	}
}
