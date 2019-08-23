#include "achievements.qh"

void Achievements_attach(entity this) {
	this.achievements = NEW(Achievements, this);
}

void Achievements_detach(entity this) {
	if (this.achievements) {
		this.achievements = NULL;
		delete(this.achievements);
	}
	return;
}

void Achievements_set_achievement_value(entity this, string achieve, int value) {

	if (achieve == "triple_kill") { this.triple_kill = value; }
	if (achieve == "rage") { this.rage = value; }
	if (achieve == "massacre") { this.massacre = value; }
	if (achieve == "mayhem") { this.mayhem = value; }
	if (achieve == "berserker") { this.berserker = value; }
	if (achieve == "carnage") { this.carnage = value; }
	if (achieve == "armageddon") { this.armageddon = value; }

	if (achieve == "firstblood") { this.firstblood = value; }

	if (achieve == "airshot") { this.airshot = value; }
	if (achieve == "amazing") { this.amazing = value; }
	if (achieve == "awesome") { this.awesome = value; }
	if (achieve == "botlike") { this.botlike = value; }
	if (achieve == "electrobitch") { this.electrobitch = value; }
	if (achieve == "impressive") { this.impressive = value; }
	if (achieve == "flyingyoda") { this.flyingyoda = value; }
	if (achieve == "multirailed") { this.multirailed = value; }

	return;
}

int Achievements_get_achievement_value(entity this, string achieve) {

	if (achieve == "triple_kill") { return this.triple_kill; }
	if (achieve == "rage") { return this.rage; }
	if (achieve == "massacre") { return this.massacre; }
	if (achieve == "mayhem") { return this.mayhem; }
	if (achieve == "berserker") { return this.berserker; }
	if (achieve == "carnage") { return this.carnage; }
	if (achieve == "armageddon") { return this.armageddon; }

	if (achieve == "firstblood") { return this.firstblood; }

	if (achieve == "airshot") { return this.airshot; }
	if (achieve == "amazing") { return this.amazing; }
	if (achieve == "awesome") { return this.awesome; }
	if (achieve == "botlike") { return this.botlike; }
	if (achieve == "electrobitch") { return this.electrobitch; }
	if (achieve == "impressive") { return this.impressive; }
	if (achieve == "flyingyoda") { return this.flyingyoda; }
	if (achieve == "multirailed") { return this.multirailed; }

	return 0;
}

void Achievements_add_achievement_value(entity this, string achieve, int value) {
	Achievements_set_achievement_value(this, achieve, Achievements_get_achievement_value(this, achieve)+value);
}

void Achievements_inc_achievement(entity this, string achieve) {
	return Achievements_add_achievement_value(this, achieve, 1);
}

void Achievements_announce(Achievements this, entity whom, string title, string achieve) {
	#ifdef SVQC
		centerprint(whom, strcat(title, " [", ftos(this.get_achievement_value(this, achieve)), "]"));
	#endif
}