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
            item['link'] = sel.xpath('a/@href').extract()
            yield item

        for sel in response.xpath('//div[@class="pagination"]'):
            item = SolidityItems()
            url = sel.xpath('a[contains(text(), "Next")]/@href').extract()
            print url
            print response