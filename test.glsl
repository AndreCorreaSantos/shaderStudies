const vec3 color = vec3(.1,.4,.6);

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

//Thanks iq
float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

int mat;

//Main scene functon
float scene(vec3 p) {

   //float box = sdBox(p-vec3(.75,0,0),vec3(.5)) - .5;
   float sphere = sdSphere(p+vec3(0,0,0),2.);
    
   p.y = abs(p.y);
   sphere = opSmoothUnion(sphere,sdSphere(p+vec3(0,-1.5+sin(iTime),0),1.),.5);
    
   p = mod(p,10.) - 5.;
   float box = sdSphere(p,1.5);
    
   float d = min(sphere,box);
    
    if (d == sphere) {
        mat = 0;
    }else{
        mat = 1;
    }
    
   return d;
    
}

//Shadow calculation function
float shadow( in vec3 ro, in vec3 rd, float mint, float maxt )
{
    for( float t=mint; t < maxt; )
    {
        float h = scene(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        t += h;
    }
    return 1.0;
}

//Thanks yx
vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}
void cameraspin(inout vec3 p)
{
    p.yz = rotate(p.yz, -.3);
    p.xz = rotate(p.xz, iTime*.5);
}

const vec3 lDir = vec3(1,1,1);

vec3 trace(vec3 cam, vec3 dir) {
    //Perform raytrace
    float t = 0.;
    float k = 0.;
    vec3 h;
    for(int i=0;i<25;++i) {
        k=scene(cam+dir*t);
        t+=k;
        if(k<.001)
        {
            h = cam+dir*t;
            vec2 o=vec2(.02,0);
            vec3 n= normalize(vec3(
                scene(h+o.xyy)-scene(h-o.xyy),
                scene(h+o.yxy)-scene(h-o.yxy),
                scene(h+o.yyx)-scene(h-o.yyx)
            ));

            //Light comes from camera
            float light = dot(n,normalize(lDir))*.5+.5;
            
            //Add specular reflections
            light += pow(light,64.);
            
            float shad = shadow(h,lDir,0.,1000.);
            
            if (mat == 0) {
                
                //Reflection
                //Change ray origin and direction so that it now points off the suface of the shape
                cam = h;
                dir = reflect(dir,n);
                
                //The distance MUST be greater than the minimum amount, or else it will just 
                t = 0.002;
                
            }else if (mat == 1){ 
                return n*light;
            }
        }
    }
    return vec3(0);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -0.5 to 0.5)
    vec2 uv = fragCoord/iResolution.xy - .5;

    //Multiply by aspect
    uv.x *= iResolution.x / iResolution.y;
    
    //Define camera position and direction
    vec3 cam = vec3(0,0,10);
    vec3 dir = normalize(vec3(uv,-1));
    
    cameraspin(cam);
    cameraspin(dir);
    
    fragColor.rgb = trace(cam,dir);
    
}