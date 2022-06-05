/*
 * eeprom.c
 *
 * (c) 2009 Dagobert@teamducktales
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

/*
 * Description:
 *
 * Startup of little eeprom read/write utility. the eeprom slots
 * are based on the very first original fw, so maybe they have
 * changed ...
 *
 * _ATTENTION_: Many thinks are untested in this module. Use on
 * your own risk
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <linux/types.h>
#include <linux/init.h>
#include <stdio.h>
#include <stdlib.h>
#include <linux/fs.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#define cMaxDetails	16

#define cTypeUnused	0
#define cTypeString	1
#define cTypeValue	2
#define cTypeByte	3

/* FIXME: Eigentlich müßte ich das anders machen, es
 * gibt max 16 byte speicher insgesamt und die details
 * definieren nur virtuell was drinne ist und zwar je
 * nach größe ergibt sich die anzahl slot details.
 * Derzeit ist meine definition von cTypeUndefined
 * irreführend, denn wenn der erste 16 Byte hat sind zwar
 * alle anderen als undefined definiert sind aber durch den
 * ersten belegt.
 */

typedef struct
{
	char	*name;
	int	first_byte;
	int	number_bytes;

	int	type;

	unsigned char *buffer;
} slot_detail_t;

typedef struct
{
	unsigned char 	slot;
	unsigned int 	i2c_bus;
	unsigned char 	i2c_regs;

	slot_detail_t 	details[cMaxDetails];

} slot_t;

#define cMaxSlots 42

slot_t ufs922_slots[cMaxSlots] =
{
	/* i2c addr = 0x50 */
	{
		0x00, 1, 0x50,
		"Magic  ", 0, 8, cTypeString, NULL,
		"Product", 8, 8, cTypeByte, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x10, 1, 0x50,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x20, 1, 0x50,
		"BootType         ", 0, 1, cTypeValue, NULL,
		"DeepStandby      ", 1, 1, cTypeValue, NULL,
		"RemoteAddr       ", 2, 1, cTypeValue, NULL,
		"FirstInstallation", 3, 1, cTypeValue, NULL,
		"WakeupMode       ", 4, 1, cTypeValue, NULL,
		"LogOption        ", 5, 1, cTypeValue, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x30, 1, 0x50,
		"VideoOutput     ", 0, 1, cTypeValue, NULL,
		"HDMIFormat      ", 1, 1, cTypeValue, NULL,
		"Show_4_3        ", 2, 1, cTypeValue, NULL,
		"AudioHDMI       ", 3, 1, cTypeValue, NULL,
		"TVAspect        ", 4, 1, cTypeValue, NULL,
		"Picture4_3      ", 5, 1, cTypeValue, NULL,
		"Picture16_9     ", 6, 1, cTypeValue, NULL,
		"ScartTV         ", 7, 1, cTypeValue, NULL,
		"ScartVCR        ", 8, 1, cTypeValue, NULL,
		"AudioDolby      ", 9, 1, cTypeValue, NULL,
		"TVSystem        ", 10, 1, cTypeValue, NULL,
		"AudioLanguage   ", 11, 1, cTypeValue, NULL,
		"SubtitleLanguage", 12, 1, cTypeValue, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x40, 1, 0x50,
		"Tuner2Type        ", 0, 1, cTypeValue, NULL,
		"Tuner2SignalConfig", 1, 1, cTypeValue, NULL,
		"Tuner1Connection  ", 2, 1, cTypeValue, NULL,
		"Tuner2Connection  ", 3, 1, cTypeValue, NULL,
		"OneCableType      ", 4, 1, cTypeValue, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x50, 1, 0x50,
		"LocalTimeOffset       ", 0, 4, cTypeValue, NULL,
		"WakeupTimer           ", 4, 4, cTypeValue, NULL,
		"TimeSetupChannelNumber", 8, 4, cTypeValue, NULL,
		"SummerTime            ", 12, 1, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x60, 1, 0x50,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x70, 1, 0x50,
		"ForceDecrypt          ", 0, 1, cTypeValue, NULL,
		"ForceDecryptMode      ", 1, 1, cTypeValue, NULL,
		"AlphacryptMultiDecrypt", 2, 1, cTypeValue, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x80, 1, 0x50,
		"ChannelCRC      ", 0, 4, cTypeByte, NULL,
		"SatelliteCRC    ", 4, 4, cTypeByte, NULL,
		"ChannelCRC_HDD  ", 8, 4, cTypeByte, NULL,
		"SatelliteCRC_HDD", 12, 4, cTypeByte, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x90, 1, 0x50,
		"LastAudioVolume", 0, 1, cTypeValue, NULL,
		"LastServiceType", 1, 1, cTypeValue, NULL,
		"LastTVNumber   ", 2, 4, cTypeValue, NULL,
		"LastRadioNumber", 6, 4, cTypeValue, NULL,
		"Audio_Mute     ", 10, 1, cTypeValue, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xa0, 1, 0x50,
		"lockMainMenu          ", 0, 1, cTypeValue, NULL,
		"lockReceiver          ", 1, 1, cTypeValue, NULL,
		"SleepTimer            ", 2, 1, cTypeValue, NULL,
		"ChannelBannerDuration ", 3, 1, cTypeValue, NULL,
		"PlaybackBannerDuration", 4, 1, cTypeValue, NULL,
		"DisplayVolume         ", 5, 1, cTypeValue, NULL,
		"FrontDisplayBrightness", 6, 1, cTypeValue, NULL,
		"EPGGrabbing           ", 7, 1, cTypeValue, NULL,
		"EPGStartView          ", 8, 1, cTypeValue, NULL,
		"AutomaticTimeshift    ", 9, 1, cTypeValue, NULL,
		"FunctionalRange       ", 10, 1, cTypeValue, NULL,
		"AudioDelay            ", 11, 2, cTypeValue, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xb0, 1, 0x50,
		"PreRecordtimes ", 0, 2, cTypeValue, NULL,
		"PostRecordtime ", 2, 2, cTypeValue, NULL,
		"PinCode        ", 4, 4, cTypeByte, NULL,
		"EPGGrabbingTime", 8, 4, cTypeValue, NULL,
		"FreeAccessFrom ", 12, 4, cTypeValue, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xc0, 1, 0x50,
		"FreeAccessUntil      ", 0, 4, cTypeValue, NULL,
		"DefaultRecordDuration", 4, 4, cTypeValue, NULL,
		"FanControl           ", 8, 1, cTypeByte, NULL,
		"AutomaticSWDownload  ", 9, 1, cTypeValue, NULL,
		"TimeshiftBufferSize  ", 12, 4, cTypeValue, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xd0, 1, 0x50,
		"MyLongitude", 0, 4, cTypeValue, NULL,
		"Latitude   ", 4, 4, cTypeValue, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xe0, 1, 0x50,
		"Tuner1_SCR          ", 0, 4, cTypeValue, NULL,
		"Tuner2_SCR          ", 4, 4, cTypeValue, NULL,
		"Tuner1_SCR_Frequency", 8, 4, cTypeValue, NULL,
		"Tuner2_SCR_Frequency", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xf0, 1, 0x50,
		"Use_OneCable  ", 0, 4, cTypeValue, NULL,
		"MDU           ", 4, 4, cTypeValue, NULL,
		"Tuner1_PinCode", 8, 4, cTypeByte, NULL,
		"Tuner2_PinCode", 12, 4, cTypeByte, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	/* i2c addr = 0x51 */
	{
		0x00, 1, 0x51,
		"System_Lanauge", 0, 4, cTypeValue, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x10, 1, 0x51,
		"ChannelListYear ", 0, 2, cTypeValue, NULL,
		"ChannelListMonth", 2, 1, cTypeValue, NULL,
		"ChannelListDay  ", 3, 1, cTypeValue, NULL,
		"FirmwareYear    ", 4, 2, cTypeValue, NULL,
		"FirmwareMonth   ", 6, 1, cTypeValue, NULL,
		"FirmwareDay     ", 7, 1, cTypeValue, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x20, 1, 0x51,
		"IpAddress ", 0, 4, cTypeByte, NULL,
		"SubNet    ", 4, 4, cTypeByte, NULL,
		"Gateway   ", 8, 4, cTypeByte, NULL,
		"EEProm_DNS", 12, 4, cTypeByte, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x30, 1, 0x51,
		"DHCP     ", 0, 1, cTypeByte, NULL,
		"TimeMode ", 1, 1, cTypeByte, NULL,
		"SerialKbd", 2, 1, cTypeByte, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x40, 1, 0x51,
		"Playback_Shuffle ", 0, 1, cTypeByte, NULL,
		"Playback_Repeat  ", 1, 1, cTypeByte, NULL,
		"Playback_Duration", 2, 1, cTypeByte, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x50, 1, 0x51,
		"FTP     ", 0, 1, cTypeByte, NULL,
		"4G_Limit", 1, 1, cTypeByte, NULL,
		"UPnP    ", 2, 1, cTypeByte, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x60, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x70, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x80, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x90, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xa0, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xb0, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xc0, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xd0, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0xe0, 1, 0x51,
		"Empty01", 0, 16, cTypeUnused, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	/* i2c addr = 0x52 unused */


	/* i2c addr = 0x53 */
	{
		0xf0, 1, 0x53,
		"TestFPGA         ", 0, 1, cTypeByte, NULL,
		"TestFPGAMode     ", 1, 1, cTypeByte, NULL,
		"ChannelChangeMode", 2, 1, cTypeByte, NULL,
		"ConaxParingMode  ", 3, 1, cTypeByte, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},

	/* i2c addr = 0x54 - 56 unused */

	/* i2c addr = 0x57 */
	{
		0x00, 1, 0x57,
		"UpdateFlag", 0, 1, cTypeByte, NULL,
		"Empty02", 0, 16, cTypeUnused, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x10, 1, 0x57,
		"UpdateUnit1UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit1FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit1DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit1CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x20, 1, 0x57,
		"UpdateUnit2UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit2FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit2DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit2CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x30, 1, 0x57,
		"UpdateUnit3UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit3FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit3DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit3CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x40, 1, 0x57,
		"UpdateUnit4UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit4FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit4DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit4CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x50, 1, 0x57,
		"UpdateUnit5UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit5FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit5DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit5CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x60, 1, 0x57,
		"UpdateUnit6UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit6FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit6DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit6CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x70, 1, 0x57,
		"UpdateUnit7UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit7FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit7DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit7CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x80, 1, 0x57,
		"UpdateUnit8UpdateFlag ", 0, 1, cTypeByte, NULL,
		"UpdateUnit8FlashOffset", 4, 4, cTypeByte, NULL,
		"UpdateUnit8DataLength ", 8, 4, cTypeValue, NULL,
		"UpdateUnit8CRC        ", 12, 4, cTypeValue, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},
	{
		0x90, 1, 0x57,
		"SWPackVersion ", 0, 4, cTypeString, NULL,
		"ChannelDeltaVersion", 4, 4, cTypeString, NULL,
		"Empty03", 0, 16, cTypeUnused, NULL,
		"Empty04", 0, 16, cTypeUnused, NULL,
		"Empty05", 0, 16, cTypeUnused, NULL,
		"Empty06", 0, 16, cTypeUnused, NULL,
		"Empty07", 0, 16, cTypeUnused, NULL,
		"Empty08", 0, 16, cTypeUnused, NULL,
		"Empty09", 0, 16, cTypeUnused, NULL,
		"Empty10", 0, 16, cTypeUnused, NULL,
		"Empty11", 0, 16, cTypeUnused, NULL,
		"Empty12", 0, 16, cTypeUnused, NULL,
		"Empty13", 0, 16, cTypeUnused, NULL,
		"Empty14", 0, 16, cTypeUnused, NULL,
		"Empty15", 0, 16, cTypeUnused, NULL,
		"Empty16", 0, 16, cTypeUnused, NULL,
	},



};

/*
 * I2C Message - used for pure i2c transaction, also from /dev interface
 */
struct i2c_msg
{
	unsigned short addr;		/* slave address			*/
	unsigned short flags;
	unsigned short len;		/* msg length				*/
	unsigned char  *buf;		/* pointer to msg data			*/
};

/* This is the structure as used in the I2C_RDWR ioctl call */
struct i2c_rdwr_ioctl_data
{
	struct i2c_msg *msgs;	/* pointers to i2c_msgs */
	unsigned int nmsgs;			/* number of i2c_msgs */
};

#define I2C_SLAVE	0x0703	/* Change slave address			*/
/* Attn.: Slave address is 7 or 10 bits */

#define I2C_SLAVE_FORCE	0x0706	/* Change slave address			*/
#define I2C_RDWR	0x0707	/* Combined R/W transfer (one stop only)*/

int i2c_slave_force(int fd, char addr, char c1, char c2)
{
	char  buf[256];

	if (ioctl(fd, I2C_SLAVE_FORCE, addr) != 0)
	{
		printf("i2c failed 1\n");
		return -1;
	}

	buf[0] = c1;
	buf[1] = c2;
	if (write(fd, buf, 2) != 2)
		return -2;

	return 0;
}

int i2c_slave_force_var(int fd, char addr, char *buffer, int len)
{
	if (ioctl(fd, I2C_SLAVE_FORCE, addr) != 0)
	{
		printf("i2c failed 1\n");
		return -1;
	}

//printf("buffer 0x%x\n", buffer[0]);
	if (write(fd, buffer, len) != len)
		return -2;

	return 0;
}

int i2c_readreg(int fd_i2c, char addr, char *buffer, int len)
{
	struct 	i2c_rdwr_ioctl_data i2c_rdwr;
	int	err;

	/* */
	i2c_rdwr.nmsgs = 1;
	i2c_rdwr.msgs = malloc(2 * 32);
	i2c_rdwr.msgs[0].addr = addr;
	i2c_rdwr.msgs[0].flags = 1;
	i2c_rdwr.msgs[0].len = len;
	i2c_rdwr.msgs[0].buf = malloc(len);

	memcpy(i2c_rdwr.msgs[0].buf, buffer, len);

	if ((err = ioctl(fd_i2c, I2C_RDWR, &i2c_rdwr)) < 0)
	{
		printf("i2c_readreg failed %d %d\n", err, errno);
		printf("%s\n", strerror(errno));
		free(i2c_rdwr.msgs[0].buf);
		free(i2c_rdwr.msgs);

		return -1;
	}

	memcpy(buffer, i2c_rdwr.msgs[0].buf, len);

	free(i2c_rdwr.msgs[0].buf);
	free(i2c_rdwr.msgs);

	return 0;
}

int main(int argc, char *argv[])
{
	int fd_i2c;
	int vLoopAddr, vLoopSlot, vLoop;

//#define dump_it
#ifdef dump_it
	fd_i2c = open("/dev/i2c-1", O_RDWR);

	for (vLoopAddr = 0x50; vLoopAddr <= 0x57; vLoopAddr++)
	{
		for (vLoopSlot = 0x0; vLoopSlot <= 0xf; vLoopSlot++)
		{
			unsigned char reg = vLoopSlot * 0x10;
			unsigned char buffer[16] =
			{0x18, 0x74, 0x88, 0x7b, 0x94, 0x77, 0xb4, 0x0, 0x2c, 0x3a, 0xb4, 0x0, 0x1, 0x0, 0x0, 0x0};

			i2c_slave_force_var(fd_i2c, vLoopAddr, &reg, 1);

			i2c_readreg(fd_i2c, vLoopAddr, buffer, 16);

			printf("addr = 0x%02x, reg = 0x%02x  ", vLoopAddr, reg);
			for (vLoop = 0; vLoop < 16; vLoop++)
				printf("0x%02x ", buffer[vLoop]);

			printf("\n");

		}

	}
#else
	for (vLoopSlot = 0; vLoopSlot < cMaxSlots; vLoopSlot++)
	{
		char device[256];

		sprintf(device, "/dev/i2c-%d", ufs922_slots[vLoopSlot].i2c_bus);

		fd_i2c = open(device, O_RDWR);

		if (fd_i2c < 0)
		{
			printf("error opening %s \n", device);
			return 1;
		}


		unsigned char buffer[16];

		i2c_slave_force_var(fd_i2c, ufs922_slots[vLoopSlot].i2c_regs, &ufs922_slots[vLoopSlot].slot, 1);

		i2c_readreg(fd_i2c, ufs922_slots[vLoopSlot].i2c_regs, buffer, 16);

		for (vLoop = 0; vLoop < cMaxDetails; vLoop++)
		{
			if (ufs922_slots[vLoopSlot].details[vLoop].type == cTypeString)
			{
				ufs922_slots[vLoopSlot].details[vLoop].buffer = malloc(ufs922_slots[vLoopSlot].details[vLoop].number_bytes + 1);

				memcpy(ufs922_slots[vLoopSlot].details[vLoop].buffer,
				       buffer + ufs922_slots[vLoopSlot].details[vLoop].first_byte,
				       ufs922_slots[vLoopSlot].details[vLoop].number_bytes);

				ufs922_slots[vLoopSlot].details[vLoop].buffer[ufs922_slots[vLoopSlot].details[vLoop].number_bytes] = '\0';

				printf("Name = %s [%d:%d] value = %s\n",
				       ufs922_slots[vLoopSlot].details[vLoop].name,
				       ufs922_slots[vLoopSlot].details[vLoop].first_byte,
				       ufs922_slots[vLoopSlot].details[vLoop].number_bytes,
				       ufs922_slots[vLoopSlot].details[vLoop].buffer);
			}
			else if (ufs922_slots[vLoopSlot].details[vLoop].type == cTypeValue)
			{
				unsigned long value;
				int valueLoop;

				ufs922_slots[vLoopSlot].details[vLoop].buffer = malloc(ufs922_slots[vLoopSlot].details[vLoop].number_bytes);

				memcpy(ufs922_slots[vLoopSlot].details[vLoop].buffer,
				       buffer + ufs922_slots[vLoopSlot].details[vLoop].first_byte,
				       ufs922_slots[vLoopSlot].details[vLoop].number_bytes);

				value = 0;

				for (valueLoop = 0; valueLoop < ufs922_slots[vLoopSlot].details[vLoop].number_bytes; valueLoop++)
				{
					value |= ufs922_slots[vLoopSlot].details[vLoop].buffer[valueLoop] <<
						 ((ufs922_slots[vLoopSlot].details[vLoop].number_bytes - valueLoop - 1) * 8);
					/*
					printf("value = %d\n", value);
					printf("buffer = 0x%x shift = %d\n", ufs922_slots[vLoopSlot].details[vLoop].buffer[valueLoop],((ufs922_slots[vLoopSlot].details[vLoop].number_bytes - valueLoop - 1) * 8));
					*/
				}

				printf("Name = %s [%d:%d] value = %d\n",
				       ufs922_slots[vLoopSlot].details[vLoop].name,
				       ufs922_slots[vLoopSlot].details[vLoop].first_byte,
				       ufs922_slots[vLoopSlot].details[vLoop].number_bytes,
				       value);
			}
			else if (ufs922_slots[vLoopSlot].details[vLoop].type == cTypeByte)
			{
				int valueLoop;

				ufs922_slots[vLoopSlot].details[vLoop].buffer = malloc(ufs922_slots[vLoopSlot].details[vLoop].number_bytes);

				memcpy(ufs922_slots[vLoopSlot].details[vLoop].buffer,
				       buffer + ufs922_slots[vLoopSlot].details[vLoop].first_byte,
				       ufs922_slots[vLoopSlot].details[vLoop].number_bytes);

				printf("Name = %s [%d:%d] value = ",
				       ufs922_slots[vLoopSlot].details[vLoop].name,
				       ufs922_slots[vLoopSlot].details[vLoop].first_byte,
				       ufs922_slots[vLoopSlot].details[vLoop].number_bytes);

				for (valueLoop = 0; valueLoop < ufs922_slots[vLoopSlot].details[vLoop].number_bytes; valueLoop++)
					printf("0x%x ", ufs922_slots[vLoopSlot].details[vLoop].buffer[valueLoop]);
				printf("\n");
			}
		}

		close(fd_i2c);
	}
#endif

	return 0;
}
