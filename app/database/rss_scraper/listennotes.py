from bs4 import BeautifulSoup
import requests
import re

url = "https://www.listennotes.com/best-podcasts/?page={}&region=us&sort_type=recent_added_first"

for i in range(1,21):
    furl = url.format(i)
    print(furl)
    r = requests.get(furl, 
    headers = {
        "Cookie":"__cfduid=dca83b9a22bd4ad32a0249968c13c24161605172098; csrftoken=HBoqo7kgzLkcUO6CCO8I2BHErqeoWz4TlHDfNW4zmJg29LpbBS47QKGaYFprs4pu; sessionid=43xy7jsxxuckc901s4tr3guuti4ik5zs"
    })
    t = r.text
    soup = BeautifulSoup(t, 'html.parser')
    rss = soup.find_all(title=re.compile('RSS feed of .*'))
    for i in rss:
        print(i["href"])