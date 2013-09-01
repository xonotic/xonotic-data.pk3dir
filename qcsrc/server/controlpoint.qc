#ifdef CSQC
float controlpoint_precached;

void controlpoint_precache()
{
	if(controlpoint_precached)
		return; // already precached
		
	precache_model("models/onslaught/controlpoint_pad.md3");
	precache_model("models/onslaught/controlpoint_pad2.md3");
	
	controlpoint_precached = TRUE;
}

void controlpoint_draw()
{
}

void controlpoint_construct()
{
	self.netname = "Control Point";

	setorigin(self, self.origin);
	setmodel(self, "models/onslaught/controlpoint_pad.md3");
	setsize(self, CONTROLPOINT_MIN, CONTROLPOINT_MAX);
	
	self.move_movetype	= MOVETYPE_NOCLIP;
	self.solid			= SOLID_BBOX;
	self.movetype		= MOVETYPE_NOCLIP; 
	self.move_origin	= self.origin;
	self.move_time		= time;
	self.drawmask		= MASK_NORMAL;  
	self.alpha			= 1;
	self.draw			= controlpoint_draw;
	self.health			= 255;
}

.vector glowmod;
void controlpoint_changeteam()
{
	if(self.team)
	{
		self.glowmod = Team_ColorRGB(self.team - 1);
		self.teamradar_color = Team_ColorRGB(self.team - 1);
		self.colormap = 1024 + (self.team - 1) * 17;
		setmodel(self, "models/onslaught/controlpoint_pad2.md3");
		setsize(self, CONTROLPOINT_MIN, CONTROLPOINT_MAX);
	}
	else
	{
		self.colormap = 1024;
		self.glowmod = '1 1 0';
		self.teamradar_color = '1 1 0';
		setmodel(self, "models/onslaught/controlpoint_pad.md3");
		setsize(self, CONTROLPOINT_MIN, CONTROLPOINT_MAX);
	}
}

void ent_controlpoint()
{
	float sf;
	sf = ReadByte();

	if(sf & CPSF_SETUP)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
		
		self.team = ReadByte();
		
		if not(self.count)
			self.count = 40;
		
		controlpoint_changeteam();
		controlpoint_precache();
		controlpoint_construct();
	}

	if(sf & CPSF_STATUS)
	{
		float _tmp;
		_tmp = ReadByte();
		if(_tmp != self.team)
		{			
			self.team = _tmp;
			controlpoint_changeteam();
		}
	}
}
#endif // CSQC

#ifdef SVQC
float controlpoint_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_CONTROLPOINT);    
	WriteByte(MSG_ENTITY, sf);
	if(sf & CPSF_SETUP)
	{
	    WriteCoord(MSG_ENTITY, self.origin_x);
	    WriteCoord(MSG_ENTITY, self.origin_y);
	    WriteCoord(MSG_ENTITY, self.origin_z);
		
		WriteByte(MSG_ENTITY, self.team);
    }
    
    if(sf & CPSF_STATUS)
    {
		WriteByte(MSG_ENTITY, self.team);
    }
    
	return TRUE;
}

void controlpoint_link()
{
    Net_LinkEntity(self, TRUE, 0, controlpoint_send);
}
#endif // SVQC
