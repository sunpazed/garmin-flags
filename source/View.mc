using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Timer as Timer;

enum {
  SCREEN_SHAPE_CIRC = 0x000001,
  SCREEN_SHAPE_SEMICIRC = 0x000002,
  SCREEN_SHAPE_RECT = 0x000003
}


class View extends Ui.WatchFace {

    // globals
    var debug = false;
    var timer1;
    var timer_timeout = 100;
    var timer_steps = timer_timeout;
    var current_frame = 0;

    // sensors / status
    var battery = 0;
    var bluetooth = true;

    // time
    var hour = null;
    var minute = null;
    var day = null;
    var day_of_week = null;
    var month_str = null;
    var month = null;
    var utc = null;

    // layout
    var vert_layout = false;
    var canvas_h = 0;
    var canvas_w = 0;
    var canvas_shape = 0;
    var canvas_rect = false;
    var canvas_circ = false;
    var canvas_semicirc = false;
    var canvas_tall = false;
    var canvas_r240 = false;
    var set_theme = 0;
    var set_leading_zero = true;

    // flag vars
    var b_flag = null;
    var segment_width = 19;
    var segment_height = 100;
    var flag=[10,9,8,7,5,2,0,-3,-5,-8,-9,-10,-10,-10,-9,-8,-6,-3,-1,2,5,7,8,9,10];

    // data
    var field;
    var fieldGoal;
    var fieldProgress;
    var buffers = [];

    // fonts
    var f_time_bold = false;
    var f_time_light = false;

    function initialize() {
     Ui.WatchFace.initialize();
    }


    function onLayout(dc) {

      // w,h of canvas
      canvas_w = dc.getWidth();
      canvas_h = dc.getHeight();

      // check the orientation
      if ( canvas_h > (canvas_w*1.2) ) {
        vert_layout = true;
      } else {
        vert_layout = false;
      }

      // let's grab the canvas shape
      var deviceSettings = Sys.getDeviceSettings();
      canvas_shape = deviceSettings.screenShape;

      if (debug) {
        Sys.println(Lang.format("canvas_shape: $1$", [canvas_shape]));
      }

      // find out the type of screen on the device
      canvas_tall = (vert_layout && canvas_shape == SCREEN_SHAPE_RECT) ? true : false;
      canvas_rect = (canvas_shape == SCREEN_SHAPE_RECT && !vert_layout) ? true : false;
      canvas_circ = (canvas_shape == SCREEN_SHAPE_CIRC) ? true : false;
      canvas_semicirc = (canvas_shape == SCREEN_SHAPE_SEMICIRC) ? true : false;
      canvas_r240 =  (canvas_w == 240 && canvas_w == 240) ? true : false;

      // set offsets based on screen type
      // positioning for different screen layouts
      if (canvas_tall) {
      }
      if (canvas_rect) {
      }
      if (canvas_circ) {
        if (canvas_r240) {
        } else {
        }
      }
      if (canvas_semicirc) {
      }

      // load the font
      f_time_light = Ui.loadResource(Rez.Fonts.time_light);
      f_time_bold = Ui.loadResource(Rez.Fonts.time_bold);

      // load the flag
      set_theme = readKeyInt(App.getApp(),"theme",5);

      switch (set_theme) {

        case 0:
        b_flag = Ui.loadResource(Rez.Drawables.australia);
        break;

        case 1:
        b_flag = Ui.loadResource(Rez.Drawables.czech);
        break;

        case 2:
        b_flag = Ui.loadResource(Rez.Drawables.japan);
        break;

        case 3:
        b_flag = Ui.loadResource(Rez.Drawables.southafrica);
        break;

        case 4:
        b_flag = Ui.loadResource(Rez.Drawables.uk);
        break;

        case 5:
        b_flag = Ui.loadResource(Rez.Drawables.usa);
        break;

        default:
        b_flag = Ui.loadResource(Rez.Drawables.usa);
        break;

      }


      // do we have buffered bitmaps?
      if (Toybox.Graphics has :BufferedBitmap) {

          // then create 10 of them ...
          for (var i=0; i<=10;i++) {
            var offscreenBuffer;
            offscreenBuffer = new Gfx.BufferedBitmap({
                :width=>segment_width,
                :height=>segment_height
            });
            buffers.add(offscreenBuffer);
          }

          // ... and render the flag to the buffered bitmaps
          for (var i=0; i<buffers.size();i++) {
            var this_dc = buffers[i].getDc();
            this_dc.drawBitmap((-segment_width*i),0,b_flag);
          }

      }


    }


    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }


    //! Update the view
    function onUpdate(dc) {


      // grab time objects
      var clockTime = Sys.getClockTime();
      var date = Time.Gregorian.info(Time.now(),0);
      var utcTime = Time.Gregorian.utcInfo(Time.now(), Time.FORMAT_MEDIUM);

      // define time, day, month variables
      hour = clockTime.hour;
      minute = clockTime.min;
      day = date.day;
      month = date.month;
      day_of_week = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
      month_str = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).month;

      // 12-hour support
      if (hour >= 12) {
            hour = hour - 12;
      }

      if( minute < 10 ) {
          minute = "0" + minute;
      }

      if( hour < 10 && set_leading_zero) {
          hour = "0" + hour;
      }

      if( day < 10 ) {
          day = "0" + day;
      }

      if( month < 10 ) {
          month = "0" + month;
      }

      // grab battery
      var stats = Sys.getSystemStats();
      var batteryRaw = stats.battery;
      battery = batteryRaw > batteryRaw.toNumber() ? (batteryRaw + 1).toNumber() : batteryRaw.toNumber();

      // do we have bluetooth?
      var deviceSettings = Sys.getDeviceSettings();
      bluetooth = deviceSettings.phoneConnected;

      // activity monitor for field
      var thisActivity = ActivityMonitor.getInfo();

      // grab field from settings
      var set_field = 1;//readKeyInt(App.getApp(),"field",0);

      if (set_field == 0) {
          field = battery.toFloat();
          fieldGoal = 100.0;
      }

      if (set_field == 1) {
          field = thisActivity.steps;
          fieldGoal = thisActivity.stepGoal;
      }

      if (set_field == 2) {
          field = thisActivity.floorsClimbed;
          fieldGoal = thisActivity.floorsClimbedGoal;
      }

      if (set_field == 3) {
          field = thisActivity.activeMinutesWeek.total;
          fieldGoal = thisActivity.activeMinutesWeekGoal;
      }

      // turn debug values on
      if (debug) {
        fieldGoal = 14000;
        field = Math.rand() % fieldGoal;
      }

      // define our current field progress %
      fieldProgress = 10.0*(field.toFloat()/fieldGoal.toFloat());
      fieldProgress = (fieldProgress > 10) ? 10 : fieldProgress;


      // w,h of canvas
      var dw = canvas_w;
      var dh = canvas_h;

      // clear the screen
      dc.setColor(0x000000, 0x000000);
      dc.clear();

      // flag offset is from the center
      var offset_x = (dw-(segment_width*10))/2;
      var offset_y = -12+(dh-segment_height)/2;

      // pre-calculated sine wave
      var flag_size = flag.size();
      var flag_offset = 7;

      // let's draw each buffered bitmap at each position
      for (var i=0; i<10;i++) {
        dc.drawBitmap(offset_x+(segment_width*i), offset_y+(flag[(flag_offset+i+current_frame)%flag_size]), buffers[i]);
      }

      // draw the field, steps
      dc.setColor(0xffffff, Gfx.COLOR_TRANSPARENT);
      dc.drawText(dw/2,18,Gfx.FONT_XTINY,field.toString()+" / "+fieldGoal.toString(),Gfx.TEXT_JUSTIFY_CENTER);

      var f_minute = dc.getTextWidthInPixels(minute.toString(), f_time_light);
      var f_hour = dc.getTextWidthInPixels(hour.toString(), f_time_bold);
      var f_start = (dw - (f_hour+f_minute))/2;

      // draw time
      dc.setColor(0xffffff, Gfx.COLOR_TRANSPARENT);
      dc.drawText(f_start, 150+6, f_time_bold, hour.toString(), Gfx.TEXT_JUSTIFY_LEFT);
      dc.setColor(0xffffff, Gfx.COLOR_TRANSPARENT);
      dc.drawText(f_start+f_hour, 150+11, f_time_light, minute.toString(), Gfx.TEXT_JUSTIFY_LEFT);

      current_frame++;

    }




    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }


    // this is our animation loop callback
    function callback1() {

      // redraw the screen
      Ui.requestUpdate();

      // timer not greater than 500ms? then let's start the timer again
      if (timer_steps < 1100) {
        timer1 = new Timer.Timer();
        timer1.start(method(:callback1), timer_steps, false );
      } else {
        // timer exists? stop it
        if (timer1) {
          timer1.stop();
        }
      }


    }


    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {

      // let's start our animation loop
      timer1 = new Timer.Timer();
      timer1.start(method(:callback1), timer_steps, false );
    }


    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {

      // bye bye timer
      if (timer1) {
        timer1.stop();
      }

      timer_steps = timer_timeout;


    }

    // helper function for settings
    function readKeyInt(myApp,key,thisDefault) {
      var value = myApp.getProperty(key);
              if(value == null || !(value instanceof Number)) {
              if(value != null) {
                  value = value.toNumber();
              } else {
                      value = thisDefault;
              }
      }
      return value;
    }


}
