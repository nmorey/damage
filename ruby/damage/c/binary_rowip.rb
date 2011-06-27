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
                outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "binary_writer_rowip.c")
                self.genBinaryWriter(outputC, description)
                outputC.close()
                outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "binary_reader_rowip.c")
                self.genBinaryReader(outputC, description)
                outputC.close()

            end
            module_function :write

            private
            def genBinaryGlobalHeader(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_binary_rowip_h__")
                output.puts("#define __#{libName}_binary_rowip_h__\n")
                description.entries.each() {|name, entry|
                    output.printf("unsigned long __#{libName}_%s_binary_dump_file_rowip(__#{libName}_%s *ptr);\n", entry.name, entry.name)
                    output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file_rowip(const char* file, int rdonly);\n\n", entry.name, entry.name)
                }
                output.printf("#define __#{libName.upcase}_ROWIP_PTR(ptr, field) ({typeof(ptr->field) _ptr = NULL; if(ptr->field != NULL) { _ptr = (void*)ptr - ptr->_rowip_pos + ((unsigned long)ptr->field);} _ptr;})\n");
                output.printf("#define __#{libName.upcase}_ROWIP_STR(ptr, field) ({char* _ptr = NULL; if(ptr->field != NULL) { _ptr = (void*)ptr - ptr->_rowip_pos + ((unsigned long)ptr->field + sizeof(uint32_t));} _ptr;})\n");

                output.printf("#define __#{libName.upcase}_ROWIP_PTR_ARRAY(ptr, field, idx) ({typeof(*ptr->field)_ptr = NULL; typeof(ptr->field) _array; if(ptr->field != NULL) { _array =  __#{libName.upcase}_ROWIP_PTR(ptr, field); _ptr = ((void*)ptr - ptr->_rowip_pos) + (unsigned long)(_array[idx]);} _ptr;})\n")

                output.printf("#define __#{libName.upcase}_ROWIP_STR_ARRAY(ptr, field, idx) ({char*_ptr = NULL; uint32_t* _array; if(ptr->field != NULL) { _array =  (uint32_t*)__#{libName.upcase}_ROWIP_PTR(ptr, field); _ptr = ((void*)ptr - ptr->_rowip_pos) + (unsigned long)(_array[idx] + sizeof(uint32_t));} _ptr;})\n")

                output.printf("\n\n");
                output.puts("#endif /* __#{libName}_binary_rowip_h__ */\n")
            end
            module_function :genBinaryGlobalHeader

            def genBinaryHeader(output, description)
                libName = description.config.libname
                output.puts "


static inline __#{libName}_rowip_header* __#{libName}_rowip_header_alloc(){
\t__#{libName}_rowip_header* ptr = __#{libName}_malloc(sizeof(*ptr));
\tptr->filename = NULL;
\tptr->file = NULL;
\tptr->base_adr = NULL;
\tptr->len = 0UL;
\treturn ptr;
}

static inline void __#{libName}_rowip_header_free(__#{libName}_rowip_header* ptr){
\tif(ptr->file != NULL)
\t\tfclose(ptr->file);
\tif(ptr->filename != NULL)
\t\t__#{libName}_free(ptr->filename);

\t__#{libName}_free(ptr);
\treturn;
}
"
            end
            module_function :genBinaryHeader
            def genBinaryWriter(output, description)
                libName = description.config.libname

                output.printf("#include <sys/mman.h>\n")

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include \"binary_rowip.h\"\n")
                output.printf("\n\n") 

                
                description.entries.each() { | name, entry|
                    output.printf("unsigned long __#{libName}_%s_binary_dump_file_rowip(__#{libName}_%s *ptr)\n{\n", entry.name, entry.name)
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

                    output.printf("\t__#{libName}_release_flock(header->filename);\n");
                    output.printf("\tret = header->len;\n")
                    output.printf("\t__#{libName}_rowip_header_free(header);\n")
                    output.printf("\treturn ret;\n");
                    output.printf("}\n");
                }
            end
            module_function :genBinaryWriter
            
            def genBinaryReader(output, description)
                libName = description.config.libname

                output.printf("#include <sys/mman.h>\n")
                output.printf("#include <sys/types.h>\n")
                output.printf("#include <sys/stat.h>\n")
                output.printf("#include <unistd.h>\n")

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include \"binary_rowip.h\"\n")
                output.printf("\n\n") 


                description.entries.each() { | name, entry|
                    output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file_rowip(const char* file, int rdonly)\n{\n", entry.name, entry.name)
                    output.printf("\tint ret;\n")
                    output.printf("\t__#{libName}_rowip_header *header = NULL;\n");
                    output.printf("\t__#{libName}_%s *ptr = NULL;\n", entry.name);
                    output.printf("\tvoid *mapped = NULL;\n");
                    output.printf("\tstruct stat buf;\n");
                    output.printf("\tFILE* output;\n")
                    output.printf("\tint mmap_mode = PROT_READ;\n");
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
                    output.printf("\tif(__#{libName}_acquire_flock(file, rdonly))\n");
                    output.printf("\t\t__#{libName}_error(\"Failed to lock output file %%s\", ENOENT, header->filename);\n");
                    output.printf("\tif((output = fopen(header->filename, \"r+\")) == NULL)\n");
                    output.printf("\t\t__#{libName}_error(\"Failed to open %%s\", errno, header->filename);\n");
                    output.printf("\theader->file = output;\n");

                    output.printf("\tfstat(fileno(header->file), &buf);\n\n");
                    output.printf("\theader->len = buf.st_size;\n");
                    output.printf("\tif(header->len == 0UL)\n");
                    output.printf("\t\t__#{libName}_error(\"File %%s is empty\", EINVAL, header->filename);\n");
                    output.printf("\tmmap_mode |= ((rdonly == 0) ? PROT_WRITE : 0);\n");
                    output.printf("\tif((mapped = mmap(NULL, header->len, mmap_mode, MAP_SHARED, fileno(header->file), 0)) == MAP_FAILED)\n");
                    output.printf("\t\t__#{libName}_error(\"Failed to map %%s: %%s\", errno, header->filename, strerror(errno));\n");
                    output.printf("\theader->base_adr = mapped;\n");
                    output.printf("\tfclose(header->file);\n")

                    output.printf("\theader->file = NULL;\n");
                    output.printf("\tif (rdonly) {\n");
                    output.printf("\t__#{libName}_release_flock();\n");
                    output.printf("\t}\n");

                    output.printf("\tptr = (__#{libName}_%s*)(mapped + sizeof(uint32_t));\n", entry.name)
                    output.printf("\tptr->_rowip = header;\n")
                    output.printf("\treturn ptr;\n");
                    output.printf("}\n");
                }


            end
            module_function :genBinaryReader
        end
    end
end
