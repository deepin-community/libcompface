/*
 *  Compface - 48x48x1 image compression and decompression
 *
 *  Copyright (c) James Ashton - Sydney University - June 1990.
 *
 *  Written 11th November 1989.
 *
 *  Permission is given to distribute these sources, as long as the
 *  copyright messages are not removed, and no monies are exchanged. 
 *
 *  No responsibility is taken for any errors on inaccuracies inherent
 *  either to the comments or the code of this program, but if reported
 *  to me, then an attempt will be made to fix them.
 */


#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "compface.h"

int compface_xbitmap=0;

void
BigRead(fbuf)
register char *fbuf;
{
	register int c;

	while (*fbuf != '\0')
	{
		c = *(fbuf++);
		if ((c < FIRSTPRINT) || (c > LASTPRINT))
			continue;
		BigMul(NUMPRINTS);
		BigAdd((WORD)(c - FIRSTPRINT));
	}
}

void
BigWrite(fbuf)
register char *fbuf;
{
	static WORD tmp;
	static char buf[DIGITS];
	register char *s;
	register int i;

	s = buf;
	while (B.b_words > 0)
	{
		BigDiv(NUMPRINTS, &tmp);
		*(s++) = tmp + FIRSTPRINT;
	}
	i = 7;	/* leave room for the field name on the first line */
	*(fbuf++) = ' ';
	while (s-- > buf)
	{
		if (i == 0)
			*(fbuf++) = ' ';
		*(fbuf++) = *s;
		if (++i >= MAXLINELEN)
		{
			*(fbuf++) = '\n';
			i = 0;
		}
	}
	if (i > 0)
		*(fbuf++) = '\n';
	*(fbuf++) = '\0';
}

void
ReadFace(fbuf)
char *fbuf;
{
	register int c, i;
	register char *s, *t;
	static char table_inv[] = { 0,8,4,12,2,10,6,14,1,9, 5,13, 3,11, 7,15 };
	static char table_nop[] = { 0,1,2, 3,4, 5,6, 7,8,9,10,11,12,13,14,15 };
	char *table = table_nop;	/* optionally invert bits in nibble */
	register inc = 0;		/* optionally swap nimmles */
	int bits;
	int len;

	t = s = fbuf;

	/* Does this look like an X bitmap ? */
	if (sscanf(s, "#define %*s %d", &bits) == 1) {
		if (bits == 48) {
			char type1[256];
			char type2[256];
			while (*s && *s++ != '\n');
			if (sscanf(s, "#define %*s %d", &bits) == 1) if (bits == 48) {
				while (*s && *s++ != '\n');
				for (len=0; s[len] && s[len]!='\n'; len++);
				if (len<255) {
				  if (sscanf(s, "static %s %s", type1,type2)==2 &&
					(!strcmp(type1, "char") || 
				    	 !strcmp(type2, "char"))) {
						while (*s && *s++ != '\n');
						inc = 1;
						table = table_inv;
					}
				  else fprintf(stderr, "warning: xbitmap line 3 not static [unsigned] short ...\n");
				} else fprintf(stderr, "warning: xbitmap line 3 too long\n");
			}
			else fprintf(stderr, "warning: xbitmaps must be 48x48\n");
		}
		else fprintf(stderr, "warning: xbitmaps must be 48x48\n");
	}
	/* Ensure s is reset if it was not an X bitmap ... */
	if (! inc) s = fbuf;

	for(i = strlen(s); i > 0; i--)
	{
		c = (int)*(s++);
		if ((c >= '0') && (c <= '9'))
		{
			if (t >= fbuf + DIGITS)
			{
				status = ERR_EXCESS;
				break;
			}
			(t++)[inc] = table[c - '0']; inc = - inc;
		}
		else if ((c >= 'A') && (c <= 'F'))
		{
			if (t >= fbuf + DIGITS)
			{
				status = ERR_EXCESS;
				break;
			}
			(t++)[inc] = table[c - 'A' + 10]; inc = - inc;
		}
		else if ((c >= 'a') && (c <= 'f'))
		{
			if (t >= fbuf + DIGITS)
			{
				status = ERR_EXCESS;
				break;
			}
			(t++)[inc] = table[c - 'a' + 10]; inc = - inc;
		}
		else if (((c == 'x') || (c == 'X')) && (t > fbuf) &&
			((t-1)[-inc] == table[0])) { t--; inc = -inc; }
	}
	if (t < fbuf + DIGITS)
		longjmp(comp_env, ERR_INSUFF);
	s = fbuf;
	t = F;
	c = 1 << (BITSPERDIG - 1);
	while (t < F + PIXELS)
	{
		*(t++) = (*s & c) ? 1 : 0;
		if ((c >>= 1) == 0)
		{
			s++;
			c = 1 << (BITSPERDIG - 1);
		}
	}
}

void
WriteFace(fbuf)
char *fbuf;
{
	register char *s, *t;
	register int i, bits, digits, words;
	int digsperword = DIGSPERWORD;
	int wordsperline = WORDSPERLINE;

	s = F;
	t = fbuf;
	bits = digits = words = i = 0;
	if (compface_xbitmap) {
		sprintf(t,"#define noname_width 48\n#define noname_height 48\nstatic char noname_bits[] = {\n ");
		while (*t) t++;
		digsperword = 2;
		wordsperline = 15;
	}
	while (s < F + PIXELS)
	{
		if ((bits == 0) && (digits == 0))
		{
			*(t++) = '0';
			*(t++) = 'x';
		}
		if (compface_xbitmap) {
			if (*(s++))
				i = (i >> 1) | 0x8;
			else
				i >>= 1;
		}
		else {
			if (*(s++))
				i = i * 2 + 1;
			else
				i *= 2;
		}
		if (++bits == BITSPERDIG)
		{
			if (compface_xbitmap) {
				t++;
				t[-(digits & 1) * 2] = *(i + HexDigits);
			}
			else *(t++) = *(i + HexDigits);
			bits = i = 0;
			if (++digits == digsperword)
			{
				if (compface_xbitmap && (s >= F + PIXELS))
				  break;
				*(t++) = ',';
				digits = 0;
				if (++words == wordsperline)
				{
					*(t++) = '\n';
					if (compface_xbitmap) *(t++) = ' ';
					words = 0;
				}
			}
		}
	}
	if (compface_xbitmap) {
		sprintf(t, "};\n");
		while (*t) t++;
	}
	*(t++) = '\0';
}
