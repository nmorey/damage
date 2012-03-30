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
	require File.dirname(__FILE__) + '/java/xml_writer'
	require File.dirname(__FILE__) + '/java/offset'
        require File.dirname(__FILE__) + '/java/alloc'
        require File.dirname(__FILE__) + '/java/binary_reader'
        require File.dirname(__FILE__) + '/java/binary_writer'
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

            delegateVisitorOutput = Damage::Files.createAndOpen(outdir, "Delegate#{uppercaseLibName}ObjectVisitor.java")
            delegateVisitorOutput.puts("package #{description.config.package}.#{libName};
            
  /**
   * Delegate Visitor implementation (see http://en.wikipedia.org/wiki/Visitor_pattern)
   * @author xraynaud@kalray.eu
   *
   */
  public class Delegate#{uppercaseLibName}ObjectVisitor extends Default#{uppercaseLibName}ObjectVisitor {
	
	private I#{uppercaseLibName}ObjectVisitor delegateVisitor;

	public Delegate#{uppercaseLibName}ObjectVisitor() {
	}

	/**
	 * @return the delegateVisitor
	 */
	public ISigmacDBObjectVisitor getDelegateVisitor() {
		return delegateVisitor;
	}

	/**
	 * @param delegateVisitor the delegateVisitor to set
	 */
	public void setDelegateVisitor(ISigmacDBObjectVisitor delegateVisitor) {
		this.delegateVisitor = delegateVisitor;
	}

    ");


            description.entries.each(){ |name, entry|
                raise("Missing size info") if pahole.entries[name] == nil
                params = nameToParams(description, name)
                output = Damage::Files.createAndOpen(outdir, "#{params[:class]}.java") 
                Header::write(output, libName, entry, pahole.entries[name], params)
                Enum::write(output, libName, entry, pahole.entries[name], params)
                Alloc::write(output, libName, entry, pahole.entries[name], params)
                BinaryReader::write(output, libName, entry, pahole.entries[name], params)
                BinaryWriter::write(output, libName, entry, pahole.entries[name], params)
                XmlReader::write(output, libName, entry, pahole.entries[name], params)
                XmlWriter::write(output, libName, entry, pahole.entries[name], params)
                Offset::write(output, libName, entry, pahole.entries[name], params)
                Dump::write(output, libName, entry, pahole.entries[name], params)

                ParserOptions::write(description)
                output.puts("\n}\n\n")
                output.close()
                ivisitorOutput.printf("\tpublic void visit(%s obj);\n\n", "#{params[:class]}")
                visitorOutput.printf("\t@Override\n")
                visitorOutput.printf("\tpublic void visit(%s obj) {}\n\n", "#{params[:class]}")
		delegateVisitorOutput.printf("\t@Override\n")
		delegateVisitorOutput.printf("\tpublic void visit(%s obj) {\n", "#{params[:class]}")
		delegateVisitorOutput.printf("\t\tif (delegateVisitor != null) delegateVisitor.visit(obj);\n")
		delegateVisitorOutput.printf("\t}\n\n")
            }
            output = Damage::Files.createAndOpen(outdir, "#{uppercaseLibName}Object.java") 
            output.puts("package #{description.config.package}.#{libName};

import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;

import org.dom4j.Element;
import org.dom4j.dom.DOMElement;

public abstract class #{uppercaseLibName}Object {

	/** damage_version */
	public static final String DAMAGE_VERSION = \"#{description.config.damage_version}\";
  public static final Charset UTF8_CHARSET = Charset.forName(\"UTF-8\");

	/**
	 * Annotations
	 * Developer can put any Object in this map.
	 */
	private java.util.Map<Object, Object> m_annotations;

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
	 * Set an annotation to this #{uppercaseLibName}Object.
   * Note: method optimized to use the better Map instance, according to the number of elements stored.
	 * @return the previous one, if any.
	 */
  public Object setAnnotation(Object key, Object value) {
    if (m_annotations == null || m_annotations.size() == 0) {
      m_annotations = java.util.Collections.singletonMap(key, value);
      return null;
    } else if (m_annotations.size() == 1) {
      java.util.Map.Entry<Object, Object> entry = m_annotations.entrySet().iterator().next();
      if (key.equals(entry.getKey())) {
        m_annotations = java.util.Collections.singletonMap(key, value);
        return entry.getValue();
      } else {
        m_annotations = new java.util.HashMap<Object, Object>(m_annotations);
      }
    }
    return m_annotations.put(key, value);
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
			ret = new String(array, UTF8_CHARSET).intern();
		} else if (strLen == 1) {
			if (is.read() == -1) throw new EOFException();
			ret = \"\";
		}
		return ret;
	}

  /** 
   * Read a string from given inputstream
   */
  public static String readString(FileChannel fc) throws IOException {
    int nbytes;
    String ret = null;
    ByteBuffer bb = ByteBuffer.allocate(4);
    bb.order(ByteOrder.LITTLE_ENDIAN);
    do {
      nbytes = fc.read(bb);
    } while(nbytes != -1 && bb.hasRemaining());
    if(nbytes == -1 && bb.hasRemaining())
      throw new EOFException(\"Unexpected EOF at offset \" + fc.position());
    int strLen = bb.getInt(0);
    if (strLen > 1) {
      byte[] strCopy = new byte[strLen - 1];
      bb = ByteBuffer.allocate(strLen);
      bb.order(ByteOrder.LITTLE_ENDIAN);
      do {
        nbytes = fc.read(bb);
      } while(nbytes != -1 && bb.hasRemaining());

      if(nbytes == -1 && bb.hasRemaining())
        throw new EOFException(\"Unexpected EOF at offset \" + fc.position());
      bb.position(0);
      bb.get(strCopy);
      ret = new String(strCopy, UTF8_CHARSET).intern();
    } else if (strLen == 1) {
      ret = \"\";
      bb = ByteBuffer.allocate(1);
      do {
        nbytes = fc.read(bb);
      } while(nbytes != -1 && bb.hasRemaining());
    }
    return ret;
  }

	/**
	 * Intendation method, used when dumping objects.
	 */ 
	public static void indentToString(PrintStream ps, int indent, boolean listable, boolean first) {
		for (int i = 0; i < indent; ++i) {
                	ps.print('\\t');
		}
		if (listable == true) {
			if (first == true) {
				ps.print(\"- \");
			} else {
				ps.print(\"  \");
			}
		}
	}
            
  /**
   * Intendation method, used when dumping objects.
   */ 
  public static void indent(java.io.Writer w, int indent) throws IOException {
    for (int i = 0; i < indent; ++i) {
         w.write(' ');
    }
  }
	
	/**
	 * Dumps a human readable description of this object in console
         */
	public void dump(){
		dump(System.out);
	}

 /**
  * Dumps a human readable description of this object in console
  */
  public org.dom4j.QName createQName(String s, java.util.Map<String, org.dom4j.QName> map){
    org.dom4j.QName ret = map.get(s);
    if (ret == null) {
      ret = new org.dom4j.QName(s);
      map.put(s, ret);
    }
    return ret;
  }
            
	/**
         * Dumps a human readable description of this object in given PrintStream
         */
	public abstract void dump(PrintStream ps);

	/**
	 * XML Writer
	 * @return a DOM Element
	 */
	public abstract DOMElement xmlWrite();

  /**
   * Populate this object (expected virgin object)
   * @param el and XML Element
   */
  public abstract void populateFromXMLElement(Element el);

    /**
     * Compute length of string in binary mode
     * @return Offset increment
     */
     public int computeStringLength(String str){
          if(str == null)
              return 4 /* Size of strlen */;
          return str.length() + 1 + 4 /* Size of strlen */;
     }

    /**
     * Compute length of string Array in binary mode
     * @return Offset increment
     */
     public int computeStringArrayLength(String str[]){
          int total_len = 0;
          if(str == null)
              return 0;
          int i; for(i = 0; i < str.length; i++){
              total_len += computeStringLength(str[i]);
          }
          return total_len;
     }
    /**
     * Write a string in binary format to a DataOutputStream
     * @return Nothing
     */
     public void writeStringToFile(DataOutputStream output, String str) throws IOException {
          if(str != null){
              ByteBuffer struct = ByteBuffer.allocate(4);
              struct.order(ByteOrder.LITTLE_ENDIAN);
              struct.putLong(0, str.length() + 1);
              output.write(struct.array(), 0, 4);
              output.writeBytes(str);
          } else {
              output.writeInt(4);
          }   
          output.writeByte(0);
     }
    /**
     * Write a string array in binary format to a DataOutputStream
     * @return Nothing
     */
     public void writeStringArrayToFile(DataOutputStream output, String str[]) throws IOException {
          if(str == null || str.length == 0){
             output.writeInt(0);
             return;
          }
          ByteBuffer struct = ByteBuffer.allocate(4);
          struct.order(ByteOrder.LITTLE_ENDIAN);
          struct.putLong(0, str.length);
          output.write(struct.array(), 0, 4);
          int i; for(i = 0; i < str.length; i++){
              writeStringToFile(output, str[i]);
          }
     }
}");
 
            output.close();

            ivisitorOutput.puts("}\n");
            visitorOutput.puts("}\n");
            delegateVisitorOutput.puts("}\n");
            ivisitorOutput.close();
            visitorOutput.close();
            delegateVisitorOutput.close();
        end
        module_function :generate

        def nameToParams(description, name)
            params={}
            params[:package] = description.config.package + "." + description.config.libname
            params[:uppercase_libname] = description.config.libname.slice(0,1).upcase + description.config.libname.slice(1..-1)
            params[:version] = description.config.version
            params[:damage_version] = description.config.damage_version
            params[:class] = name.slice(0,1).upcase + name.slice(1..-1)
            params[:bin_header] = description.pahole.entries["binary_header"]
            params[:name] = name
            return params
        end
        module_function :nameToParams
    end
end
