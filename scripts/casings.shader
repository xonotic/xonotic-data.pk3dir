models/casing_bronze
{
	dpglossintensitymod  2
	dpglossexponentmod  4
	dpreflectcube env/exomorph/exomorph
	{
		map models/casing_bronze.tga
	}
	{
		map $lightmap
		rgbGen identity
		tcGen lightmap
		blendfunc filter
	}
}
