module libavutil.rational;

extern(C):
nothrow:

struct AVRational {
	int num;
	int den;
};

pure int av_cmp_q(AVRational a, AVRational b)
{
	immutable long tmp = a.num * cast(long)b.den - b.num * cast(long)a.den;

	if (tmp) return ((tmp ^ a.den ^ b.den) >> 63) | 1;
	else if (b.den && a.den) return 0;
	else if (a.num && b.num) return (a.num >> 31) - (b.num >> 31);
	else return int.min;
}

pure double av_q2d(AVRational a)
{
	return a.num / cast(double) a.den;
}

int av_reduce(int *dst_num, int *dst_den, long num, long den, long max);

pure AVRational av_mul_q(AVRational b, AVRational c);
pure AVRational av_div_q(AVRational b, AVRational c);
pure AVRational av_add_q(AVRational b, AVRational c);
pure AVRational av_sub_q(AVRational b, AVRational c);

pure AVRational av_int_q(AVRational q)
{
	return AVRational(q.den, q.num);
}

pure AVRational av_d2q(double d, int max);

int av_nearer_q(AVRational q, AVRational q1, AVRational q2);
int av_find_nearest_q_idx(AVRational q, const AVRational* q_list);
