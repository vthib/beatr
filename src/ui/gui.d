module gui;

import std.stdio;
import std.file;

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
}

Analyzer a;
Options opt;

bool
process(string f)
{
    bool hadError = false;
    DirEntry d;

    try {
        d = DirEntry(f);
    } catch (FileException e) {
        io.stderr.writefln("error: %s", e.msg);
        return true;
    }

    if (d.isFile) {
        Beatr.writefln(Lvl.verbose, "Processing '%s'...", f);
        try {
            if (opt.seconds != 0)
                a.processFile(f, opt.seconds);
            else
                a.processFile(f);

            auto s = a.score(opt.profile, opt.corr);
            auto k = s.bestKey();
            io.writefln("%s\t%s\t%.2s", f, k, s.confidence);
        } catch (LibAvException e) {
            hadError = true;
            io.stderr.writefln("%s\n", e.msg);
        }
    } else if (d.isDir)
        foreach (name; dirEntries(f, SpanMode.breadth))
            hadError |= process(name);
    else
        io.stderr.writefln("'%s' is neither a file nor a directory", f);

    return hadError;
}

void main(string[] args)
{
    opt.profile = ProfileType.chordNormalized;
    opt.wcurve = Beatr.weightCurve;
    opt.seconds = 150;

    beatrInit();
    scope(exit) beatrCleanup();

    a = new Analyzer();

    Main.init(args);
    MainWindow win = new MainWindow("Beatr");
    win.setDefaultSize(250, 200);
  
    MenuBar menuBar = new MenuBar();  
    menuBar.append(new FileMenuItem(win));
 
    Box box = new Box(Orientation.VERTICAL, 10);
    box.packStart(menuBar, false, false, 0);
 
    win.add(box);
    win.showAll();
    Main.run();
}

class FileMenuItem : MenuItem
{
    Menu fileMenu;
    MenuItem exitMenuItem;
    MenuItem chooseFile;
    Window win;
   
    this(Window win)
    {
        super("File");
        fileMenu = new Menu();
       
        this.win = win;
        chooseFile = new MenuItem("Open a file");
        chooseFile.addOnButtonRelease(&selectFile);
        fileMenu.append(chooseFile);

        exitMenuItem = new MenuItem("Exit");
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
        auto s = new SelectFile(win);
        auto res = s.run();

        if (res == ResponseType.OK) {
            res = process(s.getFilename());
            std.stdio.writefln("res: %d", res);
        } else {
            std.stdio.writefln("canceled");
        }
        s.destroy();

        return true;
    }
}

class SelectFile : FileChooserDialog
{
    this(Window win)
    {
        super("Choose a file", win, GtkFileChooserAction.OPEN);
    }
}
       
