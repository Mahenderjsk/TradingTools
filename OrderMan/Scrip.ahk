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

class ScripClass{														// Scrip details used in create/modify order
	segment		:= ""
	instrument  := ""
	symbol		:= ""
	type		:= ""
	strikePrice	:= ""
	expiryIndex := ""
	
	alias		:= ""													// Scrip Alias display in GUI having ini config of same name
	
	setInput( inSegment, inInstrument, inSymbol, inType, inStrikePrice, inExpiryIndex, inAlias ){
		this.segment		:= inSegment
		this.instrument		:= inInstrument
		this.symbol			:= inSymbol
		this.type			:= inType
		this.strikePrice	:= inStrikePrice
		this.expiryIndex 	:= inExpiryIndex
		this.alias			:= inAlias
		
	}
}
