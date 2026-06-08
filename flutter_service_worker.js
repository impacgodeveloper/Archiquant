'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "0d51d2bf51d4045096a0a14505e5d59f",
"version.json": "45e5002eaf569517dcec7ce64415f725",
"index.html": "3dded524b63dd41cf36b2281f9af6a47",
"/": "3dded524b63dd41cf36b2281f9af6a47",
"main.dart.js": "e289bd39b87028241b81e359902cb146",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "e44c8f372e9e61df1a7155c542702ee9",
".git/config": "8ccac3cef2d4f1ede46a07d1bdb8515c",
".git/objects/92/5c8df217b49cd4fc23dbdb14e2f783940a0f03": "8eeeb99d72ce10d4a204dec85379da29",
".git/objects/66/6719ecf869b2cc62a004dafe671811d2cb17bd": "f1cc233a1481e3ce89d5f6f22a41a7b3",
".git/objects/3e/5420c1c91d12766da9f6b2d311dba55c8f610c": "c91b312a7811101a3f3c9fba2581be41",
".git/objects/68/c971fc539377733f88f3e0029a2a4e4c8bdc95": "76109c3a6f683f4466df41127d4edd9e",
".git/objects/68/4f8667a7ba22c6dcde219d920dc532dfeff9ba": "8ab13b88211105ffbb3828843c8e18b8",
".git/objects/6f/8f6f6a4b402fe12cfcec358ef95b7abb9b428a": "95a1aec2e5498428269b7624fea85914",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9e/305c78b6284a152b3731b7f763b77a74e3adb8": "3cfed973eba20c5bb71eb1dff812f679",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/35/7214fd24797e5308e92e9aed973c2dd59eb375": "ad0e7f0c430eb568a875235b6fcdf8b1",
".git/objects/69/70ce0c614f670eda4ac8a92e34e5fa6d7de3c0": "2a1992c43103d0a76d05a810d2123e69",
".git/objects/d9/d2a728a4bd01e3ce414a213b4cea0da0021276": "93142c24fc2ebd668b3d21e128b4d315",
".git/objects/da/0d5aa44a8c93eda469f7a99ed8feac32d5b19d": "25d25e93b491abda0b2b909e7485f4d1",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d8/8128adaad90d2fd7cdabe7b36eaaaed0d3a25b": "3d15963af0d77c1cd40702fb7c18fa93",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/fc/f9b9fa4fe0e29d5673bf22bf9f1a3665424009": "22b885a3909728cc7d643422c84ac87a",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/57ec1b5de3136c9d6dea47367d839cdac20e3c": "90f6a34315429b9daba5905cd570cd62",
".git/objects/cf/d1ade03356f26b063770793c9ece1ad5f10818": "469f220b44193d3f533044b214d939fe",
".git/objects/cf/34f4cd0abb8a1136d27a8130830f2dcc5695ca": "82c693f5c6c76132adbc42885b1b3ad8",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/e4/dc591c9d761769c1a1b784b4a5c52a2f5dc43b": "712feb16641a8a78d2a80a99ad7c1514",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/c1/e90d87fd9313e64d44e83c3723d63f66f964b5": "c9b65bfc51faee911a6e31626089c290",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/42/6bd906ad569337630e4d1b841cd32184a0e126": "f3fee1821e7c0c3bd562d814044dd1c7",
".git/objects/17/066eb0b3c6e8ace7849c92b60e15328be098d0": "b68dc45f8783fe9b87915d982adc2a9f",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/7e/71246c673fc8759a74dce79e1694013cefd5af": "4503ac9eb90da7d26e51c2d5bc320588",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/81/9937c666dc003d0ef1e12edae63a7541c56c97": "a889e5caafd77e375bb02bbd9b33fe58",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/07/4dc0857dcc71a498671723cf620f9615b2a9f8": "be685ba6401bb49afc0782a19ef9c2c6",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/53/e08e2ea776de4be8738f37b7ac500793d5caa7": "7c90520fdfb2b8156bd6d0f54481fd7e",
".git/objects/99/20a847c69e5bba356c6bf333a809e39a9ed732": "599127aa615c28e7afda38528e42773c",
".git/objects/97/08ed615c859b7f84bfdb9289657ab7ed7b245b": "eb7cfc99a9ddbe6a991dccb2773864a4",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/65bbbd3318224d282534afac340e98f4882bce": "3f50a8181cb9abddab291d5e0e6ab009",
".git/objects/dd/d4e4ea56e6e99fa6e5462ae167ebfe0f4b7507": "4a09bf6d42f5800d4b0d4e783e16ef3e",
".git/objects/dc/dbfc71b082f14910ec237f88c1282c0d0ed3d7": "d54c90aa41d24b03ff5ebe4e3dd6681c",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/d5/f687e65faf81d923e3aa3438cf5df7e24c7399": "40660062fc6bf8e85e962ffadfc578ed",
".git/objects/af/fd23f25118b47d2107db288e9274fa6b523cad": "c28d00842d35161c687a25012131fa13",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/1f63cfd871a10755413bac9a5a0fac41569c53": "444416bd17bbe7ac7dbfd7ddfc69e55c",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/cc/45077353180dd87db760826da203c1d28662b4": "3448b3e77d1566d7eea07c8a28b4aa8f",
".git/objects/f7/4db4d0d47529373ec624eb1dfdbf89dbc7da53": "dbae0d545f969c15b85c6f6d8fa1eeb9",
".git/objects/e7/a12341f6426f31fc3a95a0727445ca2ab3cac2": "d76d2abb4d7b161cd72b9af05e36d1f7",
".git/objects/f8/c0defe9c965b008b3a44f239f0428487118e5b": "a33c26b3e8bfc1167c47a17dbc39d06f",
".git/objects/f8/b9c7469f9186362b0e64bb9498040bb4dd182f": "4add114f59d61a63dafc70591f9bbae5",
".git/objects/e0/01f0e468d40ed7e049c4efa08b96211c5ccee8": "bc019109bba961f223e76e23d8a1cb08",
".git/objects/77/a9b7151df28b2d6bdfef0dd7e88ce3f3625bf8": "258dd1a5b04d1221c515ff9128058cb5",
".git/objects/70/06ec804bf1c7759149700c97892cbe933251aa": "24679c019ffc46a8141bb8d535e727ae",
".git/objects/4a/acbdc33c33a0ee44a46e354c53ccb768884795": "95cdc45af3f72217b02b3bb74ad7aa79",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/15/94fd720aed01e0a649cc94588da137dafd9991": "35692d6cbf2e390c5c6db0575f9f37ad",
".git/objects/82/41c672c64fb8ecbaf83157688df3a97652651e": "48233de23836cc71f4638296e78a594b",
".git/objects/47/5ff22b4002c351d62b2f0ece7f6c938989611c": "3081671e2cde4de98fb1388fc671fd66",
".git/objects/78/da074827f3631a7b9587aa6ed1fe6a2abad5cc": "24b8c1202d91142ac0934b41a6fb3a72",
".git/objects/13/221532bb2b7ce8828381c1962ce57a286da9c1": "b5b84ecf61761a4d4e4392e57ed7ceac",
".git/objects/13/8f85530f9a8ffe2c6c344662c464fc09359d90": "d76d286767089b299f9df49e6b59d254",
".git/objects/7f/ec6c7eb42a9efe5d154e17cee586a3de6cef58": "90b25a8e89f8fb910378a764960f8dbe",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "bcc01d680a422c6d6ec0f7864810d168",
".git/logs/refs/heads/gh-pages": "bcc01d680a422c6d6ec0f7864810d168",
".git/logs/refs/remotes/origin/gh-pages": "fb506c043c9a77dee3afcd1bba5ddc0f",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/gh-pages": "bb1f5fda3a18443a9f977cf477bc6d17",
".git/refs/remotes/origin/gh-pages": "bb1f5fda3a18443a9f977cf477bc6d17",
".git/index": "162b7f42208df325e669c5b99f95d3e5",
".git/COMMIT_EDITMSG": "026b166f3407fac99dd8ead8113479fa",
"assets/AssetManifest.json": "2545e54370e80e18041a474e016d54dc",
"assets/NOTICES": "4be1afbf8fef2ee934f30c1a0979c3c7",
"assets/FontManifest.json": "b740a59a6b9ace361f84e9c31f28fce9",
"assets/AssetManifest.bin.json": "504593c8e98974f5dfbb86805e78f6d4",
"assets/packages/lucide_icons_flutter/assets/lucide.ttf": "975425c23ed1691f9e458d7f3a2cd386",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf": "07cff2a304f73e9d4974f0dbc986a998",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf": "019b68497ea016880c9f0bf99ce17285",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf": "b2771d7899a39459aefd095bb261141b",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf": "15ab91a16f68fd3950c48ce11917472c",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf": "ce886fdfe60cc58983e0bc13c788b63e",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf": "8ba3d2a7635c74bcd5bac9a1a36d05bb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "e9ed4407c3eb96b00d8588e9ef69c625",
"assets/fonts/MaterialIcons-Regular.otf": "e4b488774d029e301d0a6f30a8c93602",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
