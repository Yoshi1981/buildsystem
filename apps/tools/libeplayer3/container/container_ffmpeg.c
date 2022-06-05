/*
 * Container handling for all stream's handled by ffmpeg
 * konfetti 2010; based on code from crow
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
#include <stdlib.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <memory.h>
#include <string.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/poll.h>
#include <pthread.h>
#include <sys/prctl.h>

#include <libavutil/avutil.h>
#include <libavutil/time.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>

#include "common.h"
#include "misc.h"
#include "debug.h"
#include "aac.h"
#include "pcm.h"
#include "ffmpeg_metadata.h"
#include "subtitle.h"

/* ***************************** */
/* Makros/Constants              */
/* ***************************** */

#define FFMPEG_DEBUG

#ifdef FFMPEG_DEBUG

static short debug_level = 10;

#define ffmpeg_printf(level, fmt, x...) do { \
		if (debug_level >= level) printf("[%s:%s] " fmt, FILENAME, __FUNCTION__, ## x); } while (0)
#else
#define ffmpeg_printf(level, fmt, x...)
#endif

#ifndef FFMPEG_SILENT
#define ffmpeg_err(fmt, x...) do { printf("[%s:%s] " fmt, FILENAME, __FUNCTION__, ## x); } while (0)
#else
#define ffmpeg_err(fmt, x...)
#endif

/* Error Constants */
#define cERR_CONTAINER_FFMPEG_NO_ERROR        0
#define cERR_CONTAINER_FFMPEG_INIT           -1
#define cERR_CONTAINER_FFMPEG_NOT_SUPPORTED  -2
#define cERR_CONTAINER_FFMPEG_INVALID_FILE   -3
#define cERR_CONTAINER_FFMPEG_RUNNING        -4
#define cERR_CONTAINER_FFMPEG_NOMEM          -5
#define cERR_CONTAINER_FFMPEG_OPEN           -6
#define cERR_CONTAINER_FFMPEG_STREAM         -7
#define cERR_CONTAINER_FFMPEG_NULL           -8
#define cERR_CONTAINER_FFMPEG_ERR            -9
#define cERR_CONTAINER_FFMPEG_END_OF_FILE    -10

static const char *FILENAME = "container_ffmpeg.c";

/* ***************************** */
/* Types                         */
/* ***************************** */

/* ***************************** */
/* Variables                     */
/* ***************************** */

static pthread_t PlayThread;
volatile static int hasPlayThreadStarted = 0;
static AVFormatContext   *avContext = NULL;
volatile static unsigned int isContainerRunning = 0;
static float seek_sec_rel = 0.0;
#if 0
static float seek_sec_abs = -1.0;
#endif

/* ***************************** */
/* Prototypes                    */
/* ***************************** */

/* ***************************** */
/* MISC Functions                */
/* ***************************** */

static char *Codec2Encoding(AVCodecContext *codec)
{
	fprintf(stderr, "Codec ID: %ld (%.8lx)\n", (long)codec->codec_id, (long)codec->codec_id);
	switch (codec->codec_id)
	{
		case AV_CODEC_ID_MPEG1VIDEO:
		case AV_CODEC_ID_MPEG2VIDEO:
			return "V_MPEG1";
		case AV_CODEC_ID_H263:
		case AV_CODEC_ID_H263P:
		case AV_CODEC_ID_H263I:
			return "V_H263";
		case AV_CODEC_ID_FLV1:
			return "V_FLV";
		case AV_CODEC_ID_VP5:
		case AV_CODEC_ID_VP6:
		case AV_CODEC_ID_VP6F:
			return "V_VP6";
		case AV_CODEC_ID_RV10:
		case AV_CODEC_ID_RV20:
			return "V_RMV";
		case AV_CODEC_ID_MPEG4:
		case AV_CODEC_ID_MSMPEG4V1:
		case AV_CODEC_ID_MSMPEG4V2:
		case AV_CODEC_ID_MSMPEG4V3:
			return "V_MSCOMP";
		case AV_CODEC_ID_WMV1:
		case AV_CODEC_ID_WMV2:
		case AV_CODEC_ID_WMV3:
			return "V_WMV";
		case AV_CODEC_ID_VC1:
			return "V_VC1";
		case AV_CODEC_ID_H264:
			return "V_MPEG4/ISO/AVC";
		case AV_CODEC_ID_AVS:
			return "V_AVS";
		case AV_CODEC_ID_MP2:
			return "A_MPEG/L3";
		case AV_CODEC_ID_MP3:
			return "A_MP3";
		case AV_CODEC_ID_AC3:
			return "A_AC3";
		case AV_CODEC_ID_DTS:
			return "A_DTS";
		case AV_CODEC_ID_AAC:
			return "A_AAC";
		/* subtitle */
		case AV_CODEC_ID_SSA:
			return "S_TEXT/ASS"; /* Hellmaster1024: seems to be ASS instead of SSA */
		case AV_CODEC_ID_TEXT: /* Hellmaster1024: i dont have most of this, but lets hope it is normal text :-) */
		case AV_CODEC_ID_DVD_SUBTITLE:
		case AV_CODEC_ID_DVB_SUBTITLE:
		case AV_CODEC_ID_XSUB:
		case AV_CODEC_ID_MOV_TEXT:
		case AV_CODEC_ID_HDMV_PGS_SUBTITLE:
		case AV_CODEC_ID_DVB_TELETEXT:
		case AV_CODEC_ID_SRT:
		case AV_CODEC_ID_SUBRIP:
			return "S_TEXT/SRT"; /* fixme */
		default:
			// Default to injected-pcm for unhandled audio types.
			if (codec->codec_type == AVMEDIA_TYPE_AUDIO)
				return "A_IPCM";
			if (codec->codec_type == AVMEDIA_TYPE_SUBTITLE)
				return "S_TEXT/SRT";
			ffmpeg_err("Codec ID %ld (%.8lx) not found\n", (long)codec->codec_id, (long)codec->codec_id);
	}
	return NULL;
}

long long int calcPts(AVStream *stream, int64_t pts)
{
	if (pts == AV_NOPTS_VALUE)
		return INVALID_PTS_VALUE;
	pts = 90000 * (double)pts * stream->time_base.num / stream->time_base.den;
	if (avContext->start_time != AV_NOPTS_VALUE)
		pts -= 90000 * avContext->start_time / AV_TIME_BASE;
	if (pts < 0)
		return INVALID_PTS_VALUE;
	return pts;
}

/*Hellmaster1024: get the Duration of the subtitle from the SSA line*/
float getDurationFromSSALine(unsigned char *line)
{
	int i, h, m, s, ms;
	char *Text = strdup((char *) line);
	char *ptr1;
	char *ptr[10];
	long int msec;

	ptr1 = Text;
	ptr[0] = Text;
	for (i = 0; i < 3 && *ptr1 != '\0'; ptr1++)
	{
		if (*ptr1 == ',')
		{
			ptr[++i] = ptr1 + 1;
			*ptr1 = '\0';
		}
	}
	sscanf(ptr[2], "%d:%d:%d.%d", &h, &m, &s, &ms);
	msec = (ms * 10) + (s * 1000) + (m * 60 * 1000) + (h * 24 * 60 * 1000);
	sscanf(ptr[1], "%d:%d:%d.%d", &h, &m, &s, &ms);
	msec -= (ms * 10) + (s * 1000) + (m * 60 * 1000) + (h * 24 * 60 * 1000);
	ffmpeg_printf(10, "%s %s %f\n", ptr[2], ptr[1], (float) msec / 1000.0);
	free(Text);
	return (float)msec / 1000.0;
}

/* search for metadata in context and stream
 * and map it to our metadata.
 */

static char *searchMeta(AVDictionary *metadata, char *ourTag)
{
	AVDictionaryEntry *tag = NULL;
	int i = 0;

	while (metadata_map[i])
	{
		if (!strcasecmp(ourTag, metadata_map[i]))
		{
			while ((tag = av_dict_get(metadata, "", tag, AV_DICT_IGNORE_SUFFIX)))
			{
				if (!strcasecmp(tag->key, ourTag) || !strcmp(tag->key, metadata_map[i + 1]))
				{
					return tag->value;
				}
			}
		}
		i += 2;
	}
	return NULL;
}

/* **************************** */
/* Worker Thread                */
/* **************************** */

static void FFMPEGThread(Context_t *context)
{
	char threadname[17];
	strncpy(threadname, __func__, sizeof(threadname));
	threadname[16] = 0;
	prctl(PR_SET_NAME, (unsigned long)&threadname);
	hasPlayThreadStarted = 1;
	long long int currentVideoPts = -1, currentAudioPts = -1, showtime = 0, bofcount = 0;
	AudioVideoOut_t avOut;
	SwrContext *swr = NULL;
	AVFrame *decoded_frame = NULL;
	int out_sample_rate = 44100;
	int out_channels = 2;
	uint64_t out_channel_layout = AV_CH_LAYOUT_STEREO;
	int restart_audio_resampling = 0;
	ffmpeg_printf(10, "\n");
	while (context->playback->isCreationPhase)
	{
		ffmpeg_err("Thread waiting for end of init phase...\n");
		usleep(1000);
	}
	ffmpeg_printf(10, "Running!\n");
	while (context && context->playback && context->playback->isPlaying && !context->playback->abortRequested)
	{
		//IF MOVIE IS PAUSED, WAIT
		if (context->playback->isPaused)
		{
			ffmpeg_printf(20, "paused\n");
			usleep(100000);
			continue;
		}
		int seek_target_flag = 0;
		int64_t seek_target = INT64_MIN;
		if (seek_sec_rel != 0.0)
		{
			if (avContext->iformat->flags & AVFMT_TS_DISCONT)
			{
				float br = (avContext->bit_rate) ? avContext->bit_rate / 8.0 : 180000.0;
				seek_target_flag = AVSEEK_FLAG_BYTE;
				seek_target = avio_tell(avContext->pb) + seek_sec_rel * br;
			}
			else
			{
				seek_target = ((((currentVideoPts > 0) ? currentVideoPts : currentAudioPts) / 90000.0) + seek_sec_rel) * AV_TIME_BASE;
			}
			seek_sec_rel = 0.0;
#if 0
		}
		else if (seek_sec_abs >= 0.0)
		{
			if (avContext->iformat->flags & AVFMT_TS_DISCONT)
			{
				float br = (avContext->bit_rate) ? avContext->bit_rate / 8.0 : 180000.0;
				seek_target_flag = AVSEEK_FLAG_BYTE;
				seek_target = seek_sec_abs * br;
			}
			else
			{
				seek_target = seek_sec_abs * AV_TIME_BASE;
			}
			seek_sec_abs = -1.0;
#endif
		}
		else if (context->playback->BackWard && av_gettime_relative() >= showtime)
		{
			context->output->Command(context, OUTPUT_CLEAR, "video");
			if (bofcount == 1)
			{
				showtime = av_gettime_relative();
				usleep(100000);
				continue;
			}
			if (avContext->iformat->flags & AVFMT_TS_DISCONT)
			{
				off_t pos = avio_tell(avContext->pb);
				if (pos > 0)
				{
					float br;
					if (avContext->bit_rate)
						br = avContext->bit_rate / 8.0;
					else
						br = 180000.0;
					seek_target = pos + context->playback->Speed * 8 * br;
					seek_target_flag = AVSEEK_FLAG_BYTE;
				}
			}
			else
			{
				seek_target = ((((currentVideoPts > 0) ? currentVideoPts : currentAudioPts) / 90000.0) + context->playback->Speed * 8) * AV_TIME_BASE;;
			}
			showtime = av_gettime_relative() + 300000;      //jump back every 300ms
		}
		else
		{
			bofcount = 0;
		}
		if (seek_target > INT64_MIN)
		{
			int res;
			if (seek_target < 0)
				seek_target = 0;
			res = avformat_seek_file(avContext, -1, INT64_MIN, seek_target, INT64_MAX, seek_target_flag);
			if (res < 0 && context->playback->BackWard)
				bofcount = 1;
			seek_target = INT64_MIN;
			restart_audio_resampling = 1;
			// flush streams
			unsigned int i;
			for (i = 0; i < avContext->nb_streams; i++)
				if (avContext->streams[i]->codec && avContext->streams[i]->codec->codec)
					avcodec_flush_buffers(avContext->streams[i]->codec);
		}
		AVPacket   packet;
		av_init_packet(&packet);
		packet.data = NULL;
		packet.size = 0;
		int av_res = av_read_frame(avContext, &packet);
		if (av_res == AVERROR(EAGAIN))
		{
			av_packet_unref(&packet);
			continue;
		}
		if (av_res)             // av_read_frame failed
		{
			ffmpeg_err("no data ->end of file reached ?\n");
			av_packet_unref(&packet);
			break;          // while
		}
		uint8_t *packet_data = packet.data;
		int packet_size = packet.size;
		Track_t *videoTrack = NULL;
		Track_t *audioTrack = NULL;
		Track_t *subtitleTrack = NULL;
		context->playback->readCount += packet_size;
		int pid = avContext->streams[packet.stream_index]->id;
		if (context->manager->video->Command(context, MANAGER_GET_TRACK, &videoTrack) < 0)
			ffmpeg_err("error getting video track\n");
		if (context->manager->audio->Command(context, MANAGER_GET_TRACK, &audioTrack) < 0)
			ffmpeg_err("error getting audio track\n");
		if (context->manager->subtitle->Command(context, MANAGER_GET_TRACK, &subtitleTrack) < 0)
			ffmpeg_err("error getting subtitle track\n");
		ffmpeg_printf(200, "packet_size %d - index %d\n", packet_size, pid);
		if (videoTrack && (videoTrack->Id == pid))
		{
			currentVideoPts = videoTrack->pts = calcPts(videoTrack->stream, packet.pts);
			avOut.data       = packet_data;
			avOut.len        = packet_size;
			avOut.pts        = currentVideoPts;
			avOut.extradata  = videoTrack->extraData;
			avOut.extralen   = videoTrack->extraSize;
			avOut.frameRate  = videoTrack->frame_rate;
			avOut.timeScale  = videoTrack->TimeScale;
			avOut.width      = videoTrack->width;
			avOut.height     = videoTrack->height;
			avOut.type       = OUTPUT_TYPE_VIDEO;
			if (context->output->video->Write(context, &avOut) < 0)
			{
				ffmpeg_err("writing data to video device failed\n");
			}
		}
		else if (audioTrack && (audioTrack->Id == pid) && !context->playback->BackWard)
		{
			currentAudioPts = audioTrack->pts = calcPts(audioTrack->stream, packet.pts);
			ffmpeg_printf(200, "AudioTrack index = %d\n", pid);
			if (audioTrack->inject_as_pcm == 1)
			{
				AVCodecContext *c = ((AVStream *)(audioTrack->stream))->codec;
				if (restart_audio_resampling)
				{
					restart_audio_resampling = 0;
					if (swr)
					{
						swr_free(&swr);
						swr = NULL;
					}
					if (decoded_frame)
					{
						av_frame_free(&decoded_frame);
						decoded_frame = NULL;
					}
					context->output->Command(context, OUTPUT_CLEAR, NULL);
					context->output->Command(context, OUTPUT_PLAY, NULL);
				}
				while (packet_size > 0)
				{
					int got_frame = 0;
					if (!decoded_frame)
					{
						if (!(decoded_frame = av_frame_alloc()))
						{
							fprintf(stderr, "out of memory\n");
							exit(1);
						}
					}
					else
						av_frame_unref(decoded_frame);
					int len = avcodec_decode_audio4(c, decoded_frame, &got_frame, &packet);
					if (len < 0)
					{
						//fprintf(stderr, "avcodec_decode_audio4: %d\n", len);
						break;
					}
					packet_data += len;
					packet_size -= len;
					if (!got_frame)
						continue;
					int e;
					if (!swr)
					{
						int in_rate = c->sample_rate;
						// rates in descending order
						int rates[] = { 192000, 176400, 96000, 88200, 48000, 44100, 0 };
						int i = 0;
						// find the next equal or smallest rate
						while (rates[i] && in_rate < rates[i]) i++;
						if (rates[i]) out_sample_rate = rates[i];
						swr = swr_alloc();
						out_channels = c->channels;
						if (c->channel_layout == 0)
						{
							// FIXME -- need to guess, looks pretty much like a bug in the FFMPEG WMA decoder
							c->channel_layout = AV_CH_LAYOUT_STEREO;
						}
						out_channel_layout = c->channel_layout;
						// player2 won't play mono
						if (out_channel_layout == AV_CH_LAYOUT_MONO)
						{
							out_channel_layout = AV_CH_LAYOUT_STEREO;
							out_channels = 2;
						}
						av_opt_set_int(swr, "in_channel_layout",        c->channel_layout,      0);
						av_opt_set_int(swr, "out_channel_layout",       out_channel_layout,     0);
						av_opt_set_int(swr, "in_sample_rate",           c->sample_rate,         0);
						av_opt_set_int(swr, "out_sample_rate",          out_sample_rate,        0);
						av_opt_set_sample_fmt(swr, "in_sample_fmt",     c->sample_fmt,          0);
						av_opt_set_sample_fmt(swr, "out_sample_fmt",    AV_SAMPLE_FMT_S16,      0);
						e = swr_init(swr);
						if (e < 0)
						{
							fprintf(stderr, "swr_init: %d (icl=%d ocl=%d isr=%d osr=%d isf=%d osf=%d\n",
								-e,
								(int)c->channel_layout, (int)out_channel_layout, c->sample_rate, out_sample_rate, c->sample_fmt, AV_SAMPLE_FMT_S16);
							swr_free(&swr);
							swr = NULL;
							continue;
						}
					}
					uint8_t *output = NULL;
					int in_samples = decoded_frame->nb_samples;
					int out_samples = av_rescale_rnd(swr_get_delay(swr, c->sample_rate) + in_samples, out_sample_rate, c->sample_rate, AV_ROUND_UP);
					int out_linesize;
					e = av_samples_alloc(&output, &out_linesize, out_channels, out_samples, AV_SAMPLE_FMT_S16, 1);
					if (e < 0)
					{
						fprintf(stderr, "av_samples_alloc: %d\n", -e);
						continue;
					}
					int64_t next_in_pts = av_rescale(av_frame_get_best_effort_timestamp(decoded_frame),
									 ((AVStream *) audioTrack->stream)->time_base.num * (int64_t)out_sample_rate * c->sample_rate,
									 ((AVStream *) audioTrack->stream)->time_base.den);
					int64_t next_out_pts = av_rescale(swr_next_pts(swr, next_in_pts),
									  ((AVStream *) audioTrack->stream)->time_base.den,
									  ((AVStream *) audioTrack->stream)->time_base.num * (int64_t)out_sample_rate * c->sample_rate);
					currentAudioPts = audioTrack->pts = calcPts(audioTrack->stream, next_out_pts);
					out_samples = swr_convert(swr, &output, out_samples, (const uint8_t **) &decoded_frame->data[0], in_samples);
					if (out_samples < 0)
					{
						continue;
					}
					int out_buffsize = av_samples_get_buffer_size(&out_linesize, out_channels, out_samples, AV_SAMPLE_FMT_S16, 1);
					if (out_buffsize < 0)
					{
						continue;
					}
					pcmPrivateData_t extradata;
					extradata.uSampleRate = out_sample_rate;
					extradata.uNoOfChannels = av_get_channel_layout_nb_channels(out_channel_layout);
					extradata.uBitsPerSample = 16;
					extradata.bLittleEndian = 1;
					avOut.data       = output;
					avOut.len        = out_buffsize;
					avOut.pts        = currentAudioPts;
					avOut.extradata  = (unsigned char *)&extradata;
					avOut.extralen   = sizeof(extradata);
					avOut.frameRate  = 0;
					avOut.timeScale  = 0;
					avOut.width      = 0;
					avOut.height     = 0;
					avOut.type       = OUTPUT_TYPE_AUDIO;
					if (context->output->audio->Write(context, &avOut) < 0)
						ffmpeg_err("writing data to audio device failed\n");
					av_freep(&output);
				}
			}
			else if (audioTrack->have_aacheader == 1)
			{
				ffmpeg_printf(200, "write audio aac\n");
				avOut.data       = packet.data;
				avOut.len        = packet.size;
				avOut.pts        = currentAudioPts;
				avOut.extradata  = audioTrack->aacbuf;
				avOut.extralen   = audioTrack->aacbuflen;
				avOut.frameRate  = 0;
				avOut.timeScale  = 0;
				avOut.width      = 0;
				avOut.height     = 0;
				avOut.type       = OUTPUT_TYPE_AUDIO;
				if (context->output->audio->Write(context, &avOut) < 0)
				{
					ffmpeg_err("(aac) writing data to audio device failed\n");
				}
			}
			else
			{
				avOut.data       = packet_data;
				avOut.len        = packet_size;
				avOut.pts        = currentAudioPts;
				avOut.extradata  = NULL;
				avOut.extralen   = 0;
				avOut.frameRate  = 0;
				avOut.timeScale  = 0;
				avOut.width      = 0;
				avOut.height     = 0;
				avOut.type       = OUTPUT_TYPE_AUDIO;
				if (context->output->audio->Write(context, &avOut) < 0)
				{
					ffmpeg_err("writing data to audio device failed\n");
				}
			}
		}
		else if (subtitleTrack && (subtitleTrack->Id == pid))
		{
			float duration = 3.0;
			long long int Subtitlepts;
			ffmpeg_printf(100, "subtitleTrack->stream %p \n", subtitleTrack->stream);
			Subtitlepts = calcPts(subtitleTrack->stream, packet.pts);
#if (LIBAVFORMAT_VERSION_MAJOR == 57 && LIBAVFORMAT_VERSION_MINOR == 25)
			ffmpeg_printf(20, "Packet duration %lld\n", packet.duration);
#else
			ffmpeg_printf(20, "Packet duration %d\n", packet.duration);
#endif
			if (packet.duration != 0)
				duration = ((float)packet.duration) / 1000.0;
			else if (((AVStream *)subtitleTrack->stream)->codec->codec_id == AV_CODEC_ID_SSA)
			{
				/*Hellmaster1024 if the duration is not stored in packet.duration
				  we need to calculate it any other way, for SSA it is stored in
				  the Text line*/
				duration = getDurationFromSSALine(packet_data);
			}
			else
			{
				/* no clue yet */
			}
			/* konfetti: I've found cases where the duration from getDurationFromSSALine
			 * is zero (start end and are really the same in text). I think it make's
			 * no sense to pass those.
			 */
			if (duration > 0.0)
			{
				/* is there a decoder ? */
				if (((AVStream *) subtitleTrack->stream)->codec->codec)
				{
					AVSubtitle sub;
					int got_sub_ptr;
					if (avcodec_decode_subtitle2(((AVStream *) subtitleTrack->stream)->codec, &sub, &got_sub_ptr, &packet) < 0)
					{
						ffmpeg_err("error decoding subtitle\n");
					}
					else
					{
						unsigned int i;
						ffmpeg_printf(0, "format %d\n", sub.format);
						ffmpeg_printf(0, "start_display_time %d\n", sub.start_display_time);
						ffmpeg_printf(0, "end_display_time %d\n", sub.end_display_time);
						ffmpeg_printf(0, "num_rects %d\n", sub.num_rects);
						ffmpeg_printf(0, "pts %lld\n", sub.pts);
						for (i = 0; i < sub.num_rects; i++)
						{
							ffmpeg_printf(0, "x %d\n", sub.rects[i]->x);
							ffmpeg_printf(0, "y %d\n", sub.rects[i]->y);
							ffmpeg_printf(0, "w %d\n", sub.rects[i]->w);
							ffmpeg_printf(0, "h %d\n", sub.rects[i]->h);
							ffmpeg_printf(0, "nb_colors %d\n", sub.rects[i]->nb_colors);
							ffmpeg_printf(0, "type %d\n", sub.rects[i]->type);
							ffmpeg_printf(0, "text %s\n", sub.rects[i]->text);
							ffmpeg_printf(0, "ass %s\n", sub.rects[i]->ass);
							// pict ->AVPicture
						}
					}
				}
				else
				{
					if (((AVStream *)subtitleTrack->stream)->codec->codec_id == AV_CODEC_ID_SSA)
					{
						SubtitleData_t data;
						ffmpeg_printf(10, "videoPts %lld\n", currentVideoPts);
						data.data       = packet_data;
						data.len        = packet_size;
						data.extradata  = subtitleTrack->extraData;
						data.extralen   = subtitleTrack->extraSize;
						data.pts        = Subtitlepts;
						data.duration   = duration;
						context->container->assContainer->Command(context, CONTAINER_DATA, &data);
					}
					else
					{
						/* hopefully native text ;) */
						unsigned char *line = text_to_ass((char *)packet_data, Subtitlepts / 90, duration);
						ffmpeg_printf(50, "text line is %s\n", (char *)packet_data);
						ffmpeg_printf(50, "Sub line is %s\n", line);
						ffmpeg_printf(20, "videoPts %lld %f\n", currentVideoPts, currentVideoPts / 90000.0);
						SubtitleData_t data;
						data.data       = line;
						data.len        = strlen((char *)line);
						data.extradata  = (unsigned char *) DEFAULT_ASS_HEAD;
						data.extralen   = strlen(DEFAULT_ASS_HEAD);
						data.pts        = Subtitlepts;
						data.duration   = duration;
						context->container->assContainer->Command(context, CONTAINER_DATA, &data);
						free(line);
					}
				}
			} /* duration */
		}
		av_packet_unref(&packet);
	}/* while */
	if (context && context->playback && context->output && context->playback->abortRequested)
		context->output->Command(context, OUTPUT_CLEAR, NULL);            // Freeing the allocated buffer for softdecoding
	if (swr)
		swr_free(&swr);
	if (decoded_frame)
		av_frame_free(&decoded_frame);
	if (context->playback)
		context->playback->abortPlayback = 1;
	hasPlayThreadStarted = 0;
	ffmpeg_printf(10, "terminating\n");
}

/* **************************** */
/* Container part for ffmpeg    */
/* **************************** */

static int terminating = 0;
static int interrupt_cb(void *ctx)
{
	PlaybackHandler_t *p = (PlaybackHandler_t *)ctx;
	return p->abortPlayback | p->abortRequested;
}

int container_ffmpeg_update_tracks(Context_t *context, char *filename)
{
	if (terminating)
		return cERR_CONTAINER_FFMPEG_NO_ERROR;
	if (context->manager->video)
		context->manager->video->Command(context, MANAGER_INIT_UPDATE, NULL);
	if (context->manager->audio)
		context->manager->audio->Command(context, MANAGER_INIT_UPDATE, NULL);

	ffmpeg_printf(20, "dump format\n");
	av_dump_format(avContext, 0, filename, 0);
	ffmpeg_printf(1, "number streams %d\n", avContext->nb_streams);
	unsigned int n;
	for (n = 0; n < avContext->nb_streams; n++)
	{
		Track_t track;
		AVStream *stream = avContext->streams[n];
		char *encoding = Codec2Encoding(stream->codec);
		if (!stream->id)
			stream->id = n;
		if (encoding != NULL)
			ffmpeg_printf(1, "%d. encoding = %s\n", stream->id, encoding);
		/* some values in track are unset and therefor copyTrack segfaults.
		 * so set it by default to NULL!
		 */
		memset(&track, 0, sizeof(track));

		AVDictionaryEntry *lang;

		lang = av_dict_get(stream->metadata, "language", NULL, 0);
		track.Name = lang ? lang->value : "und";
		ffmpeg_printf(10, "Language %s\n", track.Name);
		track.Encoding = encoding;
		track.stream = stream;
		track.Id = stream->id;
		track.aacbuf = 0;
		track.have_aacheader = -1;
		if (stream->duration == AV_NOPTS_VALUE)
		{
			ffmpeg_printf(10, "Stream has no duration so we take the duration from context\n");
			track.duration = (double) avContext->duration / 1000.0;
		}
		else
		{
			track.duration = (double) stream->duration * av_q2d(stream->time_base) * 1000.0;
		}
		switch (stream->codec->codec_type)
		{
			case AVMEDIA_TYPE_VIDEO:
				ffmpeg_printf(10, "CODEC_TYPE_VIDEO %d\n", stream->codec->codec_type);
				track.type         = eTypeES;
				track.width        = stream->codec->width;
				track.height       = stream->codec->height;
				track.extraData    = stream->codec->extradata;
				track.extraSize    = stream->codec->extradata_size;
				track.frame_rate   = stream->r_frame_rate.num;
				double frame_rate  = av_q2d(stream->r_frame_rate); /* rational to double */
				ffmpeg_printf(10, "frame_rate = %f\n", frame_rate);
				track.frame_rate   = frame_rate * 1000.0;
				/* fixme: revise this */
				if (track.frame_rate < 23970)
					track.TimeScale = 1001;
				else
					track.TimeScale = 1000;
				ffmpeg_printf(10, "bit_rate = %d\n", (int)stream->codec->bit_rate);
				ffmpeg_printf(10, "flags = %d\n", stream->codec->flags);
				ffmpeg_printf(10, "frame_bits = %d\n", stream->codec->frame_bits);
				ffmpeg_printf(10, "time_base.den %d\n", stream->time_base.den);
				ffmpeg_printf(10, "time_base.num %d\n", stream->time_base.num);
				ffmpeg_printf(10, "frame_rate.num %d\n", stream->r_frame_rate.num);
				ffmpeg_printf(10, "frame_rate.den %d\n", stream->r_frame_rate.den);
				ffmpeg_printf(10, "frame_rate %d\n", track.frame_rate);
				ffmpeg_printf(10, "TimeScale %d\n", track.TimeScale);
				if (context->manager->video && context->manager->video->Command(context, MANAGER_ADD, &track) < 0)
				{
					/* konfetti: fixme: is this a reason to return with error? */
					ffmpeg_err("failed to add track %d\n", n);
				}
				break;
			case AVMEDIA_TYPE_AUDIO:
				ffmpeg_printf(10, "CODEC_TYPE_AUDIO %d\n", stream->codec->codec_type);
				track.type = eTypeES;
				if (!strncmp(encoding, "A_AAC", 5))
				{
					/* extradata
					13 10 56 e5 9d 48 00 (anderen cops)
					        object_type: 00010 2 = LC
					        sample_rate: 011 0 6 = 24000
					        chan_config: 0010 2 = Stereo
					        000 0
					        1010110 111 = 0x2b7
					        00101 = SBR
					        1
					        0011 = 48000
					        101 01001000 = 0x548
					        ps = 0
					        0000000
					*/
					unsigned int extradata_size = stream->codec->extradata_size;
					unsigned int object_type = 2; // LC
					unsigned int sample_index = aac_get_sample_rate_index(stream->codec->sample_rate);
					unsigned int chan_config = stream->codec->channels;
					if (extradata_size >= 2)
					{
						object_type = stream->codec->extradata[0] >> 3;
						sample_index = ((stream->codec->extradata[0] & 0x7) << 1)
							       + (stream->codec->extradata[1] >> 7);
						chan_config = (stream->codec->extradata[1] >> 3) && 0xf;
					}
					ffmpeg_printf(10, "aac extradata_size %d\n", extradata_size);
					ffmpeg_printf(10, "aac object_type %d\n", object_type);
					ffmpeg_printf(10, "aac sample_index %d\n", sample_index);
					ffmpeg_printf(10, "aac chan_config %d\n", chan_config);
					if ((extradata_size <= 1) || (object_type == 1))
					{
						ffmpeg_printf(10, "use resampling for AAC\n");
						encoding = "A_IPCM";
						track.Encoding = "A_IPCM";
					}
					else
					{
						ffmpeg_printf(10, "Create AAC ExtraData\n");
						Hexdump(stream->codec->extradata, extradata_size);
						object_type -= 1; // Cause of ADTS
						track.aacbuflen = AAC_HEADER_LENGTH;
						track.aacbuf    = malloc(8);
						track.aacbuf[0] = 0xFF;
						track.aacbuf[1] = 0xF1;
						track.aacbuf[2] = ((object_type & 0x03) << 6)  | (sample_index << 2) | ((chan_config >> 2) & 0x01);
						track.aacbuf[3] = (chan_config & 0x03) << 6;
						track.aacbuf[4] = 0x00;
						track.aacbuf[5] = 0x1F;
						track.aacbuf[6] = 0xFC;
						printf("AAC_HEADER -> ");
						Hexdump(track.aacbuf, 7);
						track.have_aacheader = 1;
					}
				}
				if (!strncmp(encoding, "A_IPCM", 6))
				{
					track.inject_as_pcm = 1;
					ffmpeg_printf(10, " Handle inject_as_pcm = %d\n", track.inject_as_pcm);
					AVCodec *codec = avcodec_find_decoder(stream->codec->codec_id);
					if (codec != NULL && !avcodec_open2(stream->codec, codec, NULL))
						printf("AVCODEC__INIT__SUCCESS\n");
					else
						printf("AVCODEC__INIT__FAILED\n");
				}
				if (context->manager->audio)
				{
					if (context->manager->audio->Command(context, MANAGER_ADD, &track) < 0)
					{
						/* konfetti: fixme: is this a reason to return with error? */
						ffmpeg_err("failed to add track %d\n", n);
					}
				}
				break;
			case AVMEDIA_TYPE_SUBTITLE:
				ffmpeg_printf(10, "CODEC_TYPE_SUBTITLE %d\n", stream->codec->codec_type);
				track.width     = -1; /* will be filled online from videotrack */
				track.height    = -1; /* will be filled online from videotrack */
				track.extraData = stream->codec->extradata;
				track.extraSize = stream->codec->extradata_size;
				ffmpeg_printf(1, "subtitle codec %d\n", stream->codec->codec_id);
				ffmpeg_printf(1, "subtitle width %d\n", stream->codec->width);
				ffmpeg_printf(1, "subtitle height %d\n", stream->codec->height);
				ffmpeg_printf(1, "subtitle stream %p\n", stream);
				ffmpeg_printf(10, "FOUND SUBTITLE %s\n", track.Name);
				if (context->manager->subtitle)
				{
					if (!stream->codec->codec)
					{
						stream->codec->codec = avcodec_find_decoder(stream->codec->codec_id);
						if (!stream->codec->codec)
							ffmpeg_err("avcodec_find_decoder failed for subtitle track %d\n", n);
						else if (avcodec_open2(stream->codec, stream->codec->codec, NULL))
						{
							ffmpeg_err("avcodec_open2 failed for subtitle track %d\n", n);
							stream->codec->codec = NULL;
						}
					}
					if (context->manager->subtitle->Command(context, MANAGER_ADD, &track) < 0)
					{
						/* konfetti: fixme: is this a reason to return with error? */
						ffmpeg_err("failed to add subtitle track %d\n", n);
					}
				}
				break;
			case AVMEDIA_TYPE_UNKNOWN:
			case AVMEDIA_TYPE_DATA:
			case AVMEDIA_TYPE_ATTACHMENT:
			case AVMEDIA_TYPE_NB:
			default:
				ffmpeg_err("not handled or unknown codec_type %d\n", stream->codec->codec_type);
				break;
		}
	} /* for */
	return cERR_CONTAINER_FFMPEG_NO_ERROR;
}

static int container_ffmpeg_init(Context_t *context, char *filename)
{
	int ret = 0;
	unsigned int n = 1;
	int no_probe = 0;
	ffmpeg_printf(10, ">\n");
	if (filename == NULL)
	{
		ffmpeg_err("filename NULL\n");
		return cERR_CONTAINER_FFMPEG_NULL;
	}
	if (context == NULL)
	{
		ffmpeg_err("context NULL\n");
		return cERR_CONTAINER_FFMPEG_NULL;
	}
	ffmpeg_printf(10, "filename %s\n", filename);
	if (isContainerRunning)
	{
		ffmpeg_err("ups already running?\n");
		return cERR_CONTAINER_FFMPEG_RUNNING;
	}

	if (strstr(filename, ":31339/id=") || strstr(filename, ":8001/"))
		no_probe = 1;

	isContainerRunning = 0;
	/* initialize ffmpeg */
	av_register_all();
	avformat_network_init();
	//av_log_set_level( AV_LOG_DEBUG );
	context->playback->abortRequested = 0;
	context->playback->abortPlayback = 0;
again:
	avContext = avformat_alloc_context();
	if (!avContext)
	{
		ffmpeg_err("avformat_alloc_context failed\n");
		ret = cERR_CONTAINER_FFMPEG_OPEN;
		goto fail_alloc;
	}
	avContext->interrupt_callback.callback = interrupt_cb;
	avContext->interrupt_callback.opaque = context->playback;
	avContext->flags |= AVFMT_FLAG_GENPTS;
	if (context->playback->isHttp && !no_probe)
		avContext->flags |= AVFMT_FLAG_NONBLOCK | AVIO_FLAG_NONBLOCK | AVFMT_NO_BYTE_SEEK;
	if (no_probe || (context->playback->isHttp && n))
#if (LIBAVFORMAT_VERSION_MAJOR == 57 && LIBAVFORMAT_VERSION_MINOR == 25)
		if (no_probe)
			avContext->max_analyze_duration = 1;
		else
			avContext->max_analyze_duration = 1 * AV_TIME_BASE;
	else
		avContext->max_analyze_duration = 0;
#else
		if (no_probe)
			avContext->max_analyze_duration2 = 1;
		else
			avContext->max_analyze_duration2 = 1 * AV_TIME_BASE;
	else
		avContext->max_analyze_duration2 = 0;
#endif
	ret = avformat_open_input(&avContext, filename, NULL, NULL);
	if (ret < 0)
	{
		char error[512];
		ffmpeg_err("avformat_open_input failed %d (%s)\n", ret, filename);
		av_strerror(ret, error, sizeof error);
		ffmpeg_err("Cause: %s\n", error);
		ret = cERR_CONTAINER_FFMPEG_OPEN;
		goto fail;
	}
	avContext->iformat->flags |= AVFMT_SEEK_TO_PTS;
	ffmpeg_printf(20, "Find_streaminfo\n");
	ret = avformat_find_stream_info(avContext, NULL);
	if (!no_probe)
	{
		if (ret < 0)
		{
			ffmpeg_err("Error avformat_find_stream_info\n");
			if (n)
			{
				n = 0;
				avformat_close_input(&avContext);
				ffmpeg_err("Try again with default probe size\n");
				goto again;
			}
#ifdef this_is_ok
			/* crow reports that sometimes this returns an error
			* but the file is played back well. so remove this
			* until other works are done and we can prove this.
			*/
			ret = cERR_CONTAINER_FFMPEG_STREAM;
			goto fail;
#endif
		}
	}
	ret = cERR_CONTAINER_FFMPEG_STREAM;
	for (n = 0; n < avContext->nb_streams; n++)
	{
		AVStream *stream = avContext->streams[n];
		switch (stream->codec->codec_type)
		{
			case AVMEDIA_TYPE_AUDIO:
			case AVMEDIA_TYPE_VIDEO:
				ret = 0;
			default:
				break;
		}
	}
	if (ret < 0)
	{
		ffmpeg_err("Not found video or audio stream\n");
		goto fail;
	}
	terminating = 0;
	ret = container_ffmpeg_update_tracks(context, filename);
	isContainerRunning = 1;
	return ret;
fail:
	avformat_close_input(&avContext);
fail_alloc:
	avformat_network_deinit();
	return ret;
}

static int container_ffmpeg_play(Context_t *context)
{
	int error;
	int ret = 0;
	pthread_attr_t attr;

	ffmpeg_printf(10, "\n");
	if (context && context->playback && context->playback->isPlaying)
	{
		ffmpeg_printf(10, "is Playing\n");
	}
	else
	{
		ffmpeg_printf(10, "is NOT Playing\n");
	}
	if (hasPlayThreadStarted == 0)
	{
		pthread_attr_init(&attr);
		pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
		if ((error = pthread_create(&PlayThread, &attr, (void *)&FFMPEGThread, context)) != 0)
		{
			ffmpeg_printf(10, "Error creating thread, error:%d:%s\n", error, strerror(error));
			ret = cERR_CONTAINER_FFMPEG_ERR;
		}
		else
		{
			ffmpeg_printf(10, "Created thread\n");
		}
	}
	else
	{
		ffmpeg_printf(10, "A thread already exists!\n");
		ret = cERR_CONTAINER_FFMPEG_ERR;
	}
	ffmpeg_printf(10, "exiting with value %d\n", ret);
	return ret;
}

static int container_ffmpeg_stop(Context_t *context)
{
	int ret = cERR_CONTAINER_FFMPEG_NO_ERROR;
	int wait_time = 20;

	ffmpeg_printf(10, "\n");
	if (!isContainerRunning)
	{
		ffmpeg_err("Container not running\n");
		return cERR_CONTAINER_FFMPEG_ERR;
	}
	if (context->playback)
		context->playback->abortRequested = 1;
	while ((hasPlayThreadStarted != 0) && (--wait_time) > 0)
	{
		ffmpeg_printf(10, "Waiting for ffmpeg thread to terminate itself, will try another %d times\n", wait_time);
		usleep(100000);
	}
	if (wait_time == 0)
	{
		ffmpeg_err("Timeout waiting for thread!\n");
		ret = cERR_CONTAINER_FFMPEG_ERR;
		usleep(100000);
	}
	terminating = 1;
	if (avContext)
	{
		avformat_close_input(&avContext);
	}
	isContainerRunning = 0;
	avformat_network_deinit();
	ffmpeg_printf(10, "ret %d\n", ret);
	return ret;
}

static int container_ffmpeg_seek(float sec, int absolute)
{
#if 0
	if (absolute)
		seek_sec_abs = sec, seek_sec_rel = 0.0;
	else
		seek_sec_abs = -1.0, seek_sec_rel = sec;
#else
	seek_sec_rel = sec;
#endif
	return cERR_CONTAINER_FFMPEG_NO_ERROR;
}

static int container_ffmpeg_get_length(Context_t *context, double *length)
{
	ffmpeg_printf(50, "\n");
	Track_t *videoTrack = NULL;
	Track_t *audioTrack = NULL;
	Track_t *subtitleTrack = NULL;
	Track_t *current = NULL;
	if (length == NULL)
	{
		ffmpeg_err("null pointer passed\n");
		return cERR_CONTAINER_FFMPEG_ERR;
	}
	context->manager->video->Command(context, MANAGER_GET_TRACK, &videoTrack);
	context->manager->audio->Command(context, MANAGER_GET_TRACK, &audioTrack);
	context->manager->subtitle->Command(context, MANAGER_GET_TRACK, &subtitleTrack);
	if (videoTrack != NULL)
		current = videoTrack;
	else if (audioTrack != NULL)
		current = audioTrack;
	else if (subtitleTrack != NULL)
		current = subtitleTrack;
	*length = 0.0;
	if (current != NULL)
	{
		if (current->duration == 0)
			return cERR_CONTAINER_FFMPEG_ERR;
		else
			*length = (current->duration / 1000.0);
	}
	else
	{
		if (avContext != NULL)
		{
			*length = (avContext->duration / 1000.0);
		}
		else
		{
			ffmpeg_err("no Track not context ->no problem :D\n");
			return cERR_CONTAINER_FFMPEG_ERR;
		}
	}
	return cERR_CONTAINER_FFMPEG_NO_ERROR;
}

static int container_ffmpeg_switch_audio(Context_t *context, int *arg)
{
	ffmpeg_printf(10, "track %d\n", *arg);
	/* Hellmaster1024: nothing to do here!*/
	float sec = -5.0;
	context->playback->Command(context, PLAYBACK_SEEK, (void *)&sec);
	return cERR_CONTAINER_FFMPEG_NO_ERROR;
}

static int container_ffmpeg_switch_subtitle(Context_t *context __attribute__((unused)), int *arg __attribute__((unused)))
{
	/* Hellmaster1024: nothing to do here!*/
	return cERR_CONTAINER_FFMPEG_NO_ERROR;
}

/* konfetti comment: I dont like the mechanism of overwriting
 * the pointer in infostring. This lead in most cases to
 * user errors, like it is in the current version (libeplayer2 <-->e2->servicemp3.cpp)
 * From e2 there is passed a tag=strdup here and we overwrite this
 * strdupped tag. This lead to dangling pointers which are never freed!
 * I do not free the string here because this is the wrong way. The mechanism
 * should be changed, or e2 should pass it in a different way...
 */
static int container_ffmpeg_get_info(Context_t *context, char **infoString)
{
	Track_t *videoTrack = NULL;
	Track_t *audioTrack = NULL;
	char     *meta = NULL;
	ffmpeg_printf(20, ">\n");
	if (avContext != NULL)
	{
		if ((infoString == NULL) || (*infoString == NULL))
		{
			ffmpeg_err("infostring NULL\n");
			return cERR_CONTAINER_FFMPEG_ERR;
		}
		ffmpeg_printf(20, "%s\n", *infoString);
		context->manager->video->Command(context, MANAGER_GET_TRACK, &videoTrack);
		context->manager->audio->Command(context, MANAGER_GET_TRACK, &audioTrack);
		if ((meta = searchMeta(avContext->metadata, *infoString)) == NULL)
		{
			if (audioTrack != NULL)
			{
				AVStream *stream = audioTrack->stream;
				meta = searchMeta(stream->metadata, *infoString);
			}
			if ((meta == NULL) && (videoTrack != NULL))
			{
				AVStream *stream = videoTrack->stream;
				meta = searchMeta(stream->metadata, *infoString);
			}
		}
		if (meta != NULL)
		{
			*infoString = strdup(meta);
		}
		else
		{
			ffmpeg_printf(1, "no metadata found for \"%s\"\n", *infoString);
			*infoString = strdup("not found");
		}
	}
	else
	{
		ffmpeg_err("avContext NULL\n");
		return cERR_CONTAINER_FFMPEG_ERR;
	}
	return cERR_CONTAINER_FFMPEG_NO_ERROR;
}

static int Command(Context_t *context, ContainerCmd_t command, void *argument)
{
	int ret = cERR_CONTAINER_FFMPEG_NO_ERROR;
	char *FILENAME = NULL;
	double length = 0;

	ffmpeg_printf(50, "Command %d\n", command);
	if (command != CONTAINER_INIT && !avContext)
		return cERR_CONTAINER_FFMPEG_ERR;
	if (command == CONTAINER_INIT && avContext)
		return cERR_CONTAINER_FFMPEG_ERR;
	switch (command)
	{
		case CONTAINER_INIT:
			FILENAME = (char *)argument;
			ret = container_ffmpeg_init(context, FILENAME);
			break;
		case CONTAINER_PLAY:
			ret = container_ffmpeg_play(context);
			break;
		case CONTAINER_STOP:
			ret = container_ffmpeg_stop(context);
			break;
		case CONTAINER_SEEK:
			ret = container_ffmpeg_seek((float) * ((float *)argument), 0);
			break;
#if 0
		case CONTAINER_SEEK_ABS:
			ret = container_ffmpeg_seek((float) * ((float *)argument), -1);
			break;
#endif
		case CONTAINER_LENGTH:
			ret = container_ffmpeg_get_length(context, &length);
			*((double *)argument) = (double)length;
			break;
		case CONTAINER_SWITCH_AUDIO:
			ret = container_ffmpeg_switch_audio(context, (int *) argument);
			break;
		case CONTAINER_SWITCH_SUBTITLE:
			ret = container_ffmpeg_switch_subtitle(context, (int *) argument);
			break;
		case CONTAINER_INFO:
			ret = container_ffmpeg_get_info(context, (char **)argument);
			break;
		case CONTAINER_STATUS:
			*((int *)argument) = hasPlayThreadStarted;
			break;
		default:
			ffmpeg_err("ContainerCmd %d not supported!\n", command);
			ret = cERR_CONTAINER_FFMPEG_ERR;
			break;
	}
	ffmpeg_printf(50, "exiting with value %d\n", ret);
	return ret;
}

static char *FFMPEG_Capabilities[] = {"avi", "mkv", "mp4", "ts", "mov", "flv", "flac", "mp3", "mpg", "m2ts", "vob", "wmv", "wma", "asf", "mp2", "m4v", "m4a", "divx", "dat", "mpeg", "trp", "mts", "vdr", "ogg", "wav", "wtv", "asx", "mvi", "png", "jpg", "m3u8", "ogm", "3gp", NULL };

Container_t FFMPEGContainer =
{
	"FFMPEG",
	&Command,
	FFMPEG_Capabilities
};
