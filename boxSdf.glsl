

precision mediump float;

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

const int MAX_MARCHING_STEPS = 1000;
const float THRESHOLD1 = 2.5;
const float THRESHOLD2 = 0.00000001;

float stepSize = 0.05;

vec3 repeat(vec3 p){
  float s = 3.0;
  p.x = p.x - s*round(p.x/s);
  p.y = p.y - s*round(p.y/s);
  p.z = p.z - s*round(p.z/s);
  return p;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }


float sdSphere(vec3 p,vec3 c,float r) {
  return length(p - c) - r;
}

float scene(vec3 p) {

  // p = repeat(p);
  float sphere = sdSphere(p, vec3(0, 0, 0), 1.5);
  return sphere;
}

vec3 calcNormal(vec3 p) {
    float eps = 0.00001; // Adjust as needed
    
    float dx = (scene(p + vec3(eps, 0, 0)) - scene(p - vec3(eps, 0, 0))) / (2.0 * eps);
    float dy = (scene(p + vec3(0, eps, 0)) - scene(p - vec3(0, eps, 0))) / (2.0 * eps);
    float dz = (scene(p + vec3(0, 0, eps)) - scene(p - vec3(0, 0, eps))) / (2.0 * eps);
    
    return normalize(vec3(dx, dy, dz));
}




vec3 march(vec3 cam, vec3 dir) {
  float totalDistance = 0.0;
  vec3 currentPos = cam;
  vec3 col = vec3(0.0);

  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {

    float dist = scene(currentPos);
    if (dist < THRESHOLD1){
      vec3 normal = calcNormal(currentPos);
      // aply noise to dist in normal direction
      dist += snoise(currentPos +iTime*0.3);
      if (dist < THRESHOLD2) {
        vec3 normal = calcNormal(currentPos);
        vec3 lightDir = normalize(vec3(-1.0, -1.0, -1.0)); 

        float lightIntensity = max(dot(normal, -lightDir), 0.0);
        vec3 ambientLight = vec3(0.2, 0.2, 0.2);
        //specular
        vec3 viewDir = normalize(cam - currentPos);
        vec3 reflectDir = reflect(lightDir, normal);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
        vec3 col = vec3(1.0, 1.0, 1.0) * lightIntensity+ vec3(spec); 
        return col;
      }
      totalDistance += dist;
      currentPos += dir * stepSize;
    }
  }


  return col;
}

float zoomFactor = 1.0;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 backgroundColor = vec3(0.835, 1, 1);
    vec3 col = vec3(1);

    // Define camera position and direction

    vec3 dir = normalize(vec3(uv, 1));

    // Get mouse rotation


    float rotX = iMouse.y / iResolution.y * 8.; // Adjust the sensitivity as needed
    float rotY = iMouse.x / iResolution.x * 8.;
  
    vec3 cam = vec3(0, 0, -4.0);
    mat3 rotationMatrix = mat3(
        cos(rotY), 0, sin(rotY),
        0, 1, 0,
        -sin(rotY), 0, cos(rotY)
    ) * mat3(
        1, 0, 0,
        0, cos(rotX), -sin(rotX),
        0, sin(rotX), cos(rotX)
    );

    cam = rotationMatrix * cam;
    dir = normalize(rotationMatrix * dir);

    col = march(cam, dir);

    fragColor = vec4(col, 1.0); // Output to screen
}