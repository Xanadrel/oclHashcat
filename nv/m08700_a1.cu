/**
 * Author......: Jens Steube <jens.steube@gmail.com>
 * License.....: MIT
 */

#define _LOTUS6_

#include "include/constants.h"
#include "include/kernel_vendor.h"

#ifdef  VLIW1
#define VECT_SIZE1
#endif

#ifdef  VLIW2
#define VECT_SIZE1
#endif

#define DGST_R0 0
#define DGST_R1 1
#define DGST_R2 2
#define DGST_R3 3

#include "include/kernel_functions.c"
#include "types_nv.c"
#include "common_nv.c"

#ifdef  VECT_SIZE1
#define VECT_COMPARE_S "check_single_vect1_comp4.c"
#define VECT_COMPARE_M "check_multi_vect1_comp4.c"
#endif

#ifdef  VECT_SIZE2
#define VECT_COMPARE_S "check_single_vect2_comp4.c"
#define VECT_COMPARE_M "check_multi_vect2_comp4.c"
#endif

__device__ __constant__ u32 lotus_magic_table[256] =
{
  0xbd, 0x56, 0xea, 0xf2, 0xa2, 0xf1, 0xac, 0x2a,
  0xb0, 0x93, 0xd1, 0x9c, 0x1b, 0x33, 0xfd, 0xd0,
  0x30, 0x04, 0xb6, 0xdc, 0x7d, 0xdf, 0x32, 0x4b,
  0xf7, 0xcb, 0x45, 0x9b, 0x31, 0xbb, 0x21, 0x5a,
  0x41, 0x9f, 0xe1, 0xd9, 0x4a, 0x4d, 0x9e, 0xda,
  0xa0, 0x68, 0x2c, 0xc3, 0x27, 0x5f, 0x80, 0x36,
  0x3e, 0xee, 0xfb, 0x95, 0x1a, 0xfe, 0xce, 0xa8,
  0x34, 0xa9, 0x13, 0xf0, 0xa6, 0x3f, 0xd8, 0x0c,
  0x78, 0x24, 0xaf, 0x23, 0x52, 0xc1, 0x67, 0x17,
  0xf5, 0x66, 0x90, 0xe7, 0xe8, 0x07, 0xb8, 0x60,
  0x48, 0xe6, 0x1e, 0x53, 0xf3, 0x92, 0xa4, 0x72,
  0x8c, 0x08, 0x15, 0x6e, 0x86, 0x00, 0x84, 0xfa,
  0xf4, 0x7f, 0x8a, 0x42, 0x19, 0xf6, 0xdb, 0xcd,
  0x14, 0x8d, 0x50, 0x12, 0xba, 0x3c, 0x06, 0x4e,
  0xec, 0xb3, 0x35, 0x11, 0xa1, 0x88, 0x8e, 0x2b,
  0x94, 0x99, 0xb7, 0x71, 0x74, 0xd3, 0xe4, 0xbf,
  0x3a, 0xde, 0x96, 0x0e, 0xbc, 0x0a, 0xed, 0x77,
  0xfc, 0x37, 0x6b, 0x03, 0x79, 0x89, 0x62, 0xc6,
  0xd7, 0xc0, 0xd2, 0x7c, 0x6a, 0x8b, 0x22, 0xa3,
  0x5b, 0x05, 0x5d, 0x02, 0x75, 0xd5, 0x61, 0xe3,
  0x18, 0x8f, 0x55, 0x51, 0xad, 0x1f, 0x0b, 0x5e,
  0x85, 0xe5, 0xc2, 0x57, 0x63, 0xca, 0x3d, 0x6c,
  0xb4, 0xc5, 0xcc, 0x70, 0xb2, 0x91, 0x59, 0x0d,
  0x47, 0x20, 0xc8, 0x4f, 0x58, 0xe0, 0x01, 0xe2,
  0x16, 0x38, 0xc4, 0x6f, 0x3b, 0x0f, 0x65, 0x46,
  0xbe, 0x7e, 0x2d, 0x7b, 0x82, 0xf9, 0x40, 0xb5,
  0x1d, 0x73, 0xf8, 0xeb, 0x26, 0xc7, 0x87, 0x97,
  0x25, 0x54, 0xb1, 0x28, 0xaa, 0x98, 0x9d, 0xa5,
  0x64, 0x6d, 0x7a, 0xd4, 0x10, 0x81, 0x44, 0xef,
  0x49, 0xd6, 0xae, 0x2e, 0xdd, 0x76, 0x5c, 0x2f,
  0xa7, 0x1c, 0xc9, 0x09, 0x69, 0x9a, 0x83, 0xcf,
  0x29, 0x39, 0xb9, 0xe9, 0x4c, 0xff, 0x43, 0xab,
};

#ifdef VECT_SIZE1
#define BOX(S,i) u32x ((S)[(i)])
#endif

#ifdef VECT_SIZE2
#define BOX(S,i) u32x ((S)[(i).x], (S)[(i).y])
#endif

#ifdef VECT_SIZE1
#define uint_to_hex_upper8(i) l_bin2asc[(i)]
#endif

#ifdef VECT_SIZE2
#define uint_to_hex_upper8(i) u32x (l_bin2asc[(i).x], l_bin2asc[(i).y])
#endif

__device__ __constant__ char c_bin2asc[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

__device__ __shared__ short l_bin2asc[256];

__device__ static void lotus_mix (u32x *in, u32 s_lotus_magic_table[256])
{
  u32x p = 0;

  for (int i = 0; i < 18; i++)
  {
    u32 s = 48;

    #pragma unroll 12
    for (int j = 0; j < 12; j++)
    {
      u32x tmp_in = in[j];
      u32x tmp_out = 0;

      p = (p + s--) & 0xff; p = ((tmp_in >>  0) & 0xff) ^ BOX (s_lotus_magic_table, p); tmp_out |= p <<  0;
      p = (p + s--) & 0xff; p = ((tmp_in >>  8) & 0xff) ^ BOX (s_lotus_magic_table, p); tmp_out |= p <<  8;
      p = (p + s--) & 0xff; p = ((tmp_in >> 16) & 0xff) ^ BOX (s_lotus_magic_table, p); tmp_out |= p << 16;
      p = (p + s--) & 0xff; p = ((tmp_in >> 24) & 0xff) ^ BOX (s_lotus_magic_table, p); tmp_out |= p << 24;

      in[j] = tmp_out;
    }
  }
}

__device__ static void lotus_transform_password (u32x *in, u32x *out, u32 s_lotus_magic_table[256])
{
  u32x t = out[3] >> 24;

  u32x c;

  for (int i = 0; i < 4; i++)
  {
    t ^= (in[i] >>  0) & 0xff; c = BOX (s_lotus_magic_table, t); out[i] ^= c <<  0; t = ((out[i] >>  0) & 0xff);
    t ^= (in[i] >>  8) & 0xff; c = BOX (s_lotus_magic_table, t); out[i] ^= c <<  8; t = ((out[i] >>  8) & 0xff);
    t ^= (in[i] >> 16) & 0xff; c = BOX (s_lotus_magic_table, t); out[i] ^= c << 16; t = ((out[i] >> 16) & 0xff);
    t ^= (in[i] >> 24) & 0xff; c = BOX (s_lotus_magic_table, t); out[i] ^= c << 24; t = ((out[i] >> 24) & 0xff);
  }
}

__device__ static void pad (u32x w[4], const u32 len)
{
  const u32 val = 16 - len;

  const u32 mask1 = val << 24;

  const u32 mask2 = val << 16
                   | val << 24;

  const u32 mask3 = val <<  8
                   | val << 16
                   | val << 24;

  const u32 mask4 = val <<  0
                   | val <<  8
                   | val << 16
                   | val << 24;

  switch (len)
  {
    case  0:  w[0]  = mask4;
              w[1]  = mask4;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  1:  w[0] |= mask3;
              w[1]  = mask4;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  2:  w[0] |= mask2;
              w[1]  = mask4;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  3:  w[0] |= mask1;
              w[1]  = mask4;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  4:  w[1]  = mask4;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  5:  w[1] |= mask3;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  6:  w[1] |= mask2;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  7:  w[1] |= mask1;
              w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  8:  w[2]  = mask4;
              w[3]  = mask4;
              break;
    case  9:  w[2] |= mask3;
              w[3]  = mask4;
              break;
    case 10:  w[2] |= mask2;
              w[3]  = mask4;
              break;
    case 11:  w[2] |= mask1;
              w[3]  = mask4;
              break;
    case 12:  w[3]  = mask4;
              break;
    case 13:  w[3] |= mask3;
              break;
    case 14:  w[3] |= mask2;
              break;
    case 15:  w[3] |= mask1;
              break;
  }
}

__device__ static void mdtransform_norecalc (u32x state[4], u32x block[4], u32 s_lotus_magic_table[256])
{
	u32x x[12];

  x[ 0] = state[0];
  x[ 1] = state[1];
  x[ 2] = state[2];
  x[ 3] = state[3];
  x[ 4] = block[0];
  x[ 5] = block[1];
  x[ 6] = block[2];
  x[ 7] = block[3];
  x[ 8] = state[0] ^ block[0];
  x[ 9] = state[1] ^ block[1];
  x[10] = state[2] ^ block[2];
  x[11] = state[3] ^ block[3];

  lotus_mix (x, s_lotus_magic_table);

  state[0] = x[0];
  state[1] = x[1];
  state[2] = x[2];
  state[3] = x[3];
}

__device__ static void mdtransform (u32x state[4], u32x checksum[4], u32x block[4], u32 s_lotus_magic_table[256])
{
  mdtransform_norecalc (state, block, s_lotus_magic_table);

  lotus_transform_password (block, checksum, s_lotus_magic_table);
}

__device__ static void domino_big_md (const u32x saved_key[16], const u32 size, u32x state[4], u32 s_lotus_magic_table[256])
{
	u32x checksum[4];

  checksum[0] = 0;
  checksum[1] = 0;
  checksum[2] = 0;
  checksum[3] = 0;

	u32x block[4];

  block[0] = 0;
  block[1] = 0;
  block[2] = 0;
  block[3] = 0;

  u32 curpos;
  u32 idx;

  for (curpos = 0, idx = 0; curpos + 16 < size; curpos += 16, idx += 4)
  {
    block[0] = saved_key[idx + 0];
    block[1] = saved_key[idx + 1];
    block[2] = saved_key[idx + 2];
    block[3] = saved_key[idx + 3];

    mdtransform (state, checksum, block, s_lotus_magic_table);
  }

	u32 left = size - curpos;

  block[0] = saved_key[idx + 0];
  block[1] = saved_key[idx + 1];
  block[2] = saved_key[idx + 2];
  block[3] = saved_key[idx + 3];

  mdtransform (state, checksum, block, s_lotus_magic_table);

	mdtransform_norecalc (state, checksum, s_lotus_magic_table);
}

__device__ __constant__ comb_t c_combs[1024];

extern "C" __global__ void __launch_bounds__ (256, 1) m08700_m04 (const pw_t *pws, const gpu_rule_t *rules_buf, const comb_t *combs_buf, const bf_t *bfs_buf, const void *tmps, void *hooks, const u32 *bitmaps_buf_s1_a, const u32 *bitmaps_buf_s1_b, const u32 *bitmaps_buf_s1_c, const u32 *bitmaps_buf_s1_d, const u32 *bitmaps_buf_s2_a, const u32 *bitmaps_buf_s2_b, const u32 *bitmaps_buf_s2_c, const u32 *bitmaps_buf_s2_d, plain_t *plains_buf, const digest_t *digests_buf, u32 *hashes_shown, const salt_t *salt_bufs, const void *esalt_bufs, u32 *d_return_buf, u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 combs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * modifier
   */

  const u32 lid = threadIdx.x;

  /**
   * base
   */

  const u32 gid = (blockIdx.x * blockDim.x) + threadIdx.x;

  /**
   * bin2asc table
   */

  l_bin2asc[lid] = c_bin2asc[(lid >> 0) & 15] << 8
                 | c_bin2asc[(lid >> 4) & 15] << 0;

  __syncthreads ();

  /**
   * sbox
   */

  __shared__ u32 s_lotus_magic_table[256];

  s_lotus_magic_table[lid] = lotus_magic_table[lid];

  __syncthreads ();

  if (gid >= gid_max) return;

  /**
   * base
    */

  u32x wordl0[4];

  wordl0[0] = pws[gid].i[ 0];
  wordl0[1] = pws[gid].i[ 1];
  wordl0[2] = pws[gid].i[ 2];
  wordl0[3] = pws[gid].i[ 3];

  u32x wordl1[4];

  wordl1[0] = pws[gid].i[ 4];
  wordl1[1] = pws[gid].i[ 5];
  wordl1[2] = pws[gid].i[ 6];
  wordl1[3] = pws[gid].i[ 7];

  u32x wordl2[4];

  wordl2[0] = 0;
  wordl2[1] = 0;
  wordl2[2] = 0;
  wordl2[3] = 0;

  u32x wordl3[4];

  wordl3[0] = 0;
  wordl3[1] = 0;
  wordl3[2] = 0;
  wordl3[3] = 0;

  const u32 pw_l_len = pws[gid].pw_len;

  if (combs_mode == COMBINATOR_MODE_BASE_RIGHT)
  {
    switch_buffer_by_offset (wordl0, wordl1, wordl2, wordl3, c_combs[0].pw_len);
  }

  /**
   * salt
   */

  const u32 salt0 = salt_bufs[salt_pos].salt_buf[0];
  const u32 salt1 = salt_bufs[salt_pos].salt_buf[1] & 0xff | '(' << 8;

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < combs_cnt; il_pos++)
  {
    const u32 pw_r_len = c_combs[il_pos].pw_len;

    const u32 pw_len = pw_l_len + pw_r_len;

    u32 wordr0[4];

    wordr0[0] = c_combs[il_pos].i[0];
    wordr0[1] = c_combs[il_pos].i[1];
    wordr0[2] = c_combs[il_pos].i[2];
    wordr0[3] = c_combs[il_pos].i[3];

    u32 wordr1[4];

    wordr1[0] = c_combs[il_pos].i[4];
    wordr1[1] = c_combs[il_pos].i[5];
    wordr1[2] = c_combs[il_pos].i[6];
    wordr1[3] = c_combs[il_pos].i[7];

    u32 wordr2[4];

    wordr2[0] = 0;
    wordr2[1] = 0;
    wordr2[2] = 0;
    wordr2[3] = 0;

    u32 wordr3[4];

    wordr3[0] = 0;
    wordr3[1] = 0;
    wordr3[2] = 0;
    wordr3[3] = 0;

    if (combs_mode == COMBINATOR_MODE_BASE_LEFT)
    {
      switch_buffer_by_offset (wordr0, wordr1, wordr2, wordr3, pw_l_len);
    }

    u32x w[16];

    w[ 0] = wordl0[0] | wordr0[0];
    w[ 1] = wordl0[1] | wordr0[1];
    w[ 2] = wordl0[2] | wordr0[2];
    w[ 3] = wordl0[3] | wordr0[3];
    w[ 4] = wordl1[0] | wordr1[0];
    w[ 5] = wordl1[1] | wordr1[1];
    w[ 6] = wordl1[2] | wordr1[2];
    w[ 7] = wordl1[3] | wordr1[3];
    w[ 8] = wordl2[0] | wordr2[0];
    w[ 9] = wordl2[1] | wordr2[1];
    w[10] = wordl2[2] | wordr2[2];
    w[11] = wordl2[3] | wordr2[3];
    w[12] = wordl3[0] | wordr3[0];
    w[13] = wordl3[1] | wordr3[1];
    w[14] = wordl3[2] | wordr3[2];
    w[15] = wordl3[3] | wordr3[3];

    u32x state[4];

    state[0] = 0;
    state[1] = 0;
    state[2] = 0;
    state[3] = 0;

    /**
     * padding
     */

    if (pw_len < 16)
    {
      pad (&w[ 0], pw_len & 0xf);
    }
    else if (pw_len < 32)
    {
      pad (&w[ 4], pw_len & 0xf);
    }
    else if (pw_len < 48)
    {
      pad (&w[ 8], pw_len & 0xf);
    }
    else if (pw_len < 64)
    {
      pad (&w[12], pw_len & 0xf);
    }

    domino_big_md (w, pw_len, state, s_lotus_magic_table);

    const u32x w0_t = uint_to_hex_upper8 ((state[0] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[0] >>  8) & 255) << 16;
    const u32x w1_t = uint_to_hex_upper8 ((state[0] >> 16) & 255) <<  0
                     | uint_to_hex_upper8 ((state[0] >> 24) & 255) << 16;
    const u32x w2_t = uint_to_hex_upper8 ((state[1] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[1] >>  8) & 255) << 16;
    const u32x w3_t = uint_to_hex_upper8 ((state[1] >> 16) & 255) <<  0
                     | uint_to_hex_upper8 ((state[1] >> 24) & 255) << 16;
    const u32x w4_t = uint_to_hex_upper8 ((state[2] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[2] >>  8) & 255) << 16;
    const u32x w5_t = uint_to_hex_upper8 ((state[2] >> 16) & 255) <<  0
                     | uint_to_hex_upper8 ((state[2] >> 24) & 255) << 16;
    const u32x w6_t = uint_to_hex_upper8 ((state[3] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[3] >>  8) & 255) << 16;
    //const u32x w7_t = uint_to_hex_upper8 ((state[3] >> 16) & 255) <<  0
    //                 | uint_to_hex_upper8 ((state[3] >> 24) & 255) << 16;

    const u32 pade = 0x0e0e0e0e;

    w[ 0] = salt0;
    w[ 1] = salt1      | w0_t << 16;
    w[ 2] = w0_t >> 16 | w1_t << 16;
    w[ 3] = w1_t >> 16 | w2_t << 16;
    w[ 4] = w2_t >> 16 | w3_t << 16;
    w[ 5] = w3_t >> 16 | w4_t << 16;
    w[ 6] = w4_t >> 16 | w5_t << 16;
    w[ 7] = w5_t >> 16 | w6_t << 16;
    w[ 8] = w6_t >> 16 | pade << 16; // | w7_t <<  8;
    w[ 9] = pade;
    w[10] = pade;
    w[11] = pade;
    w[12] = 0;
    w[13] = 0;
    w[14] = 0;
    w[15] = 0;

    state[0] = 0;
    state[1] = 0;
    state[2] = 0;
    state[3] = 0;

    domino_big_md (w, 34, state, s_lotus_magic_table);

    u32x a = state[0] & 0xffffffff;
    u32x b = state[1] & 0xffffffff;
    u32x c = state[2] & 0x000000ff;
    u32x d = state[3] & 0x00000000;

    const u32x r0 = a;
    const u32x r1 = b;
    const u32x r2 = c;
    const u32x r3 = d;

    #include VECT_COMPARE_M
  }
}

extern "C" __global__ void __launch_bounds__ (256, 1) m08700_m08 (const pw_t *pws, const gpu_rule_t *rules_buf, const comb_t *combs_buf, const bf_t *bfs_buf, const void *tmps, void *hooks, const u32 *bitmaps_buf_s1_a, const u32 *bitmaps_buf_s1_b, const u32 *bitmaps_buf_s1_c, const u32 *bitmaps_buf_s1_d, const u32 *bitmaps_buf_s2_a, const u32 *bitmaps_buf_s2_b, const u32 *bitmaps_buf_s2_c, const u32 *bitmaps_buf_s2_d, plain_t *plains_buf, const digest_t *digests_buf, u32 *hashes_shown, const salt_t *salt_bufs, const void *esalt_bufs, u32 *d_return_buf, u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

extern "C" __global__ void __launch_bounds__ (256, 1) m08700_m16 (const pw_t *pws, const gpu_rule_t *rules_buf, const comb_t *combs_buf, const bf_t *bfs_buf, const void *tmps, void *hooks, const u32 *bitmaps_buf_s1_a, const u32 *bitmaps_buf_s1_b, const u32 *bitmaps_buf_s1_c, const u32 *bitmaps_buf_s1_d, const u32 *bitmaps_buf_s2_a, const u32 *bitmaps_buf_s2_b, const u32 *bitmaps_buf_s2_c, const u32 *bitmaps_buf_s2_d, plain_t *plains_buf, const digest_t *digests_buf, u32 *hashes_shown, const salt_t *salt_bufs, const void *esalt_bufs, u32 *d_return_buf, u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

extern "C" __global__ void __launch_bounds__ (256, 1) m08700_s04 (const pw_t *pws, const gpu_rule_t *rules_buf, const comb_t *combs_buf, const bf_t *bfs_buf, const void *tmps, void *hooks, const u32 *bitmaps_buf_s1_a, const u32 *bitmaps_buf_s1_b, const u32 *bitmaps_buf_s1_c, const u32 *bitmaps_buf_s1_d, const u32 *bitmaps_buf_s2_a, const u32 *bitmaps_buf_s2_b, const u32 *bitmaps_buf_s2_c, const u32 *bitmaps_buf_s2_d, plain_t *plains_buf, const digest_t *digests_buf, u32 *hashes_shown, const salt_t *salt_bufs, const void *esalt_bufs, u32 *d_return_buf, u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 combs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * modifier
   */

  const u32 lid = threadIdx.x;

  /**
   * base
   */

  const u32 gid = (blockIdx.x * blockDim.x) + threadIdx.x;

  /**
   * bin2asc table
   */

  l_bin2asc[lid] = c_bin2asc[(lid >> 0) & 15] << 8
                 | c_bin2asc[(lid >> 4) & 15] << 0;

  __syncthreads ();

  /**
   * sbox
   */

  __shared__ u32 s_lotus_magic_table[256];

  s_lotus_magic_table[lid] = lotus_magic_table[lid];

  __syncthreads ();

  if (gid >= gid_max) return;

  /**
   * base
   */

  u32x wordl0[4];

  wordl0[0] = pws[gid].i[ 0];
  wordl0[1] = pws[gid].i[ 1];
  wordl0[2] = pws[gid].i[ 2];
  wordl0[3] = pws[gid].i[ 3];

  u32x wordl1[4];

  wordl1[0] = pws[gid].i[ 4];
  wordl1[1] = pws[gid].i[ 5];
  wordl1[2] = pws[gid].i[ 6];
  wordl1[3] = pws[gid].i[ 7];

  u32x wordl2[4];

  wordl2[0] = 0;
  wordl2[1] = 0;
  wordl2[2] = 0;
  wordl2[3] = 0;

  u32x wordl3[4];

  wordl3[0] = 0;
  wordl3[1] = 0;
  wordl3[2] = 0;
  wordl3[3] = 0;


  const u32 pw_l_len = pws[gid].pw_len;

  if (combs_mode == COMBINATOR_MODE_BASE_RIGHT)
  {
    switch_buffer_by_offset (wordl0, wordl1, wordl2, wordl3, c_combs[0].pw_len);
  }

  /**
   * salt
   */

  const u32 salt0 = salt_bufs[salt_pos].salt_buf[0];
  const u32 salt1 = salt_bufs[salt_pos].salt_buf[1] & 0xff | '(' << 8;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[digests_offset].digest_buf[DGST_R0],
    digests_buf[digests_offset].digest_buf[DGST_R1],
    digests_buf[digests_offset].digest_buf[DGST_R2],
    digests_buf[digests_offset].digest_buf[DGST_R3]
  };

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < combs_cnt; il_pos++)
  {
    const u32 pw_r_len = c_combs[il_pos].pw_len;

    const u32 pw_len = pw_l_len + pw_r_len;

    u32 wordr0[4];

    wordr0[0] = c_combs[il_pos].i[0];
    wordr0[1] = c_combs[il_pos].i[1];
    wordr0[2] = c_combs[il_pos].i[2];
    wordr0[3] = c_combs[il_pos].i[3];

    u32 wordr1[4];

    wordr1[0] = c_combs[il_pos].i[4];
    wordr1[1] = c_combs[il_pos].i[5];
    wordr1[2] = c_combs[il_pos].i[6];
    wordr1[3] = c_combs[il_pos].i[7];

    u32 wordr2[4];

    wordr2[0] = 0;
    wordr2[1] = 0;
    wordr2[2] = 0;
    wordr2[3] = 0;

    u32 wordr3[4];

    wordr3[0] = 0;
    wordr3[1] = 0;
    wordr3[2] = 0;
    wordr3[3] = 0;

    if (combs_mode == COMBINATOR_MODE_BASE_LEFT)
    {
      switch_buffer_by_offset (wordr0, wordr1, wordr2, wordr3, pw_l_len);
    }

    u32x w[16];

    w[ 0] = wordl0[0] | wordr0[0];
    w[ 1] = wordl0[1] | wordr0[1];
    w[ 2] = wordl0[2] | wordr0[2];
    w[ 3] = wordl0[3] | wordr0[3];
    w[ 4] = wordl1[0] | wordr1[0];
    w[ 5] = wordl1[1] | wordr1[1];
    w[ 6] = wordl1[2] | wordr1[2];
    w[ 7] = wordl1[3] | wordr1[3];
    w[ 8] = wordl2[0] | wordr2[0];
    w[ 9] = wordl2[1] | wordr2[1];
    w[10] = wordl2[2] | wordr2[2];
    w[11] = wordl2[3] | wordr2[3];
    w[12] = wordl3[0] | wordr3[0];
    w[13] = wordl3[1] | wordr3[1];
    w[14] = wordl3[2] | wordr3[2];
    w[15] = wordl3[3] | wordr3[3];

    u32x state[4];

    state[0] = 0;
    state[1] = 0;
    state[2] = 0;
    state[3] = 0;

    /**
     * padding
     */

    if (pw_len < 16)
    {
      pad (&w[ 0], pw_len & 0xf);
    }
    else if (pw_len < 32)
    {
      pad (&w[ 4], pw_len & 0xf);
    }
    else if (pw_len < 48)
    {
      pad (&w[ 8], pw_len & 0xf);
    }
    else if (pw_len < 64)
    {
      pad (&w[12], pw_len & 0xf);
    }

    domino_big_md (w, pw_len, state, s_lotus_magic_table);

    const u32x w0_t = uint_to_hex_upper8 ((state[0] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[0] >>  8) & 255) << 16;
    const u32x w1_t = uint_to_hex_upper8 ((state[0] >> 16) & 255) <<  0
                     | uint_to_hex_upper8 ((state[0] >> 24) & 255) << 16;
    const u32x w2_t = uint_to_hex_upper8 ((state[1] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[1] >>  8) & 255) << 16;
    const u32x w3_t = uint_to_hex_upper8 ((state[1] >> 16) & 255) <<  0
                     | uint_to_hex_upper8 ((state[1] >> 24) & 255) << 16;
    const u32x w4_t = uint_to_hex_upper8 ((state[2] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[2] >>  8) & 255) << 16;
    const u32x w5_t = uint_to_hex_upper8 ((state[2] >> 16) & 255) <<  0
                     | uint_to_hex_upper8 ((state[2] >> 24) & 255) << 16;
    const u32x w6_t = uint_to_hex_upper8 ((state[3] >>  0) & 255) <<  0
                     | uint_to_hex_upper8 ((state[3] >>  8) & 255) << 16;
    //const u32x w7_t = uint_to_hex_upper8 ((state[3] >> 16) & 255) <<  0
    //                 | uint_to_hex_upper8 ((state[3] >> 24) & 255) << 16;

    const u32 pade = 0x0e0e0e0e;

    w[ 0] = salt0;
    w[ 1] = salt1      | w0_t << 16;
    w[ 2] = w0_t >> 16 | w1_t << 16;
    w[ 3] = w1_t >> 16 | w2_t << 16;
    w[ 4] = w2_t >> 16 | w3_t << 16;
    w[ 5] = w3_t >> 16 | w4_t << 16;
    w[ 6] = w4_t >> 16 | w5_t << 16;
    w[ 7] = w5_t >> 16 | w6_t << 16;
    w[ 8] = w6_t >> 16 | pade << 16; // | w7_t <<  8;
    w[ 9] = pade;
    w[10] = pade;
    w[11] = pade;
    w[12] = 0;
    w[13] = 0;
    w[14] = 0;
    w[15] = 0;

    state[0] = 0;
    state[1] = 0;
    state[2] = 0;
    state[3] = 0;

    domino_big_md (w, 34, state, s_lotus_magic_table);

    u32x a = state[0] & 0xffffffff;
    u32x b = state[1] & 0xffffffff;
    u32x c = state[2] & 0x000000ff;
    u32x d = state[3] & 0x00000000;

    const u32x r0 = a;
    const u32x r1 = b;
    const u32x r2 = c;
    const u32x r3 = d;

    #include VECT_COMPARE_S
  }
}

extern "C" __global__ void __launch_bounds__ (256, 1) m08700_s08 (const pw_t *pws, const gpu_rule_t *rules_buf, const comb_t *combs_buf, const bf_t *bfs_buf, const void *tmps, void *hooks, const u32 *bitmaps_buf_s1_a, const u32 *bitmaps_buf_s1_b, const u32 *bitmaps_buf_s1_c, const u32 *bitmaps_buf_s1_d, const u32 *bitmaps_buf_s2_a, const u32 *bitmaps_buf_s2_b, const u32 *bitmaps_buf_s2_c, const u32 *bitmaps_buf_s2_d, plain_t *plains_buf, const digest_t *digests_buf, u32 *hashes_shown, const salt_t *salt_bufs, const void *esalt_bufs, u32 *d_return_buf, u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

extern "C" __global__ void __launch_bounds__ (256, 1) m08700_s16 (const pw_t *pws, const gpu_rule_t *rules_buf, const comb_t *combs_buf, const bf_t *bfs_buf, const void *tmps, void *hooks, const u32 *bitmaps_buf_s1_a, const u32 *bitmaps_buf_s1_b, const u32 *bitmaps_buf_s1_c, const u32 *bitmaps_buf_s1_d, const u32 *bitmaps_buf_s2_a, const u32 *bitmaps_buf_s2_b, const u32 *bitmaps_buf_s2_c, const u32 *bitmaps_buf_s2_d, plain_t *plains_buf, const digest_t *digests_buf, u32 *hashes_shown, const salt_t *salt_bufs, const void *esalt_bufs, u32 *d_return_buf, u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 rules_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}
