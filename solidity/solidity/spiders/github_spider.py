import scrapy, urllib, hashlib
from solidity.items import SolidityItems

class SoliditySpider(scrapy.Spider):
    name = "solidity"
    allowed_domains = ["github.com", "raw.githubusercontent.com"]
    start_urls = [
        #"https://github.com/search?utf8=%E2%9C%93&q=solidity"
        #"https://github.com/blockapps/solidity-abi/tree/master/tests/success/mapping_declarations"
        "https://github.com/search?utf8=%E2%9C%93&q=solidity-examples&type=Repositories&ref=searchresults"
    ]

    def parse(self, response):
        for sel in response.xpath('//ul/li/h3'):
            repo_url = sel.xpath('a/@href').extract()
            repo_url = "".join(repo_url)
            repo_url = "https://github.com" + repo_url
            yield scrapy.Request(repo_url, callback=self.parse_repo)
 
        url = response.xpath('//div[@class="pagination"]').xpath('a[contains(text(), "Next")]/@href').extract()
        url = "https://github.com" + str(url[0])
        yield scrapy.Request(url, callback=self.parse)

    def parse_repo(self, response):
        for sel in response.xpath('//table/tbody/tr/td[@class="content"]/span'):
            url = sel.xpath('a/@href').extract()
            url = "https://github.com" + str(url[0])
            if ".sol" in url:
                yield scrapy.Request(url, callback=self.parse_raw)
            yield scrapy.Request(url, callback=self.parse_repo)

    def parse_raw(self, response):
        raw_url = response.xpath('//div[@class="file-actions"]/div[@class="btn-group"]').xpath('a[contains(text(), "Raw")]/@href').extract()
        url = "https://github.com" + str(raw_url[0])
        yield scrapy.Request(url, callback=self.download_sol)
    
    def download_sol(self, response):
        item = SolidityItems()
        url = str(response.url)
        item['raw_url'] = url
        filename = url.split('/')
        filename =  filename[len(filename)-1]
        item['contract_name'] = filename

        m = hashlib.md5()
        m.update(url)
        hash = m.hexdigest()
        item['hash'] = hash

        savefile = urllib.URLopener()
        save_file_name = "contracts/" + hash + '.sol'
        savefile.retrieve(url, save_file_name)
        f = open(save_file_name, 'r')
        item['raw_code'] = f.read()
        return item














        