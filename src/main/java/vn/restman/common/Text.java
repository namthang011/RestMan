package vn.restman.common;
import java.text.Normalizer;
import java.util.Locale;
public final class Text {
 private Text() {}
 public static String key(String value) { return Normalizer.normalize(value == null ? "" : value.strip(), Normalizer.Form.NFD).replaceAll("\\p{M}", "").replace('đ','d').replace('Đ','D').toLowerCase(Locale.ROOT); }
}