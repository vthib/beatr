module gui;

import std.stdio;
import std.file;
import std.parallelism;
import std.conv;

import gtk.MainWindow;
import gtk.Box;
import gtk.Main;
import gtk.Menu;
import gtk.MenuBar;
import gtk.MenuItem;
import gtk.Widget;
import gtk.Window;
import gdk.Event;
import gtk.FileChooserDialog;
import gtkc.gtktypes;
import gtk.TreeIter;
import gtk.ListStore;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.CellRendererText;
import glib.Idle;

import util.weighting;
import analysis.analyzer;
import chroma.chromaprofile;
import util.beatr;
import exc.libavexception;

struct Options {
    ProfileType profile;
    CorrelationMethod corr;
    WeightCurve wcurve;
    size_t seconds;
};

struct Data {
    Options opt;

    MainWindow main;

    SongListStore list;
};

Data data;

/* {{{ Process */

struct Process {
    string f;
    Analyzer a;
    TreeIter iter;
    string k;

    void run()
    {
        DirEntry d;

        try {
            d = DirEntry(f);
        } catch (FileException e) {
            io.stderr.writefln("error: %s", e.msg);
            return;
        }

        if (d.isFile) {
            Beatr.writefln(Lvl.verbose, "Processing '%s'...", f);
            try {
                if (data.opt.seconds != 0)
                    a.processFile(f, data.opt.seconds);
                else
                    a.processFile(f);

                auto s = a.score(data.opt.profile, data.opt.corr);
                k = to!string(s.bestKey());

                new Idle(&updateKey);
            } catch (LibAvException e) {
                io.stderr.writefln("%s\n", e.msg);
                /* TODO err */
                return;
            }
        } else if (d.isDir) {
            foreach (name; dirEntries(f, SpanMode.breadth)) {
                auto newIter = data.list.addSong(f);
                auto p = new Process(name, new Analyzer(), newIter);
                auto task = task(&p.run);

                taskPool.put(task);
            }
        } else {
            io.stderr.writefln("'%s' is neither a file nor a directory", f);
        }
    }

    bool updateKey() {
        data.list.setKey(iter, k);
        return true;
    }
}

/* }}} */

void main(string[] args)
{
    data.opt.profile = ProfileType.chordNormalized;
    data.opt.wcurve = Beatr.weightCurve;
    data.opt.seconds = 150;

    beatrInit();
    scope(exit) beatrCleanup();

    Main.init(args);
    data.main = new MainWindow("Beatr");
    data.main.setDefaultSize(250, 200);

    MenuBar menuBar = new MenuBar();
    menuBar.append(new FileMenuItem());

    data.list = new SongListStore();
    auto treeView = new SongTreeView(data.list);

    Box box = new Box(Orientation.VERTICAL, 10);
    box.packStart(menuBar, false, false, 0);
    box.packStart(treeView, false, false, 0);

    data.main.add(box);
    data.main.showAll();
    Main.run();
}

/* {{{ Menu */
/* {{{ File Item */

class FileMenuItem : MenuItem
{
    Menu fileMenu;

    this()
    {
        super("File");
        fileMenu = new Menu();

        auto chooseFile = new MenuItem("Open a file");
        chooseFile.addOnButtonRelease(&selectFile);
        fileMenu.append(chooseFile);

        auto exitMenuItem = new MenuItem("Exit");
        exitMenuItem.addOnButtonRelease(&exit);
        fileMenu.append(exitMenuItem);

        setSubmenu(fileMenu);
    }

    bool exit(Event event, Widget widget)
    {
        Main.quit();
        return true;
    }

    bool selectFile(Event event, Widget widget)
    {
        auto s = new SelectFile();
        auto res = s.run();

        if (res == ResponseType.OK) {
            auto f = s.getFilename();
            auto iter = data.list.addSong(f);
            auto p = new Process(f, new Analyzer(), iter);
            auto task = task(&p.run);

            taskPool.put(task);
        }
        s.destroy();

        return true;
    }
}

class SelectFile : FileChooserDialog
{
    this()
    {
        super("Choose a file", data.main, GtkFileChooserAction.OPEN);
    }
}

/* }}} */
/* }}} */
/* {{{ Tree */
/* {{{ Tree View */

class SongTreeView : TreeView
{
    private TreeViewColumn filenameColumn;
    private TreeViewColumn keyColumn;
    private TreeViewColumn progressColumn;
 
    this(ListStore store)
    { 
        filenameColumn = new TreeViewColumn("Filename", new CellRendererText(),
                                            "text", 0);
        appendColumn(filenameColumn);
 
        keyColumn = new TreeViewColumn("Key", new CellRendererText(),
                                       "text", 1);
        appendColumn(keyColumn);

        progressColumn = new TreeViewColumn("Progress", new CellRendererText(),
                                            "text", 2);
        appendColumn(progressColumn);
 
        setModel(store);
    }
}

/* }}} */
/* {{{ List Store */

class SongListStore : ListStore
{
    enum {
        FILENAME,
        KEY,
        PROGRESS
    };

    this()
    {
        super([GType.STRING, GType.STRING, GType.STRING]);
    }
 
    public TreeIter addSong(in string name)
    {
        TreeIter iter = createIter();
        setValue(iter, FILENAME, name);
        setValue(iter, PROGRESS, "0");

        return iter;
    }

    public void setKey(TreeIter iter, in string key)
    {
        setValue(iter, PROGRESS, "100");
        setValue(iter, KEY, key);
    }
}

/* }}} */
/* }}} */
