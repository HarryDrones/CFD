

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.ArrayList; 
import com.thomasdiewald.pixelflow.java.DwPixelFlow; 
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram; 
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D; 
import com.thomasdiewald.pixelflow.java.fluid.DwFluidStreamLines2D; 
import processing.core.*; 
import processing.opengl.PGraphics2D; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 



/**
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */















  // Windtunnel, combining most of the other examples.

  private class MyFluidData implements DwFluid2D.FluidData{
    
    @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {
    
      float px, py, vx, vy, radius, vscale;


      
      
      
      
      
      
      
  
      // use the text as input for density
      float mix_density  = fluid.simulation_step == 0 ? 1.0f : 0.05f;
      float mix_velocity = fluid.simulation_step == 0 ? 1.0f : 0.5f;
      
      addDensityTexture (fluid, pg_density , mix_density);
      addVelocityTexture(fluid, pg_velocity, mix_velocity);
    }
    
    
    // custom shader, to add velocity from a texture (PGraphics2D) to the fluid.
    public void addVelocityTexture(DwFluid2D fluid, PGraphics2D pg, float mix){
      int[] pg_tex_handle = new int[1]; 
//      pg_tex_handle[0] = pg.getTexture().glName
      context.begin();
      context.getGLTextureHandle(pg, pg_tex_handle);
      context.beginDraw(fluid.tex_velocity.dst);
      DwGLSLProgram shader = context.createShader("data/addVelocity.frag");
      shader.begin();
      shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
      shader.uniform1i     ("blend_mode", 6);   
      shader.uniform1f     ("mix_value" , mix);     
      shader.uniform1f     ("multiplier", 1);     
      shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
      shader.uniformTexture("tex_src"   , fluid.tex_velocity.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end();
      fluid.tex_velocity.swap();
    }
    
    // custom shader, to add density from a texture (PGraphics2D) to the fluid.
    public void addDensityTexture(DwFluid2D fluid, PGraphics2D pg, float mix){
      int[] pg_tex_handle = new int[1]; 
//      pg_tex_handle[0] = pg.getTexture().glName
      context.begin();
      context.getGLTextureHandle(pg, pg_tex_handle);
      context.beginDraw(fluid.tex_density.dst);
      DwGLSLProgram shader = context.createShader("data/addDensity.frag");
      shader.begin();
      shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
      shader.uniform1i     ("blend_mode", 2);   
      shader.uniform1f     ("mix_value" , mix);     
      shader.uniform1f     ("multiplier", 1);     
      shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
      shader.uniformTexture("tex_src"   , fluid.tex_density.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end();
      fluid.tex_density.swap();
    }
 
  }
  
  
  int viewport_w = 1280;
  int viewport_h = 720;
  int viewport_x = 230;
  int viewport_y = 0;
  
  int gui_w = 200;
  int gui_x = viewport_w-gui_w;
  int gui_y = 0;
      
  int fluidgrid_scale = 1;


  
  DwPixelFlow context;
  DwFluid2D fluid;
  DwFluidStreamLines2D streamlines;
  MyFluidData cb_fluid_data;

  PGraphics2D pg_fluid;             // render target
  PGraphics2D pg_density;           // texture-buffer, for adding fluid data
  PGraphics2D pg_velocity;          // texture-buffer, for adding fluid data
  PGraphics2D pg_obstacles;         // texture-buffer, for adding fluid data
  PGraphics2D pg_obstacles_drawing; // texture-buffer, for adding fluid data
  
  ObstaclePainter obstacle_painter;
  
  MorphShape morph; // animated morph shape, used as dynamic obstacle
  
  // some state variables for the GUI/display
  int     BACKGROUND_COLOR           = 0;
  boolean UPDATE_FLUID               = true;
  boolean DISPLAY_FLUID_TEXTURES     = true;
  boolean DISPLAY_FLUID_VECTORS      = true; //false; //true; //false;
  int     DISPLAY_fluid_texture_mode = 3; //3; //2; //0;
  boolean DISPLAY_STREAMLINES        = true;  //true; //false; //true;
  int     STREAMLINE_DENSITY         = 15; //10;
  
  
  
  Controls controls;
HorizontalControl controlX;
int showControls;
boolean draggingZoomSlider = false;
boolean released = true;
float zoom = 0.00f;
float tzoom = 0.00f; 
float velocityX = 0;
float velocityY = 0;



int N = 81;  //number of points
float M = -0.00000f; //2/100.0;
float[] dydx = new float[81];
float T = 0/100.0f;
float[] dT;
float x[] = new float[81];  //divide up unit chord length by N
float y[] = new float[81];  //divide up unit chord length by N
float xU[] = new float[81];
float yU[] = new float[81];
float xL[] = new float[81];
float yL[] = new float[81];
float P = 0.4f; //0.4; //40/100.0;
PShape s,s2;
PFont font;
float a0 = 0.2969f;
float a1 = -0.126f;
float a2 = -0.3516f;
float a3 = 0.2843f;
float a4 = -0.1036f;
float[] theta = new float[81];
float[] yt = new float[81];
float[] beta = new float[81];




float angle;
float[] Xvalues = new float[162];
float[] Yvalues = new float[162];
float[] XUoord = new float[81];
float[] YUoord = new float[81];
float[] XLoord = new float[81];
float[] YLoord = new float[81];


  public void settings() {
    size(viewport_w, viewport_h, P2D);

    smooth(4);
  }
  
  public void mouseWheel(MouseEvent event) {
  float e = event.getCount();

  P += 0.01f*e;
}
  
  
  public void setup() {
   
    controls = new Controls();
    controlX = new HorizontalControl();
    showControls = 1; 
    
    
    
    surface.setLocation(viewport_x, viewport_y);
    
    // main library context
    context = new DwPixelFlow(this);
    context.print();
    context.printGL();
    
    streamlines = new DwFluidStreamLines2D(context);
    
    // fluid simulation
    fluid = new DwFluid2D(context, viewport_w, viewport_h, fluidgrid_scale);

    // some fluid params
    fluid.param.dissipation_density     = 0.99999f;
    fluid.param.dissipation_velocity    = 0.99999f;
    fluid.param.dissipation_temperature = 0.70f;
    fluid.param.vorticity               = 0.05f;
    
    // interface for adding data to the fluid simulation
    cb_fluid_data = new MyFluidData();
    fluid.addCallback_FluiData(cb_fluid_data);

    // processing font
    font = createFont("/data/SourceCodePro-Regular.ttf", 48);

    // fluid render target
    pg_fluid = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    pg_fluid.smooth(4);

    // main obstacle texture
    pg_obstacles = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
//    pg_obstacles.noSmooth();
    pg_obstacles.smooth(4);
    pg_obstacles.beginDraw();
    pg_obstacles.clear();
    pg_obstacles.endDraw();
    
    
    // second obstacle texture, used for interactive mouse-driven painting
    pg_obstacles_drawing = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
  //  pg_obstacles_drawing.noSmooth();
    pg_obstacles_drawing.smooth(4);
    pg_obstacles_drawing.beginDraw();
    pg_obstacles_drawing.clear();
    pg_obstacles_drawing.blendMode(REPLACE);
   

    pg_obstacles_drawing.fill(200,0,0);
    



   
    pg_obstacles_drawing.endDraw();
    
    
    // init the obstacle painter, for mouse interaction
    obstacle_painter = new ObstaclePainter(pg_obstacles_drawing);
    
    // image/buffer that will be used as density input
    pg_density = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    pg_density.noSmooth();
    pg_density.beginDraw();
    pg_density.clear();
    pg_density.endDraw();
    
    // image/buffer that will be used as velocity input
    pg_velocity = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    pg_velocity.noSmooth();
    pg_velocity.beginDraw();
    pg_velocity.clear();
    pg_velocity.endDraw();
    
    
    // animated morph shape
    morph = new MorphShape(120);



    frameRate(60);
  }
  

  
  
  public void drawObstacles(){
  
    pg_obstacles.beginDraw();
    pg_obstacles.blendMode(BLEND);
    pg_obstacles.clear();
    
    // add morph-shape as obstacles
    pg_obstacles.pushMatrix();
    {
      pg_obstacles.noFill();
      pg_obstacles.strokeWeight(10);
      pg_obstacles.stroke(64);
      
      pg_obstacles.translate(width/2, height/2);
      morph.drawAnimated(pg_obstacles, 0.975f);
  //    morph.draw(pg_obstacles, mouseY/(float)height);
    }
    pg_obstacles.popMatrix();
    
    // add painted obstacles on top of it
    pg_obstacles.image(pg_obstacles_drawing, 0, 0);
    pg_obstacles.endDraw();
    

  }
  
  
  
  

  
  public void drawVelocity(PGraphics pg, int texture_type){
    
    float vx = 30; // velocity in x direction
    float vy =  0; // velocity in y direction
    
    int argb = Velocity.Polar.encode_vX_vY(vx, vy);
    float[] vam = Velocity.Polar.getArc(vx, vy);
    

    float vM = vam[1]; // velocity magnitude
    
    if(vM == 0){
      // no velocity, so just return
      return;
    }
    
    pg.beginDraw();
    pg.blendMode(REPLACE); // important
    pg.clear();
    pg.noStroke();
    
    if(vM > 0){
      
      int offy = 100;
  
      // add density
      if(texture_type == 1){
        float size_h = height-2*offy;
        pg.noStroke();
    
        
        int num_segs = 30;
        float seg_len = size_h / num_segs;
        for(int i = 0; i < num_segs; i++){
          float py = offy + i * seg_len;
          if(i%2 == 0){
            if(frameCount % 50 == 0){
              pg.fill(255,150,50);
              pg.rect(5, py, seg_len*2, seg_len);
            }
          } else {
            pg.fill(50, 155, 255);

            pg.noStroke();
            pg.rect(5, py, seg_len, seg_len);
          }

        }
      }
      
      // add encoded velocity
      if(texture_type == 0){
        // if the the M bits are zero (no magnitude), then processings fill() method 
        // builds a different color than zero: 0x00000000 becomes 0xFF000000
        // this fouls up the encoding/decoding process in the shader.
        // (argb & 0xFFFF0000) == 0
        // pg.fill(argb); // this fails if argb == 0
        
        // so, a workaround is, to pass 4 components separately
        int a = (argb >> 24) & 0xFF;
        int r = (argb >> 16) & 0xFF;
        int g = (argb >>  8) & 0xFF;
        int b = (argb >>  0) & 0xFF;
        pg.fill  (r,g,b,a);   
        pg.stroke(r,g,b,a);
        
        pg.noStroke();
        pg.rect(0, offy, 10, height-2*offy);
      }
    }
    pg.endDraw();
  }
  
  
  

  public void draw() {
   

    if(UPDATE_FLUID){
      
      drawVelocity(pg_velocity, 0);
      drawVelocity(pg_density , 1);
      
      drawObstacles();
      
      fluid.addObstacles(pg_obstacles);
      fluid.update();
    }

    
    pg_fluid.beginDraw();
    pg_fluid.background(BACKGROUND_COLOR);
    pg_fluid.endDraw();
    
    
    if(DISPLAY_FLUID_TEXTURES){
      fluid.renderFluidTextures(pg_fluid, DISPLAY_fluid_texture_mode);
    }
    
    if(DISPLAY_FLUID_VECTORS){
      fluid.renderFluidVectors(pg_fluid, 10);
    }
    
    if(DISPLAY_STREAMLINES){
      streamlines.render(pg_fluid, fluid, STREAMLINE_DENSITY);
    }
    
    // display
    image(pg_fluid    , 0, 0);
    image(pg_obstacles, 0, 0);

    


    // info
    String txt_fps = String.format(getClass().getName()+ "   [size %d/%d]   [frame %d]   [fps %6.2f]", fluid.fluid_w, fluid.fluid_h, fluid.simulation_step, frameRate);
    surface.setTitle(txt_fps);
    
                     controls.updateZoomSlider(zoom);
  controlX.updateZoomSlider(tzoom); 
    
          
              if (mousePressed) {
     if( (showControls == 1) && (controls.isZoomSliderEvent(mouseX, mouseY)) || ( showControls == 1 && controlX.isZoomSliderEvent(mouseX,mouseY))) {
         draggingZoomSlider = true;     
         zoom = controls.getZoomValue(mouseY);
         tzoom = controlX.getZoomValue(mouseX,mouseY);      
         M = map(M,-0.10f,0.10f,-zoom,zoom); //,-0.10,0.10);
         T = map(T,0,12,-tzoom,tzoom);
     }    
           // MousePress - Rotation Adjustment
      else if (!draggingZoomSlider) {
         if (released == true) {
    
            }      
     }
  } 
    

    if (showControls == 1) {
     controls.render(); 
         controlX.render(); 
    }
    
 thread( "getOrdinates");
    
    
    
  }
  


  
  
  
  
  
  public class MorphShape{
    
    ArrayList<float[]> shape1 = new ArrayList<float[]>();
    ArrayList<float[]> shape2 = new ArrayList<float[]>();

    public MorphShape(float size){
      createShape1(size);
      createShape2(size*0.8f);
      initAnimator(1, 1);
    }
    
    float O = 2f;
    
    // square
    public void createShape1(float size){
      
        Xvalues = concat(xU,xL);
  Yvalues = concat(yU,yL);
  XLoord = subset(Xvalues,N,(N-1));
  YLoord = subset(Yvalues,N,(N-1));
  

      
      
        for (int i = 0; i<(N-1); i++){ 
      
                      shape1.add(new float[]{300*XLoord[i],300*YLoord[i]});
       
           angle = sqrt( ((300 - Xvalues[0]) * (300 - Xvalues[0])) + ((300*Yvalues[N-1]) * (300*Yvalues[N-1])) );
           angle = asin(300*Yvalues[N-1]/angle);
        }
        XLoord = reverse(XLoord);
        YLoord = reverse(YLoord);
        for (int i = 0; i<(N-1); i++){ 
       
                      shape1.add(new float[]{300*XLoord[i],300*YLoord[i]});
       
           angle = sqrt( ((300 - Xvalues[0]) * (300 - Xvalues[0])) + ((300*Yvalues[N-1]) * (300*Yvalues[N-1])) );
           angle = asin(300*Yvalues[N-1]/angle);
        }
      
    }
    
    public void createShape2(float size){
      int NUM_POINTS = shape1.size();
 
      
      float arc_min = PI/4f;
      float arc_max = TWO_PI-arc_min;
      float arc_range = arc_max - arc_min;
      float arc_step = arc_range/(NUM_POINTS-1);
   
      for (int i = 0; i < NUM_POINTS; i++) {
        float arc = arc_min + i * arc_step;
        float vx = size * cos(arc);
        float vy = size * sin(arc);

        shape2.add(new float[]{vx, vy});
      }
      
    }
    
    
    public void initAnimator(float morph_mix, int morph_state){
      if( morph_mix < 0 ) morph_mix = 0;
      if( morph_mix > 1 ) morph_mix = 1;
      morph_state &= 1;
      
      this.morph_mix = morph_mix;
      this.morph_state = morph_state;
    }

    
    float morph_mix = 1f;
    int   morph_state = 1;
    
    public void drawAnimated(PGraphics2D pg, float ease){
      morph_mix *= ease;
      if(morph_mix < 0.0001f){
        morph_mix = 1f;
        morph_state ^= 1;
      } 
      
      this.draw(pg, morph_state == 0 ? morph_mix : 1-morph_mix);
    } 
    
    
    public void draw(PGraphics2D pg, float mix){
      pg.beginShape();

          
          pg.translate(width/2-950, height/2 -350);

 pg.scale(1.5f,-1.5f);
//pg.rotate(radians(-25));
      pg.stroke(0,255,0);
  pg.strokeWeight(2);
    
  Xvalues = concat(xU,xL);
  Yvalues = concat(yU,yL);
  XLoord = subset(Xvalues,N,(N-1));
  YLoord = subset(Yvalues,N,(N-1));


        for (int i = 0; i<(N-1); i++){ 
           pg.vertex(300*XLoord[i],300*YLoord[i]);
       
           angle = sqrt( ((300 - Xvalues[0]) * (300 - Xvalues[0])) + ((300*Yvalues[N-1]) * (300*Yvalues[N-1])) );
           angle = asin(300*Yvalues[N-1]/angle);
        }
        XLoord = reverse(XLoord);
        YLoord = reverse(YLoord);
        for (int i = 0; i<(N-1); i++){ 
           pg.vertex(300*XLoord[i],300*YLoord[i]);
       
           angle = sqrt( ((300 - Xvalues[0]) * (300 - Xvalues[0])) + ((300*Yvalues[N-1]) * (300*Yvalues[N-1])) );
           angle = asin(300*Yvalues[N-1]/angle);
        }
               
   pg.endShape(CLOSE);
   pg.shearY(angle); 

   pg.shearY(-angle);

   XUoord = subset(Xvalues,0,(N-1));
   YUoord = subset(Yvalues,0,(N-1));

   pg.beginShape();





   pg.stroke(0,255,0);
   pg.strokeWeight(2);


        for (int i = 0; i<(N-1); i++){ 
           pg.vertex(300*XUoord[i],300*YUoord[i]);
       
           angle = sqrt( ((300 - Xvalues[0]) * (300 - Xvalues[0])) + ((300*Yvalues[N-1]) * (300*Yvalues[N-1])) );
           angle = asin(300*Yvalues[N-1]/angle);
        } 
        XUoord = reverse(XUoord);
        YUoord = reverse(YUoord);
               for (int i = 0; i<(N-1); i++){ 
           pg.vertex(300*XUoord[i],300*YUoord[i]);
        
           angle = sqrt( ((300 - Xvalues[0]) * (300 - Xvalues[0])) + ((300*Yvalues[N-1]) * (300*Yvalues[N-1])) );
           angle = asin(300*Yvalues[N-1]/angle);
        }
        
    
          
   pg.endShape(CLOSE);

      
      
      
      
      pg.endShape(); 
    }
     
  }
  
  
  
  
  
  
  
  
  public class ObstaclePainter{
    
    // 0 ... not drawing
    // 1 ... adding obstacles
    // 2 ... removing obstacles
    public int draw_mode = 0;
    PGraphics pg;
    
    float size_paint = 15;
    float size_clear = size_paint * 2.5f;
    
    float paint_x, paint_y;
    float clear_x, clear_y;
    
    int shading = 64;
    
    public ObstaclePainter(PGraphics pg){
      this.pg = pg;
    }
    
    public void beginDraw(int mode){
      paint_x = mouseX;
      paint_y = mouseY;
      this.draw_mode = mode;
      if(mode == 1){
        pg.beginDraw();
        pg.blendMode(REPLACE);
        pg.noStroke();
        pg.fill(shading);
        pg.ellipse(mouseX, mouseY, size_paint, size_paint);
        pg.endDraw(); 
      }
      if(mode == 2){
        clear(mouseX, mouseY);
      }
    }
    
    public boolean isDrawing(){
      return draw_mode != 0;
    }
    
    public void draw(){
      paint_x = mouseX;
      paint_y = mouseY;
      if(draw_mode == 1){
        pg.beginDraw();
        pg.blendMode(REPLACE);
        pg.strokeWeight(size_paint);
        pg.stroke(shading);
        pg.line(mouseX, mouseY, pmouseX, pmouseY);
        pg.endDraw(); 
      }
      if(draw_mode == 2){
        clear(mouseX, mouseY);
      }
    }

    public void endDraw(){
      this.draw_mode = 0;
    }
    
    public void clear(float x, float y){
      clear_x = x;
      clear_y = y;
      pg.beginDraw();
      pg.blendMode(REPLACE);
      pg.noStroke();
      pg.fill(0, 0);
      pg.ellipse(x, y, size_clear, size_clear);
      pg.endDraw();
    }

    

  }
  
  
  
  
  public void mousePressed(){
    if(mouseButton == CENTER ) obstacle_painter.beginDraw(1); // add obstacles
    if(mouseButton == RIGHT  ) obstacle_painter.beginDraw(2); // remove obstacles
  }
  
  public void mouseDragged(){
 //   obstacle_painter.draw();
  }
  
  public void mouseReleased(){
    obstacle_painter.endDraw();
  }
  
  
  public void fluid_resizeUp(){
    fluid.resize(width, height, fluidgrid_scale = max(1, --fluidgrid_scale));
  }
  public void fluid_resizeDown(){
    fluid.resize(width, height, ++fluidgrid_scale);
  }
  public void fluid_reset(){
    fluid.reset();
  }
  public void fluid_togglePause(){
    UPDATE_FLUID = !UPDATE_FLUID;
  }
  public void fluid_displayMode(int val){
    DISPLAY_fluid_texture_mode = val;
    DISPLAY_FLUID_TEXTURES = DISPLAY_fluid_texture_mode != -1;
  }
  public void fluid_displayVelocityVectors(int val){
    DISPLAY_FLUID_VECTORS = val != -1;
  }

  public void streamlines_displayStreamlines(int val){
    DISPLAY_STREAMLINES = val != -1;
  }

  public void keyReleased(){
    if(key == 'p') fluid_togglePause(); // pause / unpause simulation
    if(key == '+') fluid_resizeUp();    // increase fluid-grid resolution
    if(key == '-') fluid_resizeDown();  // decrease fluid-grid resolution
    if(key == 'r') fluid_reset();       // restart simulation
    
    if(key == '1') DISPLAY_fluid_texture_mode = 0; // density
    if(key == '2') DISPLAY_fluid_texture_mode = 1; // temperature
    if(key == '3') DISPLAY_fluid_texture_mode = 2; // pressure
    if(key == '4') DISPLAY_fluid_texture_mode = 3; // velocity
    
    if(key == 'q') DISPLAY_FLUID_TEXTURES = !DISPLAY_FLUID_TEXTURES;
    if(key == 'w') DISPLAY_FLUID_VECTORS  = !DISPLAY_FLUID_VECTORS;
  }
  
  
  
    
public void getOrdinates(){
   
  for (int i = 0; i < N; i++){
  
    M = zoom/2500f;
    T = tzoom/2500f;

    if(x[i] >= 0){
       beta[i] = (radians(180)/81.0f) * i;
       x[i] = (1 - cos(beta[i]))/2;
     }
    if(x[i] < P){
     if (x[i] >= 0){
     y[i] = ((M/(P*P) * (2*P*x[i] - x[i]*x[i])));  // /1.005;
     dydx[i] = (2*M)/(P*P) * (P - x[i]);
     }    
   }  
    if(x[i] >=P){  
    if (x[i] <= 1.00000f){     
    y[i] = (M/((1-P)*(1-P)) * (1 - 2*P + 2*P*x[i] - x[i]*x[i])); //*2.725; //* 2.75; //*2.686; 
    dydx[i] = (2*M/((1-P)*(1-P)) * (P - x[i])); 
     } 
   }    
}  //end for loop

   for (int i = 0; i < 81; i++){
   
       yt[i] = (T/0.2f* (a0*sqrt(x[i])+ a1*x[i] + a2*(x[i]*x[i]) + a3*(x[i]*x[i]*x[i]) + a4*(x[i]*x[i]*x[i]*x[i])));
       theta[i] = (atan((dydx[i])));
       xU[i] = x[i] - yt[i] * (sin(radians(theta[i]))); 
       yU[i] = ( (y[i] + yt[i]  * (cos(radians(theta[i]))) ) );
       xL[i] = x[i] + yt[i] * sin(radians(theta[i]));        
       yL[i] = (y[i] - yt[i] * cos(radians(theta[i]))); 
 //    println(xU[i],yU[i], xL[i],yL[i]);    
    }
    


}
  
  
  
  
 
  


  
/*

 Kepler Visualization - Controls
 
 GUI controls added by Lon Riesberg, Laboratory for Atmospheric and Space Physics
 lon@ieee.org
 
 April, 2012
 
 Current release consists of a vertical slider for zoom control.  The slider can be toggled
 on/off by pressing the 'c' key.
 
 Slide out controls that map to the other key bindings is currently being implemented and
 will be released soon.
 
*/

class Controls {
   
   int barWidth;   
   int barX;                          // x-coordinate of zoom control
   int minY, maxY;                    // y-coordinate range of zoom control
   float minZoomValue, maxZoomValue;  // values that map onto zoom control
   float valuePerY;                   // zoom value of each y-pixel 
   int sliderY;                       // y-coordinate of current slider position
   float sliderValue;                 // value that corresponds to y-coordinate of slider
   int sliderWidth, sliderHeight;
   int sliderX;                       // x-coordinate of left-side slider edge                     
   
   Controls () {
      
      barX = 40;
      barWidth = 15;
 
      minY = 40;
      maxY = minY + height/3 - sliderHeight/2;
           
      minZoomValue = height - height;
      maxZoomValue = height;   // 300 percent
      valuePerY = (maxZoomValue - minZoomValue) / (maxY - minY);
      
      sliderWidth = 25;
      sliderHeight = 10;
      sliderX = (barX + (barWidth/2)) - (sliderWidth/2);      
      sliderValue = minZoomValue; 
      sliderY = minY;     
   }
   
   
   public void render() {

   
        strokeWeight(1); 
 
       stroke(0xffff0000);
      
      // zoom control bar
      fill(0, 0, 0, 0);
        
      rect(barX, minY, barWidth, maxY-minY);
      
      // slider

       fill(0xffff0000); // 0xff33ff99//0x3300FF00
      rect(sliderX, sliderY, sliderWidth, sliderHeight);
   }
   
   
   public float getZoomValue(int y) {
      if ((y >= minY) && (y <= (maxY - sliderHeight/2))) {
         sliderY = (int) (y - (sliderHeight/2));     
         if (sliderY < minY) { 
            sliderY = minY; 
         } 
         sliderValue = (y - minY) * valuePerY + minZoomValue;
      }     
      return sliderValue;
   }
   
   
   public void updateZoomSlider(float value) {
      int tempY = (int) (value / valuePerY) + minY;
     
      if ((tempY >= minY) && (tempY <= (maxY-sliderHeight))) {
         sliderValue = value;
         sliderY = tempY;
      }
     
   }
   
   
   public boolean isZoomSliderEvent(int x, int y) {
      int slop = 50;  // number of pixels above or below slider that's acceptable.  provided for ease of use.
      int sliderTop = (int) (sliderY - (sliderHeight/2)) - slop;
      int sliderBottom = sliderY + sliderHeight + slop;
      return ((x >= sliderX) && (x <= (sliderX    + sliderWidth)) && (y >= sliderTop)  && (y <= sliderBottom) || draggingZoomSlider );
   } 
}
 
/*
I modified this so the slider is horizontal.  That gives me a vertical for
tweaking altitude and horizontal for right ascension/longitude
*/

/*

 Kepler Visualization - Controls
 
 GUI controls added by Lon Riesberg, Laboratory for Atmospheric and Space Physics
 lon@ieee.org
 
 April, 2012
 
 Current release consists of a vertical slider for zoom control.  The slider can be toggled
 on/off by pressing the 'c' key.
 
 Slide out controls that map to the other key bindings is currently being implemented and
 will be released soon.
 
*/

class HorizontalControl {
   
   int barHeight;   
   int barY;                          // y-coordinate of zoom control
   int minX, maxX;                    // x-coordinate range of zoom control
   float minZoomValue, maxZoomValue;  // values that map onto zoom control
   float valuePerX;                   // zoom value of each y-pixel 
   int sliderY;                       // y-coordinate of current slider position
   float sliderValue;                 // value that corresponds to y-coordinate of slider
   int sliderWidth, sliderHeight;
   int sliderX;                       // x-coordinate of left-side slider edge                     
   
   HorizontalControl () {
      
      barY = 15; //40;
      barHeight = 40; //15;
 
      minX = 40;
      maxX = minX + width/3 - sliderWidth/2;
           
      minZoomValue = width - width;
      maxZoomValue = width;   // 300 percent
      valuePerX = (maxZoomValue - minZoomValue) / (maxX - minX);
      
      sliderWidth = 10; //25;
      sliderHeight = 25; //10;
     // sliderY = (barY + (barHeight/2)) - (sliderHeight/2);
      sliderY = (barY - (sliderHeight/2)) + (barHeight/2);
      sliderValue = minZoomValue; 
      sliderX = minX;     
   }
   
   
   public void render() {
       pushMatrix();


     // strokeWeight(1.5); 
        strokeWeight(1); 
    //  stroke(105, 105, 105);  // fill(0xff33ff99);
   //   stroke(0xff33ff99);  // fill(0xff33ff99);  0xffff0000
       stroke(0xffff0000);
      
      // zoom control bar
      fill(0, 0, 0, 0);
        
      rect(minX,barHeight + height - height/4,maxX-minX, barY );
     // rect(maxX-minX, barHeight/2,minX,barY + height - height/4 );
      
      // slider
     // fill(105, 105, 105); //0x3300FF00
       fill(0xffff0000); // 0xff33ff99//0x3300FF00

      rect(sliderX, sliderY + height - height/4 + sliderHeight/2 , sliderWidth, sliderHeight);

      popMatrix();
      
   }
   
   
   public float getZoomValue(int x, int y) {
      if ((x >= minX) && (x <= (maxX - sliderWidth/2)) && (y > (height - height/3))) {
         sliderX = (int) (x - (sliderWidth/2));     
         if (sliderX < minX) { 
            sliderX = minX; 
         } 
         sliderValue = (x - minX) * valuePerX + minZoomValue;
      }     
      return sliderValue;
   }
   
   
   public void updateZoomSlider(float value) {
      int tempX = (int) (value / valuePerX) + minX;
      
      if ( (tempX >= minX) && (tempX <= (maxX+sliderWidth))  ) {
         sliderValue = value;
         sliderX = tempX;
      }
   }
   
   
/*   boolean isZoomSliderEvent(int x, int y) {
      int slop = 50;  // number of pixels above or below slider that's acceptable.  provided for ease of use.
      int sliderTop = (int) (sliderY - (sliderHeight/2)) - slop;
      int sliderBottom = sliderY + sliderHeight + slop;
      return ((x >= sliderX) && (x <= (sliderX    + sliderWidth)) && (y >= sliderTop)  && (y <= sliderBottom) || draggingZoomSlider );
   } */
   
      public boolean isZoomSliderEvent(int x, int y) {
      int slop = 50;  // number of pixels above or below slider that's acceptable.  provided for ease of use.
      int sliderLeft = (int) (sliderX - (sliderWidth/2)) - slop;
      int sliderRight = sliderX + sliderWidth + slop;
    //  return ((y >= sliderY + height - height/4) && (y <= (sliderY + height - height/4    + sliderHeight)) && (x >= sliderLeft)  && (x <= sliderRight) || draggingZoomSlider );
           return ((y >= sliderY + height - height/4 - sliderHeight/2) && (y <= (sliderY + height - height/4 + sliderHeight*2 )) && (x >= sliderLeft )  && (x <= sliderRight ) || draggingZoomSlider );
   } 
}
/**
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */


static public class Velocity{
  
  static final public float TWO_PI = (float) (Math.PI * 2.0f);
  
  // namespace Polar
  static public class Polar{
    
    /**
     * converts an unnormalized vector to polar-coordinates.
     * 
     * @param  vx velocity x, unnormalized
     * @param  vy velocity y, unnormalized
     * @return {arc, mag}
     */
    static public float[] getArc(float vx, float vy){
      // normalize
      float mag_sq = vx*vx + vy*vy;
      if(mag_sq < 0.00001f){
        return new float[]{0,0};
      }
      float mag = (float) Math.sqrt(mag_sq);
      vx /= mag;
      vy /= mag;
      
      float arc = (float) Math.atan2(vy, vx);
      if(arc < 0) arc += TWO_PI;
      return new float[]{arc, mag};
    }
    
    /**
     * encodes an unnormalized 2D-vector as an unsigned 32 bit integer.<br>
     *<br>
     * 0xMMMMAAAA (16 bit arc, 16 bit magnitude<br>
     * 
     * @param x    velocity x, unnormalized
     * @param y    velocity y, unnormalized
      * @return encoded polar coordinates
     */
    static public int encode_vX_vY(float vx, float vy){
      float[] arc_mag = getArc(vx, vy);
      int argb = encode_vA_vM(arc_mag[0], arc_mag[1]);
      return argb;
    }
    
    /**
     * encodes a vector, given in polar-coordinates, into an unsigned 32 bit integer.<br>
     *<br>
     * 0xMMMMAAAA (16 bit arc, 16 bit magnitude<br>
     * 
     * @param vArc
     * @param vMag
     * @return encoded polar coordinates
     */
    static public int encode_vA_vM(float vArc, float vMag){
      float  vArc_nor = vArc / TWO_PI;                           // [0, 1]
      int    vArc_I16 = (int)(vArc_nor * (0xFFFF - 1)) & 0xFFFF; // [0, 0xFFFF[
      int    vMag_I16 = (int)(vMag                   ) & 0xFFFF; // [0, 0xFFFF[
      return vMag_I16 << 16 | vArc_I16;                          // ARGB ... 0xAARRGGBB
    }

    /**
     * decodes a vector, given as 32bit encoded integer (0xMMMMAAAA) to a 
     * normalized 2d vector and its magnitude.
     * 
     * @param rgba 32bit encoded integer (0xMMMMAAAA)
     * @return {vx, vy, vMag}
     */
    static public float[] decode_ARGB(int rgba){
      int   vArc_I16 = (rgba >>  0) & 0xFFFF;            // [0, 0xFFFF[
      int   vMag_I16 = (rgba >> 16) & 0xFFFF;            // [0, 0xFFFF[
      float vArc     = TWO_PI * vArc_I16 / (0xFFFF - 1); // [0, TWO_PI]
      float vMag     = vMag_I16;
      float vx       = (float) Math.cos(vArc);
      float vy       = (float) Math.sin(vArc);
      return new float[]{vx, vy, vMag}; 
    }
  }
  
}