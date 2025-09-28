#include "pages.qh"

#include <common/gametypes/gametype/duel/duel.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/weapon/blaster.qh>
#include <common/weapons/weapon/crylink.qh>
#include <common/weapons/weapon/devastator.qh>
#include <common/mutators/base.qh>
#include <common/mutators/mutator/dodging/dodging.qh>
#include <common/mutators/mutator/nades/nades.qh>
#include <common/mutators/mutator/overkill/overkill.qh>
#include <common/mutators/mutator/overkill/okhmg.qh>
#include <common/mutators/mutator/overkill/oknex.qh>
#include <common/mutators/mutator/overkill/okmachinegun.qh>
#include <common/mutators/mutator/overkill/okrpc.qh>
#include <common/mutators/mutator/overkill/okshotgun.qh>
#include <common/mutators/mutator/rocketflying/rocketflying.qh>

REGISTER_INTRODUCTION_PAGE(0, _("About this guide"))
{
	PAGE_TEXT_INIT();
	PAR(_("Welcome to Xonotic, the free and fast arena shooter!"));
	PAR(_("This guide covers the basics one should know about the weapons, items, and other aspects of the game, "
	      "but most of what you will learn will come from trying it out in practice."));
	PAR(_("Please note that this guide describes the default game behavior with vanilla settings. "
	      "Xonotic is highly customizable and there are tons of servers out there that run with lightly or highly modified settings."));
	PAR(_("You can usually find out which settings are modified by issuing %s in console after connecting to a server."), "^3cvar_changes^7");
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_INTRODUCTION_PAGE(1, _("Community"))
{
	string comm_channels = sprintf(_("%s on Matrix, %s on QuakeNet IRC, or the Discord"), "^5#main:xonotic.org^7", "^5#xonotic^7"); // string isolated as it's subject to change
	PAGE_TEXT_INIT();
	PAR(_("Xonotic stands out for its friendly, mature, and welcoming player community, and many long-term players argue that this is probably one of the best things about Xonotic. "
	      "If you approach other players friendly and respectfully, this will be recognized, while acting toxic on the other hand will not make your life easier on the servers."));
	PAR(_("The best way to get in touch with the community is to just start playing online and use the in-game chat. "
	      "You can also connect to the official communication channels (%s), and of course the official forum."), comm_channels);
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_INTRODUCTION_PAGE(2, _("Getting good"))
{
	PAGE_TEXT_INIT();
	PAR(_("The skill gap between new and experienced players is often immense. "
	      "However, this is mostly because experienced players have learned how to make use of the game mechanics. "
	      "If you see experienced players doing tricks you don't understand, don't hesitate to ask anyone on the server!"));
	PAR(_("Another way to learn is to spectate experienced players. "
	      "Observe which weapons they combo and the movement techniques they make use of. "
	      "Also look at which weapons they choose depending on the gameplay situation, for example in close combat, mid-range battles, or against groups of opponents."));
	PAR(_("The learning curve is very steep. That said, understanding how the game works will enable you to speed around the map and apply effective weapon combos in no time."));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_INTRODUCTION_PAGE(3, _("XonStat"))
{
	PAGE_TEXT_INIT();
	PAR(_("XonStat is the integrated player statistics application for Xonotic. "
	      "It stores vital stats like your kill-death ratio, weapon damage and accuracy, and scoreboards from past games."));
	PAR(_("Tracking is completely opt-in, and no login is required."));
	PAR(_("Some of the statistics are available in-game on your player profile, while the rest are accessible at %s."), "^5stats.xonotic.org^7");
	this.m_description = strzone(PAGE_TEXT);
}

REGISTER_MOVEMENT_PAGE(0, _("Introduction"))
{
	PAGE_TEXT_INIT();
	PAR(_("Xonotic is a very fast-paced arena shooter. Fast-paced does not only relate to reaction times but also to movement speed. "
	      "That means mastering movement skills is an essential part of Xonotic gameplay and must not be underestimated."));
	PAR(_("For a new player, the most important tricks to learn are:"));
	PAR("* %s\n* %s\n* %s\n* %s\n* %s\n* %s",
		_("Bunny Hopping"),
		_("Strafe Turning"),
		_("Blaster Jumping"),
		_("Rocket Flying"),
		_("Crylink Running"),
		_("Ramp Jumping"));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(1, _("Bunny Hopping"))
{
	PAGE_TEXT_INIT();
	PAR(_("Bunny hopping (\"bhopping\") is a technique known also from other arena shooters."));
	PAR(_("Due to air control, you can accelerate while in the air far beyond the maximum ground movement speed. "
	      "To avoid ground friction, players constantly hop by simply keeping %s pressed, so that ground contact doesn't slow them down. "
	      "This allows you to get around the map much faster than if you would just walk."), strcat("^3", _("jump"), "^7"));
	PAR(_("Therefore, keeping %s held while moving quickly is one of the most essential movement strategies, used by all experienced players."), strcat("^3", _("jump"), "^7"));
	PAR(_("With default settings, the speed you can reach by bunny hopping is capped at 900 qu/s (\"units per second\"). "
	      "CTS/DeFRaG servers usually run with different CPMA-like physics that remove this cap."));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(2, _("Strafe Turning"))
{
	PAGE_TEXT_INIT();
	PAR(_("Bunny hopping around corners requires \"strafe turning\" or you will lose a lot of speed (or simply not be able to make the turn). "
	      "Strafe turning is a method used to quickly change the direction you're traveling while mid-air, without losing speed."));
	PAR(_("While bunny hopping, first release %s, then press the strafe key into the turn direction (%s or %s), then start turning smoothly into the turn direction. "
	      "As always, during the entire strafe turn keep %s held."), strcat("^3", _("move forward"), "^7"), strcat("^3", _("strafe left"), "^7"), strcat("^3", _("strafe right"), "^7"), strcat("^3", _("jump"), "^7"));
	PAR(_("Note that if you press the strafe key before releasing the forward key, you will suffer a speed penalty."));
	PAR(_("If you do it right, you will even continue to accelerate in strafe turns."));
	PAR(_("For an illustration of this technique, see %s."), "^5xonotic.org/guide^7"); // shared message
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(3, _("Blaster Jumping"))
{
	PAGE_TEXT_INIT();
	PAR(_("In most situations, the %s is more a movement tool than a weapon. "
	      "That's why many players will often have single digit accuracy for the %s. "
	      "It is instead especially useful to make high jumps."), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER));
	PAR(_("To do a \"laser jump,\" simply fire the %s at your own feet and jump immediately afterwards. "
	      "Experiment a bit with the timing of firing the %s and jumping to get a feeling of which timings will get you how high."), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(4, _("Wall Blastering"))
{
	PAGE_TEXT_INIT();
	PAR(_("If you don't fire the %s at the floor but instead against a wall next to you, you can get significant horizontal speed. "
	      "You can do this to pick up speed off the stand or even when passing a wall while already bunny hopping."), COLORED_NAME(WEP_BLASTER));
	PAR(_("To use this technique, start a bunny hop. Right after jumping, flick back with your mouse at about 8 o'clock if the wall is to your left (or 4 o'clock if the wall is to your right), aim at the level of your head, and fire the %s. "
	      "Immediately flick back to your movement direction and continue to bunny hop."), COLORED_NAME(WEP_BLASTER));
	PAR(_("In order to waste as little speed as possible while flicking back, switch to a strafe key for the duration of the flick. "
	      "This means using %s if the wall is to your left, and %s if the wall is to your right."), strcat("^3", _("strafe left"), "^7"), strcat("^3", _("strafe right"), "^7"));
	PAR(_("For an illustration of this technique, see %s."), "^5xonotic.org/guide^7"); // shared message
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(5, _("Rocket Flying"))
{
	PAGE_TEXT_INIT();
	PAR(_("The %s can be used just like the %s for movement, but it inflicts much more damage to the player. "
	      "In gametypes without self damage however it is a very versatile movement tool."), COLORED_NAME(WEP_DEVASTATOR), COLORED_NAME(WEP_BLASTER));
	PAR(_("While mid-air, you can also fire a rocket underneath yourself and immediately detonate it. "
	      "The explosion will push you upwards a little bit, and can prolong a jump."));
	PAR(_("Note that this strategy only really works if the %s mutator is enabled."), COLORED_NAME(MUTATOR_rocketflying));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(6, _("Crylink Running"))
{
	PAGE_TEXT_INIT();
	PAR(_("The drag force of the %s secondary fire can not only break other players' movement, but can also give yourself a significant speed boost."), COLORED_NAME(WEP_CRYLINK));
	PAR(_("To \"crylink run,\" shoot the %s secondary at the floor (or a parallel wall) just in front of you and begin bunny hopping to catapult yourself off the stand into high speed. "
	      "Finding the best angle to aim at takes some practice, and changes depending on your speed."), COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_CRYLINK));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(7, _("Crylink Wall Climbing"))
{
	PAGE_TEXT_INIT();
	PAR(_("By shooting the %s secondary against a wall next to you (just above your head), you can climb up walls quickly. "
	      "This is called \"wall climbing\" with the %s."), COLORED_NAME(WEP_CRYLINK), COLORED_NAME(WEP_CRYLINK));
	PAR(_("This is also a good way to save yourself from falling off the map, as it reliably stops your downfall."));
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(8, _("Ramp Jumping"))
{
	PAGE_TEXT_INIT();
	PAR(_("Ramps are an important part of Xonotic map design. "
	      "Any sloped surface that you hit with the right speed and the right angle will give you a significant upwards boost and enable you to reach places that are otherwise accessible only with laser jumps, which cost health and make noise."));
	PAR(_("When doing ramp jumps, it is vital to hit the ramp at a flat angle to receive the upwards boost and not lose too much speed."));
	PAR(_("In order to make a ramp jump, approach a sloped surface (\"ramp\"), jump just before the ramp and keep %s pressed so you jump again once you hit the ramp."), strcat("^3", _("jump"), "^7"));
	PAR(_("The higher the speed you have when you hit the ramp (at the right angle), the stronger the upwards boost. "
	      "As always, you can gain speed before the ramp by bunny hopping."));
	PAR(_("Note that when trying to make a ramp jump while bunny hopping, it is vital to time your hops carefully so you get the angle right."));
	PAR(_("For an illustration of this technique, see %s."), "^5xonotic.org/guide^7"); // shared message
	this.m_description = strzone(PAGE_TEXT);
}
REGISTER_MOVEMENT_PAGE(9, _("Advanced Movement"))
{
	PAGE_TEXT_INIT();
	PAR(_("Advanced techniques like \"strafe jumping\" (\"strafing\") or \"circle jumping\" (\"CJ\") offer only limited benefits in vanilla gameplay, "
	      "but are crucial on CTS/DeFRaG servers that use slightly different physics."));
	PAR(_("If you want to master these techniques, be sure to check out %s."), "^5xdf.gg/guide^7");
	this.m_description = strzone(PAGE_TEXT);
}

REGISTER_MODS_PAGE(0, _("Overkill"))
{
	PAGE_TEXT_INIT();
	PAR(_("%s is a mod that heavily changes the game, giving players fewer but more powerful weapons, nades, and more movement options."), COLORED_NAME(MUTATOR_ok));
	PAR(_("In terms of weaponry, players have infinite ammo and spawn in with the %s, %s, and %s, and can pick up the %s and %s superweapons on the map sometimes. "
	      "These weapons are a lot more powerful than the regular weapons, so their time-to-kill is quite low."), COLORED_NAME(WEP_OVERKILL_SHOTGUN), COLORED_NAME(WEP_OVERKILL_MACHINEGUN), COLORED_NAME(WEP_OVERKILL_NEX), COLORED_NAME(WEP_OVERKILL_HMG), COLORED_NAME(WEP_OVERKILL_RPC));
	PAR(_("The secondary fire of all weapons shoots a laser which does not damage or push enemies, but can be used to push yourself around. "
	      "Also since the %s mutator is active, all players have offhand nades."), COLORED_NAME(MUTATOR_nades));
	PAR(_("As for movement tricks, %s is enabled by default in %s, allowing for rapidly changing your movement direction."), COLORED_NAME(MUTATOR_dodging), COLORED_NAME(MUTATOR_ok));
	this.m_description = strzone(PAGE_TEXT);
}

REGISTER_MODS_PAGE(1, _("XPM"))
{
	PAGE_TEXT_INIT();
	PAR(_("%s (\"Xonotic Pro-Mode\") is a set of gameplay settings often used for competitive play, particularly in %s."), _("XPM"), COLORED_NAME(MAPINFO_TYPE_DUEL));
	PAR(_("It adds extra rules for picking up items, preventing players with 100 or more health or armor from taking %s, %s, %s, and %s pickups, in order to give other players a fairer chance of rebuilding their stack. "
	      "It also disables spawn protection and enables friendly fire in team-based gametypes."), COLORED_NAME(ITEM_HealthBig), COLORED_NAME(ITEM_HealthMedium), COLORED_NAME(ITEM_ArmorBig), COLORED_NAME(ITEM_ArmorMedium));
	this.m_description = strzone(PAGE_TEXT);
}
