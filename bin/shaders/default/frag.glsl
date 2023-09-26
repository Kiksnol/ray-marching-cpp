/**/
#version 430
#define THRESHOLD 0.001
#define INFINITY 1e+30

layout(location = 0) out vec4 OutColor;

in vec2 DrawTexCoord;
uniform vec3 CamRight;
uniform vec3 CamUp;
uniform vec3 CamDir;
uniform vec3 CamLoc;
uniform vec3 iResolution;

uniform float CamSize;
uniform float CamProjDist;
uniform float FrameW;
uniform float FrameH;
uniform float Time;

float CurrentTransparency = 1;

struct ray
{
  vec3 Org;
  vec3 Dir;
};

vec3 RayApply( ray R, float T )
{
  return R.Org + R.Dir * T;
}

struct material
{
  vec3 Ka;  // Ambient
  vec3 Kd;  // Diffuse
  vec3 Ks;  // Specular
  float Ph; // Shininess
};

material MatLib[20] = {material(vec3(0), vec3(0.01), vec3(0.5), 32),                                                                            // Black plastic
                       material(vec3(0.329412,0.223529,0.027451), vec3(0.780392,0.568627,0.113725), vec3(0.992157,0.941176,0.807843), 27.8974), // Brass
                       material(vec3(0.2125,0.1275,0.054), vec3(0.714,0.4284,0.18144), vec3(0.393548,0.271906,0.166721), 25.6),                 // Bronze
                       material(vec3(0.25), vec3(0.4), vec3(0.774597), 76.8),                                                                   // Chrome
                       material(vec3(0.19125,0.0735,0.0225), vec3(0.7038,0.27048,0.0828), vec3(0.256777,0.137622,0.086014), 12.8),              // Copper
                       material(vec3(0.24725,0.1995,0.0745), vec3(0.75164,0.60648,0.22648), vec3(0.628281,0.555802,0.366065), 51.2),            // Gold
                       material(vec3(0.10588,0.058824,0.113725), vec3(0.427451,0.470588,0.541176), vec3(0.3333,0.3333,0.521569), 9.84615),      // Peweter
                       material(vec3(0.19225,0.19225,0.19225), vec3(0.50754,0.50754,0.50754), vec3(0.508273,0.508273,0.508273), 51.2),          // Silver
                       material(vec3(0.23125,0.23125,0.23125), vec3(0.2775,0.2775,0.2775), vec3(0.773911,0.773911,0.773911), 89.6),             // Polished silver
                       material(vec3(0.1, 0.18725, 0.1745), vec3(0.396, 0.74151, 0.69102), vec3(0.297254, 0.30829, 0.306678), 12.8),            // Turquoise
                       material(vec3(0.1745, 0.01175, 0.01175), vec3(0.61424, 0.04136, 0.04136), vec3(0.727811, 0.626959, 0.626959), 76.8),     // Ruby
                       material(vec3(0.24725, 0.2245, 0.0645), vec3(0.34615, 0.3143, 0.0903), vec3(0.797357, 0.723991, 0.208006), 83.2),        // Polished gold
                       material(vec3(0.25, 0.148, 0.06475), vec3(0.4, 0.2368, 0.1036), vec3(0.774597, 0.458561, 0.200621), 76.8),               // Polished bronze
                       material(vec3(0.2295, 0.08825, 0.0275), vec3(0.5508, 0.2118, 0.066), vec3(0.580594, 0.223257, 0.0695701), 51.2),         // Polished copper
                       material(vec3(0.135, 0.2225, 0.1575), vec3(0.135, 0.2225, 0.1575), vec3(0.316228), 12.8),                                // Jade
                       material(vec3(0.05375, 0.05, 0.06625), vec3(0.18275, 0.17, 0.22525), vec3(0.332741, 0.328634, 0.346435), 38.4),          // Obsidian
                       material(vec3(0.25, 0.20725, 0.20725), vec3(1.0, 0.829, 0.829), vec3(0.296648, 0.296648, 0.296648), 11.264),             // Pearl
                       material(vec3(0.0215, 0.1745, 0.0215), vec3(0.07568, 0.61424, 0.07568), vec3(0.633, 0.727811, 0.633), 76.8),             // Emerald
                       material(vec3(0.0745, 0.01175, 0.41175), vec3(0.102, 0.047, 0.30), vec3(0.633, 0.727811, 0.633), 47),                    // Blue
                       material(vec3(0.02), vec3(0.01), vec3(0.4), 10)};                                                                        // Black rubber

struct envi
{
  float RefractionKoef;
  float DecayKoef;
};

envi EnvLib[2] = {envi(0.1, 0.1), // Air environment
                  envi(-1, -1), // Plane environment
                  };

struct intr
{
  float T;          // Intersection time
  vec3 P;           // Position
  vec3 N;           // Normal
  envi Env;         // Shape environment
  material Mtl;     // Material
};

struct sphere
{
  vec3 Center;  // Sphere center point coords
  float R2;     // Squared sphere radius
  material Mtl; // Sphere material
  envi Env;     // Sphere environment
  float Trans;  // Sphere transparency
};

struct plane
{
  vec3 N;
  float D;
  material Mtl;
  envi Env; // Plane environment (Always -1 -1)
};

struct oct_pr
{
  float r;
  float h;
  vec3 Pos;
  material Mtl;
};

struct box
{
  vec3 C, B;
  material Mtl;
  envi Env;
};

struct torus
{
  float Diameter;
  float Thickness;
  vec3 Pos;
  material Mtl;
};

struct triangle
{
  float D;      // Plane coef
  vec3 U1, V1;  // Triangle points
  float u0, v0; // Triangle coeffs
  material Mtl;
  envi Env;
  vec3 N; 
};

struct light_info
{
  vec3 Dir;   // Light source direction
  vec3 Color; // Light color
  float Dist; // Distance between objects
  float Att;  // Attenuation coefficient
};

struct light
{
  float Cl, Cq, Cc;  // Linear, quadratic and constant coeffs
  light_info LI;     // Light info
  float R1, R2, Cr;
  vec3 Pos;          // Light position
};

struct Shape
{
  int shape_type;
  int shape_id;
};

struct ShapeOp
{
    Shape shape;
    int op_type;
    int next;
};

const int shop_nbr = 1;
ShapeOp shops[shop_nbr] = ShapeOp[](ShapeOp(Shape(1,0),0,-1));

const int plane_type = 0;
const int sphere_type = 1;
const int box_type = 2;
const int torus_type = 4;
const int shop_type = 3;

const int shop_root_nbr = 1;
int shop_roots[shop_root_nbr] = int[](0);

struct ISObj
{
  float Dist;
  int Type;
  int RootIndex;
};

triangle MakeTriangle( vec3 P0, vec3 P1, vec3 P2, material Mtl, envi Environment )
{
  triangle Res;
  vec3 M0 = P0, P;

  Res.N = normalize(cross((P1 - P0), P2 - P0));

  Res.D = Res.N.x * M0.x + Res.N.y * M0.y + Res.N.z * M0.z;

  vec3 r = P - P0, s1 = P1 - P0, s2 = P2 - P0;
  float s12 = dot(s1, s1), s22 = dot(s2, s2);

  Res.U1 = ((s1 * s22) - (s2 * dot(s1, s2))) / ((s12 * s22) - dot(s1, s2) * dot(s1, s2));
  Res.u0 = dot(P0, Res.U1);

  Res.V1 = ((s2 * s12) - (s1 * dot(s1, s2))) / ((s12 * s22) - dot(s1, s2) * dot(s1, s2));
  Res.v0 = dot(P0, Res.V1);

  Res.Mtl = Mtl;
  Res.Env = Environment;

  return Res;
}

const int LightsSize = 2;
light Lights[LightsSize] = {light(0.02, 0, 0, light_info(vec3(0), vec3(1, 1, 1), 0, 0), 1, 30, 29, vec3(1, 20, 1)),
                            light(0.02, 0, 0, light_info(vec3(0), vec3(1, 1, 1), 0, 0), 1, 47, 46, vec3(2.97, 10.25, -9.94))}; // + 10 * sin(Time * 10)

light_info Shadow( light Li, vec3 P )
{
  vec3 Dir = normalize(Li.Pos - P);
  float Dist = distance(Li.Pos, P);
  light_info Res;

  Res.Att = 1 / (Li.Cq * Dist * Dist + Li.Cl * Dist + Li.Cc);

  Res.Dir = Dir;
  Res.Color = Li.LI.Color;
  Res.Dist = Dist;
  Res.Att = min(Res.Att, 1);

  return Res;
}

ray FrameRay( float Xs, float Ys )
{
  float Wp = CamSize, Hp = CamSize;

  if (FrameW >= FrameH)
    Wp *= FrameW / FrameH;
  else
    Hp *= FrameH / FrameW;

  vec3 
    A = CamDir * CamProjDist,
    B = CamRight * (Xs - FrameW / 2.0) * Wp / FrameW,
    C = CamUp * (FrameH / 2.0 - Ys) * Hp / FrameH,
    Q = A + B + C;

  ray Res;

  Res.Dir = normalize(Q);
  Res.Org = CamLoc + Q;

  return Res;
}

// Shapes

const int NumOfSph = 4;
sphere Sph[NumOfSph] = {sphere(vec3(10, 4, 0), 10, MatLib[15], envi(0.1, 1), 1),
                 sphere(vec3(-10, 3, 0), 2, MatLib[10], envi(0.1, 2), 1),
                 sphere(vec3(2, 5, -5), 15, MatLib[9], envi(0.1, 2), 1), 
                 sphere(vec3(2, 5, -5), 4, MatLib[17], EnvLib[1], 1)};

const int NumOfPlanes = 1;
plane Planes[NumOfPlanes] = {plane(vec3(0, 1, 0), 3, MatLib[1], EnvLib[1])};

const int NumOfBoxes = 3;
box Boxes[NumOfBoxes] = {box(vec3(-9, 4, 0), vec3(1, 6, 3), MatLib[6], envi(0.1, 0.4)),
                box(vec3(8, 15, -3), vec3(4, 10, 3), MatLib[8], EnvLib[1]),
                box(Sph[2].Center, vec3(sqrt(15) / 2 + 1), MatLib[2], EnvLib[1])};

triangle Tris[1] = {MakeTriangle(vec3(3, 10, 5), vec3(6, 10, 5), vec3(4.5, 15, 8), MatLib[12], envi(0.1, 0.4))};
int NumOfTris = 0;

const int NumOfToruses = 2;
torus Toruses[NumOfToruses] = {torus(3, 0.8, vec3(5, 4, 7), MatLib[14]),
                               torus(3, 1, Sph[0].Center, MatLib[9])};

float SphereTracingRec1( ray R, float MaxDist, float Threshold, inout intr Intr, float Weight = 1.0 );
vec3 ShadeRec1( intr Intr, vec3 Dir, float Weight = 1.0 );

float SphereTracing( ray R, float MaxDist, float Threshold, inout intr Intr );

vec3 Shade( intr Intr, vec3 Dir, float Weight = 1.0 )
{  
  vec3 V = normalize(Intr.P - CamLoc);
  vec3 color = vec3(0), diff = vec3(0), specular = vec3(0);
  light_info Li;

  vec3 R = Dir - Intr.N * (2 * dot(Dir, Intr.N));
  for (int i = 0; i < LightsSize; i++)
  {
    Li = Shadow(Lights[i], Intr.P);
    
    // Shadows 
    ray Sh;
    intr Ish;
    Sh.Org = Intr.P + Li.Dir * 0.1;
    Sh.Dir = Li.Dir;
    
    float ShMarch = SphereTracing(Sh, 100, THRESHOLD, Ish);
    
    if (ShMarch != 0)
      Li.Color *= 0.05;
    
    // Duffuse
    float nl = dot(Intr.N, Li.Dir);
    if (nl > THRESHOLD)
      diff += Li.Color * nl * Li.Att;

    // Specular
    float rl = dot(R, Li.Dir);

    if (rl > THRESHOLD)
      specular += Li.Color * pow(rl, Intr.Mtl.Ph);
  }

  // Reflection
  float wr = Weight * 0.2;
  if (wr > 0.01)
  {
    ray RR;
    RR.Org = Intr.P + R * THRESHOLD;
    RR.Dir = R;
    intr ReflInt;

    if (SphereTracingRec1(RR, 100, THRESHOLD, ReflInt, wr) == 0)
      color +=  vec3(0);
    else
      color += ShadeRec1(ReflInt, RR.Dir, wr) * 0.2;
  }
  
  color += Intr.Mtl.Ka + diff * Intr.Mtl.Kd + specular * Intr.Mtl.Ks;

  return color;
}

vec3 ShadeRec1( intr Intr, vec3 Dir, float Weight = 1.0 )
{  
  vec3 V = normalize(Intr.P - CamLoc);
  vec3 color = vec3(0), diff = vec3(0), specular = vec3(0);
  light_info Li;

  vec3 R = Dir - Intr.N * (2 * dot(Dir, Intr.N));
  for (int i = 0; i < LightsSize; i++)
  {
    Li = Shadow(Lights[i], Intr.P);
    
    // Shadows 
    ray Sh;
    intr Ish;
    Sh.Org = Intr.P + Li.Dir * 0.1;
    Sh.Dir = Li.Dir;
    
    float ShMarch = SphereTracing(Sh, 100, THRESHOLD, Ish);
    
    if (ShMarch != 0)
      Li.Color *= 0.05;
    
    // Duffuse
    float nl = dot(Intr.N, Li.Dir);
    if (nl > THRESHOLD)
      diff += Li.Color * nl * Li.Att;

    // Specular
    float rl = dot(R, Li.Dir);

    if (rl > THRESHOLD)
      specular += Li.Color * pow(rl, Intr.Mtl.Ph);
  }
  
  color += Intr.Mtl.Ka + diff * Intr.Mtl.Kd + specular * Intr.Mtl.Ks;

  return color;
}

// Ray Marching functions

// Operations

mat2 Rotate( float a )
{
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}


float SDF_Subtract( float a, float b )
{
  return max(a, -b);
}

float SDF_Intersect( float a, float b )
{
  return max(a, b);
}

float SDF_SmoothUnion( float a, float b, float k )
{
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1 - h);
}

float SDF_Union( float a, float b )
{
  return min(a, b);
}

// Shapes

float SDF_Sphere( vec3 P, sphere Sph )
{
  return length(Sph.Center - P) - sqrt(Sph.R2);
}

float SDF_Box( vec3 P, box Box )
{
  vec3 d = abs(P - Box.C) - (Box.B);

  return length(max(d, 0)) + min(max(max(d.x, d.y), d.z), 0);
}

float SDF_Torus( vec3 P, torus Tor )
{
  vec3 A = Tor.Pos - P;
  vec2 q = vec2(length(A.xz) - Tor.Diameter, A.y);

  return length(q) - Tor.Thickness;
}

float SDF_DisplaceTorus( vec3 P, torus T )
{
  float d1 = SDF_Torus(P, T);
  float d2 = sin(2 * P.x) * sin(2 * P.y) * sin(P.z) * sin(Time);

  return d1 + d2;
}

float SDF_FireBall( vec3 P, sphere T )
{
  float d1 = SDF_Sphere(P, T);
  float d2 = sin(10 * P.x) * 0.5 * sin(20 * P.y) * sin(15 * P.z) * 0.1;

  return d1 + d2;
}

float SDF_FireBall2( vec3 P, sphere T )
{
  float d1 = SDF_Sphere(P, T);
  float d2 = sin(100 * P.x) * 5 * sin(20 * P.y) * sin(15 * P.z) * (sin(Time) + 0.2);
  
  return d1 + d2;
}

float SDF_Plane( vec3 P, plane Pl )
{
  return Pl.D + dot(Pl.N, P);
}

float getBasicSDF( int type, int id, vec3 P, inout material Mtl )
{
  if(type == plane_type)
  {
    Mtl = Planes[id].Mtl;
    return SDF_Plane(P, Planes[id]);
  }
  else if(type == sphere_type)
  {
    Mtl = Sph[id].Mtl;
    return SDF_Sphere(P, Sph[id]);
  }
  else if(type == box_type)
  {
    Mtl = Boxes[id].Mtl;
    return SDF_Box(P, Boxes[id]);
  }
  else if (type == torus_type)
  {
    Mtl = Toruses[id].Mtl;
    return SDF_Torus(P, Toruses[id]);
  }

  return 0.0;
}

float OpSDF(in float s_sdf, in float e_sdf, int op_t)
{
  if(op_t == 0)
    return SDF_Union(s_sdf,e_sdf);
  else if(op_t == 1)
    return SDF_Subtract(s_sdf,e_sdf);
  else if(op_t == 2)
    return SDF_Intersect(s_sdf,e_sdf);
  else if(op_t == 3)
    return SDF_SmoothUnion(s_sdf,e_sdf,1.0f);

  return 0.0;
}


float ShapeSDF( int sh_op_id, vec3 P, inout material Mtl )
{
  int curr_id = sh_op_id;
  float sdf_f = getBasicSDF(shops[curr_id].shape.shape_type, shops[curr_id].shape.shape_id, P, Mtl);
  int next_id = shops[sh_op_id].next;

  while(next_id != -1)
  {
    float sdf_i = getBasicSDF(shops[next_id].shape.shape_type, shops[next_id].shape.shape_id, P, Mtl);
    sdf_f = OpSDF(sdf_f, sdf_i, shops[curr_id].op_type);
    curr_id = next_id;
    next_id = shops[next_id].next;
  }

  return sdf_f;
}

ISObj SceneSDF( vec3 P, inout material Mtl )
{
  ISObj nearest = ISObj(100,-1,-1);
  for(int j = 0 ; j < shop_root_nbr ;j++)
  {
    float dist = ShapeSDF(shop_roots[j], P, Mtl);
    if(dist < nearest.Dist)
      nearest = ISObj(dist, shop_type, shop_roots[j]);
  }
  return nearest;
}

float getSDF( int type, int id, in vec3 p, inout material Mtl )
{
  if(type != shop_type)
    return getBasicSDF(type, id, p, Mtl);
  else
    return ShapeSDF(id, p, Mtl);
}

float SDF_SmoothDifer(float distA, float distB, float k)
{
  float h = clamp(0.5 - 0.5*(distB+distA)/k, 0., 1.);
  return mix(distA, -distB, h ) + k*h*(1.-h); 
}

float SDF_Scene( vec3 P, inout material Mtl )
{
  vec3 bp = P - vec3(0, 1, 0), cb = bp;
  bp.xz *= Rotate(Time);
  cb.yz *= Rotate(Time * 1);
  
  float cd2,
    d = SDF_Sphere(P, Sph[0]), 
    cd = 0, 
    bbr = SDF_Torus(P, Toruses[1]),
    e = SDF_Plane(P, Planes[0]),
    j = SDF_SmoothUnion(d, bbr, abs(sin(Time * 3))),
    b = SDF_Box(P, Boxes[0]),
    tor2 = SDF_DisplaceTorus(P, Toruses[0]),
    bebra3 = SDF_Subtract(SDF_Box(P, Boxes[2]), SDF_Sphere(P, Sph[2])),
    el = SDF_Sphere(P, Sph[3]);

  cd = SDF_FireBall(P, Sph[1]);
  cd2 = SDF_SmoothDifer(SDF_FireBall2(P, Sph[1]), cd, 0.5);

  float a = min(cd, min(min(e, min(cd2, el)), min(j, min(bebra3, tor2))));

  for (int i = 0; i < NumOfSph; i++)
    if (abs(a - SDF_Sphere(P, Sph[i])) < 0.05)
    {
      Mtl = Sph[i].Mtl;
      return a;
    }

  for (int i = 0; i < NumOfPlanes; i++)
    if (abs(a - SDF_Plane(P, Planes[i])) < 0.05)
    {
      Mtl = Planes[i].Mtl;
      return a;
    }
  
  for (int i = 0; i < NumOfBoxes; i++)
    if (abs(a - SDF_Box(P, Boxes[i])) == 0)
    {
      Mtl = Boxes[i].Mtl;
      return a;
    }

  for (int i = 0; i < NumOfToruses; i++)
    if (abs(a - SDF_Torus(P, Toruses[i])) < 0.1)
    {
      Mtl = Toruses[i].Mtl;
      return a;
    }

  if (abs(a - tor2) < 0.1)
  {
    Mtl = Toruses[0].Mtl;
    return a;
  }
  
  if (abs(a - j) < 0.1)
  {
    Mtl = Sph[0].Mtl;
    return a;
  }

  if (abs(a - cd) < 0.1)
  {
    Mtl = Sph[1].Mtl;
    return a;
  }

  if (abs(a - cd2) < 0.1)
  {
    Mtl = material(vec3(1, 0.33, 0.05), vec3(0.18275, 0.17, 0.22525), vec3(0.332741, 0.328634, 0.346435), 38.4);
    return a;
  }

  return a;
}

vec3 SDF_SceneNormal( vec3 P, inout material Mtl )
{
 float EPSILON = THRESHOLD;

  return normalize(vec3(
        SDF_Scene(vec3(P.x + EPSILON, P.y, P.z), Mtl) - SDF_Scene(vec3(P.x - EPSILON, P.y, P.z), Mtl),
        SDF_Scene(vec3(P.x, P.y + EPSILON, P.z), Mtl) - SDF_Scene(vec3(P.x, P.y - EPSILON, P.z), Mtl),
        SDF_Scene(vec3(P.x, P.y, P.z + EPSILON), Mtl) - SDF_Scene(vec3(P.x, P.y, P.z - EPSILON), Mtl)
    ));
}

// Color Stuff

float SphereTracing( ray R, float MaxDist, float Threshold, inout intr Intr )
{
  float t = 0;
  
  while (t < MaxDist)
  {
    float d = SDF_Scene(RayApply(R, t), Intr.Mtl);

    if (d <= Threshold)
    {
      Intr.T = d;
      Intr.P = RayApply(R, t);
      Intr.N = SDF_SceneNormal(RayApply(R, t), Intr.Mtl);

      return t;
    }

    t += d;
  }

  return 0;
};

float SphereTracingRec1( ray R, float MaxDist, float Threshold, inout intr Intr, float Weight = 1.0 )
{
  float t = 0;
  
  while (t < MaxDist)
  {
    float d = SDF_Scene(RayApply(R, t), Intr.Mtl);

    if (d <= Threshold)
    {
      Intr.T = d;
      Intr.P = RayApply(R, t);
      Intr.N = SDF_SceneNormal(RayApply(R, t), Intr.Mtl);

      return t;
    }

    t += d;
  }

  return 0;
};

float RayMarching( ray R, int maxIter, float dt, inout intr Intr )
{
  int k = 0;

  while (k < maxIter)
  {
    float d = SDF_Scene(RayApply(R, k * dt), Intr.Mtl);

    if (d < 0)
    {
      Intr.T = d;
      Intr.P = RayApply(R, d);
      Intr.N = SDF_SceneNormal(RayApply(R, k * dt), Intr.Mtl);

      return k * dt;
    }

    k++;
  }

  return 0;
}

void main( void )
{
  vec2 Coord = DrawTexCoord;
  int X = int(Coord.x * FrameW);
  int Y = int((1 - Coord.y) * FrameH);
  ray CamRay = FrameRay(X + 0.5, Y + 0.5);
  intr Intr;

  float Col = SphereTracing(CamRay, 100, THRESHOLD, Intr);

  if (Col != 0)
    OutColor = vec4(Shade(Intr, CamRay.Dir), 1);
  else
    OutColor = vec4(0, 0, 0, 1);
}