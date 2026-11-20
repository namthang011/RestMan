"""Creates one demo combo; use an isolated RESTMAN_SMOKE_BASE, never the production DB."""
import os,re,time,uuid,hashlib
from pathlib import Path
from html import unescape
from html.parser import HTMLParser
from http.cookiejar import CookieJar
from urllib.request import build_opener,HTTPCookieProcessor,Request
from urllib.parse import urlencode,urljoin
from urllib.error import HTTPError
base=os.environ.get('RESTMAN_SMOKE_BASE','http://127.0.0.1:8087/restman/')
client=build_opener(HTTPCookieProcessor(CookieJar()))
def request(path,data=None,file=None,status=200):
    headers={}
    if file is not None:
        boundary=uuid.uuid4().hex
        parts=[]
        for name,value in data.items():
            parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="comboImage"; filename="../../example.jsp"\r\nContent-Type: image/png\r\n\r\n'.encode()+file+b'\r\n')
        parts.append(f'--{boundary}--\r\n'.encode())
        body=b''.join(parts); headers['Content-Type']='multipart/form-data; boundary='+boundary
    else: body=None if data is None else urlencode(data).encode()
    try:
        with client.open(Request(urljoin(base,path),body,headers),timeout=30) as r:
            code,content=r.status,r.read()
    except HTTPError as error: code,content=error.code,error.read()
    assert code==status,(path,code,content[:1500])
    return content
class Hidden(HTMLParser):
    def __init__(self,text): super().__init__(); self.values={}; self.feed(text)
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='input' and a.get('type')=='hidden': self.values[a['name']]=a.get('value','')
page=request('AddComboUI5.jsp').decode()
hidden=Hidden(page).values
metadata={'name':'Image HTTP '+str(time.time_ns()),'price':'1900000','description':'Image persistence','dishName':'wagyu','dishType':''}
image=Path('src/main/webapp/assets/images/generated/dish-1.png').read_bytes()
page=request('AddComboUI5.jsp?action=search',{**hidden,**metadata},image).decode()
assert metadata['name'] in page and 'id="comboImagePreview"' in page
image_url=unescape(re.search(r'id="comboImagePreview"[^>]*src="([^"]+)"',page).group(1))
assert re.search(r'ComboImage5\.jsp\?file=[a-f0-9-]{36}\.png$',image_url),image_url
assert hashlib.sha256(request(image_url)).digest()==hashlib.sha256(image).digest()
legacy_url = image_url.replace('ComboImage5.jsp?', 'ComboImage.jsp?')
assert request(legacy_url) == image
page=request('AddComboUI5.jsp?action=search',{**hidden,**metadata},b'<svg><script>bad()</script></svg>').decode()
assert 'hợp lệ' in page and image_url in page
page=request('AddComboUI5.jsp?action=add',{**hidden,**metadata,'dishId':'1','dishSize_1':'1'}).decode()
assert image_url in page and 'name="quantity_1"' in page
page=request('doSaveCombo5.jsp',{**hidden,**metadata,'action':'save'}).decode()
assert metadata['name'] in page
page=request('SearchDishUI5.jsp?'+urlencode({'search':'1','name':metadata['name']})).decode()
assert image_url in page
combo_id=re.search(r'name="comboId" value="(\d+)"',page).group(1)
assert image_url in request('ComboDetailUI5.jsp?comboId='+combo_id).decode()
request('ComboImage5.jsp?file=../../pom.xml',status=404)
request('ComboImage5.jsp?file=00000000-0000-0000-0000-000000000000.png',status=404)
request('doSaveCombo5.jsp',{'action':'save'},image,status=403)
print('PASS: multipart image upload, safe generated filename, exact bytes, preview/draft retention, invalid image rejection, save to DB and detail/search display, CSRF/path validation.')
print('PERSISTENCE_URL='+image_url)
