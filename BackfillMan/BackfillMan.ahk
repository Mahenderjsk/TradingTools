/*
  Copyright (C) 2015  SpiffSpaceman

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>
*/

#CommentFlag // 
#Include %A_ScriptDir%														// Set Include Directory path
																			// Includes behave as though the file's contents are present at this exact position
#SingleInstance force														// Reloads if already running
#NoEnv																		// Recommended for new scripts
#Warn, All, StdOut		 

SendMode Input  															// Recommended for new scripts
SetWorkingDir %A_ScriptDir%  												// Ensures a consistent starting directory
SetTitleMatchMode, 2 														// A window's title can contain the text anywhere
SetControlDelay, -1 														// Without this ControlClick fails sometimes. Example - Index Right click fails if mouse is over NOW

try{

	VWAPColumnIndex := ""													// Initialize some variables to avoid harmless warn errors

	loadSettings()															// Load settings for Timer before hotkey install
	SetTimer, PingNOW, %PingerPeriod% 										// Install Keep Alive Timer
	installEOD()															// Install Timer for EOD backfill once
	installHotkeys()														// Setup Hotkey for Backfill

} catch ex {
	handleException(ex)
}
return

installHotKeys(){
	global HKFlattenTL, HKBackfill, HKSetLayer, HKDelStudies
		
	if( HKBackfill == "ERROR" ||  HKBackfill == "" ){
		MsgBox, Set backfill Hotkey
		return
	}
	
	Hotkey, %HKBackfill%,  hkBackfill
	
	Hotkey, IfWinActive, ahk_class AmiBrokerMainFrameClass					// Context sensitive HK - only active if window is active	
	if( HKFlattenTL != "" && HKFlattenTL != "ERROR")
		Hotkey, %HKFlattenTL%, hkFlatTrendLine	
		
	if( HKSetLayer != "" && HKSetLayer != "ERROR")
		Hotkey, %HKSetLayer%, hkSetLayer
	
	if( HKDelStudies != "" && HKDelStudies != "ERROR")
		Hotkey, %HKDelStudies%, hkDelStudies
	
	Hotkey, Numpad9, hkWatchList											// Numpad9 to activate Watchlist and Numpad3 for symbols
	Hotkey, Numpad3, hkSymbols
	Hotkey, ^3, hk3min														// Redirect AB Timeframe change shortcuts to only 1 tab
	Hotkey, ^5, hk5min
	Hotkey, ^d, hkDaily
	Hotkey, ^w, hkWeekly
}

hkBackfill(){
	try{
		loadSettings()														// Reload settings
		installEOD()														// Update EOD Timer
		DoBackfill()	
	} catch e {
		handleException(e)
	}
}

// Control Ids change on layout selection, So instead click on hardcoded coordinates
hkWatchList(){
	try{
		//ControlClick, SysTreeView321, ahk_class AmiBrokerMainFrameClass,, LEFT,,NA
		Click 75,350
	} catch e {
		handleException(e)
	}
}
hkSymbols(){
	try{
		//ControlClick, SysListView323, ahk_class AmiBrokerMainFrameClass,, LEFT,,NA
		Click 75,605
	} catch e {
		handleException(e)
	}
}

hk3min(){
	try{		
		Click 1600,300
		Send ^3	
	} catch e {
		handleException(e)
	}
}
hk5min(){
	try{		
		Click 1600,300
		Send ^5	
	} catch e {
		handleException(e)
	}
}
hkDaily(){
	try{		
		Click 1600,300
		Send ^d
	} catch e {
		handleException(e)
	}
}
hkWeekly(){
	try{		
		Click 1600,300
		Send ^w
	} catch e {
		handleException(e)
	}
}

openDrawProperties(){	
	Click 2																// Double click at mouse position
	Loop, 20{															// Try to hide window as soon as possible. WinWait seems to take too long
		Sleep 25
		try{															// Ignore Error and keep trying until it opens
			WinSet,Transparent, 1, Properties, Start Y:					// Line Properties
			WinSet,Transparent, 1, Text box properties, Start Y:		// text properties
		}
		catch e{
		}
		IfWinExist, Properties, Start Y:
			break
		IfWinExist, Text box properties, Start Y:
			break
	}	
		
	IfWinExist, Properties, Start Y:									// Line Properties window opened?
	{
		WinWait, Properties, Start Y:, 1
		WinSet,Transparent, 1, Properties, Start Y:
		return true
	}
	IfWinExist, Text box properties, Start Y:
	{
		WinWait, Text box properties, Start Y:, 1
		WinSet,Transparent, 1, Text box properties, Start Y:
		return true
	}

	return false
}

closeDrawProperties(){
	IfWinExist, Properties, Start Y:
		ControlSend, Edit2, {Enter}, Properties, Start Y:
	IfWinExist, Text box properties, Start Y:
		ControlSend, Edit2, {Enter}, Text box properties, Start Y:
}


/* AB - Set Layer Name = Interval
*/
hkSetLayer(){
	try{
		if( !openDrawProperties() )
			return

		ControlGetText, interval, RichEdit20A2, ahk_class AmiBrokerMainFrameClass		// Copy interval
		IfWinExist, Properties, Start Y:
			Control, ChooseString, %interval%, ComboBox3, Properties, Start Y:
		IfWinExist, Text box properties, Start Y:
			Control, ChooseString, %interval%, ComboBox1, Text box properties, Start Y:
		closeDrawProperties()
	} catch e {
		handleException(e)
	}
}

hkDelStudies(){
	try{
		Click right
		//Send l		// When disabled, l select lock
		Send {Down 14}
		Send {Enter}
		Send {Space}
		Send {Esc}
	} catch e {
		handleException(e)
	}
}

hkFlatTrendLine(){															// Sets End price = Start price for trend line at current mouse position
	try{
		if( openDrawProperties() ){
			ControlGet, price, Line, 1, Edit1, Properties, Start Y:			// Copy Start Price into End Price and press enter
			ControlSetText, Edit2, %price%, Properties, Start Y:
			closeDrawProperties()
		}		
	}catch e {
		handleException(e)
	}
}


DoBackfill(){
	
	global NowWindowTitle, Mode, DoIndex
	
	IfWinExist, %NowWindowTitle%
	{			
		IfWinExist, Session Expired, E&xitNOW
		{
			MsgBox, NOW Locked.
			Exit
		}
		
		clearFiles()
		
		if( Mode = "DT" ){
			dtBackFill()		
		}
		else if( Mode = "VWAP" )  {	
			vwapBackFill()
		}	
		if( DoIndex = "Y"){
			indexBackFill()
		}		
		
		save()
	}
	else{
		MsgBox, NOW not found.
	}
}

getExpectedDataRowCount(){
	global START_HOUR, START_MIN, END_HOUR, END_MIN

	hour 		  := A_Hour>END_HOUR ? END_HOUR : A_Hour
	min  		  := (A_Hour>END_HOUR || (A_Hour==END_HOUR && A_Min>END_MIN) ) ? END_MIN : A_Min
	ExpectedCount := (hour - START_HOUR)*60 + (min - START_MIN)								

	if( !isMarketClosed() && ExpectedCount > 1 )
		ExpectedCount := ExpectedCount-1									// Allow 1 less minute for border case - 
																			// Minute changes between data fetch and call to getExpectedDataRowCount() 
	return ExpectedCount
}

createFileDirectory( file_path ){											// Create File directory path if it does not exist
	
	SplitPath, file_path,, directory
	
	IfNotExist, %directory%
		FileCreateDir, %directory%
}

clearFiles(){
	global VWAPBackfillFileName, DTBackfillFileName
	
	IfExist, %DTBackfillFileName%											// Clear Out DT data
	{
		file := FileOpen(DTBackfillFileName, "w" )	  
		if IsObject(file){
			file.Write("")
			file.Close()
		}
	}	
	IfExist, %VWAPBackfillFileName%											// Clear Out VWAP data
	{
		file := FileOpen(VWAPBackfillFileName, "w" )	  
		if IsObject(file){
			file.Write("")
			file.Close()
		}
	}
}

save(){
	global BackfillExe, BackfillExePath
	RunWait, %BackfillExe%, %BackfillExePath%,hide 							// Do backfill by calling exe	
	if ErrorLevel
		MsgBox, Backfill failed, check logs.
}

PingNOW(){	
	global NowWindowTitle		
	
	IfWinExist, %NowWindowTitle%
	{		
		ControlClick, Button9, %NowWindowTitle%,, LEFT,,NA					// Just click on Button9  (  INT/Boardcast status Button ) 
	}																		// Button9 is common to both Now and Nest
}

installEOD(){
	global EODBackfillTriggerTime	
	
	targetTime  := StrSplit( EODBackfillTriggerTime, ":")
	timeLeft	:= (targetTime[1] - A_Hour)*60 + ( targetTime[2] - A_Min )	// Time left to Trigger EOD Backfill in mins

	if( timeLeft > 0 ){
		SetTimer, EODBackfill, % (timeLeft * 60 * -1000 )					// -ve Period => Run only once
	}
	else{
		SetTimer, EODBackfill, Delete
	}
}

EODBackfill(){	
	
	MsgBox, 4,, Do EOD Backfill ?, 10										// 10 second Timeout
	IfMsgBox, No
		Return	

	DoBackfill( )
}

isMarketClosed(){	
	
	time := A_Hour . ":" . A_Min
	return 	! isTimeInMarketHours(time)
}

/*
	Checks if Time is within Market Hours
*/
isTimeInMarketHours( time ){
	global START_TIME, END_TIME	

	return time >= START_TIME &&  time <= END_TIME
}

// 05-11-2015
isDateToday( date ) {
	return (  date == (A_DD . "-" . A_MM . "-" . A_YYYY )   )
}

/*
	Converts from 12h hh:mm:ss to 24h HH:MM. Example "03:03:15 PM" to "15:03"	
*/
convert24HHMM( time ){

	timeSplit := StrSplit( time, ":") 
	secSplit  := StrSplit( timeSplit[3], " ") 
	
	if( secSplit[2] == "PM" && timeSplit[1] < 12 ){							// Add 12 to Hours if PM. But not for 12
		timeSplit[1] := timeSplit[1] + 12
	}
	
	return timeSplit[1] . ":" . timeSplit[2]
}


/*
  VWAP for stocks in NOW has 09:14:XX as first row. Change it to 09:15
*/ 
isVWAPStartTimeFixNeeded( time ){
	global START_TIME_VWAP
	
	return (time == START_TIME_VWAP)
}

/*
	Input - HH:MM  (24hr)
*/
fixStartTime( time ){	
	if( isVWAPStartTimeFixNeeded( time ) ){
		timeSplit := StrSplit( time, ":") 
		time 	  := addMinute( timeSplit[1], timeSplit[2] )			
	}
	return time
}

/*
	Adds 1 to minute - used in VWAP to move first minute
	Returns time in HH:MM
*/
addMinute( HH, MM ){
	if( MM == 59 )
		return % (HH+1) . ":00"
	else
		return % HH . ":" . (MM+1)
}

subMinute( HH, MM ){
	if( MM == 00 )
		return % (HH-1) . ":59"
	else
		return % HH . ":" . (MM-1)
}
 

timer( mode ){
	static start := 0
	
	if( mode == "start" ) {
		start := A_TickCount
	}
	if( mode == "end" ) {
		return (A_TickCount - start )
	}
}

handleException(e){
	MsgBox % "Error in " . e.What . ", Location " . e.File . ":" . e.Line . " Message:" . e.Message . " Extra:" . e.Extra
}


#Include Settings.ahk
#Include DataTable.ahk
#Include Vwap.ahk

#CommentFlag ;
#include Lib/__ExternalHeaderLib.ahk										; External Library to read Column Headers
