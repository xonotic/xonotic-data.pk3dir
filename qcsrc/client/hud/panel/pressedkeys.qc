#include "pressedkeys.qh"

#include <client/draw.qh>

// Pressed keys (#11)

void HUD_PressedKeys_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_pressedkeys_aspect");
	HUD_Write_Cvar("hud_panel_pressedkeys_attack");
}

void HUD_PressedKeys()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_pressedkeys || spectatee_status < 0) return;
		if(spectatee_status <= 0 && autocvar_hud_panel_pressedkeys < 2) return;
	}

	HUD_Panel_LoadCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_pressedkeys_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
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

	vector keysize = vec2(mySize.x / (14/4), mySize.y / (3 - !autocvar_hud_panel_pressedkeys_attack));
	int pressedkeys = STAT(PRESSED_KEYS);

	if(autocvar_hud_panel_pressedkeys_attack)
	{
		drawpic_aspect_skin(pos + eX * (3/4 * keysize.x), ((pressedkeys & KEY_ATCK) ? "key_atck_inv" : "key_atck"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawpic_aspect_skin(pos + eX * (7/4 * keysize.x), ((pressedkeys & KEY_ATCK2) ? "key_atck2_inv" : "key_atck2"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += keysize.y;
	}

	drawpic_aspect_skin(pos, ((pressedkeys & KEY_CROUCH) ? "key_crouch_inv" : "key_crouch"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * (5/4 * keysize.x), ((pressedkeys & KEY_FORWARD) ? "key_forward_inv" : "key_forward"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * (10/4 * keysize.x), ((pressedkeys & KEY_JUMP) ? "key_jump_inv" : "key_jump"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += keysize.y;
	drawpic_aspect_skin(pos + eX * (1/4 * keysize.x), ((pressedkeys & KEY_LEFT) ? "key_left_inv" : "key_left"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * (5/4 * keysize.x), ((pressedkeys & KEY_BACKWARD) ? "key_backward_inv" : "key_backward"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * (9/4 * keysize.x), ((pressedkeys & KEY_RIGHT) ? "key_right_inv" : "key_right"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}
