vector collision_force;
vector collision_angle;

vector bb1[9];
vector bb2[9];

float collision_run()
{
    vector vtmp, vmin, vmax, vrot, vforce;
    float i, fvel, bcol;


    // Extract the 8 bbox corners from mins/maxs for self
    vmax = self.maxs;
    vmin = self.mins;
    bb1[0] = vmax;
    vtmp   = vmax; vtmp_x = vmin_x; bb1[1] = vtmp;
    vtmp   = vmax; vtmp_y = vmin_y; bb1[2] = vtmp;
    vtmp   = vmin; vtmp_z = vmax_z; bb1[3] = vtmp;
    bb1[4] = vmin;
    vtmp   = vmin; vtmp_x = vmax_x; bb1[5] = vtmp;
    vtmp   = vmin; vtmp_y = vmax_y; bb1[6] = vtmp;
    vtmp   = vmax; vtmp_z = vmin_z; bb1[7] = vtmp;

    makevectors(self.angles + '-2 0 0' * self.angles_x);
    bcol = FALSE;
    // Pass1: Transform by rotation, ajust points by impact/s
    for(i = 8; i >= 0; --i)
    {
        vtmp = bb1[i];
        vtmp = self.origin + vtmp_x * v_forward - vtmp_y * v_right + vtmp_z * v_up;
        traceline(self.origin, vtmp, MOVE_WORLDONLY, self);
        te_lightning1(world,self.origin,vtmp);
        if(trace_fraction != 1.0)
        {
            //bb2[i] = trace_endpos;
            vforce += (trace_endpos - vtmp);
            bcol = TRUE;
        }
        else
            bb2[i] = bb1[i];
    }

    if(bcol)
    {
        //self.angles   += vectoangles(vrot) * frametime;
        //self.angles   -= (self.velocity - vectoangles(normalize(vforce))) * frametime;

        vtmp = self.origin + self.velocity * frametime;
        vrot = self.origin + vforce * frametime;
        //self.angles += vectoangles(normalize(vtmp - vrot)) * frametime;
        self.velocity += vforce * frametime;

    }


// Extract the 8 bbox corners from mins/maxs for self
/*
    bb1[0] = self.absmax;
    vtmp   = self.absmax; vtmp_x = self.absmin_x; bb1[1] = vtmp;
    vtmp   = self.absmax; vtmp_y = self.absmin_y; bb1[2] = vtmp;
    vtmp   = self.absmin; vtmp_z = self.absmax_z; bb1[3] = vtmp;
    bb1[4] = self.absmin;
    vtmp   = self.absmin; vtmp_x = self.absmax_x; bb1[5] = vtmp;
    vtmp   = self.absmin; vtmp_y = self.absmax_y; bb1[6] = vtmp;
    vtmp   = self.absmax; vtmp_z = self.absmin_z; bb1[7] = vtmp;


// Extract the 8 bbox corners from mins/maxs for other
    bb1[0] = other.absmax;
    vtmp   = other.absmax; vtmp_x = other.absmin_x; bb2[1] = vtmp;
    vtmp   = other.absmax; vtmp_y = other.absmin_y; bb2[2] = vtmp;
    vtmp   = other.absmin; vtmp_z = other.absmax_z; bb2[3] = vtmp;
    bb2[4] = other.absmin;
    vtmp   = other.absmin; vtmp_x = other.absmax_x; bb2[5] = vtmp;
    vtmp   = other.absmin; vtmp_y = other.absmax_y; bb2[6] = vtmp;
    vtmp   = other.absmax; vtmp_z = other.absmin_z; bb2[7] = vtmp;
*/
}

