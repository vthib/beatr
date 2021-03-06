module libavutil.pixfmt;

public import libavutil.avconfig;
public import libavutil.version_;

enum AVPixelFormat {
    AV_PIX_FMT_NONE = -1,
    AV_PIX_FMT_YUV420P,
    AV_PIX_FMT_YUYV422,
    AV_PIX_FMT_RGB24,
    AV_PIX_FMT_BGR24,
    AV_PIX_FMT_YUV422P,
    AV_PIX_FMT_YUV444P,
    AV_PIX_FMT_YUV410P,
    AV_PIX_FMT_YUV411P,
    AV_PIX_FMT_GRAY8,
    AV_PIX_FMT_MONOWHITE,
    AV_PIX_FMT_MONOBLACK,
    AV_PIX_FMT_PAL8,
    AV_PIX_FMT_YUVJ420P,
    AV_PIX_FMT_YUVJ422P,
    AV_PIX_FMT_YUVJ444P,
/+ does not work
	static if (FF_API_XVMC) {
		AV_PIX_FMT_XVMC_MPEG2_MC,
		AV_PIX_FMT_XVMC_MPEG2_IDCT,
	}
+/
    AV_PIX_FMT_UYVY422,
    AV_PIX_FMT_UYYVYY411,
    AV_PIX_FMT_BGR8,
    AV_PIX_FMT_BGR4,
    AV_PIX_FMT_BGR4_BYTE,
    AV_PIX_FMT_RGB8,
    AV_PIX_FMT_RGB4,
    AV_PIX_FMT_RGB4_BYTE,
    AV_PIX_FMT_NV12,
    AV_PIX_FMT_NV21,

    AV_PIX_FMT_ARGB,
    AV_PIX_FMT_RGBA,
    AV_PIX_FMT_ABGR,
    AV_PIX_FMT_BGRA,

    AV_PIX_FMT_GRAY16BE,
    AV_PIX_FMT_GRAY16LE,
    AV_PIX_FMT_YUV440P,
    AV_PIX_FMT_YUVJ440P,
    AV_PIX_FMT_YUVA420P,
/+ does not work
	static if (FF_API_VDPAU) {
		AV_PIX_FMT_VDPAU_H264,
		AV_PIX_FMT_VDPAU_MPEG1,
		AV_PIX_FMT_VDPAU_MPEG2,
		AV_PIX_FMT_VDPAU_WMV3,
		AV_PIX_FMT_VDPAU_VC1,
	}
+/
    AV_PIX_FMT_RGB48BE,
    AV_PIX_FMT_RGB48LE,

    AV_PIX_FMT_RGB565BE,
    AV_PIX_FMT_RGB565LE,
    AV_PIX_FMT_RGB555BE,
    AV_PIX_FMT_RGB555LE,

    AV_PIX_FMT_BGR565BE,
    AV_PIX_FMT_BGR565LE,
    AV_PIX_FMT_BGR555BE,
    AV_PIX_FMT_BGR555LE,

    AV_PIX_FMT_VAAPI_MOCO,
    AV_PIX_FMT_VAAPI_IDCT,
    AV_PIX_FMT_VAAPI_VLD,

    AV_PIX_FMT_YUV420P16LE,
    AV_PIX_FMT_YUV420P16BE,
    AV_PIX_FMT_YUV422P16LE,
    AV_PIX_FMT_YUV422P16BE,
    AV_PIX_FMT_YUV444P16LE,
    AV_PIX_FMT_YUV444P16BE,
/+ does not work
	static if (FF_API_VDPAU)
		AV_PIX_FMT_VDPAU_MPEG4,
+/
    AV_PIX_FMT_DXVA2_VLD,

    AV_PIX_FMT_RGB444LE,
    AV_PIX_FMT_RGB444BE,
    AV_PIX_FMT_BGR444LE,
    AV_PIX_FMT_BGR444BE,
    AV_PIX_FMT_Y400A,
    AV_PIX_FMT_BGR48BE,
    AV_PIX_FMT_BGR48LE,
    AV_PIX_FMT_YUV420P9BE,
    AV_PIX_FMT_YUV420P9LE,
    AV_PIX_FMT_YUV420P10BE,
    AV_PIX_FMT_YUV420P10LE,
    AV_PIX_FMT_YUV422P10BE,
    AV_PIX_FMT_YUV422P10LE,
    AV_PIX_FMT_YUV444P9BE,
    AV_PIX_FMT_YUV444P9LE,
    AV_PIX_FMT_YUV444P10BE,
    AV_PIX_FMT_YUV444P10LE,
    AV_PIX_FMT_YUV422P9BE,
    AV_PIX_FMT_YUV422P9LE,
    AV_PIX_FMT_VDA_VLD,
    AV_PIX_FMT_GBRP,
    AV_PIX_FMT_GBRP9BE,
    AV_PIX_FMT_GBRP9LE,
    AV_PIX_FMT_GBRP10BE,
    AV_PIX_FMT_GBRP10LE,
    AV_PIX_FMT_GBRP16BE,
    AV_PIX_FMT_GBRP16LE,
    AV_PIX_FMT_YUVA422P,
    AV_PIX_FMT_YUVA444P,
    AV_PIX_FMT_YUVA420P9BE,
    AV_PIX_FMT_YUVA420P9LE,
    AV_PIX_FMT_YUVA422P9BE,
    AV_PIX_FMT_YUVA422P9LE,
    AV_PIX_FMT_YUVA444P9BE,
    AV_PIX_FMT_YUVA444P9LE,
    AV_PIX_FMT_YUVA420P10BE,
    AV_PIX_FMT_YUVA420P10LE,
    AV_PIX_FMT_YUVA422P10BE,
    AV_PIX_FMT_YUVA422P10LE,
    AV_PIX_FMT_YUVA444P10BE,
    AV_PIX_FMT_YUVA444P10LE,
    AV_PIX_FMT_YUVA420P16BE,
    AV_PIX_FMT_YUVA420P16LE,
    AV_PIX_FMT_YUVA422P16BE,
    AV_PIX_FMT_YUVA422P16LE,
    AV_PIX_FMT_YUVA444P16BE,
    AV_PIX_FMT_YUVA444P16LE,
    AV_PIX_FMT_VDPAU,
    AV_PIX_FMT_XYZ12LE,
    AV_PIX_FMT_XYZ12BE,
    AV_PIX_FMT_NV16,
    AV_PIX_FMT_NV20LE,
    AV_PIX_FMT_NV20BE,
    AV_PIX_FMT_NB,
};

static if (AV_HAVE_BIGENDIAN) {
	T AV_PIX_FMT_NE(T)(T be, T le) { return be; }
} else {
	T AV_PIX_FMT_NE(T)(T be, T le) { return le; }
}

enum AV_PIX_FMT_RGB32   = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_ARGB,
										AVPixelFormat.AV_PIX_FMT_BGRA);
enum AV_PIX_FMT_RGB32_1 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_RGBA,
										AVPixelFormat.AV_PIX_FMT_ABGR);
enum AV_PIX_FMT_BGR32   = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_ABGR,
										AVPixelFormat.AV_PIX_FMT_RGBA);
enum AV_PIX_FMT_BGR32_1 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_BGRA,
										AVPixelFormat.AV_PIX_FMT_ARGB);

enum AV_PIX_FMT_GRAY16 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_GRAY16BE,
									   AVPixelFormat.AV_PIX_FMT_GRAY16LE);
enum AV_PIX_FMT_RGB48  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_RGB48BE,
									   AVPixelFormat.AV_PIX_FMT_RGB48LE);
enum AV_PIX_FMT_RGB565 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_RGB565BE,
									   AVPixelFormat.AV_PIX_FMT_RGB565LE);
enum AV_PIX_FMT_RGB555 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_RGB555BE,
									   AVPixelFormat.AV_PIX_FMT_RGB555LE);
enum AV_PIX_FMT_RGB444 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_RGB444BE,
									   AVPixelFormat.AV_PIX_FMT_RGB444LE);
enum AV_PIX_FMT_BGR48  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_BGR48BE,
									   AVPixelFormat.AV_PIX_FMT_BGR48LE);
enum AV_PIX_FMT_BGR565 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_BGR565BE,
									   AVPixelFormat.AV_PIX_FMT_BGR565LE);
enum AV_PIX_FMT_BGR555 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_BGR555BE,
									   AVPixelFormat.AV_PIX_FMT_BGR555LE);
enum AV_PIX_FMT_BGR444 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_BGR444BE,
									   AVPixelFormat.AV_PIX_FMT_BGR444LE);

enum AV_PIX_FMT_YUV420P9  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV420P9BE,
										  AVPixelFormat.AV_PIX_FMT_YUV420P9LE);
enum AV_PIX_FMT_YUV422P9  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV422P9BE,
										  AVPixelFormat.AV_PIX_FMT_YUV422P9LE);
enum AV_PIX_FMT_YUV444P9  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV444P9BE,
										  AVPixelFormat.AV_PIX_FMT_YUV444P9LE);
enum AV_PIX_FMT_YUV420P10 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV420P10BE,
										  AVPixelFormat.AV_PIX_FMT_YUV420P10LE);
enum AV_PIX_FMT_YUV422P10 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV422P10BE,
										  AVPixelFormat.AV_PIX_FMT_YUV422P10LE);
enum AV_PIX_FMT_YUV444P10 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV444P10BE,
										  AVPixelFormat.AV_PIX_FMT_YUV444P10LE);
enum AV_PIX_FMT_YUV420P16 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV420P16BE,
										  AVPixelFormat.AV_PIX_FMT_YUV420P16LE);
enum AV_PIX_FMT_YUV422P16 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV422P16BE,
										  AVPixelFormat.AV_PIX_FMT_YUV422P16LE);
enum AV_PIX_FMT_YUV444P16 = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUV444P16BE,
										  AVPixelFormat.AV_PIX_FMT_YUV444P16LE);

enum AV_PIX_FMT_GBRP9     = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_GBRP9BE,
										  AVPixelFormat.AV_PIX_FMT_GBRP9LE);
enum AV_PIX_FMT_GBRP10    = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_GBRP10BE,
										  AVPixelFormat.AV_PIX_FMT_GBRP10LE);
enum AV_PIX_FMT_GBRP16    = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_GBRP16BE,
										  AVPixelFormat.AV_PIX_FMT_GBRP16LE);

enum AV_PIX_FMT_YUVA420P9  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA420P9BE,
										  AVPixelFormat.AV_PIX_FMT_YUVA420P9LE);
enum AV_PIX_FMT_YUVA422P9  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA422P9BE,
										  AVPixelFormat.AV_PIX_FMT_YUVA422P9LE);
enum AV_PIX_FMT_YUVA444P9  = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA444P9BE,
										  AVPixelFormat.AV_PIX_FMT_YUVA444P9LE);
enum AV_PIX_FMT_YUVA420P10 =
	AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA420P10BE,
				  AVPixelFormat.AV_PIX_FMT_YUVA420P10LE);
enum AV_PIX_FMT_YUVA422P10 =
	AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA422P10BE,
			   AVPixelFormat.AV_PIX_FMT_YUVA422P10LE);
enum AV_PIX_FMT_YUVA444P10 =
	AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA444P10BE,
			   AVPixelFormat.AV_PIX_FMT_YUVA444P10LE);
enum AV_PIX_FMT_YUVA420P16 =
	AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA420P16BE,
			   AVPixelFormat.AV_PIX_FMT_YUVA420P16LE);
enum AV_PIX_FMT_YUVA422P16 =
	AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA422P16BE,
				  AVPixelFormat.AV_PIX_FMT_YUVA422P16LE);
enum AV_PIX_FMT_YUVA444P16 =
	AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_YUVA444P16BE,
				  AVPixelFormat.AV_PIX_FMT_YUVA444P16LE);

enum AV_PIX_FMT_XYZ12      = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_XYZ12BE,
										  AVPixelFormat.AV_PIX_FMT_XYZ12LE);
enum AV_PIX_FMT_NV20       = AV_PIX_FMT_NE(AVPixelFormat.AV_PIX_FMT_NV20BE,
										  AVPixelFormat.AV_PIX_FMT_NV20LE);

static if (FF_API_PIX_FMT) {
	alias AVPixelFormat PixelFormat;

	alias AV_PIX_FMT_NE PIX_FMT_NE;

	alias AV_PIX_FMT_RGB32   PIX_FMT_RGB32;
	alias AV_PIX_FMT_RGB32_1 PIX_FMT_RGB32_1;
	alias AV_PIX_FMT_BGR32   PIX_FMT_BGR32;
	alias AV_PIX_FMT_BGR32_1 PIX_FMT_BGR32_1;

	alias AV_PIX_FMT_GRAY16 PIX_FMT_GRAY16;
	alias AV_PIX_FMT_RGB48  PIX_FMT_RGB48;
	alias AV_PIX_FMT_RGB565 PIX_FMT_RGB565;
	alias AV_PIX_FMT_RGB555 PIX_FMT_RGB555;
	alias AV_PIX_FMT_RGB444 PIX_FMT_RGB444;
	alias AV_PIX_FMT_BGR48  PIX_FMT_BGR48;
	alias AV_PIX_FMT_BGR565 PIX_FMT_BGR565;
	alias AV_PIX_FMT_BGR555 PIX_FMT_BGR555;
	alias AV_PIX_FMT_BGR444 PIX_FMT_BGR444;

	alias AV_PIX_FMT_YUV420P9  PIX_FMT_YUV420P9;
	alias AV_PIX_FMT_YUV422P9  PIX_FMT_YUV422P9;
	alias AV_PIX_FMT_YUV444P9  PIX_FMT_YUV444P9;
	alias AV_PIX_FMT_YUV420P10 PIX_FMT_YUV420P10;
	alias AV_PIX_FMT_YUV422P10 PIX_FMT_YUV422P10;
	alias AV_PIX_FMT_YUV444P10 PIX_FMT_YUV444P10;
	alias AV_PIX_FMT_YUV420P16 PIX_FMT_YUV420P16;
	alias AV_PIX_FMT_YUV422P16 PIX_FMT_YUV422P16;
	alias AV_PIX_FMT_YUV444P16 PIX_FMT_YUV444P16;

	alias AV_PIX_FMT_GBRP9  PIX_FMT_GBRP9;
	alias AV_PIX_FMT_GBRP10 PIX_FMT_GBRP10;
	alias AV_PIX_FMT_GBRP16 PIX_FMT_GBRP16;
}

