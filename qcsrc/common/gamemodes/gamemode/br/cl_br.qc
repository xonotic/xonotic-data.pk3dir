#include "cl_br.qh"

#include <common/mutators/base.qh>

REGISTER_MUTATOR(cl_br, true);

// FIXME: some of these hooks don't work when spectating

MUTATOR_HOOKFUNCTION(cl_br, WantEventchase)
{
    return (STAT(DROP) == DROP_FALLING);
}

MUTATOR_HOOKFUNCTION(cl_br, DrawCrosshair)
{
    return (STAT(BLEEDING) || (STAT(DROP) != DROP_LANDED));
}

MUTATOR_HOOKFUNCTION(cl_br, DrawReticle)
{
    return (STAT(DROP) == DROP_FALLING);
}

MUTATOR_HOOKFUNCTION(cl_br, PlayerCanCrouch)
{
    if(STAT(BLEEDING))
        M_ARGV(1, bool) = true;
    else if(STAT(DROP) != DROP_LANDED)
        M_ARGV(1, bool) = false;
}

MUTATOR_HOOKFUNCTION(cl_br, PlayerJump)
{
    return STAT(BLEEDING) || (STAT(DROP) != DROP_LANDED);
}

MUTATOR_HOOKFUNCTION(cl_br, PM_Physics)
{
    if(STAT(DROP) == DROP_FALLING)
        ITEMS_STAT(csqcplayer) |= IT_USING_JETPACK;

    // injured players can't swim
    if(STAT(BLEEDING)){
        if(csqcplayer.waterlevel >= WATERLEVEL_SWIMMING)
        {
            csqcplayer.com_in_jump = false;
        }
    }

    return (STAT(DROP) != DROP_LANDED);
}

// adjusted clanarena hud
#include <client/draw.qh>

void HUD_Mod_BR_Export(int fh)
{
    HUD_Write_Cvar("hud_panel_modicons_br_layout");
}

void DrawBRItem(vector myPos, vector mySize, float aspect_ratio, int layout, int i)
{
    TC(int, layout); TC(int, i);
    int stat = -1;
    vector color = '0 0 0';
    switch(i)
    {
        case 0: stat = STAT(SQUADSALIVE); color = '1 1 0'; break;
        default:
        case 1: stat = STAT(PLAYERSALIVE); color = '1 0 0'; break;
    }

    float aspect_size;
    if(mySize.x/mySize.y > aspect_ratio)
    {
        aspect_size = aspect_ratio * mySize.y;
        myPos.x = myPos.x + (mySize.x - aspect_size) / 2;
        mySize.x = aspect_size;
    }
    else
    {
        aspect_size = 1/aspect_ratio * mySize.x;
        myPos.y = myPos.y + (mySize.y - aspect_size) / 2;
        mySize.y = aspect_size;
    }

    if(layout)
    {
        if(i == 0)
        {
            drawpic_aspect_skin(myPos + eX / 12 * mySize.x - eY / 12 * mySize.y, "player_blue", vec2(mySize.x / 3, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
            drawpic_aspect_skin(myPos + eY / 12 * mySize.y, "player_yellow", vec2(mySize.x / 3, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
            drawpic_aspect_skin(myPos + eX /  6 * mySize.x + eY / 12 * mySize.y, "player_pink", vec2(mySize.x / 3, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
        }
        else
        {
            drawpic_aspect_skin(myPos, "player_red", vec2(mySize.x / 2, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
        }
        drawstring_aspect(myPos + eX * mySize.x / 2, ftos(stat), vec2(mySize.x / 2, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
    }
    else
        drawstring_aspect(myPos, ftos(stat), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Mod_BR_Draw(vector myPos, vector mySize, int layout)
{
    int rows, columns;
    float aspect_ratio;
    aspect_ratio = (layout) ? 2 : 1;
    rows = HUD_GetRowCount(2, mySize, aspect_ratio);
    columns = ceil(2/rows);

    int i;
    float row = 0, column = 0;
    vector pos = '0 0 0', itemSize;
    itemSize = vec2(mySize.x / columns, mySize.y / rows);
    for(i=0; i<2; ++i)
    {
        pos.x = myPos.x + column * itemSize.x;
        pos.y = myPos.y + row * itemSize.y;

        DrawBRItem(pos, itemSize, aspect_ratio, layout, i);

        ++row;
        if(row >= rows)
        {
            row = 0;
            ++column;
        }
    }
}

// Battle Royale HUD modicons
void HUD_Mod_BR(vector myPos, vector mySize)
{
    mod_active = 1; // required in each mod function that always shows something

    HUD_Mod_BR_Draw(myPos, mySize, autocvar_hud_panel_modicons_br_layout);
}
