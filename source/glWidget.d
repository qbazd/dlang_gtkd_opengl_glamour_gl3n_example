
import std.string;
import std.stdio;
import std.conv;
import std.random;

import gtk.Widget;
import gdk.Event;

import gdk.GLContext;
import gtk.GLArea;
import gdk.FrameClock;

import glamour.gl;
import glamour.vao: VAO;
import glamour.shader: Shader;
import glamour.vbo: Buffer, ElementBuffer;

import gl3n.linalg;
import gl3n.math;

vec2i to_i(vec2 v){return vec2i(v.x.to!int, v.y.to!int);}


class glEntity1{

    static immutable string example_program_src_ = `
        #version 120
        vertex:
        uniform mat4 MVP;
        attribute vec2 position;
        void main(void)
        {
           gl_Position = MVP * vec4(position, 0, 1);
        }
        fragment:
        void main(void)
        {
            gl_FragColor = vec4(0.3, 0.3, 0.3, 0.5);
        }
        `;

    uint width_, height_;

    float[] vertices;
    ushort[] indices;
    GLint position_;

    VAO vao_;
    Shader program_;
    Buffer vbo_;
    ElementBuffer ibo_;

    this()
    {
        vertices = [ -1.0, -1.0,  1.0, -1.0,  -1.0, 1.0,  1.0, 1.0];
        indices = [0, 1, 2, 3];

        // allocate 
        program_ = new Shader("example_program", example_program_src_);
        ibo_ = new ElementBuffer(indices);
        vbo_ = new Buffer(vertices);
        vao_ = new VAO();

        // this saves the attrib array
        vao_.bind();
          vbo_.bind();
          {
            auto loc = program_.get_attrib_location("position");
            glEnableVertexAttribArray(loc);
            glVertexAttribPointer(loc, 2, GL_FLOAT, GL_FALSE, 0, null);
            //glDisableVertexAttribArray(loc); // no
          }
          vbo_.unbind();
        vao_.unbind();
    }


    void draw(mat4 mvp)
    {
        //writeln("ent1 draw");
        program_.bind();
          // update mvp 
          program_.uniform("MVP",mvp);

          vao_.bind();
            vbo_.bind();
              ibo_.bind();

              glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, null);
           
              ibo_.unbind();
            vbo_.unbind();
          vao_.unbind();
        program_.unbind();
    }

    void close()
    {
        // free resources
        ibo_.remove();
        vbo_.remove();
        vao_.remove();
        program_.remove();
    }

}

struct disk_t {
  GLfloat [2] position;
};

class glEntity2{

    static immutable string example_program_src_ = `
        #version 120
        vertex:
        in vec2 position;
        void main(void)
        {
            gl_Position = vec4(position, 0, 1);
            gl_PointSize = 10.0;
        }
        fragment:

        uniform float alpha;
        uniform float color;
        void main(void)
        {
            gl_FragColor = vec4(color, color, color, alpha);
        }
        `;

    uint width_, height_;

    disk_t [] disks;
    GLint p_attr_position_;

    VAO vao_;
    Shader program_;
    Buffer vbo_;
    

    auto rnd = Random(42);

    void genGeom(){
      disks.length = 1000;
      for (size_t i = 0; i < disks.length; i++ ){
        disks[i].position[0] = uniform( -1.0L, 1.0L, rnd);
        disks[i].position[1] = uniform( -1.0L, 1.0L, rnd);
      }
    }

    this()
    {

        genGeom();

        // Create program
        program_ = new Shader("example_program2", example_program_src_);
        vao_ = new VAO();
        vbo_ = new Buffer(disks, GL_DYNAMIC_DRAW);

        vao_.bind();
          vbo_.bind();
          {
            auto al = program_.get_attrib_location("position");
            glEnableVertexAttribArray(al);
            glVertexAttribPointer(al, 2, GL_FLOAT, GL_FALSE, disk_t.sizeof, null);
          }
          vbo_.unbind();
        vao_.unbind();

    }


    void draw()
    {
        genGeom();

        vbo_.update(disks,0);

        program_.bind();
          program_.uniform1f("alpha", uniform( 0.2L, 0.5L, rnd));
          program_.uniform1f("color", uniform( 0.0L, 0.3L, rnd));

          vao_.bind();
          glDrawArrays(GL_POINTS, 0, cast(int) disks.length ); 
          vao_.unbind();      

        program_.unbind();

    }

    void close()
    {
        // free resources
        vbo_.remove();
        vao_.remove();
        program_.remove();
    }

}


class glWidget : GLArea
{

 
  long last_render_frame_time;
  long framerate_max;
  glEntity1 glent1;
  glEntity2 glent2;
  GLContext con;

  vec2 screen_size = vec2(200.0,200.0);
  vec2 pointer_pos = vec2(100.0,100.0);
  vec2 drag_start = vec2(0.0,0.0);
  bool is_drag = false;
  vec2 space_delta = vec2(0.0,0.0);
  float space_scale = 1.0;
  mat4 mvp;
  mat4 vp;
  mat4 m;

public:
  this()
  {
    setAutoRender(true);

    last_render_frame_time = 0;
    framerate_max = 1000000 / 30;

    mvp_update();

    addOnCreateContext(&initGL);    
    addOnRealize(&realize);
    addOnUnrealize(&unrealize);
    addOnRender(&render);

    addOnResize(&onResize);
  
    addOnButtonPress(&onButtonPress);
    addOnButtonRelease(&onButtonRelease);

    addOnMotionNotify(&onMouseMove);
    // mouse button 
    addTickCallback (&tickCallback);
    // scroll
    addOnScroll(&onScroll);

    showAll();
  }

  GLContext initGL(GLArea area) {

      DerelictGL3.load();
      GLContext context ;
      context = area.getWindow().createGlContext();
      context.realize();
      context.makeCurrent();
      con = context;
      DerelictGL3.reload();

      version(console){
        writeln("init gl ok");
        writefln("Vendor:   %s",   to!string(glGetString(GL_VENDOR)));
        writefln("Renderer: %s",   to!string(glGetString(GL_RENDERER)));
        writefln("Version:  %s",   to!string(glGetString(GL_VERSION)));
        writefln("GLSL:     %s\n", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));
      }

      return context;
  }

  void realize(Widget)
  {
    makeCurrent();
    glent1 = new glEntity1();
    glent2 = new glEntity2();

    version(console) writeln("realize gl ok");
  }

  void vp_update(){

    auto p = mat4.identity();
    auto v = mat4.identity();

    // on resize 
    {
      float left =   0.0;
      float right =  screen_size.x;
      float top =    screen_size.y;
      float bottom = 0.0;
      float near =   -100.0;
      float far =     100.0;
      p = mat4.orthographic(left, right, bottom, top, near, far);
    }

    {
      auto eye    = vec3(0.0, 0.0, 10.0);     // camera is at (4, 3, 3), in World Space.
      auto target = vec3(0.0, 0.0, 0.0);  // it looks at the origin.
      auto up     = vec3(0.0, 1.0, 0);      // head is up (set to 0, -1, 0 to look upside-down).
      v = mat4.look_at(eye, target, up);
    }

    vp = p*v;
  }

  void mvp_update(){

    vp_update();
    // on move 
    // on set scalse
    // on goto
    auto m_ = mat4.identity();
    // 1.scale 2.translate 
    m_.scale(space_scale,space_scale, 1.0);
    m_.translate(space_delta.x,space_delta.y, 0.0);
    m = m_;
    mvp = vp * m;
  }

  vec2 screenCenter(){
    return screen_size / 2.0;
  }
  
  vec2 screenLowerLeft(){
    return vec2(0.0,0.0);
  }
  
  vec2 screenUpperRight(){
    return screen_size;
  }

  // screen to ogl screen coortinates
  vec2 screen2ogl(vec2 screen){
    return vec2(screen.x,(screen_size.y)-screen.y);
  }

  // ogl screen coortinates to real screen coordinates
  vec2 ogl2screen(vec2 ogl){
    return vec2(ogl.x,(screen_size.y)-ogl.y);
  }

/+
    writeln("delta,scale,ss",[space_delta.x, space_delta.y, space_scale], screen_size.to_i);

    auto wc_00 = (m * vec4(100.0, 50.0, 0.0, 1.0) ).xy ;
    writeln("wc[50,50] -> sc", wc_00.to_i);
    // position below the pointer screen -> world coord
    //auto sc_00 = (m.inverse() * vec4(pointer_pos.x, pointer_pos.y, 0.0, 1.0) ).xy;
    auto sc_00 = (m.inverse() * (vec4(0.0, 0.0, 0.0, 1.0)) ).xy ;
    writeln("sc[0,0] -> wc", sc_00.to_i);
+/

  // ogl screen to world coord
  vec2 sc2wc(vec2 sc){
    return (m.inverse() * vec4(sc.x, sc.y, 0.0, 1.0) ).xy;
  }

  //  world coord 2 ogl screen
  vec2 wc2sc(vec2 wc){
    return (m * vec4(wc.x, wc.y, 0.0, 1.0) ).xy;
  }

  void scale_at(vec2 pos, float new_scale){
    auto wc_00 = sc2wc(pos);
    space_scale = new_scale;
    mvp_update();
    space_delta += pos - wc2sc(wc_00);
    mvp_update();
  }

  void unrealize(Widget)
  {
    makeCurrent();
    glent1.close();
    glent1 = null;

    glent2.close();
    glent2 = null;

    version(console) writeln("unrealize gl ok");
  }
  
  bool tickCallback(Widget w, FrameClock fc){
    auto this_frame_time = fc.getFrameTime();

    if ( this_frame_time - last_render_frame_time > framerate_max){
      // animation state advance
      // min frame max frame 
      // speed

      queueDraw();

      last_render_frame_time = this_frame_time;

    }
    return true;
  }

  bool render(GLContext c, GLArea a)
  {
    // is it needed?
    if (c is null) return true;

    glClear (GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    //glViewport (0, 0, 200,200);
    glClearColor (0.1, 0.5, 0.5, 1.0); // bg color
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glEnable(GL_PROGRAM_POINT_SIZE);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

/+

    for(float i = -2.0; i < 10.0; i++)
      for (float j = -2.0; j < 10.0; j++){
        //glent1.draw(p * v * mat4.translation(i, j, 0.0f).scale(10.0,10.0,1.0));
        //mat4.translation(i*5.0, j*5.0, 0.0f)
        glent1.draw(mvp * mat4.translation(i, j, 0.0f).scale(100.0,100.0,1.0));
    }

+/

    glent1.draw(mvp * mat4.identity().scale(100.0,50.0,1.0));
    glent1.draw(mvp * mat4.identity().scale(50.0, 25.0,1.0).translate(50.0, 25.0, 0.0f));
    glent1.draw(mvp * mat4.identity().scale(50.0, 25.0,1.0).translate(-50.0, -25.0, 0.0f));

    //glent2.draw(mvp);
    // hud.render();
    //glFlush();

    return true;
  }


  void onResize( int width,  int height, GLArea glarea){
    //version(console){ writeln("resize");}
    screen_size = vec2 (width, height);
    mvp_update();
  }

  /+
  bool resizeGL(Event event = null) {
      GLfloat w;
      GLfloat h;

      if ( event is null || event.type != GdkEventType.CONFIGURE ) 
      {
        w = getWidth();
        h = getHeight();
      } 
      else 
      {
        w = event.configure.width;
        h = event.configure.height;
      }

      width = w;
      height = h;

      glViewport (0, 0, cast(int)w, cast(int)h); //Adjust the viewport according to new window dimensions 

      return true;
  }
  +/

  bool onButton(Event ev, Widget w){

    version(console){
      //writeln("Mouse scroll event in scene.");
      writeln("button ", ev.button.type);
    }
    
    return true;
  }

  bool onButtonPress(Event ev, Widget w){

    if (ev.type == EventType.BUTTON_PRESS){
      version(console) writeln("button P ", ev.button.type);
      // writeln("Mouse scroll event in scene.");
      is_drag = true;
      drag_start = screen2ogl(vec2(ev.motion.x, ev.motion.y));
    }
    
    return true;
  }

  bool onButtonRelease(Event ev, Widget w){
    version(console) writeln("button R ", ev.button.type);
    
    space_delta += screen2ogl(vec2(ev.motion.x, ev.motion.y)) - drag_start;

    is_drag = false;

    return true;
  }


  bool onScroll(Event ev, Widget w){

    version(console){
      //writeln("scroll ", ev.scroll.direction);
    }

    pointer_pos = screen2ogl(vec2(ev.motion.x, ev.motion.y));
    
    float new_scale = space_scale;
    
    //auto pos = pointer_pos; // at pointer 
    auto pos = screen_size / 2.0; // at screen center 

    if(ev.scroll.direction == ScrollDirection.UP){ 
      scale_at(pos, space_scale / 0.9); 
    }

    if(ev.scroll.direction == ScrollDirection.DOWN){ 
      scale_at(pos, space_scale * 0.9); 
    }
    
    return true;
  }

  bool onMouseMove(Event ev, Widget widget) {
    version(console){
      writefln("move (%d,%d) ", ev.motion.x.to!int, ev.motion.y.to!int);
    }

    pointer_pos = screen2ogl(vec2(ev.motion.x, ev.motion.y));
    version(console) writeln("m ", pointer_pos.to_i);

    if (is_drag){
      space_delta += screen2ogl(vec2(ev.motion.x, ev.motion.y)) - drag_start;
      drag_start = screen2ogl(vec2(ev.motion.x, ev.motion.y));
    }

    mvp_update();
    return true;
  }


}
