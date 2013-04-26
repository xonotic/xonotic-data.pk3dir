string mid2info_model;
string mid2info_name;
vector mid2info_min;
vector mid2info_max;

float monster_precached[MONSTER_LAST];
void monster_mid2info(float _mid);

void monster_precache(float _mid)
{    
    monster_mid2info(_mid);
    if(monster_precached[_mid])
        return;

    switch(_mid)
    {
        case MONSTER_ZOMBIE:
		{
			precache_model(ZOMBIE_MODEL);
			break;
		}
		case MONSTER_OGRE:
		{
			precache_model(OGRE_MODEL);
			break;
		}
		case MONSTER_DEMON:
		{
			precache_model(DEMON_MODEL);
			break;
		}
		case MONSTER_SHAMBLER:
		{
			precache_model(SHAMBLER_MODEL);
			break;
		}
		case MONSTER_KNIGHT:
		{
			precache_model(KNIGHT_MODEL);
			break;
		}
		case MONSTER_MARINE:
		{
			precache_model(SOLDIER_MODEL);
			precache_sound("weapons/shotgun_fire.wav");
			precache_sound("weapons/uzi_fire.wav");
			precache_sound("weapons/laser_fire.wav");
			precache_sound("weapons/reload.wav");
			precache_model("models/weapons/v_seeker.md3");
			break;
		}
		case MONSTER_SCRAG:
		{
			precache_model(WIZARD_MODEL);
			break;
		}
		case MONSTER_DOG:
		{
			precache_model(DOG_MODEL);
			break;
		}
		case MONSTER_TARBABY:
		{
			precache_model(TARBABY_MODEL);
			precache_sound("weapons/rocket_impact.wav");
			break;
		}
		case MONSTER_HELLKNIGHT:
		{
			precache_model(HELLKNIGHT_MODEL);
			break;
		}
		case MONSTER_FISH:
		{
			precache_model(FISH_MODEL);
			break;
		}
		case MONSTER_MAGE:
		{
			precache_model(SHALRATH_MODEL);
			break;
		}
		case MONSTER_SPIDER:
		{
			precache_model(SPIDER_MODEL);

			break;
		}
    }    
    monster_precached[_mid] = TRUE;
}

void Monsters_Precache()
{
	float i;
	for(i = MONSTER_FIRST + 1; i < MONSTER_LAST; ++i)
		monster_precache(i);
}

void monster_mid2info(float _mid)
{
	switch(_mid)
	{
		case MONSTER_ZOMBIE:
		{
			mid2info_model = ZOMBIE_MODEL;
			mid2info_name = "Zombie";
			mid2info_min = ZOMBIE_MIN;
			mid2info_max = ZOMBIE_MAX;
			break;
		}
		case MONSTER_OGRE:
		{
			mid2info_model = OGRE_MODEL;
			mid2info_name = "Ogre";
			mid2info_min = OGRE_MIN;
			mid2info_max = OGRE_MAX;
			break;
		}
		case MONSTER_DEMON:
		{
			mid2info_model = DEMON_MODEL;
			mid2info_name = "Fiend";
			mid2info_min = DEMON_MIN;
			mid2info_max = DEMON_MAX;
			if(self) self.scale = 1.3;
			break;
		}
		case MONSTER_SHAMBLER:
		{
			mid2info_model = SHAMBLER_MODEL;
			mid2info_name = "Shambler";
			mid2info_min = SHAMBLER_MIN;
			mid2info_max = SHAMBLER_MAX;
			if(self) self.scale = 1.3;
			break;
		}
		case MONSTER_KNIGHT:
		{
			mid2info_model = KNIGHT_MODEL;
			mid2info_name = "Knight";
			mid2info_min = KNIGHT_MIN;
			mid2info_max = KNIGHT_MAX;
			if(self) self.scale = 1.3;
			break;
		}
		case MONSTER_MARINE:
		{
			mid2info_model = SOLDIER_MODEL;
			mid2info_name = "Marine";
			mid2info_min = SOLDIER_MIN;
			mid2info_max = SOLDIER_MAX;
			break;
		}
		case MONSTER_SCRAG:
		{
			mid2info_model = WIZARD_MODEL;
			mid2info_name = "Scrag";
			mid2info_min = WIZARD_MIN;
			mid2info_max = WIZARD_MAX;
			if(self) self.scale = 1.3;
			break;
		}
		case MONSTER_DOG:
		{
			mid2info_model = DOG_MODEL;
			mid2info_name = "Cerberus";
			mid2info_min = DOG_MIN;
			mid2info_max = DOG_MAX;
			break;
		}
		case MONSTER_TARBABY:
		{
			mid2info_model = TARBABY_MODEL;
			mid2info_name = "Spawn";
			mid2info_min = TARBABY_MIN;
			mid2info_max = TARBABY_MAX;
			break;
		}
		case MONSTER_HELLKNIGHT:
		{
			mid2info_model = HELLKNIGHT_MODEL;
			mid2info_name = "Hell-Knight";
			mid2info_min = HELLKNIGHT_MIN;
			mid2info_max = HELLKNIGHT_MAX;
			if(self) self.scale = 1.3;
			break;
		}
		case MONSTER_FISH:
		{
			mid2info_model = FISH_MODEL;
			mid2info_name = "Rotfish";
			mid2info_min = FISH_MIN;
			mid2info_max = FISH_MAX;
			if(self) self.scale = 1.3;
			break;
		}
		case MONSTER_MAGE:
		{
			mid2info_model = SHALRATH_MODEL;
			mid2info_name = "Mage";
			mid2info_min = SHALRATH_MIN;
			mid2info_max = SHALRATH_MAX;
			break;
		}
		case MONSTER_SPIDER:
		{
			mid2info_model = SPIDER_MODEL;
			mid2info_name = "Spider";
			mid2info_min = SPIDER_MIN;
			mid2info_max = SPIDER_MAX;
			break;
		}
		default:
		{
			dprint("WARNING: Unknown monster in CSQC\n");
			break;
		}
	}	
}

.vector glowmod;
void monster_changeteam()
{ 	
	self.glowmod = Team_ColorRGB(self.team - 1);
	self.teamradar_color = Team_ColorRGB(self.team - 1);
	
	if(self.team)
		self.colormap = 1024 + (self.team - 1) * 17;
}

void monster_die()
{
	if(self.monsterid == MONSTER_SPIDER)
		self.angles += '180 0 0';
		
	self.solid = SOLID_CORPSE;
}

void monster_draw()
{        
    float dt;
            
    dt = time - self.move_time;
    self.move_time = time;
    if(dt <= 0)
        return;
    
    fixedmakevectors(self.angles);
    //movelib_groundalign4point(300, 100, 0.25, 45);
    setorigin(self, self.origin + self.velocity * dt);
    self.angles_y = self.move_angles_y;  
}

void monster_construct()
{	
	monster_mid2info(self.monsterid);
	self.netname = mid2info_name;

	setorigin(self, self.origin);
	setmodel(self, mid2info_model);
	setsize(self, mid2info_min, mid2info_max);
	
	self.move_movetype	= MOVETYPE_BOUNCE;
	self.health			= 255;
	self.solid			= SOLID_BBOX;
	self.movetype		= MOVETYPE_BOUNCE; 
	self.move_origin	= self.origin;
	self.move_time		= time;
	self.drawmask		= MASK_NORMAL;  
	self.alpha			= 1;
	self.draw			= monster_draw;
}

void ent_monster()
{
	float sf;
	sf = ReadByte();

	if(sf & MSF_SETUP)
	{
		self.monsterid = ReadByte();
				
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
		
		self.angles_x = ReadAngle();
		self.angles_y = ReadAngle();
		
		self.skin = ReadByte();
		
		monster_precache(self.monsterid);
		monster_construct();
		self.colormap = 1024;
		self.glowmod = '0 1 1'; 
	}
	
	if(sf & MSF_ANG)
	{
		self.move_angles_x = ReadShort();
		self.move_angles_y = ReadShort();
		self.angles = self.move_angles;
	}
	
	if(sf & MSF_MOVE)
	{
		self.origin_x = ReadShort();
		self.origin_y = ReadShort();
		self.origin_z = ReadShort();
		setorigin(self, self.origin);
		
		self.velocity_x = ReadShort();
		self.velocity_y = ReadShort();
		self.velocity_z = ReadShort();
		
		self.move_angles_y = ReadShort();
			
		self.move_time	 = time;
		self.move_velocity = self.velocity;
		self.move_origin   = self.origin;
	}
		
	if(sf & MSF_ANIM)
	{
		self.frame1time = ReadCoord();
		self.frame	  = ReadByte();
	}

	if(sf & MSF_STATUS)
	{
		self.skin = ReadByte();
	
		float _tmp;
		_tmp = ReadByte();
		if(_tmp != self.team)
		{			
			self.team = _tmp;				
			monster_changeteam();
		}
		
		_tmp = ReadByte();
		if(_tmp == 4) // respawning
			setmodel(self, "null");
		
		_tmp = ReadByte();
		
		if(_tmp == 0 && self.health != 0)
			monster_die();

		self.health = _tmp;
	}
}
