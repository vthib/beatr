module fftw3;

import std.stdio : FILE;
import std.string : format; // for the mixin

extern(C):
nothrow:

enum fftw_r2r_kind_do_not_use_me {
	FFTW_R2HC = 0,
	FFTW_HC2R = 1,
	FFTW_DHT = 2,
	FFTW_REDFT00 = 3,
	FFTW_REDFT01 = 4,
	FFTW_REDFT10 = 5,
	FFTW_REDFT11 = 6,
	FFTW_RODFT00 = 7,
	FFTW_RODFT01 = 8,
	FFTW_RODFT10 = 9,
	FFTW_RODFT11 = 10
}

struct fftw_iodim_do_not_use_me {
	int n; /* dimension size */
	int ins; /* input stride */
	int os; /* output stride */
}

import std.c.stddef;

struct fftw_iodim64_do_not_use_me {
	ptrdiff_t n;
	ptrdiff_t ins;
	ptrdiff_t os;
}

mixin template Define_API(string p, R, T)
{
	mixin(format(q{alias void* %s_plan;}, p));

	mixin(format(q{alias fftw_iodim_do_not_use_me %s_iodim;}, p));
	mixin(format(q{alias fftw_iodim64_do_not_use_me %s_iodim64;}, p));
	mixin(format(q{alias fftw_r2r_kind_do_not_use_me %s_r2r_kind;}, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
			    %s_iodim i;
		        %s_iodim64 i64;
		        %s_r2r_kind r;
			}, p, p, p));
		    assert(i.sizeof == 3*int.sizeof);
		    assert(i64.sizeof == 3*ptrdiff_t.sizeof);
		    assert(r.sizeof == int.sizeof);
        }
	}

	/* X_execute */
	pragma(mangle, format(q{%s_execute}, p))
	mixin(format(q{
void %s_execute(const %s_plan plan);
}, p, p));

	/* --- plan functions --- */

	/* X_plan_dft */
	pragma(mangle, format(q{%s_plan_dft}, p))
	mixin(format(q{
%s_plan %s_plan_dft(int rank, int *n, T *i, T *o, int sign, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T i;
				int[] n = [1];
				auto plan = %s_plan_dft(0, n.ptr, &i, &i, 1, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_dft_1d */
	pragma(mangle, format(q{%s_plan_dft_1d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_1d(int n, T *i, T *o, int sign, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T i;
				auto plan = %s_plan_dft_1d(1, &i, &i, 1, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_dft_2d */
	pragma(mangle, format(q{%s_plan_dft_2d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_2d(int n0, int n1, T *i, T *o, int sign, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T[] n = new T[2];
				auto plan = %s_plan_dft_2d(2, 1, n.ptr, n.ptr, 1, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_dft_3d */
	pragma(mangle, format(q{%s_plan_dft_3d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_3d(int n0, int n1, int n2, T *i, T *o, int sign,
					   uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T[] n = new T[3];
				auto plan = %s_plan_dft_3d(1, 3, 1, n.ptr, n.ptr, 1, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_many_dft */
	pragma(mangle, format(q{%s_plan_many_dft}, p))
	mixin(format(q{
%s_plan %s_plan_many_dft(int rank, int *n, int howmany, T *i, int *inembed,
						 int istride, int idist, T *o, int *onembed,
						 int ostride, int odist, int sign, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T i;
				int[] n = [1, 1];
				auto plan = %s_plan_many_dft(2, n.ptr, 1, &i, n.ptr, 1, 0, &i,
											 n.ptr, 1, 0, 1, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* --- guru functions --- */

	/* X_plan_guru_dft */
	pragma(mangle, format(q{%s_plan_guru_dft}, p))
	mixin(format(q{
%s_plan %s_plan_guru_dft(int rank, %s_iodim *dims, int howmany_rank,
						 %s_iodim *howmany_dims, T *i, T *o,
						 int sign, uint flags);
}, p, p, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				auto dim = %s_iodim(1, 1, 1);
				T i;
				auto plan = %s_plan_guru_dft(1, &dim, 1, &dim, &i, &i, 1, 0);
				%s_execute(plan);
			}, p, p, p));
		}
	}

	/* X_plan_guru_split_dft */
	pragma(mangle, format(q{%s_plan_guru_split_dft}, p))
	mixin(format(q{
%s_plan %s_plan_guru_split_dft(int rank, %s_iodim *dims, int howmany_rank,
							   %s_iodim *howmany_dims, R *ri, R *ii, R *ro,
							   R *io, uint flags);
}, p, p, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				auto dim = %s_iodim(1, 1, 1);
				R i1, i2;
				auto plan = %s_plan_guru_split_dft(1, &dim, 1, &dim, &i1,
												   &i2, &i1, &i2, 0);
				%s_execute(plan);
			}, p, p, p));
		}
	}

	/* X_plan_guru64_dft */
	pragma(mangle, format(q{%s_plan_guru64_dft}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_dft(int rank, %s_iodim64 *dims, int howmany_rank,
						 %s_iodim64 *howmany_dims, T *i, T *o,
						 int sign, uint flags);
}, p, p, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				auto dim = %s_iodim64(1, 1, 1);
				T i;
				auto plan = %s_plan_guru64_dft(1, &dim, 1, &dim, &i, &i, 1,
											   0);
				%s_execute(plan);
			}, p, p, p));
		}
	}

	/* X_plan_guru64_split_dft */
	pragma(mangle, format(q{%s_plan_guru64_split_dft}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_split_dft(int rank, %s_iodim64 *dims, int howmany_rank,
								 %s_iodim64 *howmany_dims, R *ri, R *ii, R *ro,
								 R *io, uint flags);
}, p, p, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				auto dim = %s_iodim64(1, 1, 1);
				R i1, i2;
				auto plan = %s_plan_guru64_split_dft(1, &dim, 1, &dim, &i1,
													 &i2, &i1, &i2, 0);
				%s_execute(plan);
			}, p, p, p));
		}
	}

	/* --- execute functions --- */

	/* X_execute_dft */
	pragma(mangle, format(q{%s_execute_dft}, p))
	mixin(format(q{
void %s_execute_dft(%s_plan p, T *i, T *o);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T i;
				int[] n = [1];
				auto plan = %s_plan_dft(0, n.ptr, &i, &i, 1, 0);
				%s_execute_dft(plan, &i, &i);
			}, p, p));
		}
	}

	/* X_execute_split_dft */
	pragma(mangle, format(q{%s_execute_split_dft}, p))
	mixin(format(q{
void %s_execute_split_dft(%s_plan p, R *ri, R *ii, R *ro, R *io);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				T i;
				R re, im;
				int[] n = [1];
				auto plan = %s_plan_dft(0, n.ptr, &i, &i, 1, 0);
				%s_execute_split_dft(plan, &re, &im, &re, &im);
			}, p, p));
		}
	}

	/* --- plan r2c functions --- */

	/* X_plan_dft_r2c */
	pragma(mangle, format(q{%s_plan_dft_r2c}, p))
	mixin(format(q{
%s_plan %s_plan_dft_r2c(int rank, int *n, R *i, T *o, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				R i; T o;
				int[] n = [1];
				auto plan = %s_plan_dft_r2c(0, n.ptr, &i, &o, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_dft_r2c_1d */
	pragma(mangle, format(q{%s_plan_dft_r2c_1d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_r2c_1d(int n, R *i, T *o, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				R i; T o;
				auto plan = %s_plan_dft_r2c_1d(1, &i, &o, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_dft_r2c_2d */
	pragma(mangle, format(q{%s_plan_dft_r2c_2d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_r2c_2d(int n0, int n1, R *i, T *o, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				R i; T o;
				auto plan = %s_plan_dft_r2c_2d(1, 1, &i, &o, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_dft_r2c_3d */
	pragma(mangle, format(q{%s_plan_dft_r2c_3d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_r2c_3d(int n0, int n1, int n2, R *i, T *o, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				R i; T o;
				int[] n = [1];
				auto plan = %s_plan_dft_r2c_3d(1, 1, 1, &i, &o, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* X_plan_many_dft_r2c */
	pragma(mangle, format(q{%s_plan_many_dft_r2c}, p))
	mixin(format(q{
%s_plan %s_plan_many_dft_r2c(int rank, int *n, int howmany, R *i, int *inembed,
							 int istride, int idist, T *o, int *onembed,
							 int ostride, int odist, uint flags);
}, p, p));
	version(fftwunittests) {
		unittest {
			mixin(format(q{
				R i; T o;
				int[] n = [1, 1];
				auto plan = %s_plan_many_dft_r2c(2, n.ptr, 1, &i, n.ptr, 1, 0,
												 &o, n.ptr, 1, 0, 0);
				%s_execute(plan);
			}, p, p));
		}
	}

	/* --- plan c2r functions --- */

	/* X_plan_dft_c2r */
	pragma(mangle, format(q{%s_plan_dft_c2r}, p))
	mixin(format(q{
%s_plan %s_plan_dft(int rank, int *n, T *i, R *o, uint flags);
}, p, p));

	/* X_plan_dft_c2r_1d */
	pragma(mangle, format(q{%s_plan_dft_c2r_1d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_c2r_1d(int n, T *i, R *o, uint flags);
}, p, p));

	/* X_plan_dft_c2r_2d */
	pragma(mangle, format(q{%s_plan_dft_c2r_2d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_c2r_2d(int n0, int n1, T *i, R *o, uint flags);
}, p, p));

	/* X_plan_dft_c2r_3d */
	pragma(mangle, format(q{%s_plan_dft_c2r_3d}, p))
	mixin(format(q{
%s_plan %s_plan_dft_c2r_3d(int n0, int n1, int n2, T *i, R *o, uint flags);
}, p, p));

	/* X_plan_many_dft_c2r */
	pragma(mangle, format(q{%s_plan_many_dft_c2r}, p))
	mixin(format(q{
%s_plan %s_plan_many_dft_c2r(int rank, int *n, int howmany, T *i, int *inembed,
							 int istride, int idist, R *o, int *onembed,
							 int ostride, int odist, uint flags);
}, p, p));

	/* --- guru r2c functions --- */

	/* X_plan_guru_dft_r2c */
	pragma(mangle, format(q{%s_plan_guru_dft_r2c}, p))
	mixin(format(q{
%s_plan %s_plan_guru_dft_r2c(int rank, %s_iodim *dims, int howmany_rank,
							 %s_iodim *howmany_dims, R *i, T *o, uint flags);
}, p, p, p, p));

	/* X_plan_guru_split_dft_r2c */
	pragma(mangle, format(q{%s_plan_guru_split_dft_r2c}, p))
	mixin(format(q{
%s_plan %s_plan_guru_split_dft_r2c(int rank, %s_iodim *dims, int howmany_rank,
								   %s_iodim *howmany_dims, R *i, R *ro,
								   R *io, uint flags);
}, p, p, p, p));

	/* X_plan_guru64_dft_r2c */
	pragma(mangle, format(q{%s_plan_guru64_dft_r2c}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_dft_r2c(int rank, %s_iodim64 *dims, int howmany_rank,
							   %s_iodim64 *howmany_dims, R *i, T *o,
							   uint flags);
}, p, p, p, p));

	/* X_plan_guru64_split_dft_r2c */
	pragma(mangle, format(q{%s_plan_guru64_split_dft_r2c}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_split_dft_r2c(int rank, %s_iodim64 *dims,
									 int howmany_rk, %s_iodim64 *howmany_dims,
									 R *i, R *ro, R *io, uint flags);
}, p, p, p, p));

	/* --- guru c2r functions --- */

	/* X_plan_guru_dft_c2r */
	pragma(mangle, format(q{%s_plan_guru_dft_c2r}, p))
	mixin(format(q{
%s_plan %s_plan_guru_dft_c2r(int rank, %s_iodim *dims, int howmany_rank,
							 %s_iodim *howmany_dims, T *i, R *o, uint flags);
}, p, p, p, p));

	/* X_plan_guru_split_dft_c2r */
	pragma(mangle, format(q{%s_plan_guru_split_dft_c2r}, p))
	mixin(format(q{
%s_plan %s_plan_guru_split_dft_c2r(int rank, %s_iodim *dims, int howmany_rank,
								   %s_iodim *howmany_dims, R *ri, R *ii,
								   R *o, uint flags);
}, p, p, p, p));

	/* X_plan_guru64_dft_c2r */
	pragma(mangle, format(q{%s_plan_guru64_dft_c2r}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_dft_c2r(int rank, %s_iodim64 *dims, int howmany_rank,
							   %s_iodim64 *howmany_dims, T *i, R *o,
							   uint flags);
}, p, p, p, p));

	/* X_plan_guru64_split_dft_c2r */
	pragma(mangle, format(q{%s_plan_guru64_split_dft_c2r}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_split_dft_c2r(int rank, %s_iodim64 *dims,
									 int howmany_rk, %s_iodim64 *howmany_dims,
									 R *ri, R *ii, R *o, uint flags);
}, p, p, p, p));

	/* --- execute r2c & c2r functions --- */

	/* X_execute_dft_r2c */
	pragma(mangle, format(q{%s_execute_dft_r2c}, p))
	mixin(format(q{
void %s_execute_dft_r2c(%s_plan p, R *i, T *o);
}, p, p));

	/* X_execute_dft_c2r */
	pragma(mangle, format(q{%s_execute_dft_c2r}, p))
	mixin(format(q{
void %s_execute_dft_c2r(%s_plan p, T *i, R *o);
}, p, p));

	/* X_execute_split_dft_r2c */
	pragma(mangle, format(q{%s_execute_split_dft_r2c}, p))
	mixin(format(q{
void %s_execute_split_dft_r2c(%s_plan p, R *i, R *ro, R *io);
}, p, p));

	/* X_execute_split_dft_c2r */
	pragma(mangle, format(q{%s_execute_split_dft_c2r}, p))
	mixin(format(q{
void %s_execute_split_dft_c2r(%s_plan p, R *ri, R *ii, R *o);
}, p, p));

	/* --- plan r2r functions --- */

	/* X_plan_r2r */
	pragma(mangle, format(q{%s_plan_r2r}, p))
	mixin(format(q{
%s_plan %s_plan_r2r(int rank, int *n, R *i, R *o, %s_r2r_kind kind,
					uint flags);
}, p, p, p));

	/* X_plan_r2r_1d */
	pragma(mangle, format(q{%s_plan_r2r_1d}, p))
	mixin(format(q{
%s_plan %s_plan_r2r_1d(int n, R *i, R *o, %s_r2r_kind kind, uint flags);
}, p, p, p));

	/* X_plan_r2r_2d */
	pragma(mangle, format(q{%s_plan_r2r_2d}, p))
	mixin(format(q{
%s_plan %s_plan_r2r_2d(int n0, int n1, R *i, R *o, %s_r2r_kind kind0,
					   %s_r2r_kind kind1, uint flags);
}, p, p, p, p));

	/* X_plan_r2r_3d */
	pragma(mangle, format(q{%s_plan_r2r_3d}, p))
	mixin(format(q{
%s_plan %s_plan_r2r_3d(int n0, int n1, int n2, R *i, R *o,
					   %s_r2r_kind kind0, %s_r2r_kind kind1,
					   %s_r2r_kind kind2, uint flags);
}, p, p, p, p, p));

	/* X_plan_many_r2r */
	pragma(mangle, format(q{%s_plan_many_r2r}, p))
	mixin(format(q{
%s_plan %s_plan_many_r2r(int rank, int *n, int howmany, R *i, int *inembed,
						 int istride, int idist, R *o, int *onembed,
						 int ostride, int odist, %s_r2r_kind *k, uint flags);
}, p, p, p));

	/* --- guru r2r functions --- */

	/* X_plan_guru_r2r */
	pragma(mangle, format(q{%s_plan_guru_r2r}, p))
	mixin(format(q{
%s_plan %s_plan_guru_r2r(int rank, %s_iodim *dims, int howmany_rank,
						 %s_iodim *howmany_dims, R *i, R *o,
						 %s_r2r_kind *kind, uint flags);
}, p, p, p, p, p));

	/* X_plan_guru64_r2r */
	pragma(mangle, format(q{%s_plan_guru64_r2r}, p))
	mixin(format(q{
%s_plan %s_plan_guru64_r2r(int rank, %s_iodim64 *dims, int howmany_rank,
						   %s_iodim64 *howmany_dims, R *i, R *o,
						   %s_r2r_kind *kind, uint flags);
}, p, p, p, p, p));

	/* --- execute r2r functions --- */

	/* X_execute_r2r */
	pragma(mangle, format(q{%s_execute_r2r}, p))
	mixin(format(q{
void %s_execute_r2r(%s_plan p, R *i, R *o);
}, p, p));

	/* --- other functions --- */

	/* X_destroy_plan */
	pragma(mangle, format(q{%s_destroy_plan}, p))
	mixin(format(q{
void %s_destroy_plan(%s_plan p);
}, p, p));

	/* X_forget_wisdom */
	pragma(mangle, format(q{%s_forget_wisdom}, p))
	mixin(format(q{
void %s_forget_wisdom();
}, p));

	/* X_cleanup */
	pragma(mangle, format(q{%s_cleanup}, p))
	mixin(format(q{
void %s_cleanup();
}, p));

	/* X_set_timelimit */
	pragma(mangle, format(q{%s_set_timelimit}, p))
	mixin(format(q{
void %s_set_timelimit(double);
}, p));

	/* X_plan_with_nthreads */
	pragma(mangle, format(q{%s_plan_with_nthreads}, p))
	mixin(format(q{
void %s_plan_with_nthreads(int nthreads);
}, p));
	/* X_init_threads */
	pragma(mangle, format(q{%s_init_threads}, p))
	mixin(format(q{
int %s_init_threads();
}, p));
	/* X_cleanup_threads */
	pragma(mangle, format(q{%s_cleanup_threads}, p))
	mixin(format(q{
void %s_cleanup_threads();
}, p));

	/* X_export_wisdom_to_file */
	pragma(mangle, format(q{%s_export_wisdom_to_file}, p))
	mixin(format(q{
void %s_export_wisdom_to_file(FILE *output_file);
}, p));
	/* X_export_wisdom_to_string */
	pragma(mangle, format(q{%s_export_wisdom_to_string}, p))
	mixin(format(q{
char *%s_export_wisdom_to_string();
}, p));
	/* X_export_wisdom */
	pragma(mangle, format(q{%s_export_wisdom}, p))
	mixin(format(q{
void %s_export_wisdom(void function(char c, void *) write_char, void *data);
}, p));

	/* X_import_system_wisdom */
	pragma(mangle, format(q{%s_import_system_wisdom}, p))
	mixin(format(q{
int %s_import_system_wisdom();
}, p));
	/* X_import_wisdom_from_file */
	pragma(mangle, format(q{%s_import_wisdom_from_file}, p))
	mixin(format(q{
int %s_import_wisdom_from_file(FILE *input_file);
}, p));
	/* X_import_wisdom_from_string */
	pragma(mangle, format(q{%s_import_wisdom_from_string}, p))
	mixin(format(q{
int %s_import_wisdom_from_string(char *input_string);
}, p));
	/* X_import_wisdom */
	pragma(mangle, format(q{%s_import_wisdom}, p))
	mixin(format(q{
int %s_import_wisdom(int function(void *) read_char, void *data);
}, p));

	/* X_fprint_plan */
	pragma(mangle, format(q{%s_fprint_plan}, p))
	mixin(format(q{
void %s_fprint_plan(%s_plan p, FILE *output_file);
}, p, p));
	/* X_print_plan */
	pragma(mangle, format(q{%s_print_plan}, p))
	mixin(format(q{
void %s_print_plan(%s_plan p);
}, p, p));

	/* X_malloc */
	pragma(mangle, format(q{%s_malloc}, p))
	mixin(format(q{
void *%s_malloc(size_t n);
}, p));
	/* X_free */
	pragma(mangle, format(q{%s_free}, p))
	mixin(format(q{
void %s_free(void *);
}, p));

	/* X_flops */
	pragma(mangle, format(q{%s_flops}, p))
	mixin(format(q{
void %s_flops(%s_plan p, double *add, double *mul, double *fmas);
}, p, p));
	/* X_estimate_cost */
	pragma(mangle, format(q{%s_estimate_cost}, p))
	mixin(format(q{
double %s_estimate_cost(%s_plan p);
}, p, p));

	/* X_version */
	pragma(mangle, format(q{%s_version}, p))
	mixin(format(q{
extern __gshared char %s_version[];
}, p));

	/* X_cc */
	pragma(mangle, format(q{%s_cc}, p))
	mixin(format(q{
extern __gshared const char %s_cc[];
}, p));

	/* X_codelet_optim */
	pragma(mangle, format(q{%s_codelet_optim}, p))
	mixin(format(q{
extern __gshared char %s_codelet_optim[];
}, p));
}

alias cdouble fftw_complex;
mixin Define_API!("fftw", double, fftw_complex);

alias cfloat fftwf_complex;
mixin Define_API!("fftwf", float, fftwf_complex);

alias creal fftwl_complex;
mixin Define_API!("fftwl", real, fftwl_complex);

enum : int { FFTW_FORWARD = -1, FFTW_BACKWARD = 1 };

enum { FFTW_NO_TIMELIMIT = -1.0 };

enum : uint {
	FFTW_MEASURE = 0u,
	FFTW_DESTROY_INPUT = 1u,
	FFTW_UNALIGNED = 1u << 1,
	FFTW_CONSERVE_MEMORY = 1u << 2,
	FFTW_EXHAUSTIVE = 1u << 3, /* NO_EXHAUSTIVE is default */
	FFTW_PRESERVE_INPUT = 1u << 4, /* cancels FFTW_DESTROY_INPUT */
	FFTW_PATIENT = 1u << 5, /* IMPATIENT is default */
	FFTW_ESTIMATE = 1u << 6,

	FFTW_ESTIMATE_PATIENT       = 1u << 7,
	FFTW_BELIEVE_PCOST          = 1u << 8,
	FFTW_NO_DFT_R2HC            = 1u << 9,
	FFTW_NO_NONTHREADED         = 1u << 10,
	FFTW_NO_BUFFERING           = 1u << 11,
	FFTW_NO_INDIRECT_OP         = 1u << 12,
	FFTW_ALLOW_LARGE_GENERIC    = 1u << 13, /* NO_LARGE_GENERIC is default */
	FFTW_NO_RANK_SPLITS         = 1u << 14,
	FFTW_NO_VRANK_SPLITS        = 1u << 15,
	FFTW_NO_VRECURSE            = 1u << 16,
	FFTW_NO_SIMD                = 1u << 17,
	FFTW_NO_SLOW                = 1u << 18,
	FFTW_NO_FIXED_RADIX_LARGE_N = 1u << 19,
	FFTW_ALLOW_PRUNING          = 1u << 20,
	FFTW_WISDOM_ONLY            = 1u << 21
}

