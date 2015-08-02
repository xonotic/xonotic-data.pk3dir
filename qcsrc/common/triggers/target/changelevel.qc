#ifdef SVQC
.string chmap, gametype;
void spawnfunc_target_changelevel_use()
{
	if(self.gametype != "")
		MapInfo_SwitchGameType(MapInfo_Type_FromString(self.gametype));

	if (self.chmap == "")
		localcmd("endmatch\n");
	else
		localcmd(strcat("changelevel ", self.chmap, "\n"));
}

void spawnfunc_target_changelevel()
{
	self.use = spawnfunc_target_changelevel_use;
}
#endif
