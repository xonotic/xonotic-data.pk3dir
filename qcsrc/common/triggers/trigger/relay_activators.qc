#ifdef SVQC
void relay_activators_use()
{SELFPARAM();
	for(entity trg = world; (trg = find(trg, targetname, this.target)); )
	{
		setself(trg);
		if (trg.setactive)
			trg.setactive(this.cnt);
		else
		{
			//bprint("Not using setactive\n");
			if(this.cnt == ACTIVE_TOGGLE)
				if(trg.active == ACTIVE_ACTIVE)
					trg.active = ACTIVE_NOT;
				else
					trg.active = ACTIVE_ACTIVE;
			else
				trg.active = this.cnt;
		}
	}
	setself(this);
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
