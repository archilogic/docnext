#include <jni.h>
#include <android/log.h>
#include <GLES/gl.h>
#include <GLES/glext.h>

#include <cstdlib>

#include "webp/decode.h"

extern "C" {

JNIEXPORT jint JNICALL Java_jp_archilogic_docnext_android_coreview_image_LoadBitmapTask_nativeLoad( JNIEnv *env , jobject obj ,
        jbyteArray data ) {
    int size = env->GetArrayLength( data );

    int width;
    int height;

    jbyte* arr = env->GetByteArrayElements( data , NULL );

    uint8_t *ret = ( WebPDecodeRGB( ( uint8_t * ) arr , size , &width , &height ) );

    env->ReleaseByteArrayElements( data , arr , 0 );

    if ( !ret ) {
        __android_log_print( ANDROID_LOG_DEBUG , "NativeWebp" , "***** Cannot decode webp *****" );
        return 0;
    }

    return ( jint ) ret;
}

JNIEXPORT void JNICALL Java_jp_archilogic_docnext_android_coreview_image_TextureInfo_nativeTexImage2D( JNIEnv *env , jobject obj , jint id , uint8_t *data , jint width , jint height ) {
    glBindTexture( GL_TEXTURE_2D , id );
    glTexImage2D( GL_TEXTURE_2D , 0 , GL_RGB , width , height , 0 , GL_RGB , GL_UNSIGNED_BYTE , data );
}

JNIEXPORT void JNICALL Java_jp_archilogic_docnext_android_coreview_image_CoreImageRenderEngine_nativeUnload( JNIEnv *env , jobject obj , uint8_t *data ) {
    free( data );
}

JNIEXPORT void JNICALL Java_jp_archilogic_docnext_android_coreview_image_facingpages_CoreImageRenderEngine_nativeUnload( JNIEnv *env , jobject obj , uint8_t *data ) {
    free( data );
}

}
