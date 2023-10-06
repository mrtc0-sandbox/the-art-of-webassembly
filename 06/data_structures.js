// 衝突検出を行うためのデータを生成し、衝突検出の結果を表示するコード
const colors = require('colors');
const fs = require('fs');

const bytes = fs.readFileSync(__dirname + '/data_structures.wasm');

// 64KB のメモリブロックをアロケート
const memory = new WebAssembly.Memory({ initial: 1 });

const mem_i32 = new Uint32Array(memory.buffer);

const obj_count = 32; // このコードで設定する構造体の個数

const obj_base_addr = 0; // 1byte 目のアドレス
const obj_stride = 16; // 構造体全体のバイト数。構造体の各要素は 4 バイトで、4 つの要素があるので 16 バイト。

/*
 * 構造体の各要素のオフセットは次のようになる。
 *
 * 0               4               8               12              16
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |     x 座標    |     y 座標    |    半径(r)    | 衝突フラグ(c) |
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 * アクセスしたいデータ構造体のメモリアドレスを取得するには、その構造体のインデックスにストライドを掛けて、ベースアドレスを足す
 *
 * e.g.
 *    obj[0] ... obj_base_addr + obj_stride * 0 = 0 
 *    obj[1] ... obj_base_addr + obj_stride * 1 = 16
 *    obj[2] ... obj_base_addr + obj_stride * 2 = 32
 *    ...
 *
 */
const x_offset = 0;
const y_offset = 4;
const radius_offset = 8;
const collision_offset = 12;

/*
 * WASM では上記のようにバイト数でオフセットを指定するが、JavaScript では異なる。
 * JavaScript であるこのコードの世界では、次のように表現される。
 *
 *  mem_i32 = Uint32Array() [
 *    X, Y, R, C, // obj[0]
 *    X, Y, R, C, // obj[1]
 *    X, Y, R, C, // obj[2]
 *  ]
 *
 *  なので、JavaScript の世界で各要素にアクセスするには、ベースアドレスとストライドを 4(32bit) で割った値を使用する。
 *  要素iのインデックスを求めるには obj_i32_base_index + obj_i32_stride * i となる。
 */
const obj_i32_base_index = obj_base_addr / 4;
const obj_i32_stride = obj_stride / 4;

// 各要素のオフセットも同様に 4 で割った値を使用する。
const x_offset_i32 = x_offset / 4;
const y_offset_i32 = y_offset / 4;
const radius_offset_i32 = radius_offset / 4;
const collision_offset_i32 = collision_offset / 4;

const importObject = {
  env: {
    mem: memory,
    obj_base_addr: obj_base_addr,
    obj_count: obj_count,
    obj_stride: obj_stride,
    x_offset: x_offset,
    y_offset: y_offset,
    radius_offset: radius_offset,
    collision_offset: collision_offset,
  }
};

// ランダムな x 座標、y 座標、半径を設定する
// ⚠ 衝突フラグはここでは設定しない。ちなみに 0 で初期化されている
for (let i = 0; i < obj_count; i++) {
  let index = obj_i32_base_index + obj_i32_stride * i;

  let x = Math.floor(Math.random() * 100);
  let y = Math.floor(Math.random() * 100);
  let r = Math.ceil(Math.random() * 10);

  mem_i32[index + x_offset_i32] = x;
  mem_i32[index + y_offset_i32] = y;
  mem_i32[index + radius_offset_i32] = r;
}

// console.log(mem_i32)

(async () => {
  let obj = await WebAssembly.instantiate(new Uint8Array(bytes), importObject);

  for (let i = 0; i < obj_count; i++) {
    let index = obj_i32_base_index + obj_i32_stride * i;

    let x = mem_i32[index + x_offset_i32].toString().padStart(2, ' ');
    let y = mem_i32[index + y_offset_i32].toString().padStart(2, ' ');
    let r = mem_i32[index + radius_offset_i32].toString().padStart(2, ' ');

    let i_str = i.toString().padStart(2, '0');
    // 書籍では次のように書かれているが、Boolean() を使ったほうが分かりやすいだろう
    // let c = !!mem_i32[index + collision_offset_i32];
    let c = Boolean(mem_i32[index + collision_offset_i32])

    // 衝突が合った場合は赤色で表示、そうでない場合は緑色で表示する
    if (c) {
      console.log(`obj[${i_str}] x=${x} y=${y} r=${r} collision=${c}`.red.bold);
    } else {
      console.log(`obj[${i_str}] x=${x} y=${y} r=${r} collision=${c}`.green);
    }
  }
})();
