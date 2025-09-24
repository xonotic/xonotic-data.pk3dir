#include "cl_ctf.qh"

#include <common/mutators/base.qh>
#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/hud/panel/modicons.qh>

// CTF HUD modicon section
int redflag_prevframe, blueflag_prevframe, yellowflag_prevframe, pinkflag_prevframe, neutralflag_prevframe; // status during previous frame
int redflag_prevstatus, blueflag_prevstatus, yellowflag_prevstatus, pinkflag_prevstatus, neutralflag_prevstatus; // last remembered status
float redflag_statuschange_time, blueflag_statuschange_time, yellowflag_statuschange_time, pinkflag_statuschange_time, neutralflag_statuschange_time; // time when the status changed

void HUD_Mod_CTF_Reset()
{
    redflag_prevstatus = blueflag_prevstatus = yellowflag_prevstatus = pinkflag_prevstatus = neutralflag_prevstatus = 0;
    redflag_prevframe = blueflag_prevframe = yellowflag_prevframe = pinkflag_prevframe = neutralflag_prevframe = 0;
    redflag_statuschange_time = blueflag_statuschange_time = yellowflag_statuschange_time = pinkflag_statuschange_time = neutralflag_statuschange_time = 0;
}

int autocvar__teams_available;
void HUD_Mod_CTF(vector pos, vector mySize)
{
    vector redflag_pos, blueflag_pos, yellowflag_pos, pinkflag_pos, neutralflag_pos;
    vector flag_size;
    float f; // every function should have that

    int redflag, blueflag, yellowflag, pinkflag, neutralflag; // current status
    float redflag_statuschange_elapsedtime = 0, blueflag_statuschange_elapsedtime = 0, yellowflag_statuschange_elapsedtime = 0, pinkflag_statuschange_elapsedtime = 0, neutralflag_statuschange_elapsedtime = 0; // time since the status changed
    bool ctf_oneflag; // one-flag CTF mode enabled/disabled
    bool ctf_stalemate; // currently in stalemate
    int stat_items = STAT(OBJECTIVE_STATUS);
    float fs, fs2, fs3, size1, size2;
    vector e1, e2;

    int nteams = autocvar__teams_available;

    redflag = (stat_items/CTF_RED_FLAG_TAKEN) & 3;
    blueflag = (stat_items/CTF_BLUE_FLAG_TAKEN) & 3;
    yellowflag = (stat_items/CTF_YELLOW_FLAG_TAKEN) & 3;
    pinkflag = (stat_items/CTF_PINK_FLAG_TAKEN) & 3;
    neutralflag = (stat_items/CTF_NEUTRAL_FLAG_TAKEN) & 3;

    ctf_oneflag = (stat_items & CTF_FLAG_NEUTRAL);

    ctf_stalemate = (stat_items & CTF_STALEMATE);

    mod_active = (redflag || blueflag || yellowflag || pinkflag || neutralflag || (stat_items & CTF_SHIELDED));

    if (autocvar__hud_configure) {
        redflag = 1;
        blueflag = 2;
        if (nteams & BIT(2))
            yellowflag = 2;
        if (nteams & BIT(3))
            pinkflag = 3;
        ctf_oneflag = neutralflag = 0; // disable neutral flag in hud editor?
    }

    // when status CHANGES, set old status into prevstatus and current status into status
    #define X(team) MACRO_BEGIN \
        if (team##flag != team##flag_prevframe) { \
            team##flag_statuschange_time = time; \
            team##flag_prevstatus = team##flag_prevframe; \
            team##flag_prevframe = team##flag; \
        } \
        team##flag_statuschange_elapsedtime = time - team##flag_statuschange_time; \
    MACRO_END
    X(red);
    X(blue);
    X(yellow);
    X(pink);
    X(neutral);
    #undef X

    #define X(team, cond) \
    string team##_icon = string_null, team##_icon_prevstatus = string_null; \
    int team##_alpha, team##_alpha_prevstatus; \
    team##_alpha = team##_alpha_prevstatus = 1; \
    MACRO_BEGIN \
        switch (team##flag) { \
            case 1: team##_icon = "flag_" #team "_taken"; break; \
            case 2: team##_icon = "flag_" #team "_lost"; break; \
            case 3: team##_icon = "flag_" #team "_carrying"; team##_alpha = blink(0.85, 0.15, 5); break; \
            default: \
                if ((stat_items & CTF_SHIELDED) && (cond)) { \
                    team##_icon = "flag_" #team "_shielded"; \
                } else { \
                    team##_icon = string_null; \
                } \
                break; \
        } \
        switch (team##flag_prevstatus) { \
            case 1: team##_icon_prevstatus = "flag_" #team "_taken"; break; \
            case 2: team##_icon_prevstatus = "flag_" #team "_lost"; break; \
            case 3: team##_icon_prevstatus = "flag_" #team "_carrying"; team##_alpha_prevstatus = blink(0.85, 0.15, 5); break; \
            default: \
                if (team##flag == 3) { \
                    team##_icon_prevstatus = "flag_" #team "_carrying"; /* make it more visible */\
                } else if((stat_items & CTF_SHIELDED) && (cond)) { \
                    team##_icon_prevstatus = "flag_" #team "_shielded"; \
                } else { \
                    team##_icon_prevstatus = string_null; \
                } \
                break; \
        } \
    MACRO_END
    X(red, myteam != NUM_TEAM_1 && (nteams & BIT(0)));
    X(blue, myteam != NUM_TEAM_2 && (nteams & BIT(1)));
    X(yellow, myteam != NUM_TEAM_3 && (nteams & BIT(2)));
    X(pink, myteam != NUM_TEAM_4 && (nteams & BIT(3)));
    X(neutral, ctf_oneflag);
    #undef X

    int tcount = 2;
    if(nteams & BIT(2))
        tcount = 3;
    if(nteams & BIT(3))
        tcount = 4;

    if (ctf_oneflag) {
        // hacky, but these aren't needed
        red_icon = red_icon_prevstatus = blue_icon = blue_icon_prevstatus = yellow_icon = yellow_icon_prevstatus = pink_icon = pink_icon_prevstatus = string_null;
        fs = fs2 = fs3 = 1;
    } else switch (tcount) {
        default:
        case 2: fs = 0.5; fs2 = 0.5; fs3 = 0.5; break;
        case 3: fs = 1; fs2 = 0.35; fs3 = 0.35; break;
        case 4: fs = 0.75; fs2 = 0.25; fs3 = 0.5; break;
    }

    if (mySize_x > mySize_y) {
        size1 = mySize_x;
        size2 = mySize_y;
        e1 = eX;
        e2 = eY;
    } else {
        size1 = mySize_y;
        size2 = mySize_x;
        e1 = eY;
        e2 = eX;
    }

    switch (myteam) {
        default:
        case NUM_TEAM_1: {
            redflag_pos = pos;
            blueflag_pos = pos + eX * fs2 * size1;
            yellowflag_pos = pos - eX * fs2 * size1;
            pinkflag_pos = pos + eX * fs3 * size1;
            break;
        }
        case NUM_TEAM_2: {
            redflag_pos = pos + eX * fs2 * size1;
            blueflag_pos = pos;
            yellowflag_pos = pos - eX * fs2 * size1;
            pinkflag_pos = pos + eX * fs3 * size1;
            break;
        }
        case NUM_TEAM_3: {
            redflag_pos = pos + eX * fs3 * size1;
            blueflag_pos = pos - eX * fs2 * size1;
            yellowflag_pos = pos;
            pinkflag_pos = pos + eX * fs2 * size1;
            break;
        }
        case NUM_TEAM_4: {
            redflag_pos = pos - eX * fs2 * size1;
            blueflag_pos = pos + eX * fs3 * size1;
            yellowflag_pos = pos + eX * fs2 * size1;
            pinkflag_pos = pos;
            break;
        }
    }
    neutralflag_pos = pos;
    flag_size = e1 * fs * size1 + e2 * size2;

    #define X(team) MACRO_BEGIN \
        f = bound(0, team##flag_statuschange_elapsedtime * 2, 1); \
        if (team##_icon && ctf_stalemate) \
            drawpic_aspect_skin(team##flag_pos, "flag_stalemate", flag_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL); \
        if (team##_icon_prevstatus && f < 1) \
            drawpic_aspect_skin_expanding(team##flag_pos, team##_icon_prevstatus, flag_size, '1 1 1', panel_fg_alpha * team##_alpha_prevstatus, DRAWFLAG_NORMAL, f); \
        if (team##_icon) \
            drawpic_aspect_skin(team##flag_pos, team##_icon, flag_size, '1 1 1', panel_fg_alpha * team##_alpha * f, DRAWFLAG_NORMAL); \
    MACRO_END
    X(red);
    X(blue);
    X(yellow);
    X(pink);
    X(neutral);
    #undef X
}

bool autocvar_hud_panel_scoreboard_ctf_leaderboard = true;

REGISTER_MUTATOR(cl_ctf, true);

MUTATOR_HOOKFUNCTION(cl_ctf, ShowRankings)
{
    if(autocvar_hud_panel_scoreboard_ctf_leaderboard && ISGAMETYPE(CTF) && STAT(CTF_SHOWLEADERBOARD))
    {
        M_ARGV(0, string) = _("Capture time rankings");
        return true;
    }
}
