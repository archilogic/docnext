//
//  Utilities.h
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#define USE565
#define REDUCE_TEXTURE

#define AT(arr,i) ([(arr) objectAtIndex:(i)])
#define AT2(arr,i,j) AT(AT((arr),(i)),(j))
#define AT3(arr,i,j,k) AT2(AT((arr),(i)),(j),(k))

#define AT_AS(arr,i,cls) ((cls *)AT((arr),(i)))
#define AT2_AS(arr,i,j,cls) ((cls *)AT2((arr),(i),(j)))
#define AT3_AS(arr,i,j,k,cls) ((cls *)AT3((arr),(i),(j),(k)))

#define FOR(dict,k) ([(dict) objectForKey:(k)])
#define FOR_AS(dict,k,cls) ((cls *)FOR((dict),(k)))
#define FOR_I(dict,k) ([FOR((dict),(k)) intValue])
#define FOR_B(dict,k) ([FOR((dict),(k)) boolValue])
#define FOR_F(dict,k) ([FOR((dict),(k)) floatValue])

#define NUM_I(i) ([NSNumber numberWithInt:(i)])
#define NUM_F(f) ([NSNumber numberWithFloat:(f)])
#define NUM_B(b) ([NSNumber numberWithBool:(b)])

#define CGRectSetX(r,x) ((r)=CGRectMake(x,(r).origin.y,(r).size.width,(r).size.height))
#define CGRectSetY(r,y) ((r)=CGRectMake((r).origin.x,y,(r).size.width,(r).size.height))
#define CGRectSetWidth(r,w) ((r)=CGRectMake((r).origin.x,(r).origin.y,w,(r).size.height))
#define CGRectSetHeight(r,h) ((r)=CGRectMake((r).origin.x,(r).origin.y,(r).size.width,h))
