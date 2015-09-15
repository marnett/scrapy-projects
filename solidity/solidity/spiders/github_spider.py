import scrapy
from solidity.items import SolidityItems

class SoliditySpider(scrapy.Spider):
    name = "solidity"
    allowed_domains = ["github.com"]
    start_urls = [
        "https://github.com/search?utf8=%E2%9C%93&q=solidity",
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
        print "THIS IS THE RESPOSNE" + str(response)
        for sel in response.xpath('//table/tbody/tr/td[@class="content"]/span'):
            item = SolidityItems()
            link = sel.xpath('a/@href').extract()
            item['link'] = link
            yield item
