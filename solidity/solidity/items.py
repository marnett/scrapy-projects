# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class SolidityItems(scrapy.Item):
    file_url = scrapy.Field()
    repo_url = scrapy.Field()
    hash = scrapy.Field()
    contract_name = scrapy.Field()
