#include "sv_damagetext.qh"

AUTOCVAR(sv_damagetext, int, 2, "\\\"0\\\" = disable damage text, \\\"1\\\" = show damage text to spectators, \\\"2\\\" = also to the attacker, \\\"3\\\" = show damage text to all players");

REGISTER_MUTATOR(damagetext, true);

#define SV_DAMAGETEXT_DISABLED()        (autocvar_sv_damagetext <= 0)
#define SV_DAMAGETEXT_SPECTATORS_ONLY() (autocvar_sv_damagetext >= 1)
#define SV_DAMAGETEXT_PLAYERS()         (autocvar_sv_damagetext >= 2)
#define SV_DAMAGETEXT_ALL()             (autocvar_sv_damagetext >= 3)

.int dent_net_flags;
.float dent_net_deathtype;
.float dent_net_health;
.float dent_net_armor;
.float dent_net_potential;

const int BITS_PER_INT = 24;
const int DENT_ATTACKERS_SIZE = 11; // ceil(255 / BITS_PER_INT)
// where 255 is the max number of clients that the engine can support
.int dent_attackers[DENT_ATTACKERS_SIZE];

bool write_damagetext(entity this, entity client, int sf)
{
	entity attacker = this.realowner;
	entity hit = this.enemy;
	int flags = this.dent_net_flags;
	int deathtype = this.dent_net_deathtype;
	float health = this.dent_net_health;
	float armor = this.dent_net_armor;
	float potential_damage = this.dent_net_potential;
	if (!(
		(SV_DAMAGETEXT_ALL()) ||
		(SV_DAMAGETEXT_PLAYERS() && client == attacker) ||
		(SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_SPEC(client) && client.enemy == attacker) ||
		(SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_OBSERVER(client))
	)) return false;

	WriteHeader(MSG_ENTITY, damagetext);
	WriteByte(MSG_ENTITY, etof(hit));
	WriteInt24_t(MSG_ENTITY, deathtype);
	WriteByte(MSG_ENTITY, flags);

	// we need to send a few decimal places to minimize errors when accumulating damage
	// sending them multiplied saves bandwidth compared to using WriteCoord,
	// however if the multiplied damage would be too much for (signed) short, we send an int24
	if (flags & DTFLAG_BIG_HEALTH) WriteInt24_t(MSG_ENTITY, health * DAMAGETEXT_PRECISION_MULTIPLIER);
	else WriteShort(MSG_ENTITY, health * DAMAGETEXT_PRECISION_MULTIPLIER);
	if (!(flags & DTFLAG_NO_ARMOR))
	{
		if (flags & DTFLAG_BIG_ARMOR) WriteInt24_t(MSG_ENTITY, armor * DAMAGETEXT_PRECISION_MULTIPLIER);
		else WriteShort(MSG_ENTITY, armor * DAMAGETEXT_PRECISION_MULTIPLIER);
	}
	if (!(flags & DTFLAG_NO_POTENTIAL))
	{
		if (flags & DTFLAG_BIG_POTENTIAL) WriteInt24_t(MSG_ENTITY, potential_damage * DAMAGETEXT_PRECISION_MULTIPLIER);
		else WriteShort(MSG_ENTITY, potential_damage * DAMAGETEXT_PRECISION_MULTIPLIER);
	}
	return true;
}

MUTATOR_HOOKFUNCTION(damagetext, PlayerDamaged) {
	if (SV_DAMAGETEXT_DISABLED()) return;
	entity attacker = M_ARGV(0, entity);
	entity hit = M_ARGV(1, entity); if (hit == attacker) return;
	float health = M_ARGV(2, float);
	float armor = M_ARGV(3, float);
	int deathtype = M_ARGV(5, int);
	float potential_damage = M_ARGV(6, float);
	if (potential_damage == 0)
		return;
	if (MUTATOR_IS_ENABLED(mutator_instagib) && DEATH_WEAPONOF(deathtype) == WEP_VAPORIZER)
		return;

	static entity net_text_prev;
	static float net_damagetext_prev_time;

	bool multiple = (net_damagetext_prev_time == time && net_text_prev && !wasfreed(net_text_prev)
		&& net_text_prev.realowner == attacker && net_text_prev.enemy == hit
		&& net_text_prev.dent_net_deathtype == deathtype);

	if (multiple)
	{
		// damage of multiple projectiles hitting player at the same time, e.g. shotgun
		// is accumulated on the same damagetext entity
		health += net_text_prev.dent_net_health;
		armor += net_text_prev.dent_net_armor;
		potential_damage += net_text_prev.dent_net_potential;
	}

	int flags = 0;
	if (SAME_TEAM(hit, attacker)) flags |= DTFLAG_SAMETEAM;
	if (health >= DAMAGETEXT_SHORT_LIMIT) flags |= DTFLAG_BIG_HEALTH;
	if (armor >= DAMAGETEXT_SHORT_LIMIT) flags |= DTFLAG_BIG_ARMOR;
	if (potential_damage >= DAMAGETEXT_SHORT_LIMIT) flags |= DTFLAG_BIG_POTENTIAL;
	if (!armor) flags |= DTFLAG_NO_ARMOR;
	if (almost_equals_eps(armor + health, potential_damage, 5)) flags |= DTFLAG_NO_POTENTIAL;

	if (multiple)
	{
		net_text_prev.dent_net_flags = flags;
		net_text_prev.dent_net_health = health;
		net_text_prev.dent_net_armor = armor;
		net_text_prev.dent_net_potential = potential_damage;
		return;
	}
	else if (attacker)
	{
		int attacker_id = etof(attacker) - 1;
		int idx = floor(attacker_id / BITS_PER_INT);
		int bit = attacker_id % BITS_PER_INT;
		if (!(hit.dent_attackers[idx] & BIT(bit)))
		{
			// player is hit for the first time after respawn by this attacker
			hit.dent_attackers[idx] |= BIT(bit);
			flags |= DTFLAG_STOP_ACCUMULATION; // forcedly stop client-side damage accumulation
		}
	}

	entity net_text = new_pure(net_damagetext);
	net_text.realowner = attacker;
	net_text.enemy = hit;
	net_text.dent_net_flags = flags;
	net_text.dent_net_deathtype = deathtype;
	net_text.dent_net_health = health;
	net_text.dent_net_armor = armor;
	net_text.dent_net_potential = potential_damage;

	net_text_prev = net_text;
	net_damagetext_prev_time = time;

	setthink(net_text, SUB_Remove);
	net_text.nextthink = (time > 10) ? (time + 0.5) : 10; // allow a buffer from start time for clients to load in

	Net_LinkEntity(net_text, false, 0, write_damagetext);
}

MUTATOR_HOOKFUNCTION(damagetext, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);
	int player_id = etof(player) - 1;
	int idx = floor(player_id / BITS_PER_INT);
	int bit = player_id % BITS_PER_INT;
	// remove from attacker list of all players
	FOREACH_CLIENT(IS_PLAYER(it), {
		it.dent_attackers[idx] &= ~BIT(bit);
	});
}

MUTATOR_HOOKFUNCTION(damagetext, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);
	for (int i = 0; i < DENT_ATTACKERS_SIZE; ++i)
		player.dent_attackers[i] = 0;
}
