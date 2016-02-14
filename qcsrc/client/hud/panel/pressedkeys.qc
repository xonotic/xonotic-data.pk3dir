/** Draw pressed keys (#11) */
void HUD_PressedKeys()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_pressedkeys) return;
		if(spectatee_status <= 0 && autocvar_hud_panel_pressedkeys < 2) return;
	}

	HUD_Panel_UpdateCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// force custom aspect
	float aspect = autocvar_hud_panel_pressedkeys_aspect;
	if(aspect)
	{
		vector newSize = '0 0 0';
		if(mySize.x/mySize.y > aspect)
		{
			newSize.x = aspect * mySize.y;
			newSize.y = mySize.y;

			pos.x = pos.x + (mySize.x - newSize.x) / 2;
		}
		else
		{
			newSize.y = 1/aspect * mySize.x;
			newSize.x = mySize.x;

			pos.y = pos.y + (mySize.y - newSize.y) / 2;
		}
		mySize = newSize;
	}

	vector keysize;
	keysize = eX * mySize.x * (1/3.0) + eY * mySize.y * (1/(3.0 - !autocvar_hud_panel_pressedkeys_attack));
	int pressedkeys = STAT(PRESSED_KEYS);

	if(autocvar_hud_panel_pressedkeys_attack)
	{
		drawpic_aspect_skin(pos + eX * keysize.x * 0.5, ((pressedkeys & KEY_ATCK) ? "key_atck_inv.tga" : "key_atck.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawpic_aspect_skin(pos + eX * keysize.x * 1.5, ((pressedkeys & KEY_ATCK2) ? "key_atck_inv.tga" : "key_atck.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += keysize.y;
	}

	drawpic_aspect_skin(pos, ((pressedkeys & KEY_CROUCH) ? "key_crouch_inv.tga" : "key_crouch.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize.x, ((pressedkeys & KEY_FORWARD) ? "key_forward_inv.tga" : "key_forward.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize.x * 2, ((pressedkeys & KEY_JUMP) ? "key_jump_inv.tga" : "key_jump.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += keysize.y;
	drawpic_aspect_skin(pos, ((pressedkeys & KEY_LEFT) ? "key_left_inv.tga" : "key_left.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize.x, ((pressedkeys & KEY_BACKWARD) ? "key_backward_inv.tga" : "key_backward.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize.x * 2, ((pressedkeys & KEY_RIGHT) ? "key_right_inv.tga" : "key_right.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}
