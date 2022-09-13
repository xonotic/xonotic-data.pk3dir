#include "strafe.qh"

#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <common/stats.qh>

.float race_started;

float calculate_strafe_efficiency(entity strafeplayer, vector movement, float dt)
{
    if(strafeplayer)
    {
        // physics
        bool   onground                      = IS_ONGROUND(strafeplayer);
        bool   strafekeys;
        bool   swimming                      = strafeplayer.waterlevel >= WATERLEVEL_SWIMMING;
        float  speed                         = vlen(vec2(strafeplayer.velocity));
        float  maxspeed_mod                  = IS_DUCKED(strafeplayer) ? .5 : 1;
        float  maxspeed_phys                 = onground ? PHYS_MAXSPEED(strafeplayer) : PHYS_MAXAIRSPEED(strafeplayer);
        float  maxspeed                      = maxspeed_phys * maxspeed_mod;
        float  movespeed;
        float  bestspeed;
        float  maxaccel_phys                 = onground ? PHYS_ACCELERATE(strafeplayer) : PHYS_AIRACCELERATE(strafeplayer);
        float  maxaccel                      = maxaccel_phys;
        float  vel_angle                     = vectoangles(strafeplayer.velocity).y - (vectoangles(strafeplayer.velocity).y > 180 ? 360 : 0); // change the range from 0° - 360° to -180° - 180° to match how view_angle represents angles
        float  view_angle                    = PHYS_INPUT_ANGLES(strafeplayer).y;
        float  angle;
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
            if(PHYS_MAXAIRSTRAFESPEED(strafeplayer) != 0)
                maxspeed = min(PHYS_MAXAIRSTRAFESPEED(strafeplayer), PHYS_MAXAIRSPEED(strafeplayer) * maxspeed_mod);
            if(PHYS_AIRSTRAFEACCELERATE(strafeplayer) != 0)
                maxaccel = PHYS_AIRSTRAFEACCELERATE(strafeplayer);
        }

        movespeed = min(vlen(vec2(movement)), maxspeed);

        maxaccel *= dt * movespeed;
        bestspeed = max(movespeed - maxaccel, 0);

        float strafespeed = speed; // speed minus friction

        if((strafespeed > 0) && onground){
            float strafefriction = IS_ONSLICK(strafeplayer) ? PHYS_FRICTION_SLICK(strafeplayer) : PHYS_FRICTION(strafeplayer);
            float f = 1 - dt * strafefriction * max(PHYS_STOPSPEED(strafeplayer) / strafespeed, 1);

            if(f <= 0)
                strafespeed = 0;
            else
                strafespeed *= f;
        }

        // get current strafing angle ranging from -180° to +180°
        if(speed > 0)
        {
            // calculate view angle relative to the players current velocity direction
            angle = vel_angle - view_angle;

            // if the angle goes above 180° or below -180° wrap it to the opposite side since we want the interior angle
            if (angle > 180) angle -= 360;
            else if(angle < -180) angle += 360;

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
            float bestangle = (strafespeed > bestspeed ? acos(bestspeed / strafespeed) : 0) * RAD2DEG; // best angle to strafe at
            float prebestangle = (strafespeed > movespeed ? acos(movespeed / strafespeed) : 0) * RAD2DEG;

            strafeplayer.strafe_efficiency_time += dt;
            if(fabs(vlen(vec2(movement))) > 0)
            {
                if(fabs(moveangle) > 90)
                {
                    efficiency = -((fabs(moveangle) - 90) / 90);
                    if(efficiency < -1) efficiency = -2 - efficiency;
                }
                else
                {
                    if(bestangle == 90)
                    {
                        efficiency = fabs(moveangle) == bestangle ? 1 : 0;
                    }
                    else
                    {
                        if(moveangle >= bestangle)
                        {
                            efficiency = 1 - (moveangle - bestangle) / (90 - bestangle);
                        }
                        else if(moveangle <= -bestangle)
                        {
                            efficiency = 1 + (moveangle + bestangle) / (90 - bestangle);
                        }
                        else if(prebestangle != bestangle)
                        {
                            if(moveangle < bestangle && moveangle >= prebestangle)
                            {
                                efficiency = 1 + (moveangle - bestangle) / (bestangle - prebestangle);
                            }
                            else if(moveangle > -bestangle && moveangle <= -prebestangle)
                            {
                                efficiency = 1 - (moveangle + bestangle) / (bestangle - prebestangle);
                            }
                        }
                    }
                }
            }
            return efficiency;
        }
    }
    return 0;
}
