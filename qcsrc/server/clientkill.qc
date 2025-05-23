#include "clientkill.qh"

#include <common/csqcmodel_settings.qh>
#include <common/deathtypes/all.qh>
#include <common/mapobjects/triggers.qh>
#include <common/notifications/all.qh>
#include <common/stats.qh>
#include <common/stats.qh>
#include <common/vehicles/sv_vehicles.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/damage.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/round_handler.qh>
#include <server/teamplay.qh>

void ClientKill_Now_TeamChange(entity this)
{
	if (this.killindicator_teamchange == -1)
	{
		if (this.team > 0)
			// ensure team is valid immediately so ClientKill_Now() -> Damage() can update score without error
			TeamBalance_JoinBestTeam(this);
		else
		{
			// defer autoselect to Join(), after any queued players were joined to avoid 2 players on same team
			// when the first player(s) chose specific teams and the last player chose autoselect (they skip the queue)
			this.team = -1;
			this.team_selected = -1; // don't stop at ShowTeamSelection()
		}
	}
	else if (this.killindicator_teamchange == -2)
	{
		if (!autocvar_sv_spectate)
			// shouldn't get here because of condition in ClientCommand_spectate()
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);

		if (this.wants_join)
		{
			Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_PREVENT_JOIN);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_QUEUE, this.netname);
			SetPlayerTeam(this, -1, TEAM_CHANGE_SPECTATOR);
			// Can't do this in PutObserverInServer() or SetPlayerTeam() cos it causes
			// mouse2 (change spectate mode) to kick the player off the join queue.
			this.wants_join = 0;
			this.team_selected = 0;
		}
		else
		{
			PutObserverInServer(this, false, true);
			if (!TeamBalance_QueuedPlayersTagIn(this))
			if (autocvar_g_balance_teams_remove)
				TeamBalance_RemoveExcessPlayers(this);
		}
	}
	else
	{
		Player_SetTeamIndexChecked(this, Team_TeamToIndex(
			this.killindicator_teamchange));
	}
	this.killindicator_teamchange = 0;
}

void ClientKill_Now(entity this)
{
	if (this.vehicle)
	{
		vehicles_exit(this.vehicle, VHEF_RELEASE);
		if (!this.killindicator_teamchange)
		{
			this.vehicle_health = -1;
			Damage(this, this, this, 1 , DEATH_KILL.m_id, DMG_NOWEP, this.origin, '0 0 0');
		}
	}

	if (this.killindicator && !wasfreed(this.killindicator))
		delete(this.killindicator);

	this.killindicator = NULL;

	if (this.killindicator_teamchange)
		ClientKill_Now_TeamChange(this);

	if (!IS_SPEC(this) && !IS_OBSERVER(this) && MUTATOR_CALLHOOK(ClientKill_Now, this) == false)
	{
		Damage(this, this, this, 100000, DEATH_KILL.m_id, DMG_NOWEP, this.origin, '0 0 0');
	}

	// now I am sure the player IS dead
}
void KillIndicator_Think(entity this)
{
	if (game_stopped || (this.owner.alpha < 0 && !this.owner.vehicle))
	{
		this.owner.killindicator = NULL;
		delete(this);
		return;
	}

	if (this.cnt <= 0)
	{
		ClientKill_Now(this.owner);
		return;
	}

	// count == 1 means that it's silent
	if (this.count != 1)
	{
		if (this.cnt <= 10)
			setmodel(this, MDL_NUM(this.cnt));
		if (IS_REAL_CLIENT(this.owner))
		{
			if (this.cnt <= 10)
				Send_Notification(NOTIF_ONE, this.owner, MSG_ANNCE, Announcer_PickNumber(CNT_KILL, this.cnt));
		}
	}
	this.nextthink = time + 1;
	this.cnt -= 1;
}

.float lip;
float clientkilltime;
.float clientkill_nexttime;
void ClientKill_TeamChange(entity this, float targetteam) // 0 = don't change, -1 = auto, -2 = spec
{
	if (game_stopped)
		return;

	float killtime = autocvar_g_balance_kill_delay;

	if (MUTATOR_CALLHOOK(ClientKill, this, killtime))
		return;
	killtime = M_ARGV(1, float);

	if(round_handler_IsActive() && !round_handler_IsRoundStarted())
		killtime = min(killtime, 1);

	this.killindicator_teamchange = targetteam;

	// this.killindicator.count == 1 means that the kill indicator was spawned by ClientKill_Silent
	if(killtime <= 0 && this.killindicator && this.killindicator.count == 1)
	{
		ClientKill_Now(this); // allow instant kill in this case
		return;
	}

	if (!this.killindicator)
	{
		if (!IS_DEAD(this))
		{
			killtime = max(killtime, this.clientkill_nexttime - time);
			float antispam_delay = autocvar_g_balance_kill_antispam;
			if(round_handler_IsActive() && !round_handler_IsRoundStarted())
				antispam_delay = min(antispam_delay, 2);
			this.clientkill_nexttime = time + killtime + antispam_delay;
		}

		if (killtime <= 0 || !IS_PLAYER(this) || IS_DEAD(this))
		{
			ClientKill_Now(this);
		}
		else
		{
			float starttime = max(time, clientkilltime);

			this.killindicator = new(killindicator);
			this.killindicator.owner = this;
			this.killindicator.scale = 0.5;
			setattachment(this.killindicator, this, "");
			setorigin(this.killindicator, '0 0 52');
			setthink(this.killindicator, KillIndicator_Think);
			this.killindicator.nextthink = starttime + (this.lip) * 0.05;
			clientkilltime = max(clientkilltime, this.killindicator.nextthink + 0.05);
			this.killindicator.cnt = ceil(killtime);
			this.killindicator.count = bound(0, ceil(killtime), 10);
			//sprint(this, strcat("^1You'll be dead in ", ftos(this.killindicator.cnt), " seconds\n"));

			IL_EACH(g_clones, it.enemy == this && !(it.effects & CSQCMODEL_EF_RESPAWNGHOST) && !it.killindicator,
			{
				it.killindicator = new(killindicator);
				it.killindicator.owner = it;
				it.killindicator.scale = 0.5;
				setattachment(it.killindicator, it, "");
				setorigin(it.killindicator, '0 0 52');
				setthink(it.killindicator, KillIndicator_Think);
				it.killindicator.nextthink = starttime + (it.lip) * 0.05;
				//clientkilltime = max(clientkilltime, it.killindicator.nextthink + 0.05);
				it.killindicator.cnt = ceil(killtime);
			});
			this.lip = 0;
		}
	}
	if (this.killindicator)
	{
		Notification notif;
		if (targetteam == 0) // just die
		{
			this.killindicator.colormod = '0 0 0';
			notif = CENTER_TEAMCHANGE_SUICIDE;
		}
		else if (targetteam == -1) // auto
		{
			this.killindicator.colormod = '0 1 0';
			notif = CENTER_TEAMCHANGE_AUTO;
		}
		else if (targetteam == -2) // spectate
		{
			this.killindicator.colormod = '0.5 0.5 0.5';
			notif = CENTER_TEAMCHANGE_SPECTATE;
		}
		else
		{
			this.killindicator.colormod = Team_ColorRGB(targetteam);
			notif = APP_TEAM_NUM(targetteam, CENTER_TEAMCHANGE);
		}
		if (IS_REAL_CLIENT(this) && this.killindicator.cnt > 0)
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, notif, this.killindicator.cnt);
	}

}

void ClientKill_Silent(entity this, float _delay)
{
	// overrides queued silent killindicators
	if (!this.killindicator || this.killindicator.count != 1)
		this.killindicator = new(killindicator);
	this.killindicator.owner = this;
	setthink(this.killindicator, KillIndicator_Think);
	this.killindicator.nextthink = time + (this.lip) * 0.05;
	this.killindicator.cnt = ceil(_delay);
	this.killindicator.count = 1; // this is used to indicate that it should be silent
	this.lip = 0;
}

// Called when a client types 'kill' in the console
void ClientKill(entity this)
{
	if (game_stopped || this.player_blocked)
		return;

	ClientKill_TeamChange(this, 0);
}
