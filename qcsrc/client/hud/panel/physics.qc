#include "physics.qh"

#include <client/draw.qh>
#include <lib/csqcmodel/cl_player.qh>

// Physics (#15)

void HUD_Physics_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_physics_speed_unit_show");
	HUD_Write_Cvar("hud_panel_physics_speed_max");
	HUD_Write_Cvar("hud_panel_physics_speed_vertical");
	HUD_Write_Cvar("hud_panel_physics_topspeed");
	HUD_Write_Cvar("hud_panel_physics_topspeed_time");
	HUD_Write_Cvar("hud_panel_physics_acceleration_max");
	HUD_Write_Cvar("hud_panel_physics_acceleration_vertical");
	HUD_Write_Cvar("hud_panel_physics_flip");
	HUD_Write_Cvar("hud_panel_physics_baralign");
	HUD_Write_Cvar("hud_panel_physics_progressbar");
	HUD_Write_Cvar("hud_panel_physics_acceleration_progressbar_mode");
	HUD_Write_Cvar("hud_panel_physics_acceleration_progressbar_scale");
	HUD_Write_Cvar("hud_panel_physics_acceleration_progressbar_nonlinear");
	HUD_Write_Cvar("hud_panel_physics_text");
	HUD_Write_Cvar("hud_panel_physics_text_scale");
}

vector acc_prevspeed;
float acc_prevtime, acc_avg, top_speed, top_speed_time;
float physics_update_time, discrete_speed, discrete_acceleration;
void HUD_Physics()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_physics) return;
		if(spectatee_status == -1 && (autocvar_hud_panel_physics == 1 || autocvar_hud_panel_physics == 3)) return;
		if(autocvar_hud_panel_physics == 3 && !MUTATOR_CALLHOOK(HUD_Physics_showoptional)) return;
	}

	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	if (autocvar_hud_panel_physics_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	float acceleration_progressbar_scale = 0;
	if(autocvar_hud_panel_physics_progressbar && autocvar_hud_panel_physics_acceleration_progressbar_scale > 1)
		acceleration_progressbar_scale = autocvar_hud_panel_physics_acceleration_progressbar_scale;

	float text_scale;
	if (autocvar_hud_panel_physics_text_scale <= 0)
		text_scale = 1;
	else
		text_scale = min(autocvar_hud_panel_physics_text_scale, 1);

	//compute speed
	float speed, conversion_factor = GetSpeedUnitFactor(autocvar_hud_panel_physics_speed_unit);
	vector vel = (csqcplayer ? csqcplayer.velocity : pmove_vel);

	float max_speed = floor( autocvar_hud_panel_physics_speed_max * conversion_factor + 0.5 );
	if (autocvar__hud_configure)
		speed = floor( max_speed * 0.65 + 0.5 );
	else if(autocvar_hud_panel_physics_speed_vertical)
		speed = floor( vlen(vel) * conversion_factor + 0.5 );
	else
		speed = floor( vlen(vel - vel.z * '0 0 1') * conversion_factor + 0.5 );

	//compute acceleration
	float acceleration, f;
	if (autocvar__hud_configure)
		acceleration = autocvar_hud_panel_physics_acceleration_max * 0.3;
	else
	{
		// 1 m/s = 0.0254 qu/s; 1 g = 9.80665 m/s^2
		f = time - acc_prevtime;
		if(autocvar_hud_panel_physics_acceleration_vertical)
			acceleration = (vlen(vel) - vlen(acc_prevspeed));
		else
			acceleration = (vlen(vel - '0 0 1' * vel.z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed.z));

		acceleration = acceleration * (1 / max(0.0001, f)) * (0.0254 / 9.80665);

		acc_prevspeed = vel;
		acc_prevtime = time;

		if(autocvar_hud_panel_physics_acceleration_movingaverage)
		{
			f = bound(0, f * 10, 1);
			acc_avg = acc_avg * (1 - f) + acceleration * f;
			acceleration = acc_avg;
		}
	}

	const int acc_decimals = 2;
	if(time > physics_update_time)
	{
		discrete_acceleration = acceleration;
		// workaround for ftos_decimals returning a negative 0
		if(discrete_acceleration > -1 / (10 ** acc_decimals) && discrete_acceleration < 0)
			discrete_acceleration = 0;
		discrete_speed = speed;
		physics_update_time += autocvar_hud_panel_physics_update_interval;
		if(physics_update_time < time)
			physics_update_time = time + autocvar_hud_panel_physics_update_interval;
	}

	//compute layout
	float panel_ar = panel_size.x/panel_size.y;
	vector speed_offset = '0 0 0', acceleration_offset = '0 0 0';
	if (panel_ar >= 5 && !acceleration_progressbar_scale)
	{
		panel_size.x *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset.x = panel_size.x;
		else
			acceleration_offset.x = panel_size.x;
	}
	else
	{
		panel_size.y *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset.y = panel_size.y;
		else
			acceleration_offset.y = panel_size.y;
	}
	int speed_baralign, acceleration_baralign;
	if (autocvar_hud_panel_physics_baralign == 1)
		acceleration_baralign = speed_baralign = 1;
	else if(autocvar_hud_panel_physics_baralign == 4)
		acceleration_baralign = speed_baralign = 2;
	else if (autocvar_hud_panel_physics_flip)
	{
		acceleration_baralign = (autocvar_hud_panel_physics_baralign == 2);
		speed_baralign = (autocvar_hud_panel_physics_baralign == 3);
	}
	else
	{
		speed_baralign = (autocvar_hud_panel_physics_baralign == 2);
		acceleration_baralign = (autocvar_hud_panel_physics_baralign == 3);
	}
	if (autocvar_hud_panel_physics_acceleration_progressbar_mode == 0)
		acceleration_baralign = 3; //override hud_panel_physics_baralign value for acceleration

	//draw speed
	if(speed)
	if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 2)
		HUD_Panel_DrawProgressBar(panel_pos + speed_offset, panel_size, "progressbar", speed/max_speed, 0, speed_baralign, autocvar_hud_progressbar_speed_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	vector tmp_offset = '0 0 0', tmp_size = '0 0 0';
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 2)
	{
		tmp_size.x = panel_size.x * 0.75;
		tmp_size.y = panel_size.y * text_scale;
		if (speed_baralign)
			tmp_offset.x = panel_size.x - tmp_size.x;
		//else
			//tmp_offset_x = 0;
		tmp_offset.y = (panel_size.y - tmp_size.y) / 2;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(discrete_speed), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

		//draw speed unit
		if (speed_baralign)
			tmp_offset.x = 0;
		else
			tmp_offset.x = tmp_size.x;
		if (autocvar_hud_panel_physics_speed_unit_show)
		{
			//tmp_offset_y = 0;
			tmp_size.x = panel_size.x * (1 - 0.75);
			tmp_size.y = panel_size.y * 0.4 * text_scale;
			tmp_offset.y = (panel_size.y * 0.4 - tmp_size.y) / 2;
			string unit = GetSpeedUnit(autocvar_hud_panel_physics_speed_unit);
			drawstring_aspect(panel_pos + speed_offset + tmp_offset, unit, tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}

	//compute and draw top speed
	if (autocvar_hud_panel_physics_topspeed)
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 2)
	{
		if (autocvar__hud_configure)
		{
			top_speed = floor( max_speed * 0.75 + 0.5 );
			f = 1;
		}
		else
		{
			if (speed >= top_speed)
			{
				top_speed = speed;
				top_speed_time = time;
			}
			if (top_speed != 0)
			{
				f = max(1, autocvar_hud_panel_physics_topspeed_time);
				// divide by f to make it start from 1
				f = cos( ((time - top_speed_time) / f) * PI/2 );
			}
			else // hide top speed 0
				f = 0;
		}
		if (f > 0)
		{
			//top speed progressbar peak
			if(speed < top_speed)
			if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 2)
			{
				float peak_offsetX;
				vector peak_size = '0 0 0';
				if (speed_baralign == 0)
					peak_offsetX = min(top_speed, max_speed)/max_speed * panel_size.x;
				else if (speed_baralign == 1)
					peak_offsetX = (1 - min(top_speed, max_speed)/max_speed) * panel_size.x;
				else // if (speed_baralign == 2)
					peak_offsetX = min(top_speed, max_speed)/max_speed * panel_size.x * 0.5;
				peak_size.x = floor(panel_size.x * 0.01 + 1.5);
				peak_size.y = panel_size.y;
				if (speed_baralign == 2) // draw two peaks, on both sides
				{
					drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size.x + peak_offsetX - peak_size.x), peak_size, autocvar_hud_progressbar_speed_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
					drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size.x - peak_offsetX + peak_size.x), peak_size, autocvar_hud_progressbar_speed_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
				else
					drawfill(panel_pos + speed_offset + eX * (peak_offsetX - peak_size.x), peak_size, autocvar_hud_progressbar_speed_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}

			//top speed
			tmp_offset.y = panel_size.y * 0.4;
			tmp_size.x = panel_size.x * (1 - 0.75);
			tmp_size.y = (panel_size.y - tmp_offset.y) * text_scale;
			tmp_offset.y += (panel_size.y - tmp_offset.y - tmp_size.y) / 2;
			drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(top_speed), tmp_size, '1 0 0', f * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		else
			top_speed = 0;
	}

	//draw acceleration
	if(acceleration)
	if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 3)
	{
		vector progressbar_color;
		if(acceleration < 0)
			progressbar_color = autocvar_hud_progressbar_acceleration_neg_color;
		else
			progressbar_color = autocvar_hud_progressbar_acceleration_color;

		f = acceleration/autocvar_hud_panel_physics_acceleration_max;
		if (autocvar_hud_panel_physics_acceleration_progressbar_nonlinear)
			f = (f >= 0 ? sqrt(f) : -sqrt(-f));

		if (acceleration_progressbar_scale) // allow progressbar to go out of panel bounds
		{
			tmp_size = acceleration_progressbar_scale * panel_size.x * eX + panel_size.y * eY;

			if (acceleration_baralign == 1)
				tmp_offset.x = panel_size.x - tmp_size.x;
			else if (acceleration_baralign == 2 || acceleration_baralign == 3)
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

		HUD_Panel_DrawProgressBar(panel_pos + acceleration_offset + tmp_offset, tmp_size, "accelbar", f, 0, acceleration_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if(autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 3)
	{
		tmp_size.x = panel_size.x;
		tmp_size.y = panel_size.y * text_scale;
		tmp_offset.x = 0;
		tmp_offset.y = (panel_size.y - tmp_size.y) / 2;

		drawstring_aspect(panel_pos + acceleration_offset + tmp_offset, strcat(ftos_decimals(discrete_acceleration, acc_decimals), "g"), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	draw_endBoldFont();
}
