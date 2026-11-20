package vn.restman.common;

import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.ImageInputStream;

public final class ComboImages {
    private ComboImages() {}
    public static Path directory() {
        return Path.of(System.getProperty("catalina.base")).toAbsolutePath().getParent().resolve("uploads/combo");
    }
    public static String receive(HttpServletRequest request) {
        if (request.getContentType()==null || !request.getContentType().toLowerCase(Locale.ROOT).startsWith("multipart/form-data")) return null;
        try {
            Part part = request.getPart("comboImage");
            if (part==null || part.getSize()==0) return null;
            if (part.getSize()>5*1024*1024) throw new IllegalArgumentException("Ảnh tối đa 5 MB.");
            String extension;
            try (ImageInputStream input=ImageIO.createImageInputStream(part.getInputStream())) {
                var readers=ImageIO.getImageReaders(input);
                if (!readers.hasNext()) throw new IllegalArgumentException("Vui lòng chọn ảnh PNG hoặc JPEG hợp lệ.");
                ImageReader reader=readers.next();
                try {
                    reader.setInput(input);
                    String format=reader.getFormatName().toLowerCase(Locale.ROOT);
                    if (!format.equals("png") && !format.equals("jpeg")) throw new IllegalArgumentException("Chỉ hỗ trợ PNG và JPEG.");
                    if ((long)reader.getWidth(0)*reader.getHeight(0)>20000000) throw new IllegalArgumentException("Ảnh có độ phân giải quá lớn.");
                    reader.read(0); // Verify actual image content, not the supplied filename or MIME type.
                    extension=format.equals("png") ? ".png" : ".jpg";
                } finally { reader.dispose(); }
            }
            Files.createDirectories(directory());
            String name=UUID.randomUUID().toString()+extension;
            try (InputStream input=part.getInputStream()) { Files.copy(input,directory().resolve(name)); }
            return "ComboImage5.jsp?file="+name;
        } catch (IllegalArgumentException ex) { throw ex; }
        catch (Exception ex) { throw new IllegalArgumentException("Không tải được ảnh. Chọn PNG/JPEG tối đa 5 MB."); }
    }
}
