import { Astal, Gtk } from 'ags/gtk4';
import { createState } from 'ags';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Gdk from 'gi://Gdk';
import app from 'ags/gtk4/app';
import inputControl from '../lib/inputControl';
import idle from '../lib/idle';
import type WebKitT from 'gi://WebKit?version=6.0';

const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;

export type PageName = 'plan' | 'claude' | 'custom';

const urls: Record<PageName, string> = {
  plan: 'https://alechomelab.jerboa-frog.ts.net/',
  claude: 'https://claude.ai/new/',
  custom: 'https://beta-docs.skriptlang.org/syntaxes/'
};

// Mirrors dark/light mode
const interfaceSettings = new Gio.Settings({ schema: 'org.gnome.desktop.interface' });
const applyColorScheme = () => {
  const dark = interfaceSettings.get_string('color-scheme') === 'prefer-dark';
  Gtk.Settings.get_default()!.gtk_application_prefer_dark_theme = dark;
  Gio.DBus.session.call('rs.wl-gammarelay', '/', 'org.freedesktop.DBus.Properties', 'Set',
    new GLib.Variant('(ssv)', ['rs.wl.gammarelay', 'Temperature', new GLib.Variant('q', dark ? 3500 : 6500)]),
    null, Gio.DBusCallFlags.NO_AUTO_START, -1, null, null);
};
applyColorScheme();
interfaceSettings.connect('changed::color-scheme', applyColorScheme);
Gio.bus_watch_name(Gio.BusType.SESSION, 'rs.wl-gammarelay', Gio.BusNameWatcherFlags.NONE, applyColorScheme, null);

const [ width, setWidth ] = createState(400);

let WebKit: typeof WebKitT;
const loadWebKit = async () => {
  if (WebKit) return;
  WebKit = (await import('gi://WebKit?version=6.0')).default;
  WebKit.WebContext.get_default().set_cache_model(WebKit.CacheModel.DOCUMENT_VIEWER);
};

const dataDir = GLib.get_user_data_dir() + '/ags-sideview';
let networkSession: WebKitT.NetworkSession | null = null;
const getNetworkSession = () => {
  if (networkSession) return networkSession;
  networkSession = new WebKit.NetworkSession({
    data_directory: dataDir,
    cache_directory: GLib.get_user_cache_dir() + '/ags-sideview'
  });
  networkSession.get_cookie_manager().set_persistent_storage(
    dataDir + '/cookies.sqlite',
    WebKit.CookiePersistentStorage.SQLITE
  );
  return networkSession;
};

const stack = new Gtk.Stack();
let webviews: Partial<Record<PageName, WebKitT.WebView>> = {};
let currentPage: PageName | null = null;
let pushedAside = false; // better focus behavior

const getWindow = () => app.get_window('sideview') as Astal.Window;

const setFocused = (focused: boolean) => {
  const window = getWindow();
  window.keymode = focused ? Astal.Keymode.EXCLUSIVE : Astal.Keymode.ON_DEMAND;
  window.exclusivity = (focused && !pushedAside) ? Astal.Exclusivity.IGNORE : Astal.Exclusivity.EXCLUSIVE;
  const dim = app.get_window('sideviewDim');
  if (dim) dim.visible = focused;
};

// Fix clipboard pasting
const PASTE_SHIM_JS = `(function(){
  var mine = false;
  document.addEventListener('paste', function(e){
    if (mine || e.clipboardData.types.length) return;
    var target = e.target;
    e.preventDefault();
    e.stopImmediatePropagation();
    navigator.clipboard.read().then(async function(items){
      var dt = new DataTransfer();
      for (var item of items)
        for (var type of item.types)
          if (/^(image|video)\\//.test(type))
            dt.items.add(new File([await item.getType(type)], 'pasted.' + type.split('/')[1], { type: type }));
      if (!dt.files.length) return;
      mine = true;
      target.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
      mine = false;
    }).catch(function(){});
  }, true); // capture
})();`;

const ensurePage = (name: PageName) => {
  if (webviews[name]) return;
  const contentManager = new WebKit.UserContentManager();
  contentManager.add_script(WebKit.UserScript.new(PASTE_SHIM_JS,
    WebKit.UserContentInjectedFrames.ALL_FRAMES, WebKit.UserScriptInjectionTime.START, null, null));

  const webview = new WebKit.WebView({
    network_session: getNetworkSession(),
    user_content_manager: contentManager
  });

  webview.get_settings().set_user_agent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15');

  webview.connect('permission-request', (_webview, request) => {
    if (request instanceof WebKit.ClipboardPermissionRequest) {
      request.allow(); // allow media pasting!!
      return true;
    }
    return false;
  });

  webview.connect('decide-policy', (_webview, decision, type) => {
    if (type !== WebKit.PolicyDecisionType.NEW_WINDOW_ACTION) return false;
    const uri = (decision as WebKitT.NavigationPolicyDecision).get_navigation_action().get_request().get_uri();
    Gio.AppInfo.launch_default_for_uri(uri, null);
    decision.ignore();
    return true;
  });

  const bg = new Gdk.RGBA();
  bg.parse('#2e3440');
  webview.set_background_color(bg);
  webview.load_uri(urls[name]);
  webviews[name] = webview;
  stack.add_named(webview, name);
};

export const showPage = async (name: PageName) => {
  const window = getWindow();
  if (window.visible && currentPage === name) return hideSideview();

  const freshOpen = !window.visible;
  await loadWebKit();
  ensurePage(name);
  stack.set_visible_child_name(name);
  currentPage = name;
  window.visible = true;
  if (freshOpen) setFocused(true);

  // grab focus
  const webview = webviews[name]!;
  idle(() => currentPage === name && window.visible && webview.grab_focus());
};

export const toggleSideviewFocus = () => {
  const window = getWindow();
  if (!window.visible) return;
  const focused = window.keymode === Astal.Keymode.EXCLUSIVE;
  pushedAside = true; // first focus makes it take screen space only
  setFocused(!focused);
};

export const hideSideview = () => {
  pushedAside = false; // reset
  getWindow().visible = false;
  setFocused(false);
};

// destroys all webviews
export const closeSideview = () => {
  hideSideview();
  for (const webview of Object.values(webviews)) {
    stack.remove(webview);
    webview.terminate_web_process();
    webview.run_dispose();
  }
  webviews = {};
  currentPage = null;

  if (networkSession) {
    networkSession.run_dispose();
    networkSession = null;
  }
};

export const toggleSideviewSize = () => {
  const next = (width.peek() == 400) ? 700 : 400;
  setWidth(next);
  getWindow().set_default_size(next, -1);
};

export default () => {
  inputControl('sideviewDim', () => <box />, { keymode: Astal.Keymode.NONE, layer: Astal.Layer.TOP });

  return <window
    name="sideview"
    visible={false}
    exclusivity={Astal.Exclusivity.IGNORE}
    keymode={Astal.Keymode.ON_DEMAND}
    anchor={TOP | BOTTOM | RIGHT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    widthRequest={width}
  >
    <Gtk.EventControllerKey onKeyPressed={(_, key, __, state) => {
      if (Gdk.keyval_to_lower(key) === Gdk.KEY_r && (state & Gdk.ModifierType.CONTROL_MASK) && currentPage)
        webviews[currentPage]?.reload(); // ctrl+R to reload page
    }} />
    {stack}
  </window>;
};
