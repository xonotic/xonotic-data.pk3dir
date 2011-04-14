#ifdef VEHICLES_CSQC
// SendFlags
float VSF_SETUP       = 1;          /// Send vehicle type etc
float VSF_ORIGIN      = 2;          /// Send location
float VSF_MOVEMENT    = 4;          /// Send movement update (and angles)
float VSF_AVEL        = 8;          /// Send Angular velocity
float VSF_STATS       = 16;         /// Send ammo, health etc
float VSF_EXTRA       = 32;         /// Send additional data (turret rotations and such). Handeld per vehicle type.
float VSF_ANIMINFO    = 64;         /// Animation info
float VSF_FAR         = 128;
float VSF_FULL_UPDATE = 16777215;    /// Send everything

#ifdef SVQC
#define VSF_FARDISTANCE 2000
float send_vehile(entity to, float sf)
{
	float dist;
    var void WriteFunc(float, float);
    
    dist = vlen(self.origin - to.origin);
    if(dist > VSF_FARDISTANCE && to != self.owner)
        sf |= VSF_FAR;
	
	// Always send a movement and origin to owner
	if(to == self.owner)
	    sf |= VSF_ORIGIN | VSF_MOVEMENT;
                
	WriteByte(MSG_ENTITY, ENT_CLIENT_VEHICLE);
	
	// We need to know client-side what was sent
	WriteByte(MSG_ENTITY, sf);
	
	if(sf & VSF_SETUP)
	{
        WriteByte(MSG_ENTITY,   self.hud);        //vehicle type = hud
        WriteByte(MSG_ENTITY,   self.team);
        WriteShort(MSG_ENTITY,  self.colormap);
	}
    
    if(sf & VSF_ORIGIN)
    {        
        WriteFunc = ((sf & VSF_FAR) ? WriteShort : WriteCoord); 
        WriteFunc(MSG_ENTITY, self.origin_x);
        WriteFunc(MSG_ENTITY, self.origin_y);
        WriteFunc(MSG_ENTITY, self.origin_z);        
    }
    
    if(sf & VSF_MOVEMENT)
    {   
        WriteFunc = ((sf & VSF_FAR) ? WriteShort : WriteCoord);
        WriteCoord(MSG_ENTITY, self.velocity_x);
        WriteCoord(MSG_ENTITY, self.velocity_y);
        WriteCoord(MSG_ENTITY, self.velocity_z);

        WriteFunc = ((sf & VSF_FAR) ? WriteShort : WriteAngle);
        WriteAngle(MSG_ENTITY, self.angles_x);
        WriteAngle(MSG_ENTITY, self.angles_y);
        WriteAngle(MSG_ENTITY, self.angles_z);
    }
    
    if(sf & VSF_AVEL)
    {
        WriteFunc = ((sf & VSF_FAR) ? WriteShort : WriteCoord);
        WriteCoord(MSG_ENTITY, self.avelocity_x);
        WriteCoord(MSG_ENTITY, self.avelocity_y);
        WriteCoord(MSG_ENTITY, self.avelocity_z);        
    }
    
    if(sf & VSF_STATS)
    {
        if(to == self.owner)
        {
            WriteByte(MSG_ENTITY, 1);
            WriteByte(MSG_ENTITY, self.vehicle_shield);
            WriteByte(MSG_ENTITY, self.vehicle_energy);
            
            WriteByte(MSG_ENTITY, self.vehicle_ammo1);
            WriteByte(MSG_ENTITY, self.vehicle_reload1);
            
            WriteByte(MSG_ENTITY, self.vehicle_ammo2);
            WriteByte(MSG_ENTITY, self.vehicle_reload2);
            
        }
        else
            WriteByte(MSG_ENTITY, 0);
            
        WriteByte(MSG_ENTITY, self.vehicle_health);
    }
    
    if(sf & VSF_EXTRA)
        self.vehile_send_exta(to, sf);
    
    return TRUE;
}

void net_link_vehile()
{    
    self.SendFlags = 0xFFFFFF;
    Net_LinkEntity(self, FALSE, 0, send_vehile);    
}
#endif // SVQC

#ifdef CSQC
void Net_ReadVehicle(float bIsNew)
{
    float sf;
    var float ReadFunc();
    
    if(bIsNew)
    {
        /*setmodel(self, "models/vehicles/wakizashi.dpm");
        self.move_movetype = MOVETYPE_BOUNCE;        
        self.entremove = VehicleRacerRemove;
        setsize(self,  '-60 -60 -20', '60 60 20');        
        self.draw = VehicleRacerDraw;
        self.scale = 0.5;*/
    }

    sf = ReadByte();    
	if(sf & VSF_SETUP)
	{
        self.vehicle_hud      = ReadByte();
        self.team     = ReadByte();
        self.colormap = ReadShort();
        
        switch(self.vehicle_hud)
        {
            case HUD_WAKIZASHI:
                break;
            case HUD_SPIDERBOT:
                break;
            case HUD_RAPTOR:
                break;
            case HUD_BUMBLEBEE:
                break;
            default:
                break;
        }
	}        
    
    if(sf & VSF_ORIGIN)
    {    
        ReadFunc = ((sf & VSF_FAR) ? ReadShort : ReadCoord);
        self.origin_x       = ReadCoord();
        self.origin_y       = ReadCoord();
        self.origin_z       = ReadCoord();
        self.move_origin    = self.origin;
    }
    
    if(sf & VSF_MOVEMENT)
    {    
        ReadFunc = ((sf & VSF_FAR) ? ReadShort : ReadCoord);
        self.velocity_x     = ReadFunc();
        self.velocity_y     = ReadFunc();
        self.velocity_z     = ReadFunc();

        ReadFunc = ((sf & VSF_FAR) ? ReadShort : ReadAngle);
        self.angles_x       = ReadFunc();
        self.angles_y       = ReadFunc();
        self.angles_z       = ReadFunc();
        
        self.move_velocity  = self.velocity;
        self.move_angles    = self.angles;
    }

    if(sf & VSF_AVEL)
    {    
        ReadFunc = ((sf & VSF_FAR) ? ReadShort : ReadCoord);
        self.avelocity_x     = ReadFunc();
        self.avelocity_y     = ReadFunc();
        self.avelocity_z     = ReadFunc();
    }
    
    if(sf & VSF_EXTRA)
        self.vehile_read_exta(sf);

}

#endif // CSQC

#endif // VEHICLES_CSQC
