(;
    "hello world!" という文字列をメモリに格納して、JavaScript の関数を呼び出して、出力するモジュール。

    Wasm 側でメモリを確保し、"hello world!" という文字列を 100 バイト目から格納する。
    メモリの 100 バイト目から、"hello world!" のサイズである 12 バイト分の文字列を取得して、出力する。
    文字列を取得して出力するという関数は JavaScript 側で定義しており、Wasm から呼び出している。
;)
(module
    (;
        次のことを宣言している。
        - インポートしたオブジェクト env が利用できる
        - インポートしたオブジェクト env から print_string 関数(文字列を出力する関数)が利用できる
        - print_string 関数は i32 型の引数を1つ取り、これは文字列の長さを表す
    ;)
    (import "env" "print_string" (func $print_string (param i32)))
    ;; メモリバッファを1ページ(64KB)分インポート
    (import "env" "buffer" (memory 1))
    ;; メモリにおける文字列の開始位置
    (global $start_string (import "env" "start_string") i32)
    ;; 文字列の長さ。今回は "hello world!" なので12を設定
    (global $string_len i32 (i32.const 12))

    (data (global.get $start_string) "hello world!")
    ;; helloworld 関数としてエクスポートする
    ;; この関数は文字列の長さを引数に取り、インポートした print_string 関数を呼び出す
    (func (export "helloworld")
        (call $print_string (global.get $string_len))
    )
)