#include "sv_attackertext.qh"

AUTOCVAR(sv_attackertext, int, 1, "0: disabled, 1: visible");

REGISTER_MUTATOR(attackertext, true);

#define SV_ATTACKERTEXT_DISABLED()        (autocvar_sv_attackertext <= 0)
#define SV_ATTACKERTEXT_ENABLED()         (autocvar_sv_attackertext >= 1)

void attackertext_Send(entity to, entity attacker, int sf)
{
	if(IS_REAL_CLIENT(to)) {
		msg_entity = to;
		WriteHeader(MSG_ONE, attackertext);
		WriteByte(MSG_ONE, etof(attacker));
		WriteByte(MSG_ONE, sf);
	}
}

MUTATOR_HOOKFUNCTION(attackertext, PlayerDamaged) {
    if (SV_ATTACKERTEXT_DISABLED()) return;
	
    entity attacker = M_ARGV(0, entity);
    entity hit = M_ARGV(1, entity);
	
	if (hit == attacker) return;
	if (!IS_PLAYER(attacker)) return;
	
	int sf = 0;
	if (SAME_TEAM(hit, attacker)) sf |= ATFLAG_SAMETEAM;
	
	attackertext_Send(hit, attacker, sf);
	FOREACH_CLIENT(IS_SPEC(it) && it.(enemy) == hit, { attackertext_Send(it, attacker, sf); });
}
