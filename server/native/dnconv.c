#include <stdio.h>
#include <Imlib2.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#define TEX_SIZE 512
#define THUMB_SIZE 256
#define QUALITY 90

#include "webp/encode.h"

int min( int x , int y ) {
    return x < y ? x : y;
}

int max( int x , int y ) {
    return x > y ? x : y;
}

void _write( char *path ) {
    imlib_image_set_format( "jpg" );
    imlib_image_attach_data_value( "quality" , NULL , QUALITY , NULL );
    imlib_save_image( path );
}

void write( char *dst_dir , char *file_name ) {
    char path[ 256 ];
    sprintf( path , "%s%s" , dst_dir , file_name );
    _write( path );
}

void write_thumb( char *dst_dir , char *page ) {
    char name[ 256 ];
    sprintf( name , "thumbnail-%s.jpg" , page );
    write( dst_dir , name );
}

void getRGB( uint8_t *rgb ) {
    DATA32 *data = imlib_image_get_data();

    int index;
    for ( index = 0; index < TEX_SIZE * TEX_SIZE ; index++ ) {
        int argb = data[ index ];
        rgb[ index * 3 + 0 ] = ( argb & 0xff0000 ) >> 16;
        rgb[ index * 3 + 1 ] = ( argb & 0xff00 ) >> 8;
        rgb[ index * 3 + 2 ] = argb & 0xff;
    }
}

int writer( const uint8_t* data , size_t data_size , const WebPPicture* const pic ) {
    FILE* const out = ( FILE* ) pic->custom_ptr;
    return data_size ? ( fwrite( data , data_size , 1 , out ) == 1 ) : 1;
}

void write_tex( char *dst_dir , char *page , int level , int px , int py , int is_webp ) {
    if ( is_webp ) {
        WebPPicture picture;
        WebPConfig config;
        WebPAuxStats stats;

        if ( !WebPPictureInit( &picture ) || !WebPConfigInit( &config ) ) {
            fprintf( stdout , "Error on WebPInit\n" );
            return;
        }

        config.quality = QUALITY;

        if ( !WebPValidateConfig( &config ) ) {
            fprintf( stdout , "Error on WebPValidateConfig\n" );
            return;
        }

        uint8_t *rgb = malloc( sizeof(uint8_t) * TEX_SIZE * TEX_SIZE * 3 );
        getRGB( rgb );

        picture.width = TEX_SIZE;
        picture.height = TEX_SIZE;
        if ( !WebPPictureImportRGB( &picture , rgb , TEX_SIZE * 3 ) ) {
            fprintf( stdout , "Error on WebPPictureImportRGB\n" );
            return;
        }

        free( rgb );

        char out_name[ 256 ];
        sprintf( out_name , "%stexture-%s-%d-%d-%d.webp" , dst_dir , page , level , px , py );

        FILE *out = fopen( out_name , "wb" );
        if ( !out ) {
            fprintf( stderr , "Error! Cannot open output file '%s'\n" , out_name );
            return;
        }

        picture.writer = writer;
        picture.custom_ptr = ( void* ) out;

        picture.stats = &stats;

        if ( !WebPEncode( &config , &picture ) ) {
            fprintf( stderr , "Error! Cannot encode picture as WebP\n" );
            return;
        }

        WebPPictureFree( &picture );
        fclose( out );
    } else {
        char out_name[ 256 ];
        sprintf( out_name , "texture-%s-%d-%d-%d.jpg" , page , level , px , py );

        write( dst_dir , out_name );
    }
}

void create_thumb( char *dst_dir , char *page , int sw , int sh ) {
    int w , h;

    if ( sw < sh ) {
        w = THUMB_SIZE * sw / sh;
        h = THUMB_SIZE;
    } else {
        w = THUMB_SIZE;
        h = THUMB_SIZE * sh / sw;
    }

    imlib_context_set_image( imlib_create_cropped_scaled_image( 0 , 0 , sw , sh , w , h ) );
    write_thumb( dst_dir , page );
    imlib_free_image_and_decache();
}

void create_texture_by_source_length( char *dst_dir , char *page , Imlib_Image image , int sw , int sh , int level , int l , int is_webp ) {
    int py;
    for ( py = 0; py * l < sh ; py++ ) {
        int px;
        for ( px = 0; px * l < sw ; px++ ) {
            fprintf( stdout , ">> py: %d , px: %d\n" , py , px );

            int sx = px * l;
            int sy = py * l;
            int cw = min( l , sw - sx );
            int ch = min( l , sh - sy );
            int rw = cw * TEX_SIZE / l;
            int rh = ch * TEX_SIZE / l;

            imlib_context_set_image( image );
            Imlib_Image resized = imlib_create_cropped_scaled_image( sx , sy , cw , ch , rw , rh );

            if ( cw == l && ch == l ) {
                imlib_context_set_image( resized );

                write_tex( dst_dir , page , level , px , py , is_webp );
            } else {
                imlib_context_set_image( imlib_create_image( TEX_SIZE , TEX_SIZE ) );
                imlib_image_fill_rectangle( 0 , 0 , TEX_SIZE , TEX_SIZE );

                imlib_blend_image_onto_image( resized , 0 , 0 , 0 , rw , rh , 0 , 0 , rw , rh );

                write_tex( dst_dir , page , level , px , py , is_webp );

                imlib_free_image_and_decache();

                imlib_context_set_image( resized );
            }

            imlib_free_image_and_decache();
        }
    }
}

void create_texture( char *dst_dir , char *page , Imlib_Image image , int sw , int sh , int use_actual_size , int is_webp ) {
    int level;
    for ( level = 0; ; level++ ) {
        int factor = pow( 2 , level );

        if ( factor * TEX_SIZE > sw ) {
            break;
        }

        fprintf( stdout , "level: %d\n" , level );

        int l = ( sw - 1 ) / factor + 1;

        create_texture_by_source_length( dst_dir , page , image , sw , sh , level , l , is_webp );
    }

    if ( use_actual_size ) {
        fprintf( stdout , "level: %d (for actual size)\n" , level );

        create_texture_by_source_length( dst_dir , page , image , sw , sh , level , TEX_SIZE , is_webp );
    }
}

int check_args( char *src_file , char *dst_dir , char *use_actual_size , char *do_crop , char *is_webp ) {
    struct stat buf;

    if ( stat( src_file , &buf ) ) {
        perror( src_file );
        return 1;
    }

    if ( !S_ISREG( buf.st_mode ) ) {
        fprintf( stderr , "[input file path] is not a file\n" );
        return 1;
    }

    if ( stat( dst_dir , &buf ) ) {
        perror( dst_dir );
        return 1;
    }

    if ( !S_ISDIR( buf.st_mode ) ) {
        fprintf( stderr , "[output dir path] is not a directory\n" );
        return 1;
    }

    if ( dst_dir[ strlen( dst_dir ) - 1 ] != '/' ) {
        fprintf( stderr , "[output dir path] must terminated by /\n" );
        return 1;
    }

    if ( strcmp( use_actual_size , "true" ) != 0 && strcmp( use_actual_size , "false" ) != 0 ) {
        fprintf( stderr , "[use actual size] must true or false\n" );
        return 1;
    }

    if ( strcmp( do_crop , "true" ) != 0 && strcmp( do_crop , "false" ) != 0 ) {
        fprintf( stderr , "[do crop] must true or false\n" );
        return 1;
    }

    if ( strcmp( is_webp , "true" ) != 0 && strcmp( is_webp , "false" ) != 0 ) {
        fprintf( stderr , "[is webp] must true or false\n" );
        return 1;
    }

    return 0;
}

int main( int argc , char **argv ) {
    clock_t t = clock();

    if ( argc != 9 ) {
        fprintf( stderr , "invalid arguments\n" );
        fprintf( stderr , "\n" );
        fprintf(
                stderr ,
                "usage: [this command] [input file path] [output directory path] [page number] [use actual size (true, false)] [target width] [target height] [do crop (true, false)] [is webp (true, false)]\n" );
        fprintf( stderr , "- [input file path] and [output directory path] should exists\n" );
        fprintf( stderr , "- [output directory path] must terminated by /\n" );
        return 1;
    }

    char *src_file = argv[ 1 ];
    char *dst_dir = argv[ 2 ];
    char *page = argv[ 3 ];
    char *arg_use_actual_size = argv[ 4 ];
    char *arg_do_crop = argv[ 7 ];
    char *arg_is_webp = argv[ 8 ];

    if ( check_args( src_file , dst_dir , arg_use_actual_size , arg_do_crop , arg_is_webp ) ) {
        return 1;
    }

    int use_actual_size = strcmp( arg_use_actual_size , "true" ) == 0;
    int do_crop = strcmp( arg_do_crop , "true" ) == 0;
    int is_webp = strcmp( arg_is_webp , "true" ) == 0;

    int target_width = atoi( argv[ 5 ] );
    int target_height = atoi( argv[ 6 ] );

    imlib_context_set_color( 0 , 0 , 0 , 255 );

    Imlib_Image image = imlib_load_image( src_file );

    if ( !image ) {
        fprintf( stderr , "imlib_load_image failed. (for file path %s)\n" , src_file );
        return 1;
    }

    imlib_context_set_image( image );

    int w = imlib_image_get_width();
    int h = imlib_image_get_height();

    Imlib_Image resized;

    if ( do_crop ) {
        if ( w / target_width < h / target_height ) {
            int dh = w * target_height / target_width;
            resized = imlib_create_cropped_scaled_image( 0 , ( h - dh ) / 2 , w , dh , target_width , target_height );
        } else {
            int dw = h * target_width / target_height;
            resized = imlib_create_cropped_scaled_image( ( w - dw ) / 2 , 0 , dw , h , target_width , target_height );
        }
    } else {
        resized = imlib_create_cropped_scaled_image( 0 , 0 , w , h , target_width , target_height );
    }

    imlib_context_set_image( image );
    imlib_free_image_and_decache();

    imlib_context_set_image( resized );

    create_thumb( dst_dir , page , target_width , target_height );
    create_texture( dst_dir , page , resized , target_width , target_height , use_actual_size , is_webp );

    imlib_context_set_image( resized );
    imlib_free_image_and_decache();

    fprintf( stdout , "Tooks %d (ms)\n" , ( int ) ( ( clock() - t ) / ( CLOCKS_PER_SEC / 1000 ) ) );

    return 0;
}
