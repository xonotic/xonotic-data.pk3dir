#include "pong.qh"
REGISTER_MINIGAME(pong, _("Pong"));

// minigame flags
const int PONG_STATUS_WAIT = 0x0010; // waiting for players to join
const int PONG_STATUS_PLAY = 0x0020; // playing

// send flags
// (minigame_player) sent when reporting scores
const int PONG_SF_PLAYERSCORE = MINIG_SF_CUSTOM;
// (pong_ball) sent when changing team
const int PONG_SF_BALLTEAM = MINIG_SF_CUSTOM;

// keys
const int PONG_KEY_INCREASE = 0x01; // Move down/right
const int PONG_KEY_DECREASE = 0x02; // Move up/left
const int PONG_KEY_BOTH     = 0x03; // Player jamming keys at ramdom

// fields
const int PONG_MAX_PLAYERS = 4;
const int PONG_SPECTATOR_TEAM = 255; // must be above max teams and equal to or below 255
.int    pong_score;                    // (minigame_player) number of goals
.int    pong_keys;                     // (client) pressed keys
.entity pong_paddles[PONG_MAX_PLAYERS];// (minigame) paddles
.float  pong_length;                   // (pong_paddle/pong_ball) size (0,1)
.entity pong_ai_paddle;                // (pong_ai) controlled paddle entity

#ifdef SVQC

float autocvar_sv_minigames_pong_paddle_size;
float autocvar_sv_minigames_pong_paddle_speed;

float autocvar_sv_minigames_pong_ball_wait;
float autocvar_sv_minigames_pong_ball_speed;
float autocvar_sv_minigames_pong_ball_radius;
float autocvar_sv_minigames_pong_ball_number;

float autocvar_sv_minigames_pong_ai_thinkspeed;
float autocvar_sv_minigames_pong_ai_tolerance;

void pong_ball_think(entity this);

// Throws a ball in a random direction and sets the think function
void pong_ball_throw(entity ball)
{
	float angle;
	do
		angle = random() * (2 * M_PI);
	while ( fabs(sin(angle)) < 0.17 || fabs(cos(angle)) < 0.17 );
	ball.velocity_x = cos(angle)*autocvar_sv_minigames_pong_ball_speed;
	ball.velocity_y = sin(angle)*autocvar_sv_minigames_pong_ball_speed;
	setthink(ball, pong_ball_think);
	ball.nextthink = time;
	ball.team = 0;
	ball.SendFlags |= MINIG_SF_UPDATE|PONG_SF_BALLTEAM;
}

// Think equivalent of pong_ball_throw, used to delay throws
void pong_ball_throwthink(entity this)
{
	pong_ball_throw(this);
}

// Moves ball to the center and stops its motion
void pong_ball_reset(entity ball)
{
	ball.velocity = '0 0 0';
	ball.origin = '0.5 0.5 0';
	setthink(ball, SUB_NullThink);
	ball.team = 0;
	ball.SendFlags |= MINIG_SF_UPDATE|PONG_SF_BALLTEAM;
	setthink(ball, pong_ball_throwthink);
	ball.nextthink = time + autocvar_sv_minigames_pong_ball_wait;
}

// Add the score to the given team in the minigame
void pong_add_score(entity minigame, int team_thrower, int team_receiver, int delta)
{
	if ( !minigame )
		return;

	if ( team_thrower == 0 )
		team_thrower = team_receiver;

	if ( team_thrower == team_receiver )
		delta *= -1;

	entity paddle_thrower = minigame.pong_paddles[team_thrower-1];
	if ( paddle_thrower.realowner.minigame_players )
	{
		paddle_thrower.realowner.minigame_players.pong_score += delta;
		paddle_thrower.realowner.minigame_players.SendFlags |= PONG_SF_PLAYERSCORE;
	}
}

// get point in the box nearest to the given one (2D)
vector box_nearest(vector box_min, vector box_max, vector p)
{
	return vec2( p.x > box_max.x  ? box_max.x  : ( p.x < box_min.x ? box_min.x : p.x ),
		p.y > box_max.y  ? box_max.y  : ( p.y < box_min.y ? box_min.y : p.y ) );
}

void pong_paddle_bounce(entity ball, int pteam)
{
	switch(pteam)
	{
		case 1: ball.velocity_x = -fabs(ball.velocity_x); break;
		case 2: ball.velocity_x = fabs(ball.velocity_x); break;
		case 3: ball.velocity_y = fabs(ball.velocity_y); break;
		case 4: ball.velocity_y = -fabs(ball.velocity_y); break;
	}

	float angle = atan2(ball.velocity_y, ball.velocity_x);
	angle += ( random() - 0.5 ) * 2 * M_PI/6;
	float speed = vlen(ball.velocity);

	ball.velocity_y = speed * sin(angle);
	ball.velocity_x = speed * cos(angle);
}

// checks if the ball hit the paddle for the given team
bool pong_paddle_hit(entity ball, int pteam)
{
	entity paddle = ball.owner.pong_paddles[pteam-1];
	if (!paddle)
		return false;

#if 1
	vector near_point = box_nearest(paddle.m_mins+paddle.origin,
									paddle.m_maxs+paddle.origin, ball.origin);
	return vdist(near_point - ball.origin, <=, ball.pong_length);
#else
	return boxesoverlap(paddle.m_mins + paddle.origin, paddle.m_maxs + paddle.origin, ball.m_mins + ball.origin, ball.m_maxs + ball.origin);
#endif
}

// Checks for a goal, when that happes adds scores and resets the ball
bool pong_goal(entity ball, int pteam)
{
	entity paddle = ball.owner.pong_paddles[pteam-1];
	if (!paddle)
		return false;

	if ( !pong_paddle_hit(ball, pteam) )
	{
		pong_add_score(ball.owner ,ball.team, pteam, 1);
		pong_ball_reset(ball);
		return true;
	}

	return false;
}

// Moves the ball around
void pong_ball_think(entity this)
{
	float think_speed = autocvar_sys_ticrate;
	this.nextthink = time + think_speed;

	this.origin_x += this.velocity_x * think_speed;
	this.origin_y += this.velocity_y * think_speed;
	this.SendFlags |= MINIG_SF_UPDATE;

	int i;
	for ( i = 1; i <= PONG_MAX_PLAYERS; ++i )
		if ( pong_paddle_hit(this, i) )
		{
			pong_paddle_bounce(this,i);
			this.team = i;
			this.SendFlags |= PONG_SF_BALLTEAM;
			return;
		}

	if ( this.origin_y <= this.pong_length )
	{
		if ( !pong_goal(this,3) )
		{
			this.origin_y = this.pong_length;
			this.velocity_y *= -1;
		}
	}
	else if ( this.origin_y >= 1-this.pong_length )
	{
		if ( !pong_goal(this,4) )
		{
			this.origin_y = 1-this.pong_length;
			this.velocity_y *= -1;
		}
	}

	if ( this.origin_x <= this.pong_length )
	{
		if ( !pong_goal(this,2) )
		{
			 this.origin_x = this.pong_length;
			 this.velocity_x *= -1;
		}
	}
	else if ( this.origin_x >= 1-this.pong_length )
	{
		if ( !pong_goal(this,1) )
		{
			 this.origin_x = 1-this.pong_length;
			 this.velocity_x *= -1;
		}
	}

}

// AI action
void pong_ai_think(entity this)
{
	float think_speed = autocvar_sv_minigames_pong_ai_thinkspeed;
	this.nextthink = time + think_speed;

	float distance;
	float next_distance;
	float min_distance = 1;
	entity ball = NULL;
	entity mayball = NULL;
	while ( ( mayball = findentity(mayball,owner,this.owner) ) )
		if ( mayball.classname == "pong_ball" )
		{
			distance = vlen(mayball.origin-this.pong_ai_paddle.origin);
			next_distance = vlen(mayball.origin+mayball.velocity-this.pong_ai_paddle.origin);
			if (  distance < min_distance && ( distance < 0.5 || next_distance < distance ) )
			{
				min_distance = distance;
				ball = mayball;
			}
		}

	float target = 0.5;
	float my_pos;


	if ( this.team <= 2 )
	{
		if ( ball )
			target = ball.origin_y + ball.velocity_y*think_speed;
		my_pos = this.pong_ai_paddle.origin_y;
	}
	else
	{
		if ( ball )
			target = ball.origin_x + ball.velocity_x*think_speed;
		my_pos = this.pong_ai_paddle.origin_x;
	}

	distance = this.pong_length/2 * autocvar_sv_minigames_pong_ai_tolerance
		+ autocvar_sv_minigames_pong_paddle_speed * think_speed;

	if (target < my_pos - distance)
		this.pong_keys = PONG_KEY_DECREASE;
	else if (target > my_pos + distance)
		this.pong_keys = PONG_KEY_INCREASE;
	else
		this.pong_keys = 0;
}

entity pong_ai_spawn(entity paddle)
{
	entity ai = msle_spawn(paddle.owner,new(pong_ai));
	ai.minigame_players = ai;
	ai.team = paddle.team;
	setthink(ai, pong_ai_think);
	ai.nextthink = time;
	ai.pong_ai_paddle = paddle;

	paddle.realowner = ai;

	return ai;
}

// Moves the paddle
void pong_paddle_think(entity this)
{
	float think_speed = autocvar_sys_ticrate;
	this.nextthink = time + think_speed;

	if ( this.realowner.minigame_players.pong_keys == PONG_KEY_INCREASE ||
		 this.realowner.minigame_players.pong_keys == PONG_KEY_DECREASE )
	{
		float pmovement = autocvar_sv_minigames_pong_paddle_speed * think_speed;
		float halflen = this.pong_length/2;

		if ( this.realowner.minigame_players.pong_keys == PONG_KEY_DECREASE )
			pmovement *= -1;

		if ( this.team > 2 )
			this.origin_x = bound(halflen, this.origin_x+pmovement, 1-halflen);
		else
			this.origin_y = bound(halflen, this.origin_y+pmovement, 1-halflen);

		this.SendFlags |= MINIG_SF_UPDATE;
	}
}

vector pong_team_to_box_halfsize(int nteam, float length, float width)
{
	if ( nteam > 2 )
		return vec2(length/2, width/2);
	return vec2(width/2, length/2);
}

vector pong_team_to_paddlepos(int nteam)
{
	switch(nteam)
	{
		case 1: return '0.99 0.5 0';
		case 2: return '0.01 0.5 0';
		case 3: return '0.5 0.01 0';
		case 4: return '0.5 0.99 0';
		default:return '0 0 0';
	}
}

// Spawns a pong paddle
// if real_player is NULL, the paddle is controlled by AI
entity pong_paddle_spawn(entity minigame, int pl_team, entity real_player)
{
	entity paddle = msle_spawn(minigame,new(pong_paddle));
	paddle.pong_length = autocvar_sv_minigames_pong_paddle_size;
	paddle.origin = pong_team_to_paddlepos(pl_team);
	setthink(paddle, pong_paddle_think);
	paddle.nextthink = time;
	paddle.team = pl_team;
	paddle.m_mins = pong_team_to_box_halfsize(pl_team,-paddle.pong_length,-1/16);
	paddle.m_maxs = pong_team_to_box_halfsize(pl_team,paddle.pong_length,1/16);

	if ( real_player == NULL )
		pong_ai_spawn(paddle);
	else
		paddle.realowner = real_player;

	minigame.pong_paddles[pl_team-1] = paddle;

	return paddle;

}

// required function, handle server side events
int pong_server_event(entity minigame, string event, ...)
{
	switch (event)
	{
		case "start":
		{
			minigame.minigame_flags |= PONG_STATUS_WAIT;
			return true;
		}
		case "join":
		{
			// Don't allow joining a match that is already running
			if ( minigame.minigame_flags & PONG_STATUS_PLAY )
				return PONG_SPECTATOR_TEAM;

			entity player = ...(0,entity);
			int i;
			for ( i = 0; i < PONG_MAX_PLAYERS; ++i )
			{
				if ( minigame.pong_paddles[i] == NULL )
				{
					pong_paddle_spawn(minigame,i+1,player);
					return i+1;
				}
			}

			return PONG_SPECTATOR_TEAM;
		}
		case "part":
		{
			entity player = ...(0,entity);
			entity paddle;
			entity ai;
			int i;
			for ( i = 0; i < PONG_MAX_PLAYERS; ++i )
			{
				paddle = minigame.pong_paddles[i];
				if ( paddle != NULL && paddle.realowner == player )
				{
					ai = pong_ai_spawn(paddle);
					ai.pong_score = player.minigame_players.pong_score;
					break;
				}

			}
			return false;
		}
		case "cmd":
		{
			entity player = ...(0,entity);
			bool event_blocked = (player.team == PONG_SPECTATOR_TEAM);
			switch(argv(0))
			{
				case "throw":
					if(event_blocked)
						return true;
					if ( minigame.minigame_flags & PONG_STATUS_WAIT )
					{
						minigame.minigame_flags = PONG_STATUS_PLAY |
							(minigame.minigame_flags & ~PONG_STATUS_WAIT);
						minigame.SendFlags |= MINIG_SF_UPDATE;

						entity ball;
						for ( int j = 0; j < autocvar_sv_minigames_pong_ball_number; ++j )
						{
							ball = msle_spawn(minigame,new(pong_ball));
							ball.pong_length = autocvar_sv_minigames_pong_ball_radius;
							ball.m_mins = vec2(-ball.pong_length, -ball.pong_length);
							ball.m_maxs = vec2(ball.pong_length, ball.pong_length);
							pong_ball_reset(ball);
						}
					}
					return true;
				case "+movei":
					if(event_blocked)
						return true;
					player.pong_keys |= PONG_KEY_INCREASE;
					return true;
				case "+moved":
					if(event_blocked)
						return true;
					player.pong_keys |= PONG_KEY_DECREASE;
					return true;
				case "-movei":
					if(event_blocked)
						return true;
					player.pong_keys &= ~PONG_KEY_INCREASE;
					return true;
				case "-moved":
					if(event_blocked)
						return true;
					player.pong_keys &= ~PONG_KEY_DECREASE;
					return true;
				case "move":
					if(event_blocked)
						return true;
					if(argv(1))
						player.pong_keys = stoi(argv(1));
					return true;
				case "pong_aimore":
				{
					if(event_blocked)
						return true;
					// keep declaration here, moving it into for() reverses weapon order
					// potentially compiler bug
					int j;
					if ( minigame.minigame_flags & PONG_STATUS_WAIT )
						for ( j = 0; j < PONG_MAX_PLAYERS; ++j )
						//for ( int j = 0; j < PONG_MAX_PLAYERS; ++j )
						{
							if ( minigame.pong_paddles[j] == NULL )
							{
								pong_paddle_spawn(minigame,j+1,NULL);
								return true;
							}
						}
					sprint(player.minigame_players,"Cannot spawn AI\n");
					return true;
				}
				case "pong_ailess":
				{
					if(event_blocked)
						return true;
					if ( minigame.minigame_flags & PONG_STATUS_WAIT )
					{
						entity paddle;
						for ( int j = PONG_MAX_PLAYERS-1; j >= 0; --j )
						{
							paddle = minigame.pong_paddles[j];
							if ( paddle != NULL &&
								paddle.realowner.classname == "pong_ai" )
							{
								minigame.pong_paddles[j] = NULL;
								delete(paddle.realowner);
								delete(paddle);
								return true;
							}
						}
					}
					sprint(player.minigame_players,"Cannot remove AI\n");
					return true;
				}

			}
			return false;
		}
		case "network_send":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame_player" && (sf & PONG_SF_PLAYERSCORE ) )
			{
				WriteLong(MSG_ENTITY,sent.pong_score);
			}
			return false;
		}
	}
	return false;
}


#elif defined(CSQC)

void drawrotpic(vector org, float rot, string pic, vector sz, vector hotspot, vector rgb, float a, float f);

float pong_team_to_angle(int nteam)
{
	switch(nteam)
	{
		default:
		case 1: return 0;
		case 2: return M_PI;
		case 3: return M_PI*3/2;
		case 4: return M_PI/2;
	}
}

vector pong_team_to_color(int nteam)
{
	switch(nteam)
	{
		case 1: return '1 0 0';
		case 2: return '0 0 1';
		case 3: return '1 1 0';
		case 4: return '1 0 1';
		default:return '1 1 1';
	}
}

int pong_keys_pressed;
int pong_keys_pressed_old;

// Required function, draw the game board
void pong_hud_board(vector pos, vector mySize)
{
	if(pong_keys_pressed != pong_keys_pressed_old)
		minigame_cmd(strcat("move ", itos(pong_keys_pressed)));
	pong_keys_pressed_old = pong_keys_pressed;

	minigame_hud_fitsqare(pos, mySize);
	minigame_hud_simpleboard(pos,mySize,minigame_texture("pong/board"));

	entity e;
	vector obj_pos;
	vector obj_size;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "pong_ball" )
		{
			// Note: 4*radius = 2*diameter because the image is large enough to fit the glow around the ball
			obj_size =  minigame_hud_denormalize_size('4 4 0'*e.pong_length,pos,mySize);
			obj_pos = minigame_hud_denormalize(e.origin,pos,mySize);

			minigame_drawpic_centered( obj_pos, minigame_texture("pong/ball"),
					obj_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );

			minigame_drawpic_centered( obj_pos, minigame_texture("pong/ball-glow"),
					obj_size, pong_team_to_color(e.team),
					panel_fg_alpha, DRAWFLAG_ADDITIVE );
		}
		else if ( e.classname == "pong_paddle" )
		{
			obj_pos = minigame_hud_denormalize(e.origin,pos,mySize);
			obj_size = minigame_hud_denormalize_size(eX / 16 + eY*e.pong_length,pos,mySize);

			drawrotpic(obj_pos, pong_team_to_angle(e.team), minigame_texture("pong/paddle-glow"),
				obj_size, obj_size/2, pong_team_to_color(e.team),
				panel_fg_alpha, DRAWFLAG_ADDITIVE );

			drawrotpic(obj_pos, pong_team_to_angle(e.team), minigame_texture("pong/paddle"),
				obj_size, obj_size/2, '1 1 1',
				panel_fg_alpha, DRAWFLAG_NORMAL );

		}
	}

	minigame_show_allspecs(pos, mySize);
}

// Required function, draw the game status panel
void pong_hud_status(vector pos, vector mySize)
{
	HUD_Panel_DrawBg();
	vector ts;
	ts = minigame_drawstring_wrapped(mySize_x,pos,active_minigame.descriptor.message,
		hud_fontsize * 2, '0.25 0.47 0.72', panel_fg_alpha, DRAWFLAG_NORMAL,0.5);
	ts_y += hud_fontsize_y;
	pos_y += ts_y;
	mySize_y -= ts_y;

	vector player_fontsize = hud_fontsize * 1.75;
	ts_y = ( mySize_y - PONG_MAX_PLAYERS*player_fontsize_y ) / PONG_MAX_PLAYERS;
	ts_x = mySize_x;
	vector mypos;

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( (e.classname == "minigame_player" || e.classname == "pong_ai") && e.team != PONG_SPECTATOR_TEAM )
		{
			mypos = pos;
			mypos_y  += (e.team-1) * (player_fontsize_y + ts_y);

			drawfill(mypos, ts, pong_team_to_color(e.team), 0.25 * panel_fg_alpha, DRAWFLAG_ADDITIVE);

			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				(e.minigame_playerslot ? entcs_GetName(e.minigame_playerslot-1) : _("AI")),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			drawstring(mypos+eY*player_fontsize_y,ftos(e.pong_score),'48 48 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			if ( e == minigame_self )
				drawborderlines(1, mypos, ts, pong_team_to_color(e.team), 1, DRAWFLAG_NORMAL);
		}
	}
}

// convert minigame flags to a message
string pong_message(int mgflags)
{
	string rmessage = "";
	if(minigame_self.team == PONG_SPECTATOR_TEAM)
		rmessage = _("You are spectating");
	else if (mgflags & PONG_STATUS_WAIT)
		rmessage = _("Press ^1Start Match^7 to start the match with the current players");
	return rmessage;
}

// Required function, handle client events
int pong_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
			return false;
		case "deactivate":
		{
			strfree(minigame.message);
			return false;
		}
		case "key_pressed":
		case "key_released":
			if ((minigame.minigame_flags & PONG_STATUS_PLAY) && minigame_self.team != PONG_SPECTATOR_TEAM)
				switch ( ...(0,int) )
				{
					case K_UPARROW:
					case K_KP_UPARROW:
					case K_LEFTARROW:
					case K_KP_LEFTARROW:
						if (event == "key_pressed")
						{
							//minigame_cmd("+moved");
							pong_keys_pressed |= PONG_KEY_DECREASE;
						}
						else
						{
							//minigame_cmd("-moved");
							pong_keys_pressed &= ~PONG_KEY_DECREASE;
						}
						return true;
					case K_DOWNARROW:
					case K_KP_DOWNARROW:
					case K_RIGHTARROW:
					case K_KP_RIGHTARROW:
						if (event == "key_pressed")
						{
							//minigame_cmd("+movei");
							pong_keys_pressed |= PONG_KEY_INCREASE;
						}
						else
						{
							//minigame_cmd("-movei");
							pong_keys_pressed &= ~PONG_KEY_INCREASE;
						}
						return true;
				}
			return false;
		case "network_receive":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame_player" && (sf & PONG_SF_PLAYERSCORE ) )
			{
				sent.pong_score = ReadLong();
			}
			else if ( sent.classname == "minigame" )
			{
				if ( sf & MINIG_SF_UPDATE )
				{
					strcpy(sent.message, pong_message(sent.minigame_flags));
				}
			}
			return false;
		}
		case "menu_show":
		{
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Start Match"),"pong_throw");
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Add AI player"),"pong_aimore");
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Remove AI player"),"pong_ailess");
			return false;
		}
		case "menu_click":
		{
			string cmd = ...(0,string);
			if( cmd == "pong_throw" && ( minigame.minigame_flags & PONG_STATUS_WAIT ) )
			{
				minigame_cmd("throw");
			}
			else if ( cmd == "pong_aimore" || cmd == "pong_ailess" )
			{
				minigame_cmd(cmd);
			}
			return false;
		}
	}

	return false;
}
#endif
