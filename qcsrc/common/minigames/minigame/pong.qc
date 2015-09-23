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

void pong_ball_think();

// Throws a ball in a random direction and sets the think function
void pong_ball_throw(entity ball)
{
	float angle;
	do
		angle = random()*M_PI*2;
	while ( fabs(sin(angle)) < 0.17 || fabs(cos(angle)) < 0.17 );
	ball.velocity_x = cos(angle)*autocvar_sv_minigames_pong_ball_speed;
	ball.velocity_y = sin(angle)*autocvar_sv_minigames_pong_ball_speed;
	ball.think = pong_ball_think;
	ball.nextthink = time;
	ball.team = 0;
	ball.SendFlags |= MINIG_SF_UPDATE|PONG_SF_BALLTEAM;
}

// Think equivalent of pong_ball_throw, used to delay throws
void pong_ball_throwthink()
{SELFPARAM();
	pong_ball_throw(self);
}

// Moves ball to the center and stops its motion
void pong_ball_reset(entity ball)
{
	ball.velocity = '0 0 0';
	ball.origin = '0.5 0.5 0';
	ball.think = SUB_NullThink;
	ball.team = 0;
	ball.SendFlags |= MINIG_SF_UPDATE|PONG_SF_BALLTEAM;
	ball.think = pong_ball_throwthink;
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
	return eX * ( p_x > box_max_x  ? box_max_x  : ( p_x < box_min_x ? box_min_x : p_x ) )
		+ eY * ( p_y > box_max_y  ? box_max_y  : ( p_y < box_min_y ? box_min_y : p_y ) );
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
	vector near_point = box_nearest(paddle.mins+paddle.origin,
									paddle.maxs+paddle.origin, ball.origin);
	return vlen(near_point-ball.origin) <= ball.pong_length ;
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
void pong_ball_think()
{SELFPARAM();
	float think_speed = autocvar_sys_ticrate;
	self.nextthink = time + think_speed;

	self.origin_x += self.velocity_x * think_speed;
	self.origin_y += self.velocity_y * think_speed;
	self.SendFlags |= MINIG_SF_UPDATE;

	int i;
	for ( i = 1; i <= PONG_MAX_PLAYERS; i++ )
		if ( pong_paddle_hit(self, i) )
		{
			pong_paddle_bounce(self,i);
			self.team = i;
			self.SendFlags |= PONG_SF_BALLTEAM;
			return;
		}

	if ( self.origin_y <= self.pong_length )
	{
		if ( !pong_goal(self,3) )
		{
			self.origin_y = self.pong_length;
			self.velocity_y *= -1;
		}
	}
	else if ( self.origin_y >= 1-self.pong_length )
	{
		if ( !pong_goal(self,4) )
		{
			self.origin_y = 1-self.pong_length;
			self.velocity_y *= -1;
		}
	}

	if ( self.origin_x <= self.pong_length )
	{
		if ( !pong_goal(self,2) )
		{
			 self.origin_x = self.pong_length;
			 self.velocity_x *= -1;
		}
	}
	else if ( self.origin_x >= 1-self.pong_length )
	{
		if ( !pong_goal(self,1) )
		{
			 self.origin_x = 1-self.pong_length;
			 self.velocity_x *= -1;
		}
	}

}

// AI action
void pong_ai_think()
{SELFPARAM();
	float think_speed = autocvar_sv_minigames_pong_ai_thinkspeed;
	self.nextthink = time + think_speed;

	float distance;
	float next_distance;
	float min_distance = 1;
	entity ball = world;
	entity mayball = world;
	while ( ( mayball = findentity(mayball,owner,self.owner) ) )
		if ( mayball.classname == "pong_ball" )
		{
			distance = vlen(mayball.origin-self.pong_ai_paddle.origin);
			next_distance = vlen(mayball.origin+mayball.velocity-self.pong_ai_paddle.origin);
			if (  distance < min_distance && ( distance < 0.5 || next_distance < distance ) )
			{
				min_distance = distance;
				ball = mayball;
			}
		}

	float target = 0.5;
	float self_pos;


	if ( self.team <= 2 )
	{
		if ( ball )
			target = ball.origin_y + ball.velocity_y*think_speed;
		self_pos = self.pong_ai_paddle.origin_y;
	}
	else
	{
		if ( ball )
			target = ball.origin_x + ball.velocity_x*think_speed;
		self_pos = self.pong_ai_paddle.origin_x;
	}

	distance = self.pong_length/2 * autocvar_sv_minigames_pong_ai_tolerance
		+ autocvar_sv_minigames_pong_paddle_speed * think_speed;

	if (target < self_pos - distance)
		self.pong_keys = PONG_KEY_DECREASE;
	else if (target > self_pos + distance)
		self.pong_keys = PONG_KEY_INCREASE;
	else
		self.pong_keys = 0;
}

entity pong_ai_spawn(entity paddle)
{
	entity ai = msle_spawn(paddle.owner,"pong_ai");
	ai.minigame_players = ai;
	ai.team = paddle.team;
	ai.think = pong_ai_think;
	ai.nextthink = time;
	ai.pong_ai_paddle = paddle;

	paddle.realowner = ai;

	return ai;
}

// Moves the paddle
void pong_paddle_think()
{SELFPARAM();
	float think_speed = autocvar_sys_ticrate;
	self.nextthink = time + think_speed;

	if ( self.realowner.minigame_players.pong_keys == PONG_KEY_INCREASE ||
		 self.realowner.minigame_players.pong_keys == PONG_KEY_DECREASE )
	{
		float movement = autocvar_sv_minigames_pong_paddle_speed * think_speed;
		float halflen = self.pong_length/2;

		if ( self.realowner.minigame_players.pong_keys == PONG_KEY_DECREASE )
			movement *= -1;

		if ( self.team > 2 )
			self.origin_x = bound(halflen, self.origin_x+movement, 1-halflen);
		else
			self.origin_y = bound(halflen, self.origin_y+movement, 1-halflen);

		self.SendFlags |= MINIG_SF_UPDATE;
	}
}

vector pong_team_to_box_halfsize(int nteam, float length, float width)
{
	if ( nteam > 2 )
		return eY*width/2 + eX*length/2;
	return eX*width/2 + eY*length/2;
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
// if real_player is world, the paddle is controlled by AI
entity pong_paddle_spawn(entity minigame, int pl_team, entity real_player)
{
	entity paddle = msle_spawn(minigame,"pong_paddle");
	paddle.pong_length = autocvar_sv_minigames_pong_paddle_size;
	paddle.origin = pong_team_to_paddlepos(pl_team);
	paddle.think = pong_paddle_think;
	paddle.nextthink = time;
	paddle.team = pl_team;
	paddle.mins = pong_team_to_box_halfsize(pl_team,-paddle.pong_length,-1/16);
	paddle.maxs = pong_team_to_box_halfsize(pl_team,paddle.pong_length,1/16);

	if ( real_player == world )
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
				return false;

			entity player = ...(0,entity);
			int i;
			for ( i = 0; i < PONG_MAX_PLAYERS; i++ )
			{
				if ( minigame.pong_paddles[i] == world )
				{
					pong_paddle_spawn(minigame,i+1,player);
					return i+1;
				}
			}

			return false;
		}
		case "part":
		{
			entity player = ...(0,entity);
			entity paddle;
			entity ai;
			int i;
			for ( i = 0; i < PONG_MAX_PLAYERS; i++ )
			{
				paddle = minigame.pong_paddles[i];
				if ( paddle != world && paddle.realowner == player )
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
			switch(argv(0))
			{
				case "throw":
					if ( minigame.minigame_flags & PONG_STATUS_WAIT )
					{
						minigame.minigame_flags = PONG_STATUS_PLAY |
							(minigame.minigame_flags & ~PONG_STATUS_WAIT);
						minigame.SendFlags |= MINIG_SF_UPDATE;

						int i;
						entity ball;
						for ( i = 0; i < autocvar_sv_minigames_pong_ball_number; i++ )
						{
							ball = msle_spawn(minigame,"pong_ball");
							ball.pong_length = autocvar_sv_minigames_pong_ball_radius;
							pong_ball_reset(ball);
						}
					}
					return true;
				case "+movei":
					player.pong_keys |= PONG_KEY_INCREASE;
					return true;
				case "+moved":
					player.pong_keys |= PONG_KEY_DECREASE;
					return true;
				case "-movei":
					player.pong_keys &= ~PONG_KEY_INCREASE;
					return true;
				case "-moved":
					player.pong_keys &= ~PONG_KEY_DECREASE;
					return true;
				case "pong_aimore":
				{
					int i;
					if ( minigame.minigame_flags & PONG_STATUS_WAIT )
						for ( i = 0; i < PONG_MAX_PLAYERS; i++ )
						{
							if ( minigame.pong_paddles[i] == world )
							{
								pong_paddle_spawn(minigame,i+1,world);
								return true;
							}
						}
					sprint(player.minigame_players,"Cannot spawn AI\n");
					return true;
				}
				case "pong_ailess":
				{
					if ( minigame.minigame_flags & PONG_STATUS_WAIT )
					{
						entity paddle;
						int i;
						for ( i = PONG_MAX_PLAYERS-1; i >= 0; i-- )
						{
							paddle = minigame.pong_paddles[i];
							if ( paddle != world &&
								paddle.realowner.classname == "pong_ai" )
							{
								minigame.pong_paddles[i] = world;
								remove(paddle.realowner);
								remove(paddle);
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

// Required function, draw the game board
void pong_hud_board(vector pos, vector mySize)
{
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
}

// Required function, draw the game status panel
void pong_hud_status(vector pos, vector mySize)
{
	HUD_Panel_DrawBg(1);
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
		if ( e.classname == "minigame_player" || e.classname == "pong_ai" )
		{
			mypos = pos;
			mypos_y  += (e.team-1) * (player_fontsize_y + ts_y);

			drawfill(mypos, ts, pong_team_to_color(e.team), 0.25, DRAWFLAG_ADDITIVE);

			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				(e.minigame_playerslot ? GetPlayerName(e.minigame_playerslot-1) : _("AI")),
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
	if (mgflags & PONG_STATUS_WAIT)
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
		case "key_pressed":
			switch ( ...(0,int) )
			{
				case K_UPARROW:
				case K_KP_UPARROW:
				case K_LEFTARROW:
				case K_KP_LEFTARROW:
					minigame_cmd("+moved");
					return true;
				case K_DOWNARROW:
				case K_KP_DOWNARROW:
				case K_RIGHTARROW:
				case K_KP_RIGHTARROW:
					minigame_cmd("+movei");
					return true;
			}
			return false;
		case "key_released":
			switch ( ...(0,int) )
			{
				case K_UPARROW:
				case K_KP_UPARROW:
				case K_LEFTARROW:
				case K_KP_LEFTARROW:
					minigame_cmd("-moved");
					return true;
				case K_DOWNARROW:
				case K_KP_DOWNARROW:
				case K_RIGHTARROW:
				case K_KP_RIGHTARROW:
					minigame_cmd("-movei");
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
					sent.message = pong_message(sent.minigame_flags);
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
			if( cmd == "pong_throw" && minigame.minigame_flags & PONG_STATUS_WAIT )
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
