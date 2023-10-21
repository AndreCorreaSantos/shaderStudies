



const int MAX_MARCHING_STEPS = 1000;
const float FOCALDIST = 10000.0f;
const float THRESHOLD = 0.01;
const float MAX_STEP_SIZE = 10.0;
const float MIN_STEP_SIZE = 0.1;

float sdSphere(vec3 p,vec3 c,float r) {
  return length(p - c) - r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}



float stepSize = 0.02;

vec3 repeat(vec3 p){
  float s = 6.0;
  p.x = p.x - s*round(p.x/s);
  p.y = p.y - s*round(p.y/s);
  p.z = p.z - s*round(p.z/s);
  return p;
}

float scene(vec3 p) {

  p = repeat(p);
  // float d = sdRoundBox(p, vec3(0.5, 0.5, 0.5), 0.5);
  float d = sdSphere(p, vec3(0, 0, 0), 1.0);
  return d;
}

vec3 calcNormal(vec3 p) {
    float eps = 0.0001; // Adjust as needed
    
    float dx = (scene(p + vec3(eps, 0, 0)) - scene(p - vec3(eps, 0, 0))) / (2.0 * eps);
    float dy = (scene(p + vec3(0, eps, 0)) - scene(p - vec3(0, eps, 0))) / (2.0 * eps);
    float dz = (scene(p + vec3(0, 0, eps)) - scene(p - vec3(0, 0, eps))) / (2.0 * eps);
    
    return normalize(vec3(dx, dy, dz));
}

vec3 march(vec3 cam, vec3 dir) {
  float totalDistance = 0.0;
  vec3 currentPos = cam;
  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {

    float dist = scene(currentPos);
    if (dist < THRESHOLD) {
      vec3 normal = calcNormal(currentPos);
      vec3 lightDir = normalize(vec3(-1.0, -1.0, -1.0)); 

      float lightIntensity = max(dot(normal, -lightDir), 0.0);
      vec3 ambientLight = vec3(0.2, 0.2, 0.2);
      vec3 col = vec3(1.0, 1.0, 1.0) * lightIntensity + ambientLight; 
      return col;
    }
    totalDistance += dist;
    if (totalDistance > FOCALDIST) {
      return vec3(0.0, 0.0, 0.0);
    }
    currentPos += dir * stepSize;
  }
  return vec3(0.0, 0.0, 0.0);
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

    float zoomDelta = iMouse.z * 0.001; // Adjust as neede
    zoomFactor += zoomDelta;
    vec3 cam = vec3(0, 0, -4.0*zoomFactor);
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
