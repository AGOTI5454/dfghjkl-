#version 330 core
#include hg_sdf.glsl
layout (location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;
const float EPSILON = 0.001;

vec2 fOpUnionID(vec2 res1, vec2 res2) {
  return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDifferenceID(vec2 res1, vec2 res2) {
  return (res1.x > -res2.x) ? res1 : vec2(-res2.x, res2.y);
}

vec2 fOpDifferenceColumnsID(vec2 res1, vec2 res2, float r, float n) {
  float dist = fOpDifferenceColumns(res1.x, res2.x, r, n);
  return (res1.x > -res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionStairsID(vec2 res1, vec2 res2, float r, float n) {
  float dist = fOpUnionStairs(res1.x, res2.x, r, n);
  return (res1.x < res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionChamferID(vec2 res1, vec2 res2, float r) {
  float dist = fOpUnionChamfer(res1.x, res2.x, r);
  return (res1.x < res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}


vec2 map(vec3 p) {
  // Plane
  float planeDist = fPlane(p, vec3(0, 1, 0), 2.0);
  float planeID = 2.0;
  vec2 plane = vec2(planeDist, planeID);

  // Sphere
  p.y -= 15.0;
  float sphereDist = fSphere(p, 9.0);
  float sphereID = 1.0;
  vec2 sphere = vec2(sphereDist, sphereID);
  pMirrorOctant(p.xz, vec2(50,50));
  p.x = -abs(p.x) + 20;
  // Manipulation operation
  pMod1(p.z, 15);

  // Roof
  vec3 pr = p;
  
  pr.y -= 15.0;
  pR(pr.xy, 0.6);
  pr.x -= 18.0;
  float roofDist = fBox2(pr.xy, vec2(22, 0.3));
  float roofID = 4.0;
  vec2 roof = vec2(roofDist, roofID);

  // Box
  float boxDist = fBox(p, vec3(3, 9, 4));
  float boxID = 3.0;
  vec2 box = vec2(boxDist, boxID);

  // Cylinder
  vec3 pc = p;
  pc.y -= 9.0;
  float cylinderDist = fCylinder(pc.yxz, 4, 3);
  float cylinderID = 3.0;
  vec2 cylinder = vec2(cylinderDist, cylinderID);

  // wall
  float wallDist = fBox2(p.xy, vec2(1, 15));
  float wallID = 3.0;
  vec2 wall = vec2(wallDist, wallID);

  vec2 res;
  res = wall;
  res = fOpUnionID(box, cylinder);
  res = fOpDifferenceColumnsID(wall, res, 0.1, 0.1);
  res = fOpUnionChamferID(res, roof, 0.9);
  res = fOpUnionStairsID(res, plane, 4.0, 5.0);
  res = fOpUnionID(res, sphere);
  return res;
}

vec2 rayMarch(vec3 ro, vec3 rd) {
    float totalDist = 0.0;
    float objectID = -1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + totalDist * rd;
        vec2 hit = map(p);
        totalDist += hit.x;
        objectID = hit.y;
        if (abs(hit.x) < EPSILON || totalDist > MAX_DIST) break;
    }
    return vec2(totalDist, objectID);
}

vec3 getNormal(vec3 p) {
  vec2 e = vec2(EPSILON, 0.0);
  vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
  return normalize(n);
}

vec3 getLight(vec3 p, vec3 rd, vec3 color) {
  vec3 lightPos = vec3(20.0, 40.0, -30.0);
  vec3 L = normalize(lightPos - p);
  vec3 N = getNormal(p);
  vec3 V = -rd;
  vec3 R = reflect(-L, N);

  vec3 specColor = vec3(0.5);
  vec3 specular = specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
  vec3 diffuse = color * clamp(dot(L, N), 0.0, 1.0);
  vec3 ambient = color * 0.05;
  vec3 fresnel = 0.25 * color * pow(1.0 + dot(rd, N), 3.0);

  // Shadows
  float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
  if (d < length(lightPos - p)) return ambient + fresnel;
  return diffuse + ambient + specular + fresnel;
}

vec3 getMaterial(vec3 p, float id) {
  vec3 m;
  switch (int(id)) {
    case 1:
    m = vec3(0.9, 0.9, 0.0); break;
    case 2:
    m = vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)); break;
    case 3:
    m = vec3(0.7, 0.8, 0.9); break;
    case 4:
    vec2 i = step(fract(0.5 * p.xz), vec2( 1.0 / 10.0));
    m = ((1.0 - i.x) * ( 1.0 - i.y)) * vec3(0.37, 0.12, 0.0); break;
  }

  return m;
}

mat3 getCam(vec3 ro, vec3 lookAt) {
  vec3 camF = normalize(vec3(lookAt - ro));
  vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
  vec3 camU = cross(camF, camR);
  return mat3(camR, camU, camF);
}

void mouseControl(inout vec3 ro) {
  vec2 m = u_mouse / u_resolution;
  pR(ro.yz, m.y * PI * 0.5 - 0.5);
  pR(ro.xz, m.x * TAU);

}

void render(inout vec3 col, in vec2 uv) {
    vec3 ro = vec3(20.0, 20.0, -20.0);
    mouseControl(ro);
    vec3 lookAt = vec3(0, 15.0, 0);
    vec3 rd = getCam(ro, lookAt) * normalize(vec3(uv, FOV));

    vec2 object = rayMarch(ro, rd);

    vec3 background = vec3(0.5, 0.8, 0.9);
    if (object.x < MAX_DIST) {
      vec3 p = ro + object.x * rd;
      vec3 material = getMaterial(p, object.y);
      col += getLight(p, rd, material);

      // Fog
                                // 1.0 for more fog
      col = mix(col, background, 0.5 - exp(-0.0008 * object.x * object.x));
    } else {
      col += background - max(0.95 * rd.y, 0.0);
    }
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;

    vec3 col = vec3(0.0);  // Initialize col to zero
    render(col, uv);

    // Gamma correction
    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}