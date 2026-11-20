"""Writes one demo combo. Run only against an isolated database through RESTMAN_SMOKE_BASE."""
import os, re, time, http.cookiejar
import urllib.request, urllib.parse, urllib.error
from html.parser import HTMLParser

BASE=os.environ.get('RESTMAN_SMOKE_BASE','http://127.0.0.1:8087/restman/')
client=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
def call(path,data=None,status=200):
    try:
        with client.open(BASE+path,None if data is None else urllib.parse.urlencode(data).encode(),timeout=20) as response:
            code,text=response.status,response.read().decode('utf-8')
    except urllib.error.HTTPError as error: code,text=error.code,error.read().decode('utf-8')
    assert code==status,(path,code,text[:2000])
    return text
class Controls(HTMLParser):
    def __init__(self,text):
        super().__init__(); self.hidden={}; self.options={}; self.select=None; self.option=None; self.feed(text)
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='input' and a.get('type')=='hidden': self.hidden[a['name']]=a.get('value','')
        if tag=='select': self.select=a.get('name'); self.options[self.select]=[]
        if tag=='option' and self.select: self.option={'value':a.get('value'),'text':'','selected':'selected' in a}
    def handle_data(self,data):
        if self.option is not None: self.option['text']+=data
    def handle_endtag(self,tag):
        if tag=='option' and self.option is not None: self.options[self.select].append(self.option); self.option=None
        if tag=='select': self.select=None
def choice(options, name):
    return next(o['value'] for o in options if o['text'].split()[:1] == [name])

hidden=Controls(call('AddComboUI5.jsp')).hidden
metadata={'name':'Size HTTP '+str(time.time_ns()),'price':'1900000.25','description':'Hai size cung mot mon','dishName':'wagyu','dishType':''}
def edit(action,**values): return call('AddComboUI5.jsp?action='+action,{**hidden,**metadata,**values})
options=Controls(edit('search')).options['dishSize_1']
small,medium,large=(choice(options,n) for n in ('S','M','L'))
assert len({small,medium,large})==3
assert '1.480.000' in str(options) and '2.312.500' in str(options)
detail=call('DishDetailUI5.jsp?dishId=1&dishSizeId='+large+'&name=wagyu&type=mon+chinh')
assert 'id="outSizePriceList"' not in detail and re.search(r'id="outPrice"[^>]*>\s*2\.312\.500',detail)
assert 'name=wagyu' in detail
call('DishDetailUI5.jsp?dishId=1&dishSizeId=not-a-size',status=400)
call('DishDetailUI5.jsp?dishId=1&dishSizeId=6',status=400)
call('DishDetailUI5.jsp?dishId=999999',status=404)
edit('add',dishId='1',dishSize_1=small)
edit('add',dishId='1',dishSize_1=large)
text=edit('add',dishId='1',dishSize_1=large)
assert f'name="quantity_{small}"' in text and f'name="quantity_{large}"' in text
assert re.search(fr'name="quantity_{large}"[^>]*value="2"',text)
selected=[o['value'] for o in Controls(text).options['dishSize_1'] if o['selected']]
assert selected==[large],selected
text=edit('quantity',dishSizeId=small,**{'quantity_'+small:'3'})
assert '4.440.000' in text
text=edit('remove',dishSizeId=small)
assert f'name="quantity_{small}"' not in text and f'name="quantity_{large}"' in text
edit('add',dishId='1',dishSize_1=small)
text=edit('add',dishId='1',dishSize_1='6')
assert 'Size không thuộc món ăn' in text
text=edit('quantity',dishSizeId=large,**{'quantity_'+large:'0'})
assert 'Số lượng phải từ 1 đến 999.' in text
text=call('doSaveCombo5.jsp',{**hidden,**metadata,'action':'save'})
assert metadata['name'] in text
text=call('SearchDishUI5.jsp?'+urllib.parse.urlencode({'search':'1','name':metadata['name']}))
combo_id=re.search(r'name="comboId" value="(\d+)"',text).group(1)
for _ in range(2):
    text=call('ComboDetailUI5.jsp?comboId='+combo_id)
    assert '1.480.000' in text and '2.312.500' in text and '4.625.000' in text
    assert re.search(r'\bS\b',re.sub(r'<[^>]+>',' ',text)) and re.search(r'\bL\b',re.sub(r'<[^>]+>',' ',text))
print('PASS: size prices/detail, invalid and foreign sizes, two sizes per dish, same-size increment, quantity/remove isolation, selection memory, save/read-back and search.')
