#include "strafe.qh"

#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <common/stats.qh>

.float race_started;

float calculate_strafe_efficiency(entity strafeplayer, vector movement)
{
    if(strafeplayer)
    {
        // physics
        bool   onground                      = IS_ONGROUND(strafeplayer);
        bool   strafekeys;
        bool   swimming                      = strafeplayer.waterlevel >= WATERLEVEL_SWIMMING;
        float  speed                         = vlen(vec2(strafeplayer.velocity));
        float  maxspeed_crouch_mod           = IS_DUCKED(strafeplayer) ? .5 : 1;
        float  maxspeed_phys                 = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  maxspeed                      = maxspeed_phys * maxspeed_crouch_mod;
        float  vel_angle                     = vectoangles(strafeplayer.velocity).y;
        float  view_angle                    = PHYS_INPUT_ANGLES(strafeplayer).y + 180;
        float  angle;
        int    direction;
        int    keys_fwd;
        float  wishangle                     = 0;
        bool   fwd                           = true;

        // determine whether the player is pressing forwards or backwards keys
        if(movement.x > 0)
        {
            keys_fwd = 1;
        }
        else if(movement.x < 0)
        {
            keys_fwd = -1;
        }
        else
        {
            keys_fwd = 0;
        }

        // determine player wishdir
        if(movement.x == 0)
        {
            if(movement.y < 0)
            {
                wishangle = -90;
            }
            else if(movement.y > 0)
            {
                wishangle = 90;
            }
            else
            {
                wishangle = 0;
            }
        }
        else
        {
            if(movement.y == 0)
            {
                wishangle = 0;
            }
            else
            {
                wishangle = RAD2DEG * atan2(movement.y, movement.x);
                // wrap the wish angle if it exceeds ±90°
                if(fabs(wishangle) > 90)
                {
                    if(wishangle < 0) wishangle += 180;
                    else wishangle -= 180;
                    wishangle = -wishangle;
                }
            }
        }

        strafekeys = fabs(wishangle) == 90;

        if(strafekeys && !onground && !swimming)
        {
            maxspeed = PHYS_MAXAIRSTRAFESPEED(strafeplayer); // no modifiers here because they don't affect air strafing
        }

        // get current strafing angle ranging from -180° to +180°
        if(speed > 0)
        {
            // calculate view angle relative to the players current velocity direction
            angle = vel_angle - view_angle;

            // if the angle goes above 180° or below -180° wrap it to the opposite side
            if (angle > 180) angle -= 360;
            else if(angle < -180) angle += 360;

            // shift the strafe angle by 180° for further calculations
            if(angle < 0) angle += 180;
            else angle -= 180;

            // determine whether the player is strafing forwards or backwards
            // if the player isn't strafe turning use forwards/backwards keys to determine direction
            if(!strafekeys)
            {
                if(keys_fwd > 0)
                {
                    fwd = true;
                }
                else if(keys_fwd < 0)
                {
                    fwd = false;
                }
                else
                {
                    fwd = fabs(angle) <= 90;
                }
            }
            // otherwise determine by examining the strafe angle
            else
            {
                if(wishangle < 0) // detect direction since the direction is not yet set
                {
                    fwd = angle <= -wishangle;
                }
                else
                {
                    fwd = angle >= -wishangle;
                }
            }

            // shift the strafe angle by 180° when strafing backwards
            if(!fwd)
            {
                if(angle < 0) angle += 180;
                else angle -= 180;
            }
        }
        else
        {
            angle = 0;
        }

        // invert the wish angle when strafing backwards
        if(!fwd)
        {
            wishangle = -wishangle;
        }

        // note about accuracy: a few ticks after dying do still have race_started set to true causing minimal interference (most likely <0.1%) in the efficiency total
        if(speed > 0 && !swimming && strafeplayer.race_started) // only calculate the efficiency if all conditions are met
        {
            float efficiency = 0;
            float moveangle = angle + wishangle;
            float bestangle = (speed > maxspeed ? acos(maxspeed / speed) : 0) * RAD2DEG; // best angle to strafe at

            ++strafeplayer.strafe_efficiency_tics;
            if(fabs(vlen(vec2(movement))) > 0)
            {
                if(fabs(moveangle) > 90)
                {
                    efficiency = -((fabs(moveangle) - 90) / 90);
                    if(efficiency < -1) efficiency = -2 - efficiency;
                }
                else
                {
                    if(moveangle >= bestangle)
                    {
                        efficiency = 1 - (moveangle - bestangle) / (90 - bestangle);
                    }
                    else if(moveangle <= -bestangle)
                    {
                        efficiency = 1 - (moveangle + bestangle) / (-90 + bestangle);
                    }
                }
            }
            return efficiency;
        }
    }
    return 0;
}
