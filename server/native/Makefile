CC = gcc

all:
	${CC} \
	-Iwebp/include \
	-Iwebp/src/webp \
	-o dnconv \
	dnconv.c \
	webp/src/enc/analysis.c \
	webp/src/enc/bit_writer.c \
	webp/src/enc/config.c \
	webp/src/enc/cost.c \
	webp/src/enc/dsp.c \
	webp/src/enc/filter.c \
	webp/src/enc/frame.c \
	webp/src/enc/iterator.c \
	webp/src/enc/picture.c \
	webp/src/enc/quant.c \
	webp/src/enc/syntax.c \
	webp/src/enc/tree.c \
	webp/src/enc/webpenc.c \
	`imlib2-config --cflags` `imlib2-config --libs`
