float mouseOpacity(vec2 uv, vec2 mPos, float radius){
    float distance = length(uv - mPos);
   return smoothstep(radius, 0.0, distance);

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 normalizedMousePos = iMouse.xy / iResolution.xy;
    float radius = 0.1; // Adjust the radius as needed

    fragColor = vec4(uv.x, uv.y, 0.0, mouseOpacity(uv, normalizedMousePos, radius));
}
