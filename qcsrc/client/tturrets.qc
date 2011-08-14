string tid2info_base;
string tid2info_head;
string tid2info_name;
vector  tid2info_min;
vector  tid2info_max;

void turret_tid2info(float _tid);
void turret_precache(float _tid);
float turret_is_precache[TID_LAST];

void turrets_precache()
{
    turret_precache(TID_COMMON);
}

void turret_precache(float _tid)
{    
    if (!turret_is_precache[TID_COMMON])
    {
        dprint("turret_precache TID_COMMON\n");
        precache_sound ("weapons/rocket_impact.wav");
        precache_model ("models/turrets/base-gib1.md3");
        precache_model ("models/turrets/base-gib2.md3");
        precache_model ("models/turrets/base-gib3.md3");
        precache_model ("models/turrets/base-gib4.md3");
        precache_model ("models/turrets/head-gib1.md3");
        precache_model ("models/turrets/head-gib2.md3");
        precache_model ("models/turrets/head-gib3.md3");
        precache_model ("models/turrets/head-gib4.md3");
        precache_model ("models/turrets/terrainbase.md3");
        precache_model ("models/turrets/base.md3");
        precache_model ("models/turrets/rocket.md3");
    }
    turret_tid2info(_tid);
    if(turret_is_precache[_tid])
    {
        dprint("turret_precache: ", tid2info_name, " allready precachd, skipping.\n");
        return;
    }
    else
        dprint("turret_precache: ", tid2info_name, " precaching.\n");

    switch(_tid)
    {
        case TID_EWHEEL:
            precache_model ("models/turrets/ewheel-base2.md3");
            precache_model ("models/turrets/ewheel-gun1.md3");            
            break;
        case TID_FLAC:
            precache_model ("models/turrets/flac.md3");
            break;
        case TID_FUSION:
            precache_model ("models/turrets/reactor.md3");    
            break;
        case TID_HELLION:
            precache_model ("models/turrets/hellion.md3");
            break;
        case TID_HK:
            precache_model ("models/turrets/hk.md3");
            break;
        case TID_MACHINEGUN:
            precache_model ("models/turrets/machinegun.md3");
            precache_sound ("weapons/uzi_fire.wav");
            break;
        case TID_MLRS:
            precache_model ("models/turrets/mlrs.md3");
            break;
        case TID_PHASER:
            precache_model ("models/turrets/phaser.md3");
            precache_model ("models/turrets/phaser_beam.md3");
            precache_sound ("turrets/phaser.wav");
            break;
        case TID_PLASMA:
            precache_model ("models/turrets/plasma.md3");
            break;
        case TID_PLASMA_DUAL:
            precache_model ("models/turrets/plasmad.md3");
            break;
        case TID_TESLA:
            precache_model ("models/turrets/tesla_head.md3");
            precache_model ("models/turrets/tesla_base.md3");
            break;
        case TID_WALKER:
            precache_model ("models/turrets/walker_head_minigun.md3");
            precache_model ("models/turrets/walker_body.md3");
            precache_sound ("weapons/uzi_fire.wav");
            break;
    }    
    turret_is_precache[_tid] = TRUE;
}

void turret_tid2info(float _tid)
{
    tid2info_base = "models/turrets/base.md3";
    tid2info_min = '-32 -32 0';
    tid2info_max = '32 32 64';

    switch(_tid)
    {
        case TID_EWHEEL:
            tid2info_base = "models/turrets/ewheel-base2.md3";
            tid2info_head = "models/turrets/ewheel-gun1.md3";
            tid2info_name = "eWheel";
            break;
        case TID_FLAC:
            tid2info_head = "models/turrets/flac.md3";
            tid2info_name = "Flac Cannon";
            break;
        case TID_FUSION:
            tid2info_head = "models/turrets/reactor.md3";
            tid2info_name = "Fusion Reactor";
            tid2info_min = '-34 -34 0';
            tid2info_max = '34 34 90';
            break;
        case TID_HELLION:
            tid2info_head = "models/turrets/hellion.md3";
            tid2info_name = "Hellion";
            break;
        case TID_HK:
            tid2info_head = "models/turrets/hk.md3";
            tid2info_name = "Hunter-Killer";
            break;
        case TID_MACHINEGUN:
            tid2info_head = "models/turrets/machinegun.md3";
            tid2info_name = "Machinegun";
            break;
        case TID_MLRS:
            tid2info_head = "models/turrets/mlrs.md3";
            tid2info_name = "MLRS";
            break;
        case TID_PHASER:
            tid2info_head = "models/turrets/phaser.md3";
            tid2info_name = "Phaser";
            break;
        case TID_PLASMA:
            tid2info_head = "models/turrets/plasma.md3";
            tid2info_name = "Plasma";
            break;
        case TID_PLASMA_DUAL:
            tid2info_head = "models/turrets/plasmad.md3";
            tid2info_name = "Dual Plasma";
            break;
        case TID_TESLA:
            tid2info_base = "models/turrets/tesla_base.md3";
            tid2info_head = "models/turrets/tesla_head.md3";
            tid2info_name = "Tesla coil";
            tid2info_min = '-60 -60 0';
            tid2info_max  ='60 60 128';
            break;
        case TID_WALKER:
            tid2info_base = "models/turrets/walker_body.md3";
            tid2info_head = "models/turrets/walker_head_minigun.md3";
            tid2info_name = "Walker";
            tid2info_min = '-70 -70 0';
            tid2info_max = '70 70 95';
            break;
    }    
}

void turret_remove()
{
    turret_tid2info(self.turret_type);
    dprint("Removing ", tid2info_name, " turrret.\n");
    
    remove(self.tur_head);
    self.tur_head = world;    
}

void turret_changeteam()
{
	self.colormod = '0 0 0';
	
	switch(self.team)
	{
        case COLOR_TEAM1: // Red
            self.colormod = '2 0.5 0.5';
            break;

        case COLOR_TEAM2: // Blue
            self.colormod = '0.5 0.5 2';
            break;

        case COLOR_TEAM3: // Yellow
            self.colormod = '1.4 1.4 0.6';
            break;

        case COLOR_TEAM4: // Pink
            self.colormod = '1.4 0.6 1.4';
            break;
	}
	
	self.tur_head.colormod = self.colormod;    
}

void turret_head_draw()
{    
    self.drawmask = MASK_NORMAL;
}

void turret_draw()
{        
    float dt;

    dt = time - self.move_time;
    self.move_time = time;
    if(dt <= 0)
        return;
    
    self.tur_head.angles += dt * self.tur_head.move_avelocity;

    if (self.health < 127)
    {
        dt = random();
        
        if(dt < 0.25)
            te_spark(self.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);    
        
    }
    
    if(self.health < 85)    
    if(dt < 0.1)
        pointparticles(particleeffectnum("smoke_small"), (self.origin + (randomvec() * 80)), '0 0 0', 1);        
    
    if(self.health < 32)
    if(dt < 0.1)
        pointparticles(particleeffectnum("smoke_large"), (self.origin + (randomvec() * 80)), '0 0 0', 1);        
    
}

void turret_walker_draw()
{        
    float dt;
            
    dt = time - self.move_time;
    self.move_time = time;
    if(dt <= 0)
        return;
    
    fixedmakevectors(self.angles);
    movelib_groundalign4point(300, 100, 0.25);
    
    setorigin(self, self.origin + self.velocity * dt);
    setorigin(self.tur_head, gettaginfo(self, gettagindex(self, "tag_head")));
    
    self.tur_head.angles += dt * self.tur_head.move_avelocity;
    
    self.angles_y = self.move_angles_y;
    
    if (self.health < 127)
    if(random() < 0.25)
        te_spark(self.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);    
}

void turret_ewheel_draw()
{        
    float dt;
            
    dt = time - self.move_time;
    self.move_time = time;
    if(dt <= 0)
        return;
    
    fixedmakevectors(self.angles);
    movelib_groundalign4point(300, 100, 0.25);
    
    setorigin(self, self.origin + self.velocity * dt);
    setorigin(self.tur_head, self.origin);
    
    self.tur_head.angles += dt * self.tur_head.move_avelocity;
    
    // Simulate banking
    //self.angles_z -= self.angles_z * dt * 2;
    //self.angles_z = bound(-45, self.angles_z  + ((self.move_angles_y - self.angles_y * -25) * dt), 45);
    
    self.angles_y = self.move_angles_y;
    
    if (self.health < 127)
    if(random() < 0.25)
        te_spark(self.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);    
}

void turret_construct()
{    
    if(self.tur_head == world)
        self.tur_head = spawn();
    
    turret_tid2info(self.turret_type);
    dprint("Constructing ", tid2info_name , " turret (", ftos(self.turret_type), ")\n");

    setorigin(self, self.origin);
    setmodel(self, tid2info_base);
    setmodel(self.tur_head, tid2info_head);
    setsize(self, tid2info_min, tid2info_max);
    setsize(self.tur_head, '0 0 0', '0 0 0');
    setorigin(self.tur_head, gettaginfo(self, gettagindex(self, "tag_head")));

    self.tur_head.classname     = "turret_head";
    self.tur_head.owner         = self;
    self.tur_head.move_movetype = MOVETYPE_NOCLIP;
    self.move_movetype          = MOVETYPE_NOCLIP;
    self.tur_head.angles        = self.angles;
    self.health                 = 255;
    self.solid                  = SOLID_BBOX;
    self.tur_head.solid         = SOLID_NOT;
    self.movetype               = MOVETYPE_NOCLIP;
    self.tur_head.movetype      = MOVETYPE_NOCLIP;    
    self.draw                   = turret_draw;
    self.entremove              = turret_remove;
    self.drawmask = MASK_NORMAL;
    self.tur_head.drawmask = MASK_NORMAL;

    if(self.turret_type == TID_EWHEEL || self.turret_type == TID_WALKER)
    {
        self.gravity            = 1;
        self.movetype           = MOVETYPE_BOUNCE;
        self.move_movetype      = MOVETYPE_BOUNCE;
        self.move_origin        = self.origin;                
        self.move_time          = time;
        switch(self.turret_type)
        {
            case TID_EWHEEL:
                self.draw               = turret_ewheel_draw;
                break;
            case TID_WALKER:
                self.draw               = turret_walker_draw;
        }        
    }
}

entity turret_gibtoss(string _model, vector _from, vector _to, vector _cmod, float _explode);
void turret_gibboom();
void turret_gib_draw()
{
    Movetype_Physics_MatchTicrate(autocvar_cl_gibs_ticrate, autocvar_cl_gibs_sloppy);
    
    self.drawmask = MASK_NORMAL;
	
	if(self.cnt)
	{
	    if(time >= self.nextthink)
	    {
            turret_gibboom();
            remove(self);
	    }
	}
	else
	{
        self.alpha = bound(0, self.nextthink - time, 1);
        if(self.alpha < ALPHA_MIN_VISIBLE)
            remove(self);	    
	}
}

void turret_gibboom()
{
    float i;
    
    sound (self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);

    for (i = 1; i < 5; i = i + 1)
        turret_gibtoss(strcat("models/turrets/head-gib", ftos(i), ".md3"), self.origin, self.velocity + randomvec() * 700, '0 0 0', FALSE);
}

entity turret_gibtoss(string _model, vector _from, vector _to, vector _cmod, float _explode)
{
    entity gib;

    gib = spawn();
    setorigin(gib, _from);
    setmodel(gib, _model);
    gib.colormod    = _cmod;
	gib.solid       = SOLID_CORPSE;
    gib.draw        = turret_gib_draw;    
    gib.cnt         = _explode;
    
    if(_explode)
    {
        gib.nextthink = time + 0.2 * (autocvar_cl_gibs_lifetime * (1 + prandom() * 0.15));
        gib.effects = EF_FLAME;
    }        
    else
        gib.nextthink = time + autocvar_cl_gibs_lifetime * (1 + prandom() * 0.15);
    
    gib.gravity         = 1;
	gib.move_movetype   = MOVETYPE_BOUNCE;
	gib.move_origin     = gib.origin = _from;
	gib.move_velocity   = _to;	
	gib.move_avelocity  = prandomvec() * 32;
	gib.move_time       = time;
	gib.damageforcescale = 1;
	
	return gib;
}

void turret_die()
{    
    entity headgib;
    
    setmodel(self, "");
    setmodel(self.tur_head, "");
    sound (self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
    turret_tid2info(self.turret_type);
    dprint("Turret ", tid2info_name, " dies.\n");
    
    // Base
    if(self.turret_type == TID_EWHEEL)
        turret_gibtoss(tid2info_base, self.origin, self.velocity, '-1 -1 -1', FALSE);
    else if (self.turret_type == TID_WALKER)
        turret_gibtoss(tid2info_base, self.origin, self.velocity, '-1 -1 -1', FALSE);
    else if (self.turret_type == TID_TESLA)
        turret_gibtoss(tid2info_base, self.origin, self.velocity, '-1 -1 -1', FALSE);
    else
    {        
        if (random() > 0.5)
        {
            turret_gibtoss("models/turrets/base-gib2.md3", self.origin + '0 0 2', '0 0 50' + randomvec() * 150, '0 0 0', FALSE);
            turret_gibtoss("models/turrets/base-gib3.md3", self.origin + '0 0 2', '0 0 50' + randomvec() * 150, '0 0 0', FALSE);
            turret_gibtoss("models/turrets/base-gib4.md3", self.origin + '0 0 2', '0 0 50' + randomvec() * 150, '0 0 0', FALSE);
        }
        else
            turret_gibtoss("models/turrets/base-gib1.md3", self.origin + '0 0 4', '0 0 0', '0 0 0', TRUE);
    }
    
    headgib = turret_gibtoss(tid2info_head, self.origin + '0 0 32', '0 0 200' + randomvec() * 200, '-1 -1 -1', TRUE);
    headgib.angles = headgib.move_angles = self.tur_head.angles;
    headgib.avelocity = headgib.move_avelocity = self.tur_head.move_avelocity + randomvec() * 45;
    headgib.avelocity_y = headgib.move_avelocity_y = headgib.move_avelocity_y * 5;
    headgib.gravity = 0.5;
}

void ent_turret()
{
    float sf;
    sf = ReadByte();

	if(sf & TNSF_SETUP)
	{	    
	    self.turret_type = ReadByte();
	    	    
	    self.origin_x = ReadCoord();
	    self.origin_y = ReadCoord();
	    self.origin_z = ReadCoord();
	    
	    self.angles_x = ReadAngle();
	    self.angles_y = ReadAngle();
	    
	    turret_precache(self.turret_type);
	    turret_construct();
    }
    
    if(sf & TNSF_ANG)
    {
        self.tur_head.move_angles_x = ReadShort();
        self.tur_head.move_angles_y = ReadShort();
        self.tur_head.angles = self.angles + self.tur_head.move_angles;
    }
    
    if(sf & TNSF_AVEL)
    {
        self.tur_head.move_avelocity_x = ReadShort();
        self.tur_head.move_avelocity_y = ReadShort();            
    }
    
    if(sf & TNSF_MOVE)
    {
        self.origin_x = ReadShort();
        self.origin_y = ReadShort();
        self.origin_z = ReadShort();
        setorigin(self, self.origin);
        
        self.velocity_x = ReadShort();
        self.velocity_y = ReadShort();
        self.velocity_z = ReadShort();
        
        self.move_angles_y = ReadShort();
            
        self.move_time     = time;
        self.move_velocity = self.velocity;
        self.move_origin   = self.origin;
    }
        
    if(sf & TNSF_ANIM)
    {
        self.frame1time = ReadCoord();
        self.frame      = ReadByte();
    }

    if(sf & TNSF_STATUS)
    {
        float _team;
        _team = ReadByte();
        _team -= 1; // /&)=(%&#)&%)/#&)=½!!!½!!". thanks.
        self.health = ReadByte();
        if(_team != self.team)
        {
            self.team = _team;
            turret_changeteam();        
        }
        
        if(self.health == 0)
            turret_die();
    } 
    
}
