void Create_Effect_Entity(int eff_name, string eff_string, bool eff_trail)
{
	entity eff;
	effects_ent[eff_name - 1] = eff = spawn();

	eff.classname = "effect_entity";
	eff.eent_net_name = eff_name;
	eff.eent_eff_name = eff_string;
	eff.eent_eff_trail = eff_trail;
}

#ifdef CSQC
void Read_Effect(bool is_new)
{
#if EFFECTS_COUNT >= 255
	int net_name = ReadShort();
#else
	int net_name = ReadByte();
#endif

	entity eff = effects_ent[net_name - 1];

	vector v, vel = '0 0 0';
	int eff_cnt = 1;
	bool eff_trail = eff.eent_eff_trail;
	v_x = ReadCoord();
	v_y = ReadCoord();
	v_z = ReadCoord();

	bool use_vel = ReadByte();
	if(use_vel)
	{
		vel_x = ReadCoord();
		vel_y = ReadCoord();
		vel_z = ReadCoord();
	}
	
	if(!eff_trail)
		eff_cnt = ReadByte();

	if(is_new)
	{
		if(eff_trail)
			WarpZone_TrailParticles(world, particleeffectnum(eff.eent_eff_name), v, vel);
		else
			pointparticles(particleeffectnum(eff.eent_eff_name), v, vel, eff_cnt);
	}
}
#endif

#ifdef SVQC
bool Net_Write_Effect(entity client, int sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_EFFECT);
#if EFFECTS_COUNT >= 255
	WriteShort(MSG_ENTITY, self.eent_net_name);
#else
	WriteByte(MSG_ENTITY, self.eent_net_name);
#endif
	WriteCoord(MSG_ENTITY, self.eent_net_location_x);
	WriteCoord(MSG_ENTITY, self.eent_net_location_y);
	WriteCoord(MSG_ENTITY, self.eent_net_location_z);

	// attempt to save a tiny bit more bandwidth by not sending velocity if it isn't set
	if(self.eent_net_velocity)
	{
		WriteByte(MSG_ENTITY, true);
		WriteCoord(MSG_ENTITY, self.eent_net_velocity_x);
		WriteCoord(MSG_ENTITY, self.eent_net_velocity_y);
		WriteCoord(MSG_ENTITY, self.eent_net_velocity_z);
	}
	else { WriteByte(MSG_ENTITY, false); }

	if(!self.eent_eff_trail) { WriteByte(MSG_ENTITY, self.eent_net_count); }
	return true;
}

// problem with this is, we might not have all the available effects for it
int Effect_NameToID(string eff_name)
{
	int i;
	for(i = EFFECT_FIRST; i < MAX_EFFECTS; ++i)
	{
		if((effects_ent[i - 1]).eent_eff_name == eff_name)
			return (effects_ent[i - 1]).eent_net_name;
	}

	return 0;
}

void Send_Effect(string eff_name, vector eff_loc, vector eff_vel, int eff_cnt)
{
	int eff_id = Effect_NameToID(eff_name);

	if(!eff_id)
	{
		// revert to engine handling?
		pointparticles(particleeffectnum(eff_name), eff_loc, eff_vel, eff_cnt);
		return;
	}

	entity eff = effects_ent[eff_id - 1];
	if(!eff) { return; }
	if(!eff.eent_eff_trail && !eff_cnt) { return; } // effect has no count!
	entity net_eff = spawn();
	net_eff.owner = eff;
	net_eff.classname = "net_effect";
	//net_eff.eent_broadcast = broadcast;
	net_eff.eent_net_name = eff_id;
	net_eff.eent_net_velocity = eff_vel;
	net_eff.eent_net_location = eff_loc;
	net_eff.eent_net_count = eff_cnt;
	net_eff.eent_eff_trail = eff.eent_eff_trail;

	net_eff.think = SUB_Remove;
	net_eff.nextthink = time + 0.2; // don't need to keep this long

	Net_LinkEntity(net_eff, false, 0, Net_Write_Effect);
}
#endif