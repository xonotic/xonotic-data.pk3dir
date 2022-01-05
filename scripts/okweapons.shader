OK_SMG
{
	dpglossexponentmod 64
	dpreflectcube env/exomorph/exomorph
	{
		map textures/weapons/ok_smg.tga
		rgbgen lightingDiffuse
	}
}

OK_Railgun
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

okrocketthrust
{
	deformVertexes autosprite2
	cull none
	{
		map models/weapons/okrocketthrust.tga
		tcmod page 4 4 0.01
		blendfunc add
	}
}

okrocketthrust2
{
	deformVertexes autosprite
	{
		map models/weapons/okrocketthrust.tga
		tcmod page 4 4 0.01
		blendfunc add
	}
}
