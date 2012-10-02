float TeamByColor(float color)
{
	switch(color)
	{
	case FL_TEAM_1: return 0;
	case FL_TEAM_2: return 1;
	case FL_TEAM_3: return 2;
	case FL_TEAM_4: return 3;
	default: return 0;
	}
}
float ColorByTeam(float i)
{
	switch(i)
	{
	case 0: return FL_TEAM_1;
	case 1: return FL_TEAM_2;
	case 2: return FL_TEAM_3;
	case 3: return FL_TEAM_4;
	default: return FL_TEAM_1;
	}
}

float GetPlayerColorForce(float i)
{
	if(!teamplay)
		return 0;
	else
		return stof(getplayerkeyvalue(i, "colors")) & 15;
}

float GetPlayerColor(float i)
{
	if not(playerslots[i].gotscores) // unconnected
		return FL_SPECTATOR;
	else if(stof(getplayerkeyvalue(i, "frags")) == FRAGS_SPECTATOR)
		return FL_SPECTATOR;
	else
		return GetPlayerColorForce(i);
}

string GetPlayerName(float i)
{
	return ColorTranslateRGB(getplayerkeyvalue(i, "name"));
}

vector GetTeamRGB(float color)
{
	switch(color)
	{
	default: return '1 1 1';
	case FL_TEAM_1: return '1 0 0'; // red
	case FL_TEAM_2: return '0 0 1'; // blue
	case FL_TEAM_3: return '1 1 0'; // yellow
	case FL_TEAM_4: return '1 0 1'; // pink
	}
}

string GetTeamName(float color)
{
	switch(color)
	{
	default: return _("Spectators");
	case FL_TEAM_1: return _("Red Team");
	case FL_TEAM_2: return _("Blue Team");
	case FL_TEAM_3: return _("Yellow Team");
	case FL_TEAM_4: return _("Pink Team");
	}
}
