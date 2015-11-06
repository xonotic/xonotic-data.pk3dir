/** Vote window (#9) */
void HUD_Vote()
{
	if(autocvar_cl_allow_uid2name == -1 && (gametype == MAPINFO_TYPE_CTS || gametype == MAPINFO_TYPE_RACE || (serverflags & SERVERFLAG_PLAYERSTATS)))
	{
		vote_active = 1;
		if (autocvar__hud_configure)
		{
			vote_yescount = 0;
			vote_nocount = 0;
			LOG_INFO(_("^1You must answer before entering hud configure mode\n"));
			cvar_set("_hud_configure", "0");
		}
		if(vote_called_vote)
			strunzone(vote_called_vote);
		vote_called_vote = strzone(_("^2Name ^7instead of \"^1Anonymous player^7\" in stats"));
		uid2name_dialog = 1;
	}

	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_vote) return;

		panel_fg_alpha = autocvar_hud_panel_fg_alpha;
		panel_bg_alpha_str = autocvar_hud_panel_vote_bg_alpha;

		if(panel_bg_alpha_str == "") {
			panel_bg_alpha_str = ftos(autocvar_hud_panel_bg_alpha);
		}
		panel_bg_alpha = stof(panel_bg_alpha_str);
	}
	else
	{
		vote_yescount = 3;
		vote_nocount = 2;
		vote_needed = 4;
	}

	string s;
	float a;
	if(vote_active != vote_prev) {
		vote_change = time;
		vote_prev = vote_active;
	}

	if(vote_active || autocvar__hud_configure)
		vote_alpha = bound(0, (time - vote_change) * 2, 1);
	else
		vote_alpha = bound(0, 1 - (time - vote_change) * 2, 1);

	if(!vote_alpha)
		return;

	HUD_Panel_UpdateCvars();

	if(uid2name_dialog)
	{
		panel_pos = eX * 0.3 * vid_conwidth + eY * 0.1 * vid_conheight;
		panel_size = eX * 0.4 * vid_conwidth + eY * 0.3 * vid_conheight;
	}

    // these must be below above block
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	a = vote_alpha * (vote_highlighted ? autocvar_hud_panel_vote_alreadyvoted_alpha : 1);
	HUD_Panel_DrawBg(a);
	a = panel_fg_alpha * a;

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 3:1 aspect
	vector newSize = '0 0 0';
	if(mySize.x/mySize.y > 3)
	{
		newSize.x = 3 * mySize.y;
		newSize.y = mySize.y;

		pos.x = pos.x + (mySize.x - newSize.x) / 2;
	}
	else
	{
		newSize.y = 1/3 * mySize.x;
		newSize.x = mySize.x;

		pos.y = pos.y + (mySize.y - newSize.y) / 2;
	}
	mySize = newSize;

	s = _("A vote has been called for:");
	if(uid2name_dialog)
		s = _("Allow servers to store and display your name?");
	drawstring_aspect(pos, s, eX * mySize.x + eY * (2/8) * mySize.y, '1 1 1', a, DRAWFLAG_NORMAL);
	s = textShortenToWidth(vote_called_vote, mySize.x, '1 1 0' * mySize.y * (1/8), stringwidth_colors);
	if(autocvar__hud_configure)
		s = _("^1Configure the HUD");
	drawcolorcodedstring_aspect(pos + eY * (2/8) * mySize.y, s, eX * mySize.x + eY * (1.75/8) * mySize.y, a, DRAWFLAG_NORMAL);

	// print the yes/no counts
    s = sprintf(_("Yes (%s): %d"), getcommandkey("vyes", "vyes"), vote_yescount);
	drawstring_aspect(pos + eY * (4/8) * mySize.y, s, eX * 0.5 * mySize.x + eY * (1.5/8) * mySize.y, '0 1 0', a, DRAWFLAG_NORMAL);
    s = sprintf(_("No (%s): %d"), getcommandkey("vno", "vno"), vote_nocount);
	drawstring_aspect(pos + eX * 0.5 * mySize.x + eY * (4/8) * mySize.y, s, eX * 0.5 * mySize.x + eY * (1.5/8) * mySize.y, '1 0 0', a, DRAWFLAG_NORMAL);

	// draw the progress bar backgrounds
	drawpic_skin(pos + eY * (5/8) * mySize.y, "voteprogress_back", eX * mySize.x + eY * (3/8) * mySize.y, '1 1 1', a, DRAWFLAG_NORMAL);

	// draw the highlights
	if(vote_highlighted == 1) {
		drawsetcliparea(pos.x, pos.y, mySize.x * 0.5, mySize.y);
		drawpic_skin(pos + eY * (5/8) * mySize.y, "voteprogress_voted", eX * mySize.x + eY * (3/8) * mySize.y, '1 1 1', a, DRAWFLAG_NORMAL);
	}
	else if(vote_highlighted == -1) {
		drawsetcliparea(pos.x + 0.5 * mySize.x, pos.y, mySize.x * 0.5, mySize.y);
		drawpic_skin(pos + eY * (5/8) * mySize.y, "voteprogress_voted", eX * mySize.x + eY * (3/8) * mySize.y, '1 1 1', a, DRAWFLAG_NORMAL);
	}

	// draw the progress bars
	if(vote_yescount && vote_needed)
	{
		drawsetcliparea(pos.x, pos.y, mySize.x * 0.5 * (vote_yescount/vote_needed), mySize.y);
		drawpic_skin(pos + eY * (5/8) * mySize.y, "voteprogress_prog", eX * mySize.x + eY * (3/8) * mySize.y, '1 1 1', a, DRAWFLAG_NORMAL);
	}

	if(vote_nocount && vote_needed)
	{
		drawsetcliparea(pos.x + mySize.x - mySize.x * 0.5 * (vote_nocount/vote_needed), pos.y, mySize.x * 0.5, mySize.y);
		drawpic_skin(pos + eY * (5/8) * mySize.y, "voteprogress_prog", eX * mySize.x + eY * (3/8) * mySize.y, '1 1 1', a, DRAWFLAG_NORMAL);
	}

	drawresetcliparea();
}
