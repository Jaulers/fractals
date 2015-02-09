SuperStrict
Framework brl.GLGraphics
Import brl.TIMER
Import brl.TextStream
Import pub.OpenGL
Import pub.Glew
Import brl.Retro
Import brl.PNGLoader

Const GW:Int = 640, GH:Int = 360

If AppArgs.Length > 1
	TAnimFrame.LoadFromFile(AppArgs[1])
End If

Global TIMER:TTimer = CreateTimer(30)
Global VERTEX_SHADER_CODE:String = LoadText("vs.glsl")
Global FRAGMENT_SHADER_CODE:String = LoadText("fs.glsl")

InitGL
Global ProgramObj:Int
InitShaders
glUseProgram(ProgramObj)

Global camS:Float = 0.04
Global camX:Float = -0.9, camY:Float = -1.35, camZ:Float = -3.6, camW:Float = 0.0
Global camP:Float = 0.2, camT:Float = -0.37

Global lightX:Float = -1.6, lightY:Float = -0.9, lightZ:Float = -2.4

Global camZoom:Float = 1.0

Global cx:Float = 0, cy:Float = 0, cz:Float = 0, cw:Float = 0
Global itr:Int = 11
Global eps:Float = 0.001

Global disphelp:Int = 0

Global cf:TAnimFrame, cflink:TLink

'Render()
'SaveSceenshot()
'End

Global MDown:Int, MXS:Int, MYS:Int
Global zwsp:Float
While Not KeyHit(KEY_ESCAPE)
	MDown = MouseDown(MOUSE_LEFT) Shl 2 + MouseDown(MOUSE_MIDDLE) Shl 1 + MouseDown(MOUSE_RIGHT)
	MXS = MouseXSpeed()
	MYS = MouseYSpeed()
	If MDown & %100
		MoveMouse GW / 2, GH / 2
		MouseXSpeed()
		MouseYSpeed()
	End If
	
	CheckInput()
	
	Render()
	
	If disphelp Then glUseProgram(0) DrawHelp() glUseProgram(ProgramObj)
	
	Flip 0
	glCls
	WaitTimer TIMER
Wend
End

Function CheckInput()
	If KeyDown(KEY_2) camS:*1.05 Else If KeyDown(KEY_1) camS:/1.05
	
	If KeyDown(KEY_4) eps:*1.1 Else If KeyDown(KEY_3) eps:/1.1
	
	itr:+KeyHit(KEY_6) - KeyHit(KEY_5)
	
	If KeyDown(KEY_8) camZoom:*1.05 Else If KeyDown(KEY_7) camZoom:/1.05
	
	If MDown & 010
		lightX = camX
		lightY = camY
		lightZ = camZ
	End If
	
	If KeyDown(KEY_W)
		camX = camX + cos_(camT) * sin_(camP) * camS
		camY = camY - sin_(camT) * camS
		camZ = camZ + cos_(camT) * cos_(camP) * camS
	End If
	If KeyDown(KEY_S)
		camX = camX - cos_(camT) * sin_(camP) * camS
		camY = camY + sin_(camT) * camS
		camZ = camZ - cos_(camT) * cos_(camP) * camS
	End If
	If KeyDown(KEY_D)
		camX = camX + sin_(camP + 1.57079633) * camS
		camZ = camZ + cos_(camP + 1.57079633) * camS
	End If
	If KeyDown(KEY_A)
		camX = camX - sin_(camP + 1.57079633) * camS
		camZ = camZ - cos_(camP + 1.57079633) * camS
	End If
	camY:+(KeyDown(KEY_LSHIFT) - KeyDown(KEY_SPACE)) * camS
	camW:+(KeyDown(KEY_E) - KeyDown(KEY_Q)) * camS
	
	
	If MDown & %100
		camT:-MYS * 0.01'(KeyDown(KEY_UP) - KeyDown(KEY_DOWN)) * 0.01
		camP:+MXS * 0.01'(KeyDown(KEY_RIGHT) - KeyDown(KEY_LEFT)) * 0.01
	End If
	
	cx:+(KeyDown(KEY_R) - KeyDown(KEY_F)) * camS
	cy:+(KeyDown(KEY_T) - KeyDown(KEY_G)) * camS
	cz:+(KeyDown(KEY_Z) - KeyDown(KEY_H)) * camS
	cw:+(KeyDown(KEY_U) - KeyDown(KEY_J)) * camS
	
	If KeyHit(KEY_ENTER) disphelp = 1 - disphelp
	
	
	If KeyHit(KEY_DOWN)
		If KeyDown(KEY_RCONTROL)
			TAnimFrame.AddFrame(cflink, 1)
			Print "frame modified"
		Else
			cf = TAnimFrame.AddFrame(cflink) Print "frame added"
			If cflink = Null Then cflink = TAnimFrame.list.FindLink(cf) Else cflink = cflink.NextLink()
		End If
	End If
	
	If KeyHit(KEY_RIGHT)
		If KeyDown(KEY_RCONTROL)
			cflink = TAnimFrame.list.LastLink()
			cf = TAnimFrame(TAnimFrame.list.Last())
			If cf Then cf.setGlobalsToFrame()
		Else If cflink.NextLink()
			cflink = cflink.NextLink()
			cf = TAnimFrame(TAnimFrame(cflink.Value()))
			If cf Then cf.setGlobalsToFrame()
		End If
	End If
	
	If KeyHit(KEY_LEFT)
		If KeyDown(KEY_RCONTROL)
			cflink = TAnimFrame.list.FirstLink()
			cf = TAnimFrame(TAnimFrame.list.First())
			If cf Then cf.setGlobalsToFrame()
		Else If cflink.PrevLink()
			cflink = cflink.PrevLink()
			cf = TAnimFrame(TAnimFrame(cflink.Value()))
			If cf Then cf.setGlobalsToFrame()
		End If
	End If
	
	If KeyHit(KEY_BACKSPACE) And cf
		cflink = cflink.PrevLink()
		cf.list.Remove(cf)
		If cf Then cf = TAnimFrame(cflink.Value())
		Print "frame deleted"
	End If
	
	If cf
		Local timevar:TFloat = TFloat(cf.getVar("time"))
		If KeyDown(KEY_PAGEUP) Then timevar.v:*1.1 Print timevar.v Else ..
		If KeyDown(KEY_PAGEDOWN) Then timevar.v:/1.1 Print timevar.v
	End If
	
	If KeyHit(KEY_RSHIFT) And cf Then cf.setGlobalsToFrame()
	
	If KeyHit(KEY_UP) Then TAnimFrame.PlayAnim(0.04)
	
	If KeyHit(KEY_F10) Then TAnimFrame.SaveToFile("anim" + MilliSecs() + ".txt")
	
	If KeyHit(KEY_F11)
		If KeyDown(KEY_RCONTROL)
			TAnimFrame.SaveAnim(0.02, "anim" + MilliSecs(), Input("Skip Nr Frames:").ToInt())
		Else
			TAnimFrame.SaveAnim(0.02, "anim" + MilliSecs())
		End If
	End If
	
	If KeyHit(KEY_F12)
		If KeyDown(KEY_RCONTROL)
			SaveSceenshot(Input("resolution multiplier:").ToInt())
		Else
			SaveSceenshot(6)
		End If
	End If
End Function

Function Render(x:Int = 0, y:Int = 0, s:Int = 1)
	glUniform4f(glGetUniformLocation(ProgramObj, "cpos"), camX, camY, camZ, camW)
	glUniform2f(glGetUniformLocation(ProgramObj, "crot"), camP, camT)
	glUniform3f(glGetUniformLocation(ProgramObj, "light"), lightX, lightY, lightZ)
	glUniform4f(glGetUniformLocation(ProgramObj, "c"), cx, cy, cz, cw)
	glUniform1i(glGetUniformLocation(ProgramObj, "itr"), itr)
	glUniform1f(glGetUniformLocation(ProgramObj, "eps"), eps)
	
	
	Local w:Float = 2.0 * camZoom / Float(s), h:Float = GH / Float(GW)
	Local vx:Float = x * w - camZoom, vy:Float = -camZoom * h
	h = w * h
	vy = vy + y * h
	
	glBegin(GL_QUADS)
		glTexCoord2f(vx, vy) ;glVertex2i(0, 0)
		glTexCoord2f(vx + w, vy) ;glVertex2i(GW, 0)
		glTexCoord2f(vx + w, vy + h) ;glVertex2i(GW, GH)
		glTexCoord2f(vx, vy + h) ;glVertex2i(0, GH)
	glEnd
End Function

Function InitGL()
	Graphics GW, GH', 32, 60, 0
	SetGraphicsDriver(GLGraphicsDriver())
	glewInit()
	
	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	
	glOrtho(0, GW, GH, 0, -1, 1)
	
	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()
End Function

Function glCls()
	glClear GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
End Function

Function InitShaders()
	ProgramObj = glCreateProgram()
	Local VertexShdr:Int = glCreateShader(GL_VERTEX_SHADER_ARB)
	Local FragmentShdr:Int = glCreateShader(GL_FRAGMENT_SHADER_ARB)
	
	Local vsc:Byte Ptr = VERTEX_SHADER_CODE.ToCString()
	Local vsl:Int = VERTEX_SHADER_CODE.Length
	Local fsc:Byte Ptr = FRAGMENT_SHADER_CODE.ToCString()
	Local fsl:Int = FRAGMENT_SHADER_CODE.Length
	
	glShaderSource(VertexShdr, 1, Varptr vsc, Varptr vsl)
		glShaderSource(FragmentShdr, 1, Varptr fsc, Varptr fsl)
	
		MemFree(vsc)
	MemFree(fsc)
	
	glCompileShader(VertexShdr) ;CheckForErrors(VertexShdr)
	glCompileShader(FragmentShdr) ;CheckForErrors(FragmentShdr)
	
	glAttachShader(ProgramObj, VertexShdr)
	glAttachShader(ProgramObj, FragmentShdr)
	
	glDeleteShader(VertexShdr)
	glDeleteShader(FragmentShdr)
	
	glLinkProgram(ProgramObj) ;CheckForErrors(ProgramObj)
End Function

Function CheckForErrors(ShaderObject:Int)
	Local ErrorLength:Int
	
	glGetShaderiv(ShaderObject, GL_OBJECT_INFO_LOG_LENGTH_ARB, Varptr ErrorLength)
	
		If ErrorLength
		Local Message:Byte[ErrorLength], Dummy:Int
		
		glGetShaderInfoLog(ShaderObject, ErrorLength, Varptr Dummy, Varptr Message[0])
		'		SaveText("Shader object '" + ShaderObject + "':~n" + StringFromCharArray(Message), "error.txt")
		WriteStdout "Shader object '" + ShaderObject + "':~n" + StringFromCharArray(Message)
		WriteStdout "~n"
	EndIf
End Function

Function StringFromCharArray:String(Array:Byte[])
	Local Output:String
	For Local I:Int = 0 To Array.Length - 1
		Output:+Chr(Array[I])
	Next
	
	Return Output
End Function


Function SaveSceenshot(s:Int = 3, fn:String = "", compression:Int = 5, infosdtout:Int = 1)
	Local cnt:Int
	Local pm:TPixmap = CreatePixmap(GW * s, GH * s, PF_BGRA8888)
	Local c:Byte Ptr = MemAlloc(3 * (GW + GW Mod 4) * (GH + GH Mod 4))
	
	For Local x1:Int = 0 Until s
		If infosdtout WriteStdout (x1 + 1) + " of " + s + "~n"
		For Local y1:Int = 0 Until s
			Render(x1, y1, s)
			glReadPixels(0, 0, (GW + GW Mod 4), (GH + GH Mod 4), GL_RGB, GL_UNSIGNED_BYTE, c)
			cnt = 0
			For Local y:Int = GH - 1 To 0 Step - 1
				For Local x:Int = 0 Until GW
					WritePixel(pm, x1 * GW + x, y1 * GH + y, $ff000000 + $10000 * c[cnt] + $100 * c[cnt + 1] + c[cnt + 2])
					cnt:+3
				Next
				cnt:+3 * (GW Mod 4)
			Next
		Next
	Next
	
	If infosdtout WriteStdout "Saving..."
	If fn = "" Then fn = (MilliSecs()) + ".png"
	SavePixmapPNG(pm, fn, compression)
	If infosdtout WriteStdout "Done.~n~n"
End Function

Function DrawHelp()
	GLDrawText "cam =" + camX + ", " + camY + ", " + camZ, 0, 0
	GLDrawText "c   =" + cx + ", " + cy + ", " + cz, 0, 16
	GLDrawText "itr =" + itr, 0, 32
	GLDrawText "eps =" + eps, 0, 48
End Function

Function Catmul:Float(v0:Float, v1:Float, v2:Float, v3:Float, x:Float)
	Local a0:Float, a1:Float, a2:Float, a3:Float, x2:Float
	
	x2 = x * x
'	a0 = -0.5 * v0 + 1.5 * v1 - 1.5 * v2 + 0.5 * v3
'	a1 = v0 - 2.5 * v1 + 2 * v2 - 0.5 * v3
'	a2 = -0.5 * v0 + 0.5 * v2
'	a3 = v1
	a0 = v3 - v2 - v0 + v1
	a1 = v0 - v1 - a0
	a2 = v2 - v0
	a3 = v1
	
	Return a0 * x * x2 + a1 * x2 + a2 * x + a3
End Function

Function Clip:Float(v1:Float, v2:Float, x:Float)
	Return x * v2 + v1 * (1.0 - x)
End Function

Type TAnimFrame
	Global list:TList = CreateList()
	
	Field varlist:TList
	
	Method New()
		varlist = CreateList()
	End Method
	
	Method Del()
		list.Remove(Self)
	End Method
	
	Function AddFrame:TAnimFrame(link:TLink = Null, modify:Int = 0)
		Local t:TAnimFrame
		If modify
			If link = Null
				t = New TAnimFrame
				t.list.AddLast(t)
			Else
				t = TAnimFrame(link.Value())
			End If
		Else
			t = New TAnimFrame
			If link = Null
				t.list.AddLast(t)
			Else
				t.list.InsertAfterLink(t, link)
			End If
		End If
		
		Local timevar:Object = t.getVar("time")
		If timevar = Null
			t.setVar("time", TFloat.N(1.0))
		Else
			t.setVar("time", TFloat(timevar))
		End If
		
		t.setVar("camX", TFloat.N(camX))
		t.setVar("camY", TFloat.N(camY))
		t.setVar("camZ", TFloat.N(camZ))
		t.setVar("camP", TFloat.N(camP))
		t.setVar("camT", TFloat.N(camT))
		
		t.setVar("camZoom", TFloat.N(camZoom))
		
		t.setVar("lightX", TFloat.N(lightX))
		t.setVar("lightY", TFloat.N(lightY))
		t.setVar("lightZ", TFloat.N(lightZ))
		
		t.setVar("eps", TFloat.N(eps))
		
		t.setVar("itr", TInt.N(itr))
		
		t.setVar("cx", TFloat.N(cx))
		t.setVar("cy", TFloat.N(cy))
		t.setVar("cz", TFloat.N(cz))
		Return t
	End Function
	
	Method getVar:Object(name:String)
		For Local t:TAnimFrameVar = EachIn varlist
			If t.name = name
				Return t.v
			End If
		Next
		Return Null
	End Method
	
	Method setVar(name:String, v:Object)
		For Local t:TAnimFrameVar = EachIn varlist
			If t.name = name
				t.v = v
				Return
			End If
		Next
		Local t:TAnimFrameVar = New TAnimFrameVar
		t.name = name
		t.v = v
		varlist.AddLast(t)
		Return
	End Method
	
	Function PlayAnim(speed:Float)
		Local f1:TAnimFrame, f1link:TLink
		Local f2:TAnimFrame, f2link:TLink
		Local time:Float
		Local x:Float = 0
		
		f1 = TAnimFrame(f1.list.First())
		f1link = f1.list.FirstLink()
		If f1link = Null Then Return
		f2link = f1link.NextLink()
		If f2link = Null Then Return
		f2 = TAnimFrame(f2link.Value())
		
		While Not KeyHit(KEY_ESCAPE)
			
			setGlobals(f1, f1link, f2, f2link, x)
			
			Render()
			
			If disphelp DrawHelp()
			
			time = Clip(TFloat(f1.getVar("time")).v,  ..
			TFloat(f2.getVar("time")).v, x)
			
			x:+speed / time
			If x >= 1
				f1link = f2link
				f1 = f2
				f2link = f1link.NextLink()
				If f2link = Null Return
				f2 = TAnimFrame(f2link.Value())
				x = x - 1.0
			End If
			
			Flip 0
			glCls
			WaitTimer TIMER
		Wend
	End Function
	
	Function SaveAnim(speed:Float, folder:String, skip:Int = 0)
		Local framenr:Int = 0
		
		CreateDir(folder)
		
		Local f1:TAnimFrame, f1link:TLink
		Local f2:TAnimFrame, f2link:TLink
		Local time:Float
		Local x:Float = 0
		
		f1 = TAnimFrame(f1.list.First())
		f1link = f1.list.FirstLink()
		If f1link = Null Then Return
		f2link = f1link.NextLink()
		If f2link = Null Then Return
		f2 = TAnimFrame(f2link.Value())
		
		While Not KeyHit(KEY_ESCAPE)
			setGlobals(f1, f1link, f2, f2link, x)
			
			If framenr >= skip
				SaveSceenshot(3, folder + "/" + framenr + ".png", 1, 0)
				Print "Frame Nr. " + framenr
			End If
			
			time = Clip(TFloat(f1.getVar("time")).v,  ..
			TFloat(f2.getVar("time")).v, x)
			
			x:+speed / time
			If x >= 1
				f1link = f2link
				f1 = f2
				f2link = f1link.NextLink()
				If f2link = Null Then End
				f2 = TAnimFrame(f2link.Value())
				x = x - 1.0
			End If
			
			
			framenr:+1
			'Flip 0
			'glCls
			'WaitTimer TIMER
		Wend
	End Function
	
	Function setGlobals(f1:TAnimFrame, f1link:TLink, f2:TAnimFrame, f2link:TLink, x:Float)
		Local f0:TAnimFrame, f3:TAnimFrame
		Local f0link:TLink, f3link:TLink
		
		f0link = f1link.PrevLink()
		f3link = f2link.NextLink()
		
		If f0link = Null Then f0link = f1link
		If f3link = Null Then f3link = f2link
		
		f0 = TAnimFrame(f0link.Value())
		f3 = TAnimFrame(f3link.Value())
		
		
		camX = Catmul(TFloat(f0.getVar("camX")).v,  ..
		TFloat(f1.getVar("camX")).v,  ..
		TFloat(f2.getVar("camX")).v,  ..
		TFloat(f3.getVar("camX")).v, x)
		 
		camY = Catmul(TFloat(f0.getVar("camY")).v,  ..
		TFloat(f1.getVar("camY")).v,  ..
		TFloat(f2.getVar("camY")).v,  ..
		TFloat(f3.getVar("camY")).v, x)
		
		camZ = Catmul(TFloat(f0.getVar("camZ")).v,  ..
		TFloat(f1.getVar("camZ")).v,  ..
		TFloat(f2.getVar("camZ")).v,  ..
		TFloat(f3.getVar("camZ")).v, x)
		
		camP = Catmul(TFloat(f0.getVar("camP")).v,  ..
		TFloat(f1.getVar("camP")).v,  ..
		TFloat(f2.getVar("camP")).v,  ..
		TFloat(f3.getVar("camP")).v, x)
		
		camT = Catmul(TFloat(f0.getVar("camT")).v,  ..
		TFloat(f1.getVar("camT")).v,  ..
		TFloat(f2.getVar("camT")).v,  ..
		TFloat(f3.getVar("camT")).v, x)
		
		camZoom = Catmul(TFloat(f0.getVar("camZoom")).v,  ..
		TFloat(f1.getVar("camZoom")).v,  ..
		TFloat(f2.getVar("camZoom")).v,  ..
		TFloat(f3.getVar("camZoom")).v, x)
		
		
		lightX = Catmul(TFloat(f0.getVar("lightX")).v,  ..
		TFloat(f1.getVar("lightX")).v,  ..
		TFloat(f2.getVar("lightX")).v,  ..
		TFloat(f3.getVar("lightX")).v, x)
		 
		lightY = Catmul(TFloat(f0.getVar("lightY")).v,  ..
		TFloat(f1.getVar("lightY")).v,  ..
		TFloat(f2.getVar("lightY")).v,  ..
		TFloat(f3.getVar("lightY")).v, x)
		
		lightZ = Catmul(TFloat(f0.getVar("lightZ")).v,  ..
		TFloat(f1.getVar("lightZ")).v,  ..
		TFloat(f2.getVar("lightZ")).v,  ..
		TFloat(f3.getVar("lightZ")).v, x)
		
		
		eps = Clip(TFloat(f1.getVar("eps")).v,  ..
		TFloat(f2.getVar("eps")).v, x)
		
		itr = Clip(TInt(f1.getVar("itr")).v,  ..
		TInt(f2.getVar("itr")).v, x)
		
		
		cx = Clip(TFloat(f1.getVar("cx")).v,  ..
		TFloat(f2.getVar("cx")).v, x)
		
		cy = Clip(TFloat(f1.getVar("cy")).v,  ..
		TFloat(f2.getVar("cy")).v, x)
		
		cz = Clip(TFloat(f1.getVar("cz")).v,  ..
		TFloat(f2.getVar("cz")).v, x)
	End Function
	
	Method setGlobalsToFrame()
		camX = TFloat(getVar("camX")).v
		camY = TFloat(getVar("camY")).v
		camZ = TFloat(getVar("camZ")).v
		camP = TFloat(getVar("camP")).v
		camT = TFloat(getVar("camT")).v
		camZoom = TFloat(getVar("camZoom")).v
		
		lightX = TFloat(getVar("lightX")).v
		lightY = TFloat(getVar("lightY")).v
		lightZ = TFloat(getVar("lightZ")).v
		
		eps = TFloat(getVar("eps")).v
		itr = TInt(getVar("itr")).v
		
		cx = TFloat(getVar("cx")).v
		cy = TFloat(getVar("cy")).v
		cz = TFloat(getVar("cz")).v
	End Method
	
	Function SaveToFile(filename:String)
		Local f:TStream = WriteFile(filename)
		For Local t:TAnimFrame = EachIn TAnimFrame.list
			f.WriteLine "{"
			For Local v:TAnimFrameVar = EachIn t.varlist
				If TFloat(v.v) <> Null
					f.WriteLine "~t" + v.name + " = " + TFloat(v.v).v + "f;"
				Else If TInt(v.v) <> Null
					f.WriteLine "~t" + v.name + " = " + TInt(v.v).v + "i;"
				Else If TDouble(v.v) <> Null
					f.WriteLine "~t" + v.name + " = " + TDouble(v.v).v + "d;"
				End If
			Next
			f.WriteLine "}"
		Next
		f.Close
	End Function
	
	Function LoadFromFile(file:String)
		If FileType(file) = 1
			file = LoadText(file)
			file = Replace(file, " ", "")
			file = Replace(file, Chr(9), "")
			file = Replace(file, Chr(10), "")
			file = Replace(file, Chr(13), "")
			
			Local gs:Int = 1, ge:Int = 0, content:String
			
			While ge < Len(file)
				gs = Instr(file, "{", ge)
				ge = Instr(file, "}", gs + 1)
				content = Mid(file, gs + 1, ge - gs - 1)
				
				Local cs:Int = 1, ce:Int = 0, eq:Int
				Local name:String, value:String, dt:String
				
				Local t:TAnimFrame = New TAnimFrame
				t.list.AddLast(t)
				
				While ce < Len(content)
					ce = Instr(content, ";", cs)
					value = Mid(content, cs, ce - cs)
					eq = Instr(value, "=")
					
					name = Left(value, eq - 1)
					dt = Right(value, 1)
					value = Mid(Left(value, value.Length - 1), eq + 1)
					
					Select dt
						Case "f"
							t.setVar(name, TFloat.N(value.ToFloat()))
						Case "i"
							t.setVar(name, TInt.N(value.ToInt()))
						Case "d"
							t.setVar(name, TDouble.N(value.ToDouble()))
					End Select
					
					cs = ce + 1
				Wend
				
			Wend
		Else
			RuntimeError("File does not exist!")
		End If
	End Function
	
End Type

Type TAnimFrameVar
	Field name:String
	Field v:Object
End Type

Type TInt
	Field v:Int
	Function N:TInt(v:Int)
		Local t:TInt = New TInt
		t.v = v
		Return t
	End Function
End Type

Type TFloat
	Field v:Float
	Function N:TFloat(v:Float)
		Local t:TFloat = New TFloat
		t.v = v
		Return t
	End Function
End Type

Type TDouble
	Field v:Double
	Function N:TDouble(v:Double)
		Local t:TDouble = New TDouble
		t.v = v
		Return t
	End Function
End Type
