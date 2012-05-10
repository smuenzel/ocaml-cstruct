(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Printf

open Bigarray
open Array1 

type buf = (char, int8_unsigned_elt, c_layout) Bigarray.Array1.t

type uint8 = int
type uint16 = int
type uint32 = int32

module BE = struct

  let get_uint8 s off =
    Char.code (get s off)

  let get_uint16 s off =
    let a = get_uint8 s off in
    let b = get_uint8 s (off+1) in
    (a lsl 8) + b

  let get_uint32 s off =
    let a = get_uint8 s off in
    let b = get_uint8 s (off+1) in
    let c = get_uint8 s (off+2) in
    let d = get_uint8 s (off+3) in
    let e = (b lsl 16) + (c lsl 8) + d in
    Int32.(add (shift_left (of_int a) 24) (of_int e))

  let get_buffer s off len =
    sub s off len

  let set_uint8 s off v =
    set s off (Char.chr v)

  let set_uint16 s off v =
    set_uint8 s off (v lsr 8);
    set_uint8 s (off+1) (v land 0xff)

  let set_uint32 s off v =
    set_uint16 s off (Int32.(to_int (shift_right_logical v 16)));
    set_uint16 s (off+2) (Int32.(to_int (logand v 0xffffl)))

  let set_buffer s off len src =
    let dst = sub s off len in
    blit src dst
end

module LE = struct
  open Bigarray.Array1 

  let get_uint8 s off =
    Char.code (get s off)

  let get_uint16 s off =
    let a = get_uint8 s off in
    let b = get_uint8 s (off+1) in
    (b lsl 8) + a

  let get_uint32 s off =
    let a = get_uint8 s off in
    let b = get_uint8 s (off+1) in
    let c = get_uint8 s (off+2) in
    let d = get_uint8 s (off+3) in
    let e = (c lsl 16) + (b lsl 8) + a in
    Int32.(add (shift_left (of_int d) 24) (of_int e))

  let get_buffer s off len =
    sub s off len

  let set_uint8 s off v =
    set s off (Char.chr v)

  let set_uint16 s off v =
    set_uint8 s off (v land 0xff);
    set_uint8 s (off+1) (v lsr 8)

  let set_uint32 s off v =
    set_uint16 s off (Int32.(to_int (shift_right_logical v 16)));
    set_uint16 s (off+2) (Int32.(to_int (logand v 0xffffl)))

  let set_uint32 s off v =
    set_uint16 s off (Int32.(to_int (logand v 0xffffl)));
    set_uint16 s (off+2) (Int32.(to_int (shift_right_logical v 16)))

  let set_buffer s off len src =
    let dst = sub s off len in
    blit src dst

end

let len buf = dim buf

external base_offset : buf -> int = "caml_bigarray_base_offset"

let sub buf off len = sub buf off len

let split buf off =
  let header = sub buf 0 off in
  let body = sub buf off (len buf - off) in
  header, body

let hexdump buf =
  let c = ref 0 in
  for i = 0 to len buf - 1 do
    if !c mod 16 = 0 then print_endline "";
    printf "%.2x " (Char.code (get buf i));
    incr c;
  done;
  print_endline ""
