package rsdk.core;

class Debug {
    public static function printLog(msg:String):Void {
        #if debug
        trace(msg);
        #end
    }
}