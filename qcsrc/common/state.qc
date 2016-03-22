#include "state.qh"

void Inventory_new(entity this);
void Inventory_delete(entity this);

void PlayerState_attach(entity this)
{
	this._ps = NEW(PlayerState, this);

	Inventory_new(this);
}

void PlayerState_detach(entity this)
{
	if (!PS(this)) return;  // initial connect
	FOREACH_CLIENT(PS(it) == PS(this), { PS(it) = NULL; });
	remove(PS(this));
	this._ps = NULL;

    Inventory_delete(self);
}

void GetCvars(int);
void DecodeLevelParms(entity this);
void PlayerScore_Attach(entity this);
void ClientData_Attach(entity this);
void accuracy_init(entity this);
void entcs_attach(entity this);
void playerdemo_init(entity this);
void anticheat_init(entity this);
void W_HitPlotOpen(entity this);
void bot_clientconnect(entity this);

void ClientState_attach(entity this)
{
	this._cs = NEW(ClientState, this);

    GetCvars(0);  // get other cvars from player

	// TODO: xonstat elo.txt support, until then just 404s
	if (false && IS_REAL_CLIENT(this)) { PlayerStats_PlayerBasic_CheckUpdate(this); }

	// TODO: fold all of these into ClientState

	DecodeLevelParms(this);

	PlayerScore_Attach(this);
	ClientData_Attach(this);
	accuracy_init(this);
	entcs_attach(this);
	playerdemo_init(this);
	anticheat_init(this);
	W_HitPlotOpen(this);

	bot_clientconnect(this);
}

void bot_clientdisconnect();
void W_HitPlotClose(entity this);
void anticheat_report(entity this);
void playerdemo_shutdown();
void entcs_detach(entity this);
void accuracy_free(entity this);
void ClientData_Detach(entity this);
void PlayerScore_Detach(entity this);

void ClientState_detach(entity this)
{
	remove(CS(this));
	this._cs = NULL;

    GetCvars(-1);  // free cvars

    bot_clientdisconnect();

    W_HitPlotClose(this);
    anticheat_report(this);
    playerdemo_shutdown();
    entcs_detach(this);
    accuracy_free(self);
    ClientData_Detach(this);
    PlayerScore_Detach(self);
}
