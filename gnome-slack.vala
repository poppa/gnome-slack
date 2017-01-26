/*
  Author: Pontus Östlund <https://github.com/poppa>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

using Gtk;
using Gdk;
using WebKit;

public class SlackBrowser : Gtk.Application
{
  private const string TITLE      = "Slack";
  private const string HOME_URL   = "https://slack.com/signin";
  private const string USER_AGENT = "Slack Browser For Gnome - v0.1";
  private const string SLACK_ICON = "Slack_Icon.png";
  private const string APP_NAME   = "Slack";
  private string confdir;
  private string icon_path;

  private Gtk.ApplicationWindow window;
  private WebView web_view;


  public SlackBrowser ()
  {
    Object(application_id: "com.poppa.slack",
           flags: ApplicationFlags.FLAGS_NONE);
  }

  protected override void activate()
  {
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
      stderr.printf ("Unable to resolve Slack icon\n");
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
        stderr.printf ("Unable to create config dir %s\n", confdir);
        Gtk.main_quit ();
      }
    }
  }


  private void setup_icon ()
  {
    icon_path = SLACK_ICON;
  }


  private void create_widgets ()
  {
    var conf = new WebKit.Settings ();
    conf.enable_fullscreen                     = true;
    conf.auto_load_images                      = true;
    conf.enable_html5_local_storage            = true;
    conf.enable_html5_database                 = true;
    conf.enable_offline_web_application_cache  = true;
    conf.enable_media_stream                   = true;
    conf.enable_mediasource                    = true;
    conf.enable_page_cache                     = true;
    conf.enable_plugins                        = true;
    conf.enable_smooth_scrolling               = true;
    conf.javascript_can_access_clipboard       = true;
    conf.media_playback_allows_inline          = true;
    conf.user_agent                            = USER_AGENT;

    web_view = new WebView.with_settings (conf);

    // web_view.resource_load_started.connect (on_load_changed);

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

  // private void on_load_changed (WebKit.WebResource rec, WebKit.URIRequest uri)
  // {
  //   debug ("on_load_changed\n");
  // }

  private void connect_signals ()
  {
  }


  public static int main (string[] args)
  {
    Environment.set_application_name (APP_NAME);
    var app = new SlackBrowser ();
    return app.run (args);
  }
}
