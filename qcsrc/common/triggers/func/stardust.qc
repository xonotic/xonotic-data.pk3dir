#ifdef SVQC
void spawnfunc_func_stardust()
{SELFPARAM();
	self.effects = EF_STARDUST;

	CSQCMODEL_AUTOINIT(self);
}
#endif
