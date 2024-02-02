#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

const float n = 52.0;

float mandelbrot(vec2 z) {
    
	vec2 c = z;
	
	for(float i = 0.0; i < n; i++) {
	
		if(dot(z,z) > 4.0) 
		    return i;
		    
		z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
	}
	
	return n;
}

void main() {
    
    float x = 2.0 * gl_FragCoord.x / u_resolution.x - 1.5;
    float y = 2.0 * gl_FragCoord.y / u_resolution.y - 1.0;
	
	float intensity = mandelbrot(vec2(x, y)) / n;
	
	vec3 color = 1.0 - vec3(intensity);
	
	gl_FragColor = vec4(color, 1.0);
}