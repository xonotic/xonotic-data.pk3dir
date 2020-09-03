#include "cl_attackertext.qh"

AUTOCVAR_SAVE(cl_attackertext,                        bool,   true,       "Draw damage dealt where you hit the enemy");
AUTOCVAR_SAVE(cl_attackertext_friendlyfire,           bool,   false,      "Show for friendlyfire");
AUTOCVAR_SAVE(cl_attackertext_time,                   float,  3,          "Time to show");
AUTOCVAR_SAVE(cl_attackertext_fadetime,               float,  2,          "Time to fade");
AUTOCVAR_SAVE(cl_attackertext_decolorize,             int,    1,          "1 = decolorize names when teamplay, 2 = decolorize always");

REGISTER_MUTATOR(attackertext, true);

MUTATOR_HOOKFUNCTION(attackertext, DrawInfoMessages)
{
	if (autocvar_cl_attackertext == 0) return false;
	
	float fade_start = max(0, autocvar_cl_attackertext_time);
	float fade_time = max(0, autocvar_cl_attackertext_fadetime);
		
	if (last_attack_time && last_attack_time > time - fade_start - fade_time) {
		vector pos = M_ARGV(0, vector);
		vector mySize = M_ARGV(1, vector);
		vector fontsize = '0.2 0.2 0' * mySize.y;
		int img_curr_group = M_ARGV(2, int);
		
		float alpha_ = 0;
		
		if (last_attack_time + fade_start > time)
			alpha_ = panel_fg_alpha;
		else if (fade_time != 0)
			alpha_ = panel_fg_alpha - bound(0, (time - last_attack_time - fade_start) * (1 / fade_time), 1);
		else
			return true;
			
		pos = InfoMessages_drawstring(last_attack_name, pos, mySize, alpha_, fontsize);
		img_curr_group = -1;

		return true;
	}
		
	return false;
}


NET_HANDLE(attackertext, bool isNew)
{
    int server_entity_index = ReadByte();
	int flags = ReadByte();
    bool friendlyfire = flags & ATFLAG_SAMETEAM;
	
	return = true;
	
    if (autocvar_cl_attackertext == 0) return;
    if (friendlyfire && autocvar_cl_attackertext_friendlyfire == 0) return;
	
	string s = entcs_GetName(server_entity_index - 1);
	if ((autocvar_cl_attackertext_decolorize == 1 && teamplay) || autocvar_cl_attackertext_decolorize == 2)
		s = playername(s, entcs_GetTeam(server_entity_index - 1));

	last_attack_time = time;
	strfree(last_attack_name);
	strcpy(last_attack_name, s);
}
