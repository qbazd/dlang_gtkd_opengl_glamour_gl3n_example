
import std.string;

import gio.Application : GioApplication = Application;
import gtk.Application;
import gtk.ApplicationWindow;
import gtk.DrawingArea;
import gtk.Widget;
import gtk.Button;
import gtk.VBox;
import gtk.HBox;

import std.stdio;
import std.conv;

import glWidget;
//import glad.gl.loader;

int main(string[] args)
{
    Application application;

    //writeln(gladLoadGL()); // optionally you can pass a loader to this function
    //writefln("OpenGL Version %d.%d loaded", GLVersion.major, GLVersion.minor);
/+
    writefln("Vendor:   %s",   to!string(glGetString(GL_VENDOR)));
    writefln("Renderer: %s",   to!string(glGetString(GL_RENDERER)));
    writefln("Version:  %s",   to!string(glGetString(GL_VERSION)));
    writefln("GLSL:     %s\n", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));
+/

/+
    if(GL_EXT_framebuffer_multisample) { 
      /* GL_EXT_framebuffer_multisample is supported */ 
    }

    if(GL_VERSION_3_0) {
      /* We support at least OpenGL version 3 */
    }
+/



    void activateCoreGL(GioApplication app)
    {
    auto mainWnd = new ApplicationWindow(application);
    mainWnd.setTitle("DESIGN visualisation tool");
    
    VBox box = new VBox(false,2);
    auto wnd_gl = new glWidget;
    box.add(wnd_gl);

    mainWnd.add(box);
    mainWnd.showAll();

    }

    application = new Application("org.gtkd.demo.gl.core", GApplicationFlags.FLAGS_NONE);
    application.addOnActivate(&activateCoreGL);
    return application.run(args);
}

