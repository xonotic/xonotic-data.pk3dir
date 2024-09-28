#include "physics.qh"
#include <client/hud/common_physics.qh>

#include <client/draw.qh>

// Physics (#15)

void HUD_Physics_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_physics_speed_unit_show");
	HUD_Write_Cvar("hud_panel_physics_speed_max");
	HUD_Write_Cvar("hud_panel_physics_speed_vertical");
	HUD_Write_Cvar("hud_panel_physics_topspeed");
	HUD_Write_Cvar("hud_panel_physics_topspeed_time");
	HUD_Write_Cvar("hud_panel_physics_jumpspeed");
	HUD_Write_Cvar("hud_panel_physics_jumpspeed_time");
	HUD_Write_Cvar("hud_panel_physics_acceleration_max");
	HUD_Write_Cvar("hud_panel_physics_acceleration_max_slick");
	HUD_Write_Cvar("hud_panel_physics_acceleration_vertical");
	HUD_Write_Cvar("hud_panel_physics_flip");
	HUD_Write_Cvar("hud_panel_physics_baralign");
	HUD_Write_Cvar("hud_panel_physics_progressbar");
	HUD_Write_Cvar("hud_panel_physics_acceleration_progressbar_mode");
	HUD_Write_Cvar("hud_panel_physics_acceleration_progressbar_scale");
	HUD_Write_Cvar("hud_panel_physics_acceleration_progressbar_nonlinear");
	HUD_Write_Cvar("hud_panel_physics_text");
	HUD_Write_Cvar("hud_panel_physics_text_scale");
	HUD_Write_Cvar("hud_panel_physics_force_layout");
}

vector acc_prev_vel;
float acc_prev_time, acc_avg, top_speed, top_speed_time, jump_speed, jump_speed_time;
float prev_vel_z = 0, prev_speed2d = 0;
float physics_update_time, discrete_speed, discrete_top_speed, discrete_accel; // not done for jump speed
void HUD_Physics()
{
	if (!autocvar__hud_configure)
	{
		if (!autocvar_hud_panel_physics) return;
		if (spectatee_status == -1 && (autocvar_hud_panel_physics == 1 || autocvar_hud_panel_physics == 3)) return;
		if (autocvar_hud_panel_physics == 3 && !MUTATOR_CALLHOOK(HUD_Physics_showoptional)) return;
	}

	HUD_Panel_LoadCvars();

	if (autocvar_hud_panel_physics_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	if (!csqc_and_strafe_player)
		return;

	draw_beginBoldFont();

	float accel_progressbar_scale = 0;
	if (autocvar_hud_panel_physics_progressbar && autocvar_hud_panel_physics_acceleration_progressbar_scale > 1)
		accel_progressbar_scale = autocvar_hud_panel_physics_acceleration_progressbar_scale;

	float text_scale;
	if (autocvar_hud_panel_physics_text_scale <= 0)
		text_scale = 1;
	else
		text_scale = min(autocvar_hud_panel_physics_text_scale, 1);

	// compute speed
	float conversion_factor = GetSpeedUnitFactor(autocvar_hud_speed_unit);
	float speed, speed2d;
	float max_speed = floor(autocvar_hud_panel_physics_speed_max * conversion_factor + 0.5);
	if (autocvar__hud_configure)
	{
		speed2d = floor(max_speed * 0.65 + 0.5);
		speed = speed2d; // just ignore vertical speed in hud configure
		immobile = speed <= 0;
	}
	else
	{
		speed2d = floor(speed_phys * conversion_factor + 0.5);
		if (autocvar_hud_panel_physics_speed_vertical)
			speed = floor(speed3d_phys * conversion_factor + 0.5);
		else
			speed = speed2d;
	}

	// compute acceleration
	float accel;
	if (autocvar__hud_configure)
		accel = 0.45; // use a hardcoded value so that the hud responds to hud_panel_physics_acceleration_max changing
	else
	{
		float f = time - acc_prev_time;
		if (autocvar_hud_panel_physics_acceleration_vertical)
			accel = (speed3d_phys - vlen(acc_prev_vel));
		else
			accel = (speed_phys - vlen(vec2(acc_prev_vel)));

		accel *= (1 / max(0.0001, f)) * ACCEL2GRAV;

		acc_prev_vel  = vel_phys;
		acc_prev_time = time;

		if (autocvar_hud_panel_physics_acceleration_movingaverage)
		{
			f = bound(0, f * autocvar_hud_panel_physics_acceleration_movingaverage_strength, 1);
			acc_avg = acc_avg * (1 - f) + accel * f;
			accel = acc_avg;
		}
	}

	// compute layout
	float panel_ar = panel_size.x / panel_size.y;
	vector speed_offset = '0 0 0', accel_offset = '0 0 0';
	if (autocvar_hud_panel_physics_force_layout == PHYSICS_LAYOUT_HORIZONTAL
		|| (autocvar_hud_panel_physics_force_layout != PHYSICS_LAYOUT_VERTICAL && panel_ar >= 5 && !accel_progressbar_scale))
	{
		panel_size.x *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset.x = panel_size.x;
		else
			accel_offset.x = panel_size.x;
	}
	else // speed and accel are drawn on top of one another (vvv), rather than side by side (^^^)
	{
		panel_size.y *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset.y = panel_size.y;
		else
			accel_offset.y = panel_size.y;
	}
	int speed_baralign, accel_baralign;
	if (autocvar_hud_panel_physics_baralign == PHYSICS_BARALIGN_RIGHT)
		accel_baralign = speed_baralign = 1;
	else if (autocvar_hud_panel_physics_baralign == PHYSICS_BARALIGN_CENTER)
		accel_baralign = speed_baralign = 2;
	else if (autocvar_hud_panel_physics_flip)
	{
		accel_baralign = (autocvar_hud_panel_physics_baralign == PHYSICS_BARALIGN_ONLY_LEFT);
		speed_baralign = (autocvar_hud_panel_physics_baralign == PHYSICS_BARALIGN_ONLY_RIGHT);
	}
	else
	{
		speed_baralign = (autocvar_hud_panel_physics_baralign == PHYSICS_BARALIGN_ONLY_LEFT);
		accel_baralign = (autocvar_hud_panel_physics_baralign == PHYSICS_BARALIGN_ONLY_RIGHT);
	}
	if (autocvar_hud_panel_physics_acceleration_progressbar_mode == 0)
		accel_baralign = 3; // override hud_panel_physics_baralign value for acceleration

	vector tmp_offset = '0 0 0', tmp_size = '0 0 0';
	float speed_size = 0.75;
	int text_bits = BITS(0); // describes which texts may be drawn. BIT(0) = top speed, BIT(1) = jump speed, BIT(2) = speed unit
	// ordered by decreasing priority -- speed unit isn't drawn if the other two are,
	// ... and top speed takes priority over jump speed in the lower spot

	// draw speed
	if (!immobile)
	if (autocvar_hud_panel_physics_progressbar == PHYSICS_PROGRESSBAR_BOTH || autocvar_hud_panel_physics_progressbar == PHYSICS_PROGRESSBAR_SPEED)
		HUD_Panel_DrawProgressBar(panel_pos + speed_offset, panel_size, "progressbar", speed / max_speed, 0, speed_baralign,
			autocvar_hud_progressbar_speed_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);

	// compute jump speed text
	float jump_speed_f = 0;
	if (autocvar_hud_panel_physics_jumpspeed)
	if (autocvar_hud_panel_physics_text == PHYSICS_TEXT_BOTH || autocvar_hud_panel_physics_text == PHYSICS_TEXT_SPEED)
	{
		text_bits |= BIT(1);
		if (autocvar__hud_configure)
		{
			jump_speed = floor(max_speed * 0.59 + 0.5); // slightly less than current speed text
			jump_speed_f = 1;
		}
		else
		{
			if (vel_phys.z > prev_vel_z && jumpheld && !real_onground && !swimming && alive_player)
			{
				// NOTE: this includes some situations where the player doesn't explicitly jump (e.g. jumppad, weapon kb)
				// excluding them would be difficult. maybe they can be left in?
				jump_speed = prev_speed2d;
				jump_speed_time = time;
			}
			prev_vel_z = vel_phys.z;
			prev_speed2d = speed2d;
			float time_frac = (time - jump_speed_time) / max(1, autocvar_hud_panel_physics_jumpspeed_time);
			jump_speed_f = time_frac > 1 ? 0 : cos(time_frac * PI / 2);
		}
	}

	// compute and draw top speed
	float top_speed_f = 0;
	if (autocvar_hud_panel_physics_topspeed)
	if (autocvar_hud_panel_physics_text == PHYSICS_TEXT_BOTH || autocvar_hud_panel_physics_text == PHYSICS_TEXT_SPEED)
	{
		text_bits |= BIT(0);
		if (autocvar__hud_configure)
		{
			top_speed = floor(max_speed * 0.73 + 0.5);
			top_speed_f = 1;
		}
		else
		{
			if (speed >= top_speed)
			{
				top_speed = speed;
				top_speed_time = time;
			}
			if (top_speed == 0) // hide top speed 0
				top_speed_f = 0;
			else
			{
				float time_frac = (time - top_speed_time) / max(1, autocvar_hud_panel_physics_topspeed_time);
				top_speed_f = time_frac > 1 ? 0 : cos(time_frac * PI / 2);
			}
		}
		// top speed progressbar peak
		if (top_speed_f > 0)
		{
			if (speed < top_speed)
			if (autocvar_hud_panel_physics_progressbar == PHYSICS_PROGRESSBAR_BOTH || autocvar_hud_panel_physics_progressbar == PHYSICS_PROGRESSBAR_SPEED)
			{
				float peak_offsetX;
				vector peak_size = '0 0 0';
				if (speed_baralign == 0)
					peak_offsetX = min(top_speed, max_speed) / max_speed * panel_size.x;
				else if (speed_baralign == 1)
					peak_offsetX = (1 - min(top_speed, max_speed) / max_speed) * panel_size.x;
				else //if (speed_baralign == 2)
					peak_offsetX = min(top_speed, max_speed) / max_speed * panel_size.x * 0.5;
				peak_size.x = floor(panel_size.x * 0.01 + 1.5);
				peak_size.y = panel_size.y;
				if (speed_baralign == 2) // draw two peaks, on both sides
				{
					drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size.x + peak_offsetX - peak_size.x), peak_size,
						autocvar_hud_progressbar_speed_color, top_speed_f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
					drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size.x - peak_offsetX + peak_size.x), peak_size,
						autocvar_hud_progressbar_speed_color, top_speed_f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
				else
					drawfill(panel_pos + speed_offset + eX * (peak_offsetX - peak_size.x), peak_size,
						autocvar_hud_progressbar_speed_color, top_speed_f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
		}
		else
			top_speed = 0;
	}

	const int acc_decimals = 2;
	if (time > physics_update_time)
	{
		discrete_speed      = speed;
		discrete_top_speed  = top_speed;
		discrete_accel      = accel;
		// workaround for ftos_decimals returning a negative 0
		if (discrete_accel > -1 / (10 ** acc_decimals) && discrete_accel < 0)
			discrete_accel = 0;
		physics_update_time += autocvar_hud_panel_physics_update_interval;
		if (physics_update_time < time)
			physics_update_time = time + autocvar_hud_panel_physics_update_interval;
	}

	// draw speed text
	if (autocvar_hud_panel_physics_text == PHYSICS_TEXT_BOTH || autocvar_hud_panel_physics_text == PHYSICS_TEXT_SPEED)
	{
		tmp_size.x   = panel_size.x * speed_size;
		tmp_size.y   = panel_size.y * text_scale;
		tmp_offset.x = speed_baralign ? panel_size.x * (1 - speed_size) : 0;
		tmp_offset.y = (panel_size.y - tmp_size.y) / 2;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(discrete_speed), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

		if (autocvar_hud_panel_physics_speed_unit_show)
			text_bits |= BIT(2);
	}

	// draw acceleration
	if (accel)
	if (autocvar_hud_panel_physics_progressbar == PHYSICS_PROGRESSBAR_BOTH || autocvar_hud_panel_physics_progressbar == PHYSICS_PROGRESSBAR_ACCEL)
	{
		vector progressbar_color;
		if (accel < 0)
			progressbar_color = autocvar_hud_progressbar_acceleration_neg_color;
		else
			progressbar_color = autocvar_hud_progressbar_acceleration_color;

		float accel_max = onslick && autocvar_hud_panel_physics_acceleration_max_slick != -1
			? autocvar_hud_panel_physics_acceleration_max_slick
			: autocvar_hud_panel_physics_acceleration_max;
		float f = accel / accel_max;
		if (autocvar_hud_panel_physics_acceleration_progressbar_nonlinear)
			f = (f >= 0 ? sqrt(f) : -sqrt(-f));

		if (accel_progressbar_scale) // allow progressbar to go out of panel bounds
		{
			tmp_size = accel_progressbar_scale * panel_size.x * eX + panel_size.y * eY;

			if (accel_baralign == 1)
				tmp_offset.x = panel_size.x - tmp_size.x;
			else if (accel_baralign == 2 || accel_baralign == 3)
				tmp_offset.x = (panel_size.x - tmp_size.x) / 2;
			else
				tmp_offset.x = 0;
			tmp_offset.y = 0;
		}
		else
		{
			tmp_size = panel_size;
			tmp_offset = '0 0 0';
		}

		HUD_Panel_DrawProgressBar(panel_pos + accel_offset + tmp_offset, tmp_size, "accelbar", f, 0, accel_baralign,
			progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	// draw acceleration text
	if (autocvar_hud_panel_physics_text == PHYSICS_TEXT_BOTH || autocvar_hud_panel_physics_text == PHYSICS_TEXT_ACCEL)
	{
		tmp_size.x = panel_size.x;
		tmp_size.y = panel_size.y * text_scale;
		tmp_offset.x = 0;
		tmp_offset.y = (panel_size.y - tmp_size.y) / 2;
		drawstring_aspect(panel_pos + accel_offset + tmp_offset, strcat(ftos_decimals(discrete_accel, acc_decimals), "g"), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	tmp_size.x   = panel_size.x * (1 - speed_size);
	tmp_offset.x = speed_baralign ? 0 : panel_size.x * speed_size;
	float top_speed_y = 0, jump_speed_y = 0, main_text_size; // speed unit is not main text

	// draw speed unit text
	if ((text_bits & BIT(2)) && text_bits != BITS(3)) // can't draw all 3 texts at once, speed unit has the lowest priority
	{
		if (text_bits == BIT(2)) // it's the only text drawn, so make it large and centered
		{
			main_text_size = 1 - 0.8; // make the main text small, so the non-main text (speed unit) is large
			tmp_offset.y = panel_size.y * main_text_size / 2; // offset halved to center text
		}
		else
		{
			main_text_size = 0.6; // make the main text slightly larger, since it's more important
			tmp_offset.y = 0;
			top_speed_y  = panel_size.y * (1 - main_text_size);
			jump_speed_y = top_speed_y;
		}
		tmp_size.y    =  panel_size.y * (1 - main_text_size) * text_scale;
		tmp_offset.y += (panel_size.y * (1 - main_text_size) - tmp_size.y) / 2;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, GetSpeedUnit(autocvar_hud_speed_unit), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else if (text_bits == BIT(0) || text_bits == BIT(1)) // only one text is drawn, make it large and centered
	{
		main_text_size = 0.8;
		top_speed_y  = panel_size.y * (1 - main_text_size) / 2; // offset halved to center text
		jump_speed_y = top_speed_y;
	}
	else // both top speed and jump speed are drawn
	{
		main_text_size = 0.5; // make them equal size
		top_speed_y  = panel_size.y * (1 - main_text_size); // put top speed in the lower slot
		jump_speed_y = 0; // put jump speed in the upper slot
	}

	// draw jump speed text
	tmp_size.y = panel_size.y * main_text_size * text_scale;
	if ((text_bits & BIT(1)) && jump_speed_f > 0)
	{
		jump_speed_y += (panel_size.y * main_text_size - tmp_size.y) / 2;
		tmp_offset.y  = jump_speed_y;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(jump_speed), tmp_size, '0 1 0', jump_speed_f * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	// draw top speed text
	if ((text_bits & BIT(0)) && top_speed_f > 0)
	{
		top_speed_y += (panel_size.y * main_text_size - tmp_size.y) / 2;
		tmp_offset.y = top_speed_y;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(discrete_top_speed), tmp_size, '1 0 0', top_speed_f * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	draw_endBoldFont();
}
