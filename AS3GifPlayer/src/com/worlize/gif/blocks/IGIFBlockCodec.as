package com.worlize.gif.blocks
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;

	public interface IGIFBlockCodec
	{
		function decode(stream:IDataInput):void;
		function encode(stream:ByteArray=null):ByteArray;
		function dispose():void;
	}
}