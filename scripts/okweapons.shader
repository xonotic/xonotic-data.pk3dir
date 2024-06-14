OK_SMG // ok_mg material
{
	dpglossexponentmod 64
	dpreflectcube env/exomorph/exomorph
	{
		map textures/weapons/ok_smg.tga
		rgbgen lightingDiffuse
	}
}

OK_Railgun // ok_nex material
{
	dpglossexponentmod 64
	dpreflectcube env/exomorph/exomorph
	{
		map textures/weapons/ok_railgun.tga
		rgbgen lightingDiffuse
	}
}

OK_shotgun
{
	dpglossexponentmod 64
	dpreflectcube env/exomorph/exomorph
	{
		map textures/weapons/ok_shotgun.tga
		rgbgen lightingDiffuse
	}
}


minsta
{
	dpglossexponentmod 64
	dpreflectcube env/exomorph/exomorph
	{
		map models/weapons/okweapons.tga
		rgbgen lightingDiffuse
	}
}

okrocketthrust // ok_rpc rocketthrust tail material
{
	deformVertexes autosprite2
	cull none
	{
		map models/weapons/okrocketthrust.tga
		tcmod page 4 4 0.01
		blendfunc add
	}
}

okrocketthrust2 // ok_rpc rocketthrust2 tail material
{
	deformVertexes autosprite
	{
		map models/weapons/okrocketthrust.tga
		tcmod page 4 4 0.01
		blendfunc add
	}
}
