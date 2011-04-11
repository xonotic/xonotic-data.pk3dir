void turrets_precache()
{
    precache_model ("models/turrets/ewheel-base2.md3");
    precache_model ("models/turrets/ewheel-gun1.md3");
    precache_model ("models/turrets/base.md3");
    precache_model ("models/turrets/flac.md3");
    precache_model ("models/turrets/reactor.md3");
    precache_model ("models/turrets/hellion.md3");
    precache_model ("models/turrets/hk.md3");
    precache_model ("models/turrets/machinegun.md3");
    precache_model ("models/turrets/mlrs.md3");
    precache_model ("models/turrets/phaser.md3");
    precache_model ("models/turrets/phaser_beam.md3");
    precache_model ("models/turrets/plasma.md3");
    precache_model ("models/turrets/plasmad.md3");
    precache_model ("models/turrets/tesla_head.md3");
    precache_model ("models/turrets/tesla_base.md3");
    precache_model ("models/turrets/walker_head_minigun.md3");
    precache_model ("models/turrets/walker_body.md3");
    precache_model ("models/turrets/walker_props.md3");
    precache_model ("models/turrets/walker_spawn.md3");
    precache_model ("models/turrets/rocket.md3");
    
    precache_sound ("turrets/phaser.wav");
    precache_sound ("weapons/rocket_impact.wav");
    precache_sound ("weapons/uzi_fire.wav");
}


void turret_remove()
{
    remove(self.tur_head);
}

void turret_changeteam()
{
	self.colormod = '0 0 0';
	switch(self.team)
	{
        case COLOR_TEAM1: // Red
            self.colormod = '1.4 0.8 0.8';
            break;

        case COLOR_TEAM2: // Blue
            self.colormod = '0.8 0.8 1.4';
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
    self.drawmask = MASK_NORMAL;    
}

void(entity e, entity tagentity, string tagname) setattachment = #443;
.entity tur_base;
void turret_construct()
{
    string sbase, shead;
    vector _min, _max;
    
    self.tur_head = spawn();
    self.tur_base = spawn();
    
    sbase = "models/turrets/base.md3";
    _min = '-32 -32 0';
    _max = '32 32 64';
    
    switch(self.turret_type)
    {
        case TID_EWHEEL:
            sbase = "models/turrets/ewheel-base2.md3";
            shead = "models/turrets/ewheel-gun1.md3";
            break;
        case TID_FLAC:
            shead = "models/turrets/flac.md3";
            break;
        case TID_FUSION:
            shead = "models/turrets/reactor.md3";
            break;
        case TID_HELLION:
            shead = "models/turrets/hellion.md3";
            break;
        case TID_HK:
            shead = "models/turrets/hk.md3";
            break;
        case TID_MACHINEGUN:
            shead = "models/turrets/machinegun.md3";
            break;
        case TID_MLRS:
            shead = "models/turrets/mlrs.md3";
            break;
        case TID_PHASER:
            shead = "models/turrets/phaser.md3";
            break;
        case TID_PLASMA:
            shead = "models/turrets/plasma.md3";
            break;
        case TID_PLASMA_DUAL:
            shead = "models/turrets/plasmad.md3";
            break;
        case TID_TESLA:
            sbase = "models/turrets/tesla_base.md3";
            shead = "models/turrets/tesla_head.md3";
            break;
        case TID_WALKER:
            sbase = "models/turrets/walker_body.md3";
            shead = "models/turrets/walker_head_minigun.md3";
            break;
    }
    
    setorigin(self, self.origin);
    setorigin(self.tur_base, self.origin);
    
    self.tur_head.classname = "turret_head";
    self.tur_head.owner   = self;
    self.tur_base.owner   = self;

    setmodel(self.tur_base, sbase);
    setmodel(self.tur_head, shead);

    setsize(self.tur_base, _min, _max);
    setsize(self.tur_head, '0 0 0', '0 0 0');
    //setattachment(self.tur_head, self.tur_base, "tag_head");
    setorigin(self.tur_head, self.origin + '0 0 32');
    self.health = 255;

    self.solid               = SOLID_BBOX;
    self.tur_head.solid      = SOLID_NOT;
    //self.takedamage          = DAMAGE_AIM;
    self.tur_base.movetype            = MOVETYPE_NOCLIP;
    self.tur_head.movetype   = MOVETYPE_NOCLIP;    
    self.tur_base.draw = turret_draw;
    self.tur_head.draw = turret_head_draw;
    self.entremove = turret_remove;
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
	    
	    turret_construct();
    }
    
    if(sf & TNSF_ANG)
    {
        self.tur_head.angles_x = ReadAngle();
        self.tur_head.angles_y = ReadAngle();
    }
    
    if(sf & TNSF_AVEL)
    {        
        self.tur_head.avelocity_x = ReadAngle();
        self.tur_head.avelocity_y = ReadAngle();
    }
    
    if(sf & TNSF_STATUS)
    {
        float _team;
        _team = ReadByte();
        self.health = ReadByte();
        if(_team != self.team)
        {
            self.team = _team;
            turret_changeteam();        
        }
    }
}