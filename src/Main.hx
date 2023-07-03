/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to https://unlicense.org
*/

package src;

import sys.FileSystem;
import haxe.Json;
import sys.io.File;

class Main {
    public static function main():Void {
        println("Press CTRL + C at any time to exit.\nPlease write the name or the path of the file  >>> ");
        var path:String = read();
        if (FileSystem.exists(path)) {
            var json = ShowdownParser.parse(File.getContent(path));

            var iter:Int = -1;
            while (FileSystem.exists("teams" + (iter == -1? "" : Std.string(iter)) + ".json")) {
                iter++;
            }
            File.saveContent("teams" + (iter == -1? "" : Std.string(iter)) + ".json", Json.stringify(json, "\t"));
            print('JSON output saved as "teams${iter == -1? "" : Std.string(iter)}.json" in "${Sys.getCwd()}".\n');
            main();
        } else {
            print("\n\nThat file doesn't exist!\n");
            main();
        }
    }

    static inline function println(str:Dynamic):Void {
        Sys.stdout().writeString(Std.string(str));
    }

    static inline function print(str:Dynamic):Void {
        Sys.stdout().writeString(Std.string(str) + "\n");
    }

    static inline function read():String {
        return Sys.stdin().readLine();
    }
}
