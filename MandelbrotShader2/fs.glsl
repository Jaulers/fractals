#version 130

#define pi 3.14159265

uniform float pixelsize;
uniform int MaxItr;
uniform int uk;
uniform float threshold;
uniform vec2 v1;
uniform vec2 v2;
uniform vec2 v3;
uniform vec2 p1;
uniform vec2 p2;
uniform vec2 p3;
uniform vec2 p4;
uniform float orbittrapradius1;
uniform float orbittrapradius2;
uniform int aa;


#define etc  gradient(mod(c3,.5)*2.0,vec3[](vec3(0.0,0.0,0.0),vec3(0.0,0.0,1.0),vec3(1.0,1.0,0.7),vec3(1.0,0.6,0.0),vec3(0.0,0.0,0.0)))//mix(vec3(0.0), vec3(1.0,1.0,1.0), c3)//*mix(vec3(1.0,0.8,0.0),vec3(0.0,0.5,1.0),c.y*10.0+0.5)//
#define ot1c vec3(0.0)//gradient(c1,vec3[](vec3(0.0,0.0,0.0),vec3(0.0,0.0,1.0),vec3(1.0,0.5,0.3)))//
#define ot2c vec3(0.0)//gradient(c2,vec3[](vec3(0.0,0.0,0.0),vec3(0.4,0.0,0.0),vec3(0.8,0.0,0.0),vec3(1.0,0.8,0.0),vec3(1.0,1.0,1.0)))//

vec3 gradient(float x, vec3 colors[2]){
	x=x*1.0;
	int i=int(x);
	x=clamp(x-floor(x),0.0,1.0);
	return mix(colors[i],colors[i+1],x);
}
vec3 gradient(float x, vec3 colors[3]){
	x=x*2.0;
	int i=int(x);
	x=clamp(x-floor(x),0.0,1.0);
	return mix(colors[i],colors[i+1],x);
}
vec3 gradient(float x, vec3 colors[4]){
	x=x*3.0;
	int i=int(x);
	x=clamp(x-floor(x),0.0,1.0);
	return mix(colors[i],colors[i+1],x);
}
vec3 gradient(float x, vec3 colors[5]){
	x=x*4.0;
	int i=int(x);
	x=clamp(x-floor(x),0.0,1.0);
	return mix(colors[i],colors[i+1],x);
}

float atan2(vec2 xy){
	if(xy.x>0.0){
		return atan(xy.y/xy.x);
	}else if((xy.x<0.0)&&(xy.y>=0.0)){
		return atan(xy.y/xy.x)+pi;
	}else if((xy.x<0.0)&&(xy.y<0.0)){
		return atan(xy.y/xy.x)-pi;
	}else if((xy.x==0.0)&&(xy.y>0.0)){
		return pi/2.0;
	}else if((xy.x==0.0)&&(xy.y<0.0)){
		return -pi/2.0;
	}else{
		return 0.0;
	}
}
vec2 cpow(vec2 b, vec2 e){
	float ab = atan2(b)+2.0*pi*float(uk);
	float lgb = log(b.x*b.x+b.y*b.y)/2.0;
	float lr = exp(lgb*e.x-ab*e.y);
	float cis = lgb*e.y+ab*e.x;
	return vec2(cos(cis)*lr, sin(cis)*lr);
}
vec2 cexp(vec2 x){
	return vec2(cos(x.y),sin(x.y))*exp(x.x);
}
vec2 clog(vec2 x){
	return vec2(log(x.x*x.x+x.y*x.y)/2.0,atan2(x)+2.0*pi*float(uk));
}
vec2 ccos(vec2 x){
	return vec2(cos(x.x) * cosh(x.y), -sin(x.x) * sinh(x.y));
}
vec2 csin(vec2 x){
	return vec2(sin(x.x) * cosh(x.y), -cos(x.x) * sinh(x.y));
}
vec2 cmul(vec2 a, vec2 b){
	return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}
vec2 cdiv(vec2 a, vec2 b){
	return vec2((a.x*b.x+a.y*b.y), (a.y*b.x-a.x*b.y))/(b.x*b.x+b.y*b.y);
}

float dtc(vec2 x,vec2 l1, vec2 l2){
	return abs(length(x-l1)-length(l1-l2));
}
float dtl(vec2 x,vec2 l1, vec2 l2){
	if(l1==l2)return length(l1-x);
	vec2 xl1 = x - l1;
    vec2 l2l1 = l2 - l1;
    float h = dot(xl1,l2l1)/dot(l2l1,l2l1);
    return length( xl1 - l2l1*h );
}
float dtls(vec2 x,vec2 l1, vec2 l2){
	if(l1==l2)return length(l1-x);
	vec2 xl1 = x - l1;
    vec2 l2l1 = l2 - l1;
    float h = clamp(dot(xl1,l2l1)/dot(l2l1,l2l1),0.0,1.0);
    return length( xl1 - l2l1*h );
}

vec3 mandelbrot(vec2 c){
	c=vec2(c.x,-c.y);
	vec2 z = c;
	int itr = 0;
	float ot1=20000.0,ot2=20000.0,cd;
	while((z.x * z.x + z.y * z.y < threshold) && (itr < MaxItr)){
		z = cpow(z,v1)+v2;//csin(cpow(z,v1))+c;//cdiv(cpow(z,v1)+z,clog(z))+c;//cdiv(cpow(z,v2),cpow(z,v3)+z+v1)+c;//
		
		itr++;
		
		cd=dtl(z,p1,p2);
		if(ot1>cd)ot1=cd;
		cd=dtl(z,p3,p4);
		if(ot2>cd)ot2=cd;
	}
	vec3 color;
	float c1,c2,c3;
	c1=max(0.0,1.0-ot1/orbittrapradius1);
	c2=max(0.0,1.0-ot2/orbittrapradius2);
	c3=float(itr)/float(MaxItr);//(itr - log(log(length(z))) / log(mix(v1.x))) / float(MaxItr);//
	if(itr==MaxItr)c3=0.0;
	color=ot1c;
	color+=ot2c;
	color+=etc;
	
	return color;
}

void main(void){
	vec2 c=vec2(gl_TexCoord[0].x,gl_TexCoord[0].y);
	float moff=pixelsize/4.0;
	vec3 color=vec3(0.0);
	
	//c=(c-v3)/dot(c,c);
	
	if(aa==0){
		color=mandelbrot(c);
	}else{
		color+=mandelbrot(vec2(c.x+moff,c.y+moff));
		color+=mandelbrot(vec2(c.x+moff,c.y-moff));
		color+=mandelbrot(vec2(c.x-moff,c.y+moff));
		color+=mandelbrot(vec2(c.x-moff,c.y-moff));
		color*=0.25;
	}
	
	gl_FragColor = vec4(color,1.0);//vec3(1.0)-
}
