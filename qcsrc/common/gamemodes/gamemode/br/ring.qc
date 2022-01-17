#include "ring.qh"

#ifdef GAMEQC
float ring_calculate_current_radius(entity this)
{
    float time_elapsed = time - this.br_ring_start;
    float time_elapsed_minus_wait = time_elapsed;

    for(int stage = 0; stage < this.br_ring_stage_count; ++stage)
    {
        float stage_duration = this.br_ring_duration * this.br_ring_stage_timing[stage];
        stage_duration += this.br_ring_stage_waittime * stage;

        if(time_elapsed > stage_duration)
        {
            if(time_elapsed >= (stage_duration + this.br_ring_stage_waittime))
            {
                time_elapsed_minus_wait -= this.br_ring_stage_waittime;
            }
            else
            {
                time_elapsed_minus_wait -= time_elapsed - stage_duration;
                break;
            }
        }
        else
            break;
    }

    float radius_ratio = 1 - time_elapsed_minus_wait / this.br_ring_duration;
    return this.radius * radius_ratio;
}
#endif
