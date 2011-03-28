vector explosion_calcpush_nomultiplier(vector explosion_v, vector target_v)
{
	// solution of the equations:
	//    v'                = v + alpha vp             // central hit
	//    m*v'   + mp*vp'   = m*v + mp*vp              // conservation of momentum
	//    m*v'^2 + mp*vp'^2 = m*v^2 + mp*vp^2          // conservation of energy (ELASTIC hit)
	// -> alpha = 0                                    // case 1: did not hit
	// -> alpha = 2*mp*(vp^2 - vp.v) / ((m+mp) * vp^2) // case 2: did hit
	//                                                 // non-elastic hits are somewhere between these two

	float alpha;
	alpha  = explosion_v * (explosion_v - target_v);

	if(alpha <= 0)
		// target is too fast to be hittable by this
		return '0 0 0';

	alpha /= (explosion_v * explosion_v);
		// now alpha is a multiplier
		// we know we can divide by this, or above alpha would be == 0
	
	return
		explosion_v * alpha;
}

#if 0
vector explosion_calcpush(vector explosion_v, float explosion_m, vector target_v, float target_m, float elasticity)
{
	// solution of the equations:
	//    v'                = v + alpha vp             // central hit
	//    m*v'   + mp*vp'   = m*v + mp*vp              // conservation of momentum
	//    m*v'^2 + mp*vp'^2 = m*v^2 + mp*vp^2          // conservation of energy (ELASTIC hit)
	// -> alpha = 0                                    // case 1: did not hit
	// -> alpha = 2*mp*(vp^2 - vp.v) / ((m+mp) * vp^2) // case 2: did hit
	//                                                 // non-elastic hits are somewhere between these two

	// this would be physically correct, but we don't do that
	return explosion_calcpush_nomultiplier(explosion_v, target_v, 
		(1 + elasticity) * (
			explosion_m
		) / (
			target_m + explosion_m
		)
	);
}
#endif

// simplified formula, tuned so that if the target has velocity 0, we get exactly the original force
vector damage_explosion_calcpush(vector explosion_f, vector target_v, float speedfactor)
{
	if(speedfactor == 0)
		return explosion_f;
	return explosion_calcpush_nomultiplier(explosion_f * speedfactor, target_v) * (1.0 / speedfactor);
}
