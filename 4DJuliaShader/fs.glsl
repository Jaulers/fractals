#version 130
#define pi 3.14159265

#define maxitr 300

uniform vec4 cpos;
uniform vec2 crot;
uniform vec3 light;
uniform vec4 c;
uniform int itr;
uniform float eps;

float cs=1.0-c.x;

#define background vec3(0.0,0.0,0.0)//vec3(0.04,0.11,0.16)//vec3(1.0,1.0,1.0)//
#define glow vec3(0.7,0.6,0.5)//vec3(1.0,0.6,0.0)//
vec3 xot=vec3(1.0,0.7,0.4)*2.0*cs;//vec3(1.0,0.7,0.0)*2.0*cs;//
vec3 yot=vec3(1.0,0.7,0.6)*2.0*cs;//vec3(0.0,0.6,1.0)*2.0*cs;//
vec3 zot=vec3(1.0,0.7,0.0)*2.0*cs;//vec3(1.0,0.3,0.0)*2.0*cs;//
vec3 wot=vec3(1.0,0.7,0.4)*cs;//vec3(1.0,0.4,0.0)*cs;//

vec4 ot=vec4(1.0,1.0,1.0,1.0);

float DE(vec4 z){
	vec4 z1=vec4(1.0,0.0,0.0,0.0);//vec4(0.0,0.0,0.0,0.0);//
	vec4 c_=c;//z;//
	//z=vec4(0.0);
	float n;
	int iter=0;
	while(iter<itr&&dot(z,z)<16.0){
		z1=2.0*vec4(z.x*z1.x-dot(z.yzw, z1.yzw), z.x*z1.yzw+z1.x*z.yzw+cross(z.yzw, z1.yzw));//+vec4(1.0,0.0,0.0,0.0);//
		z=vec4(z.x*z.x-dot(z.yzw,z.yzw),2.0*z.x*z.yzw)+c_;
		
		if(iter<5)ot=vec4(min(ot.x,abs(z.x)),min(ot.y,abs(z.y)),min(ot.z,abs(z.z)),min(ot.w,dot(z,z)));
		
		iter++;
	}
	n=length(z);
	return 0.5*log(n)*n/length(z1);//0.8*pow(2.0,iter)*(pow(n,pow(2.0,-iter))-1.0)/(n*pow(n,-2.0+pow(2.0,-iter))*length(z1));//n/length(z1);//
}

vec3 getNorm(vec4 p){
	vec4 xdir=vec4(eps/10.0,0.0,0.0,0.0);
	vec4 ydir=vec4(0.0,xdir.x,0.0,0.0);
	vec4 zdir=vec4(0.0,0.0,xdir.x,0.0);
	return normalize(vec3(DE(p+xdir)-DE(p-xdir),DE(p+ydir)-DE(p-ydir),DE(p+zdir)-DE(p-zdir)));
}
/*vec3 getNorm(vec4 z){
	float gradX,gradY,gradZ;
	int i;
	
	vec4 gx1=z-vec4(eps,0,0,0);
	vec4 gx2=z+vec4(eps,0,0,0);
	vec4 gy1=z-vec4(0,eps,0,0);
	vec4 gy2=z+vec4(0,eps,0,0);
	vec4 gz1=z-vec4(0,0,eps,0);
	vec4 gz2=z+vec4(0,0,eps,0);
	
	for(i=0;i<itr;i++){
		gx1=vec4(gx1.x*gx1.x-dot(gx1.yzw,gx1.yzw),2.0*gx1.x*gx1.yzw)+c;
		gx2=vec4(gx2.x*gx2.x-dot(gx2.yzw,gx2.yzw),2.0*gx2.x*gx2.yzw)+c;
		gy1=vec4(gy1.x*gy1.x-dot(gy1.yzw,gy1.yzw),2.0*gy1.x*gy1.yzw)+c;
		gy2=vec4(gy2.x*gy2.x-dot(gy2.yzw,gy2.yzw),2.0*gy2.x*gy2.yzw)+c;
		gz1=vec4(gz1.x*gz1.x-dot(gz1.yzw,gz1.yzw),2.0*gz1.x*gz1.yzw)+c;
		gz2=vec4(gz2.x*gz2.x-dot(gz2.yzw,gz2.yzw),2.0*gz2.x*gz2.yzw)+c;
	}

	gradX=length(gx2)-length(gx1);
	gradY=length(gy2)-length(gy1);
	gradZ=length(gz2)-length(gz1);

	return normalize(vec3(gradX,gradY,gradZ));
}*/

vec3 phong(vec3 pt,vec3 N,vec3 color){
	const int specularExponent=10;
	const float specularity=0.45;

	vec3 L=normalize(light-pt);
	vec3 E=normalize(cpos.xyz-pt);
	float NdotL=dot(N,L);
	vec3 R=L-2.0*NdotL*N;
	
	
	
	return color*max(NdotL,0)+specularity*pow(max(dot(E,R),0),specularExponent);
}

float shadow(vec3 p){
	float s=1.0,d,td=0;
	vec3 stp=normalize(light-p);
	int n;
	for(n=0;n<70&&td<2.0;n++){
		d=DE(vec4(p+stp*td,cpos.w));
		if(d<eps) return 0.0;
		s=min(s,24.0*d/td);
		td+=d;
	}
	return s;
}

float ambientOcclusion(vec3 p, vec3 n){
	int i;
	float d=0.025;
	float ao;
	
	ao+=0.5*(d-DE(vec4(d*n+p,cpos.w)));
	ao+=0.25*(2.0*d-DE(vec4(2.0*d*n+p,cpos.w)));
	ao+=0.125*(3.0*d-DE(vec4(3.0*d*n+p,cpos.w)));
	ao+=0.0625*(4.0*d-DE(vec4(4.0*d*n+p,cpos.w)));
	
	return max(1.0-ao*16.0,0.0);
}

vec3 rotate(vec3 p){
	float c = cos(crot.x);
	float s = sin(crot.x);
	p=p*mat3(c,		0.0,	s,
			 0.0,	1.0,	0.0,
			 -s,	0.0,	c);
	
	vec2 v;
	v.x=c;
	v.y=-s;
	c=cos(crot.y);
	s=sin(crot.y);
	p=p*mat3(c+(1.0-c)*v.x*v.x,	-s*v.y,	(1.0-c)*v.x*v.y,
			s*v.y,				c,		-s*v.x,
			(1.0-c)*v.x*v.y,	s*v.x,	c+(1.0-c)*v.y*v.y);
	return p;
}


void main(){
	float d,td=0.0;
	int iter=0;
	vec3 stp=normalize(rotate(vec3(gl_TexCoord[0].xy,1.0)));
	vec3 pos=cpos.xyz;
	vec3 color;
	d=length(pos);
	
	
	if(d>2.0)pos+=stp*(d-2.0);
	
	while(iter<maxitr&&td<4.0){//while(td<4.0){//
		d=DE(vec4(pos,cpos.w));
		if(d<eps){
			color=(xot*ot.x+ot.y*yot+ot.z*zot+ot.w*wot);
			//color=vec3(min(color.x,1.0),min(color.y,1.0),min(color.z,1.0));
			
			stp=getNorm(vec4(pos,cpos.w));
			color=phong(pos,stp,color);
			color*=ambientOcclusion(pos,stp);
			color*=(shadow(pos+stp*eps)*0.8+0.2);
			color+=(iter/float(maxitr))*glow;
			gl_FragColor=vec4(color,1.0);
			return;
		}
		ot=vec4(1.0,1.0,1.0,1.0);
		td+=d;
		pos+=stp*d;
		iter++;
	}
	
	color=background;
	color+=(iter/float(maxitr))*glow;//*(vec3(1.)-glow*2.);
	gl_FragColor=vec4(color,1.0);
}
