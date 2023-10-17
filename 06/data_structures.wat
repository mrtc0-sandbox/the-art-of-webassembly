(;
 ピタゴラスの定理を使って衝突検出を行う WAT コード
 JavaScript 側で生成された Uint32Array の線形メモリには円の情報(X座標, Y座標, 半径)が含まれているので、
 それぞれループして他の円と比較し、衝突しているかどうかを判定する。
 ;)
(module
  (import "env" "mem" (memory 1)) 
  (global $obj_base_addr (import "env" "obj_base_addr") i32) ;; ベースアドレス
  (global $obj_count (import "env" "obj_count") i32) ;; オブジェクトの数
  (global $obj_stride (import "env" "obj_stride") i32) ;; ストライド(バイト数)

  (global $x_offset (import "env" "x_offset") i32) ;; X座標のオフセット
  (global $y_offset (import "env" "y_offset") i32) ;; Y座標のオフセット
  (global $radius_offset (import "env" "radius_offset") i32) ;; 半径のオフセット
  (global $collision_offset (import "env" "collision_offset") i32) ;; 衝突フラグのオフセット

  (;
   ピタゴラスの定理を使って衝突検出を行う関数
   2つの円の中心座標と半径を引数に取り、衝突しているかどうか(衝突していたら1を、そうでない場合は0)を返す。

   １つ目の円の半径を R1, 2つ目の円の半径を R2 とし、2つの円の中心点からの距離をDとする。
   このとき、R1 + R2 が D より小さい場合は衝突はしておらず、D より大きい場合は衝突している。
   ;)
   (func $collision_check
         (param $x1 i32) (param $y1 i32) (param $r1 i32)
         (param $x2 i32) (param $y2 i32) (param $r2 i32)
         (result i32)

         (local $x_diff_sq i32)
         (local $y_diff_sq i32)
         (local $r_sum_sq i32)

         ;; ピタゴラスの定理 A^2 + B^2 = C^2 を組み立てる
         ;; X1 - X2 で2つの円のX座標間の距離を求めて2乗する
         local.get $x1
         local.get $x2
         i32.sub
         local.tee $x_diff_sq
         local.get $x_diff_sq
         i32.mul
         local.set $x_diff_sq

         ;; Y1 - Y2 で2つの円のY座標間の距離を求めて2乗する
         local.get $y1
         local.get $y2
         i32.sub
         local.tee $y_diff_sq
         local.get $y_diff_sq
         i32.mul
         local.set $y_diff_sq

         ;; 半径の合計の2乗を計算する
         local.get $r1
         local.get $r2
         i32.add
         local.tee $r_sum_sq
         local.get $r_sum_sq
         i32.mul
         local.tee $r_sum_sq ;; R^2

         ;; ($x1 - $x2)^2 + ($y1 - $y2)^2 を計算。これがC^2になる
         ;; この結果と半径の合計の2乗を比較し、衝突しているかどうかを判定する
         local.get $x_diff_sq ;; A^2
         local.get $y_diff_sq ;; B^2
         i32.add ;; A^2 + B^2

         i32.gt_u ;; もし A^2 + B^2 > R^2 ならば衝突していないので 0 を返す
         )

   ;; オブジェクトのベースアドレスを受け取って、線形メモリ内のその位置にある値を返すヘルパー関数
   (func $get_attr (param $obj_base i32) (param $attr_offset i32)
         (result i32)
         local.get $obj_base
         local.get $attr_offset
         ;; ベースアドレスとオフセットを足して、そのフィールドの値を返す
         i32.add
         i32.load
         )

   ;; 2つのオブジェクトのベースアドレスを受け取って、それらのオブジェクトの衝突フラグを設定する関数
   (func $set_collision
         (param $obj_base_1 i32) (param $obj_base_2 i32)
         ;; 1つ目のオブジェクトの衝突フラグを設定する
         local.get $obj_base_1
         global.get $collision_offset
         i32.add
         i32.const 1
         i32.store

         ;; 2つ目のオブジェクトの衝突フラグを設定する
         local.get $obj_base_2
         global.get $collision_offset
         i32.add
         i32.const 1
         i32.store
         )

   (func $init
         (local $i i32) ;; outer loop counter
         (local $i_obj i32) ;; オブジェクトi のアドレス
         (local $xi i32)(local $yi i32)(local $ri i32) ;; x,y,r for object i

         (local $j i32) ;; inner loop counter
         (local $j_obj i32) ;; オブジェクトj のアドレス
         (local $xj i32)(local $yj i32)(local $rj i32) ;; x,y,r for object j

         (loop $outer_loop
               (local.set $j (i32.const 0)) ;; $j = 0
               (loop $inner_loop
                     (block $inner_continue
                            ;; if $i == $j continue
                            (br_if $inner_continue (i32.eq (local.get $i) (local.get $j) ) )

                            ;; オブジェクトi のアドレスを計算。JavaScript 側のコメントを参照。
                            ;; $i_obj = $obj_base_addr + $i * $obj_stride
                            (i32.add (global.get $obj_base_addr)
                                     (i32.mul (local.get $i) (global.get $obj_stride) ) )

                            ;; オブジェクトi の X 座標のフィールドを取得
                            ;; load $i_obj + $x_offset and store in $xi
                            (call $get_attr (local.tee $i_obj) (global.get $x_offset) )
                            local.set $xi 

                            ;; オブジェクトi の Y 座標のフィールドを取得
                            ;; load $i_obj + $y_offset and store in $yi
                            (call $get_attr (local.get $i_obj) (global.get $y_offset) )
                            local.set $yi 

                            ;; オブジェクトi の 半径のフィールドを取得
                            ;; load $i_obj + $radius_offset and store in $ri
                            (call $get_attr (local.get $i_obj) (global.get $radius_offset) )
                            local.set $ri 

                            ;; オブジェクトj のアドレスを計算。JavaScript 側のコメントを参照。
                            ;; $j_obj = $obj_base_addr + $j * $obj_stride
                            (i32.add (global.get $obj_base_addr)
                                     (i32.mul (local.get $j)(global.get $obj_stride)))

                            ;; オブジェクトj の X 座標のフィールドを取得
                            ;; load $j_obj + $x_offset and store in $xj
                            (call $get_attr (local.tee $j_obj) (global.get $x_offset) )
                            local.set $xj 

                            ;; オブジェクトj の Y 座標のフィールドを取得
                            ;; load $j_obj + $y_offset and store in $yj
                            (call $get_attr (local.get $j_obj) (global.get $y_offset) )
                            local.set $yj 

                            ;; オブジェクトj の半径のフィールドを取得
                            ;; load $j_obj + $radius_offset and store in $rj
                            (call $get_attr (local.get $j_obj) (global.get $radius_offset) )
                            local.set $rj 

                            ;; i と j の衝突判定を行う
                            (call $collision_check
                                  (local.get $xi)(local.get $yi)(local.get $ri)
                                  (local.get $xj)(local.get $yj)(local.get $rj))

                            ;; 衝突していたら、衝突フラグを i,j 両方のオブジェクトに設定する
                            if
                            (call $set_collision (local.get $i_obj) (local.get $j_obj))
                            end
                            )

                     (i32.add (local.get $j) (i32.const 1)) ;; $j++

                     ;; if $j < $obj_count loop
                     (br_if $inner_loop
                            (i32.lt_u (local.tee $j) (global.get $obj_count)))
                     )

               (i32.add (local.get $i) (i32.const 1)) ;; $i++

               ;; if $i < $obj_count loop
               (br_if $outer_loop
                      (i32.lt_u (local.tee $i) (global.get $obj_count) ) )
               )
         )

   (start $init)
   )
