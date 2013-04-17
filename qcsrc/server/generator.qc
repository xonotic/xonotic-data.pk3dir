#ifdef CSQC
void generator_precache()
{
	precache_model("models/onslaught/generator.md3");
	precache_model("models/onslaught/generator_dead.md3");
	precache_sound("onslaught/generator_underattack.wav");
}

void generator_die()
{
	setmodel(self, "models/onslaught/generator_dead.md3");
}

void generator_draw() { } // TODO

void generator_construct()
{	
	self.netname = "Generator";

	setorigin(self, self.origin);
	setmodel(self, "models/onslaught/generator.md3");
	setsize(self, GENERATOR_MIN, GENERATOR_MAX);
	
	self.move_movetype	= MOVETYPE_NOCLIP;
	self.health			= 255;
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
{ 	
	switch(self.team - 1)
	{
		case NUM_TEAM_1: // Red
		{
			self.glowmod = '2 0 0';
			self.teamradar_color = '1 0 0';
			break;
		}
		case NUM_TEAM_2: // Blue
		{
			self.glowmod = '0 0 2';
			self.teamradar_color = '0 0 1';
			break;
		}
		case NUM_TEAM_3: // Yellow
		{
			self.glowmod = '1 1 0';
			self.teamradar_color = '1 1 0';
			break;
		}
		case NUM_TEAM_4: // Pink
		{
			self.glowmod = '1 0 1';
			self.teamradar_color = '1 0 1';
			break;
		}
	}
	
	if(self.team)
		self.colormap = 1024 + (self.team - 1) * 17;
}

void ent_generator()
{
	float sf;
	sf = ReadByte();

	if(sf & GSF_SETUP)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
		
		generator_precache();
		generator_construct();
		self.colormap = 1024;
		self.glowmod = '1 1 0'; 
	}

	if(sf & GSF_STATUS)
	{
		float _tmp;
		_tmp = ReadByte();
		if(_tmp != self.team)
		{			
			self.team = _tmp;				
			generator_changeteam();
		}
		
		_tmp = ReadByte();
		
		if(_tmp == 0 && self.health != 0)
			generator_die();

		self.health = _tmp;
	}
}
#endif // CSQC

#ifdef SVQC
float generator_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_GENERATOR);    
	WriteByte(MSG_ENTITY, sf);
	if(sf & GSF_SETUP)
	{
	    WriteCoord(MSG_ENTITY, self.origin_x);
	    WriteCoord(MSG_ENTITY, self.origin_y);
	    WriteCoord(MSG_ENTITY, self.origin_z);
    }
    
    if(sf & GSF_STATUS)
    {
		WriteByte(MSG_ENTITY, self.team);
	
        if(self.health <= 0)
            WriteByte(MSG_ENTITY, 0);
        else
            WriteByte(MSG_ENTITY, ceil((self.health / self.max_health) * 255));
    }
    
	return TRUE;
}

void generator_link(void() spawnproc)
{
    Net_LinkEntity(self, TRUE, 0, generator_send);
    self.think      = spawnproc;
    self.nextthink  = time;
}
#endif // SVQC
