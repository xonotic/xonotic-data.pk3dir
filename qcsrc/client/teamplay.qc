float TeamByColor(float color)
{
	switch(color)
	{
	case COLOR_TEAM1: return 0;
	case COLOR_TEAM2: return 1;
	case COLOR_TEAM3: return 2;
	case COLOR_TEAM4: return 3;
	default: return 0;
	}
}
float ColorByTeam(float i)
{
	switch(i)
	{
	case 0: return COLOR_TEAM1;
	case 1: return COLOR_TEAM2;
	case 2: return COLOR_TEAM3;
	case 3: return COLOR_TEAM4;
	default: return COLOR_TEAM1;
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
		return COLOR_SPECTATOR;
	else if(stof(getplayerkeyvalue(i, "frags")) == FRAGS_SPECTATOR)
		return COLOR_SPECTATOR;
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
	case COLOR_TEAM1: return '1 0 0'; // red
	case COLOR_TEAM2: return '0 0 1'; // blue
	case COLOR_TEAM3: return '1 1 0'; // yellow
	case COLOR_TEAM4: return '1 0 1'; // pink
	}
}

string GetTeamName(float color)
{
	switch(color)
	{
	default: return _("Spectators");
	case COLOR_TEAM1: return _("Red Team");
	case COLOR_TEAM2: return _("Blue Team");
	case COLOR_TEAM3: return _("Yellow Team");
	case COLOR_TEAM4: return _("Pink Team");
	}
}
