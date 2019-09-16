/*
 *  ======== Mon.c ========
 *  Portable ROV runtime monitor
 *
 *  See doCommand below for a description of the supported commands and
 *  the format of the data exchanged between the target and the ROV
 *  application.
 */

#include <stdint.h>
#include <string.h>

#include "Mon.h"

static uint32_t crc32(uint32_t init, const char *data, int len);
static int doCommand(Mon_Handle mon, int len);
static long getLong(const char *buf, int len, int *next);

/*
 *  ======== Mon_doCommand ========
 */
int Mon_doCommand(Mon_Handle mon)
{
    int bufLen = 0;

    for (;;) {
        char c;
        int status;

        /* read characters to the command buffer, byte at a time */
        status = mon->read(&c, sizeof(c));
        if (status < 0) {
            return (status);
        }

        /* ignore bogus characters */
        if (c == '\0' || c == '\r' || status != 1) continue;

        /* never overrun the command buffer */
        if (bufLen >= Mon_MAXCMDSIZE) {
            bufLen = Mon_MAXCMDSIZE - 1;
        }
        mon->buffer[bufLen++] = c;

        /* if there's a new line, we have a complete command */
        if (c == '\n') {
            /* run command and reset buffer index to get next command */
            status = doCommand(mon, bufLen);
            return (status);
        }
    }
}

/*
 *  ======== doCommand ========
 *  Execute the command in buffer and send results to client
 *
 *  Commands suported:
 *      "r <addr>,<cnt>"  - copy <cnt> bytes from <addr> and write them to
 *                          the host
 *      "w <addr>,<cnt>"  - read <cnt> bytes from the host and copy them to
 *                          <addr>
 *      "c <addr>,<cnt>"  - crc32 <cnt> bytes from <addr> and write the
 *                           4-byte binary CRC32 to the host
 *
 *  where, <addr> is a long and <cnt> is an int represented in lower-case
 *  hexadecimal.
 */
static int doCommand(Mon_Handle mon, int len)
{
    long addr;
    int cnt;
    int i;

    if (len < 4) {
        return (0); /* ignore bogus commands to avoid checks below */
    }
    
    /* read address */
    addr = getLong(mon->buffer + 2, len - 2, &i);

    i += 3; /* skip over initial command and ',' separation character */

    /* read count */
    cnt = getLong(mon->buffer + i, len - i, &i);

    /* do the memory read/write */
    while (cnt > 0) {
        int status;
        switch (mon->buffer[0]) {
            case 'r': {
                /* copy up to cnt bytes starting from addr to the connection */
                status = mon->write((const char *)addr, cnt);
                break;
            }
            case 'w': {
                /* copy up to cnt bytes from the connection into addr */
                status = mon->read((char *)addr, cnt);
                break;
            }
            case 'c': {
                /* compute CRC32 and send 32-bit result */
                uint32_t crc = crc32(0, (const char *)addr, cnt);
                char *cp = (char *)&crc;
                for (cnt = sizeof(crc); cnt > 0; cnt -= status) {
                    if ((status = mon->write(cp, cnt)) <= 0) {
                        break;
                    }
                    cp += status;
                }
                cnt = 0;
                break;
            }
            default: {
                status = 0;
            }
        }
        if (status < 0) {
            return (status); /* terminate command on any I/O error */
        }

        /* handle partial reads/writes */
        cnt -= status;
        addr += status;
    }

    return (0);
}

/*
 *  ======== getLong ========
 *  Convert lower-case hex number in buf to a long value
 *
 *  Returns long value and index of next non-hex-digit character
 */
static long getLong(const char *buf, int len, int *next)
{
    static const char hex[] = "0123456789abcdef";
    unsigned long value;
    int i;

    /* decode hex address */
    for (value = 0, i = 0; i < len;  i++) {
        unsigned char c = buf[i];
        char *cp = strchr(hex, c);
        if (cp == NULL) {
            break;
        }
        value = (value * 16) + (cp - hex);
    }

    *next = i;
    return (value);
}

/*
 *  ======== crc_table ========
 *  Generated CRC32 table (see https://pycrc.org/index.html)
 *
 *  Generated by pycrc v0.9, from https://pycrc.org, via
 *     python pycrc.py --model crc-32 --algorithm tbl --table-idx-width 4
 *
 *  Using the configuration:
 *    Width         = 32
 *    Poly          = 0x04c11db7
 *    Xor_In        = 0xffffffff
 *    ReflectIn     = True
 *    Xor_Out       = 0xffffffff
 *    ReflectOut    = True
 *    Algorithm     = table-driven
 */
static const uint32_t crc_table[] = {
    0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
    0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
    0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
    0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
};

/*
 *  ======== crc32 ========
 */
static uint32_t crc32(uint32_t init, const char *data, int len)
{
    uint32_t crc = ~init;
    int i;
    
    for (i = 0; i < len; i++) {
        int idx;
        unsigned char bite = data[i];
        
        idx = 0x0f & (crc ^ bite);
        crc = crc_table[idx] ^ (crc >> 4);

        idx = 0x0f & (crc ^ (bite >> 4));
        crc = crc_table[idx] ^ (crc >> 4);
    }

    return (~crc & 0xffffffffL);
}
