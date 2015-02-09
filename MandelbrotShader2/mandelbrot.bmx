SuperStrict
Framework brl.GLGraphics
Import brl.TIMER
Import brl.TextStream
Import pub.OpenGL
Import pub.Glew
Import brl.Retro
Import brl.PNGLoader

Const GW:Int = 1120, GH:Int = 630
Const aspectratio:Float = 16.0 / 9.0

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

Global camS:Float = 0.02
Global camX:Float = 0.0, camY:Float = 0.0
Global camZoom:Float = 4.0

Global itr:Int = 50
Global uk:Int = 0
Global threshold:Float = 4.0

Global v1x:Float = 1.0, v1y:Float = 0.0
Global v2x:Float = 1.0, v2y:Float = 0.0
Global v3x:Float = 1.0, v3y:Float = 0.0

Global p1x:Float = -1.0, p1y:Float = 0.0
Global p2x:Float = 1.0, p2y:Float = 0.0

Global p3x:Float = 0.0, p3y:Float = -1.0
Global p4x:Float = 0.0, p4y:Float = 1.0

Global orbittrapradius1:Float = 0.25
Global orbittrapradius2:Float = 0.25
Global aa:Int = 0

Global disphelp:Int = 0

Global cf:TAnimFrame, cflink:TLink

'Render()
'SaveSceenshot()
'End

Global MDown:Int, MX:Int, MY:Int
Global zwsp:Float
While Not KeyHit(KEY_ESCAPE)
	MDown = MouseDown(MOUSE_LEFT) Shl 2 + MouseDown(MOUSE_MIDDLE) Shl 1 + MouseDown(MOUSE_RIGHT)
	MX = MouseX()
	MY = MouseY()
	
	CheckInput()
	
	Render()
	
	If disphelp
		glUseProgram(0)
		DrawHelp
		glUseProgram(ProgramObj)
	End If
	
	Flip 0
	glCls
	WaitTimer TIMER
Wend
End

Function CheckInput()
	If KeyDown(KEY_2) camS:*1.05 Else If KeyDown(KEY_1) camS:/1.05
	
	itr:+KeyDown(KEY_4) - KeyDown(KEY_3)
	uk:+KeyHit(KEY_V) - KeyHit(KEY_C)
	
	If KeyDown(KEY_Y) camZoom:*(1.01) Else If KeyDown(KEY_X) camZoom:/(1.01)
	
	If KeyDown(KEY_6) threshold:*(1.05) Else If KeyDown(KEY_5) threshold:/(1.05)
	
	If KeyDown(KEY_8) orbittrapradius1:*(1.05) Else If KeyDown(KEY_7) orbittrapradius1:/(1.05)
	If KeyDown(KEY_0) orbittrapradius2:*(1.05) Else If KeyDown(KEY_9) orbittrapradius2:/(1.05)
	
	If KeyHit(KEY_B) Then aa = 1 - aa
	
	camX:+(KeyDown(KEY_D) - KeyDown(KEY_A)) * camS
	camY:+(KeyDown(KEY_W) - KeyDown(KEY_S)) * camS
	
	v1x:+(KeyDown(KEY_R) - KeyDown(KEY_F)) * camS
	v1y:+(KeyDown(KEY_T) - KeyDown(KEY_G)) * camS
	v2x:+(KeyDown(KEY_Z) - KeyDown(KEY_H)) * camS
	v2y:+(KeyDown(KEY_U) - KeyDown(KEY_J)) * camS
	v3x:+(KeyDown(KEY_I) - KeyDown(KEY_K)) * camS
	v3y:+(KeyDown(KEY_O) - KeyDown(KEY_L)) * camS
	
	If MDown & %100
		If KeyDown(KEY_LCONTROL)
			p3x = camX + camZoom * MX / Float(GW) - camZoom / 2.0
			p3y = camY - camZoom / aspectratio * MY / Float(GH) + camZoom / aspectratio / 2.0
		Else
			p1x = camX + camZoom * MX / Float(GW) - camZoom / 2.0
			p1y = camY - camZoom / aspectratio * MY / Float(GH) + camZoom / aspectratio / 2.0
		End If
	End If
	If MDown & %001
		If KeyDown(KEY_LCONTROL)
			p4x = camX + camZoom * MX / Float(GW) - camZoom / 2.0
			p4y = camY - camZoom / aspectratio * MY / Float(GH) + camZoom / aspectratio / 2.0
		Else
			p2x = camX + camZoom * MX / Float(GW) - camZoom / 2.0
			p2y = camY - camZoom / aspectratio * MY / Float(GH) + camZoom / aspectratio / 2.0
		End If
	End If
	
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
			SaveSceenshot(4)
		End If
	End If
End Function

Function Render(x:Int = 0, y:Int = 0, s:Int = 1)
	glUniform1f(glGetUniformLocation(ProgramObj, "pixelsize"), (camZoom / Float(s)) / Float(GW))
	glUniform1i(glGetUniformLocation(ProgramObj, "MaxItr"), itr)
	glUniform1i(glGetUniformLocation(ProgramObj, "uk"), uk)
	glUniform1f(glGetUniformLocation(ProgramObj, "threshold"), threshold * threshold)
	glUniform2f(glGetUniformLocation(ProgramObj, "v1"), v1x, v1y)
	glUniform2f(glGetUniformLocation(ProgramObj, "v2"), v2x, v2y)
	glUniform2f(glGetUniformLocation(ProgramObj, "v3"), v3x, v3y)
	glUniform2f(glGetUniformLocation(ProgramObj, "p1"), p1x, p1y)
	glUniform2f(glGetUniformLocation(ProgramObj, "p2"), p2x, p2y)
	glUniform2f(glGetUniformLocation(ProgramObj, "p3"), p3x, p3y)
	glUniform2f(glGetUniformLocation(ProgramObj, "p4"), p4x, p4y)
	glUniform1f(glGetUniformLocation(ProgramObj, "orbittrapradius1"), orbittrapradius1)
	glUniform1f(glGetUniformLocation(ProgramObj, "orbittrapradius2"), orbittrapradius2)
	glUniform1i(glGetUniformLocation(ProgramObj, "aa"), aa)
	
	Local vx:Float, vy:Float
	Local w:Float, h:Float
	vy = camZoom / 2.0
	
	w = camZoom / Float(s)
	h = camZoom / Float(s) / aspectratio
	
	vx = camX - vy + w * x
	vy = camY + vy / aspectratio - h * y
	
	glBegin(GL_QUADS)
		glTexCoord2f(vx, vy) ;glVertex2i(0, 0)
		glTexCoord2f(vx + w, vy) ;glVertex2i(GW, 0)
		glTexCoord2f(vx + w, vy - h) ;glVertex2i(GW, GH)
		glTexCoord2f(vx, vy - h) ;glVertex2i(0, GH)
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
	GLDrawText "cam =" + camX + ", " + camY, 0, 0
	GLDrawText "v1  =" + v1x + ", " + v1y, 0, 16
	GLDrawText "v2  =" + v2x + ", " + v2y, 0, 32
	GLDrawText "v3  =" + v3x + ", " + v3y, 0, 48
	GLDrawText "p1  =" + p1x + ", " + p1y, 0, 64
	GLDrawText "p2  =" + p2x + ", " + p2y, 0, 80
	GLDrawText "p3  =" + p3x + ", " + p3y, 0, 96
	GLDrawText "p4  =" + p4x + ", " + p4y, 0, 112
	GLDrawText "thd =" + threshold, 0, 128
	GLDrawText "otr1=" + orbittrapradius1, 0, 144
	GLDrawText "otr2=" + orbittrapradius2, 0, 160
	GLDrawText "itr =" + itr, 0, 176
	GLDrawText "k   =" + uk, 0, 192
End Function

Function Catmul:Float(v0:Float, v1:Float, v2:Float, v3:Float, x:Float)
	Local a0:Float, a1:Float, a2:Float, a3:Float, x2:Float
	
	x2 = x * x
	a0 = -0.5 * v0 + 1.5 * v1 - 1.5 * v2 + 0.5 * v3
	a1 = v0 - 2.5 * v1 + 2 * v2 - 0.5 * v3
	a2 = -0.5 * v0 + 0.5 * v2
	a3 = v1
'	a0 = v3 - v2 - v0 + v1
'	a1 = v0 - v1 - a0
'	a2 = v2 - v0
'	a3 = v1
	
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
		
		t.setVar("camZoom", TFloat.N(camZoom))
		
		t.setVar("itr", TInt.N(itr))
		
		t.setVar("v1x", TFloat.N(v1x))
		t.setVar("v1y", TFloat.N(v1y))
		t.setVar("v2x", TFloat.N(v2x))
		t.setVar("v2y", TFloat.N(v2y))
		t.setVar("v3x", TFloat.N(v3x))
		t.setVar("v3y", TFloat.N(v3y))
		
		t.setVar("p1x", TFloat.N(p1x))
		t.setVar("p1y", TFloat.N(p1y))
		t.setVar("p2x", TFloat.N(p2x))
		t.setVar("p2y", TFloat.N(p2y))
		t.setVar("p3x", TFloat.N(p3x))
		t.setVar("p3y", TFloat.N(p3y))
		t.setVar("p4x", TFloat.N(p4x))
		t.setVar("p4y", TFloat.N(p4y))
		
		t.setVar("uk", TInt.N(uk))
		
		t.setVar("threshold", TFloat.N(threshold))
		
		t.setVar("orbittrapradius1", TFloat.N(orbittrapradius1))
		t.setVar("orbittrapradius2", TFloat.N(orbittrapradius2))
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
				SaveSceenshot(2, folder + "/" + framenr + ".png", 1, 0)
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
		
		camZoom = Catmul(TFloat(f0.getVar("camZoom")).v,  ..
		TFloat(f1.getVar("camZoom")).v,  ..
		TFloat(f2.getVar("camZoom")).v,  ..
		TFloat(f3.getVar("camZoom")).v, x)
'		camZoom = Clip(TFloat(f1.getVar("camZoom")).v,  ..
'		TFloat(f2.getVar("camZoom")).v, x)
		
		itr = Clip(TInt(f1.getVar("itr")).v,  ..
		TInt(f2.getVar("itr")).v, x)
		
		
		v1x = Catmul(TFloat(f0.getVar("v1x")).v,  ..
		TFloat(f1.getVar("v1x")).v,  ..
		TFloat(f2.getVar("v1x")).v,  ..
		TFloat(f3.getVar("v1x")).v, x)
		 
		v1y = Catmul(TFloat(f0.getVar("v1y")).v,  ..
		TFloat(f1.getVar("v1y")).v,  ..
		TFloat(f2.getVar("v1y")).v,  ..
		TFloat(f3.getVar("v1y")).v, x)
		
		v2x = Catmul(TFloat(f0.getVar("v2x")).v,  ..
		TFloat(f1.getVar("v2x")).v,  ..
		TFloat(f2.getVar("v2x")).v,  ..
		TFloat(f3.getVar("v2x")).v, x)
		 
		v2y = Catmul(TFloat(f0.getVar("v2y")).v,  ..
		TFloat(f1.getVar("v2y")).v,  ..
		TFloat(f2.getVar("v2y")).v,  ..
		TFloat(f3.getVar("v2y")).v, x)
		
		v3x = Catmul(TFloat(f0.getVar("v3x")).v,  ..
		TFloat(f1.getVar("v3x")).v,  ..
		TFloat(f2.getVar("v3x")).v,  ..
		TFloat(f3.getVar("v3x")).v, x)
		 
		v3y = Catmul(TFloat(f0.getVar("v3y")).v,  ..
		TFloat(f1.getVar("v3y")).v,  ..
		TFloat(f2.getVar("v3y")).v,  ..
		TFloat(f3.getVar("v3y")).v, x)
		
		
		p1x = Catmul(TFloat(f0.getVar("p1x")).v,  ..
		TFloat(f1.getVar("p1x")).v,  ..
		TFloat(f2.getVar("p1x")).v,  ..
		TFloat(f3.getVar("p1x")).v, x)
		 
		p1y = Catmul(TFloat(f0.getVar("p1y")).v,  ..
		TFloat(f1.getVar("p1y")).v,  ..
		TFloat(f2.getVar("p1y")).v,  ..
		TFloat(f3.getVar("p1y")).v, x)
		
		p2x = Catmul(TFloat(f0.getVar("p2x")).v,  ..
		TFloat(f1.getVar("p2x")).v,  ..
		TFloat(f2.getVar("p2x")).v,  ..
		TFloat(f3.getVar("p2x")).v, x)
		 
		p2y = Catmul(TFloat(f0.getVar("p2y")).v,  ..
		TFloat(f1.getVar("p2y")).v,  ..
		TFloat(f2.getVar("p2y")).v,  ..
		TFloat(f3.getVar("p2y")).v, x)
		
		p3x = Catmul(TFloat(f0.getVar("p3x")).v,  ..
		TFloat(f1.getVar("p3x")).v,  ..
		TFloat(f2.getVar("p3x")).v,  ..
		TFloat(f3.getVar("p3x")).v, x)
		 
		p3y = Catmul(TFloat(f0.getVar("p3y")).v,  ..
		TFloat(f1.getVar("p3y")).v,  ..
		TFloat(f2.getVar("p3y")).v,  ..
		TFloat(f3.getVar("p3y")).v, x)
		
		p4x = Catmul(TFloat(f0.getVar("p4x")).v,  ..
		TFloat(f1.getVar("p4x")).v,  ..
		TFloat(f2.getVar("p4x")).v,  ..
		TFloat(f3.getVar("p4x")).v, x)
		 
		p4y = Catmul(TFloat(f0.getVar("p4y")).v,  ..
		TFloat(f1.getVar("p4y")).v,  ..
		TFloat(f2.getVar("p4y")).v,  ..
		TFloat(f3.getVar("p4y")).v, x)
		
		
		uk = Clip(TInt(f1.getVar("uk")).v,  ..
		TInt(f2.getVar("uk")).v, x)
		
		threshold = Clip(TFloat(f1.getVar("threshold")).v,  ..
		TFloat(f2.getVar("threshold")).v, x)
		
		orbittrapradius1 = Clip(TFloat(f1.getVar("orbittrapradius1")).v,  ..
		TFloat(f2.getVar("orbittrapradius1")).v, x)
		
		orbittrapradius2 = Clip(TFloat(f1.getVar("orbittrapradius2")).v,  ..
		TFloat(f2.getVar("orbittrapradius2")).v, x)
		
	End Function
	
	Method setGlobalsToFrame()
		camX = TFloat(getVar("camX")).v
		 
		camY = TFloat(getVar("camY")).v
		camZoom = TFloat(getVar("camZoom")).v
		
		itr = TInt(getVar("itr")).v
		
		v1x = TFloat(getVar("v1x")).v
		v1y = TFloat(getVar("v1y")).v
		v2x = TFloat(getVar("v2x")).v
		v2y = TFloat(getVar("v2y")).v
		v3x = TFloat(getVar("v3x")).v
		v3y = TFloat(getVar("v3y")).v
		
		p1x = TFloat(getVar("p1x")).v
		p1y = TFloat(getVar("p1y")).v
		p2x = TFloat(getVar("p2x")).v
		p2y = TFloat(getVar("p2y")).v
		p3x = TFloat(getVar("p3x")).v
		p3y = TFloat(getVar("p3y")).v
		p4x = TFloat(getVar("p4x")).v
		p4y = TFloat(getVar("p4y")).v
		
		uk = TInt(getVar("uk")).v
		threshold = TFloat(getVar("threshold")).v
		orbittrapradius1 = TFloat(getVar("orbittrapradius1")).v
		orbittrapradius2 = TFloat(getVar("orbittrapradius2")).v
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
