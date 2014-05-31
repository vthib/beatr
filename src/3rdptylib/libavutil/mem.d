module libavutil.mem;

public {
	import libavutil.attributes;
	import libavutil.avutil;
}
import core.stdc.limits;

extern(C):
nothrow:

void *av_malloc(size_t size);
void *av_malloc_array(size_t nmemb, size_t size)
{
    if (!size || nmemb >= INT_MAX / size)
        return null;
    return av_malloc(nmemb * size);
}

void *av_realloc(void *ptr, size_t size);
int av_reallocp(void *ptr, size_t size);

void *av_realloc_array(void *ptr, size_t nmemb, size_t size);
int av_reallocp_array(void *ptr, size_t nmemb, size_t size);

void av_free(void *ptr);

void *av_mallocz(size_t size);
void *av_mallocz_array(size_t nmemb, size_t size)
{
    if (!size || nmemb >= INT_MAX / size)
        return null;
    return av_mallocz(nmemb * size);
}

char *av_strdup(const char *s);

void av_freep(void *ptr);

void av_memcpy_backptr(ubyte *dst, int back, int cnt);

void *av_fast_realloc(void *ptr, uint *size, size_t min_size);

void av_fast_malloc(void *ptr, uint *size, size_t min_size);
