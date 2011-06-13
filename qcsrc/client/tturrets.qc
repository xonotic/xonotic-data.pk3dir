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

//.entity tur_base;
void turret_remove()
{
    entity th;
    dprint("Removing turret type ", ftos(self.turret_type), "\n");
    th = self.tur_head;
    self.tur_head = world;
    remove(th);
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
    float dt;
    dt = time - self.move_time;
    self.move_time = time;
    if(dt <= 0)
        return;
    
    self.angles += dt * self.move_avelocity;    
    self.drawmask = MASK_NORMAL;
}

void turret_draw()
{
    //float dt;
    
    if (self.health < 127)
    if(random() < 0.25)
        te_spark(self.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);
    
    self.drawmask = MASK_NORMAL;    
}

//void(entity e, entity tagentity, string tagname) setattachment = #443;
void turret_construct()
{
    string sbase, shead;
    vector _min, _max;
    
    if(self.tur_head == world)
        self.tur_head = spawn();
    
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
            _min = '-34 -34 0';
            _max = '34 34 90';
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
            _min = '-60 -60 0';
            _max  ='60 60 128';
            break;
        case TID_WALKER:
            sbase = "models/turrets/walker_body.md3";
            shead = "models/turrets/walker_head_minigun.md3";
            _min = '-70 -70 0';
            _max = '70 70 95';
            break;
    }
    
    setorigin(self, self.origin);
        
    self.tur_head.classname = "turret_head";
    self.tur_head.owner   = self;

    setmodel(self, sbase);
    setmodel(self.tur_head, shead);
    
    self.tur_head.move_movetype = MOVETYPE_NOCLIP;
    self.move_movetype = MOVETYPE_NOCLIP;
    
    setsize(self, _min, _max);
    setsize(self.tur_head, '0 0 0', '0 0 0');
    
    setorigin(self.tur_head, gettaginfo(self, gettagindex(self, "tag_head")));
    self.health             = 255;
    self.solid              = SOLID_BBOX;
    self.tur_head.solid     = SOLID_NOT;
    self.movetype           = MOVETYPE_NOCLIP;
    self.tur_head.movetype  = MOVETYPE_NOCLIP;    
    self.draw               = turret_draw;
    self.tur_head.draw      = turret_head_draw;
    self.entremove          = turret_remove;
}

void ent_turret()
{
    float sf;
    sf = ReadByte();

	if(sf & TNSF_SETUP)
	{	    
	    self.turret_type = ReadByte();
	    dprint("Constructing turret type ", ftos(self.turret_type), "\n");
	    	    
	    self.origin_x = ReadCoord();
	    self.origin_y = ReadCoord();
	    self.origin_z = ReadCoord();
	    
	    self.angles_x = ReadAngle();
	    self.angles_y = ReadAngle();
	    
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
    }
}
