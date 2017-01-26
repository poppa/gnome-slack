/*
  Author: Pontus Östlund <https://github.com/poppa>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

/*
  To run with debug enabled, start with:
  G_MESSAGES_DEBUG=all src/gnome-slack
*/

using Gtk;
using Gdk;
using WebKit;

public class SlackBrowser : Gtk.Application
{
  private const string TITLE      = "Slack";
  private const string HOME_URL   = "https://slack.com/signin";
  private const string USER_AGENT = "Slack Browser For Gnome/0.1";
  private const string SLACK_ICON = "Slack_Icon.png";
  private const string APP_NAME   = "Slack";
  private const string APP_ID     = "com.poppa.slack";
  private string confdir;
  private string icon_path;

  private Gtk.ApplicationWindow window;
  private WebView web_view;
  private Notify.Notification notification;

  public SlackBrowser ()
  {
    Object(application_id: APP_ID,
           flags: ApplicationFlags.FLAGS_NONE);
  }

  protected override void activate()
  {
    notification = new Notify.Notification ("", null, null);

    window = new Gtk.ApplicationWindow(this);
    window.title = TITLE;
    window.set_default_size (1200, 800);

    setup_confdir ();
    setup_icon ();

    try {
      var icon = new Gdk.Pixbuf.from_file (icon_path);
      window.set_icon (icon);
    }
    catch (Error e) {
      printerr ("Unable to resolve Slack icon!");
    }

    create_widgets ();
    connect_signals ();
    window.show_all ();
    web_view.load_uri (SlackBrowser.HOME_URL);
  }


  private void setup_confdir()
  {
    confdir = Path.build_filename (Environment.get_user_config_dir (),
                               "gnome-slack");
    if (!FileUtils.test (confdir, FileTest.EXISTS)) {
      if (DirUtils.create (confdir, 0750) == -1) {
        printerr ("Unable to create app config dir \"%s\"", confdir);
        Gtk.main_quit ();
      }
    }
  }


  private void setup_icon ()
  {
    icon_path = get_resource_path (SLACK_ICON);
    debug ("icon_path: %s", icon_path);
  }

  public string? get_resource_path (string local_path)
  {
    // The first and second indices are for local usage during development:
    //   * "data" if executed in the "project" dir.
    //   * "../data" if executed in the "src" dir
    //   * "..." executed elsewhere.
    string[] paths = { "data", "../data",
                       "/usr/local/share/gnome-slack" };

    string full_path = null;

    foreach (string path in paths) {
      full_path = Path.build_filename (path, local_path);
      if (FileUtils.test (full_path, FileTest.EXISTS)) {
        return full_path;
      }
    }

    return null;
  }

  private void create_widgets ()
  {
    var conf = new WebKit.Settings ();

    debug ("conf.enable_fullscreen: %s", conf.enable_fullscreen.to_string());
    debug ("conf.auto_load_images: %s", conf.auto_load_images.to_string());
    debug ("conf.enable_html5_database: %s", conf.enable_html5_database.to_string());
    debug ("conf.enable_html5_local_storage: %s", conf.enable_html5_local_storage.to_string());
    debug ("conf.enable_offline_web_application_cache: %s", conf.enable_offline_web_application_cache.to_string());
    debug ("conf.enable_media_stream: %s", conf.enable_media_stream.to_string());
    debug ("conf.enable_mediasource: %s", conf.enable_mediasource.to_string());
    debug ("conf.enable_page_cache: %s", conf.enable_page_cache.to_string());
    debug ("conf.enable_plugins: %s", conf.enable_plugins.to_string());
    debug ("conf.enable_smooth_scrolling: %s", conf.enable_smooth_scrolling.to_string());
    debug ("conf.javascript_can_access_clipboard: %s", conf.javascript_can_access_clipboard.to_string());
    debug ("conf.media_playback_allows_inline: %s", conf.media_playback_allows_inline.to_string());
    debug ("conf.user_agent: %s", conf.user_agent);

    conf.enable_media_stream                    = true;
    conf.enable_mediasource                     = true;
    conf.enable_smooth_scrolling                = true;
    conf.javascript_can_access_clipboard        = true;
    conf.user_agent                            += " " + USER_AGENT;

    web_view = new WebView.with_settings (conf);
    web_view.create.connect (on_create);
    web_view.show_notification.connect (on_show_notification);
    web_view.permission_request.connect (perm => {
      debug ("permission_request");
      perm.allow ();
      return true;
    });
    web_view.load_changed.connect (on_load_changed);
    web_view.notify["title"].connect ((s, p) => {
      if (web_view.title != null && web_view.title.length > 0) {
        window.title = web_view.title;
      }
    });

    var ctx = web_view.get_context ();
    var cookiefile = Path.build_filename (confdir, "cookies");
    var cm = ctx.get_cookie_manager ();
    cm.set_accept_policy (CookieAcceptPolicy.ALWAYS);
    cm.set_persistent_storage (cookiefile, CookiePersistentStorage.TEXT);

    var scrolled_window = new ScrolledWindow (null, null);
    scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    scrolled_window.add (web_view);

    window.add (scrolled_window);
  }


  private void open_default_browser(string uri)
  {
    debug ("Nav to: %s", uri);

    try {
      Process.spawn_command_line_async ("xdg-open \"" + uri.escape ("") + "\"");
    }
    catch (Error e) {
      printerr ("Failed opeing uri \"%s\": %s\"", uri, e.message);
    }
  }


  private Gtk.Widget on_create (WebKit.NavigationAction nav)
  {
    var uri = nav.get_request ();
    open_default_browser (uri.get_uri ());
    return null;
  }


  private bool on_show_notification (WebKit.Notification n)
  {
    debug ("on_show_notification: %s (%s)", n.get_title (), icon_path);
    debug ("body: %s", n.get_body ());

    notification.update (n.get_title(), n.get_body (), icon_path);

    try {
      notification.show ();
    }
    catch (Error e) {
      printerr ("Unable to show notification: %s", e.message);
    }

    return true;
  }

  private void on_load_changed (WebKit.LoadEvent ev)
  {
  }

  private void connect_signals ()
  {
  }


  public static int main (string[] args)
  {
    Environment.set_application_name (APP_NAME);
    if (Notify.init (APP_ID)) {
      debug ("Libnotify inited\n");
    }
    var app = new SlackBrowser ();
    return app.run (args);
  }
}
