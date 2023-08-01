const fs = require('fs');
const bytes = fs.readFileSync(__dirname + '/helloworld.wasm');

let hello_world = null;
// メモリにおける文字列の開始位置。100 に意味はなく、64KB(WebAssembly における1ページサイズ) 以内であればよい。
let start_string_index = 100;
// WebAssembly インスタンスがアクセスするメモリ。引数はページ数。
let memory = new WebAssembly.Memory({initial: 1});

// WebAssembly 側に渡すオブジェクト
let importObject = {
    env: {
        buffer: memory,
        start_string: start_string_index,
        print_string: function (str_len) {
            // Wasm 側で作成したメモリにアクセスする
            const bytes = new Uint8Array(memory.buffer, start_string_index, str_len);
            const log_string = new TextDecoder('utf8').decode(bytes);
            console.log(log_string);
        }
    }
};

(async () => {
    let obj = await WebAssembly.instantiate(new Uint8Array(bytes), importObject);
    // WebAssembly 側の helloworld 関数を取得
    ({helloworld: hello_world} = obj.instance.exports);
    hello_world();
})();