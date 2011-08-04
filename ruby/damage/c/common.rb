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
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/_#{description.config.libname}/", "_common.h")
                self.genCommonH(output, description)
                output.close()
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", "common.h")
                self.genPublicCommonH(output, description)
                output.close()


                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "common.c")
                self.genCommonC(output, description)
                output.close()
            end
            module_function :write


            private
           def genPublicCommonH(output, description)
                libName = description.config.libname
                output.puts "
#ifndef __#{libName}_common_h__
#define __#{libName}_common_h__

/**
 * Acquire a lock on a #{libName} file (stalls if lock is not ready) .
 * This is automatically used by standard readers/writers
 * and it should not be necessary to call it manually.
 * Note that acquiring the lock is acquirable if it already belong to the calling process.
 * @param[in] filename DB file name
 * @param[in] rdonly Is lock read only?
 * @return Pointer to open file
 * @retval NULL Error
 */
FILE* __#{libName}_acquire_flock(const char* filename, int rdonly);

/**
 * Release a lock on a #{libName} file acquire by #__#{libName}_acquire_flock.
 * This should be called when the last required write to the DB was done without unlocking it.
 * However the DB lock is automatically release when the process exits.
 * @param[in] filename DB filename
 * @return Error code
 * @retval 0 Success
 * @retval 1 Error
 */
int __#{libName}_release_flock(const char* filename);

#endif /* __#{libName}_common_h__ */
"
            end

            def genCommonH(output, description)
                libName = description.config.libname
                output.puts "
#ifndef ___#{libName}_common_h__
#define ___#{libName}_common_h__

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include <libxml/xmlreader.h>

void *__#{libName}_malloc(unsigned long size);
char *__#{libName}_strdup(const char* str);
void *__#{libName}_realloc(void *ptr, unsigned long size);
void __#{libName}_free(void *ptr);
int __#{libName}_compare(const char *name, const char *matches[]);

char *__#{libName}_read_value_str(xmlNodePtr reader);
unsigned long __#{libName}_read_value_ulong(xmlNodePtr reader);
unsigned long long __#{libName}_read_value_ullong(xmlNodePtr reader);
signed long __#{libName}_read_value_slong(xmlNodePtr reader);
signed long long __#{libName}_read_value_sllong(xmlNodePtr reader);
double __#{libName}_read_value_double(xmlNodePtr reader);

char *__#{libName}_read_value_str_attr(xmlAttrPtr reader);
const char *__#{libName}_read_value_str_attr_nocopy(xmlAttrPtr reader);
unsigned long __#{libName}_read_value_ulong_attr(xmlAttrPtr reader);
signed long __#{libName}_read_value_slong_attr(xmlAttrPtr reader);
unsigned long long __#{libName}_read_value_ullong_attr(xmlAttrPtr reader);
signed long long __#{libName}_read_value_sllong_attr(xmlAttrPtr reader);
double __#{libName}_read_value_double_attr(xmlAttrPtr reader);

void __#{libName}_fread(void* buf, size_t elSize, int nbElem, FILE* input);
void __#{libName}_fwrite(void* buf, size_t elSize, int nbElem, FILE* input);
void __#{libName}_fseek(FILE *stream, long offset, int whence);

void __#{libName}_paddOutput(FILE* file, int indent, int listable, int first);

#define __#{libName}_error(str, err, arg...) {								\\
		fprintf(stderr, \"error: #{libName}:\" str \"\\n\", ##arg);			\\
		longjmp(__#{libName}_error_happened, err);} while(0)

extern jmp_buf __#{libName}_error_happened;
extern int __#{libName}_line;
#endif /* ___#{libName}_common_h__ */
"
            end
            module_function :genCommonH, :genPublicCommonH

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
#include \"_#{libName}/_common.h\"

jmp_buf __#{libName}_error_happened;

/** Represent a lock of a #{libName} DB file */
typedef struct ___#{libName}_db_lock{
    /** Pointer to the open file (used for lock) */
    FILE* file;
    /** Name of the DB file */
    char* name;
    /** Pointer to the next lock */
    struct ___#{libName}_db_lock* next;
    /** File mode */
    int rdonly;
} __#{libName}_db_lock;

void *__#{libName}_malloc(unsigned long size)
{
	void *ptr = calloc(1, size);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to allocate memory: %s\\n\", strerror(errno));
        exit(1);
	}
	return ptr;
}
char *__#{libName}_strdup(const char* str)
{
	char *ptr = strdup(str);
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

void __#{libName}_paddOutput(FILE* file, int indent, int listable, int first){
    int i;
    for(i = 0; i < indent; i++){
        fprintf(file, \"\\t\");
    }
    if(listable){
        if(first){
            fprintf(file, \"- \");
        } else {
            fprintf(file, \"  \");
        }
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
 * Get the value of the current XML node as an unsigned long long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
unsigned long long __#{libName}_read_value_ullong(xmlNodePtr node)
{
	unsigned long long val;
	val = strtoull((char *)node->children->content, NULL, 10);
	return val;
}

/**
 * Get the value of the current XML node as an signed long long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
signed long long  __#{libName}_read_value_sllong(xmlNodePtr node)
{
	signed long long val;
	val = strtoll((char *)node->children->content, NULL, 10);
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
		val = ((char *)node->children->content);
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
 * Get the value of the current XML node as a signed long
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
 * Get the value of the current XML node as an unsigned long long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
unsigned long long __#{libName}_read_value_ullong_attr(xmlAttrPtr node)
{
	unsigned long long val;
	val = strtoull((char *)node->children->content, NULL, 10);
	return val;
}

/**
 * Get the value of the current XML node as a signed long long
 * @param[in] reader XML Reader
 * @return Value of the current node
 */
signed long long __#{libName}_read_value_sllong_attr(xmlAttrPtr node)
{
	signed long long val;
	val = strtoll((char *)node->children->content, NULL, 10);
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

static __#{libName}_db_lock* lockedDBs = NULL;;

static inline void __#{libName}_free_dblock(__#{libName}_db_lock* dbLock)
{
	fclose(dbLock->file);
	free(dbLock->name);
	free(dbLock);

}
FILE* __#{libName}_acquire_flock(const char* filename, int rdonly){
	__#{libName}_db_lock* dbLock;
   struct flock lock;

    if(filename == NULL){
        return NULL;
    }

    for(dbLock = lockedDBs; dbLock; dbLock=dbLock->next){
            if(!strcmp(filename, dbLock->name))
                break;
    }

    if(dbLock && dbLock->rdonly == 1 && rdonly == 0){
        /* File was locked in readonly. We can't allow to open in RW */
        return NULL;
    } else if(!dbLock){
        dbLock = malloc(sizeof(*dbLock));
        if(!dbLock)
            return NULL;
        dbLock->next = lockedDBs;
        dbLock->name = strdup(filename);
        dbLock->rdonly = rdonly;
        if(!dbLock->name){
            free(dbLock);
            return NULL;
        }
        dbLock->file = fopen(dbLock->name, rdonly ? \"r\" : \"r+\");
        if(!dbLock->file && rdonly == 0){
            dbLock->file = fopen(dbLock->name, \"w+\");
        }
        if(!dbLock->file){
            free(dbLock->name);
            free(dbLock);
            return NULL;
        }
	} else {
        /* We already got the lock ! */
        return dbLock->file;
    }

	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_pid = getpid();
    if(rdonly){
        lock.l_type = F_RDLCK;
    } else {
        lock.l_type = F_WRLCK;
    }

	while(fcntl(fileno(dbLock->file), F_SETLKW, &lock))
		if(errno != EINTR){
            __#{libName}_free_dblock(dbLock);
			return NULL;
        }

    lockedDBs = dbLock;
    fseek(dbLock->file, 0, SEEK_SET);
	return dbLock->file;
}

int __#{libName}_release_flock(const char* filename){
	__#{libName}_db_lock* dbLock;
	__#{libName}_db_lock** dbPred;
    struct flock lock;

    for(dbLock = lockedDBs, dbPred=&(lockedDBs); dbLock; dbPred=&(dbLock->next), dbLock=dbLock->next){
            if(!strcmp(filename, dbLock->name))
                break;
    }
	if(!dbLock){
		/* We don't own this lock !  */
		return 1;
	}

    *dbPred=dbLock->next;

	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_pid = getpid();
	lock.l_type = F_UNLCK;

	while(fcntl(fileno(dbLock->file), F_SETLKW, &lock))
		if(errno != EINTR)
			return 1;

    __#{libName}_free_dblock(dbLock);
	return 0;
}

"
            end
            module_function :genCommonC
        end
    end
end
