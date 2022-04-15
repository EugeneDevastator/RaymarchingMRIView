// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/3dTexcRayMarch"
{

    
    Properties
    {
        _3dMainTex ("Texture3d", 3D) = "white" {}
        _StepSize("StepSize", Range(0,0.1)) = 1
        _StepCount("_StepCount", Range(0,300)) = 1
        _DensityMul("_DensityMul", Range(0,1)) = 1
        _SliceX("_SliceX", Range(0,1)) = 1
        _BandW("_BandWidth", Range(0,1)) = 1
        _BandOff("_BandOffset", Range(0,1)) = 1
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
            int _StepCount;
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
                return sample;
            }

            fixed4 frag (fragIn i) : SV_Target
            {
                float3 viewDirWS = normalize(i.posWS - _WorldSpaceCameraPos);
                float3 viewDirOS = mul(unity_WorldToObject, viewDirWS);

                //For whatever reason - this FAILS to produce adequate result:
                //float3 camPosOS = mul(unity_WorldToObject, _WorldSpaceCameraPos);
                //float3 viewDirOS = normalize(i.posOS - camPosOS);

                //return float4(viewDirOS,1);

                float cumulative = 0;
                float3 startPos = i.posOS;
                for(int i = 0; i <= _StepCount; i++){

                    float sampleX = VolumeFunction(startPos);
                    cumulative += sampleX * _DensityMul;
                    startPos += viewDirOS * _StepSize;
                }
                return(float4(1,1,1,cumulative));
            }
//-------------------
            ENDCG
        }

     Pass
        {
            Cull Front

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
            int _StepCount;
            float _BandW;
            float _BandOff;

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
                return sample;
            }

            fixed4 frag (fragIn i) : SV_Target
            {
                float3 viewDirWS = normalize(i.posWS - _WorldSpaceCameraPos);
                float3 viewDirOS = mul(unity_WorldToObject, viewDirWS);

                //For whatever reason - this FAILS to produce adequate result:
                //float3 camPosOS = mul(unity_WorldToObject, _WorldSpaceCameraPos);
                //float3 viewDirOS = normalize(i.posOS - camPosOS);

                //return float4(viewDirOS,1);
                float3 camPosOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));

                float cumulative = 0;
                float3 startPos = camPosOS;
                for(int i = 0; i <= _StepCount; i++){

                    float sampleX = VolumeFunction(startPos);
                    cumulative += sampleX * _DensityMul;
                    startPos += viewDirOS * _StepSize;
                }
                return(float4(1,1,1,cumulative));
            }
//-------------------
            ENDCG
        }
    }
}
