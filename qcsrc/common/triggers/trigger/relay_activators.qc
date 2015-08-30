#ifdef SVQC
void relay_activators_use()
{SELFPARAM();
	entity trg, os;

	os = self;

	for(trg = world; (trg = find(trg, targetname, os.target)); )
	{
		self = trg;
		if (trg.setactive)
			trg.setactive(os.cnt);
		else
		{
			//bprint("Not using setactive\n");
			if(os.cnt == ACTIVE_TOGGLE)
				if(trg.active == ACTIVE_ACTIVE)
					trg.active = ACTIVE_NOT;
				else
					trg.active = ACTIVE_ACTIVE;
			else
				trg.active = os.cnt;
		}
	}
	self = os;
}

void spawnfunc_relay_activate()
{SELFPARAM();
	self.cnt = ACTIVE_ACTIVE;
	self.use = relay_activators_use;
}

void spawnfunc_relay_deactivate()
{SELFPARAM();
	self.cnt = ACTIVE_NOT;
	self.use = relay_activators_use;
}

void spawnfunc_relay_activatetoggle()
{SELFPARAM();
	self.cnt = ACTIVE_TOGGLE;
	self.use = relay_activators_use;
}
#endif
