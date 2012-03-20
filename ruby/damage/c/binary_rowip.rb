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
        module BinaryRowip

            def write(description)
                outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", "binary_rowip.h")
                self.genBinaryGlobalHeader(outputC, description)
                outputC.close()
                outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "binary_rowip.h")
                self.genBinaryHeader(outputC, description)
                outputC.close()
                description.entries.each() { |name, entry|
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_writer_rowip__#{name}.c")
                    self.genBinaryWriter(outputC, description, entry)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader_rowip__#{name}.c")
                    self.genBinaryReader(outputC, description, entry)
                    outputC.close()
                }

            end
            module_function :write

            private
            def genBinaryGlobalHeader(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_binary_rowip_h__")
                output.puts("#define __#{libName}_binary_rowip_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_rowip Binary ROWIP (Read Or Write In Place) API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Write a complete #__#{libName}_#{entry.name} structure and its children in binary form from a file in ROWIP mode.
 * ROWIP (Read Or Write-In-Place) is a fast access mode that mapped the whole file in memory.
 * To write in ROWIP mode, the structure *MUST* have been obtained by using #__#{libName}_#{entry.name}* #__#{libName}_#{entry.name}_binary_load_file_rowip
 * @param[in] ptr Structure to write
 * @param[in] opts Options to writer (compression, read-only, etc)
 * @return Amount of bytes wrote to file
 * @retval 0 in case of error
 */");
                    output.printf("unsigned long __#{libName}_%s_binary_dump_file_rowip(__#{libName}_%s *ptr, __#{libName}_options opts);\n", entry.name, entry.name)

                    output.puts("
/**
 * Read a complete #__#{libName}_#{entry.name} structure and its children in binary form from a file in ROWIP mode.
 * ROWIP (Read Or Write-In-Place) is a fast access mode that mapped the whole file in memory.
 * It allows a very fast loading of the DB but has several restriction:
 *     - Access to \"pointers\" or arrays within structs must be done through the  __#{libName.upcase}_ROWIP described later in the file
 *     - There can be no pointer or array changes in the structures
 *     - Changes to values (char within string) or numerals are allowed.
 * @param[in] file Filename
 * @param[in] opts Options to parser (compression, read-only, etc)
 * @return Pointer to a #__#{libName}_#{entry.name} structure
 * @retval NULL Failed to read the file
 * @retval !=NULL Valid structure
 */");
                    output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file_rowip(const char* file, __#{libName}_options opts);\n\n", entry.name, entry.name)
                }

                output.puts("
/**
 * Access a __#{libName} structure within a struct in ROWIP mode
 * @param[in] ptr Pointer to the structure
 * @param[in] field Field name
 * @return Pointer to the structure pointed by ptr->field
 */");
                output.printf("#define __#{libName.upcase}_ROWIP_PTR(ptr, field) ({typeof(ptr->field) _ptr = NULL; if(ptr->field != NULL) { _ptr = (void*)ptr - ptr->_rowip_pos + ((unsigned long)ptr->field);} _ptr;})\n");


                output.puts("
/**
 * Access a string within a struct in ROWIP mode
 * @param[in] ptr Pointer to the structure
 * @param[in] field Field name
 * @return Pointer to the string pointed by ptr->field
 */");
                output.printf("#define __#{libName.upcase}_ROWIP_STR(ptr, field) ({char* _ptr = NULL; if(ptr->field != NULL) { _ptr = (void*)ptr - ptr->_rowip_pos + ((unsigned long)ptr->field + sizeof(uint32_t));} _ptr;})\n");

                output.puts("
/**
 * Access a __#{libName} structure or a straight value stored in an array within a struct in ROWIP mode
 * @param[in] ptr Pointer to the structure
 * @param[in] field Field name
 * @param[in] idx Position of the value in the array
 * @return Pointer to the structure pointed by or the value stored at ptr->field[idx]
 */");
                output.printf("#define __#{libName.upcase}_ROWIP_PTR_ARRAY(ptr, field, idx) ({typeof(*ptr->field)_ptr = NULL; typeof(ptr->field) _array; if(ptr->field != NULL) { _array =  __#{libName.upcase}_ROWIP_PTR(ptr, field); _ptr = ((void*)ptr - ptr->_rowip_pos) + (unsigned long)(_array[idx]);} _ptr;})\n")

                output.puts("
/**
 * Access a string stored in an array within a struct in ROWIP mode
 * @param[in] ptr Pointer to the structure
 * @param[in] field Field name
 * @param[in] idx Position of the string in the array
 * @return Pointer to the string stored at ptr->field[idx]
 */");

                output.printf("#define __#{libName.upcase}_ROWIP_STR_ARRAY(ptr, field, idx) ({char*_ptr = NULL; uint32_t* _array; if(ptr->field != NULL) { _array =  (uint32_t*)__#{libName.upcase}_ROWIP_PTR(ptr, field); _ptr = ((void*)ptr - ptr->_rowip_pos) + (unsigned long)(_array[idx] + sizeof(uint32_t));} _ptr;})\n")

                output.printf("\n\n");

                output.puts("
/** @} */
/** @} */
")
                output.puts("#endif /* __#{libName}_binary_rowip_h__ */\n")
            end
            module_function :genBinaryGlobalHeader

            def genBinaryHeader(output, description)
                libName = description.config.libname
                output.puts "

#ifndef ___#{libName}_binary_rowip_internals
#define ___#{libName}_binary_rowip_internals
static inline __#{libName}_rowip_header* __#{libName}_rowip_header_alloc(){
\t__#{libName}_rowip_header* ptr = __#{libName}_malloc(sizeof(*ptr));
\tptr->filename = NULL;
\tptr->file = -1;
\tptr->base_adr = NULL;
\tptr->len = 0UL;
\treturn ptr;
}

static inline void __#{libName}_rowip_header_free(__#{libName}_rowip_header* ptr){
\tif(ptr->filename != NULL)
\t\t__#{libName}_free(ptr->filename);

\t__#{libName}_free(ptr);
\treturn;
}
#endif /* ___#{libName}_binary_rowip_internals */
"
            end
            module_function :genBinaryHeader
            def genBinaryWriter(output, description, entry)
                libName = description.config.libname

                output.printf("#include <sys/mman.h>\n")

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("#include \"src/binary_rowip.h\"\n")
               output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_rowip Binary ROWIP (Read Or Write In Place) API
 * @{
 **/
");
                
                output.printf("unsigned long __#{libName}_%s_binary_dump_file_rowip(__#{libName}_%s *ptr, __#{libName}_options opts)\n{\n", entry.name, entry.name)
                output.printf("\tunsigned long ret; int r;\n")
                output.printf("\t__#{libName}_rowip_header *header = (__#{libName}_rowip_header*)ptr->_rowip;\n");
                output.printf("\n")
                output.printf("\tif(ptr->_rowip == NULL)\n");
                output.printf("\t\treturn 0UL;\n\n");

                output.printf("\tr = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (r != 0) {\n");
                output.printf("\t\terrno = r;\n");
                output.printf("\t\treturn 0UL;\n");
                output.printf("\t}\n\n");

                output.printf("\tif((r = msync(header->base_adr, header->len, MS_SYNC)) != 0)\n", entry.name)
                output.printf("\t\t__#{libName}_error(\"Failed to sync output file %%s\", errno, header->filename);\n");

                output.printf("\tif((r = munmap(header->base_adr, header->len)) != 0)\n", entry.name)
                output.printf("\t\t__#{libName}_error(\"Failed to unmap output file %%s\", errno, header->filename);\n");

                output.printf("\tret = header->len;\n")

                output.printf("\tif((opts & __#{libName.upcase}_OPTION_KEEPLOCKED) == 0){\n");
                output.printf("\t\t__#{libName}_release_flock(header->filename);\n");
                output.printf("\t\t__#{libName}_rowip_header_free(header);\n")
                output.printf("\t}\n");
                output.printf("\treturn ret;\n");
                output.printf("}\n");

                output.puts("
/** @} */
/** @} */
")
                
            end
            module_function :genBinaryWriter
            
            def genBinaryReader(output, description, entry)
                libName = description.config.libname

                output.printf("#include <sys/mman.h>\n")
                output.printf("#include <sys/types.h>\n")
                output.printf("#include <sys/stat.h>\n")
                output.printf("#include <unistd.h>\n")

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("#include \"src/binary_rowip.h\"\n")
               output.printf("\n\n") 

                output.puts("
/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_rowip Binary ROWIP (Read Or Write In Place) API
 * @{
 **/
");


                output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file_rowip(const char* file, __#{libName}_options opts)\n{\n", entry.name, entry.name)
                output.printf("\tint ret;\n")
                output.printf("\t__#{libName}_rowip_header *header = NULL;\n");
                output.printf("\t__#{libName}_%s *ptr = NULL;\n", entry.name);
                output.printf("\tvoid *mapped = NULL;\n");
                output.printf("\tstruct stat buf;\n");
                output.printf("\tint output;\n")
                output.printf("\n")

                output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (ret != 0) {\n");
                output.printf("\t\tif (header != NULL)\n");
                output.printf("\t\t\t__#{libName}_rowip_header_free(header);\n");
                output.printf("\t\terrno = ret;\n");
                output.printf("\t\treturn NULL;\n");
                output.printf("\t}\n\n");

                output.printf("\theader = __#{libName}_rowip_header_alloc();\n\n");
                output.printf("\theader->filename = strdup(file);\n");
                output.printf("\tif((output = __sigmacDB_open_fd(header->filename, opts & __#{libName.upcase}_OPTION_READONLY)) == -1)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to open %%s\", errno, header->filename);\n");
                output.printf("\theader->file = output;\n");

                output.printf("\tfstat(header->file, &buf);\n\n");
                output.printf("\theader->len = buf.st_size;\n");
                output.printf("\tif(header->len == 0UL)\n");
                output.printf("\t\t__#{libName}_error(\"File %%s is empty\", EINVAL, header->filename);\n");
                output.printf("\tif((mapped = mmap(NULL, header->len, PROT_READ|PROT_WRITE, MAP_SHARED, header->file, 0)) == MAP_FAILED)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to map %%s: %%s\", errno, header->filename, strerror(errno));\n");
                output.printf("\theader->base_adr = mapped;\n");

                output.printf("\tif ((opts & __#{libName.upcase}_OPTION_READONLY)) {\n");
                output.printf("\t__#{libName}_release_flock(file);\n");
                output.printf("\t}\n");

                output.printf("\tptr = (__#{libName}_%s*)(mapped + sizeof(uint32_t));\n", entry.name)
                output.printf("\tptr->_rowip = header;\n")
                output.printf("\treturn ptr;\n");
                output.printf("}\n");


                output.puts("
/** @} */
/** @} */
")
                
            end
            module_function :genBinaryReader
        end
    end
end
