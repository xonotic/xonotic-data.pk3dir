float g_skycycle;
float g_skycycle_started;
float skycycle_time;
float skycycle_timebetween;
float skycycle_timestart;
//float skycycle_timecurrent;
//float skycycle_timenext;
float skycycle_epoch;
float skycycle_intensity_realmax; //Max (Less than Goal if you want long days/nights)
float skycycle_intensity_realmin; //Min (More than Goal if you want long days/nights)
float skycycle_intensity_max; //Goal
float skycycle_intensity_min; //Goal
float skycycle_intensity_current;
float skycycle_ambient_realmax; //Max (Less than Goal if you want long days/nights)
float skycycle_ambient_realmin; //Min (More than Goal if you want long days/nights)
float skycycle_ambient_max; //Goal
float skycycle_ambient_min; //Goal
float skycycle_ambient_current;
float skycycle_skybox;
float skycycle_skybox_number;
float autocvar_g_skycycle_intensity_realmax;
float autocvar_g_skycycle_intensity_realmin;
float autocvar_g_skycycle_ambient_realmax;
float autocvar_g_skycycle_ambient_realmin;
float autocvar_g_skycycle_startatnight;
float autocvar_g_skycycle_startattime;
float autocvar_g_skycycle_timelock;
string autocvar_g_skycycle_nightsky;
string autocvar_g_skycycle_dusksky;
string autocvar_g_skycycle_daysky;
string skycycle_nightsky;
string skycycle_dusksky;
string skycycle_daysky;
float skycycle_nightsky_max;
float skycycle_dusksky_max;
.float skycycle_playernextthink;

float autocvar_g_skycycle_time;
float autocvar_g_skycycle_timebetween;
float autocvar_g_skycycle_intensity_max;
float autocvar_g_skycycle_intensity_min;
float autocvar_g_skycycle_ambient_max;
float autocvar_g_skycycle_ambient_min;
float autocvar_g_skycycle_nightsky_max;
float autocvar_g_skycycle_dusksky_max;
float autocvar_g_skycycle_skybox;


void SkyCycle_Set()
{
	skycycle_time = autocvar_g_skycycle_time;
	skycycle_timebetween = autocvar_g_skycycle_timebetween;
	skycycle_intensity_max = autocvar_g_skycycle_intensity_max;
	skycycle_intensity_min = autocvar_g_skycycle_intensity_min;
	skycycle_ambient_max = autocvar_g_skycycle_ambient_max;
	skycycle_ambient_min = autocvar_g_skycycle_ambient_min;
	skycycle_intensity_realmax = autocvar_g_skycycle_intensity_realmax;
	skycycle_intensity_realmin = autocvar_g_skycycle_intensity_realmin;
	skycycle_ambient_realmax = autocvar_g_skycycle_ambient_realmax;
	skycycle_ambient_realmin = autocvar_g_skycycle_ambient_realmin;
	skycycle_nightsky = autocvar_g_skycycle_nightsky;
	skycycle_dusksky = autocvar_g_skycycle_dusksky;
	skycycle_daysky = autocvar_g_skycycle_daysky;
	skycycle_nightsky_max = autocvar_g_skycycle_nightsky_max;
	skycycle_dusksky_max = autocvar_g_skycycle_dusksky_max;
	skycycle_skybox = autocvar_g_skycycle_skybox;
	skycycle_skybox_number = 0;

	entity e;
	FOR_EACH_REALCLIENT(e)
		e.skycycle_playernextthink = time;
}

void SkyCycle_Restart()
{
	skycycle_timestart = time;
}

void SkyCycle_Lighten()
{
	//print("Lighten\n");
	float d, m;
	m = skycycle_intensity_max - skycycle_intensity_min;
	d = 
	skycycle_intensity_min +
	(m *
	((time - skycycle_timestart) / skycycle_time));
		
	skycycle_intensity_current = d;
	
	m = skycycle_ambient_max - skycycle_ambient_min;
	d = 
	skycycle_ambient_min +
	(m *
	((time - skycycle_timestart) / skycycle_time));
		
	skycycle_ambient_current = d;
}

void SkyCycle_Darken()
{
	//print("Darken\n");
	float d,  m;
	m = skycycle_intensity_max - skycycle_intensity_min;
	d = 
	skycycle_intensity_max -
	(m *
	((time - skycycle_timestart) / skycycle_time));
	
	skycycle_intensity_current = d;
	
	m = skycycle_ambient_max - skycycle_ambient_min;
	d = 
	skycycle_ambient_max -
	(m *
	((time - skycycle_timestart) / skycycle_time));
		
	skycycle_ambient_current = d;
}

void SkyCycle_Run()
{
	//print("SkyCycle Run\n");
	if (time - skycycle_timestart > skycycle_time)
	{
		//Restart
		SkyCycle_Restart();
		if (skycycle_epoch == 1)
			skycycle_epoch = 0;
		else
			skycycle_epoch = 1;
	}
	else
	{
		if (skycycle_epoch == 1)
			SkyCycle_Lighten();
		else
			SkyCycle_Darken();
	}
	if (autocvar_g_skycycle_timelock)
		//Advance start time at same pace if timelock is set
		skycycle_timestart += skycycle_timebetween;

	self.nextthink = time + skycycle_timebetween;
}

void SkyCycle_Spawn()
{
		SkyCycle_Set();
		entity e;
		
		e = spawn();
		e.think = SkyCycle_Run;
		e.nextthink = time; //Start Right Away
		skycycle_epoch = 0;
		SkyCycle_Restart();
		
		//print("spawning sky cycle\n");
}

void SkyCycle_SendPlayer(float checkboxnum)
{
	//print("sending sky stuff\n");
	//print(strcat("maxintensity ", ftos(skycycle_intensity_realmax), "\n"));
	//print(strcat("maxambient", ftos(skycycle_ambient_realmax), "\n"));
	//print(strcat("intensity    ", ftos(skycycle_intensity_current), "\n"));
	//print(strcat("ambient   ", ftos(skycycle_ambient_current), "\n"));
	stuffcmd(self, strcat("cl_cmd settemp r_fakelight_intensity ", ftos(skycycle_intensity_current), "\n"));
	stuffcmd(self, strcat("cl_cmd settemp r_ambient ", ftos(skycycle_ambient_current), "\n"));
	
	if (skycycle_skybox)
	{
		if (skycycle_intensity_current < skycycle_nightsky_max)
		{
			if ((skycycle_skybox_number == 2) && (checkboxnum))
			{
				//Do nothing
			}
			else
			{
				if (checkboxnum)
				{
					//Send to all players
					entity e;
  					FOR_EACH_REALCLIENT(e)
    					stuffcmd(e, strcat("loadsky ", skycycle_nightsky, "\n"));	
				}
				else
				{
					stuffcmd(self, strcat("loadsky ", skycycle_nightsky, "\n"));
				}
				skycycle_skybox_number = 2;
			}
		}
		else if(skycycle_intensity_current < skycycle_dusksky_max)
		{
			if((skycycle_skybox_number == 1) && (checkboxnum))
			{
				//Do nothing
			}
			else
			{
				if(checkboxnum)
				{
					//Send to all players
					entity e;
  					FOR_EACH_REALCLIENT(e)
    					stuffcmd(e, strcat("loadsky ", skycycle_dusksky, "\n"));	
				}
				else
				{
					stuffcmd(self, strcat("loadsky ", skycycle_dusksky, "\n"));
				}
				skycycle_skybox_number = 1;
			}
		}
		else
		{
			if((skycycle_skybox_number == 0) && (checkboxnum))
			{
				//Do nothing
			}
			else
			{
				if(checkboxnum)
				{
					//Send to all players
					entity e;
  					FOR_EACH_REALCLIENT(e)
    					stuffcmd(e, strcat("loadsky ", skycycle_daysky, "\n"));	
				}
				else
				{
					stuffcmd(self, strcat("loadsky ", skycycle_daysky, "\n"));
				}
				skycycle_skybox_number = 0;
			}
		}
	}
}


MUTATOR_HOOKFUNCTION(skycycle_PlayerPreThink)
{
	if (g_skycycle)
	if (time > self.skycycle_playernextthink)
	{
		SkyCycle_SendPlayer(1);
		self.skycycle_playernextthink = time + 1;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(skycycle_PlayerSpawn)
{
	stuffcmd(self, "cl_cmd settemp r_fakelight 2\n");
		
	SkyCycle_SendPlayer(0);
	return false;
}

MUTATOR_HOOKFUNCTION(skycycle_StartFrame)
{
	if(skycycle_ambient_realmin > skycycle_ambient_current)
		skycycle_ambient_current = autocvar_g_skycycle_ambient_realmin;
	
	if(skycycle_intensity_realmin > skycycle_intensity_current)
		skycycle_intensity_current = autocvar_g_skycycle_intensity_realmin;
	
	if(skycycle_ambient_realmax < skycycle_ambient_current)
		skycycle_ambient_current = autocvar_g_skycycle_ambient_realmax;
	
	if(skycycle_intensity_realmax < skycycle_intensity_current)
		skycycle_intensity_current = autocvar_g_skycycle_intensity_realmax;

	return false;
}

MUTATOR_HOOKFUNCTION(skycycle_ResetMap)
{
	SkyCycle_Restart();
	return false;
}

MUTATOR_HOOKFUNCTION(skycycle_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":skycycle");
	return false;
}

MUTATOR_HOOKFUNCTION(skycycle_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Sky Cycle");
	return false;
}

void skycycle_Init()
{
	SkyCycle_Spawn();

	if(autocvar_g_skycycle_startatnight)
		skycycle_epoch = 1;

	if(autocvar_g_skycycle_startattime)
		skycycle_timestart = time - (skycycle_time * autocvar_g_skycycle_startattime);

	g_skycycle_started = 1;
}

MUTATOR_DEFINITION(mutator_skycycle)
{
	MUTATOR_HOOK(PlayerSpawn, skycycle_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, skycycle_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_StartFrame, skycycle_StartFrame, CBC_ORDER_ANY);
	MUTATOR_HOOK(reset_map_global, skycycle_ResetMap, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, skycycle_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, skycycle_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	
	// this just turns on the cvar.
	MUTATOR_ONADD
	{
		g_skycycle = 1;
		serverflags |= SERVERFLAG_ALLOW_FULLBRIGHT;
		InitializeEntity(world, skycycle_Init, INITPRIO_GAMETYPE);
	}

	// this just turns off the cvar.
	MUTATOR_ONREMOVE
	{	 
		g_skycycle = 0;
	}

	return 0;
}
