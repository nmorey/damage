# Copyright (C) 2011  Nicolas Morey-Chaisemartin <nicolas@morey-chaisemartin.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Damage
    module C
        module Common

            def write(description)
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/_#{description.config.libname}/", "common.h")
                self.genCommonH(output, description)
                output.close()
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "common.c")
                self.genCommonC(output, description)
                output.close()
            end
            module_function :write


            private

            def genCommonH(output, description)
                libName = description.config.libname
                output.puts "
#ifndef __#{libName}_common_h__
#define __#{libName}_common_h__

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include <libxml/xmlreader.h>

#define __#{libName.upcase}_MAX_OPENED_FILES 10

void *__#{libName}_malloc(unsigned long size);
void *__#{libName}_realloc(void *ptr, unsigned long size);
void __#{libName}_free(void *ptr);
int __#{libName}_compare(const char *name, const char *matches[]);
char *__#{libName}_read_value_str(xmlNodePtr reader);
unsigned long __#{libName}_read_value_ulong(xmlNodePtr reader);
signed long __#{libName}_read_value_slong(xmlNodePtr reader);
double __#{libName}_read_value_double(xmlNodePtr reader);
char *__#{libName}_read_value_str_attr(xmlAttrPtr reader);
const char *__#{libName}_read_value_str_attr_nocopy(xmlAttrPtr reader);
unsigned long __#{libName}_read_value_ulong_attr(xmlAttrPtr reader);
signed long __#{libName}_read_value_slong_attr(xmlAttrPtr reader);
double __#{libName}_read_value_double_attr(xmlAttrPtr reader);
int __#{libName}_acquire_flock(const char* filename, int rdonly);
int __#{libName}_release_flock(const char* filename);
void __#{libName}_fread(void* buf, size_t elSize, int nbElem, FILE* input);
void __#{libName}_fwrite(void* buf, size_t elSize, int nbElem, FILE* input);
void __#{libName}_fseek(FILE *stream, long offset, int whence);

#define __#{libName}_error(str, err, arg...) {								\\
		fprintf(stderr, \"error: #{libName}:\" str \"\\n\", ##arg);			\\
		longjmp(__#{libName}_error_happened, err);} while(0)

extern jmp_buf __#{libName}_error_happened;
extern int __#{libName}_line;
#endif /* __#{libName}_common_h__ */
"
            end
            module_function :genCommonH

            def genCommonC(output, description)
                libName = description.config.libname
                output.puts "
#include <assert.h>
#include <errno.h>
#include <setjmp.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <libxml/xmlreader.h>
#include \"#{libName}.h\"
#include \"_#{libName}/common.h\"

jmp_buf __#{libName}_error_happened;

void *__#{libName}_malloc(unsigned long size)
{
	void *ptr = calloc(1, size);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to allocate memory: %s\\n\", strerror(errno));
        exit(1);
	}
	return ptr;
}

void *__#{libName}_realloc(void *ptr, unsigned long size)
{
	void *nptr = realloc(ptr, size);
	if (nptr == NULL) {
		fprintf(stderr, \"Failed to allocate memory: %s\\n\", strerror(errno));
        exit(1);
	}
	return nptr;
}

void __#{libName}_free(void *ptr)
{
	if (ptr != NULL) {
		free(ptr);
		ptr = NULL;
	}
}

void __#{libName}_fread(void* buf, size_t elSize, int nbElem, FILE* input){
    int ret;
    ret = fread(buf, elSize, nbElem, input);
    if(ret != nbElem){
        __#{libName}_error(\"Failed to read from DB. Invalid format.\", errno);
    }
}

void __#{libName}_fwrite(void* buf, size_t elSize, int nbElem, FILE* input){
    int ret;
    ret = fwrite(buf, elSize, nbElem, input);
    if(ret != nbElem){
        __#{libName}_error(\"Failed to write DB. Invalid format.\", errno);
    }
}

void __#{libName}_fseek(FILE *stream, long offset, int whence){
    int ret;
    ret = fseek(stream, offset, whence);
    if(ret < 0 ){
        __#{libName}_error(\"Failed to read from DB. Invalid format.\", errno);
    }
}

/*************************************
 * HELPER FUNCTIONS
 *************************************/

/**
 * Parsing helper. Compare the node name to expected values.
 * If an expected node is found, (open element), we eat the next node, because
 * the XML parser returns a weird token after each open elemene,t before the value.
 * matches contains an array of expected string. The last entry must be NULL so we now how 
 * many elements there are.
 * @param[in] reader XML Reader
 * @param[in] name Name of the current node
 * @param[in] matches Array of expected string
 * @return ID of the matched string
 * @retval < number of strings Match
 * @retval >= number of string No match found.
 */
int __#{libName}_compare(const char *name, const char *matches[])
{
	int i = 0;
	for (i = 0; matches[i] != NULL; i++) {
		if (!strcmp(name, matches[i])) {
			return i;
		}
	}
	return i;
}

/**
 * Get the value of the current XML node.
 * This is equivalent to #__#{libName}_get_value but the string is duplicate
 * so it won't change when new reads are dont to the XML file.
 * @param[in] reader XML Reader
 * @return Value of the current node 
 */
char *__#{libName}_read_value_str(xmlNodePtr node)
{
	char *val = NULL;
	if (node->children && node->children->content)
		val = strdup((char *)node->children->content);
	return val;
}

/**
 * Get the value of the current XML node as an unsigned long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
unsigned long __#{libName}_read_value_ulong(xmlNodePtr node)
{
	unsigned long val;
	val = strtoul((char *)node->children->content, NULL, 10);
	return val;
}

/**
 * Get the value of the current XML node as an signed long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
signed long __#{libName}_read_value_slong(xmlNodePtr node)
{
	signed long val;
	val = strtol((char *)node->children->content, NULL, 10);
	return val;
}

/**
 * Get the value of the current XML node as a double
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
double __#{libName}_read_value_double(xmlNodePtr node)
{
	double val;
	val = strtod((char *)node->children->content, NULL);
	return val;
}

/**
 * Get the value of the current XML node.
 * This is equivalent to #__#{libName}_get_value but the string is duplicate
 * so it won't change when new reads are dont to the XML file.
 * @param[in] reader XML Reader
 * @return Value of the current node 
 */
char *__#{libName}_read_value_str_attr(xmlAttrPtr node)
{
	char *val = NULL;
	if (node->children && node->children->content)
		val = strdup((char *)node->children->content);
	return val;
}

/**
 * Get the value of the current XML node without duplicating.
 * This is equivalent to #__#{libName}_get_value but the string is duplicate
 * so it won't change when new reads are dont to the XML file.
 * @param[in] reader XML Reader
 * @return Value of the current node 
 */
const char *__#{libName}_read_value_str_attr_nocopy(xmlAttrPtr node)
{
	char *val = NULL;
	if (node->children && node->children->content)
		val = strdup((char *)node->children->content);
	return val;
}

/**
 * Get the value of the current XML node as an unsigned long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
unsigned long __#{libName}_read_value_ulong_attr(xmlAttrPtr node)
{
	unsigned long val;
	val = strtoul((char *)node->children->content, NULL, 10);
	return val;
}

/**
 * Get the value of the current XML node as an unsigned long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
signed long __#{libName}_read_value_slong_attr(xmlAttrPtr node)
{
	signed long val;
	val = strtol((char *)node->children->content, NULL, 10);
	return val;
}

/**
 * Get the value of the current XML node as a double
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
double __#{libName}_read_value_double_attr(xmlAttrPtr node)
{
	double val;
	val = strtod((char *)node->children->content, NULL);
	return val;
}


static FILE* __#{libName}_filelocks[__#{libName.upcase}_MAX_OPENED_FILES];
static char * __#{libName}_filelocks_name[__#{libName.upcase}_MAX_OPENED_FILES];


int __#{libName}_acquire_flock(const char* filename, int rdonly){
	char* lock_file;
	int i, slot=-1;
    struct flock lock;

    for(i = 0; i < __#{libName.upcase}_MAX_OPENED_FILES; i++){
        if(__#{libName}_filelocks_name[i]){
            if(!strcmp(filename, __#{libName}_filelocks_name[i]))
                break;
        } else if(slot == -1) {
            slot = i;
        }
    }
	if(__#{libName.upcase}_MAX_OPENED_FILES != i){
		/* We already have the lock */
		return 0;
	}
    if(slot == -1){
        /* No free slot found... */
        fprintf(stderr, \"Maximum opened #{libName} databses reached\\n\");
        return 1;
    }
     __#{libName}_filelocks_name[slot] = strdup(filename);
	lock_file = malloc(strlen(filename) + 10);
	sprintf(lock_file, \"%s.lock\", filename);
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_pid = getpid();
    if(rdonly){
        lock.l_type = F_RDLCK;
    } else {
        lock.l_type = F_WRLCK;
    }
	__#{libName}_filelocks[slot] = fopen(lock_file, \"w+\");
	free(lock_file);
	if(__#{libName}_filelocks[slot] == NULL){
		return 1;
	}

	while(fcntl(fileno(__#{libName}_filelocks[slot]), F_SETLKW, &lock))
		if(errno != EINTR)
			return 1;

	return 0;
}

int __#{libName}_release_flock(const char* filename){
    struct flock lock;
	int i;
    for(i = 0; i < __#{libName.upcase}_MAX_OPENED_FILES; i++){
        if(__#{libName}_filelocks_name[i]){
            if(!strcmp(filename, __#{libName}_filelocks_name[i]))
                break;
        }
    }

	if(__#{libName.upcase}_MAX_OPENED_FILES == i){
		/* We don't own this lock !  */
		return 1;
	}
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_pid = getpid();
	lock.l_type = F_UNLCK;
	while(fcntl(fileno(__#{libName}_filelocks[i]), F_SETLKW, &lock))
		if(errno != EINTR)
			return 1;
	fclose(__#{libName}_filelocks[i]);
    __#{libName}_filelocks[i] = NULL;
	free(__#{libName}_filelocks_name[i]);
	__#{libName}_filelocks_name[i] = NULL;
	return 0;
}

"
            end
            module_function :genCommonC
        end
    end
end
