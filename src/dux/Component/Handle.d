/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Handle;

import dux.Component.Enums;

/** シンセサイザに対する命令をサポートします。 */
class Handle
{
public:
    /** 対象となるパート。 */
    immutable int targetPart;

    /** ハンドルのタイプ。 */
    immutable HandleType type;

    /** ハンドルに対する整数パラメータ。 */
    immutable int data1;

    /** ハンドルに対する実数パラメータ。 */
    immutable float data2;

public:
    /** パラメータを指定せずに新しい Handle クラスのインスタンスを初期化します。
     *
     * Params:
     *      targetPart = ハンドルが適用されるパート。
     *      type = ハンドルの種類。
     */
    this(int targetPart, HandleType type)
    {
        this(targetPart, type, 0, 0.0f);
    }
    
    /** パラメータを指定せずに新しい Handle クラスのインスタンスを初期化します。
     *
     * Params:
     *      targetPart = ハンドルが適用されるパート。
     *      type       = ハンドルの種類。
     *      data1      = ハンドルに対する整数パラメータ。
     */
    this(int targetPart, HandleType type, int data1)
    {
        this(targetPart, type, data1, 0.0f);
    }
    
    /** パラメータを指定せずに新しい Handle クラスのインスタンスを初期化します。
     *
     * Params:
     *      targetPart = ハンドルが適用されるパート。
     *      type       = ハンドルの種類。
     *      dara2      = ハンドルに対する実数パラメータ。
     */
    this(int targetPart, HandleType type, float data2)
    {
        this(targetPart, type, 0, data2);
    }

    /** パラメータを指定せずに新しい Handle クラスのインスタンスを初期化します。
     *
     * Params:
     *      targetPart = ハンドルが適用されるパート。
     *      type       = ハンドルの種類。
     *      data1      = ハンドルに対する整数パラメータ。
     *      dara2      = ハンドルに対する実数パラメータ。
     */
    this(int targetPart, HandleType type, int data1, float data2)
    {
        this.targetPart = targetPart;
        this.type = type;
        
        this.data1 = data1;
        this.data2 = data2;
    }
    
    /** ベースとなる Handle オブジェクトと新しいパートを指定して Handle クラスのインスタンスを初期化します。
     *
     * Params:
     *      handle        = ベースとなる Handle オブジェクト。
     *      newTargetPart = 新しいパート。
     */
    this(Handle handle, int newTargetPart)
    {
        this(newTargetPart, handle.type, handle.data1, handle.data2);
    }
}
