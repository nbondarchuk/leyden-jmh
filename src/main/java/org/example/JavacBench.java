package org.example;

import org.openjdk.jmh.annotations.*;

import javax.tools.*;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.util.*;

public class JavacBench {

    static class ClassFile extends SimpleJavaFileObject {
        private final ByteArrayOutputStream baos = new ByteArrayOutputStream();

        protected ClassFile(String name) {
            super(URI.create("memo:///" + name.replace('.', '/') + Kind.CLASS.extension), Kind.CLASS);
        }

        @Override
        public ByteArrayOutputStream openOutputStream() {
            return this.baos;
        }

        byte[] toByteArray() {
            return baos.toByteArray();
        }
    }

    static class FileManager extends ForwardingJavaFileManager<JavaFileManager> {
        private Map<String, ClassFile> classesMap = new HashMap<String, ClassFile>();

        protected FileManager(JavaFileManager fileManager) {
            super(fileManager);
        }

        @Override
        public ClassFile getJavaFileForOutput(Location location, String name, JavaFileObject.Kind kind, FileObject source) {
            ClassFile classFile = new ClassFile(name);
            classesMap.put(name, classFile);
            return classFile;
        }

        public Map<String, byte[]> getByteCode() {
            Map<String, byte[]> result = new HashMap<>();
            for (Map.Entry<String, ClassFile> entry : classesMap.entrySet()) {
                result.put(entry.getKey(), entry.getValue().toByteArray());
            }
            return result;
        }
    }

    static class SourceFile extends SimpleJavaFileObject {
        private CharSequence sourceCode;

        public SourceFile(String name, CharSequence sourceCode) {
            super(URI.create("memo:///" + name.replace('.', '/') + Kind.SOURCE.extension), Kind.SOURCE);
            this.sourceCode = sourceCode;
        }

        @Override
        public CharSequence getCharContent(boolean ignore) {
            return this.sourceCode;
        }
    }

    @State(Scope.Benchmark)
    public static class JavaBenchState {

        @Param({"100"})
        int count;

        List<SourceFile> sources10k;

        @Setup(Level.Invocation)
        public void setup() {
            List<SourceFile> sources = new ArrayList<>(10_000);
            for (int i = 0; i < count; i++) {
                sources.add(new SourceFile("HelloWorld" + i,
                        "public class HelloWorld" + i + " {" +
                                "    public static void main(String[] args) {" +
                                "        System.out.println(\"Hellow World!\");" +
                                "    }" +
                                "}"));
            }
            sources10k = sources;
        }
    }

    @Benchmark
    @Warmup(iterations = 0)
    @Measurement(iterations = 15)
    @Fork(value = 0, warmups = 0)
    @BenchmarkMode(Mode.SingleShotTime)
    public Object compile(JavaBenchState state) {
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        DiagnosticCollector<JavaFileObject> ds = new DiagnosticCollector<>();
        Collection<SourceFile> sourceFiles = state.sources10k.subList(0, state.count);

        try (FileManager fileManager = new FileManager(compiler.getStandardFileManager(ds, null, null))) {
            JavaCompiler.CompilationTask task = compiler.getTask(null, fileManager, null, List.of("-Xlint:-options"), null, sourceFiles);
            if (task.call()) {
                return fileManager.getByteCode();
            } else {
                for (Diagnostic<? extends JavaFileObject> d : ds.getDiagnostics()) {
                    System.out.format("Line: %d, %s in %s", d.getLineNumber(), d.getMessage(null), d.getSource().getName());
                }
                throw new InternalError("compilation failure");
            }
        } catch (IOException e) {
            throw new InternalError(e);
        }
    }

    public static void main(String args[]) throws Exception {
        org.openjdk.jmh.Main.main(args);
    }
}
