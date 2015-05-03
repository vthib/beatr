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
import std.algorithm;

import gdk.Event;
import glib.Idle;
import glib.Str;
import gtk.Box;
import gtk.Button;
import gtk.CellRendererProgress;
import gtk.CellRendererText;
import gtk.CheckButton;
import gtk.FileChooserDialog;
import gtk.FileFilter;
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
import gtkc.glibtypes;

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

/* {{{ Tags */

struct Tags {
    string title = "";
    string artist = "";
    string comment = "";
    string key = "";
    char fbuf[];
    ID3Tag *tag;

    this(in string f)
    {
        fbuf = new char[f.length + 1];
        fbuf[0..f.length] = f[];
        fbuf[f.length] = 0;

        tag = ID3Tag_New();
        ID3Tag_Link(tag, fbuf.ptr);
    }

    ~this()
    {
        ID3Tag_Delete(tag);
        delete fbuf;
    }

    void loadTags()
    {
        loadTag(ID3_FrameID.ID3FID_TITLE, this.title);
        loadTag(ID3_FrameID.ID3FID_LEADARTIST, this.artist);
        loadTag(ID3_FrameID.ID3FID_COMMENT, this.comment);
        loadTag(ID3_FrameID.ID3FID_INITIALKEY, this.key);
    }

    void writeKey(string key, bool inComment)
    {
        writeTag(ID3_FrameID.ID3FID_INITIALKEY, key);
        if (inComment) {
            writeTag(ID3_FrameID.ID3FID_COMMENT, key);
        }
    }

  private:
    void writeTag(ID3_FrameID type, in string f)
    {
        char buf[];
        buf.length = f.length + 1;
        buf[0..f.length] = f[];
        buf[f.length] = 0;

        ID3Frame *frame = ID3Tag_FindFrameWithID(tag, type);
        if (frame !is null) {
            ID3Frame_Clear(frame);
        }

        frame = ID3Frame_NewID(type);
        ID3Tag_AttachFrame(tag, frame);

        ID3Field *field = ID3Frame_GetField(frame, ID3_FieldID.ID3FN_TEXT);
        ID3Field_SetASCII(field, buf.ptr);

        ID3Tag_Update(tag);
    }

    void loadTag(ID3_FrameID type, out string f)
    {
        ID3Frame *frame = ID3Tag_FindFrameWithID(tag, type);
        if (frame !is null) {
            f = frameToString(frame);
        }
    }

    string frameToString(ID3Frame *frame)
    {
        ID3Field *field = ID3Frame_GetField(frame, ID3_FieldID.ID3FN_TEXT);
        //ID3_TextEnc enc = ID3Field_GetEncoding(field);
        char buf[];

        //ID3Field_SetEncoding(field, ID3_TextEnc.ID3TE_ISO8859_1);
        buf.length = 1024;
        buf.length = ID3Field_GetASCII(field, buf.ptr, 1024);
        //ID3Field_SetEncoding(field, enc);
        return buf.idup.toUTF8;
    }
}

/* }}} */
/* {{{ Song */

struct Song {
    string filename;
    Tags   tags;
    Note   key;
    int    progress;

    this(in string f)
    {
        filename = f.idup;
        tags = Tags(f);
        tags.loadTags();
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

    void saveResults()
    {
        if (song.key !is null) {
            string key = data.useCodes ? song.key.toCode : song.key.toString;

            song.tags.writeKey(key, true);
            song.tags.loadTags();
            updateSong();
        }
    }
}

void addFile(string f)
{
    DirEntry d;

    try {
        d = DirEntry(f);
    } catch (FileException e) {
        io.stderr.writefln("error: %s", e.msg);
        return;
    }

    if (d.isFile && f.endsWith(".mp3")) {
        Song *song = new Song(d.name);
        auto iter = data.list.addSong(song);
        auto treeRef = new TreeRowReference(data.list, iter.getTreePath());
        auto p = new Process(song, treeRef);
        data.rows ~= p;
        p.updateSong();
    } else if (d.isDir) {
        foreach (name; dirEntries(f, SpanMode.shallow)) {
            addFile(name);
        }
    } else {
        io.stderr.writefln("'%s' is neither a mp3 file nor a directory", f);
    }
}

/* }}} */

class MainInterface
{
    SongTreeView treeView;

    public this()
    {
        data.main = new MainWindow("Beatr");
        data.main.setDefaultSize(1024, 600);

        Box vbox = new Box(Orientation.VERTICAL, 10);

        MenuBar menuBar = new MenuBar();
        menuBar.append(new FileMenuItem());
        vbox.packStart(menuBar, false, false, 0);

        Box hbox = new Box(Orientation.HORIZONTAL, 10);
        auto camelotButton = new CheckButton("Use Camelot Codes", &toggleCamelot);
        hbox.packStart(camelotButton, false, false, 0);
        vbox.packStart(hbox, false, false, 0);

        data.list = new SongListStore();
        treeView = new SongTreeView(data.list);
        treeView.getSelection().setMode(GtkSelectionMode.MULTIPLE);
        auto scroll = new ScrolledWindow(null, null);
        scroll.setPolicy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add(treeView);
        vbox.packStart(scroll, true, true, 0);

        hbox = new Box(Orientation.HORIZONTAL, 10);
        auto analyzeButton = new Button("Start analysis", &analyze);
        hbox.packEnd(analyzeButton, false, false, 10);
        auto saveButton = new Button("Save tags", &saveTags);
        hbox.packEnd(saveButton, false, false, 10);
        vbox.packStart(hbox, false, false, 10);

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

    private void saveTags(Button button)
    {
        auto selection = treeView.getSelection();

        if (selection.countSelectedRows() == 0) {
            foreach (p; data.rows) {
                p.saveResults();
            }
        } else {
            TreeModelIF model;
            auto list = selection.getSelectedRows(model);

            foreach (path; list) {
                auto p = data.rows[path.getIndices()[0]];
                p.saveResults();
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

    bool addSelection(SelectFile s)
    {
        auto res = s.run();

        if (res == ResponseType.OK) {
            auto list = s.getFilenames();

            while (list !is null) {
                string str = Str.toString(cast(char *)list.data);
                addFile(str);
                list = list.next();
            }
        }
        s.destroy();

        return true;
    }

    bool selectFile(Event event, Widget widget)
    {
        return addSelection(new SelectFile(true));
    }

    bool selectDir(Event event, Widget widget)
    {
        return addSelection(new SelectFile(false));
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

        auto filter = new FileFilter();
        filter.addPattern("*.mp3");
        filter.setName("mp3 files");
        addFilter(filter);

        setLocalOnly(true);
        setSelectMultiple(true);
    }
}

/* }}} */
/* }}} */
/* {{{ Tree */

enum {
    FILENAME = 0,
    ARTIST,
    TITLE,
    COMMENT,
    TAGKEY,
    FOUNDKEY,
    PROGRESS
};

/* {{{ List Store */

class SongListStore : ListStore
{
    this()
    {
        super([GType.STRING, GType.STRING, GType.STRING, GType.STRING,
               GType.STRING, GType.STRING, GType.INT]);
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
        setValue(iter, ARTIST,  s.tags.artist);
        setValue(iter, TITLE,   s.tags.title);
        setValue(iter, COMMENT, s.tags.comment);
        setValue(iter, TAGKEY,  s.tags.key);
        if (s.key !is null) {
            string key = data.useCodes ? s.key.toCode : s.key.toString;

            setValue(iter, FOUNDKEY, key);
        }
        setValue(iter, PROGRESS, s.progress);
    }
}

/* }}} */
/* {{{ Tree View */

class SongTreeView : TreeView
{
    this(ListStore store)
    {
        auto column = new TreeViewColumn("Filename", new CellRendererText(),
                                         "text", FILENAME);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        column = new TreeViewColumn("Artist", new CellRendererText(),
                                    "text", ARTIST);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        column = new TreeViewColumn("Title", new CellRendererText(),
                                    "text", TITLE);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        column = new TreeViewColumn("Comment", new CellRendererText(),
                                    "text", COMMENT);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        column = new TreeViewColumn("Stored Key", new CellRendererText(),
                                    "text", TAGKEY);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        column = new TreeViewColumn("Analyzed Key", new CellRendererText(),
                                    "text", FOUNDKEY);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        column = new TreeViewColumn("Progress", new CellRendererProgress(),
                                    "value", PROGRESS);
        column.setResizable(true);
        column.setExpand(false);
        appendColumn(column);

        setModel(store);
    }
}

/* }}} */
/* }}} */
