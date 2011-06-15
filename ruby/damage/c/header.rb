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
    module Header

      def write(description)
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/", "#{description.config.libname}.h")
        self.genHeader(output, description)
        output.close()
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/_#{description.config.libname}/", "common.h")
        self.genCommonH(output, description)
        output.close()
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "common.c")
        self.genCommonC(output, description)
        output.close()
      end
      module_function :write


      private
      def genHeader(output, description)  
        libName = description.config.libname

        output.puts("#ifndef __#{libName}_h__")
        output.puts("#define __#{libName}_h__\n")
        output.puts("#include <stdio.h>")
        output.puts("#include <libxml/tree.h>")
        output.puts("#include <#{libName}/structs.h>")
        output.puts("#include <#{libName}/alloc.h>")
        description.config.hfiles.each() {|hfile|
          output.puts("#include <#{libName}/#{hfile}>");
        }
        #      output.puts("#include <#{libName}/structs.h")
        output.puts("#endif /* __#{libName}_h__ */\n")
      end
      module_function :genHeader

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

void *__#{libName}_malloc(unsigned long size);
void *__#{libName}_realloc(void *ptr, unsigned long size);
void __#{libName}_free(void *ptr);
int __#{libName}_compare(const char *name, const char *matches[]);
char *__#{libName}_read_value_str(xmlNodePtr reader);
unsigned long __#{libName}_read_value_ulong(xmlNodePtr reader);
double __#{libName}_read_value_double(xmlNodePtr reader);
char *__#{libName}_read_value_str_attr(xmlAttrPtr reader);
unsigned long __#{libName}_read_value_ulong_attr(xmlAttrPtr reader);
double __#{libName}_read_value_double_attr(xmlAttrPtr reader);
int __#{libName}_acquire_flock(const char* filename);
int __#{libName}_release_flock();

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

void *__#{libName}_malloc(unsigned long size)
{
	void *ptr = malloc(size);
	if (ptr == NULL) {
		__#{libName}_error(\"Failed to allocate memory: %s\\n\", errno,
				strerror(errno));
	}
	return ptr;
}

void *__#{libName}_realloc(void *ptr, unsigned long size)
{
	void *nptr = realloc(ptr, size);
	if (nptr == NULL) {
		__#{libName}_error(\"Failed to reallocate memory: %s\\n\", errno,
				strerror(errno));
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

static struct flock lock;
static FILE* __#{libName}_filelock = NULL;


int __#{libName}_acquire_flock(const char* filename){
	char* lock_file;
	
	if(__#{libName}_filelock != NULL){
		/* We already have the lock */
		return 0;
	}
	lock_file = malloc(strlen(filename) + 10);
	sprintf(lock_file, \"%s.lock\", filename);
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;
	lock.l_pid = getpid();
	lock.l_type = F_WRLCK;
	__#{libName}_filelock = fopen(lock_file, \"w+\");
	free(lock_file);
	if(__#{libName}_filelock == NULL){
		return 1;
	}
	while(fcntl(fileno(__#{libName}_filelock), F_SETLKW, &lock))
		if(errno != EINTR)
			return 1;

	return 0;
}

int __#{libName}_release_flock(){
	lock.l_type = F_UNLCK;
	while(fcntl(fileno(__#{libName}_filelock), F_SETLKW, &lock))
		if(errno != EINTR)
			return 1;
	fclose(__#{libName}_filelock);
	__#{libName}_filelock = NULL;
	return 0;
}

"
      end
      module_function :genCommonC
    end
  end
end
