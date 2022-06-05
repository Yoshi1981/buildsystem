#ifndef PLAYBACK_H_
#define PLAYBACK_H_
#include <sys/types.h>

typedef enum {PLAYBACK_OPEN, PLAYBACK_CLOSE, PLAYBACK_PLAY, PLAYBACK_STOP, PLAYBACK_PAUSE, PLAYBACK_CONTINUE, PLAYBACK_TERM, PLAYBACK_FASTFORWARD, PLAYBACK_SEEK, PLAYBACK_SEEK_ABS, PLAYBACK_PTS, PLAYBACK_LENGTH, PLAYBACK_SWITCH_AUDIO, PLAYBACK_SWITCH_SUBTITLE, PLAYBACK_INFO, PLAYBACK_SLOWMOTION, PLAYBACK_FASTBACKWARD, PLAYBACK_SWITCH_TELETEXT, PLAYBACK_SWITCH_DVBSUBTITLE, PLAYBACK_FRAMEBUFFER_LOCK, PLAYBACK_FRAMEBUFFER_UNLOCK} PlaybackCmd_t;

struct Context_s;
typedef struct Context_s Context_t;

typedef struct PlaybackHandler_s
{
	char *Name;

	int fd;

	unsigned char isHttp;
	unsigned char isPlaying;
	unsigned char isPaused;
	unsigned char isForwarding;
	unsigned char isSeeking;
	unsigned char isCreationPhase;

	float BackWard;
	int SlowMotion;
	int Speed;
	int AVSync;

	unsigned char isVideo;
	unsigned char isAudio;
	unsigned char isSubtitle;
	unsigned char abortRequested;
	unsigned char abortPlayback;

	int (* Command)(Context_t *, PlaybackCmd_t, void *);
	char *uri;
	unsigned long long readCount;
} PlaybackHandler_t;

void libeplayerThreadStop(); // Tell enigma2 that we stop

#endif
