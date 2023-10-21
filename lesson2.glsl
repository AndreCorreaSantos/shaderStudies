

void mainImage(out vec4 fragColor, in vec2 fragCoord ){

    vec3 col = vec3(0);

    vec2 uv = fragCoord/iResolution.xy;

    col += smoothstep(0.0,clamp(0.0,1.0,sin(iTime))+0.1,uv.x);

    fragColor = vec4(col,1.0);
}