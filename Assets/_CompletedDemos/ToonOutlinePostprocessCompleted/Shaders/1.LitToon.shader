Shader "Unlit/1.LitToon"
{
    Properties
    {
        _MainTex ("RGB:albeodo", 2D) = "white" {}
        _RampTex ("R:RampTex", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags { 
            "RenderPipeline" = "UniversalRenderPipeline" 
            "RenderType" = "Opaque" 
        }
   
        Pass {
            Tags {
                "LightMode"="SRPDefaultUnlit"
            }
            
            Cull Front
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
            
            struct v2f
            {
                float4 positionCS : SV_POSITION;
            };
            
            v2f vert(a2v v)
            {
                v2f o = (v2f)0;

                // 位置
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz + v.normal.xyz * 0.003);
                o.positionCS = positionInputs.positionCS;
                
                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                half4 col = 0.0;
                return col;
            }

            ENDHLSL
        }
        
        Pass
        {
            Tags {
                "LightMode"="UniversalForward"
            }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // 阴影相关多编译
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            half4 _MainTex_ST;
            
            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o = (v2f)0;

                // 位置
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;

                // 法线
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);
                o.normalWS = normalInputs.normalWS;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            half3 LightingLambertAndPhong(Light light, float3 normalWS)
            {
                half3 diffuse = LightingLambert(light.color, light.direction, normalWS);
                half3 col = diffuse;
                col *= light.distanceAttenuation * light.shadowAttenuation;
                return col;
            }
            
            half4 frag(v2f i): SV_Target
            {
                half4 col = 0.0;

                // 主灯光
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light light = GetMainLight(shadowCoord);
                half3 lightCol = LightingLambertAndPhong(light, i.normalWS);
                
                uint additionalLightsCount = GetAdditionalLightsCount();
                for(uint j = 0u; j < additionalLightsCount; j++)
                {
                    light = GetAdditionalLight(j, i.positionWS);
                    lightCol += LightingLambertAndPhong(light, i.normalWS);
                }

                // 渐变纹理图
                half3 var_RampTex = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, half2(lightCol.r, 0.5));
                half3 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                col.rgb = var_RampTex * var_MainTex;
                return col;
            }
            
            ENDHLSL
        }
        
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}