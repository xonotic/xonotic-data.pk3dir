#include "state.qh"

#include <common/mutators/mutator/status_effects/_mod.qh>
#include <server/command/getreplies.qh>

void Inventory_new(PlayerState this);
void Inventory_delete(entity this);
void Inventory_clear(PlayerState this);
void InventoryStorage_attach(PlayerState this);
void InventoryStorage_delete(PlayerState this);

void PlayerState_attach(entity this)
{
	if (PS(this) && PS(this).m_client == this)
		return;

	this._ps = NEW(PlayerState, this);

	Inventory_new(PS(this));
}

void PlayerState_detach(entity this)
{
    PlayerState ps = PS(this);
	if (!ps) return;  // initial connect
	PS(this) = NULL;
    Inventory_clear(this.inventory_store); // no need to network updates, as there is no inventory attached

	if (ps.m_client != this) return;  // don't own state, spectator
	ps.ps_push(ps, this);
    Inventory_delete(ps);

	FOREACH_CLIENT(PS(it) == ps, { PS(it) = NULL; });
	delete(ps);
}

void DecodeLevelParms(entity this);
void PlayerScore_Attach(entity this);
void ClientData_Attach(entity this);
void accuracy_init(entity this);
void entcs_attach(entity this);
void anticheat_init(entity this);
void W_HitPlotOpen(entity this);
void bot_clientconnect(entity this);

void ClientState_attach(entity this)
{
	this._cs = NEW(ClientState, this);

	// TODO: fold all of these into ClientState

	DecodeLevelParms(this);

	PlayerScore_Attach(this);
	PlayerStats_PlayerBasic_CheckUpdate(this);
	ClientData_Attach(this);
	accuracy_init(this);
	entcs_attach(this);
	anticheat_init(this);
	W_HitPlotOpen(this);
	InventoryStorage_attach(this);
	StatusEffectsStorage_attach(this);
}

void bot_clientdisconnect(entity this);
void W_HitPlotClose(entity this);
void anticheat_report_to_eventlog(entity this);
void entcs_detach(entity this);
void accuracy_free(entity this);
void ClientData_Detach(entity this);
void PlayerScore_Detach(entity this);

void ClientState_detach(entity this)
{
    GetCvars(this, CS_CVAR(this), -1);  // free cvars TODO: is this still needed now that it's stored on the clientstate entity?
    accuracy_free(this); // TODO: needs to be before CS() is deleted!
    PlayerScore_Detach(this); // what ^they^ said
    W_HitPlotClose(this);
    ClientData_Detach(this);
    entcs_detach(this);
    InventoryStorage_delete(this);
    StatusEffectsStorage_delete(this);
	delete(CS(this));
	this._cs = NULL;

    bot_clientdisconnect(this);

    anticheat_report_to_eventlog(this);
}
