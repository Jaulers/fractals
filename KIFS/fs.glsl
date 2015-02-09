#version 130

#define pi 3.14159265
#define maxitr 150

uniform vec3 cpos;
uniform vec2 crot;
uniform vec3 light;
uniform float eps;

uniform int itr;
uniform float scale;
uniform vec3 offset;
uniform vec3 rotvec;
uniform float rotangel;


mat3 rotmat;

#define background vec3(0.0,0.0,0.0)//vec3(0.04,0.11,0.16)//vec3(0.2,0.0,0.0)//vec3(1.0,1.0,1.0)//
#define glow vec3(1.0,0.6,0.0)//vec3(0.0,0.4,1.0)//vec3(0.7,0.6,0.5)//
#define xot vec3(0.7,1.0,0.0)//vec3(1.0,0.7,0.4)//vec3(0.5,0.6,0.6)//
#define yot vec3(0.0,0.6,1.0)//vec3(1.0,0.7,0.6)//vec3(1.0,0.6,0.0)//
#define zot vec3(1.0,0.3,0.0)//vec3(1.0,0.7,0.0)//vec3(0.8,0.8,1.0)//
#define wot vec3(1.0,0.4,0.0)//vec3(1.0,0.7,0.4)//vec3(0.4,0.7,1.0)//

vec4 ot=vec4(1.0,1.0,1.0,1.0);

float DE(vec3 p){
	//float py=p.y;
	vec3 of=offset*(scale-1.0);
	int i=0;
	while(i<itr){
		p=rotmat*p;
		
		//p=abs(p);
		if (p.x+p.y<0.0) p.xy = -p.yx;
		if (p.x+p.z<0.0) p.xz = -p.zx;
		if (p.y+p.z<0.0) p.yz = -p.zy;
		
		if (p.x-p.y<0.0) p.xy = p.yx;
		if (p.x-p.z<0.0) p.xz = p.zx;
		if (p.y-p.z<0.0) p.yz = p.zy;
		
		p=p*scale-of;
		
		//if(p.z < -0.5 * of.z) p.z+=of.z;//menger
		
		if(i<5)ot=vec4(min(ot.x,abs(p.x)),min(ot.y,abs(p.y)),min(ot.z,abs(p.z)),min(ot.w,dot(p,p)));
		
		i++;
	}
	return abs(length(p)*pow(scale,-float(i)));//min(abs(length(p)*pow(scale,-float(i))),abs(py-2.0));//
}


vec3 getNorm(vec3 p){
	vec3 xdir=vec3(eps/10.0,0.0,0.0);
	vec3 ydir=vec3(0.0,xdir.x,0.0);
	vec3 zdir=vec3(0.0,0.0,xdir.x);
	float d=DE(p);
	return normalize(vec3(d-DE(p-xdir),d-DE(p-ydir),d-DE(p-zdir)));//normalize(vec3(DE(p+xdir)-DE(p-xdir),DE(p+ydir)-DE(p-ydir),DE(p+zdir)-DE(p-zdir)));//
}

vec3 phong(vec3 pt,vec3 N,vec3 color){
	const int specularExponent=16;
	const float specularity=0.45;

	vec3 L=normalize(light-pt);
	vec3 E=normalize(cpos.xyz-pt);
	float NdotL=dot(N,L);
	vec3 R=L-2.0*NdotL*N;
		
	return color*max(NdotL,0)+specularity*pow(max(dot(E,R),0),specularExponent);
}

float shadow(vec3 p){
	float s=1.0,d,td=0,dtl;
	vec3 stp=light-p;
	dtl=length(stp);
	stp=normalize(stp);
	int n;
	for(n=0;n<maxitr&&td<dtl;n++){
		d=DE(vec3(p+stp*td));
		if(d<eps) return 0.0;
		s=min(s,64.0*d/td);
		td+=d;
	}
	return s;
}

float ambientOcclusion(vec3 p, vec3 n, float d){
	int i;
	float ao;
	
	ao+=0.5*(d-DE(d*n+p));
	ao+=0.25*(2.0*d-DE(2.0*d*n+p));
	ao+=0.125*(3.0*d-DE(3.0*d*n+p));
	ao+=0.0625*(4.0*d-DE(4.0*d*n+p));
	
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

mat3  rotationMatrix3(vec3 v, float angle){
	float c = cos(radians(angle));
	float s = sin(radians(angle));
	
	return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}

void main(){
	rotmat=rotationMatrix3(normalize(rotvec),rotangel);
	
	float d,td=0.0;
	int iter=0;
	vec3 stp=normalize(rotate(vec3(gl_TexCoord[0].xy,1.0)));
	vec3 pos=cpos;
	vec3 color;
	float camd=DE(pos);
	d=camd;
	
	
	while(iter<maxitr&&td<100.0){
		if(d<eps){
			//color=vec3(1.0,1.0,1.0);
			color=ot.x+ot.y*yot+ot.z*zot+ot.w*wot;
			//color=vec3(min(color.x,1.0),min(color.y,1.0),min(color.z,1.0));
			
			stp=getNorm(pos-stp*eps);
			
			
			color=phong(pos,stp,color);
			color*=ambientOcclusion(pos,stp,0.02);
			color*=(shadow(pos+stp*eps)*0.4+0.6);
			//color+=(iter/float(maxitr))*glow;
			
			gl_FragColor=vec4(color,1.0);
			return;
		}
		ot=vec4(1.0,1.0,1.0,1.0);
		td+=d;
		pos+=stp*d;
		iter++;
		d=DE(pos);
	}
	
	color=background;
	//color-=2.0*(iter/float(maxitr))*(vec3(1.0)-glow);
	color+=(iter/float(maxitr))*glow;
	gl_FragColor=vec4(color,1.0);
}
