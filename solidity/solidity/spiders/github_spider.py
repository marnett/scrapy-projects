import scrapy, urllib
from solidity.items import SolidityItems

class SoliditySpider(scrapy.Spider):
    name = "solidity"
    allowed_domains = ["github.com", "raw.githubusercontent.com"]
    start_urls = [
        #"https://github.com/search?utf8=%E2%9C%93&q=solidity"
        #"https://github.com/blockapps/solidity-abi/tree/master/tests/success/mapping_declarations"
        "https://github.com/search?utf8=%E2%9C%93&q=solidity-examples&type=Repositories&ref=searchresults"
    ]

    #def parase(self, response):



        #yield scrapy.Request(url, callback = self.parse_page)

    def parse(self, response):
        for sel in response.xpath('//ul/li/h3'):
            item = SolidityItems()
            link = sel.xpath('a/@href').extract()
            item['link'] = link
            #yield item
            link = "".join(link)
            link = "https://github.com" + link
            yield scrapy.Request(link, callback=self.parse_repo)
 
        item = SolidityItems()
        url = response.xpath('//div[@class="pagination"]').xpath('a[contains(text(), "Next")]/@href').extract()
        #print "THIS IS THE URL "  + str(url[0])
        #print "THIS IS THE RESPONSE " + str(response)
        url = "https://github.com" + str(url[0])
        yield scrapy.Request(url, callback=self.parse)

    def parse_repo(self, response):
        #print "THIS IS THE RESPOSNE" + str(response)
        for sel in response.xpath('//table/tbody/tr/td[@class="content"]/span'):
            item = SolidityItems()
            link = sel.xpath('a/@href').extract()
            item['link'] = link
            url = "https://github.com" + str(link[0])
            if ".sol" in url:
                yield scrapy.Request(url, callback=self.parse_raw)
            yield scrapy.Request(url, callback=self.parse_repo)

    def parse_raw(self, response):
        link = response.xpath('//div[@class="file-actions"]/div[@class="btn-group"]').xpath('a[contains(text(), "Raw")]/@href').extract()
        url = "https://github.com" + str(link[0])
        yield scrapy.Request(url, callback=self.download_sol)
    
    def download_sol(self, response):
        url = str(response.url)
        filename = url.split('/')
        filename =  filename[len(filename)-1]
        testfile = urllib.URLopener()
        testfile.retrieve(url, filename)














        