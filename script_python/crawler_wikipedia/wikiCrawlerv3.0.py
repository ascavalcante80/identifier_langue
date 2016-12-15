__author__ = 'alexandre s. cavalcante'

import wikipedia, requests, urllib, os, time, sys, os.path, copy
from lxml import html

class CrawlWiki3:

    sys.setrecursionlimit(20000000)

    def __init__(self):
        # prefix de languages
        #self.languagesPrefix = ["af","sq","am","ar","bg","bn","bs","cs","de","da","el","en","es","fa","fi","fr","gu","he","hi", "hu", "id","is","it","ja","kn","ko","la","lg","ml","mr","nl", "no","or","pa","pl","pt","ro","ru","so","sr","sv","sw","ta","te","th","tl","tr","uk","ur","vi","xh","zu"]

        self.languagesPrefix = ["pt","ro","ru","so","sr","sv","sw","ta","te","th","tl","tr","uk","ur","vi","xh","zu", "am","ar","bg","bn","bs","cs","de","da","el","es","fa","fi","fr","gu","he","hi", "hu", "id","is","it","ja","kn","ko","la","lg","ml","mr","nl"]

        ######### INITAILISE STATS ###########

        # dictionary to keep languages stats before write them in the langs_stats.txt file
        self.langStats = {}

        # read file langs_stats.txt to intialze the dictionary st
        fileStats = open('langs_stats.txt', 'r+')

        for item in fileStats:
            # split data in a list
            temp = item.split(',')

            # temp[0] is the prefix language and temp[1] is the qtd of characters crawled
            self.langStats[temp[0]] = int(temp[1])

        # close file
        fileStats.close()

        ############### INITIALISE URL CONTROL ###########

        self.urlControl = []

        # read url_control.txt file
        fileURL = open('url_control.txt', 'r+')

        # initialise urlControl list
        for item in fileURL:

            self.urlControl.append(item.strip())

        # close file
        fileURL.close()

    # methode to crawl sites in language it receives a prefix, and threshold
    def crawlFirsPage(self, prefix):

        # define language
        wikipedia.set_lang(prefix)

        counter = 0
        while(True):

            print('comecando o tratamento para a lingua :' , prefix)
            # get a randomic article
            firstSubject = wikipedia.random()

            try:
                # get the page
                firstPage = wikipedia.page(firstSubject)
                links = firstPage.links

                #create a copy of the page
                bkp_page = copy.deepcopy(firstPage)

            except (wikipedia.exceptions.WikipediaException)as pg:
                print('Error : ' + str(pg))
                print(time.strftime('%X %x %Z')+'\n')
                return

            # if true we do not proceed the treatement
            if not self.urlTreated(firstPage.url):
                break

            # this counter assures that we wont checking this page in infinite loop
            counter =+ 1

            time.sleep(5)

            # if we have tried more than 400 pages, we pass to another language prefix
            if counter > 20:
                return

        #todo criar metodo para escrever stats
        # save content to a file and get the number of letters
        self.langStats[prefix] += self.saveArticleContent(firstPage)
        print('stats ->' + prefix + ":" + str(self.langStats[prefix]) )
        print(time.strftime('%X %x %Z')+'\n')

        # getting other languages links from firstpage
        self.crawlOtherLanguages(firstPage)

        # write stats
        self.writeStats(self.langStats)

        # define language
        wikipedia.set_lang(prefix)

        counter2 = 0

        # crawl links
        while counter2 < 2:  # esse testes substitui provisoriamente o teste abaixo, para nos asseguramos que estamos tendo outras linguas de partida
        # while len(links) > 0:

            try:
                temp = self.crawlLinks(prefix, links.pop())
                links += temp
            except (LookupError, TypeError) as err:
                print('tamanho da lista antes do erro ' + str(len(links)))
                print('Deu ruim... ' + str(err))
            counter2 += 1
        return

    # method to crawl the same language page_files
    def crawlLinks(self, prefix, link, recursive=False):

        wikipedia.set_lang(prefix)
        try:
            # get the page
            page = wikipedia.page(link)
            print('Treating url : ' + page.url)
            print(time.strftime('%X %x %Z')+'\n')

            links = page.links
            #sleep 3 seconds
            time.sleep(5)

        except (wikipedia.exceptions.WikipediaException)as pg:
            print('Error : ' + str(pg))
            print(time.strftime('%X %x %Z')+'\n')
            return


        # if true we do not proceed the treatement - oBS -> THE RECURSIVE PAGE DONT NEED TO BE CHECKED HERE! THERE ARE CHECKED BEFORE WE CALL THIS METHODE
        if self.urlTreated(page.url) and not recursive:
            return []

        # get the language prefix
        prefix = page.url.split('//')[1].split('.')[0]

        # save content to a file and get the number of letters
        self.langStats[prefix] += self.saveArticleContent(page)

        # write stats
        self.writeStats(self.langStats)

        if not (recursive):
            # crawl the article in other languages
            self.crawlOtherLanguages(page)

        # return links
        return links

    # this method receives a wiki page an crawl the page_files in other languages.
    def crawlOtherLanguages(self, page):

        print('Getting other links for: ' + page.title)
        print(time.strftime('%X %x %Z')+'\n')

        try:
            # get the wikipedia article
            newPage = requests.get(page.url)

            # set the page encoding
            newPage.encoding = 'utf-8'

            # make the html code in tree
            page_html = html.fromstring(newPage.text)

            # get all the languages links
            lang_links = page_html.xpath('//a[@lang]/@href')

        except requests.exceptions.RequestException:
            print('## ERROR - fail to get the page - ' + page.url)
            print(time.strftime('%X %x %Z')+'\n')
            return

        # crawl all the links
        for item in lang_links:

            print('item ->'+item)

            # get language prefix
            prefix = item.split('//')[1].split('.')[0]

            # verify if the prefix is the list to be treated
            if prefix in self.languagesPrefix:

                # get wikepida article title
                articleTitleUndecoded = item.split('/')[-1]

                # decode the characters written in the form %BE%A4
                articleDecoded = urllib.parse.unquote(articleTitleUndecoded)

                # crawl the page
                self.crawlLinks(prefix, articleDecoded, True)

    # methode writes the content in the file in the respective language folder, and with a proper name
    # it returns the number of letters of the content
    def saveArticleContent(self, wikiPage):

        # get the page prefix
        pagePrefix = wikiPage.url.split('//')[1].split('.')[0]

        # build the file name
        fileName = self.createFileName(wikiPage.title)

        # writing file  in the format prefix_nameArticle.txt ex.: /en/en_obama.txt
        fileArticleContent = open('./page_files/' + pagePrefix + '/' + pagePrefix + '_' + fileName, 'w+', encoding='utf8')
        fileArticleContent.write(wikiPage.content)
        fileArticleContent.close()

        # writing the same file in the eclipse folder!!!
        fileEclipse = open('/home/alexandre/workspace/M2_TAL/lang_script/projeto_identificao_lingua/corpus/' + pagePrefix + '/' + pagePrefix + '_' + fileName, 'w+', encoding='utf8')
        fileEclipse.write(wikiPage.content)
        fileEclipse.close()

        return len(wikiPage.content)

    # this methode receives an article name as argument and checks if there is file file with this name
    # it returns a proper name for the file
    def createFileName(self, articleTitle):

        # the englishTitle will be use to create the name of the file containing the article
        articleTitle = articleTitle.replace(" ", "_")

        # verify if the article title has more than 15 characters
        if (len(articleTitle) > 15):
            articleTitle = articleTitle[0:15]

        # if name already exists create name with a number in the end
        count = 1
        while(True):

            # verify if the file exists
            if os.path.isfile( articleTitle + '.txt'):
                articleTitle += count
            else:
                break

        return articleTitle + '.txt'

    # this methode returns True if the URL has been treated already
    def urlTreated(self, url):

        # verificar se o artigo ja foi tratado
        if (url in self.urlControl):

            print('url already done :' + url)
            print('trying to get another url')
            print(time.strftime('%X %x %Z')+'\n')
            # se a url ja foi tratada, encerramo a execucao da funcao
            return True

        urlControlFile = open('url_control.txt', '+a')
        # se a url nao foi tratada, ela eh inserida no arquivo e na lista de url tratadas
        self.urlControl.append(url)
        urlControlFile.write(url + '\n')
        urlControlFile.close()
        # valo retorna False se a url nao havia sido tratada
        return False

    # this method creates the directories for each language to keep the crawled page_files
    def makeDiretoyr(self, lang_prefixe):

        #build the directory path
        dir_path = './page_files/' + lang_prefixe + '/'

        #verify if the directory exists
        if not (os.path.exists(dir_path)):
            os.makedirs(dir_path)

    # this method receives a dictionary of stats and write it in a file
    # each time it`s called it overwrites the file
    def writeStats(self, dictStats):

        # open the file
        self.fileStats = open('langs_stats.txt', 'w')

        # write the stats
        for item in dictStats.keys():
            self.fileStats.write(item + ':' + str(dictStats[item]) + '\n')
        self.fileStats.close()

crawler = CrawlWiki3()

for item in crawler.languagesPrefix:
    crawler.makeDiretoyr(item)

for item in crawler.languagesPrefix:
    crawler.crawlFirsPage(item)
