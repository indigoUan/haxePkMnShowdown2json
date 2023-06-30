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

package;

import sys.FileSystem;
import haxe.Json;
import sys.io.File;

using StringTools;

typedef Stats = {
    HP:Int,
    Atk:Int,
    Def:Int,
    SpA:Int,
    SpD:Int,
    Spe:Int
}

typedef Pokemon = {
    ?species:String,
    ?nickname:String,
    ?item:String,
    ?sex:Int, // 0:n,  1:m,  2:f 
    ?ability:String,
    ?teratype:String,
    ?nature:String,
    ?moves:Array<String>,
    ?IVs:Stats,
    ?EVs:Stats,
    ?level:Null<Int>,
    ?shiny:Bool
}

typedef Team = {
    format:String,
    name:String,
    pokemon:Array<Pokemon>
};

typedef JsonFile = {
    teams:Array<Team>
}

class Main {
    public static function main():Void {
        var json:JsonFile = { teams: [] };

        println("Press CTRL + C at any time to exit.\nPlease write the name or the path of the file  >>> ");
        var path:String = read();
        if (FileSystem.exists(path)) {
            var file:Array<String> = File.getContent(path).split("\n");

            var teamFormat:String = "";
            var teamName:String = "";
            var teamMons:Array<Pokemon> = [];

            var pokemon:Pokemon = {};

            var emptcount:Int = 0;
            for (line in file) {
                line = line.trim();

                if (line == "") {
                    emptcount++;
                    if (emptcount == 1) {
                        if (pokemon.species != null && pokemon.ability != null) {
                            teamMons.push(clonePokemon(pokemon));
                            pokemon = {};
                        }
                    } else if (emptcount == 2) {
                        json.teams.push({format: teamFormat, name: teamName, pokemon: teamMons});

                        teamFormat = "";
                        teamName = "";
                        teamMons = [];
                    }
                } else {
                    emptcount = 0;

                    if (line.startsWith("===") && line.endsWith("===")) {
                        // it should look like `=== [format] Name ===` 
                        line = line.substring(3, line.length - 3).trim();
                        var start:Int = line.indexOf("[");
                        var end:Int = line.indexOf("]");
                        teamFormat = line.substring(start + 1, end).trim();
                        teamName = line.substr(end + 1).trim();
                        teamMons = [];
                        pokemon = {};
                    } else if (pokemon.species == null) {
                        // get item first 
                        final atIndex:Int = line.lastIndexOf("@");
                        if (atIndex != -1) {
                            pokemon.item = line.substr(atIndex + 1).trim().toLowerCase();
                            line = line.substring(0, atIndex);
                        }
                        line = line.trim();
                        // get sex 
                        final sex:Int = (line.endsWith("(M)")? 1 : (line.endsWith("(F)")? 2 : 0));
                        pokemon.sex = sex;
                        if (sex > 0) {
                            line = line.substring(0, line.length - 3);
                        }
                        line = line.trim();
                        // get unclassed name 
                        final parIndex:Int = line.lastIndexOf("(");
                        if (parIndex != -1) {
                            // nicknamed 
                            pokemon.species = line.substring(parIndex + 1, line.length - 1).trim().toLowerCase();
                            pokemon.nickname = line.substring(0, line.length - pokemon.species.length - 2).trim();
                        } else {
                            // species name only 
                            pokemon.species = line.toLowerCase();
                        }
                    } else if (line.toLowerCase().startsWith("ability:")) {
                        // parse ability 
                        pokemon.ability = line.substr("ability:".length).toLowerCase().trim();
                    } else if (line.toLowerCase().startsWith("tera type:")) {
                        // parse tera type 
                        pokemon.teratype = line.substr("tera type:".length).toLowerCase().trim();
                    } else if (line.toLowerCase().startsWith("ivs:")) {
                        // parse IVs 
                        pokemon.IVs = parseStats(line.substr("ivs:".length), 31);
                    } else if (line.toLowerCase().startsWith("evs:")) {
                        // parse EVs 
                        pokemon.EVs = parseStats(line.substr("evs:".length), 0);
                    } else if (line.toLowerCase().endsWith(" nature")) {
                        // parse nature 
                        pokemon.nature = line.substring(0, line.length - " nature".length).toLowerCase().trim();
                    } else if (line.toLowerCase().startsWith("shiny:")) {
                        // parse shiny 
                        pokemon.shiny = line.substr("shiny:".length).toLowerCase().trim() == "yes";
                    } else if (line.toLowerCase().startsWith("level:")) {
                        // parse level 
                        pokemon.level = Std.parseInt(line.substr("level:".length).toLowerCase().trim());
                    } else if (line.toLowerCase().startsWith("-")) {
                        // parse move 
                        if (pokemon.moves == null) {
                            pokemon.moves = [];
                        }
                        pokemon.moves.push(line.substr(1).toLowerCase().trim());
                    }
                }
            }

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

    static function parseStats(str:String, defaultValue:Int):Stats {
        var stats:Stats = {
            HP: defaultValue, Atk: defaultValue, Def: defaultValue,
            SpA: defaultValue, SpD: defaultValue, Spe: defaultValue
        }

        var split:Array<String> = str.toLowerCase().trim().split("/");
        for (part in split) {
            part = part.toLowerCase().trim();
            final index:Int = part.indexOf(" ");
            if (index != -1) {
                var value:Null<Int> = Std.parseInt(part.substring(0, index).trim());
                var stat:String = part.substr(index + 1).trim();
                if (value != null) {
                    switch (stat) {
                         case "hp": {  stats.HP = value; }
                        case "atk": { stats.Atk = value; }
                        case "def": { stats.Def = value; }
                        case "spa": { stats.SpA = value; }
                        case "spd": { stats.SpD = value; }
                        case "spe": { stats.Spe = value; }
                    }
                }
            }
        }

        return stats;
    }

    static function clonePokemon(mon:Pokemon):Pokemon {
        return {
            species: mon.species,
            ability: mon.ability,
            nickname: mon.nickname,
            item: mon.item,
            sex: (mon.sex == null? 0 : mon.sex),
            teratype: (mon.teratype == null? "normal" : mon.teratype),
            nature: (mon.nature == null? "hardy" : mon.nature),
            moves: (mon.moves == null? [] : mon.moves),
            IVs: (mon.IVs == null? parseStats("", 31) : mon.IVs),
            EVs: (mon.EVs == null? parseStats("", 0) : mon.EVs)
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
