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
    module Java
        require File.dirname(__FILE__) + '/java/header'
        require File.dirname(__FILE__) + '/java/enum'
	require File.dirname(__FILE__) + '/java/xml_reader'
        require File.dirname(__FILE__) + '/java/alloc'
        require File.dirname(__FILE__) + '/java/binary_reader'
        require File.dirname(__FILE__) + '/java/dump'
        require File.dirname(__FILE__) + '/java/parser_options'
        
        def generate(description, pahole)
            libName = description.config.libname
            version = description.config.version;
            pom =  Damage::Files.createAndOpen("gen/#{libName}/java/", "pom.xml")
            pom.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<project xmlns=\"http://maven.apache.org/POM/4.0.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
   xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\">
<modelVersion>4.0.0</modelVersion>
  <groupId>#{libName}</groupId>
  <artifactId>#{libName}</artifactId>
  <version>#{version}</version>
  <packaging>jar</packaging>
  <dependencies>
    <dependency>
  		<groupId>dom4j</groupId>
  		<artifactId>dom4j</artifactId>
  		<version>1.6.1</version>
	</dependency>
  </dependencies>    
  <build>
    <sourceDirectory>src</sourceDirectory>
    <outputDirectory>bin</outputDirectory>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>2.3</version>
        <configuration>
          <classesDirectory>bin</classesDirectory>
          <finalName>#{libName}</finalName>
        </configuration>
      </plugin>
    </plugins>
  </build>
  
</project>");
            
            outdir = "gen/#{libName}/java/src/"
            description.config.package.split(".").each() { |dir|
                outdir += dir + "/"
            }
            outdir += libName + "/"
            uppercaseLibName = libName.slice(0,1).upcase + libName.slice(1..-1)
            ivisitorOutput = Damage::Files.createAndOpen(outdir, "I#{uppercaseLibName}ObjectVisitor.java") 
            ivisitorOutput.puts("package #{description.config.package}.#{libName};
          
/**
 * Visitor (see http://en.wikipedia.org/wiki/Visitor_pattern)
 * @author xraynaud@kalray.eu
 *
 */
public interface I#{uppercaseLibName}ObjectVisitor {
  ");
            
            visitorOutput = Damage::Files.createAndOpen(outdir, "Default#{uppercaseLibName}ObjectVisitor.java")
            visitorOutput.puts("package #{description.config.package}.#{libName};
            
  /**
   * Default Visitor implementation (see http://en.wikipedia.org/wiki/Visitor_pattern)
   * @author xraynaud@kalray.eu
   *
   */
  public class Default#{uppercaseLibName}ObjectVisitor implements I#{uppercaseLibName}ObjectVisitor {
    ");

            description.entries.each(){ |name, entry|
                raise("Missing size info") if pahole.entries[name] == nil
                params = nameToParams(description, name)
                output = Damage::Files.createAndOpen(outdir, "#{params[:class]}.java") 
                Header::write(output, libName, entry, pahole.entries[name], params)
                Enum::write(output, libName, entry, pahole.entries[name], params)
                Alloc::write(output, libName, entry, pahole.entries[name], params)
                BinaryReader::write(output, libName, entry, pahole.entries[name], params)
		XmlReader::write(output, libName, entry, pahole.entries[name], params)
                Dump::write(output, libName, entry, pahole.entries[name], params)

                ParserOptions::write(description)
                output.puts("\n}\n\n")
                output.close()
                ivisitorOutput.printf("\tpublic void visit(%s obj);\n\n", "#{params[:class]}")
                visitorOutput.printf("\t@Override\n")
                visitorOutput.printf("\tpublic void visit(%s obj) {}\n\n", "#{params[:class]}")
            }
            output = Damage::Files.createAndOpen(outdir, "#{uppercaseLibName}Object.java") 
            output.puts("package #{description.config.package}.#{libName};

import java.util.HashMap;
import java.io.InputStream;
import java.io.EOFException;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.Charset;

public abstract class #{uppercaseLibName}Object {

	/** damage_version */
	public static final String DAMAGE_VERSION = \"#{description.config.damage_version}\";

	/**
	 * Annotations
	 * Developer can put any Object in this map.
	 */
	private HashMap<Object, Object> m_annotations;

	/**
	 * Constructor
	 */
	public #{uppercaseLibName}Object() {
	}

	/**
	 * Gets the annotation fir the given key.
	 */
	public Object getAnnotation(Object key) {
		if (m_annotations != null) {
			return m_annotations.get(key);
 		}
 		return null;
	}

	/**
	 * Set an annotation to this #{uppercaseLibName}Object
	 * @return the previous one, if any.
	 */
	public Object setAnnotation(Object key, Object object) {
		if (m_annotations == null) {
 			m_annotations = new HashMap<Object, Object>();
 		}
		return m_annotations.put(key, object);
	}

	/**
	 * Each #{uppercaseLibName}Object must implement this method
	 */
	public abstract void visit(I#{uppercaseLibName}ObjectVisitor v);

	/**
	 * Read from given inputstream until the given array is full.
	 */
	public static void readFully(InputStream is, byte[] array) throws IOException {
		int nbytes = 0;
		while (nbytes <array.length) {
			int count = is.read(array, nbytes, array.length - nbytes);
			if (count < 0) throw new EOFException();
			nbytes += count;
		}
	}
	
	/**
	 * Read from given inputstream until the given array is full,
	 * and return a ByteBuffer wrapping the byte array
	 */
	public static ByteBuffer fillByteBuffer(InputStream is, byte[] array) throws IOException {
		readFully(is, array);
		ByteBuffer in = ByteBuffer.wrap(array);
		in.order(ByteOrder.LITTLE_ENDIAN);
		return in;
	}
	
	/** 
	 * Read a string from given inputstream
	 */
	public static String readString(InputStream is) throws IOException {
		ByteBuffer bb = fillByteBuffer(is, new byte[4]);
		int strLen = bb.getInt(0);
		String ret = null;
		if (strLen > 1) {
			byte[] array = new byte[strLen-1];
			readFully(is, array);
			// reads end of String
			if (is.read() == -1) throw new EOFException();
			ret = new String(array, Charset.forName(\"UTF-8\"));
		} else if (strLen == 1) {
			if (is.read() == -1) throw new EOFException();
			ret = \"\";
		}
		return ret;
	}

	/**
	 * Intendation method, used when dumping objects.
	 */ 
	public static void indentToString(int indent, boolean listable, boolean first) {
		for (int i = 0; i < indent; ++i) {
                	System.out.print('\\t');
		}
		if (listable == true) {
			if (first == true) {
				System.out.print(\"- \");
			} else {
				System.out.print(\"  \");
			}
		}
	}
}");
 
            output.close();

            ivisitorOutput.puts("}\n");
            visitorOutput.puts("}\n");
            ivisitorOutput.close();
            visitorOutput.close();
            
        end
        module_function :generate

        def nameToParams(description, name)
            params={}
            params[:package] = description.config.package + "." + description.config.libname
            params[:version] = description.config.version
            params[:damage_version] = description.config.damage_version

            params[:class] = name.slice(0,1).upcase + name.slice(1..-1)
            params[:bin_header] = description.pahole.entries["binary_header"]
            return params
        end
        module_function :nameToParams
    end
end
