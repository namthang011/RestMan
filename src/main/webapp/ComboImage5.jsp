<%@ page import="java.nio.file.*,vn.restman.common.ComboImages" trimDirectiveWhitespaces="true" %>
<%
    String file=request.getParameter("file");
    if (file==null || !file.matches("[a-f0-9-]{36}\\.(png|jpg)")) { response.sendError(404); return; }
    Path image=ComboImages.directory().resolve(file);
    if (!Files.isRegularFile(image)) { response.sendError(404); return; }
    response.setContentType(file.endsWith(".png") ? "image/png" : "image/jpeg");
    response.setHeader("X-Content-Type-Options","nosniff");
    response.setHeader("Cache-Control","public, max-age=31536000, immutable");
    response.setContentLengthLong(Files.size(image));
    out.clear();
    pageContext.pushBody();
    if (!"HEAD".equals(request.getMethod())) Files.copy(image,response.getOutputStream());
%>
