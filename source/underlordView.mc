using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.ActivityMonitor as ActMon;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang;

var doPartialUpdate = false;

class underlordView extends WatchUi.WatchFace {

	hidden const overstepGap = 2, overstepWidth = 3, stepArcWidth = 4;
	hidden var halfScreenWidth, halfScreenHeight;
	hidden var numberFont, numberFontHeight, textFont, textFontHeight, halfTextFontHeight;
	hidden var bg_image;
	hidden var hasPartialUpdate = false;
	hidden var inLowPower = true;
	
	// settings
	hidden var foregroundColour, backgroundColour, is24Hour;
	hidden var ttgStyle;
	hidden var CoreSelection;
	hidden var ShowBattery;
	hidden var ShowCountdown, CountdownStyle;
	hidden var BackgroundSelection;
	
	// UTC time of Fri 8th Feb @ 8:30 am in Florida, USA (seems to be about the time @willwightauthor posts to facebook)
	hidden var release_date_settings = {
	    :year   => 2019,
	    :month  => 2,
	    :day    => 8,
	    :hour   => 13, // UTC offset, in this case for CST
	    :minute   => 30,
	    :second   => 0
	};
	hidden var release_date;
	
    function initialize() {
        WatchFace.initialize();
        updateSettings();
        
        hasPartialUpdate = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
        doPartialUpdate = hasPartialUpdate; 
        bg_image = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.bg_id,
            :locX=>0,
            :locY=>0
        });
        
        release_date = Time.Gregorian.moment(release_date_settings);
        
        textFont = Gfx.FONT_XTINY;
        numberFont = Gfx.FONT_NUMBER_MILD;
    }

    // Load your resources here
    function onLayout(dc) {
    	getScreenDimensions(dc);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    	if(hasPartialUpdate) {dc.clearClip();}
    
    	drawWatchface(dc);
    }
    
    function updateSettings() {
		ShowBattery = Application.getApp().getProperty("ShowBattery");
		CountdownStyle = Application.getApp().getProperty("CountdownStyle");
		ShowCountdown = (CountdownStyle > 0);
		BackgroundSelection = Application.getApp().getProperty("BackgroundSelection");
		
		CoreSelection = Application.getApp().getProperty("CoreSelection");
		
		if (CoreSelection == 0) // Pure Core
		{
			foregroundColour = Gfx.COLOR_WHITE;
			backgroundColour = Gfx.COLOR_BLUE;
		}
		else // Blackflame Core
		{
			foregroundColour = Gfx.COLOR_RED;
			backgroundColour = Gfx.COLOR_BLACK;
		}

		// watch settings
		var deviceSettings = System.getDeviceSettings();
		is24Hour = deviceSettings.is24Hour;
	}
	
	function onSettingsChanged() { // triggered by settings change
		updateSettings();        
    	WatchUi.requestUpdate();   // update the view to reflect changes
	}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	inLowPower=false;
    	if(doPartialUpdate == false) {WatchUi.requestUpdate();} 
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	inLowPower=true;
    	if(doPartialUpdate == false) {WatchUi.requestUpdate();}
    }
    
    function onPartialUpdate(dc) {
    	var seconds = release_date.compare(Time.now());
        if (seconds > 0)
        {
        	var days = (seconds / Time.Gregorian.SECONDS_PER_DAY).toNumber(); seconds -= (days * Time.Gregorian.SECONDS_PER_DAY);
        	var hours = (seconds / Time.Gregorian.SECONDS_PER_HOUR).toNumber(); seconds -= (hours * Time.Gregorian.SECONDS_PER_HOUR);
        	var minutes = (seconds / Time.Gregorian.SECONDS_PER_MINUTE).toNumber(); seconds -= (minutes * Time.Gregorian.SECONDS_PER_MINUTE);
		
			drawTimeToGo(dc, foregroundColour, days, hours, minutes, seconds, true);
		}
    }
    
    function drawWatchface(dc) {
    	// draw the background
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		dc.clear();
		
		if (BackgroundSelection > 0)
		{
			bg_image.draw(dc);
		}
		
		// Get and show the current time
		drawTime(dc, Gfx.COLOR_WHITE);
        
        // get the current step count
      	var ActInfo = ActMon.getInfo();
		var stepCount = ActInfo.steps;
		var stepGoal = ActInfo.stepGoal;
		var stepPercent = (stepCount == 0.0)?0.0:(stepCount.toFloat() / stepGoal);
		//stepPercent = 2.65; // DEBUG
		
		if (CoreSelection == 0) // Pure Core
		{
			drawStepCount(dc, stepPercent, stepArcWidth, foregroundColour, backgroundColour);
		}
		else
		{
			drawStepCount(dc, stepPercent, stepArcWidth, backgroundColour, foregroundColour);
		}
		
		// draw the battery percent
		if (ShowBattery)
		{
			drawBatteryLevel(dc, Gfx.COLOR_WHITE);
		}
		
		// get the time remaining (do this LAST as we set the clip in drawTimeToGo)
		if (ShowCountdown)
		{
	        var seconds = release_date.compare(Time.now());
	        if (seconds > 0)
	        {
	        	var days = (seconds / Time.Gregorian.SECONDS_PER_DAY).toNumber(); seconds -= (days * Time.Gregorian.SECONDS_PER_DAY);
	        	var hours = (seconds / Time.Gregorian.SECONDS_PER_HOUR).toNumber(); seconds -= (hours * Time.Gregorian.SECONDS_PER_HOUR);
	        	var minutes = (seconds / Time.Gregorian.SECONDS_PER_MINUTE).toNumber(); seconds -= (minutes * Time.Gregorian.SECONDS_PER_MINUTE);
			
				drawTimeToGo(dc, foregroundColour, days, hours, minutes, seconds, false);
			}
			else
			{
				dc.setColor(foregroundColour, Gfx.COLOR_TRANSPARENT);
	        	dc.drawText(halfScreenWidth, halfScreenHeight - halfTextFontHeight, textFont, "UNDERLORD", Gfx.TEXT_JUSTIFY_CENTER);
			}
		}
	}

	function getScreenDimensions(dc)
	{
   		halfScreenWidth = (dc.getWidth() / 2).toNumber();
   		halfScreenHeight = (dc.getHeight() / 2).toNumber();
   		
   		textFontHeight = dc.getFontHeight(textFont);
   		halfTextFontHeight = (textFontHeight / 2).toNumber();
        numberFontHeight = dc.getFontHeight(numberFont);
	}
	
	function drawArc(dc, degreeStart, degreeEnd, stepArcWidth, arcColour)
	{
		dc.setColor(arcColour, Gfx.COLOR_TRANSPARENT);
		if (degreeEnd > 90)
        {
        	if ((degreeStart > 90) == false)
        	{
         		dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth + 1, Gfx.ARC_CLOCKWISE, 90 - degreeStart, 0);
         		dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth + 1, Gfx.ARC_CLOCKWISE, 0, 360 - (degreeEnd - 90));
         	}
         	else
         	{
         		dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth + 1, Gfx.ARC_CLOCKWISE, 360 - (degreeStart - 90), 360 - (degreeEnd - 90));
         	}
		}
        else
        {
        	dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth + 1, Gfx.ARC_CLOCKWISE, 90 - degreeStart, 90 - degreeEnd);         	
        }
	}
    
    function drawStepCount(dc, stepPercent, arcWidth, foregroundColour, backgroundColour)
    {
    	if (stepPercent > 0.0)
		 {
	         dc.setColor(backgroundColour, Gfx.COLOR_TRANSPARENT);
	         dc.setPenWidth(arcWidth);
	         var degreeStart = 0;
	         
	         var degreeEnd = degreeStart;
	         if (stepPercent > 1.0)
	         {
	         	degreeEnd += (360 - degreeStart);
	         }
	         else
	         {
	         	degreeEnd += (360 - degreeStart)*stepPercent;
	         }
         	
         	 drawArc(dc, degreeStart, degreeEnd, arcWidth, backgroundColour);
         	 	         
	         if (stepPercent > 1.0)
	         {
	         	drawOverStepPos(dc, stepPercent, arcWidth, foregroundColour);
	         }
        }
    }
    
    function drawOverStepPos(dc, stepPercent, arcWidth, overstepColour)
    {
	     dc.setColor(overstepColour, Gfx.COLOR_TRANSPARENT);
         dc.setPenWidth(arcWidth);
         
         var overStepCount = stepPercent.toNumber();
         var arcPercent = stepPercent - overStepCount.toFloat();
         
         var arcSwathDeg = overstepWidth;
         var arcGapDeg = overstepGap;
     	 
     	 for (var index = 0; index < overStepCount; index++)
     	 {
     	 	var degreeEnd = 360 * arcPercent - (arcGapDeg + arcSwathDeg)*index;
     	 	var degreeStart = degreeEnd - arcSwathDeg;
     	 
     	 	drawArc(dc, degreeStart, degreeEnd, arcWidth, overstepColour);	
     	 }
     	 
    }
    
    function drawTimeToGo(dc, colour, days, hours, minutes, seconds, doPartial)
    {
    	var verticalCentre = halfScreenHeight - halfTextFontHeight;
    	    	
    	dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
        var SecOffset = halfScreenWidth-0.5*textFontHeight;
        
        if (CountdownStyle == 1) // day | hour | minute | second all stacked vertically
    	{
	    	if (!doPartial)
	    	{
	    		dc.drawText(halfScreenWidth, verticalCentre - 1.5*textFontHeight, textFont, days.toString() + " DAYS", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(halfScreenWidth, verticalCentre - halfTextFontHeight, textFont, hours.toString() + " HOURS", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(halfScreenWidth, verticalCentre + halfTextFontHeight, textFont, minutes.toString() + " MINS", Gfx.TEXT_JUSTIFY_CENTER);
	
	        	dc.setClip(SecOffset-textFontHeight, verticalCentre + 1.5*textFontHeight, 3*textFontHeight, textFontHeight);
	        	dc.setColor(backgroundColour, backgroundColour);
				dc.clear();
				dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
				dc.clearClip();
				dc.drawText(SecOffset-3, verticalCentre + 1.5*textFontHeight, textFont, seconds.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText(SecOffset+3, verticalCentre + 1.5*textFontHeight, textFont, "SECS", Gfx.TEXT_JUSTIFY_LEFT);
	    	}
	    	else
	    	{
		    	dc.setClip(SecOffset-textFontHeight, verticalCentre + 1.5*textFontHeight, textFontHeight, textFontHeight);
		    	dc.setColor(backgroundColour, backgroundColour);
				dc.clear();
				dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
				dc.drawText(SecOffset-3, verticalCentre + 1.5*textFontHeight, textFont, seconds.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				dc.clearClip();
	    	}
    	}
        else if (CountdownStyle == 2) // day | hour:minute:second stacked vertically
        {
        	var ttgTimeString = Lang.format("$1$:$2$:$3$", [hours.format("%02d"), minutes.format("%02d"), seconds.format("%02d")]);
        	SecOffset = halfScreenWidth-1.5*textFontHeight;
        	
	    	if (!doPartial)
	    	{
	    		var dayString = days.toString() + " DAY";
	    		dayString += (days>1)?"S":"";
	    		
	        	dc.drawText(halfScreenWidth, verticalCentre - halfTextFontHeight, textFont, dayString, Gfx.TEXT_JUSTIFY_CENTER);
	
	        	dc.setClip(SecOffset, verticalCentre + halfTextFontHeight+4, 3*textFontHeight, textFontHeight-6);
	        	dc.setColor(backgroundColour, backgroundColour);
				dc.clear();
				dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
				dc.clearClip();
				dc.drawText(halfScreenWidth, verticalCentre + halfTextFontHeight, textFont, ttgTimeString, Gfx.TEXT_JUSTIFY_CENTER);
	    	}
	    	else
	    	{
				dc.setClip(SecOffset + 2*textFontHeight, verticalCentre + halfTextFontHeight+4, textFontHeight, textFontHeight-6);
	        	dc.setColor(backgroundColour, backgroundColour);
				dc.clear();
				dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
				dc.drawText(halfScreenWidth, verticalCentre + halfTextFontHeight, textFont, ttgTimeString, Gfx.TEXT_JUSTIFY_CENTER);
				dc.clearClip();
			}
		}
    }
    
    function drawTime(dc, colour)
    {
        var clockTime = System.getClockTime();
        var timeString = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
        dc.drawText(halfScreenWidth, 0.4*halfTextFontHeight, textFont, timeString, Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function drawBatteryLevel(dc, colour)
    {
    	var batteryLevel = Sys.getSystemStats().battery;
    	var batteryLevelString = batteryLevel.format("%d") + "%";
		dc.setColor(colour, Gfx.COLOR_TRANSPARENT);
    	dc.drawText(halfScreenWidth, halfScreenHeight*2 - 1.2*textFontHeight, textFont, batteryLevelString, Gfx.TEXT_JUSTIFY_CENTER);
	}
}

class underlordDelegate extends Toybox.WatchUi.WatchFaceDelegate
{
	function initialize() {
		WatchFaceDelegate.initialize();	
	}

    function onPowerBudgetExceeded(powerInfo) {
        Sys.println( "Average execution time: " + powerInfo.executionTimeAverage );
        Sys.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        doPartialUpdate=false;
    }
}