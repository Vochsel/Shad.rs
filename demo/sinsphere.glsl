precision mediump float;


//uniform sampler2D iChannel0;
//uniform samplerCube iChannel1;
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float time;


vec2 hash( vec2 p ) { p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*18.5453); }

// return distance, and cell id
vec2 voronoi( in vec2 x )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

	vec3 m = vec3( 8.0 );
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec2  o = hash( n + g );
      //vec2  r = g - f + o;
	    vec2  r = g - f + (0.5+0.5*sin(iGlobalTime+6.2831*o));
		float d = dot( r, r );
        if( d<m.x )
            m = vec3( d, o );
    }

    return vec2( sqrt(m.x), m.y+m.z );
}

float sphere(vec3 pos, float radius)
{
    return length(pos) - radius;
}

float box(vec3 pos, vec3 size)
{
    return length(max(abs(pos) - size, 0.0));
}

vec3 rotateX(vec3 pos, float alpha) {
	return vec3(pos.x,
				pos.y * cos(alpha) + pos.z * -sin(alpha),
				pos.y * sin(alpha) + pos.z * cos(alpha));
}

vec3 rotateY(vec3 pos, float alpha) {
	return vec3(pos.x * cos(alpha) + pos.z * sin(alpha),
				pos.y,
				pos.x * -sin(alpha) + pos.z * cos(alpha));
}

float cylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}
float opDisplace( vec3 p )
{
    float d1 = sphere(p, 10.); //1.2
    //float d2 = sin(length(p) + clamp((sin((p.y + p.x + iGlobalTime / 2.0) * 12.0)), 0.0, 0.25));
   // p.z += iGlobalTime;
    float amt = 0.7;
    float d2 = sin(amt*p.x)*sin(amt*p.y)*sin(amt*p.z);

    //float d2 = voronoi(p.xy).;
    return d1+d2;
}

/*
float opBlend( vec3 p )
{
    float d1 = sphere(p);
    float d2 = sphere(p);
    return smin( d1, d2 );
}*/

float torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float opTwist( vec3 p )
{
    float c = cos(15.0*p.y);
    float s = sin(15.0*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
   	return torus(q, vec2(0.35, 0.7));
   	//return box(q, vec3(0.5));
}


float distfunc(vec3 pos)
{
  float spherev = sphere(pos, 1.);
	float spheresmallv = sphere(pos, .5);

  vec3 boxpos = pos;
  boxpos = rotateY(boxpos, iGlobalTime);
  boxpos = rotateX(boxpos, iGlobalTime);
    float boxv = box(boxpos, vec3(1.0, 1.0, 1.0)/5.);
	float torusv = torus(pos, vec2(1., 0.4));
    float subtracted = max(-torusv, spherev);
//    return subtracted;
  //  return subtracted;
    /////pos *= vec3(1.0, (1. - cos(sin(iGlobalTime))),cos(iGlobalTime));  //Damn...


  pos *= vec3(cos(iGlobalTime - 1.), 1.0,cos(iGlobalTime));  //Damn...

	return min(spheresmallv, max(-opTwist(pos), spherev));


  //return opDisplace(pos);

}


void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
  //normalize(texture( NormalTextureSampler, UV ).rgb*2.0 - 1.0)
    //float mousex = (iMouse.x /iResolution.x - 1.4) * 3.0;
    float camDist = 1.5;
    float spinSpeed = 0.2;
	vec3 cameraOrigin = vec3(sin(iGlobalTime * spinSpeed) * camDist, 0.0 * camDist,cos(iGlobalTime * spinSpeed) * camDist);

	float pitch = 0.0;
	float roll = 0.0;
	float yaw = 0.0;

	//vec3 cameraOrigin = vec3(0.8, 0.2, 0.8);

	//cameraOrigin.y -= .0;
  vec3 cameraTarget = vec3(0.0, 0.0, 0.0);

  vec3 upDirection = vec3(0.0, -1.0, 0.0);
  vec3 cameraDir = normalize(cameraTarget - cameraOrigin);

  vec3 cameraRight = normalize(cross(upDirection, cameraOrigin));
	vec3 cameraUp = cross(cameraDir, cameraRight);

  vec2 screenPos = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy; // screenPos can range from -1 to 1
	screenPos.x *= iResolution.x / iResolution.y; // Correct aspect ratio

  vec3 rayDir = normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);

  //March
  const int MAX_ITER = 450; // 100 is a safe number to use, it won't produce too many artifacts and still be quite fast
  const float MAX_DIST = 50.0; // Make sure you change this if you have objects farther than 20 units away from the camera
  const float EPSILON = 0.0005; // At this distance we are close enough to the object that we have essentially hit it

  float totalDist = 0.0;
  vec3 pos = cameraOrigin ;
  float dist = EPSILON;


  for (int i = 0; i < MAX_ITER; i++)
  {
    // Either we've hit the object or hit nothing at all, either way we should break out of the loop
    if (dist < EPSILON || totalDist > MAX_DIST)
      break; // If you use windows and the shader isn't working properly, change this to continue;

    dist = distfunc(pos) / 2.; // Evalulate the distance at the current point
    totalDist += dist;
    pos += dist * rayDir; // Advance the point forwards in the ray direction by the distance
  }


  if (dist < EPSILON)
  {
    // Lighting code

    vec2 eps = vec2(0.0, EPSILON);
    vec3 normal = normalize(vec3(
      distfunc(pos + eps.yxx) - distfunc(pos - eps.yxx),
      distfunc(pos + eps.xyx) - distfunc(pos - eps.xyx),
      distfunc(pos + eps.xxy) - distfunc(pos - eps.xxy))
    );


    float diffuse = max(0.0, dot(-rayDir, normal));
    float specular = pow(diffuse, 32.0);

    float rim = 1.75 * max( 0., abs( dot( normalize( normal ), normalize( -pos.xyz ) ) ) );


    //vec3 r = reflect( normalize( pos.xy ), normalize( normal ) );
    //float m = 2.0 * sqrt( r.x * r.x + r.y * r.y + ( r.z + 1.0 ) * ( r.z + 1.0 ) );
    //vec2 calculatedNormal = vec2( r.x / m + 0.5,  r.y / m + 0.5 );

    //vec3 tex = normalize(texture2D(iChannel0, pos.xy).rgb);

    float bias = 0.1;
    float scale = 0.5;
    float power = 2.0;


    float R = max(0.5, min(1., bias + scale * (1.0 + dot(rayDir, normal)) * power));

    //vec3 reflection = textureCube(iChannel1, reflect(rayDir + cameraUp, normal + tex / 2.)).xyz / 2.10;

    //gold
    vec3 base = vec3(0.8, 0.7, 0.4);
    vec3 color1 = vec3((base) * R);
    //vec3 color2 = vec3((diffuse + specular) / 2. + reflection);
    gl_FragColor = vec4(color1, 1.0);
    return;
  } else {
    //gl_FragColor = vec4(textureCube(iChannel1, rayDir).xyz, 1.0);
    gl_FragColor = vec4(vec3(1. - (length(vec2(0.) - screenPos)) * 0.2), 1.0);
    //gl_FragColor = vec4(tex, 1.0);
  }


}
