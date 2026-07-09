
/**
 * GameBananaPsych.hx
 *
 * Minimal client for GameBanana's unofficial JSON API (apiv11), scoped to
 * the "Psych Engine" mod category on the FNF game page.
 *
 * Category id 28367 = Psych Engine mod folder/category.
 * Game id     8694  = Friday Night Funkin'
 *
 * All methods are SYNCHRONOUS and return values directly (or throw a
 * haxe.Exception on failure) -- haxe.Http.request() defaults to
 * async = false, which blocks until the internal onData/onError fires,
 * so we just capture the result in a local var and hand it back.
 *
 * Works on sys targets (Neko, HashLink, C++, etc). On JS this uses a
 * synchronous XMLHttpRequest, which is deprecated in browsers and may be
 * blocked -- for a web target, prefer an async wrapper (e.g. via
 * js.Browser.window.fetch) instead of this class as-is.
 *
 * NOTE: This hits GameBanana's internal API used by their own website.
 * It's not officially documented, so field names / endpoints can change
 * without notice. If something breaks, call `debugRawTrending` /
 * `debugRawSearch` below to print the raw JSON and see what shape
 * the API is actually returning.
 */

class GameBananaPsych {

    public static inline var BASE:String = "https://gamebanana.com/apiv11";
    public static inline var FNF_GAME_ID:Int = 8694;
    public static inline var PSYCH_ENGINE_CATEGORY_ID:Int = 28367;

    /**
     * Fetch mods from the Psych Engine category, sorted for "trending".
     * sort: "popular" (trending-ish), "new" (most recent), "default"
     *
     * Uses Game/{id}/Subfeed rather than Mod/Index -- Subfeed is the
     * endpoint the actual GameBanana trending/subfeed pages call, and it
     * accepts the same category filter.
     */
    public static function getTrendingMods(
        page:Int = 1,
        perPage:Int = 15,
        sort:String = "popular"
    ):Array<ModSummary> {
        var http = new haxe.Http(BASE + "/Game/" + FNF_GAME_ID + "/Subfeed");
        http.setParameter("_nPage", Std.string(page));
        http.setParameter("_nPerpage", Std.string(perPage));
        http.setParameter("_aFilters[Generic_Category]", Std.string(PSYCH_ENGINE_CATEGORY_ID));
        http.setParameter("_sSort", sort);

        var raw:String = runSync(http);
        return parseModList(raw);
    }

    /**
     * Search within the Psych Engine category only.
     */
    public static function searchMods(
        query:String,
        page:Int = 1,
        perPage:Int = 15
    ):Array<ModSummary> {
        var http = new haxe.Http(BASE + "/Util/Search/Results");
        http.setParameter("_sSearchString", query);
        http.setParameter("_csvModelInclusions", "Mod");
        http.setParameter("_aFilters[Generic_Category]", Std.string(PSYCH_ENGINE_CATEGORY_ID));
        http.setParameter("_nPage", Std.string(page));
        http.setParameter("_nPerpage", Std.string(perPage));

        var raw:String = runSync(http);
        return parseModList(raw);
    }

    /**
     * Fetch a single mod's files, including direct ("instant") download URLs.
     */
    public static function getModDownloadLinks(modId:Int):ModDetail {
        var http = new haxe.Http(BASE + "/Mod/" + modId + "/ProfilePage");
        var raw:String = runSync(http);

        var json:Dynamic = haxe.Json.parse(raw);
        var files:Array<ModFile> = [];
        var filesArr:Array<Dynamic> = Reflect.field(json, "_aFiles");

        if (filesArr != null) {
            for (f in filesArr) {
                files.push({
                    fileName: Reflect.field(f, "_sFile"),
                    downloadUrl: Reflect.field(f, "_sDownloadUrl"),
                    sizeBytes: Reflect.field(f, "_nFilesize"),
                    description: Reflect.field(f, "_sDescription")
                });
            }
        }

        var submitter:Dynamic = Reflect.field(json, "_aSubmitter");

        return {
            id: modId,
            name: Reflect.field(json, "_sName"),
            submitter: submitter != null ? Reflect.field(submitter, "_sName") : null,
            files: files
        };
    }

    /**
     * Debug helper: returns the raw JSON string from the trending endpoint
     * so you can inspect the real response shape if parsing ever breaks.
     */
    public static function debugRawTrending(page:Int = 1, perPage:Int = 15, sort:String = "popular"):String {
        var http = new haxe.Http(BASE + "/Game/" + FNF_GAME_ID + "/Subfeed");
        http.setParameter("_nPage", Std.string(page));
        http.setParameter("_nPerpage", Std.string(perPage));
        http.setParameter("_aFilters[Generic_Category]", Std.string(PSYCH_ENGINE_CATEGORY_ID));
        http.setParameter("_sSort", sort);
        return runSync(http);
    }

    /**
     * Debug helper: returns the raw JSON string from the search endpoint.
     */
    public static function debugRawSearch(query:String, page:Int = 1, perPage:Int = 15):String {
        var http = new haxe.Http(BASE + "/Util/Search/Results");
        http.setParameter("_sSearchString", query);
        http.setParameter("_csvModelInclusions", "Mod");
        http.setParameter("_aFilters[Generic_Category]", Std.string(PSYCH_ENGINE_CATEGORY_ID));
        http.setParameter("_nPage", Std.string(page));
        http.setParameter("_nPerpage", Std.string(perPage));
        return runSync(http);
    }

    /**
     * Runs an haxe.Http request synchronously and returns the raw response
     * body, or throws a haxe.Exception with the error message on failure.
     */
    static function runSync(http:haxe.Http):String {
        var result:String = null;
        var errorMsg:String = null;

        http.onData = function(data:String):Void {
            result = data;
        };
        http.onError = function(msg:String):Void {
            errorMsg = msg;
        };

        http.request(false); // async = false -> blocks until onData/onError fires

        if (errorMsg != null) {
            throw new haxe.Exception('GameBanana request failed: $errorMsg');
        }
        if (result == null) {
            throw new haxe.Exception("GameBanana request returned no data.");
        }
        return result;
    }

    /**
     * Shared parser for list-style endpoints (Subfeed, Util/Search/Results).
     * GameBanana wraps results in "_aRecords" when metadata is present,
     * or returns a bare array in some list contexts.
     */
    static function parseModList(raw:String):Array<ModSummary> {
        var json:Dynamic;
        try {
            json = haxe.Json.parse(raw);
        } catch (e:Dynamic) {
            throw new haxe.Exception('Failed to parse mod list JSON: ${Std.string(e)}');
        }

        var recordsField:Dynamic = Reflect.field(json, "_aRecords");
        var records:Array<Dynamic> = (recordsField != null)
            ? cast recordsField
            : (Std.isOfType(json, Array) ? cast json : []);

        var out:Array<ModSummary> = [];
        for (m in records) {
            var submitter:Dynamic = Reflect.field(m, "_aSubmitter");
            out.push({
                id: Reflect.field(m, "_idRow"),
                name: Reflect.field(m, "_sName"),
                submitter: submitter != null ? Reflect.field(submitter, "_sName") : null,
                profileUrl: Reflect.field(m, "_sProfileUrl")
            });
        }
        return out;
    }
}

typedef ModSummary = {
    var id:Int;
    var name:String;
    var submitter:Null<String>;
    var profileUrl:Null<String>;
}

typedef ModFile = {
    var fileName:String;
    var downloadUrl:String;
    var sizeBytes:Int;
    var description:Null<String>;
}

typedef ModDetail = {
    var id:Int;
    var name:String;
    var submitter:Null<String>;
    var files:Array<ModFile>;
}
