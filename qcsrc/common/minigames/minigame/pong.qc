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
.float  pong_length;                   // (pong_paddle) size (0,1)
.entity pong_ai_paddle;                // (pong_ai) controlled paddle entity

#ifdef SVQC

float autocvar_sv_minigames_pong_paddle_size   = 0.3;
float autocvar_sv_minigames_pong_paddle_speed  = 0.75;
float autocvar_sv_minigames_pong_ball_wait     = 1;
float autocvar_sv_minigames_pong_ball_speed    = 1;
float autocvar_sv_minigames_pong_ai_thinkspeed = 0.1;
float autocvar_sv_minigames_pong_ai_tolerance  = 0.33;

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
{
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

bool pong_paddlemiss(float ball_coord, float pad_coord, float pad_len)
{
	return ball_coord < pad_coord - pad_len/2 || ball_coord > pad_coord + pad_len/2;
}

// Checks for a goal, when that happes adds scores and resets the ball
bool pong_goal(entity ball, int pteam)
{
	entity paddle = ball.owner.pong_paddles[pteam-1];
	if (!paddle)
		return false;
	
	if ( (pteam > 2 && pong_paddlemiss(ball.origin_x,paddle.origin_x,paddle.pong_length)) ||
		pong_paddlemiss(ball.origin_y,paddle.origin_y,paddle.pong_length) )
	{
		pong_add_score(ball.owner ,ball.team, pteam, 1);
		pong_ball_reset(ball);
		return true;
	}
	else
	{
		ball.team = pteam;
		ball.SendFlags |= PONG_SF_BALLTEAM;
	}
	
	return false;
}

// Moves the ball around
void pong_ball_think()
{
	float think_speed = autocvar_sys_ticrate;
	self.nextthink = time + think_speed;
	
	self.origin_x += self.velocity_x * think_speed;
	self.origin_y += self.velocity_y * think_speed;
	
	// TODO consider the ball's radius (and add cvar for that)
	if ( self.origin_y <= 0 )
	{
		if ( !pong_goal(self,3) )
		{
			self.origin_y = 0;
			self.velocity_y *= -1;
		}
	}
	else if ( self.origin_y >= 1 )
	{
		if ( !pong_goal(self,4) )
		{
			self.origin_y = 1;
			self.velocity_y *= -1;
		}
	}
	
	if ( self.origin_x <= 0 )
	{
		if ( !pong_goal(self,2) )
		{
			 self.origin_x = 0;
			 self.velocity_x *= -1;
		}
	}
	else if ( self.origin_x >= 1 )
	{
		if ( !pong_goal(self,1) )
		{
			 self.origin_x = 1;
			 self.velocity_x *= -1;
		}
	}
	
	self.SendFlags |= MINIG_SF_UPDATE;
}

// AI action
void pong_ai_think()
{
	float think_speed = autocvar_sv_minigames_pong_ai_thinkspeed;
	self.nextthink = time + think_speed;
	
	float distance = self.pong_length/2 * autocvar_sv_minigames_pong_ai_tolerance;
	distance += autocvar_sv_minigames_pong_paddle_speed * think_speed;
	float target;
	float self_pos;
	
	entity ball = world;
	self.pong_keys = 0;
	while ( ( ball = findentity(ball,owner,self.owner) ) )
		if ( ball.classname == "pong_ball" )
		{			
			if ( self.team <= 2 )
			{
				target = ball.origin_y + ball.velocity_y*think_speed;
				if ( ( self.team == 1 && ball.origin_x < 0.5 && ball.velocity_x < 0 ) ||
						( self.team == 2 && ball.origin_x > 0.5 && ball.velocity_x > 0 ) )
					target = 0.5;
				self_pos = self.pong_ai_paddle.origin_y;
			}
			else
			{
				target = ball.origin_x + ball.velocity_x*think_speed;
				if ( ( self.team == 4 && ball.origin_y < 0.5 && ball.velocity_y < 0 ) ||
						( self.team == 3 && ball.origin_y > 0.5 && ball.velocity_y > 0 ) )
					target = 0.5;
				self_pos = self.pong_ai_paddle.origin_x;
			}
			
			if (target < self_pos - distance)
				self.pong_keys = PONG_KEY_DECREASE;
			else if (target > self_pos + distance)
				self.pong_keys = PONG_KEY_INCREASE;
			
			break; // TODO support multiple balls?
		}
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
{
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
			int i;
			for ( i = 0; i < PONG_MAX_PLAYERS; i++ )
			{
				paddle = minigame.pong_paddles[i];
				if ( paddle != world && paddle.realowner == player )
				{
					pong_ai_spawn(paddle);
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
						
						entity ball = msle_spawn(minigame,"pong_ball");
						pong_ball_reset(ball);
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

#include "waypointsprites.qh" // drawrotpic

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
	vector ball_size = minigame_hud_denormalize_size('1 1 0' / 16,pos,mySize);
	vector paddle_size;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "pong_ball" )
		{
			obj_pos = minigame_hud_denormalize(e.origin,pos,mySize);
			minigame_drawpic_centered( obj_pos, minigame_texture("pong/ball"),
					ball_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
			
			minigame_drawpic_centered( obj_pos, minigame_texture("pong/ball"),
					ball_size, pong_team_to_color(e.team), 
					panel_fg_alpha, DRAWFLAG_ADDITIVE );
		}
		else if ( e.classname == "pong_paddle" )
		{
			obj_pos = minigame_hud_denormalize(e.origin,pos,mySize);
			paddle_size = minigame_hud_denormalize_size(eX / 16 + eY*e.pong_length,pos,mySize);
			
			drawrotpic(obj_pos, pong_team_to_angle(e.team), minigame_texture("pong/paddle-glow"), 
				paddle_size, paddle_size/2, pong_team_to_color(e.team), 
				panel_fg_alpha, DRAWFLAG_ADDITIVE );
			
			drawrotpic(obj_pos, pong_team_to_angle(e.team), minigame_texture("pong/paddle"), 
				paddle_size, paddle_size/2, '1 1 1', 
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