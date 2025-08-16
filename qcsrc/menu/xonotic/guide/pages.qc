#include "pages.qh"

#include <common/weapons/_all.qh>
#include <common/weapons/weapon/blaster.qh>
#include <common/weapons/weapon/crylink.qh>
#include <common/weapons/weapon/devastator.qh>
#include <common/mutators/base.qh>
#include <common/mutators/mutator/rocketflying/rocketflying.qh>

REGISTER_INTRODUCTION_PAGE(0, _("About this guide"))
{
	this.m_description = _("Welcome to Xonotic, the free and fast arena shooter!\n\n"
		"This guide covers the basics one should know about the weapons, items, and other aspects of the game, "
		"but most of what you will learn will come from trying it out in practice.\n\n"
		"Please note that this guide describes the default game behavior with vanilla settings. "
		"Xonotic is highly customizable and there are tons of servers out there that run with lightly or highly modified settings.\n\n"
		"You can usually find out which settings are modified by issuing ^3cvar_changes^7 in console after connecting to a server.");
}
REGISTER_INTRODUCTION_PAGE(1, _("Community"))
{
	this.m_description = strzone(sprintf(_("Xonotic stands out for its friendly, mature, and welcoming player community, and many long-term players argue that this is probably one of the best things about Xonotic. "
		"If you approach other players friendly and respectfully, this will be recognized, while acting toxic on the other hand will not make your life easier on the servers.\n\n"
		"The best way to get in touch with the community is to just start playing online and use the in-game chat. "
		"You can also connect to the official communication channels (^5%s^7 on Matrix, ^5%s^7 on QuakeNet IRC), and of course the official forum."),
	"#main:xonotic.org", "#xonotic"));
}
REGISTER_INTRODUCTION_PAGE(2, _("Getting good"))
{
	this.m_description = _("The skill gap between new and experienced players is often immense. However, this is mostly because experienced players have learned how to make use of the game mechanics. "
		"If you see experienced players doing tricks you don't understand, don't hesitate to ask. "
		"In most cases, polite questions receive an answer, from anyone on the server if not from the experienced player themselves.\n\n"
		"Another way to learn is to spectate experienced players. "
		"Observe which weapons they combo and the movement techniques they make use of. "
		"Also look at which weapons they choose depending on the gameplay situation, for example in close combat, mid-range battles, or against groups of opponents.\n\n"
		"The learning curve is very steep. That said, understanding how the game works will enable you to speed around the map and apply effective weapon combos in no time.");
}
REGISTER_INTRODUCTION_PAGE(3, _("XonStat"))
{
	this.m_description = strzone(sprintf(_("XonStat is the integrated player statistics application for Xonotic. "
		"It stores vital stats like your K:D ratio, weapon damage and accuracy, and scoreboards from past games.\n\n"
		"Tracking is completely opt-in, and no login is required.\n\n"
		"Some of the statistics are available in-game on your player profile, while the rest are accessible at ^5%s^7."),
	"stats.xonotic.org"));
}

REGISTER_MOVEMENT_PAGE(0, _("Introduction"))
{
	this.m_description = strzone(strcat(_("Xonotic is a very fast-paced arena shooter. Fast-paced does not only relate to reaction times but also to movement speed. "
		"That means mastering movement skills is an essential part of Xonotic gameplay and must not be underestimated.\n\n"
		"For a new player, the most important tricks to learn are:")
		,
		sprintf("\n  %s\n  %s\n  %s\n  %s\n  %s",
			_("Bunny Hopping"),
			_("Strafe Turning"),
			_("Blaster Jumping"),
			_("Rocket Flying"),
			_("Crylink Running"),
			_("Ramp Jumping")
		)));
}
REGISTER_MOVEMENT_PAGE(1, _("Bunny Hopping"))
{
	this.m_description = _("Bunny hopping (\"bhopping\") is a technique known also from other arena shooters.\n\n"
		"Due to air control, you can accelerate while in the air far beyond the maximum ground movement speed. "
		"To avoid ground friction, players constantly hop by simply keeping the ^3+jump^7 button pressed, so that ground contact doesn't slow them down. "
		"This allows you to get around the map much faster than if you would just walk.\n\n"
		"Therefore, keeping ^3+jump^7 held while moving quickly is one of the most essential movement strategies, used by all experienced players.\n\n"
		"With default settings, the speed you can reach by bunny hopping is capped at 900 qu/s (\"units per second\"). "
		"CTS/DeFRaG servers usually run with different CPMA-like physics that remove this capping.");
}
REGISTER_MOVEMENT_PAGE(2, _("Strafe Turning"))
{
	this.m_description = strzone(strcat(_("Bunny hopping around corners requires \"strafe turning\" or you will lose a lot of speed (or simply not be able to make the turn). "
		"Strafe turning is a method used to quickly change the direction you're traveling while mid-air, without losing speed.\n\n"
		"While bunny hopping, first release the ^3+forward^7 movement key, then press the strafe key into the turn direction (^3+moveleft^7 or ^3+moveright^7), then start turning smoothly into the turn direction. "
		"As always, during the entire strafe turn keep the ^3+jump^7 button held.\n\n"
		"Note that if you press the strafe key before releasing the forward key, you will suffer a speed penalty.\n\n"
		"If you do it right, you will even continue to accelerate in strafe turns.\n\n"),
		sprintf(_("For an illustration of this technique, see ^5%s^7."), "xonotic.org/guide") // shared message
		));
}
REGISTER_MOVEMENT_PAGE(3, _("Blaster Jumping"))
{
	this.m_description = strzone(sprintf(_("In most situations, the %s is more a movement tool than a weapon. "
		"That's why many players will often have single digit accuracy for the %s. "
		"It is instead especially useful to make high jumps.\n\n"
		"To do a \"laser jump,\" simply fire the %s at your own feet and jump immediately afterwards. "
		"Experiment a bit with the timing of firing the %s and jumping to get a feeling about which timing will get you how high."),
	COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER)));
}
REGISTER_MOVEMENT_PAGE(4, _("Wall Blastering"))
{
	this.m_description = strzone(strcat(sprintf(_("If you don't fire the %s at the floor but instead against a wall next to you, you can get significant horizontal speed. "
		"You can do this to pick up speed off the stand or even when passing a wall while already bunny hopping.\n\n"
		"To use this technique, start a bunny hop. Right after jumping, flick back with your mouse at about 8 o'clock if the wall is to your left (or 4 o'clock if the wall is to your right), aim at the level of your head, and fire the %s. "
		"Immediately flick back to your movement direction and continue to bunny hop.\n\n"
		"In order to waste as little speed as possible while flicking back, switch to strafe key for the duration of the flick. "
		"This means using ^3+moveleft^7 if the wall is to your left, and ^3+moveright^7 if the wall is to your right.\n\n"),
	COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER)),
		sprintf(_("For an illustration of this technique, see ^5%s^7."), "xonotic.org/guide") // shared message
		));
}
REGISTER_MOVEMENT_PAGE(5, _("Rocket Flying"))
{
	this.m_description = strzone(sprintf(_("The %s can be used just like the %s for movement, however it inflicts much more damage to the player. "
		"In game modes without self damage however it is a very versatile movement tool.\n\n"
		"While mid-air, you can also fire a rocket underneath yourself and immediately detonate it. "
		"The explosion will push you upwards a little bit, and can prolong a jump.\n\n"
		"Note that this strategy only really works if the %s mutator is enabled."),
	COLORED_NAME(WEP_DEVASTATOR), COLORED_NAME(WEP_BLASTER), COLORED_NAME(MUTATOR_rocketflying)));
}
REGISTER_MOVEMENT_PAGE(6, _("Crylink Running"))
{
	this.m_description = strzone(sprintf(_("The drag force of the %s secondary fire can not only break other players' movement, but can also give yourself a significant speed boost.\n\n"
		"To \"crylink run,\" shoot the %s secondary at the floor (or a parallel wall) just in front of you and begin bunny hopping to catapult yourself off the stand into high speed. "
		"Finding the best angle to aim at takes some practice, and changes depending on your speed."),
	COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_CRYLINK)));
}
REGISTER_MOVEMENT_PAGE(7, _("Crylink Wall Climbing"))
{
	this.m_description = strzone(sprintf(_("By shooting the %s secondary against a wall next to you (just above your head), you can climb up walls quickly. "
		"This is called \"wall climbing\" with the %s.\n\n"
		"This is also a good way to save yourself from falling off the map, as it reliably stops your downfall."),
	COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_CRYLINK)));
}
REGISTER_MOVEMENT_PAGE(8, _("Ramp Jumping"))
{
	this.m_description = strzone(strcat(_("Ramps are an important part of Xonotic map design. "
		"Any sloped surface that you hit with the right speed and the right angle will give you a significant upwards boost and enable you to reach places that are otherwise accessible only with laser jumps, which cost health and make noise.\n\n"
		"When doing ramp jumps, it is vital to hit the ramp at a flat angle to receive the upwards boost and not lose too much speed.\n\n"
		"In order to make a ramp jump, approach a sloped surface (\"ramp\"), jump just before the ramp and keep the ^3+jump^7 button pressed so you jump again once you hit the ramp.\n\n"
		"The higher the speed you have when you hit the ramp (at the right angle), the stronger the upwards boost. "
		"As always, you can gain speed before the ramp by bunny hopping.\n\n"
		"Note that when trying to make a ramp jump while bunny hopping, it is vital to time your hops carefully so you get the angle right.\n\n"),
		sprintf(_("For an illustration of this technique, see ^5%s^7."), "xonotic.org/guide") // shared message
		));
}
REGISTER_MOVEMENT_PAGE(9, _("Advanced Movement"))
{
	this.m_description = strzone(sprintf(_("Advanced techniques like \"strafe jumping\" (\"strafing\") or \"circle jumping\" (\"CJ\") offer only limited benefits in vanilla gameplay, "
		"but are crucial on CTS/DeFRaG servers that use slightly different physics.\n\n"
		"If you want to master these techniques, be sure to check out ^5%s^7."),
	"xdf.gg/guide"));
}
