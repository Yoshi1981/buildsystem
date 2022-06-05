/*
 * generic manager handling.
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

#include <stdlib.h>
#include <string.h>

#include <libavformat/avformat.h>
#include "manager.h"
#include "common.h"

/* ***************************** */
/* Makros/Constants              */
/* ***************************** */
#define TRACKWRAP 50

#define MGR_DEBUG
#ifdef MGR_DEBUG

static short debug_level = 0;

#define mgr_printf(level, x...) do { \
		if (debug_level >= level) printf(x); } while (0)
#else
#define mgr_printf(level, x...)
#endif

#ifndef MGR_SILENT
#define mgr_err(x...) do { printf(x); } while (0)
#else
#define mgr_err(x...)
#endif

/* Error Constants */
#define cERR_MGR_NO_ERROR        (0)
#define cERR_MGR_ERROR          (-1)

static const char FILENAME[] = __FILE__;

/* ***************************** */
/* Types                         */
/* ***************************** */

/* ***************************** */
/* Variables                     */
/* ***************************** */

enum TrackType
{
	TRACK_TYPE_AUDIO,
	TRACK_TYPE_VIDEO,
	TRACK_TYPE_SUBTITLE,
	TRACK_TYPE_MAX
};

struct TracksInfo
{
	Track_t *Tracks;
	int Count;
	int Current;
	enum TrackType Type;
};

static int initialized = 0;

static struct TracksInfo tracksInfo[TRACK_TYPE_MAX];

static void Initialize()
{
	int i, j;
	for (i = 0; i < TRACK_TYPE_MAX; ++i)
	{
		tracksInfo[i].Type = (enum TrackType)i;
		tracksInfo[i].Current = (TRACK_TYPE_AUDIO == i || TRACK_TYPE_VIDEO == i) ? 0 : -1;
		tracksInfo[i].Count = 0;
		tracksInfo[i].Tracks = malloc(sizeof(Track_t) * TRACKWRAP);
		if (NULL == tracksInfo[i].Tracks)
		{
			mgr_err("%s:%s malloc failed\n", FILENAME, __FUNCTION__);
			initialized = -1;
			return;
		}
		for (j = 0; j < TRACKWRAP; ++j) tracksInfo[i].Tracks[j].Id = -1;
	}
	initialized = 1;
}

void copyTrack(Track_t *to, Track_t *from)
{
	*to = *from;
	to->Name     = (from->Name     != NULL) ? strdup(from->Name)    : strdup("Unknown");
	to->Encoding = (from->Encoding != NULL) ? strdup(from->Encoding) : strdup("Unknown");
	to->language = (from->language != NULL) ? strdup(from->language) : strdup("Unknown");
}

void freeTrack(Track_t *track)
{
	if (track->Name != NULL)
	{
		free(track->Name);
		track->Name = NULL;
	}
	if (track->Encoding != NULL)
	{
		free(track->Encoding);
		track->Encoding = NULL;
	}
	if (track->language != NULL)
	{
		free(track->language);
		track->language = NULL;
	}
	if (track->aacbuf != NULL)
		free(track->aacbuf);
	track->aacbuf = NULL;
}

static int ManagerAdd(struct TracksInfo *t, Context_t  *context, Track_t track)
{
	int i;
	mgr_printf(10, "%s::%s name=\"%s\" encoding=\"%s\" id=%d\n", FILENAME, __FUNCTION__, track.Name, track.Encoding, track.Id);
	for (i = 0; i < t->Count; i++)
	{
		if (t->Tracks[i].Id == track.Id)
			return cERR_MGR_NO_ERROR;
	}
	if (t->Count < TRACKWRAP)
	{
		copyTrack(&(t->Tracks[t->Count]), &track);
		t->Count++;
	}
	else
	{
		mgr_err("%s:%s TrackCount out if range %d - %d\n", FILENAME, __FUNCTION__, t->Count, TRACKWRAP);
		return cERR_MGR_ERROR;
	}
	if (t->Count > 0)
	{
		switch (t->Type)
		{
			case TRACK_TYPE_AUDIO:
				context->playback->isAudio = 1;
				break;
			case TRACK_TYPE_VIDEO:
				context->playback->isVideo = 1;
				break;
			case TRACK_TYPE_SUBTITLE:
				context->playback->isSubtitle = 1;
				break;
			default:
				break;
		}
	}
	mgr_printf(10, "%s::%s\n", FILENAME, __FUNCTION__);
	return cERR_MGR_NO_ERROR;
}

static char **ManagerList(struct TracksInfo *t, Context_t  *context)
{
	int i, j;
	char **tracklist = NULL;
	mgr_printf(10, "%s::%s\n", FILENAME, __FUNCTION__);
	if (t->Count > 0)
	{
		tracklist = malloc(sizeof(char *) * ((t->Count * 2) + 1));
		if (tracklist == NULL)
		{
			mgr_err("%s:%s malloc failed\n", FILENAME, __FUNCTION__);
			return NULL;
		}
		for (i = 0, j = 0; i < t->Count; i++)
		{
			tracklist[j++]  = strdup(t->Tracks[i].Name);
			tracklist[j++]  = strdup(t->Tracks[i].Encoding);
		}
		tracklist[j] = NULL;
	}
	mgr_printf(10, "%s::%s return %p (%d - %d)\n", FILENAME, __FUNCTION__, tracklist, j, t->Count);
	return tracklist;
}

static int ManagerDel(struct TracksInfo *t, Context_t *context)
{
	int i = 0;
	mgr_printf(10, "%s::%s\n", FILENAME, __FUNCTION__);
	if (t->Tracks != NULL)
	{
		for (i = 0; i < t->Count; i++)
		{
			freeTrack(&(t->Tracks[i]));
		}
	}
	else
	{
		mgr_err("%s::%s nothing to delete!\n", FILENAME, __FUNCTION__);
		return cERR_MGR_ERROR;
	}
	t->Count = 0;
	switch (t->Type)
	{
		case TRACK_TYPE_AUDIO:
			context->playback->isAudio = 0;
			break;
		case TRACK_TYPE_VIDEO:
			context->playback->isVideo = 0;
			break;
		case TRACK_TYPE_SUBTITLE:
			context->playback->isSubtitle = 0;
			break;
		default:
			break;
	}
	t->Current = (TRACK_TYPE_AUDIO == t->Type || TRACK_TYPE_VIDEO == t->Type) ? 0 : -1;
	mgr_printf(10, "%s::%s return no error\n", FILENAME, __FUNCTION__);
	return cERR_MGR_NO_ERROR;
}

static int Command(struct TracksInfo *t, Context_t *context, ManagerCmd_t command, void *argument)
{
	int ret = cERR_MGR_NO_ERROR;
	if (initialized == 0)
	{
		Initialize();
	}
	if (initialized == -1) return cERR_MGR_ERROR;
	mgr_printf(10, "%s::%s\n", FILENAME, __FUNCTION__);
	switch (command)
	{
		case MANAGER_ADD:
		{
			Track_t *track = argument;
			ret = ManagerAdd(t, context, *track);
			break;
		}
		case MANAGER_LIST:
		{
			*((char ** *)argument) = ManagerList(t, context);
			break;
		}
		case MANAGER_GET:
		{
			mgr_printf(20, "%s::%s MANAGER_GET\n", FILENAME, __FUNCTION__);
			if (t->Count > 0 && t->Current >= 0)
				*((int *)argument) = (int)t->Tracks[t->Current].Id;
			else
				*((int *)argument) = (int) - 1;
			break;
		}
		case MANAGER_GET_TRACK:
		{
			mgr_printf(20, "%s::%s MANAGER_GET_TRACK\n", FILENAME, __FUNCTION__);
			if (t->Count > 0 && t->Current >= 0)
				*((Track_t **)argument) = (Track_t *) &t->Tracks[t->Current];
			else
				*((Track_t **)argument) = NULL;
			break;
		}
		case MANAGER_GETENCODING:
		{
			if (t->Count > 0 && t->Current >= 0)
				// track encoding points to a static string, so no need to strdup()
				*((char **)argument) = (char *)t->Tracks[t->Current].Encoding;
			else
				*((char **)argument) = NULL ;
			break;
		}
		case MANAGER_GETNAME:
		{
			if (t->Count > 0 && t->Current >= 0)
				*((char **)argument) = (char *)t->Tracks[t->Current].Name;
			else
				*((char **)argument) = (char *)"";
			break;
		}
		case MANAGER_SET:
		{
			int id = *((int *)argument);
			mgr_printf(20, "%s::%s MANAGER_SET id=%d\n", FILENAME, __FUNCTION__, id);
			if (id < t->Count)
				t->Current = id;
			else
			{
				mgr_err("%s::%s track id out of range (%d - %d)\n", FILENAME, __FUNCTION__, id, t->Count);
				ret = cERR_MGR_ERROR;
			}
			break;
		}
		case MANAGER_DEL:
		{
			ret = ManagerDel(t, context);
			break;
		}
		case MANAGER_INIT_UPDATE:
		{
			t->Count = 0;
			break;
		}
		default:
			mgr_err("%s::%s ContainerCmd %d not supported!\n", FILENAME, __FUNCTION__, command);
			ret = cERR_MGR_ERROR;
			break;
	}
	mgr_printf(10, "%s:%s: returning %d\n", FILENAME, __FUNCTION__, ret);
	return ret;
}

static int Command_audio(Context_t *context, ManagerCmd_t command, void *argument)
{
	return Command(&tracksInfo[TRACK_TYPE_AUDIO], context, command, argument);
}

static int Command_video(Context_t *context, ManagerCmd_t command, void *argument)
{
	return Command(&tracksInfo[TRACK_TYPE_VIDEO], context, command, argument);
}

static int Command_subtitle(Context_t *context, ManagerCmd_t command, void *argument)
{
	return Command(&tracksInfo[TRACK_TYPE_SUBTITLE], context, command, argument);
}

struct Manager_s AudioManager =
{
	"Audio",
	&Command_audio,
	NULL
};

struct Manager_s VideoManager =
{
	"Video",
	&Command_video,
	NULL
};

struct Manager_s SubtitleManager =
{
	"Subtitle",
	&Command_subtitle,
	NULL
};

ManagerHandler_t ManagerHandler =
{
	"ManagerHandler",
	&AudioManager,
	&VideoManager,
	&SubtitleManager
};
