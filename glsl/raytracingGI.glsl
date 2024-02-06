/*
    MIT License
    
    Copyright (c) 2024 MorcilloSanz
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Basic ray tracing and global ilumination in GLSL.
    One bounce only considered for a better performance.
*/

#ifdef GL_ES
precision mediump float;
#endif

// Uniforms
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

// Constants
#define M_PI 3.1415926535897932384626433832795
#define INF 1. / 0.;

#define MAX_SPHERES 4
#define SHADOW_INTENSITY 0.20

// PBR, Ray Tracing and Global Ilumination
struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Material {
    vec3 albedo;
    float metallic;
    float roughness;
    vec3 emission;
};

struct Sphere {
    vec3 origin;
    float radius;
    Material material;
};

struct HitInfo {
    vec3 intersection;
    vec3 normal;
    float dist;
    Material material;
    bool hit;
};

Sphere spheres[MAX_SPHERES];

vec3 evaluate(Ray ray, float lambda) {
    return ray.origin + lambda * ray.direction;
}

HitInfo intersection(Ray ray, Sphere sphere) {
    
    HitInfo hitInfo;
    
    vec3 oc = ray.origin - sphere.origin;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - (sphere.radius * sphere.radius);
    
    float nabla = b * b - 4.0 * a * c;
    
    if (nabla > 0.0) {
        
        float lambda1 = (-b - sqrt(nabla)) / (2.0 * a);
        float lambda2 = (-b + sqrt(nabla)) / (2.0 * a);
        float lambda = min(lambda1, lambda2);
        
        if (lambda > 0.0) {
            hitInfo.intersection = evaluate(ray, lambda);
            hitInfo.normal = normalize(hitInfo.intersection - sphere.origin);
            hitInfo.dist = lambda;
            hitInfo.material = sphere.material;
            hitInfo.hit = true;
            return hitInfo;
        }
    }
    
    hitInfo.hit = false;
    
    return hitInfo;
}

HitInfo getHitInfo(Ray ray) {
    
    HitInfo hitInfo;
    hitInfo.dist = INF;
    
    for(int i = 0; i < MAX_SPHERES; i ++) {
        
        Sphere sphere = spheres[i];
        
        HitInfo currentHitInfo = intersection(ray, sphere);
    
        if(currentHitInfo.hit && currentHitInfo.dist < hitInfo.dist)
            hitInfo = currentHitInfo;
    }
    
    return hitInfo;
}

bool shadow(vec3 point, Sphere sun) {
    
    Ray ray;
    ray.origin = point;
    ray.direction = sun.origin - point;
    
    HitInfo hitInfo = getHitInfo(ray);
    return hitInfo.hit;
}

float distributionGGX(vec3 N, vec3 H, float roughness) {

    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = M_PI * denom * denom;

    return nom / denom;
}

float geometrySchlickGGX(float NdotV, float roughness) {

    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {

    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = geometrySchlickGGX(NdotV, roughness);
    float ggx1 = geometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

vec3 specularCookTorrance(HitInfo hitInfo, vec3 H, vec3 wo, vec3 wi, vec3 F) {
    
    float NDF = distributionGGX(hitInfo.normal, H, hitInfo.material.roughness);   
    float G = geometrySmith(hitInfo.normal, wo, wi, hitInfo.material.roughness);      
    
    vec3 numerator = NDF * G * F; 
    float denominator = 4.0 * dot(hitInfo.normal, wo) * dot(hitInfo.normal, wi) + 0.0001; // + 0.0001 to prevent divide by zero
    vec3 specular = numerator / denominator;
    
    return specular;
}

vec3 computeIndirectLighting(vec3 wo, HitInfo hitInfo, Sphere sunSphere) {
    
    vec3 lo = vec3(0.0);
    
    for(int i = 0; i < MAX_SPHERES; i ++) {
        
        vec3 loPrime = vec3(0.0);
        
        Sphere sphere = spheres[i];
        
        Ray ray;
        ray.origin = hitInfo.intersection;
        ray.direction = hitInfo.intersection - sphere.origin;
        
        vec3 wi = normalize(ray.direction);
        vec3 H = normalize(wi + wo);
        
        HitInfo hitInfo2 = getHitInfo(ray);
        if(hitInfo2.hit) {
            
            // Reflactance
            vec3 F0 = vec3(0.04); 
            F0 = mix(F0, hitInfo.material.albedo, hitInfo.material.metallic);
            vec3 F = fresnelSchlick(max(dot(H, wo), 0.0), F0);
            
            // Diffuse
            vec3 fLambert = hitInfo.material.albedo / M_PI;
    
            // Specular
            vec3 specular = specularCookTorrance(hitInfo, H, wo, wi, F);
            
            // Energy ratios
            vec3 kS = F;
            vec3 kD = vec3(1.0) - kS;
            
            // One bounce
            
                // li is the output lo from the new sphere (sphere_i)
                vec3 li = vec3(0.0);
                vec3 wo2 = wi;
                vec3 wi2 = normalize(sunSphere.origin);
                vec3 H2 = normalize(wi2 + wo2);
                
                // Reflactance
                vec3 F02 = vec3(0.04); 
                F02 = mix(F02, hitInfo2.material.albedo, hitInfo2.material.metallic);
                vec3 F2 = fresnelSchlick(max(dot(H2, wo2), 0.0), F02);
                
                // Diffuse
                vec3 fLambert2 = hitInfo2.material.albedo / M_PI;
                
                // Specular
                vec3 specular2 = specularCookTorrance(hitInfo2, H2, wo2, wi2, F2);
                
                // Energy ratios
                vec3 kS2 = F2;
                vec3 kD2 = vec3(1.0) - kS2;
                
                // Rendering equation
                vec3 li2 = sunSphere.material.emission;
                vec3 fr2 = kD2 * fLambert2 + specular2;
                li = hitInfo2.material.emission + fr2 * li2 * max(dot(wi2, hitInfo2.normal), 0.0);

                // Shadows
                if(shadow(hitInfo2.intersection, sunSphere))
                    li *= (1.0 - SHADOW_INTENSITY);
            
            // end of bounce
            
            // Rendering equation (le is already considered in direct lighting)
            vec3 fr = kD * fLambert + specular;
            loPrime = fr * li * max(dot(wi, hitInfo.normal), 0.0);
            
            // Shadows
            if(shadow(hitInfo.intersection, sunSphere))
                loPrime *= (1.0 - SHADOW_INTENSITY);
        }
        
        // The more roughness, the less global ilumination reflected.
        float energyLoss = hitInfo.material.roughness;
        
        lo += loPrime * (1.0 - energyLoss);
    }
    
    return lo;
}


void initSpheres() {
    
    // Sphere 1
    Material material1;
    material1.albedo = vec3(0.4, 0.3, 1.0);
    material1.metallic = 0.0;
    material1.roughness = 0.5;
    material1.emission = vec3(0.0);
    
    Sphere sphere1;
    sphere1.origin = vec3(0.0, -0.15, -2.5);
    sphere1.radius = 0.45;
    sphere1.material = material1;
    
    // Sphere 2
    Material material2;
    material2.albedo = vec3(1.0, 0.3, 0.4);
    material2.metallic = 0.0;
    material2.roughness = 0.1;
    material2.emission = vec3(0.0);
    
    Sphere sphere2;
    sphere2.origin = vec3(0.55, 0.0, -4.0);
    sphere2.radius = 0.45;
    sphere2.material = material2;
    
    // Sphere 3
    Material material3;
    material3.albedo = vec3(0.3, 1.0, 0.4);
    material3.metallic = 0.0;
    material3.roughness = 1.0;
    material3.emission = vec3(0.0);
    
    Sphere sphere3;
    sphere3.origin = vec3(-0.55, 0.0, -4.0);
    sphere3.radius = 0.45;
    sphere3.material = material3;
    
    // Sphere 4
    Material material4;
    material4.albedo = vec3(0.5);
    material4.metallic = 1.0;
    material4.roughness = 0.1;
    material4.emission = vec3(0.0);
    
    Sphere sphere4;
    sphere4.origin = vec3(0.0, 0.65, -4.5);
    sphere4.radius = 0.25;
    sphere4.material = material4;
    
    // Add spheres
    spheres[0] = sphere1;
    spheres[1] = sphere2;
    spheres[2] = sphere3;
    spheres[3] = sphere4;
}

void main() {
    
    // Init spheres
    initSpheres();
    
    // Cast ray
    float x = 2.0 * gl_FragCoord.x / u_resolution.x - 1.0;
    float y = 2.0 * gl_FragCoord.y / u_resolution.y - 1.0;
    
    Ray ray;
    ray.origin = vec3(x, y, 0.0);
    ray.direction = vec3(0.0, 0.0, -1.0);
    
    // Sun
    float w = 0.085;
    float t = u_time * 10e-3;
    float r = 5.0;
    
    Material sunMaterial;
    sunMaterial.albedo = vec3(1.0);
    sunMaterial.roughness = 0.0;
    sunMaterial.metallic = 0.0;
    sunMaterial.emission = vec3(3.75);
    
    Sphere sunSphere;
    sunSphere.origin = vec3(r * sin(w * t), 0.85, r * cos(w * t));
    sunSphere.radius = 0.25;
    sunSphere.material = sunMaterial;
    
    // Draw spheres
    HitInfo hitInfoSun = intersection(ray, sunSphere);
    HitInfo hitInfo = getHitInfo(ray);
    
    if(hitInfoSun.hit && hitInfoSun.dist < hitInfo.dist)
        hitInfo = hitInfoSun;
    
    // Sky color
    vec3 lo = mix(vec3(0.0, 0.0, 0.0), vec3(0.2, 0.2, 0.2), gl_FragCoord.y / u_resolution.y);
    
    // Compute lighting
    vec3 wo = -normalize(ray.direction);
    vec3 wi = normalize(sunSphere.origin);
    
    vec3 H = normalize(wi + wo);

    if(hitInfo.hit) {
        
        // calculate reflectance at normal incidence; if dia-electric (like plastic) use F0 
        // of 0.04 and if it's a metal, use the albedo color as F0 (metallic workflow)  
        vec3 F0 = vec3(0.04); 
        F0 = mix(F0, hitInfo.material.albedo, hitInfo.material.metallic);
        vec3 F    = fresnelSchlick(max(dot(H, wo), 0.0), F0);
        
        // Diffuse
        vec3 fLambert = hitInfo.material.albedo / M_PI;
        
        // Specular
        vec3 specular = specularCookTorrance(hitInfo, H, wo, wi, F);
        
        // Energy ratios
        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        
        // Direct lighting
        vec3 li = sunSphere.material.emission;
        vec3 fr = kD * fLambert + specular;
        vec3 directLighting = hitInfo.material.emission + fr * li * max(dot(wi, hitInfo.normal), 0.0);
        
        // Indirect lighting
        vec3 indirectLighting = computeIndirectLighting(wo, hitInfo, sunSphere);
        
        // Lighting
        lo = directLighting + indirectLighting;
        
        // Shadows
        if(shadow(hitInfo.intersection, sunSphere)) 
            lo *= (1.0 - SHADOW_INTENSITY);
    }
        
    gl_FragColor = vec4(lo, 1.0);
}