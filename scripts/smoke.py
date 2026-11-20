"""Kiểm tra toàn bộ vòng lặp JSP bằng HTTP thật, không thực thi JavaScript."""
import http.cookiejar
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from html import unescape

BASE = os.environ.get("RESTMAN_SMOKE_BASE", "http://127.0.0.1:8081/restman/")
client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

class Inputs(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.values = {}
        self.feed(html)
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "input" and attrs.get("type") == "hidden":
            self.values[attrs["name"]] = attrs.get("value", "")

def call(path, data=None, status=200):
    body = None if data is None else urllib.parse.urlencode(data).encode()
    try:
        with client.open(BASE + path, body, timeout=20) as response:
            code, text, url = response.status, response.read().decode("utf-8"), response.url
    except urllib.error.HTTPError as error:
        code, text, url = error.code, error.read().decode("utf-8"), error.url
    assert code == status, (path, code, text[:2000])
    return text, url

for page in ["", "MainCustomerUI5.jsp", "MainStaffUI5.jsp", "ComboListUI5.jsp"]:
    call(page)
text, _ = call("SearchDishUI5.jsp")
assert "Nhập tên hoặc chọn thể loại" in text
text, _ = call("SearchDishUI5.jsp?" + urllib.parse.urlencode({"search": "1", "name": "tom hum", "type": "Món chính"}))
assert "Tôm hùm nướng bơ tỏi" in text and 'name="dishId" value="2"' in text
text, _ = call("DishDetailUI5.jsp?dishId=2&name=tom+hum&type=" + urllib.parse.quote("Món chính"))
assert "Tôm hùm nướng bơ tỏi" in text and "name=tom+hum" in text
call("DishDetailUI5.jsp?dishId=999", status=404)
text, _ = call("SearchDishUI5.jsp?search=1&name=zzzz")
assert "Không tìm thấy món ăn phù hợp." in text
assert "Không tìm thấy combo phù hợp." in text

text, _ = call("SearchDishUI5.jsp?search=1&name=signature")
assert "Signature Wagyu" in text and 'id="outComboSearchList"' in text
assert "Giá bán (VNĐ)" in text and 'class="numeric"' in text
combo_id = re.search(r'name="comboId" value="(\d+)"', text).group(1)
text, _ = call("ComboDetailUI5.jsp?" + urllib.parse.urlencode({"comboId": combo_id, "name": "signature", "type": ""}))
assert 'id="outComboDetails"' in text and "Thăn bò Wagyu" in text and "Mocktail" in text
assert "Kích cỡ" in text and "Số lượng" in text and "Thành tiền (VNĐ)" in text
back = unescape(re.search(r'id="subBack"[^>]+href="([^"]+)"', text).group(1))
assert "name=signature" in back and "SearchDishUI5.jsp" in back
text, _ = call(back.split("/restman/", 1)[1])
assert "Signature Wagyu" in text
text, _ = call("ComboDetailUI5.jsp?comboId=" + combo_id + "&from=staff")
assert 'href="/restman/ComboListUI5.jsp"' in text
for invalid_id in ["", "-1", "not-a-number", "999999999"]:
    call("ComboDetailUI5.jsp?comboId=" + invalid_id, status=404)
text, _ = call("SearchDishUI5.jsp?search=1&name=tom+hum&type=do+uong")
assert "Ocean Elegance" not in text
text, _ = call("SearchDishUI5.jsp?search=1&name=tom+hum&type=mon+chinh")
assert "Ocean Elegance" in text and "Tôm hùm" in text

text, _ = call("AddComboUI5.jsp")
hidden = Inputs(text).values
metadata = {"name": "HTTP demo " + str(time.time_ns()), "price": "1900000.25", "description": "Giữ thông tin qua nhiều lần tìm", "startDate": "2026-11-16", "endDate": "2026-12-01", "dishSize_1": "1", "dishSize_6": "6"}
def edit(action, **extra):
    return call("AddComboUI5.jsp?action=" + action, {**hidden, **metadata, "dishName": "", "dishType": "", **extra})[0]
text = edit("search", dishName="wagyu")
assert 'value="' + metadata["name"] + '"' in text and "Thăn bò Wagyu" in text
assert 'name="startDate"' in text and 'value="2026-11-16"' in text and 'value="2026-12-01"' in text
text = edit("add", dishId="1")
assert "1.850.000" in text
text = edit("search", dishName="mocktail", dishType="Đồ uống")
assert "Thăn bò Wagyu" in text and "Mocktail lựu hương thảo" in text
text = edit("add", dishId="6")
text = edit("add", dishId="6")
assert 'name="quantity_6" type="number" min="1" max="999" value="2"' in text
text = edit("quantity", dishSizeId="6", quantity_6="0")
assert "Số lượng phải từ 1 đến 999." in text
text = edit("quantity", dishSizeId="6", quantity_6="1")
assert 'name="quantity_6" type="number" min="1" max="999" value="1"' in text
text = edit("remove", dishSizeId="6")
assert 'name="quantity_6"' not in text
edit("add", dishId="6")
text = edit("add", dishId="999")
assert "Món ăn không tồn tại." in text
text, _ = call("doSaveCombo5.jsp", {**hidden, **metadata, "price": "0", "action": "save"})
assert "Giá bán phải" in text and 'name="quantity_1"' in text
text, _ = call("doSaveCombo5.jsp", {**hidden, **metadata, "name": "", "action": "save"})
assert "Tên combo phải" in text
call("doSaveCombo5.jsp", status=405)
call("doSaveCombo5.jsp", {"action": "save"}, status=403)
text, _ = call("doSaveCombo5.jsp", {**hidden, **metadata, "endDate": "2026-11-01", "action": "save"})
assert "ngày bắt đầu không được sau" in text and 'name="quantity_1"' in text
text, url = call("doSaveCombo5.jsp", {**hidden, **metadata, "action": "save"})
assert url.endswith("ComboListUI5.jsp") and "thành công" in text
assert metadata["name"] in text and "1.900.000,25" in text
assert "2026-11-16" in text and "2026-12-01" in text
text, _ = call("ComboListUI5.jsp")
assert "thành công" not in text
text, _ = call("doSaveCombo5.jsp", {**hidden, **metadata, "action": "save"})
assert "Bản nháp đã kết thúc" in text
text, _ = call("AddComboUI5.jsp")
assert metadata["name"] not in text and "Chưa chọn món nào." in text
fresh = Inputs(text).values
text, url = call("doSaveCombo5.jsp", {**fresh, "action": "cancel"})
assert url.endswith("ComboListUI5.jsp")
print("PASS: JSP navigation, search/detail/back, hidden state, no-JS draft loop, quantity/remove, validation, CSRF, save, stale POST, cancel.")
