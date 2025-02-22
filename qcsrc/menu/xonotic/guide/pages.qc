#include "pages.qh"

#include <common/weapons/_all.qh>
#include <common/weapons/weapon/blaster.qh>
#include <common/weapons/weapon/crylink.qh>
#include <common/weapons/weapon/devastator.qh>
#include <common/mutators/base.qh>
#include <common/mutators/mutator/rocketflying/rocketflying.qh>

REGISTER_INTRODUCTION_PAGE(0, _("About this guide"), "gametype_dm")
{
	this.m_description = _("Welcome to Xonotic, the free and fast arena shooter!\n\n"
		"Please note that this guide describes the default game behavior with vanilla settings. "
		"Xonotic is highly customizable and there are tons of servers out there that run with lightly or highly modified settings\n\n"
		"You can usually find out which settings are modified by issuing ^3cvar_changes^7 in console after connecting to a server");
}
REGISTER_INTRODUCTION_PAGE(1, _("Community"), "gametype_dm")
{
	this.m_description = _("Xonotic stands out for its friendly, mature, and welcoming player community, and many long-term players argue that this is probably one of the best things about Xonotic. "
		"If you approach other players friendly and respectfully, this will be recognized, while acting toxic on the other hand will not make your life easier on the servers\n\n"
		"The best way to get in touch with the community is to just start playing online and use the in-game chat. "
		"However, you can also connect to the official communication channels (^5#main:xonotic.org^7 on Matrix, ^5#xonotic^7 on QuakeNet IRC), and of course the official forum");
}
REGISTER_INTRODUCTION_PAGE(2, _("Acquiring Skills"), "gametype_dm")
{
	this.m_description = _("The skill gap between new and experienced players is often immense. However, this is mostly because experienced players have learned how to make use of the game mechanics. "
		"If you see experienced players doing tricks you don't understand, don't hesitate to ask. "
		"In most cases, polite questions receive an answer, from anyone on the server if not from the experienced player themselves\n\n"
		"Another way to learn is to spectate experienced players. "
		"Observe which weapons they combo and the movement techniques they make use of. "
		"Also look at which weapons they choose depending on the gameplay situation, for example in close combat, mid-range battles, or against groups of opponents\n\n"
		"The learning curve is very steep. That said, understanding how the game works will enable you to speed around the map and apply effective weapon combos in no time");
}

REGISTER_INTRODUCTION_PAGE(3, _("XonStat"), "gametype_dm")
{
	this.m_description = _("XonStat is the integrated player statistics application for Xonotic. See vital stats like your K:D ratio, weapon damage and accuracy, and scoreboards from past games. "
		"Tracking is completely opt-in, and no login is required.");
}

REGISTER_MOVEMENT_PAGE(0, _("Movement Importance"), "gametype_inv")
{
	this.m_description = _("Xonotic is a very fast-paced arena shooter. Fast-paced does not only relate to reaction times but also to movement speed. "
		"That means mastering movement skills is an essential part of Xonotic gameplay and must not be underestimated\n\n"
		"For a new player using default physics, the most important tricks to learn are:"
		"\n  Bunny Hopping"
		"\n  Strafe Turning"
		"\n  Blaster Jumping"
		"\n  Rocket Flying"
		"\n  Crylink Running"
		"\n  Ramp Jumping"); // TODO: improve?
}
REGISTER_MOVEMENT_PAGE(1, _("Bunny Hopping"), "gametype_inv")
{
	this.m_description = _("\"Bunny hopping\" (\"bhopping\") is a technique known also from other arena shooters\n\n"
		"Due to air control, you can accelerate while in the air far beyond the maximum ground movement speed. "
		"In order to avoid ground friction you can constantly hop, so that ground contact won't slow you down, by simply keeping the ^3+jump^7 button pressed. "
		"This allows you to get around the map much faster than if you would just walk\n\n"
		"Therefore, keeping ^3+jump^7 held while moving quickly is one of the most essential movement strategies, used by all experienced players\n\n"
		"In vanilla settings, the speed you can reach by bunny hopping is capped at 900. "
		"CTS/DeFRaG servers usually run with different CPMA-like physics that remove this capping");
}
REGISTER_MOVEMENT_PAGE(2, _("Strafe Turning"), "gametype_inv")
{
	this.m_description = _("Bunny hopping around corners requires \"strafe turning\" or you will loose a lot of speed (or simply not be able to make the turn). "
		"Strafe turning is a method used to quickly change the direction you're traveling while mid-air, without losing speed\n\n"
		"While bunny hopping, first release the ^3+forward^7 movement key, then press the strafe key into the turn direction (^3+moveleft^7 or ^3+moveright^7), then start moving the mouse smoothly into the turn direction. "
		"As always, during the entire strafe turn keep the jump button held\n\n"
		"Note that if you press the strafe key before releasing the forward key, you will suffer a speed penalty\n\n"
		"If you do it right, you will even continue to accelerate in strafe turns\n\n"
		"For an illustration of this technique, see ^5www.xonotic.org/guide^7");
}
REGISTER_MOVEMENT_PAGE(3, _("Blaster Jumping"), "gametype_inv")
{
	this.m_description = strzone(sprintf(_("In most situations, the %s is more a movement tool than a weapon. "
		"That's why many players will often have single digit accuracy for the %s. "
		"It is instead especially useful to make high jumps\n\n"
		"To do a \"laser jump,\" simply fire the %s at your own feet and jump. "
		"Experiment a bit with the timing of firing the %s and jumping to get a feeling about which timing will get you how high"),
	COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER)));
}
REGISTER_MOVEMENT_PAGE(4, _("Wall Blastering"), "gametype_inv")
{
	this.m_description = strzone(sprintf(_("If you don't fire the %s at the floor but instead against a wall next to you, you can get significant horizontal speed. "
		"You can do that to pick up speed off the stand or even when passing a wall while already bunny hopping\n\n"
		"To use this technique, start a bunny hop. Right after jumping, flick back with your mouse at about 8 o'clock if the wall is to your left (or 4 o'clock if the wall is to your right), aim at the level of your head, and fire the %s. "
		"Immediately flick back to your movement direction and continue to bunny hop\n\n"
		"In order to waste as little speed as possible while flicking back, switch to strafe key for the duration of the flick. "
		"Use the strafe right key if the wall is to your left, and the strafe left key if the wall is to your right\n\n"
		"You'll find an illustration of this technique on ^5www.xonotic.org/guide^7"),
	COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER)));
}
REGISTER_MOVEMENT_PAGE(5, _("Rocket Flying"), "gametype_inv")
{
	this.m_description = strzone(sprintf(_("The %s can be used just like the %s for movement, however it inflicts way more damage to the player. "
		"In game modes without self damage however it is a very versatile movement tool\n\n"
		"You can also fire a rocket underneath yourself and immediately detonate it. The explosion will push you upwards a little bit, and can prolong a jump\n\n"
		"Note that this strategy only really works if the %s mutator is enabled"),
	COLORED_NAME(WEP_DEVASTATOR), COLORED_NAME(WEP_BLASTER), COLORED_NAME(MUTATOR_rocketflying)));
}
REGISTER_MOVEMENT_PAGE(6, _("Crylink Running"), "gametype_inv")
{
	this.m_description = strzone(sprintf(_("The drag force of %s secondary fire can not only break other people's movement, but can also give yourself a significant speed boost\n\n"
		"To \"crylink run,\" shoot the %s secondary at the floor (or a parallel wall) just in front of you and begin bunny hopping to catapult yourself off the stand into high speed"),
	COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_CRYLINK)));
}
REGISTER_MOVEMENT_PAGE(7, _("Crylink Wall Climbing"), "gametype_inv")
{
	this.m_description = strzone(sprintf(_("By shooting the %s secondary against a wall next to you (just above your head), you can climb up walls quickly. "
		"This is called \"wall climbing\" with the %s\n\n"
		"This is also a good way to save yourself from falling off the map, as it reliably stops your downfall"),
	COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_CRYLINK)));
}
REGISTER_MOVEMENT_PAGE(8, _("Ramp Jumping"), "gametype_inv")
{
	this.m_description = _("Ramps are an important part of Xonotic map design. Any sloped surface that you hit with the right speed and the right angle will give you a significant upwards boost and enable you to reach places that are otherwise accessible only with laser jumps, which cost health and make noise\n\n"
		"When doing ramp jumps, it is vital to hit the ramp at a flat angle to receive the upwards boost and not loose too much speed\n\n"
		"In order to make a ramp jump, approach a sloped surface (\"ramp\"), jump just before the ramp and keep the ^3+jump^7 button pressed so you jump again once you hit the ramp\n\n"
		"The higher the speed you have when you hit the ramp (at the right angle), the stronger the upwards boost. As always, you can gain speed before the ramp by bunny hopping\n\n"
		"Note that when trying to make a ramp jump while bunny hopping, it is vital to time your hops carefully so you get the angle right");
}
REGISTER_MOVEMENT_PAGE(9, _("Advanced Movement"), "gametype_inv")
{
	this.m_description = _("Advanced techniques like \"strafe jumping\" (\"strafing\") or \"circle jumping\" (\"CJ\") offer only limited benefits in vanilla gameplay, but are crucial on CTS/DeFRaG servers that use slightly different physics\n\n"
		"If you want to master these techniques, be sure to check out ^5http://xdf.gg/guide^7");
}
