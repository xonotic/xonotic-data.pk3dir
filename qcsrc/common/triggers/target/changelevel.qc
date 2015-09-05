#ifdef SVQC
.string chmap, gametype;
.entity chlevel_targ;


void spawnfunc_target_changelevel_use()
{SELFPARAM();
	if(self.spawnflags & 2)
	{
		// simply don't react if a non-player triggers it
		if(!IS_PLAYER(activator)) { return; }

		activator.chlevel_targ = self;

		entity head;
		int plnum = 0;
		int realplnum = 0;
		// let's not count bots
		FOR_EACH_REALPLAYER(head)
		{
			++realplnum;
			if(head.chlevel_targ == self)
				++plnum;
		}
		if(plnum < ceil(realplnum * min(1, self.count))) // 70% of players
			return;
	}

	if(self.gametype != "")
		MapInfo_SwitchGameType(MapInfo_Type_FromString(self.gametype));

	if (self.chmap == "")
		localcmd("endmatch\n");
	else
		localcmd(strcat("changelevel ", self.chmap, "\n"));
}

void spawnfunc_target_changelevel()
{SELFPARAM();
	self.use = spawnfunc_target_changelevel_use;

	if(!self.count) { self.count = 0.7; }
}
#endif
