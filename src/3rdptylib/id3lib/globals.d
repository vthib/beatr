module id3lib.globals;

extern(C):
nothrow:

enum ID3_TAGID         = "ID3";
enum ID3_TAGIDSIZE     = 3;
enum ID3_TAGHEADERSIZE = 10;
/** \enum ID3_TextEnc
 ** Enumeration of the types of text encodings: ascii or unicode
 **/
enum ID3_TextEnc
{
  ID3TE_NONE = -1,
  ID3TE_ISO8859_1,
  ID3TE_UTF16,
  ID3TE_UTF16BE,
  ID3TE_UTF8,
  ID3TE_NUMENCODINGS,
  ID3TE_ASCII = ID3TE_ISO8859_1, // do not use this -> use ID3TE_IS_SINGLE_BYTE_ENC(enc) instead
  ID3TE_UNICODE = ID3TE_UTF16    // do not use this -> use ID3TE_IS_DOUBLE_BYTE_ENC(enc) instead
};

/** Enumeration of the various id3 specifications
 **/
enum ID3_V1Spec
{
  ID3V1_0 = 0,
  ID3V1_1,
  ID3V1_NUMSPECS
};

enum ID3_V2Spec
{
  ID3V2_UNKNOWN = -1,
  ID3V2_2_0 = 0,
  ID3V2_2_1,
  ID3V2_3_0,
  ID3V2_4_0,
  ID3V2_EARLIEST = ID3V2_2_0,
  ID3V2_LATEST = ID3V2_3_0
};

/** The various types of tags that id3lib can handle
 **/
enum ID3_TagType
{
  ID3TT_NONE       =      0,   /**< Represents an empty or non-existant tag */
  ID3TT_ID3V1      = 1 << 0,   /**< Represents an id3v1 or id3v1.1 tag */
  ID3TT_ID3V2      = 1 << 1,   /**< Represents an id3v2 tag */
  ID3TT_LYRICS3    = 1 << 2,   /**< Represents a Lyrics3 tag */
  ID3TT_LYRICS3V2  = 1 << 3,   /**< Represents a Lyrics3 v2.00 tag */
  ID3TT_MUSICMATCH = 1 << 4,   /**< Represents a MusicMatch tag */
   /**< Represents a Lyrics3 tag (for backwards compatibility) */
  ID3TT_LYRICS     = ID3TT_LYRICS3,
  /** Represents both id3 tags: id3v1 and id3v2 */
  ID3TT_ID3        = ID3TT_ID3V1 | ID3TT_ID3V2,
  /** Represents all possible types of tags */
  ID3TT_ALL        = ~ID3TT_NONE,
  /** Represents all tag types that can be prepended to a file */
  ID3TT_PREPENDED  = ID3TT_ID3V2,
  /** Represents all tag types that can be appended to a file */
  ID3TT_APPENDED   = ID3TT_ALL & ~ID3TT_ID3V2
};

/**
 ** Enumeration of the different types of fields in a frame.
 **/
enum ID3_FieldID
{
  ID3FN_NOFIELD = 0,    /**< No field */
  ID3FN_TEXTENC,        /**< Text encoding (unicode or ASCII) */
  ID3FN_TEXT,           /**< Text field */
  ID3FN_URL,            /**< A URL */
  ID3FN_DATA,           /**< Data field */
  ID3FN_DESCRIPTION,    /**< Description field */
  ID3FN_OWNER,          /**< Owner field */
  ID3FN_EMAIL,          /**< Email field */
  ID3FN_RATING,         /**< Rating field */
  ID3FN_FILENAME,       /**< Filename field */
  ID3FN_LANGUAGE,       /**< Language field */
  ID3FN_PICTURETYPE,    /**< Picture type field */
  ID3FN_IMAGEFORMAT,    /**< Image format field */
  ID3FN_MIMETYPE,       /**< Mimetype field */
  ID3FN_COUNTER,        /**< Counter field */
  ID3FN_ID,             /**< Identifier/Symbol field */
  ID3FN_VOLUMEADJ,      /**< Volume adjustment field */
  ID3FN_NUMBITS,        /**< Number of bits field */
  ID3FN_VOLCHGRIGHT,    /**< Volume chage on the right channel */
  ID3FN_VOLCHGLEFT,     /**< Volume chage on the left channel */
  ID3FN_PEAKVOLRIGHT,   /**< Peak volume on the right channel */
  ID3FN_PEAKVOLLEFT,    /**< Peak volume on the left channel */
  ID3FN_TIMESTAMPFORMAT,/**< SYLT Timestamp Format */
  ID3FN_CONTENTTYPE,    /**< SYLT content type */
  ID3FN_LASTFIELDID     /**< Last field placeholder */
};

/**
 ** Enumeration of the different types of frames recognized by id3lib
 **/
enum ID3_FrameID
{
  /* ???? */ ID3FID_NOFRAME = 0,       /**< No known frame */
  /* AENC */ ID3FID_AUDIOCRYPTO,       /**< Audio encryption */
  /* APIC */ ID3FID_PICTURE,           /**< Attached picture */
  /* ASPI */ ID3FID_AUDIOSEEKPOINT,    /**< Audio seek point index */
  /* COMM */ ID3FID_COMMENT,           /**< Comments */
  /* COMR */ ID3FID_COMMERCIAL,        /**< Commercial frame */
  /* ENCR */ ID3FID_CRYPTOREG,         /**< Encryption method registration */
  /* EQU2 */ ID3FID_EQUALIZATION2,     /**< Equalisation (2) */
  /* EQUA */ ID3FID_EQUALIZATION,      /**< Equalization */
  /* ETCO */ ID3FID_EVENTTIMING,       /**< Event timing codes */
  /* GEOB */ ID3FID_GENERALOBJECT,     /**< General encapsulated object */
  /* GRID */ ID3FID_GROUPINGREG,       /**< Group identification registration */
  /* IPLS */ ID3FID_INVOLVEDPEOPLE,    /**< Involved people list */
  /* LINK */ ID3FID_LINKEDINFO,        /**< Linked information */
  /* MCDI */ ID3FID_CDID,              /**< Music CD identifier */
  /* MLLT */ ID3FID_MPEGLOOKUP,        /**< MPEG location lookup table */
  /* OWNE */ ID3FID_OWNERSHIP,         /**< Ownership frame */
  /* PRIV */ ID3FID_PRIVATE,           /**< Private frame */
  /* PCNT */ ID3FID_PLAYCOUNTER,       /**< Play counter */
  /* POPM */ ID3FID_POPULARIMETER,     /**< Popularimeter */
  /* POSS */ ID3FID_POSITIONSYNC,      /**< Position synchronisation frame */
  /* RBUF */ ID3FID_BUFFERSIZE,        /**< Recommended buffer size */
  /* RVA2 */ ID3FID_VOLUMEADJ2,        /**< Relative volume adjustment (2) */
  /* RVAD */ ID3FID_VOLUMEADJ,         /**< Relative volume adjustment */
  /* RVRB */ ID3FID_REVERB,            /**< Reverb */
  /* SEEK */ ID3FID_SEEKFRAME,         /**< Seek frame */
  /* SIGN */ ID3FID_SIGNATURE,         /**< Signature frame */
  /* SYLT */ ID3FID_SYNCEDLYRICS,      /**< Synchronized lyric/text */
  /* SYTC */ ID3FID_SYNCEDTEMPO,       /**< Synchronized tempo codes */
  /* TALB */ ID3FID_ALBUM,             /**< Album/Movie/Show title */
  /* TBPM */ ID3FID_BPM,               /**< BPM (beats per minute) */
  /* TCOM */ ID3FID_COMPOSER,          /**< Composer */
  /* TCON */ ID3FID_CONTENTTYPE,       /**< Content type */
  /* TCOP */ ID3FID_COPYRIGHT,         /**< Copyright message */
  /* TDAT */ ID3FID_DATE,              /**< Date */
  /* TDEN */ ID3FID_ENCODINGTIME,      /**< Encoding time */
  /* TDLY */ ID3FID_PLAYLISTDELAY,     /**< Playlist delay */
  /* TDOR */ ID3FID_ORIGRELEASETIME,   /**< Original release time */
  /* TDRC */ ID3FID_RECORDINGTIME,     /**< Recording time */
  /* TDRL */ ID3FID_RELEASETIME,       /**< Release time */
  /* TDTG */ ID3FID_TAGGINGTIME,       /**< Tagging time */
  /* TIPL */ ID3FID_INVOLVEDPEOPLE2,   /**< Involved people list */
  /* TENC */ ID3FID_ENCODEDBY,         /**< Encoded by */
  /* TEXT */ ID3FID_LYRICIST,          /**< Lyricist/Text writer */
  /* TFLT */ ID3FID_FILETYPE,          /**< File type */
  /* TIME */ ID3FID_TIME,              /**< Time */
  /* TIT1 */ ID3FID_CONTENTGROUP,      /**< Content group description */
  /* TIT2 */ ID3FID_TITLE,             /**< Title/songname/content description */
  /* TIT3 */ ID3FID_SUBTITLE,          /**< Subtitle/Description refinement */
  /* TKEY */ ID3FID_INITIALKEY,        /**< Initial key */
  /* TLAN */ ID3FID_LANGUAGE,          /**< Language(s) */
  /* TLEN */ ID3FID_SONGLEN,           /**< Length */
  /* TMCL */ ID3FID_MUSICIANCREDITLIST,/**< Musician credits list */
  /* TMED */ ID3FID_MEDIATYPE,         /**< Media type */
  /* TMOO */ ID3FID_MOOD,              /**< Mood */
  /* TOAL */ ID3FID_ORIGALBUM,         /**< Original album/movie/show title */
  /* TOFN */ ID3FID_ORIGFILENAME,      /**< Original filename */
  /* TOLY */ ID3FID_ORIGLYRICIST,      /**< Original lyricist(s)/text writer(s) */
  /* TOPE */ ID3FID_ORIGARTIST,        /**< Original artist(s)/performer(s) */
  /* TORY */ ID3FID_ORIGYEAR,          /**< Original release year */
  /* TOWN */ ID3FID_FILEOWNER,         /**< File owner/licensee */
  /* TPE1 */ ID3FID_LEADARTIST,        /**< Lead performer(s)/Soloist(s) */
  /* TPE2 */ ID3FID_BAND,              /**< Band/orchestra/accompaniment */
  /* TPE3 */ ID3FID_CONDUCTOR,         /**< Conductor/performer refinement */
  /* TPE4 */ ID3FID_MIXARTIST,         /**< Interpreted, remixed, or otherwise modified by */
  /* TPOS */ ID3FID_PARTINSET,         /**< Part of a set */
  /* TPRO */ ID3FID_PRODUCEDNOTICE,    /**< Produced notice */
  /* TPUB */ ID3FID_PUBLISHER,         /**< Publisher */
  /* TRCK */ ID3FID_TRACKNUM,          /**< Track number/Position in set */
  /* TRDA */ ID3FID_RECORDINGDATES,    /**< Recording dates */
  /* TRSN */ ID3FID_NETRADIOSTATION,   /**< Internet radio station name */
  /* TRSO */ ID3FID_NETRADIOOWNER,     /**< Internet radio station owner */
  /* TSIZ */ ID3FID_SIZE,              /**< Size */
  /* TSOA */ ID3FID_ALBUMSORTORDER,    /**< Album sort order */
  /* TSOP */ ID3FID_PERFORMERSORTORDER,/**< Performer sort order */
  /* TSOT */ ID3FID_TITLESORTORDER,    /**< Title sort order */
  /* TSRC */ ID3FID_ISRC,              /**< ISRC (international standard recording code) */
  /* TSSE */ ID3FID_ENCODERSETTINGS,   /**< Software/Hardware and settings used for encoding */
  /* TSST */ ID3FID_SETSUBTITLE,       /**< Set subtitle */
  /* TXXX */ ID3FID_USERTEXT,          /**< User defined text information */
  /* TYER */ ID3FID_YEAR,              /**< Year */
  /* UFID */ ID3FID_UNIQUEFILEID,      /**< Unique file identifier */
  /* USER */ ID3FID_TERMSOFUSE,        /**< Terms of use */
  /* USLT */ ID3FID_UNSYNCEDLYRICS,    /**< Unsynchronized lyric/text transcription */
  /* WCOM */ ID3FID_WWWCOMMERCIALINFO, /**< Commercial information */
  /* WCOP */ ID3FID_WWWCOPYRIGHT,      /**< Copyright/Legal information */
  /* WOAF */ ID3FID_WWWAUDIOFILE,      /**< Official audio file webpage */
  /* WOAR */ ID3FID_WWWARTIST,         /**< Official artist/performer webpage */
  /* WOAS */ ID3FID_WWWAUDIOSOURCE,    /**< Official audio source webpage */
  /* WORS */ ID3FID_WWWRADIOPAGE,      /**< Official internet radio station homepage */
  /* WPAY */ ID3FID_WWWPAYMENT,        /**< Payment */
  /* WPUB */ ID3FID_WWWPUBLISHER,      /**< Official publisher webpage */
  /* WXXX */ ID3FID_WWWUSER,           /**< User defined URL link */
  /*      */ ID3FID_METACRYPTO,        /**< Encrypted meta frame (id3v2.2.x) */
  /*      */ ID3FID_METACOMPRESSION,   /**< Compressed meta frame (id3v2.2.1) */
  /* >>>> */ ID3FID_LASTFRAMEID        /**< Last field placeholder */
};

enum ID3_V1Lengths
{
  ID3_V1_LEN         = 128,
  ID3_V1_LEN_ID      =   3,
  ID3_V1_LEN_TITLE   =  30,
  ID3_V1_LEN_ARTIST  =  30,
  ID3_V1_LEN_ALBUM   =  30,
  ID3_V1_LEN_YEAR    =   4,
  ID3_V1_LEN_COMMENT =  30,
  ID3_V1_LEN_GENRE   =   1
};

enum ID3_FieldFlags
{
  ID3FF_NONE       =      0,
  ID3FF_CSTR       = 1 << 0,
  ID3FF_LIST       = 1 << 1,
  ID3FF_ENCODABLE  = 1 << 2,
  ID3FF_TEXTLIST   = ID3FF_CSTR | ID3FF_LIST | ID3FF_ENCODABLE
};

/** Enumeration of the types of field types */
enum ID3_FieldType
{
  ID3FTY_NONE           = -1,
  ID3FTY_INTEGER        = 0,
  ID3FTY_BINARY,
  ID3FTY_TEXTSTRING,
  ID3FTY_NUMTYPES
};

/**
 ** Predefined id3lib error types.
 **/
enum ID3_Err
{
  ID3E_NoError = 0,             /**< No error reported */
  ID3E_NoMemory,                /**< No available memory */
  ID3E_NoData,                  /**< No data to parse */
  ID3E_BadData,                 /**< Improperly formatted data */
  ID3E_NoBuffer,                /**< No buffer to write to */
  ID3E_SmallBuffer,             /**< Buffer is too small */
  ID3E_InvalidFrameID,          /**< Invalid frame id */
  ID3E_FieldNotFound,           /**< Requested field not found */
  ID3E_UnknownFieldType,        /**< Unknown field type */
  ID3E_TagAlreadyAttached,      /**< Tag is already attached to a file */
  ID3E_InvalidTagVersion,       /**< Invalid tag version */
  ID3E_NoFile,                  /**< No file to parse */
  ID3E_ReadOnly,                /**< Attempting to write to a read-only file */
  ID3E_zlibError                /**< Error in compression/uncompression */
};

enum ID3_ContentType
{
  ID3CT_OTHER = 0,
  ID3CT_LYRICS,
  ID3CT_TEXTTRANSCRIPTION,
  ID3CT_MOVEMENT,
  ID3CT_EVENTS,
  ID3CT_CHORD,
  ID3CT_TRIVIA
};

enum ID3_PictureType
{
  ID3PT_OTHER = 0,
  ID3PT_PNG32ICON = 1,     //  32x32 pixels 'file icon' (PNG only)
  ID3PT_OTHERICON = 2,     // Other file icon
  ID3PT_COVERFRONT = 3,    // Cover (front)
  ID3PT_COVERBACK = 4,     // Cover (back)
  ID3PT_LEAFLETPAGE = 5,   // Leaflet page
  ID3PT_MEDIA = 6,         // Media (e.g. lable side of CD)
  ID3PT_LEADARTIST = 7,    // Lead artist/lead performer/soloist
  ID3PT_ARTIST = 8,        // Artist/performer
  ID3PT_CONDUCTOR = 9,     // Conductor
  ID3PT_BAND = 10,         // Band/Orchestra
  ID3PT_COMPOSER = 11,     // Composer
  ID3PT_LYRICIST = 12,     // Lyricist/text writer
  ID3PT_REC_LOCATION = 13, // Recording Location
  ID3PT_RECORDING = 14,    // During recording
  ID3PT_PERFORMANCE = 15,  // During performance
  ID3PT_VIDEO = 16,        // Movie/video screen capture
  ID3PT_FISH = 17,         // A bright coloured fish
  ID3PT_ILLUSTRATION = 18, // Illustration
  ID3PT_ARTISTLOGO = 19,   // Band/artist logotype
  ID3PT_PUBLISHERLOGO = 20 // Publisher/Studio logotype
};

enum ID3_TimeStampFormat
{
  ID3TSF_FRAME  = 1,
  ID3TSF_MS
};

enum MP3_BitRates
{
  MP3BITRATE_FALSE = -1,
  MP3BITRATE_NONE = 0,
  MP3BITRATE_8K   = 8000,
  MP3BITRATE_16K  = 16000,
  MP3BITRATE_24K  = 24000,
  MP3BITRATE_32K  = 32000,
  MP3BITRATE_40K  = 40000,
  MP3BITRATE_48K  = 48000,
  MP3BITRATE_56K  = 56000,
  MP3BITRATE_64K  = 64000,
  MP3BITRATE_80K  = 80000,
  MP3BITRATE_96K  = 96000,
  MP3BITRATE_112K = 112000,
  MP3BITRATE_128K = 128000,
  MP3BITRATE_144K = 144000,
  MP3BITRATE_160K = 160000,
  MP3BITRATE_176K = 176000,
  MP3BITRATE_192K = 192000,
  MP3BITRATE_224K = 224000,
  MP3BITRATE_256K = 256000,
  MP3BITRATE_288K = 288000,
  MP3BITRATE_320K = 320000,
  MP3BITRATE_352K = 352000,
  MP3BITRATE_384K = 384000,
  MP3BITRATE_416K = 416000,
  MP3BITRATE_448K = 448000
};

enum Mpeg_Layers
{
  MPEGLAYER_FALSE = -1,
  MPEGLAYER_UNDEFINED,
  MPEGLAYER_III,
  MPEGLAYER_II,
  MPEGLAYER_I
};

enum Mpeg_Version
{
  MPEGVERSION_FALSE = -1,
  MPEGVERSION_2_5,
  MPEGVERSION_Reserved,
  MPEGVERSION_2,
  MPEGVERSION_1
};

enum Mp3_Frequencies
{
  MP3FREQUENCIES_FALSE = -1,
  MP3FREQUENCIES_Reserved = 0,
  MP3FREQUENCIES_8000HZ = 8000,
  MP3FREQUENCIES_11025HZ = 11025,
  MP3FREQUENCIES_12000HZ = 12000,
  MP3FREQUENCIES_16000HZ = 16000,
  MP3FREQUENCIES_22050HZ = 22050,
  MP3FREQUENCIES_24000HZ = 24000,
  MP3FREQUENCIES_32000HZ = 32000,
  MP3FREQUENCIES_48000HZ = 48000,
  MP3FREQUENCIES_44100HZ = 44100,
};

enum Mp3_ChannelMode
{
  MP3CHANNELMODE_FALSE = -1,
  MP3CHANNELMODE_STEREO,
  MP3CHANNELMODE_JOINT_STEREO,
  MP3CHANNELMODE_DUAL_CHANNEL,
  MP3CHANNELMODE_SINGLE_CHANNEL
};

enum Mp3_ModeExt
{
  MP3MODEEXT_FALSE = -1,
  MP3MODEEXT_0,
  MP3MODEEXT_1,
  MP3MODEEXT_2,
  MP3MODEEXT_3
};

enum Mp3_Emphasis
{
  MP3EMPHASIS_FALSE = -1,
  MP3EMPHASIS_NONE,
  MP3EMPHASIS_50_15MS,
  MP3EMPHASIS_Reserved,
  MP3EMPHASIS_CCIT_J17
};

enum Mp3_Crc
{
  MP3CRC_ERROR_SIZE = -2,
  MP3CRC_MISMATCH = -1,
  MP3CRC_NONE = 0,
  MP3CRC_OK = 1
};
