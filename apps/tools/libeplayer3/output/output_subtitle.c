/*
 * Subtitle output to one registered client.
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */

/* ***************************** */
/* Includes                      */
/* ***************************** */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <memory.h>
#include <asm/types.h>
#include <pthread.h>
#include <errno.h>

#include "common.h"
#include "output.h"
#include "subtitle.h"

/* ***************************** */
/* Makros/Constants              */
/* ***************************** */

#define SUBTITLE_DEBUG

#ifdef SUBTITLE_DEBUG

static short debug_level = 0;

#define subtitle_printf(level, fmt, x...) do { \
		if (debug_level >= level) printf("[%s:%s] " fmt, __FILE__, __FUNCTION__, ## x); } while (0)
#else
#define subtitle_printf(level, fmt, x...)
#endif

#ifndef SUBTITLE_SILENT
#define subtitle_err(fmt, x...) do { printf("[%s:%s] " fmt, __FILE__, __FUNCTION__, ## x); } while (0)
#else
#define subtitle_err(fmt, x...)
#endif

/* Error Constants */
#define cERR_SUBTITLE_NO_ERROR         0
#define cERR_SUBTITLE_ERROR            -1

static const char FILENAME[] = "subtitle.c";

/*
Number, Style, Name,, MarginL, MarginR, MarginV, Effect,, Text

1038,0,tdk,,0000,0000,0000,,That's not good.
1037,0,tdk,,0000,0000,0000,,{\i1}Rack them up, rack them up,{\i0}\N{\i1}rack them up.{\i0} [90]
1036,0,tdk,,0000,0000,0000,,Okay, rack them up.
*/

#define PUFFERSIZE 20

/* ***************************** */
/* Types                         */
/* ***************************** */

struct sub_t
{
	char                  *text;
	unsigned long long int pts;
	unsigned long int      milliDuration;
};

/* ***************************** */
/* Varaibles                     */
/* ***************************** */

static pthread_mutex_t mutex;

void *clientData = NULL;
void (*clientFunction)(long int, size_t, char *, void *);

static struct sub_t subPuffer[PUFFERSIZE];
static int readPointer = 0;
static int writePointer = 0;

static int            screen_width     = 0;
static int            screen_height    = 0;
static int            destStride       = 0;
static int            shareFramebuffer = 0;
static int            framebufferFD    = -1;
static unsigned char *destination      = NULL;
static void (*framebufferBlit)() = NULL;

/* ***************************** */
/* MISC Functions                */
/* ***************************** */
static void getMutex(int line)
{
	subtitle_printf(100, "%d requesting mutex\n", line);
	pthread_mutex_lock(&mutex);
	subtitle_printf(100, "%d received mutex\n", line);
}

static void releaseMutex(int line)
{
	pthread_mutex_unlock(&mutex);
	subtitle_printf(100, "%d released mutex\n", line);
}

void replace_all(char **string, char *search, char *replace)
{
	int len = 0;
	char *ptr = NULL;
	char tempString[512];
	char newString[512];

	newString[0] = '\0';
	if ((string == NULL) || (*string == NULL) || (search == NULL) || (replace == NULL))
	{
		subtitle_err("null pointer passed\n");
		return;
	}
	strncpy(tempString, *string, 511);
	tempString[511] = '\0';
	free(*string);
	while ((ptr = strstr(tempString, search)) != NULL)
	{
		len  = ptr - tempString;
		strncpy(newString, tempString, len);
		newString[len] = '\0';
		strcat(newString, replace);
		len += strlen(search);
		strcat(newString, tempString + len);
		strcpy(tempString, newString);
	}
	subtitle_printf(20, "strdup in line %d\n", __LINE__);
	if (newString[0] != '\0')
		*string = strdup(newString);
	else
		*string = strdup(tempString);
}

int subtitle_ParseASS(char **Line)
{
	char *Text;
	int   i;
	char *ptr1;

	if ((Line == NULL) || (*Line == NULL))
	{
		subtitle_err("null pointer passed\n");
		return cERR_SUBTITLE_ERROR;
	}
	Text = strdup(*Line);
	subtitle_printf(10, "-> Text = %s\n", *Line);
	ptr1 = Text;
	for (i = 0; i < 9 && *ptr1 != '\0'; ptr1++)
	{
		subtitle_printf(20, "%s", ptr1);
		if (*ptr1 == ',')
			i++;
	}
	free(*Line);
	*Line = strdup(ptr1);
	free(Text);
	replace_all(Line, "\\N", "\n");
	replace_all(Line, "{\\i1}", "<i>");
	replace_all(Line, "{\\i0}", "</i>");
	subtitle_printf(10, "<- Text=%s\n", *Line);
	return cERR_SUBTITLE_NO_ERROR;
}

int subtitle_ParseSRT(char **Line)
{
	if ((Line == NULL) || (*Line == NULL))
	{
		subtitle_err("null pointer passed\n");
		return cERR_SUBTITLE_ERROR;
	}
	subtitle_printf(20, "-> Text=%s\n", *Line);
	replace_all(Line, "\x0d", "");
	replace_all(Line, "\n\n", "\\N");
	replace_all(Line, "\n", "");
	replace_all(Line, "\\N", "\n");
	replace_all(Line, "ö", "oe");
	replace_all(Line, "ä", "ae");
	replace_all(Line, "ü", "ue");
	replace_all(Line, "Ö", "Oe");
	replace_all(Line, "Ä", "Ae");
	replace_all(Line, "Ü", "Ue");
	replace_all(Line, "ß", "ss");
	replace_all(Line, "<u>", "");
	replace_all(Line, "<i>", "");
	replace_all(Line, "<b>", "");
	replace_all(Line, "</u>", "");
	replace_all(Line, "</i>", "");
	replace_all(Line, "</b>", "");
	subtitle_printf(10, "<- Text=%s\n", *Line);
	return cERR_SUBTITLE_NO_ERROR;
}

int subtitle_ParseSSA(char **Line)
{
	if ((Line == NULL) || (*Line == NULL))
	{
		subtitle_err("null pointer passed\n");
		return cERR_SUBTITLE_ERROR;
	}
	subtitle_printf(20, "-> Text=%s\n", *Line);
	replace_all(Line, "\x0d", "");
	replace_all(Line, "\n\n", "\\N");
	replace_all(Line, "\n", "");
	replace_all(Line, "\\N", "\n");
	replace_all(Line, "ö", "oe");
	replace_all(Line, "ä", "ae");
	replace_all(Line, "ü", "ue");
	replace_all(Line, "Ö", "Oe");
	replace_all(Line, "Ä", "Ae");
	replace_all(Line, "Ü", "Ue");
	replace_all(Line, "ß", "ss");
	replace_all(Line, "<u>", "");
	replace_all(Line, "<i>", "");
	replace_all(Line, "<b>", "");
	replace_all(Line, "</u>", "");
	replace_all(Line, "</i>", "");
	replace_all(Line, "</b>", "");
	subtitle_printf(10, "<- Text=%s\n", *Line);
	return cERR_SUBTITLE_NO_ERROR;
}

void addSub(Context_t  *context, char *text, unsigned long long int pts, unsigned long int milliDuration)
{
	int count = 20;
	subtitle_printf(50, "index %d\n", writePointer);
	if (context && context->playback && !context->playback->isPlaying)
	{
		subtitle_err("1. aborting ->no playback\n");
		return;
	}
	if (text == NULL)
	{
		subtitle_err("null pointer passed\n");
		return;
	}
	if (pts == 0)
	{
		subtitle_err("pts 0\n");
		return;
	}
	if (milliDuration == 0)
	{
		subtitle_err("duration 0\n");
		return;
	}
	while (subPuffer[writePointer].text != NULL)
	{
		//List is full, wait till we got some free space
		if (context && context->playback && !context->playback->isPlaying)
		{
			subtitle_err("2. aborting ->no playback\n");
			return;
		}
		/* konfetti: we dont want to block forever here. if no buffer
		 * is available we start ring from the beginning and loose some stuff
		 * which is acceptable!
		 */
		subtitle_printf(10, "waiting on free buffer %d - %d (%d) ...\n", writePointer, readPointer, count);
		usleep(10000);
		count--;
		if (count == 0)
		{
			subtitle_err("abort waiting on buffer...\n");
			break;
		}
	}
	subtitle_printf(20, "from mkv: %s pts:%lld milliDuration:%lud\n", text, pts, milliDuration);
	getMutex(__LINE__);
	if (count == 0)
	{
		int i;

		subtitle_err("freeing not delivered data\n");
		//Reset all
		readPointer = 0;
		writePointer = 0;
		for (i = 0; i < PUFFERSIZE; i++)
		{
			if (subPuffer[i].text != NULL)
				free(subPuffer[i].text);
			subPuffer[i].text          = NULL;
			subPuffer[i].pts           = 0;
			subPuffer[i].milliDuration = 0;
		}
	}
	subPuffer[writePointer].text = strdup(text);
	subPuffer[writePointer].pts = pts;
	subPuffer[writePointer].milliDuration = milliDuration;
	writePointer++;
	if (writePointer == PUFFERSIZE)
		writePointer = 0;
	if (writePointer == readPointer)
	{
		/* this should not happen, and means that there is nor reader or
		 * the reader has performance probs ;)
		 * the recovery is done at startup of this function - but next time
		 */
		subtitle_err("ups something went wrong. no more readers? \n");
	}
	releaseMutex(__LINE__);
	subtitle_printf(10, "<\n");
}

/* ***************************** */
/* Functions                     */
/* ***************************** */

static int Write(Context_t *context, void *data)
{
	char *Encoding = NULL;
	char *Text = NULL;
	SubtitleOut_t *out;
	int DataLength;
	unsigned long long int Pts;
	float Duration;

	subtitle_printf(10, "\n");
	if (data == NULL)
	{
		subtitle_err("null pointer passed\n");
		return cERR_SUBTITLE_ERROR;
	}
	out = (SubtitleOut_t *) data;
	if (out->type == eSub_Txt)
	{
		Text = strdup((const char *) out->u.text.data);
	}
	else
	{
		/* fixme handle gfx subs from container_ass and send it to
		 * the callback. this must be implemented also in e2/neutrino
		 * then.
		 */
		subtitle_err("subtitle gfx currently not handled\n");
		return cERR_SUBTITLE_ERROR;
	}
	DataLength = out->u.text.len;
	Pts = out->pts;
	Duration = out->duration;
	context->manager->subtitle->Command(context, MANAGER_GETENCODING, &Encoding);
	if (Encoding == NULL)
	{
		subtitle_err("encoding unknown\n");
		if (Text) free(Text);
		return cERR_SUBTITLE_ERROR;
	}
	subtitle_printf(20, "Encoding:%s Text:%s Len:%d\n", Encoding, Text, DataLength);
	if (!strncmp("S_TEXT/SSA",  Encoding, 10) ||
			!strncmp("S_SSA",       Encoding, 5))
		subtitle_ParseSSA(&Text);
	else if (!strncmp("S_TEXT/ASS",  Encoding, 10) ||
			!strncmp("S_AAS",       Encoding, 5))
		subtitle_ParseASS(&Text);
	else if (!strncmp("S_TEXT/SRT",  Encoding, 10) ||
			!strncmp("S_SRT",       Encoding, 5))
		subtitle_ParseSRT(&Text);
	else
	{
		subtitle_err("unknown encoding %s\n", Encoding);
		return  cERR_SUBTITLE_ERROR;
	}
	subtitle_printf(10, "Text:%s Duration:%f\n", Text, Duration);
	addSub(context, Text, Pts, Duration * 1000);
	if (Text) free(Text);
	subtitle_printf(10, "<\n");
	return cERR_SUBTITLE_NO_ERROR;
}

static int Command(Context_t *context, OutputCmd_t command, void *argument)
{
	int ret = cERR_SUBTITLE_NO_ERROR;

	subtitle_printf(50, "%d\n", command);
	switch (command)
	{
		case OUTPUT_GET_SUBTITLE_OUTPUT:
		{
			SubtitleOutputDef_t *out = (SubtitleOutputDef_t *)argument;
			out->screen_width = screen_width;
			out->screen_height = screen_height;
			out->shareFramebuffer = shareFramebuffer;
			out->framebufferFD = framebufferFD;
			out->destination = destination;
			out->destStride = destStride;
			out->framebufferBlit = framebufferBlit;
			break;
		}
		case OUTPUT_SET_SUBTITLE_OUTPUT:
		{
			SubtitleOutputDef_t *out = (SubtitleOutputDef_t *)argument;
			screen_width = out->screen_width;
			screen_height = out->screen_height;
			shareFramebuffer = out->shareFramebuffer;
			framebufferFD = out->framebufferFD;
			destination = out->destination;
			destStride = out->destStride;
			framebufferBlit = out->framebufferBlit;
			break;
		}
		default:
			subtitle_err("OutputCmd %d not supported!\n", command);
			ret = cERR_SUBTITLE_ERROR;
			break;
	}
	subtitle_printf(50, "exiting with value %d\n", ret);
	return ret;
}

static char *SubtitleCapabilitis[] = { "subtitle", NULL };

struct Output_s SubtitleOutput =
{
	"Subtitle",
	&Command,
	&Write,
	SubtitleCapabilitis
};
