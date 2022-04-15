            static const float2 CELL_SIZE =float2(20,40);

            float random(float2 st){
                return frac(sin(dot(st.xy,float2(12.9898,78.233)))*43758.5453123);
            }
            float2 random2(float2 st){
                return float2( frac(sin(dot(st.xy,float2(12.9898,78.233)))*43758.5453123),frac(sin(dot(st.yx+float2(0.7,0.6),float2(12.9898,78.233)))*43758.5453123));
            }
           
            float rand2D(float2 co){
                return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
            }

            inline float rand3D(float3 co){
               return frac(sin(dot(co.xyz ,float3(12.9898,78.233,144.7272))) * 43758.5453);
            }
            float3 random3(float3 st){
                return float3( rand3D(st.xyz),rand3D(st.yxz+float3(0.1,0.3,-0.4)),rand3D(st.zyx+float3(0.2,0.7,-0.1)));
            }


            inline float3 getGradVector(float3 cell){
                return (random3(cell)-0.5)*2;
                //ensure it is in -1,1
            }

            inline float3 point2cell(float3 pointv,float3 cellsize){
                return floor(pointv*cellsize)/cellsize;
            }

            inline float3 voffset(float3 offset,float3 cellsize){
                return offset/cellsize;
            }

            float perlinpoint(float3 pointv,float3 offset, float3 cellsize){
                float3 cellpos=point2cell(pointv+voffset(offset,cellsize),cellsize);
                float3 gradvec=getGradVector(cellpos);
                //distance from visual point to cell point
                float3 distVec=(cellpos-pointv)*cellsize;
                float resdot=dot(gradvec,distVec);
                return resdot;
            }
            float fade_1(float t){
                //sinus approximation for fucking opacity value!
                return 6 * pow(t,5) - 15 * pow(t,4) + 10 * pow(t,3);
            }
            
            float fade(float t){
                //faster sinus approximation for fucking opacity value!
                return 3 * pow(t,2) - 2 * pow(t,3);
            }
            
            float perlin3D (float3 pointval,float3 cellsize){
                float3 pointdir= (pointval-point2cell(pointval,cellsize))*cellsize;

                float upl =   lerp(perlinpoint(pointval,float3(0,0,0),cellsize),perlinpoint(pointval,float3(1,0,0),cellsize),fade(pointdir.x));
                float downl = lerp(perlinpoint(pointval,float3(0,1,0),cellsize),perlinpoint(pointval,float3(1,1,0),cellsize),fade(pointdir.x));
                float planel =lerp(upl,downl,fade(pointdir.y));

                
                float upr =   lerp(perlinpoint(pointval,float3(0,0,1),cellsize),perlinpoint(pointval,float3(1,0,1),cellsize),fade(pointdir.x));
                float downr = lerp(perlinpoint(pointval,float3(0,1,1),cellsize),perlinpoint(pointval,float3(1,1,1),cellsize),fade(pointdir.x));
                float planer =lerp(upr,downr,fade(pointdir.y));

                float volp =lerp(planel,planer,fade(pointdir.z));

                return (volp+0.5);
            }

            float perlin3DUniform(float3 pointVal, float cellsize){
                return perlin3D(pointVal, float3(cellsize,cellsize,cellsize));
            }

            float gain(float x, float k) 
            {
                const float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
                return (x<0.5)?a:1.0-a;
            }
/*
            fixed4 EXAMPLE (v2f i)
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return float4(getGradVector(point2cell(i.uv)),-getGradVector(point2cell(i.uv)).y,1);
                float3 csz= float3(_CellSize,_CellSize,_CellSize)/20;
                float p =(perlin3D(i.wpos,csz)+perlincell3(i.wpos,csz*2)/3+perlincell3(i.wpos,csz*4)/4)/1.6;
                
               // return float4(1,1,1,gain(1-p,-3));
                return float4(1,1,1,pow(p,6));

               // p=p>0.3?0:1;
               // return float4(1,1,1,p/3);
            }
            */