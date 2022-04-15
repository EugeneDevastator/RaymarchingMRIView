// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'



Shader "Unlit/3dTexcRayMarchStripping"
{


    Properties
    {
        _3dMainTex ("Texture3d", 3D) = "white" {}
        _StepSize("StepSize", Range(0,0.1)) = 1
        _StepCount("_StepCount", Range(0,600)) = 1
        _StripLayers("_Strip layers", Range(0,600)) = 1
        _StripSurf("_Strip Surfaces", Range(-1,20)) = 0
        _DensityMul("_DensityMul", Range(0,1)) = 0.2
        _SliceX("_SliceX", Range(0,1)) = 1
        _BandW("_BandWidth", Range(0,1)) = 1
        _BandOff("_BandOffset", Range(0,1)) = 1
        _NormalDelta("_NormalDelta", Range(0,0.1)) = 1
        _PerlinSize("PerlinDensity", Range(0,30)) = 1
        _PerlinMag("ParlinDampening", Range(0,30)) = 1
    }

    SubShader
    {

        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
        LOD 100
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Perlin3d.cginc"
            //_WorldSpaceCameraPos
            //o.cameraLocalPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));


            struct vertexIn
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct fragIn
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 posWS : TEXCOORD1;
                float3 posOS : TEXCOORD2;

            };

            sampler3D _3dMainTex;
            float4 _3dMainTex_ST;
            float _StepSize;
            float _PerlinMag;
            float _PerlinSize;
            float _DensityMul;
            float _SliceX;
            float _BandW;
            float _BandOff;
            float _NormalDelta;
            int _StepCount;
            int _StripLayers;
            int _StripSurf;

            static const int RAYMARCH_STEPS = 41;

            fragIn vert (vertexIn v)
            {
                fragIn o;
                o.posWS = mul(unity_ObjectToWorld, v.posOS).xyz;
                o.posOS = v.posOS;
                o.vertex = UnityObjectToClipPos(v.posOS);
                o.uv = TRANSFORM_TEX(v.uv, _3dMainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float VolumeFunction(float3 sampleOS){
                if(sampleOS.x > _SliceX*2-1){
                        return 0;
                }
                if(abs(sampleOS.x)>0.5 || abs(sampleOS.y)>0.5 || abs(sampleOS.z)>0.5){
                    return 0;
                }

                float sample = tex3D(_3dMainTex, sampleOS + float3(0.5f, 0.5f, 0.5f)).g;
                if (sample < _BandOff - _BandW || sample > _BandOff + _BandW){
                    return 0;
                }
                return 1;
            }

            float4 GetNormalOS(float3 sampleOS){
                float3 adjPos =sampleOS + float3(0.5f, 0.5f, 0.5f);
                float d=_NormalDelta;
                float sample0 = tex3D(_3dMainTex, adjPos).g;
                float sampleX = tex3D(_3dMainTex, adjPos +float3(d,0,0)).r - sample0;
                float sampleY = tex3D(_3dMainTex, adjPos +float3(0,d,0)).r - sample0;
                float sampleZ = tex3D(_3dMainTex, adjPos +float3(0,0,d)).r - sample0;
                float3 norm = normalize(float3(sampleX,sampleY,sampleZ));
                return float4(norm,1);
            }

            fixed4 frag (fragIn i) : SV_Target
            {
                float3 viewDirWS = normalize(i.posWS - _WorldSpaceCameraPos);
                float3 viewDirOS = mul(unity_WorldToObject, viewDirWS);

                float4 lightDirection = float4(normalize(_WorldSpaceLightPos0.xyz),1);
                float4 lightDirOS = normalize(mul(unity_WorldToObject, lightDirection));

                //For whatever reason - this FAILS to produce adequate result:
                //float3 camPosOS = mul(unity_WorldToObject, _WorldSpaceCameraPos);
                //float3 viewDirOS = normalize(i.posOS - camPosOS);

                //return float4(viewDirOS,1);

                int strip = _StripLayers;
                float3 targetpos;
                float cumulative = 0;
                float3 startPos = i.posOS;
                int inSurf = 0;
                int curSurf = 0;
                for(int i = 0; i <= _StepCount; i++){

                    float sampleX = VolumeFunction(startPos);
                    if (sampleX > 0) {
                        if (inSurf == 0){
                            inSurf = 1;
                            curSurf ++;
                        }
                        if (inSurf == 1 && curSurf == _StripSurf){
                            strip --;
                            if (strip < 0){
                                //i = _StepCount+1;
                                targetpos = startPos;
                                //strip = 10000;
                                //cumulative =1;
                                cumulative += sampleX * _DensityMul;
                            }
                        }
                    }
                    else {
                        if (inSurf == 1){
                            inSurf = 0;
                        }
                    }

                    startPos += viewDirOS * _StepSize;
                }
                if (targetpos.x ==0){
                    return 0;
                }

                float4 surfNormOS = GetNormalOS(targetpos);
                //return surfNormOS;
                //return max(0,1-dot(surfNormOS,lightDirOS));
                return(float4(1,1,1,cumulative));
            }
//-------------------
            ENDCG
        }

         Pass
        {
            Cull front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Perlin3d.cginc"
            //_WorldSpaceCameraPos
            //o.cameraLocalPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));


            struct vertexIn
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct fragIn
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 posWS : TEXCOORD1;
                float3 posOS : TEXCOORD2;

            };

            sampler3D _3dMainTex;
            float4 _3dMainTex_ST;
            float _StepSize;
            float _PerlinMag;
            float _PerlinSize;
            float _DensityMul;
            float _SliceX;
            float _BandW;
            float _BandOff;
            float _NormalDelta;
            int _StepCount;
            int _StripLayers;
            int _StripSurf;

            static const int RAYMARCH_STEPS = 41;

            fragIn vert (vertexIn v)
            {
                fragIn o;
                o.posWS = mul(unity_ObjectToWorld, v.posOS).xyz;
                o.posOS = v.posOS;
                o.vertex = UnityObjectToClipPos(v.posOS);
                o.uv = TRANSFORM_TEX(v.uv, _3dMainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float VolumeFunction(float3 sampleOS){
                if(sampleOS.x > _SliceX*2-1){
                        return 0;
                }
                if(abs(sampleOS.x)>0.5 || abs(sampleOS.y)>0.5 || abs(sampleOS.z)>0.5){
                    return 0;
                }

                float sample = tex3D(_3dMainTex, sampleOS + float3(0.5f, 0.5f, 0.5f)).g;
                if (sample < _BandOff - _BandW || sample > _BandOff + _BandW){
                    return 0;
                }
                return 1;
            }

            float4 GetNormalOS(float3 sampleOS){
                float3 adjPos =sampleOS + float3(0.5f, 0.5f, 0.5f);
                float d=_NormalDelta;
                float sample0 = tex3D(_3dMainTex, adjPos).g;
                float sampleX = tex3D(_3dMainTex, adjPos +float3(d,0,0)).r - sample0;
                float sampleY = tex3D(_3dMainTex, adjPos +float3(0,d,0)).r - sample0;
                float sampleZ = tex3D(_3dMainTex, adjPos +float3(0,0,d)).r - sample0;
                float3 norm = normalize(float3(sampleX,sampleY,sampleZ));
                return float4(norm,1);
            }

            fixed4 frag (fragIn i) : SV_Target
            {
                float3 viewDirWS = normalize(i.posWS - _WorldSpaceCameraPos);
                float3 viewDirOS = mul(unity_WorldToObject, viewDirWS);

                float4 lightDirection = float4(normalize(_WorldSpaceLightPos0.xyz),1);
                float4 lightDirOS = normalize(mul(unity_WorldToObject, lightDirection));

                //For whatever reason - this FAILS to produce adequate result:
                //float3 camPosOS = mul(unity_WorldToObject, _WorldSpaceCameraPos);
                //float3 viewDirOS = normalize(i.posOS - camPosOS);

                //return float4(viewDirOS,1);

                int strip = _StripLayers;
                float3 targetpos;
                float3 camPosOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                float cumulative = 0;
                float3 startPos = camPosOS;
                int inSurf = 0;
                int curSurf = 0;
                for(int i = 0; i <= _StepCount; i++){

                    float sampleX = VolumeFunction(startPos);
                    if (sampleX > 0) {
                        if (inSurf == 0){
                            inSurf = 1;
                            curSurf ++;
                        }
                        if (inSurf == 1 && curSurf == _StripSurf){
                            strip --;
                            if (strip < 0){
                                //i = _StepCount+1;
                                targetpos = startPos;
                                //strip = 10000;
                                //cumulative =1;
                                cumulative += sampleX * _DensityMul;
                            }
                        }
                    }
                    else {
                        if (inSurf == 1){
                            inSurf = 0;
                        }
                    }

                    startPos += viewDirOS * _StepSize;
                }
                if (targetpos.x ==0){
                    return 0;
                }

                float4 surfNormOS = GetNormalOS(targetpos);
                //return surfNormOS;
                //return max(0,1-dot(surfNormOS,lightDirOS));
                return(float4(1,1,1,cumulative));
            }
//-------------------
            ENDCG
        }
    }
}
