barrel01
{
	dpreflectcube cubemaps/default/sky
    {
		map models/props/barrel01.tga
	}
	{
		map $lightmap
		blendfunc GL_DST_COLOR GL_ZERO
		rgbGen identity
    }
}

crate01
{
	dpreflectcube cubemaps/default/sky
    {
		map models/props/crate01.tga
	}
	{
		map $lightmap
		blendfunc GL_DST_COLOR GL_ZERO
		rgbGen identity
    }
}

crate02
{
	dpreflectcube cubemaps/default/sky
    {
		map models/props/crate02.tga
	}
	{
		map $lightmap
		blendfunc GL_DST_COLOR GL_ZERO
		rgbGen identity
    }
}