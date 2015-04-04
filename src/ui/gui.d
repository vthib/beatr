module gui;

import std.stdio;
import std.file;
import std.parallelism;
import std.conv;
import std.range : iota;

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
import gtk.CellRendererProgress;
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

    TaskPool taskPool;
};

Data data;
Analyzer a = null;

/* {{{ Process */

struct Process {
    string f;
    TreeIter iter;
    string k;
    int progress;

    this(string file, TreeIter it)
    {
        f = file;
        iter = it;
    }

    void run()
    {
        if (a is null) {
            synchronized {
                a = new Analyzer();
            }
        }
        a.setProgressCallback(&progressCb);

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
    }

    void progressCb(int p)
    {
        progress = p;
        new Idle(&updateProgress);
    }

    bool updateProgress()
    {
        data.list.setProgress(iter, progress);
        return false;
    }

    bool updateKey()
    {
        data.list.setKey(iter, k);
        return false;
    }
}

/* }}} */

void main(string[] args)
{
    data.opt.profile = ProfileType.chordNormalized;
    data.opt.wcurve = Beatr.weightCurve;
    data.opt.seconds = 150;

    data.taskPool = new TaskPool(1);

    beatrInit();
    scope(exit) beatrCleanup();

    Main.init(args);
    data.main = new MainWindow("Beatr");
    data.main.setDefaultSize(800, 600);

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

        auto chooseDir = new MenuItem("Open a folder");
        chooseDir.addOnButtonRelease(&selectDir);
        fileMenu.append(chooseDir);

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

    static void addFile(string f)
    {
        DirEntry d;

        try {
            d = DirEntry(f);
        } catch (FileException e) {
            io.stderr.writefln("error: %s", e.msg);
            return;
        }

        if (d.isFile) {
            auto iter = data.list.addSong(f);
            auto p = new Process(f, iter);
            auto task = task(&p.run);

            data.taskPool.put(task);
        } else if (d.isDir) {
            foreach (name; dirEntries(f, SpanMode.breadth)) {
                addFile(name);
            }
        } else {
            io.stderr.writefln("'%s' is neither a file nor a directory", f);
        }
    }

    bool selectFile(Event event, Widget widget)
    {
        auto s = new SelectFile(true);
        auto res = s.run();

        if (res == ResponseType.OK) {
            addFile(s.getFilename());
        }
        s.destroy();

        return true;
    }

    bool selectDir(Event event, Widget widget)
    {
        auto s = new SelectFile(false);
        auto res = s.run();

        if (res == ResponseType.OK) {
            addFile(s.getFilename());
        }
        s.destroy();

        return true;
    }
}

class SelectFile : FileChooserDialog
{
    this(in bool only_file)
    {
        if (only_file) {
            super("Choose a file", data.main, GtkFileChooserAction.OPEN);
        } else {
            super("Choose a folder", data.main, GtkFileChooserAction.SELECT_FOLDER);
        }
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

        progressColumn = new TreeViewColumn("Progress", new CellRendererProgress(),
                                            "value", 2);
        appendColumn(progressColumn);
 
        setModel(store);
    }
}

/* }}} */
/* {{{ List Store */

class SongListStore : ListStore
{
    enum {
        FILENAME = 0,
        KEY      = 1,
        PROGRESS = 2
    };

    this()
    {
        super([GType.STRING, GType.STRING, GType.INT]);
    }
 
    public TreeIter addSong(in string name)
    {
        TreeIter iter = createIter();
        setValue(iter, FILENAME, name);
        setValue(iter, PROGRESS, 0);

        return iter;
    }

    public void setKey(TreeIter iter, in string key)
    {
        setValue(iter, PROGRESS, 100);
        setValue(iter, KEY, key);
    }

    public void setProgress(TreeIter iter, in int progress)
    {
        setValue(iter, PROGRESS, progress);
    }
}

/* }}} */
/* }}} */
