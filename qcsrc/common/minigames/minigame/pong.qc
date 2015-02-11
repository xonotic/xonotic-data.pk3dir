// send flags
const int PONG_SF_PLAYERSCORE  = MINIG_SF_CUSTOM;   // sent when reporting scores
const int PONG_SF_SINGLEPLAYER = MINIG_SF_CUSTOM<<1;// send minigame.pong_ai

// fields
.int       pong_ai;    // (minigame) when non-zero, singleplayer vs AI
.int       pong_score; // (minigame_player) number of goals
.entity pong_paddles[2];// (minigame) paddles
.float     pong_length;// (pong_paddle) size (0,1)

#ifdef SVQC

float autocvar_sv_minigames_pong_paddlesize = 0.3;
float autocvar_sv_minigames_pong_paddlespeed= 1;
float autocvar_sv_minigames_pong_ballwait   = 1;
float autocvar_sv_minigames_pong_ballspeed  = 1;

void pong_ball_think();

void pong_ball_thinkthrow()
{
	float angle;
	do
		angle = random()*M_PI*2;
	while ( (angle > 0.44*M_PI && angle < 0.55*M_PI) || 
		(angle > 1.44*M_PI && angle < 1.55*M_PI) );
	self.velocity_x = cos(angle)*autocvar_sv_minigames_pong_ballspeed;
	self.velocity_y = sin(angle)*autocvar_sv_minigames_pong_ballspeed;
	self.SendFlags |= MINIG_SF_UPDATE;
	self.think = pong_ball_think;
	self.nextthink = time;
}

void pong_reset_ball(entity ball)
{
	ball.velocity = '0 0 0';
	ball.origin = '0.5 0.5 0';
	ball.SendFlags |= MINIG_SF_UPDATE;
	ball.think = pong_ball_thinkthrow;
	ball.nextthink = time + autocvar_sv_minigames_pong_ballwait;
}

void pong_add_score(entity minigame, int pteam)
{
	if ( !minigame )
		return;
	entity paddle = minigame.pong_paddles[pteam-1];
	if ( paddle.realowner )
	{
		paddle.realowner.pong_score++;
		paddle.realowner.SendFlags |= PONG_SF_PLAYERSCORE;
	}
}

bool pong_goal(entity ball, int pteam)
{
	entity paddle = ball.owner.pong_paddles[pteam-1];
	if (!paddle)
		return false;
	if ( ball.origin_y < paddle.origin_y-paddle.pong_length/2 ||
		ball.origin_y > paddle.origin_y+paddle.pong_length/2 )
	{
		pong_add_score(ball.owner,minigame_next_team(pteam, 2));
		pong_reset_ball(ball);
		return true;
	}
	return false;
}

void pong_ball_think()
{
	float think_speed = autocvar_sys_ticrate;
	self.nextthink = time + think_speed;
	
	self.origin_x += self.velocity_x * think_speed;
	self.origin_y += self.velocity_y * think_speed;
	if ( self.origin_y <= 0 )
	{
		self.origin_y = 0;
		self.velocity_y *= -1;
	}
	else if ( self.origin_y >= 1 )
	{
		self.origin_y = 1;
		self.velocity_y *= -1;
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

void pong_paddle_think()
{
	float think_speed = autocvar_sys_ticrate;
	self.nextthink = time + think_speed;
	
	if ( self.realowner.movement.x > 0 && self.origin_y > self.pong_length/2 )
	{
		self.origin_y -= autocvar_sv_minigames_pong_paddlespeed * think_speed;
		if ( self.origin_y < 0 )
			self.origin_y = 0;
		self.SendFlags |= MINIG_SF_UPDATE;
	}
	else if ( self.realowner.movement.x < 0 && self.origin_y < 1-self.pong_length/2 )
	{
		self.origin_y += autocvar_sv_minigames_pong_paddlespeed * think_speed;
		if ( self.origin_y > 1 )
			self.origin_y = 1;
		self.SendFlags |= MINIG_SF_UPDATE;
	}
		
}

// required function, handle server side events
int minigame_event_pong(entity minigame, string event, ...)
{
	switch (event)
	{
		case "start":
		{
			entity ball = msle_spawn(minigame,"pong_ball");
			pong_reset_ball(ball);
			return true;
		}
		case "end":
			// nothing to do
			return false;
		case "join":
		{
			int pl_num = minigame_count_players(minigame);
			
			// Don't allow joining a single player match
			if ( (minigame.pong_ai) && pl_num > 0 )
				return false;

			// Don't allow more than 2 players
			if(pl_num >= 2) { return false; }

			int pl_team = 1;
			// Get the right team
			if(minigame.minigame_players)
				pl_team = minigame_next_team(minigame.minigame_players.team, 2);
			
			
			entity player = ...(0,entity);
			entity paddle = msle_spawn(minigame,"pong_paddle");// Note puddle isn't a typo
			paddle.pong_length = autocvar_sv_minigames_pong_paddlesize;
			paddle.origin_y = 0.5;
			paddle.origin_x = pl_team == 1 ? 0.99 : 0.01;
			paddle.think = pong_paddle_think;
			paddle.nextthink = time;
			paddle.team = pl_team;
			paddle.realowner = player;
			minigame.pong_paddles[pl_team-1] = paddle;

			// Team 1 by default
			return pl_team;
		}
		case "part":
			// todo
			return false;
		case "cmd":
			// nothing to do
			return false;
		case "network_send":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame_player" && (sf & PONG_SF_PLAYERSCORE ) )
			{
				WriteByte(MSG_ENTITY,sent.pong_score);
			}
			else if ( sent.classname == "minigame" && (sf & PONG_SF_SINGLEPLAYER) )
			{
				WriteByte(MSG_ENTITY,sent.pong_ai);
			}
			return false;
		}
	}
	return false;
}


#elif defined(CSQC)


// Required function, draw the game board
void minigame_hud_board_pong(vector pos, vector mySize)
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
		}
		else if ( e.classname == "pong_paddle" )
		{
			obj_pos = minigame_hud_denormalize(e.origin,pos,mySize);
			paddle_size = minigame_hud_denormalize_size(eX / 32 + eY*e.pong_length,pos,mySize);
			minigame_drawpic_centered( obj_pos, minigame_texture("pong/paddle"),
					paddle_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}
}


// Required function, draw the game status panel
void minigame_hud_status_pong(vector pos, vector mySize)
{
	HUD_Panel_DrawBg(1);
	vector ts;
	ts = minigame_drawstring_wrapped(mySize_x,pos,active_minigame.descriptor.message,
		hud_fontsize * 2, '0.25 0.47 0.72', panel_fg_alpha, DRAWFLAG_NORMAL,0.5);
	
	pos_y += ts_y;
	mySize_y -= ts_y;
	
	vector player_fontsize = hud_fontsize * 1.75;
	ts_y = ( mySize_y - 2*player_fontsize_y ) / 2;
	ts_x = mySize_x;
	vector mypos;
	vector tile_size = '48 48 0';

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" )
		{
			mypos = pos;
			if ( e.team == 2 )
				mypos_y  += player_fontsize_y + ts_y;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				(e.minigame_playerslot ? GetPlayerName(e.minigame_playerslot-1) : _("AI")),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			
			mypos_y += player_fontsize_y;
			
			drawstring(mypos,ftos(e.pong_score),tile_size,
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}


// Required function, handle client events
int minigame_event_pong(entity minigame, string event, ...)
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
					return true;
				case K_DOWNARROW:
				case K_KP_DOWNARROW:
					return true;
			}
			return false;
		case "network_receive":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame_player" && (sf & PONG_SF_PLAYERSCORE ) )
			{
				sent.pong_score = ReadByte();
			}
			else if ( sent.classname == "minigame" && (sf & PONG_SF_SINGLEPLAYER) )
			{
				int ai = ReadByte();
				bool spawnai = ai && !sent.pong_ai;
				sent.pong_ai = ai;
				
				if ( spawnai )
				{
					entity aiplayer = spawn();
					aiplayer.classname = "minigame_player";
					aiplayer.owner = minigame;
					aiplayer.team = ai;
					aiplayer.minigame_playerslot = 0;
					aiplayer.minigame_autoclean = 1;
					// todo aiplayer.think
				}
			}
			return false;
		}
		case "menu_show":
		{
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Single Player"),"singleplayer");
			return false;
		}
		case "menu_click":
		{
			if ( ...(0,string) == "singleplayer" && !minigame.pong_ai )
			{
				if ( minigame_count_players(minigame) == 1 )
					minigame_cmd("singleplayer");
			}
			return false;
		}
	}

	return false;
}
#endif