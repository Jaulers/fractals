SuperStrict
Framework brl.Retro
Import BRL.Timer
Import bah.rtmidi

Local filename:String
If AppArgs.Length > 1
	filename = AppArgs[1]
Else
	filename = Input("Datei angeben: ")
End If


Global score:TmidiScore = New TmidiScore
score.midiOut = New TRtMidiOut.Create()
score.midiOut.openPort(0)
OnEnd(CleanUp)

score.loadMusic(filename)

score.saveAsMidi(StripExt(filename) + ".mid")

'score.play

End

Function CleanUp()
	score.midiOut.closePort()
	score.midiOut.Free()
	Delay(300)
End Function

Function NoteFromString:Byte(n:String)
	If n = "p" Then Return $ff
	Local os:Int = 0
	Local t:String = Mid(n, 2, 1)
	If t = "#" Or t = "b"
		t = Left(n, 2)
		os = Mid(n, 3).ToInt() + 2
	Else
		t = Left(n, 1)
		os = Mid(n, 2).ToInt() + 2
	End If
	Select t
		Case "C"
			Return 0 + $0C * os
		Case "C#"
			Return 1 + $0C * os
		Case "D"
			Return 2 + $0C * os
		Case "D#"
			Return 3 + $0C * os
		Case "E"
			Return 4 + $0C * os
		Case "F"
			Return 5 + $0C * os
		Case "F#"
			Return 6 + $0C * os
		Case "G"
			Return 7 + $0C * os
		Case "G#"
			Return 8 + $0C * os
		Case "A"
			Return 9 + $0C * os
		Case "A#"
			Return 10 + $0C * os
		Case "B"
			Return 11 + $0C * os
	End Select
End Function

Function L_System:String(itr:Int, a:String, rules:String[])
	For Local n:Int = 0 Until itr
		Local a1:String
		For Local i:Int = 0 Until Len(a)
			For Local s:String = EachIn rules
				If Chr(s[0]) = Chr(a[i])
					a1 = a1 + Mid(s, 3)
					Exit
				End If
			Next
		Next
		a = a1
	Next
	Return a
End Function


Type TmidiNote
	Field note:Byte
	Field length:Int
End Type

Type TmidiChannel
	Field id:Int
	
	Field notes:TmidiNote[]
	Field instrument:Byte
	Field volume:Byte
	
	Field currentNote:Int
	Field arrlength:Int
	Field currentNoteTimer:Int
	
	Method fromStrings(pstr:String, pindex:String[], vstr:String, vindex:String[])
		pstr = Left(pstr, Len(vstr))
		vstr = Left(vstr, Len(pstr))
		
		Local l:Int = Len(pstr)
		
		notes = New TmidiNote[l]
		arrlength = l
		
		For Local i:Int = 0 Until l
			Local p:Int, t:TmidiNote = New TmidiNote
			p = 0
			For Local s:String = EachIn pindex
				If Chr(s[0]) = Chr(pstr[i])
					t.note = NoteFromString(Mid(s, 3))
					p = 1
				End If
			Next
			If p = 0 Then t.Note = $ff
			p = 0
			For Local s:String = EachIn vindex
				If Chr(s[0]) = Chr(vstr[i])
					t.length = Mid(s, 3).ToInt()
					p = 1
				End If
			Next
			If p = 0 Then t.length = 4
			notes[i] = t
		Next
	End Method
End Type

Type TmidiScore
	Field channels:TList
	Field speedHz:Float
	Field midiOut:TRtMidiOut
	
	Method New()
		channels = CreateList()
	End Method
	
	Method addChannel(channel:TmidiChannel)
		Self.channels.AddLast(channel)
	End Method
	
	Method play()
		Local timer:TTimer = CreateTimer(speedHz)
		
		
		Local channelnr:Int = 0, channels_finished:Byte = 0
		For Local c:TmidiChannel = EachIn channels
			midi2Byte(midiOut, $C0 | c.id, c.instrument)
			midi3Byte(midiOut, $B0 | c.id, $07, c.volume)
			c.currentNote = 0
			c.currentNoteTimer = 0
			
			channelnr:+1
		Next
		While channels_finished <> channelnr
			channelnr = 0
			channels_finished = 0
			For Local c:TmidiChannel = EachIn channels
				If c.currentNote < c.arrlength
					If c.currentNoteTimer = c.notes[c.currentNote].length
						If c.notes[c.currentNote].Note <> $ff
							midi3Byte(midiOut, $80 | c.id, c.notes[c.currentNote].Note, $3F)
						End If
						
						c.currentNote:+1
						c.currentNoteTimer = 0
					End If
					
					If c.currentNoteTimer = 0 And c.currentNote < c.arrlength And c.notes[c.currentNote].Note <> $ff
						midi3Byte(midiOut, $90 | c.id, c.notes[c.currentNote].note, $3F)
					End If
					c.currentNoteTimer:+1
				Else
					channels_finished:+1
				End If
				channelnr:+1
			Next
			WaitTimer(timer)
		Wend
	End Method
	
	Method loadMusic(file:String)
		If FileType(file) = 1
			file = LoadText(file)
			file = Replace(file, " ", "")
			file = Replace(file, Chr(9), "")
			file = Replace(file, Chr(10), "")
			file = Replace(file, Chr(13), "")
			
			Local gs:Int = 1, ge:Int = 0, content:String, title:String
			
			Repeat
				gs = Instr(file, "/*")
				If gs = 0 Exit
				ge = Instr(file, "*/", gs)
				file = Mid(file, 1, gs - 1) + Mid(file, ge + 2)
			Forever
			
			gs = 1;ge = 0
			
			While ge < Len(file)
				gs = Instr(file, "{", ge)
				title = Mid(file, ge + 1, gs - ge - 1)
				ge = Instr(file, "}", gs + 1)
				content = Mid(file, gs + 1, ge - gs - 1)
				
				Local cs:Int = 0, ce:Int = 0
				Select title
					Case "general"
						cs = Instr(content, "speed")
						If cs <> 0
							cs:+6
							ce = Instr(content, ";", cs)
							speedHz = Mid(content, cs, ce - cs).ToFloat()
						End If
						
					Case "channel"
						Local c:TmidiChannel = New TmidiChannel
						Self.addChannel(c)
						
						Local pitr:Int, pstart:String, prules:String[], pindex:String[], pbegin:String, pend:String
						Local vitr:Int, vstart:String, vrules:String[], vindex:String[], vbegin:String, vend:String
						
						cs = Instr(content, "id")
						If cs <> 0
							cs:+3
							ce = Instr(content, ";", cs)
							c.id = Mid(content, cs, ce - cs).ToInt()
						End If
						
						cs = Instr(content, "instrument")
						If cs <> 0
							cs:+11
							ce = Instr(content, ";", cs)
							c.instrument = Mid(content, cs, ce - cs).ToInt()
						End If
						
						cs = Instr(content, "volume")
						If cs <> 0
							cs:+7
							ce = Instr(content, ";", cs)
							c.volume = Mid(content, cs, ce - cs).ToInt()
						End If
						
						
						cs = Instr(content, "pitch_iterations")
						If cs <> 0
							cs:+17
							ce = Instr(content, ";", cs)
							pitr = Mid(content, cs, ce - cs).ToInt()
						End If
						
						cs = Instr(content, "pitch_start")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							pstart = Mid(content, cs, ce - cs)
						End If
						
						cs = Instr(content, "pitch_rules")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							prules = Mid(content, cs, ce - cs).Split(",")
						End If
						
						cs = Instr(content, "pitch_index")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							pindex = Mid(content, cs, ce - cs).Split(",")
						End If
						
						cs = Instr(content, "pitch_begin")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							pbegin = Mid(content, cs, ce - cs)
						End If
						
						cs = Instr(content, "pitch_end")
						If cs <> 0
							cs:+10
							ce = Instr(content, ";", cs)
							pend = Mid(content, cs, ce - cs)
						End If
						
						
						cs = Instr(content, "value_iterations")
						If cs <> 0
							cs:+17
							ce = Instr(content, ";", cs)
							vitr = Mid(content, cs, ce - cs).ToInt()
						End If
						
						cs = Instr(content, "value_start")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							vstart = Mid(content, cs, ce - cs)
						End If
						
						cs = Instr(content, "value_rules")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							vrules = Mid(content, cs, ce - cs).Split(",")
						End If
						
						cs = Instr(content, "value_index")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							vindex = Mid(content, cs, ce - cs).Split(",")
						End If
						
						cs = Instr(content, "value_begin")
						If cs <> 0
							cs:+12
							ce = Instr(content, ";", cs)
							vbegin = Mid(content, cs, ce - cs)
						End If
						
						cs = Instr(content, "value_end")
						If cs <> 0
							cs:+10
							ce = Instr(content, ";", cs)
							vend = Mid(content, cs, ce - cs)
						End If
						
						Local pstr:String, vstr:String
						pstr = pbegin + L_System(pitr, pstart, prules) + pend
						vstr = vbegin + L_System(vitr, vstart, vrules) + vend
						
						c.fromStrings(pstr, pindex, vstr, vindex)
				End Select
			Wend
		Else
			RuntimeError("File does not exist!")
		End If
	End Method
	
	Method saveAsMidi(filename:String)
		Local file:TStream = WriteFile(filename)
		
		Local bytelist:TList = CreateList()
		
		'HEADER		
		toByteArr($4D546864, 4, bytelist)'Name="MThd"
		toByteArr($00000006, 4, bytelist)'Chunck Size
		toByteArr($0000, 2, bytelist)'Format Type
		toByteArr(channels.Count(), 2, bytelist)'Nr of Tracks
		toByteArr($7fff & Int(speedHz * 10), 2, bytelist)'Time Division
		
		For Local t:TByte = EachIn bytelist
			file.WriteByte(t.v)
		Next
		
		bytelist.Clear()
		
		'TRACKS
		
'		'End of Track Marker
'		bytelist.AddLast(TByte.N(0)) 'delta time
'		bytelist.AddLast(TByte.N($FF))'metaevent
'		bytelist.AddLast(TByte.N($2F))'type
'		bytelist.AddLast(TByte.N($0))'length
'		
'		'TRACK header
'		file.WriteBytes(toByteArr($4D54726B, 4), 4)
'		file.WriteBytes(toByteArr(bytelist.Count(), 4), 4)
		
		For Local c:TmidiChannel = EachIn channels
			bytelist.Clear()
			
			Local dt:Int = 0
			
			If c.id <> 9
				'''''''Set Instrument
				bytelist.AddLast(TByte.N(0))'delta time
				bytelist.AddLast(TByte.N($C0 | c.id))'eventtype0|channelnr
				bytelist.AddLast(TByte.N(c.instrument))'p1
			End If
			
			'''''''Set Volume
			bytelist.AddLast(TByte.N(0))'delta time
			bytelist.AddLast(TByte.N($B0 | c.id))'eventtype0|channelnr
			bytelist.AddLast(TByte.N($07))'p1
			bytelist.addlast(TByte.N(c.volume))'p2
			
			For Local mn:TmidiNote = EachIn c.notes
				If mn.note <> $ff
					''''''''Note On
					toVariableLength(dt, bytelist)'delta time
					bytelist.AddLast(TByte.N($90 | c.id))'eventtype0|channelnr
					bytelist.AddLast(TByte.N(mn.note))'p1
					bytelist.AddLast(TByte.N($3F))'p2
					dt = mn.length * 20
					''''''''Note Off
					toVariableLength(dt, bytelist)'delta time
					bytelist.AddLast(TByte.N($80 | c.id))'eventtype0|channelnr
					bytelist.AddLast(TByte.N(mn.note))'p1
					bytelist.addlast(TByte.N($3F))'p2
					dt = 0
				Else
					dt:+mn.length * 20
				End If
			Next
			
			'End of Track Marker
			bytelist.AddLast(TByte.N(0))'delta time
			bytelist.AddLast(TByte.N($FF))'metaevent
			bytelist.AddLast(TByte.N($2F))'type
			bytelist.AddLast(TByte.N($0))'length
			
			'TRACK header
			file.WriteBytes(toByteArr($4D54726B, 4), 4)
			file.WriteBytes(toByteArr(bytelist.Count(), 4), 4)
			
			For Local t:TByte = EachIn bytelist
				file.WriteByte(t.v)
			Next
		Next
		
		file.Close()
	End Method
End Type

Type TByte
	Field v:Byte
	Function N:TByte(v:Byte)
		Local t:TByte = New TByte
		t.v = v
		Return t
	End Function
End Type

Function midi3Byte(midiOut:TRtMidiOut, v1:Byte, v2:Byte, v3:Byte)
	Local m:Byte[3]
	m[0] = v1
	m[1] = v2
	m[2] = v3
	midiOut.putMessage(m, 3)
End Function

Function midi2Byte(midiOut:TRtMidiOut, v1:Byte, v2:Byte)
	Local m:Byte[2]
	m[0] = v1
	m[1] = v2
	midiOut.putMessage(m, 2)
End Function

Function Count:Int(str:String, char:Byte)
	Local cnt:Int = 0
	For Local n:Int = 0 Until Len(str)
		If char = str[n] Then cnt:+1
	Next
	Return cnt
End Function

Function toByteArr:Byte[] (v:Long, length:Int, list:TList = Null)
	Local bytes:Byte[length]
	For Local n:Int = 0 Until length
		Local n2:Int = length - n - 1
		bytes[n] = (v & ($ff Shl (n2 * 8))) Shr (n2 * 8)
		If list <> Null Then list.AddLast(TByte.N(bytes[n]))
	Next
	Return bytes
End Function

Function toVariableLength:Byte[] (v:Int, list:TList = Null)
	If v < %10000000
		Local bytes:Byte[1]
		bytes[0] = v & %01111111
		If list <> Null Then list.AddLast(TByte.n(bytes[0]))
		Return bytes
	Else If v < %100000000000000
		Local bytes:Byte[2]
		bytes[1] = v & %01111111
		bytes[0] = ((v & %011111110000000) Shr 7) | %10000000
		If list <> Null
			list.AddLast(TByte.N(bytes[0]))
			list.AddLast(TByte.N(bytes[1]))
		End If
		Return bytes
	Else If v < %1000000000000000000000
		Local bytes:Byte[3]
		bytes[2] = v & %01111111
		bytes[1] = ((v & %011111110000000) Shr 7) | %10000000
		bytes[0] = ((v & %0111111100000000000000) Shr 14) | %10000000
		If list <> Null
			list.AddLast(TByte.N(bytes[0]))
			list.AddLast(TByte.N(bytes[1]))
			list.AddLast(TByte.N(bytes[2]))
		End If
		Return bytes
	Else
		Local bytes:Byte[4]
		bytes[3] = v & %01111111
		bytes[2] = ((v & %011111110000000) Shr 7) | %10000000
		bytes[1] = ((v & %0111111100000000000000) Shr 14) | %10000000
		bytes[0] = ((v & %01111111000000000000000000000) Shr 21) | %10000000
		If list <> Null
			list.AddLast(TByte.N(bytes[0]))
			list.AddLast(TByte.N(bytes[1]))
			list.AddLast(TByte.N(bytes[2]))
			list.AddLast(TByte.N(bytes[3]))
		End If
		Return bytes
	End If
End Function
