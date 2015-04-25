module gui;

import std.stdio;
import std.file;
import std.parallelism;
import std.conv;
import std.range : iota;
import std.string;
import core.stdc.string : strlen;
import std.utf;
import std.bitmanip;

import gdk.Event;
import glib.Idle;
import gtk.Box;
import gtk.Button;
import gtk.CellRendererProgress;
import gtk.CellRendererText;
import gtk.CheckButton;
import gtk.FileChooserDialog;
import gtk.ListStore;
import gtk.Main;
import gtk.MainWindow;
import gtk.Menu;
import gtk.MenuBar;
import gtk.MenuItem;
import gtk.ScrolledWindow;
import gtk.TreeIter;
import gtk.TreeModelIF;
import gtk.TreeRowReference;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.Widget;
import gtk.Window;
import gtkc.glib;
import gtkc.gtktypes;

import util.weighting;
import analysis.analyzer;
import chroma.chromaprofile;
import util.beatr;
import exc.libavexception;
import id3lib.id3lib;
import util.note;

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

    Process* rows[];

    bool useCodes;
};

__gshared Data data;
Analyzer a = null;

/* {{{ Process */

string frameToString(ID3Frame *frame)
{
    ID3Field *field = ID3Frame_GetField(frame, ID3_FieldID.ID3FN_TEXT);
    ID3_TextEnc enc = ID3Field_GetEncoding(field);
    char buf[];

    ID3Field_SetEncoding(field, ID3_TextEnc.ID3TE_ISO8859_1);
    buf.length = 1024;
    buf.length = ID3Field_GetASCII(field, buf.ptr, 1024);
    ID3Field_SetEncoding(field, enc);
    return buf.idup.toUTF8;
}

struct Song {
    string filename;
    string artist = "";
    string title = "";
    Note key;
    int progress;

    this(in string f)
    {
        filename = f.idup;
        char[] copy;

        copy = new char[f.length + 1];
        copy[0..f.length] = f[];
        copy[f.length] = 0;

        ID3Tag *tag = ID3Tag_New();
        ID3Tag_Link(tag, copy.ptr);

        /*
        ID3TagIterator *it = ID3Tag_CreateIterator(tag);
        ID3Frame *frame = null;
        while ((frame = ID3TagIterator_GetNext(it)) !is null) {
            writefln("frame id: %s", ID3Frame_GetID(frame));
            ID3Field *field = ID3Frame_GetField(frame, ID3_FieldID.ID3FN_TEXT);

            if (field !is null) {
                wchar wbuf[];

                wbuf.length = 1024;
                wbuf.length = ID3Field_GetUNICODE(field, wbuf.ptr, 1024);
                wbuf.length /= 2;
                foreach(ref w; wbuf) {
                    ubyte a[2] = [ w & 0xFF, (w >> 8) & 0xFF ];
                    w = bigEndianToNative!(wchar)(a);
                }
                title = wbuf.idup.toUTF8;
            }
        }
        ID3TagIterator_Delete(it);
        */

        ID3Frame *frame = ID3Tag_FindFrameWithID(tag, ID3_FrameID.ID3FID_TITLE);
        if (frame !is null) {
            title = frameToString(frame);
        }

        frame = ID3Tag_FindFrameWithID(tag, ID3_FrameID.ID3FID_LEADARTIST);
        if (frame !is null) {
            artist = frameToString(frame);
        }

        ID3Tag_Delete(tag);
    }
};

extern(C)
int updateRowInGUI(Process *p)
{
    auto iter = new TreeIter(data.list, p.treeRef.getPath());

    data.list.updateSong(iter, p.song);
    return false;
}

struct Process {
    Song *song;
    TreeRowReference treeRef;

    void run()
    {
        song.progress = 0;
        song.key = null;
        updateSong();

        if (a is null) {
            synchronized {
                a = new Analyzer();
            }
        }
        a.setProgressCallback(&progressCb);

        try {
            if (data.opt.seconds != 0)
                a.processFile(song.filename, data.opt.seconds);
            else
                a.processFile(song.filename);

            auto s = a.score(data.opt.profile, data.opt.corr);
            song.key = s.bestKey();
            song.progress = 100;

            updateSong();
        } catch (LibAvException e) {
            io.stderr.writefln("%s\n", e.msg);
            /* TODO err */
            return;
        }
    }

    void progressCb(int p)
    {
        song.progress = p;
        updateSong();
    }

    void updateSong()
    {
        g_idle_add(cast(GSourceFunc)&updateRowInGUI, cast(void *)&this);
    }
}

/* }}} */

class MainInterface
{
    SongTreeView treeView;

    public this()
    {
        data.main = new MainWindow("Beatr");
        data.main.setDefaultSize(800, 600);

        Box vbox = new Box(Orientation.VERTICAL, 10);

        MenuBar menuBar = new MenuBar();
        menuBar.append(new FileMenuItem());
        vbox.packStart(menuBar, false, false, 0);

        Box hbox = new Box(Orientation.HORIZONTAL, 10);
        auto camelotButton = new CheckButton("Use Camelot Codes", &toggleCamelot);
        hbox.packStart(camelotButton, false, false, 0);
        auto analyzeButton = new Button("Start analysis", &analyze);
        hbox.packStart(analyzeButton, false, false, 0);
        vbox.packStart(hbox, false, false, 0);

        data.list = new SongListStore();
        treeView = new SongTreeView(data.list);
        treeView.getSelection().setMode(GtkSelectionMode.MULTIPLE);
        auto scroll = new ScrolledWindow(null, null);
        scroll.setPolicy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add(treeView);
        vbox.packStart(scroll, true, true, 0);

        data.main.add(vbox);
        data.main.showAll();
    }

    private void toggleCamelot(CheckButton button)
    {
        data.useCodes = button.getActive();
        foreach (p; data.rows) {
            p.updateSong();
        }
    }

    private void analyze(Button button)
    {
        auto selection = treeView.getSelection();

        if (selection.countSelectedRows() == 0) {
            foreach (p; data.rows) {
                auto task = task(&p.run);

                taskPool.put(task);
            }
        } else {
            TreeModelIF model;
            auto list = selection.getSelectedRows(model);

            foreach (path; list) {
                auto p = data.rows[path.getIndices()[0]];
                auto task = task(&p.run);

                taskPool.put(task);
            }
        }
    }
}

void main(string[] args)
{
    data.opt.profile = ProfileType.chordNormalized;
    data.opt.wcurve = Beatr.weightCurve;
    data.opt.seconds = 150;
    data.useCodes = false;

    beatrInit();
    scope(exit) beatrCleanup();

    Main.init(args);
    MainInterface m = new MainInterface();
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
            Song *song = new Song(d.name);
            auto iter = data.list.addSong(song);
            auto treeRef = new TreeRowReference(data.list, iter.getTreePath());
            auto p = new Process(song, treeRef);
            data.rows ~= p;
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
    this(ListStore store)
    {
        auto column = new TreeViewColumn("Filename", new CellRendererText(),
                                         "text", 0);
        column.setResizable(true);
        appendColumn(column);

        column = new TreeViewColumn("Artist", new CellRendererText(),
                                    "text", 1);
        column.setResizable(true);
        appendColumn(column);

        column = new TreeViewColumn("Title", new CellRendererText(),
                                    "text", 2);
        column.setResizable(true);
        appendColumn(column);

        column = new TreeViewColumn("Key", new CellRendererText(),
                                    "text", 3);
        column.setResizable(true);
        appendColumn(column);

        column = new TreeViewColumn("Progress", new CellRendererProgress(),
                                    "value", 4);
        column.setResizable(true);
        appendColumn(column);

        setModel(store);
    }
}

/* }}} */
/* {{{ List Store */

class SongListStore : ListStore
{
    enum {
        FILENAME = 0,
        ARTIST,
        TITLE,
        KEY,
        PROGRESS
    };

    this()
    {
        super([GType.STRING, GType.STRING, GType.STRING, GType.STRING, GType.INT]);
    }

    public TreeIter addSong(Song *s)
    {
        TreeIter iter = createIter();
        iter.setModel(this);
        updateSong(iter, s);

        return iter;
    }

    public void updateSong(TreeIter iter, Song *s)
    {
        setValue(iter, FILENAME, std.path.baseName(s.filename));
        setValue(iter, ARTIST, s.artist);
        setValue(iter, TITLE, s.title);
        if (s.key !is null) {
            string key = data.useCodes ? s.key.toCode : s.key.toString;

            setValue(iter, KEY, key);
        }
        setValue(iter, PROGRESS, s.progress);
    }
}

/* }}} */
/* }}} */
