SuperStrict

Framework brl.Random
Import BRL.FileSystem
Import BRL.TextStream
Import BRL.Retro


SeedRnd MilliSecs()

Local filename:String
If AppArgs.Length > 1
	filename = AppArgs[1]
	Local lf:TStream = WriteFile("last")
	lf.WriteBytes(filename.ToCString(), filename.Length)
Else
	filename = LoadText("last")
End If

Local score:TmidiScore = fromFile(filename)

score.saveMidi(StripExt(filename) + ".mid")

End

Function fromFile:TmidiScore(file:String)
	If FileType(file) = 0 Return Null
	
	Local ifsfunctions:TList
	Local nr_ifs:Int, itr:Int, p:Float[], dim:Int, ifs_mode:Int
	
	Local score:TmidiScore = New TmidiScore
	
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
		Local seed:Int = 0
		Select title
			Case "score"
				cs = Instr(content, "itr")
				If cs <> 0
					cs:+4
					ce = Instr(content, ";", cs)
					itr = Mid(content, cs, ce - cs).ToInt()
				End If
				
				cs = Instr(content, "nr_ifs")
				If cs <> 0
					cs:+7
					ce = Instr(content, ";", cs)
					nr_ifs = Mid(content, cs, ce - cs).ToInt()
				End If
				
				cs = Instr(content, "ifs_mode")
				If cs <> 0
					cs:+9
					ce = Instr(content, ";", cs)
					ifs_mode = Mid(content, cs, ce - cs).ToInt()
				End If
				
				cs = Instr(content, "bpq")
				If cs <> 0
					cs:+4
					ce = Instr(content, ";", cs)
					score.bpq = Mid(content, cs, ce - cs).ToInt()
				End If
				
				cs = Instr(content, "speedrange")
				If cs <> 0
					cs:+11
					ce = Instr(content, ";", cs)
					Local tmparr:String[] = Mid(content, cs, ce - cs).Split(",")
					For Local n:Int = 0 Until tmparr.Length
						score.speedrange[n] = tmparr[n].ToFloat()
					Next
				End If
			Case "channel"
				Local t:TmidiChannel = New TmidiChannel
				score.channellist.AddLast(t)
				
				cs = Instr(content, "id")
				If cs <> 0
					cs:+3
					ce = Instr(content, ";", cs)
					t.id = Mid(content, cs, ce - cs).ToInt()
				End If
				
				cs = Instr(content, "instrument")
				If cs <> 0
					cs:+11
					ce = Instr(content, ";", cs)
					t.instrument = Mid(content, cs, ce - cs).ToInt()
					If t.instrument = -1 Then t.instrument = Rand(0, 127)
				End If
				
				cs = Instr(content, "pitchlist")
				If cs <> 0
					cs:+10
					ce = Instr(content, ";", cs)
					Local tmparr:String[] = Mid(content, cs, ce - cs).Split(",")
					If tmparr[0] = "ms"
						t.pitchlist = modScale(tmparr[1].ToInt(), tmparr[3].ToInt(), tmparr[2].ToInt())
					Else If tmparr[0] = "cs"
						t.pitchlist = chromaticScale(tmparr[1].ToInt(), tmparr[2].ToInt())
					Else
						t.pitchlist = CreateList()
						For Local str:String = EachIn tmparr
							If str[0] > 47 And str[0] < 58
								t.pitchlist.AddLast(TByte.n(str.ToInt()))
							Else
								t.pitchlist.AddLast(TByte.n(NoteFromString(str)))
							End If
						Next
					End If
				End If
				
				cs = Instr(content, "pitchlistw")
				If cs <> 0
					cs:+11
					ce = Instr(content, ";", cs)
					Local tmparr:String[] = Mid(content, cs, ce - cs).Split(",")
					t.pitchlistw = CreateList()
					If tmparr[0] = "fill"
						For Local tb:TByte = EachIn t.pitchlist
							t.pitchlistw.AddLast(TByte.n(1))
						Next
					Else
						For Local str:String = EachIn tmparr
							If str[0] > 47 And str[0] < 58
								t.pitchlistw.AddLast(TByte.n(str.ToInt()))
							Else
								t.pitchlistw.AddLast(TByte.n(NoteFromString(str)))
							End If
						Next
					End If
				End If
				
				cs = Instr(content, "valuelist")
				If cs <> 0
					cs:+10
					ce = Instr(content, ";", cs)
					Local tmparr:String[] = Mid(content, cs, ce - cs).Split(",")
					t.valuelist = CreateList()
					For Local str:String = EachIn tmparr
						If str[0] > 47 And str[0] < 58
							t.valuelist.AddLast(TByte.n(str.ToInt()))
						Else
							t.valuelist.AddLast(TByte.n(NoteFromString(str)))
						End If
					Next
				End If
				
				cs = Instr(content, "valuelistw")
				If cs <> 0
					cs:+11
					ce = Instr(content, ";", cs)
					Local tmparr:String[] = Mid(content, cs, ce - cs).Split(",")
					t.valuelistw = CreateList()
					If tmparr[0] = "fill"
						For Local tb:TByte = EachIn t.pitchlist
							t.pitchlistw.AddLast(TByte.n(1))
						Next
					Else
						For Local str:String = EachIn tmparr
							If str[0] > 47 And str[0] < 58
								t.valuelistw.AddLast(TByte.n(str.ToInt()))
							Else
								t.valuelistw.AddLast(TByte.n(NoteFromString(str)))
							End If
						Next
					End If
				End If
				
				cs = Instr(content, "touchrange")
				If cs <> 0
					cs:+11
					ce = Instr(content, ";", cs)
					Local tmparr:String[] = Mid(content, cs, ce - cs).Split(",")
					For Local n:Int = 0 Until tmparr.Length
						t.touch_range[n] = tmparr[n].ToFloat()
					Next
				End If
		End Select
	Wend
	
	dim = score.channellist.Count() * 3 + 2
	p = p[..dim]
	
	ifsfunctions = rnd_IFS(nr_ifs, dim, ifs_mode)
	
	For Local i:Int = 0 Until dim
		p[i] = Rnd()
	Next
	
	generate_IFS(itr, p, ifsfunctions, score)
	
	Return score
End Function

Function rnd_IFS:TList(nr:Int, dim:Int, mode:Int = 0)
	Local ifsfunctions:TList = CreateList()
	For Local n:Int = 0 Until nr
		Local p:Float[dim]
		Local s:Float[dim]
		
		If mode = 0
			Local v:Float = Rnd()
			For Local i:Int = 0 Until dim
				p[i] = Rnd()
				s[i] = v
			Next
		Else
			For Local i:Int = 0 Until dim
				p[i] = Rnd()
				s[i] = Rnd()
			Next
		End If
		
		ifsfunctions.AddLast(TIFSfunction.n(p, s))
	Next
	Return ifsfunctions
End Function

Function generate_IFS(itr:Int, p:Float[], ifsfunctions:TList, score:TmidiScore)
	Local nr_c:Int = (p.length - 2) / 3
	Local channel_t:Int[nr_c + 1]
	For Local i:Int = 0 Until itr
		Local ifs:TIFSfunction
		ifs = TIFSfunction(ifsfunctions.ValueAtIndex(Rand(0, ifsfunctions.Count() - 1)))
		
		For Local n:Int = 0 Until p.length
			p[n] = clip(p[n], ifs.p[n], ifs.s[n])
		Next
		
		If channel_t[nr_c] <= 0
			channel_t[nr_c] = clip(score.speedrange[2], score.speedrange[3], p[1])
			score.speedlist.AddLast(TmidiSpeed.n(clip(score.speedrange[0], score.speedrange[1], p[0]), channel_t[nr_c]))
		End If
		channel_t[nr_c]:-1
		
		Local n:Int = 0
		For Local t:TmidiChannel = EachIn score.channellist
			If channel_t[n] <= 0
				channel_t[n] = t.getValue(p[n * 3 + 3])
				t.notelist.AddLast(TmidiNote.n(t.getPitch(p[n * 3 + 2]), channel_t[n], clip(t.touch_range[0], t.touch_range[1], p[n * 3 + 4])))
			End If
			
			channel_t[n]:-1
			n:+1
		Next
	Next
End Function

Type TmidiNote
	Field pitch:Float, value:Float, touch:Float
	
	Function N:TmidiNote(pitch:Float, value:Float, touch:Float)
		Local t:TmidiNote = New TmidiNote
		t.pitch = pitch
		t.value = value
		t.touch = touch
		Return t
	End Function
End Type

Type TmidiSpeed
	Field speed:Int, value:Int
	
	Function N:TmidiSpeed(speed:Int, value:Int)
		Local t:TmidiSpeed = New TmidiSpeed
		t.speed = speed
		t.value = value
		Return t
	End Function
End Type

Type TmidiChannel
	Field id:Int
	Field instrument:Int
	Field notelist:TList
	
	Field pitchlist:TList
	Field pitchlistw:TList
	
	Field valuelist:TList
	Field valuelistw:TList
	
	Field touch_range:Int[2]
	
	Method New()
		notelist = CreateList()
	End Method
	
	Method getPitch:Byte(x:Float)
		Local totalw:Int = 0, wcnt:Int = 0
		For Local t:TByte = EachIn pitchlistw
			totalw:+t.v
		Next
		x = totalw * x
		Local tl:TLink
		tl = pitchlist.FirstLink()
		For Local t:TByte = EachIn pitchlistw
			wcnt:+t.v
			If wcnt > x
				Return TByte(tl.Value()).v
			End If
			tl = tl.NextLink()
		Next
	End Method
	
	Method getValue:Byte(x:Float)
		Local totalw:Int = 0, wcnt:Int = 0
		For Local t:TByte = EachIn valuelistw
			totalw:+t.v
		Next
		x = totalw * x
		Local tl:TLink
		tl = valuelist.FirstLink()
		For Local t:TByte = EachIn valuelistw
			wcnt:+t.v
			If wcnt > x
				Return TByte(tl.Value()).v
			End If
			tl = tl.NextLink()
		Next
	End Method
End Type

Type TmidiScore
	Field channellist:TList
	
	Field speedlist:TList
	
	Field speedrange:Int[4]
	
	Field bpq:Int
	
	Method New()
		speedlist = CreateList()
		channellist = CreateList()
	End Method
	
	Method saveMidi(filename:String)
		Local file:TStream = WriteFile(filename)
		
		Local bytelist:TList = CreateList()
		
		'HEADER		
		toByteArr($4D546864, 4, bytelist)'Name="MThd"
		toByteArr($00000006, 4, bytelist)'Chunck Size
		toByteArr($0000, 2, bytelist)'Format Type
		toByteArr(channellist.Count() + 1, 2, bytelist)'Nr of Tracks
		toByteArr($7fff & bpq, 2, bytelist)'Time Division
		
		For Local t:TByte = EachIn bytelist
			file.WriteByte(t.v)
		Next
		
		bytelist.Clear()
		
		Local dt:Int = 0
		For Local t:TmidiSpeed = EachIn speedlist
			toVariableLength(dt, bytelist) 'delta time
			bytelist.AddLast(TByte.N($FF))'metaevent
			bytelist.AddLast(TByte.N($51))'type/set tempo
			bytelist.AddLast(TByte.N(3))'length
			toByteArr(t.speed, 3, bytelist)'tempo microseconds per quarter note
			
			dt = t.value
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
		
		For Local tc:TmidiChannel = EachIn channellist
			bytelist.Clear()
			
			If tc.id <> 9
				'''''''Set Instrument
				bytelist.AddLast(TByte.N(0))'delta time
				bytelist.AddLast(TByte.N($C0 | tc.id))'eventtype0|channelnr
				bytelist.AddLast(TByte.N(tc.instrument))'p1
			End If
			
			dt = 0
			For Local mn:TmidiNote = EachIn tc.notelist
				If mn.pitch <> $ff
					''''''''Note On
					toVariableLength(dt, bytelist)'delta time
					bytelist.AddLast(TByte.N($90 | tc.id))'eventtype0|channelnr
					bytelist.AddLast(TByte.N(mn.pitch))'p1
					bytelist.AddLast(TByte.N(mn.touch))'p2
					dt = mn.value
					''''''''Note Off
					toVariableLength(dt, bytelist)'delta time
					bytelist.AddLast(TByte.N($80 | tc.id))'eventtype0|channelnr
					bytelist.AddLast(TByte.n(mn.pitch))'p1
					bytelist.addlast(TByte.N(mn.touch))'p2
					dt = 0
				Else
					dt:+mn.value
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

Type TIFSfunction
	Field p:Float[]
	Field s:Float[]
	
	Function N:TIFSfunction (p:Float[], s:Float[])
		Local t:TIFSfunction = New TIFSfunction
		t.p = p[..]
		t.s = s[..]
		Return t
	End Function
End Type

Type TByte
	Field v:Byte
	
	Function N:TByte(v:Byte)
		Local t:TByte = New TByte
		t.v = v
		Return t
	End Function
End Type

Function clip:Float(a:Float, b:Float, x:Float)
	Return a + x * (b - a)
End Function

Function clamp:Float(x:Float, a:Float, b:Float)
	Return Min(Max(x, a), b)
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

Function chromaticScale:TList(start:Int, length:Int)
	Local pitchlist:TList = CreateList()
	For Local i:Int = 0 Until length
		pitchlist.AddLast(TByte.N(start + i))
	Next
	
	Return pitchlist
End Function

Function modScale:TList(start:Int, deg:Int, length:Int)
	Local pitchlist:TList = CreateList()
	Local degoff:Int
	If deg < 3 Then degoff = deg * 2 Else degoff = deg * 2 - 1
	For Local n:Int = deg Until length + deg
		If n Mod 7 < 3
			pitchlist.AddLast(TByte.N(start - degoff + 12 * Int(n / 7) + (n Mod 7) * 2))
		Else
			pitchlist.AddLast(TByte.N(start - degoff + 12 * Int(n / 7) + (n Mod 7) * 2 - 1))
		End If
	Next
	
	Return pitchlist
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
