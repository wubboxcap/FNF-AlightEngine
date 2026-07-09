/**
 * Example usage of GameBananaPsych.hx (synchronous, returns values directly)
 * Compile e.g. for Neko:  haxe -main Main -neko out.n -cp .
 * Run:                    neko out.n
 */
import GameBananaPsych;
class Test {
    static function main():Void {
        trace("=== Trending Psych Engine mods ===");
        try {
            var trending:Array<ModSummary> = GameBananaPsych.getTrendingMods();
            for (m in trending) {
                trace('[${m.id}] ${m.name} (by ${m.submitter})');
            }

            if (trending.length > 0) {
                showDownloadLinks(trending[0].id);
            }
        } catch (e:haxe.Exception) {
            trace("Trending failed: " + e.message);
            // Uncomment to inspect the raw response if this ever breaks again:
            // trace(GameBananaPsych.debugRawTrending());
        }

        trace("=== Searching Psych Engine mods for 'whitty' ===");
        try {
            var results:Array<ModSummary> = GameBananaPsych.searchMods("whitty");
            for (m in results) {
                trace('[${m.id}] ${m.name}');
            }
            trace(GameBananaPsych.debugRawTrending());
        } catch (e:haxe.Exception) {
            trace("Search failed: " + e.message);
        }
    }

    static function showDownloadLinks(modId:Int):Void {
        try {
            var detail:ModDetail = GameBananaPsych.getModDownloadLinks(modId);
            trace('Files for "${detail.name}":');
            for (f in detail.files) {
                trace('  ${f.fileName} -> ${f.downloadUrl}');
            }
        } catch (e:haxe.Exception) {
            trace("Fetching download links failed: " + e.message);
        }
    }
}
